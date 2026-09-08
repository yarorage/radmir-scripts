-- Модуль реконнекта AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local utils = require("AutoLoginByYaroRage.utils")
local M = {}

-- Safe bitstream helper with guaranteed cleanup
local function safe_bitstream(bytes, handler)
    local bs = raknetNewBitStream()
    local ok, err = pcall(function()
        for i = 1, #bytes do
            raknetBitStreamWriteInt8(bs, bytes[i])
        end
        handler(bs)
    end)
    raknetDeleteBitStream(bs)
    if not ok then
        AL.log("Ошибка bitstream: " .. tostring(err))
    end
    return ok
end

local start_reconnect_watch
local post_loading_login_watch
local emulate_loading_close_auth
local emulate_close_menu_pause
local emulate_reconnect_ui_cleanup
local finish_reconnect
local in_close_menu_emul_window
local mark_manual_reconnect
local mark_queue_seen
local last_reconnect_time = 0
local RECONNECT_COOLDOWN = 5

function M.apply_fast_reconnect_patch()
    local s = AL.state
    local base = sampGetBase()
    if not base then return end
    
    -- Check if writeMemory is available (from sampfuncs)
    if not writeMemory then
        AL.log("Патч быстрого реконнекта: writeMemory недоступен (нет sampfuncs)")
        return
    end
    
    local ok, err = pcall(function()
        if s.fast_reconnect_enabled then
            writeMemory(base + 2964549, 2, 0, true)
        else
            writeMemory(base + 2964549, 2, 0x01F4, true)
        end
    end)
    if not ok then AL.log("Ошибка writeMemory: " .. tostring(err)) end
end

function M.handle_auth_limit_cef()
    local s = AL.state
    if not s.cef_limit_seen then
        AL.log("handle_auth_limit_cef: пропуск (флаг лимита/античит/время не в сети)")
        return
    end
    if s.is_spawned then
        s.cef_limit_seen = false
        AL.log("handle_auth_limit_cef: пропуск (мы уже в мире)")
        return
    end
    lua_thread.create(function()
        AL.log("handle_auth_limit_cef: ждём 215 (лимит/античит/время) -> эмуляция закрытия")
        pcall(utils.wait_for_focus)
        wait(200)
        s.saw_menu_pause_after_esc = false
        AL.log("handle_auth_limit_cef: ESC #1")
        user32.keybd_event(0x1B, 0, 0, 0)
        wait(50)
        user32.keybd_event(0x1B, 0, 2, 0)
        wait(400)
        if s.saw_menu_pause_after_esc then
            AL.log("handle_auth_limit_cef: OnPlayerOpenMenuPause пришёл -> ESC #2")
            user32.keybd_event(0x1B, 0, 0, 0)
            wait(50)
            user32.keybd_event(0x1B, 0, 2, 0)
        else
            AL.log("handle_auth_limit_cef: OnPlayerOpenMenuPause не пришёл -> F11")
            user32.keybd_event(0x7A, 0, 0, 0)
            wait(50)
            user32.keybd_event(0x7A, 0, 2, 0)
        end
        s.cef_limit_seen = false
        AL.log("handle_auth_limit_cef: готово")
        wait(200)
        if not s.is_spawned and not s.is_reconnecting then
            mark_manual_reconnect("AuthLimit")
        end
    end)
end

