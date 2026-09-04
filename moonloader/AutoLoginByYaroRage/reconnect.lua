-- Модуль реконнекта AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local utils = require("AutoLoginByYaroRage.utils")
local M = {}

local start_reconnect_watch
local post_loading_login_watch
local emulate_loading_close_auth
local emulate_close_menu_pause
local emulate_reconnect_ui_cleanup
local finish_reconnect
local in_close_menu_emul_window
local mark_manual_reconnect
local mark_queue_seen

local function isActuallyInGame()
    local ped_ptr = getCharPointer(PLAYER_PED) or 0
    return readMemory(ped_ptr + 0x46C, 1, false) == 1
        or readMemory(ped_ptr + 0x72C, 1, false) > 0
end

function M.apply_fast_reconnect_patch()
    local s = AL.state
    if s.fast_reconnect_enabled then
        writeMemory(sampGetBase() + 2964549, 2, 0, true)
    else
        writeMemory(sampGetBase() + 2964549, 2, 0x01F4, true)
    end
end

function M.do_fast_reconnect(seconds)
    lua_thread.create(function()
        if sampIsDialogActive() then
            sampCloseCurrentDialogWithButton(0)
        end
        printStringNow("Reconnect in ~r~" .. seconds .. "  ~w~sec.", 1600)
        if sampGetGamestate() ~= GAMESTATE_RESTARTING then
            sampSetGamestate(GAMESTATE_DISCONNECTED)
            sampDisconnectWithReason(0)
        end
        wait(seconds * 1000)
        sampSetGamestate(GAMESTATE_WAIT_CONNECT)
    end)
end

in_close_menu_emul_window = function()
    local s = AL.state
    return os.clock() < s.close_menu_emul_until
end

finish_reconnect = function(reason)
    local s = AL.state
    s.is_reconnecting = false
    s.reconnect_watch_active = false
    s.close_menu_emul_until = os.clock() + s.CLOSE_MENU_EMUL_AFTER_SEC
    AL.log("Реконнект завершён (" .. tostring(reason) .. ") - is_spawned=false")
    s.is_spawned = false
end

emulate_loading_close_auth = function()
    local s = AL.state
    if s.is_logging_in or s.is_spawned then
        AL.log("Loading[3000] пропуск (не вход/в игре)")
        return
    end
    s.is_logging_in = true
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteInt8(bs, 0)
    raknetBitStreamWriteInt8(bs, 0)
    local ok, err = pcall(raknetEmulPacketReceiveBitStream, 215, bs)
    raknetDeleteBitStream(bs)
    if ok then
        AL.log("Эмуляция Loading[3000] x1 (reconnect)")
    else
        AL.log("Ошибка Loading[3000]: " .. tostring(err))
    end
end

emulate_close_menu_pause = function(times)
    local s = AL.state
    if s.is_logging_in or s.is_spawned then
        AL.log("CloseMenuPause эмуляция (не вход/в игре)")
        return
    end
    times = times or 1
    for i = 1, times do
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, 0)
        local ok, err = pcall(raknetEmulPacketReceiveBitStream, 215, bs)
        raknetDeleteBitStream(bs)
        if not ok then
            AL.log("Ошибка OnPlayerCloseMenuPause: " .. tostring(err))
        end
    end
    AL.log("Эмуляция OnPlayerCloseMenuPause x" .. tostring(times))
end

emulate_reconnect_ui_cleanup = function()
    emulate_loading_close_auth()
end

start_reconnect_watch = function()
    local s = AL.state
    s.reconnect_watch_active = true
    s.saw_loading_after_rec = false
    s.saw_queue_after_rec = false

    AL.log("Watchdog инициализирован: 20 сек (отслеживание загрузки/очереди; для ручного - F11)")

    local start_time = os.clock()
    while os.clock() - start_time < 20 do
        wait(500)
        if not s.reconnect_watch_active then
            AL.log("Watchdog: стоп (реконнект/спавн/старт/таймер) по F11 или автозапуск")
            return
        end
    end

    if not s.saw_loading_after_rec and not s.saw_queue_after_rec then
        if utils.game_window_active() then
            AL.log("Watchdog: 20с без загрузки в окне GTA - пробуем F11")
            local hwnd = user32.FindWindowA("CDisplaya", nil)
            if hwnd ~= 0 then
                AL.log("Watchdog: окно GTA активно, нажимаем F11")
                utils.wait_for_game_focus()
            end
            user32.keybd_event(0x7A, 0, 0, 0)
            user32.keybd_event(0x7A, 0, 2, 0)
            AL.log("Watchdog: F11 нажат")
        else
            AL.log("Watchdog: окно GTA не в фокусе, F11 не нажимаем")
        end
    end
    s.reconnect_watch_active = false