function M.do_fast_reconnect(seconds)
    if os.clock() - last_reconnect_time < RECONNECT_COOLDOWN then
        AL.log("do_fast_reconnect: кулдаун, пропуск")
        return
    end
    last_reconnect_time = os.clock()
    seconds = tonumber(seconds) or 1

    lua_thread.create(function()
        AL.log("do_fast_reconnect: старт, сек=" .. seconds)
        wait(300)
        printStringNow("Reconnect in ~r~" .. seconds .. "  ~w~sec.", 1600)
        pcall(sampDisconnectWithReason, 0)
        wait(seconds * 1000)
        pcall(sampSetGamestate, GAMESTATE_WAIT_CONNECT)
        wait(800)
        emulate_reconnect_ui_cleanup()
        AL.log("do_fast_reconnect: готово")
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
    s.reconnect_attempt_count = 0
    s.close_menu_emul_until = os.clock() + s.CLOSE_MENU_EMUL_AFTER_SEC
    AL.log("Reconnect done (" .. tostring(reason) .. ")")
end

emulate_loading_close_auth = function()
    local s = AL.state
    if s.is_logging_in or s.is_spawned or s.login_submitted then
        AL.log("Loading[3000] пропуск (уже зашел/в процессе)")
        return
    end
    if not s.cef_auth_window_seen then
        AL.log("Loading[3000] пропуск (нет флага окна авторизации в сети)")
        return
    end
    local ok = safe_bitstream({
        2, 0, 4, 0, 0, 0, 2,
        7, 0, 0, 0, 76, 111, 97, 100, 105, 110, 103,
        6, 0, 0, 0, 91, 51, 48, 48, 48, 93
    }, function(bs)
        raknetEmulPacketReceiveBitStream(215, bs)
    end)
    if ok then
        s.cef_auth_window_seen = false
        AL.log("Эмуляция Loading[3000] x1 (reconnect)")
    else
        AL.log("Эмуляция Loading[3000] ошибка")
    end
end

emulate_close_menu_pause = function(times)
    local s = AL.state
    if s.is_logging_in or s.is_spawned or s.login_submitted then
        AL.log("CloseMenuPause пропуск (уже зашел/в процессе)")
        return
    end
    if not s.cef_open_menu_pause_seen then
        AL.log("CloseMenuPause пропуск (OnPlayerOpenMenuPause не было в сети)")
        return
    end
    times = times or 1
    local ok = safe_bitstream({
        2, 0, 0, 0, 0, 0,
        22, 0, 0, 0,
        79, 110, 80, 108, 97, 121, 101, 114, 67, 108, 111, 115, 101, 77, 101, 110, 117, 80, 97, 117, 115, 101,
        0, 0, 0, 0
    }, function(bs)
        raknetEmulPacketReceiveBitStream(215, bs)
    end)
    if ok then
        s.cef_open_menu_pause_seen = false
        AL.log("Эмуляция OnPlayerCloseMenuPause x" .. tostring(times))
    else
        AL.log("Эмуляция OnPlayerCloseMenuPause ошибка")
    end
end

emulate_reconnect_ui_cleanup = function()
    emulate_loading_close_auth()
end

start_reconnect_watch = function()
    local s = AL.state
    s.reconnect_watch_active = true
    s.saw_loading_after_rec = false
    s.saw_queue_after_rec = false
    s.reconnect_watch_start_time = os.clock()
    AL.log("Наблюдатель: ожидание входа (20/35 сек)")

    local ok, err = pcall(function()
        local start_time = os.clock()
        while true do
            local deadline = (s.saw_loading_after_rec and 35) or 20
            if os.clock() - start_time >= deadline then break end
            wait(500)
            if not s.reconnect_watch_active then return end
        end
    end)
    if not ok then
        AL.log("Ошибка наблюдателя: " .. tostring(err))
    end

    if s.saw_loading_after_rec or s.saw_queue_after_rec then
        s.reconnect_watch_active = false
        s.reconnect_watch_start_time = 0
        s.reconnect_watch_retries = 0
        return
    end
    if s.login_submitted or s.is_spawned then
        s.reconnect_watch_active = false
        s.reconnect_watch_start_time = 0
        s.reconnect_watch_retries = 0
        return
    end

    s.reconnect_watch_retries = (s.reconnect_watch_retries or 0) + 1
    s.reconnect_watch_active = false
    s.reconnect_watch_start_time = 0
    if s.reconnect_watch_retries <= 3 then
        AL.log("Наблюдатель: завис после реконнекта, повторный реконнект (" .. tostring(s.reconnect_watch_retries) .. "/3)")
        s.is_reconnecting = false
        emulate_reconnect_ui_cleanup()
        M.do_fast_reconnect(2)
        wait(800)
        if s.login_submitted or s.is_spawned then
            s.reconnect_watch_retries = 0
            return
        end
        start_reconnect_watch()
    else
        AL.log("Наблюдатель: 3 повтора - остановка")
        s.reconnect_watch_retries = 0
    end
end

start_reconnect_internal = function(reason, seconds)
    local s = AL.state
    seconds = tonumber(seconds) or 1
    
    if s.is_reconnecting then
        AL.log("start_reconnect: уже в процессе, пропуск")
        return
    end
    if os.clock() < s.reconnect_cooldown_until then
        AL.log("start_reconnect: кулдаун")
        return
    end
    if os.clock() < s.reconnect_pause_until then
        AL.log("start_reconnect: пауза 5 минут")
        return
    end

    s.reconnect_attempt_count = s.reconnect_attempt_count + 1
    if s.reconnect_attempt_count >= 3 then
        AL.log("3 попытки - пауза 5 мин")
        s.reconnect_pause_until = os.clock() + 300
        s.reconnect_attempt_count = 0
        return
    end

    s.force_password_form = false
    s.password_form_closed = true
    s.is_logging_in = false
    s.login_submitted = false
    s.is_reconnecting = true
    s.is_spawned = false
    s.reconnect_watch_active = false

    AL.chat_msg("{FF3333}Переподключение...")
    emulate_reconnect_ui_cleanup()
    M.do_fast_reconnect(seconds)
    lua_thread.create(start_reconnect_watch)
end

post_loading_login_watch = function()
    local s = AL.state
    AL.log("Наблюдатель: ожидание входа 30 сек")
    local start_time = os.clock()
    while os.clock() - start_time < 30 do
        wait(500)
        if utils.game_window_active() and s.is_spawned then
            AL.log("Наблюдатель: вход выполнен")
            s.reconnect_watch_retries = 0
            return
        end
    end
    AL.log("Наблюдатель: таймаут 30с - вход не выполнен, реконнект")
    if not s.is_spawned and not s.login_submitted then
        mark_manual_reconnect("PostLoadingStuck")
    end
end

mark_manual_reconnect = function(reason, seconds)
    local s = AL.state
    AL.log("mark_manual_reconnect: " .. tostring(reason))
    start_reconnect_internal(reason, seconds)
end

mark_queue_seen = function(source)
    local s = AL.state
    s.saw_queue_after_rec = true
    AL.log("Наблюдатель: очередь (" .. tostring(source) .. ")")
end

function M.trigger_reconnect(reason)
    local s = AL.state
    AL.log("trigger: " .. tostring(reason) .. " реконнект=" .. tostring(s.is_reconnecting))
    start_reconnect_internal(reason, 1)
end

function M.register_commands()
    sampRegisterChatCommand("rec", function(arg)
        M.do_fast_reconnect(tonumber(arg) or 1)
    end)
    sampRegisterChatCommand("mrec", function(arg)
        if tonumber(arg) then M.do_fast_reconnect(tonumber(arg)) end
    end)
    sampRegisterChatCommand("fastrec", function()
        local s = AL.state
        s.fast_reconnect_enabled = not s.fast_reconnect_enabled
        M.apply_fast_reconnect_patch()
        AL.chat_msg("Быстрый реконнект: " .. (s.fast_reconnect_enabled and "ON" or "OFF"))
    end)
end

M._internal = {
    in_close_menu_emul_window = function() return in_close_menu_emul_window() end,
    finish_reconnect = function(r) finish_reconnect(r) end,
    emulate_loading_close_auth = function() emulate_loading_close_auth() end,
    emulate_close_menu_pause = function(t) emulate_close_menu_pause(t) end,
    emulate_reconnect_ui_cleanup = function() emulate_reconnect_ui_cleanup() end,
    mark_manual_reconnect = function(r, sec) mark_manual_reconnect(r, sec) end,
    mark_queue_seen = function(s) mark_queue_seen(s) end,
    post_loading_login_watch = function() post_loading_login_watch() end,
    start_reconnect_watch = function() start_reconnect_watch() end,
    handle_auth_limit_cef = M.handle_auth_limit_cef,
    start_reconnect_internal = function(r, sec) start_reconnect_internal(r, sec) end,
}

return M