end

mark_manual_reconnect = function(reason)
    M.trigger_reconnect(reason)
end

post_loading_login_watch = function()
    local s = AL.state
    AL.log("Watchdog: ожидание успешного входа в игру до 30 сек (старт - реконнект)")

    local start_time = os.clock()
    while os.clock() - start_time < 30 do
        wait(500)
        if s.is_spawned then
            AL.log("Watchdog: вход/спавн до 30с - отмена автозапуска")
            return
        end
    end

    AL.log("Watchdog: 30с таймаут - стоп автозапуска")
end

mark_queue_seen = function(source)
    local s = AL.state
    s.saw_queue_after_rec = true
    AL.log("Пакет разрыва (" .. tostring(source) .. ") - watchdog стоп")
end

function M.trigger_reconnect(reason)
    local s = AL.state

    if os.clock() < s.reconnect_cooldown_until then
        AL.log("Пропуск реконнекта (cooldown)")
        return
    end

    if os.clock() < s.reconnect_pause_until then
        AL.log("Пропуск реконнекта (пауза между попытками)")
        return
    end

    if s.is_reconnecting then
        AL.log("Пропуск: уже реконнектируюсь")
        return
    end

    s.reconnect_attempt_count = s.reconnect_attempt_count + 1

    if s.reconnect_attempt_count >= 3 then
        AL.log("Ошибка: 3 неудачных попытки реконнекта - пауза 5 минут")
        s.reconnect_pause_until = os.clock() + 300
        s.reconnect_attempt_count = 0
        return
    end

    AL.chat_msg("{FF3333}Потеря соединения! Переподключение...")

    s.is_reconnecting = true
    s.is_spawned = false
    s.is_logging_in = false
    s.login_submitted = false

    if s.fast_reconnect_enabled then
        M.do_fast_reconnect(5)
        AL.log("Режим: F11 (быстрый). Отправка AuthorizationT, эмуляция закрытия меню.")
    else
        local ok1, err1 = pcall(sampConnectToServer, "127.0.0.1", 7777)
        if ok1 then
            AL.log("Режим: sampConnectToServer")
        else
            sampSendChat("/rec 3")
            AL.log("Режим: /rec 3")
        end
    end

    lua_thread.create(start_reconnect_watch)
end

function M.register_commands()
    sampRegisterChatCommand("rec", function(arg)
        local seconds = tonumber(arg) or 5
        M.do_fast_reconnect(seconds)
    end)

    sampRegisterChatCommand("mrec", function(arg)
        if tonumber(arg) then
            M.do_fast_reconnect(tonumber(arg))
        else
            printStringNow("Wrong ~r~[~w~value~r~]", 1600)
        end
    end)

    sampRegisterChatCommand("fastrec", function()
        local s = AL.state
        s.fast_reconnect_enabled = not s.fast_reconnect_enabled
        M.apply_fast_reconnect_patch()
        AL.chat_msg(string.format("Быстрый реконнект: %s", s.fast_reconnect_enabled and "включён" or "отключён"))
    end)
end

M._internal = {
    in_close_menu_emul_window = function() return in_close_menu_emul_window() end,
    finish_reconnect = function(r) finish_reconnect(r) end,
    emulate_loading_close_auth = function() emulate_loading_close_auth() end,
    emulate_close_menu_pause = function(t) emulate_close_menu_pause(t) end,
    emulate_reconnect_ui_cleanup = function() emulate_reconnect_ui_cleanup() end,
    mark_manual_reconnect = function(r) mark_manual_reconnect(r) end,
    mark_queue_seen = function(s) mark_queue_seen(s) end,
    post_loading_login_watch = function() post_loading_login_watch() end,
    start_reconnect_watch = function() start_reconnect_watch() end,
}

return M
