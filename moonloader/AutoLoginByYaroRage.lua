-- AutoLoginByYaroRage v2.0
-- Автоматический вход, Anti-AFK, Telegram, Реконнект
-- Автор: YaroRage
script_name("AutoLoginByYaroRage")
script_author("YaroRage")
script_version("2.0")

require 'moonloader'
require 'lib.sampfuncs'
local sampevents = require('lib.samp.events')
local ffi = require('ffi')

ffi.cdef[[
    void keybd_event(unsigned char bVk, unsigned char bScan, unsigned long dwFlags, unsigned long long dwExtraInfo);
    void mouse_event(unsigned long dwFlags, unsigned long dx, unsigned long dy, unsigned long dwData, long long dwExtraInfo);
    int SetCursorPos(int X, int Y);
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow();
    int IsIconic(void* hwnd);
    short GetAsyncKeyState(int vKey);
    short GetKeyState(int nVirtKey);
    unsigned long GetKeyboardLayout(unsigned long idThread);
    void* LoadKeyboardLayoutA(const char* pwszKLID, unsigned int Flags);
    int ActivateKeyboardLayout(void* hkl, unsigned int Flags);
    unsigned long GetWindowThreadProcessId(void* hWnd, unsigned long* lpdwProcessId);
    int MessageBeep(unsigned int uType);
    int OpenClipboard(void* hWndNewOwner);
    int EmptyClipboard();
    int CloseClipboard();
    void* GetClipboardData(unsigned int uFormat);
    void* SetClipboardData(unsigned int uFormat, void* hMem);
    int IsClipboardFormatAvailable(unsigned int format);
    unsigned long long GlobalAlloc(unsigned int uFlags, unsigned long long dwBytes);
    void* GlobalLock(unsigned long long hMem);
    int GlobalUnlock(unsigned long long hMem);
    unsigned long long GlobalFree(unsigned long long hMem);
    int PlaySoundA(const char* pszSound, void* hmod, unsigned long fdwSound);
    int mciSendStringA(const char* lpstrCommand, char* lpstrReturnString, unsigned int uReturnLength, void* hWndCallback);
]]

user32 = ffi.load("user32")
winmm = ffi.load("winmm")
kernel32 = ffi.load("kernel32")

local AL = require("AutoLoginByYaroRage.state")
local config = require("AutoLoginByYaroRage.config")
local utils = require("AutoLoginByYaroRage.utils")
local reconnect_mod = require("AutoLoginByYaroRage.reconnect")
local auth = require("AutoLoginByYaroRage.auth")
local antiafk = require("AutoLoginByYaroRage.antiafk")
local telegram = require("AutoLoginByYaroRage.telegram")
local admin_det = require("AutoLoginByYaroRage.admin_detection")
local ui_mod = require("AutoLoginByYaroRage.ui")

local s = AL.state
s.config_folder = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\config"
s.config_file = s.config_folder .. "\\AutoLoginSettings.ini"
s.AUTH_SOUND_PATH = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\resource\\authSound.mp3"

if not doesDirectoryExist(s.config_folder) then
    createDirectory(s.config_folder)
end

function sampevents.onServerMessage(color, text)
    local lower_text = text:lower()

    if (not s.saw_queue_after_rec) and (
        lower_text:find("вы не подключены к")
        or (lower_text:find("подождите") and lower_text:find("подключения"))
        or lower_text:find("в очереди")
    ) then
        reconnect_mod._internal.mark_queue_seen("chat")
    end

    if lower_text:find("the server is restarting")
        or lower_text:find("сервер перезагружается")
        or lower_text:find("подключение к серверу")
        or lower_text:find("connecting")
        or lower_text:find("connecting to") then
        s.is_spawned = false
        s.is_logging_in = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
        s.pending_autologin = true
    end

    admin_det.handle_admin_kick(text, "чат")

    if s.is_reconnecting then return end

    if lower_text:find("не удалось подключиться")
        or lower_text:find("потеря соединения")
        or lower_text:find("разрыв соединения")
        or lower_text:find("connection lost")
        or lower_text:find("server closed the connection")
        or lower_text:find("lost connection to the server") then
        s.is_spawned = false
        s.player_in_world = false
        s.is_logging_in = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
        AL.log("Потеря соединения: " .. text:sub(1, 80))
        reconnect_mod.trigger_reconnect()
        return
    end

    if lower_text:find("connection reject")
        or lower_text:find("ошибка подключения")
        or lower_text:find("неверный пароль")
        or lower_text:find("неправильный пароль") then
        s.is_spawned = false
        s.player_in_world = false
        s.is_logging_in = false
        s.login_submitted = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
        s.pending_autologin = true
        s.saw_queue_after_rec = true
        s.reconnect_watch_active = false
        AL.log("connection reject на этапе авторизации (" .. text:sub(1, 80) .. ")")
        auth.schedule_autologin_after_reconnect()
    end

    if s.tg_enabled and admin_det.is_admin_message(color, text) then
        local safe_text = text:gsub("<[^>]+>", ""):sub(1, 500)
        telegram.send_message("[Admin] " .. safe_text)
    end
end

function sampevents.onSendDialogResponse(dialogId, button, listboxId, input)
    if s.waiting_for_spawn_choice and dialogId == s.current_dialog_id then
        if button == 0 or button == 1 then
            s.waiting_for_spawn_choice = false
            s.spawn_timer_seconds = 0
            s.is_spawned = true
            s.player_in_world = true
        end
    end
end

function sampevents.onServerJoin()
    s.is_spawned = false
    s.player_in_world = false
    s.is_logging_in = false
    s.waiting_for_spawn_choice = false
    s.spawn_timer_seconds = 0
    s.spawn_timer_running = false
    s.pending_autologin = true
    s.last_login_attempt = 0
    AL.log("onServerJoin - переподключение")
    auth.schedule_autologin_after_reconnect()

    if s.password ~= "" and not s.force_password_form then
        lua_thread.create(function()
            for attempt = 1, 6 do
                local wait_remaining = 2.0
                local last_t = os.clock()
                while wait_remaining > 0 do
                    wait(200)
                    if utils.game_window_active() then
                        local now = os.clock()
                        wait_remaining = wait_remaining - (now - last_t)
                    end
                    last_t = os.clock()
                    if s.is_spawned or not s.script_active or s.password == "" then return end
                end
                if s.is_spawned or not s.script_active or s.password == "" then return end
                if not s.is_logging_in then
                    AL.log(string.format("onServerJoin: попытка входа #%d", attempt))
                    s.last_login_attempt = 0
                    auth._internal.perform_login()
                end
            end
        end)
    end
end

function sampevents.onConnectionClosed()
    AL.log("sampevents.onConnectionClosed (packet 32)")
    if s.is_reconnecting then return end
    s.is_spawned = false
    s.player_in_world = false
    s.is_logging_in = false
    s.waiting_for_spawn_choice = false
    s.spawn_timer_seconds = 0
    reconnect_mod.trigger_reconnect()
end

function sampevents.onConnectionLost()
    AL.log("sampevents.onConnectionLost (packet 33)")
    if s.is_reconnecting then return end
    s.is_spawned = false
    s.player_in_world = false
    s.is_logging_in = false
    s.waiting_for_spawn_choice = false
    s.spawn_timer_seconds = 0
    reconnect_mod.trigger_reconnect()
end

function onConnectionClosed()
    AL.log("onConnectionClosed (global)")
    if s.is_reconnecting then return end
    s.is_spawned = false
    s.player_in_world = false
    s.is_logging_in = false
    s.waiting_for_spawn_choice = false
    s.spawn_timer_seconds = 0
    reconnect_mod.trigger_reconnect()
end

function onReceivePacket(id, bs)
    if id == 32 or id == 33 then
        AL.log(string.format("Пакет id=%d", id))
        if s.is_reconnecting then
            AL.log("Пакет при реконнекте - пропуск")
            return
        end
        s.is_spawned = false
        s.player_in_world = false
        s.is_logging_in = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
        reconnect_mod.trigger_reconnect()
        return
    end

    local antiafk_result = antiafk.on_receive_packet(id, bs)
    if antiafk_result == false then return false end

    local text = ""
    local len = raknetBitStreamGetNumberOfBytesUsed(bs)
    for i = 1, len do
        local byte = raknetBitStreamReadInt8(bs)
        if byte >= 32 and byte <= 255 then
            text = text .. string.char(byte)
        end
    end
    raknetBitStreamResetReadPointer(bs)

    if #s.my_nick == 0 and text:find('Authorization') and text:find('"auth"') then
        local parsed = text:match('"auth"%s*,%s*"([^"]+)')
        if parsed then
            s.my_nick = parsed
            AL.log("Наш ник из AuthorizationT: " .. s.my_nick)
        end
    end

    admin_det.handle_admin_kick(text, "пакет")

    if text:find('OnPlayerOpenMenuPause', 1, true) then
        if s.login_submitted or s.is_spawned or s.is_logging_in then
            AL.log("OnPlayerOpenMenuPause ignored")
        elseif reconnect_mod._internal.in_close_menu_emul_window() then
            local now = os.clock()
            if (now - s.last_close_menu_emul) >= 0.15 then
                s.last_close_menu_emul = now
                AL.log("OnPlayerOpenMenuPause -> emulate CloseMenuPause")
                lua_thread.create(function()
                    wait(50)
                    if s.login_submitted or s.is_spawned or s.is_logging_in then return end
                    reconnect_mod._internal.emulate_close_menu_pause(1)
                end)
            else
                AL.log("OnPlayerOpenMenuPause ignored (debounce)")
            end
        end
    end

    if text:find('GameText') and (text:find('загрузка') or text:find('~y~')) then
        if text:find('загрузка') or text:find('Loading') then
            s.saw_loading_after_rec = true
            s.reconnect_watch_active = false
            AL.log("Пакет загрузки/GameText - watchdog стоп")
            lua_thread.create(reconnect_mod._internal.post_loading_login_watch)
        end
    end
    if text:find('~y~загрузка') or (text:find('Загрузка') and text:find('10000')) then
        s.saw_loading_after_rec = true
        s.reconnect_watch_active = false
        AL.log("Пакет загрузки - watchdog стоп")
        lua_thread.create(reconnect_mod._internal.post_loading_login_watch)
    end

    if text:find('Loading') and text:find('3000') then
        s.saw_loading_after_rec = true
        if s.is_logging_in then
            AL.log("Loading[3000] не вход, пропуск")
            return
        end
        if s.is_spawned then
            AL.log("Loading[3000] в игре, пропуск")
            return
        end
        AL.log("Loading[3000] на входе")
    end

    if text:find('Spawn') or text:find('spawn') then
        s.is_spawned = true
        s.player_in_world = true
    end

    if text:find('SelectSpawn') and (text:find('Выбор') or text:find('Выберите')) then
        AL.log("SelectSpawn: спавн-меню")
        s.waiting_for_spawn_choice = true
        s.current_dialog_id = 0
    end

    local is_wrong = text:find('Неверный пароль') or text:find('Неправильный пароль')
    if is_wrong then
        AL.log("CEF: неверный пароль")
        s.force_password_form = true
        s.password_form_closed = false
        ui_mod.setError("Ошибка авторизации, введите пароль")
    end

    if text:find('Authorize') or text:find('auth') then
        if text:find('Введите пароль')
            or text:find('Ваш пароль')
            or text:find('Дата рождения')
            or text:find('авторизации') then
            AL.log("CEF-форма авторизации")
            if s.password ~= "" and not s.is_logging_in then
                auth._internal.perform_login()
            end
        end
    end

    if text:find('Выбор спавна') then
        s.is_spawned = true
        s.player_in_world = true
        AL.log("Игрок заспавнен")
    end
end

function onWindowMessage(msg, wparam, lparam)
    if (msg == 0x0100 or msg == 0x0104) and wparam == 0x7A then
        reconnect_mod._internal.mark_manual_reconnect("F11")
    end

    -- ESC не закрывает форму авторизации (см. ui.lua)

    if s.waiting_for_spawn_choice then
        if msg == 0x0100 or msg == 0x0104 then
            if wparam == 0x0D or wparam == 0x1B then
                s.waiting_for_spawn_choice = false
                s.spawn_timer_seconds = 0
                s.is_spawned = true
                s.player_in_world = true
            end
        elseif msg == 0x0201 then
            s.waiting_for_spawn_choice = false
            s.spawn_timer_seconds = 0
            s.is_spawned = true
            s.player_in_world = true
        end
    end

    if auth.is_password_form_visible() and ui_mod.PF.input_active then
        local ctrl_down = (user32.GetAsyncKeyState(0x11) < 0)
        if msg == 0x0100 then
            if wparam == 0x08 then
                ui_mod.handle_backspace()
            elseif wparam == 0x0D then
                ui_mod.handle_enter()
            elseif wparam == 0x56 and ctrl_down then
                local ok_cb, cb = pcall(utils.get_clipboard_text)
                if not ok_cb then cb = "" end
                if #cb > 0 then
                    if #ui_mod.PF.temp_password + #cb > 32 then
                        cb = cb:sub(1, 32 - #ui_mod.PF.temp_password)
                    end
                    ui_mod.handle_paste(cb)
                end
            elseif wparam == 0x43 and ctrl_down then
                ui_mod.handle_copy()
            end
        elseif msg == 0x0102 then
            local is_cv = (wparam == 0x56 or wparam == 0x76 or wparam == 0x43 or wparam == 0x63)
            if not (ctrl_down and is_cv) then
                if wparam >= 32 and wparam <= 126 and #ui_mod.PF.temp_password < 32 then
                    ui_mod.handle_char_input(string.char(wparam))
                elseif wparam > 126 and #ui_mod.PF.temp_password < 32 then
                    ui_mod.handle_char_input(string.char(wparam))
                end
            end
        end
    end
end

function onSendPacket(id, bs, priority, reliability, orderingChannel)
    local result = antiafk.on_send_packet(id, bs)
    if result == false then return false end
end

function sampevents.onSendCommand(command)
end

local function timer_render_thread()
    local r_font = renderCreateFont("Arial", 14, 13)
    while true do
        wait(0)
        if auth.is_password_form_visible() then
            s.render_disabled = false
            ui_mod.render()
        elseif s.render_disabled or os.clock() < s.render_disabled_until then
            if os.clock() >= s.render_disabled_until then s.render_disabled = false end
        else
            if os.clock() < s.mafk_notify_until then
                local sw, sh = getScreenResolution()
                local status_str = s.mafk_active and "{33FF33}Вкл" or "{FF3333}Выкл"
                local msg_str = string.format("Anti-AFK: %s (Ctrl 1.5с /mafk)", status_str)
                local m_w = renderGetFontDrawTextLength(r_font, msg_str)
                local m_box_w = m_w + 24
                local m_x = math.floor((sw - m_box_w) / 2)
                local m_y = math.floor(sh * 0.70)
                renderDrawBox(m_x - 12, m_y - 6, m_box_w, 26, 0xB0000000)
                renderFontDrawText(r_font, msg_str, m_x + (m_box_w - 24 - m_w) / 2, m_y, 0xFFFFFFFF)
            end

            if s.waiting_for_spawn_choice and s.spawn_timer_seconds > 0 then
                local sw, sh = getScreenResolution()
                local text_str = string.format("Спавн: авто-выбор через %d сек.", s.spawn_timer_seconds)
                local text_w = renderGetFontDrawTextLength(r_font, text_str)
                local box_w = text_w + 24
                local posX = math.floor((sw - box_w) / 2)
                local posY = 20
                renderDrawBox(posX - 12, posY - 6, box_w, 28, 0xCC000000)
                renderFontDrawText(r_font, text_str, posX + (box_w - 24 - text_w) / 2, posY, 0xFFFFFF00)
            end

            if auth.is_password_form_visible() then
                ui_mod.render()
            end
        end
    end
end

function main()
    while not isSampAvailable() do wait(100) end

    config.load()
    reconnect_mod.apply_fast_reconnect_patch()

    if s.password ~= "" then
        AL.chat_msg("Скрипт активен. Пароль: {33FF33}установлен{FFFFFF}. /alhelp для справки.")
    else
        AL.chat_msg("Скрипт активен. Пароль: {FF3333}не установлен{FFFFFF}. Введите пароль в чат.")
        s.force_password_form = true
        s.password_form_closed = false
    end

    AL.log("Telegram: " .. (s.tg_enabled and "включён" or "не включён"))
    AL.log("Админы: " .. (#s.admin_names > 0 and table.concat(s.admin_names, ", ") or "не заданы"))

    register_commands()
    reconnect_mod.register_commands()
    antiafk.register_commands()
    telegram.register_commands()

    lua_thread.create(auth.chatlog_parser_thread)
    lua_thread.create(timer_render_thread)
    lua_thread.create(antiafk.anti_afk_thread)
    lua_thread.create(antiafk.mafk_hotkey_thread)
    lua_thread.create(function()
        local cursor_was_on = false
        while true do
            wait(100)
            local form_visible = auth.is_password_form_visible()
            if form_visible then
                showCursor(true)
                cursor_was_on = true
            elseif cursor_was_on then
                showCursor(false)
                cursor_was_on = false
            end
        end
    end)

    if s.tg_enabled then
        lua_thread.create(telegram.poll_thread)
    end

    wait(-1)
end

function register_commands()
    sampRegisterChatCommand("setpass", function(arg)
        if not arg or #arg == 0 then
            AL.chat_msg("Использование: /setpass <пароль>")
            return
        end
        s.password = arg
        config.save()
        AL.chat_msg("Пароль установлен.")
    end)

    sampRegisterChatCommand("mspawn", function()
        s.spawn_choice = not s.spawn_choice
        local status = s.spawn_choice and "{33FF33}Да" or "{FF3333}Нет"
        AL.chat_msg("авто-выбор спавна: " .. status)
    end)

    sampRegisterChatCommand("alogin", function()
        s.script_active = not s.script_active
        local status = s.script_active and "{33FF33}Вкл" or "{FF3333}Выкл"
        AL.chat_msg("Скрипт: " .. status)
    end)

    sampRegisterChatCommand("autostart", function()
        s.auto_restart = not s.auto_restart
        local status = s.auto_restart and "{33FF33}Вкл" or "{FF3333}Выкл"
        AL.chat_msg("Автозапуск: " .. status)
    end)

    sampRegisterChatCommand("alhelp", function()
        AL.chat_msg("/setpass <пароль> - установить пароль")
        AL.chat_msg("/alogin - вкл/выкл скрипта")
        AL.chat_msg("/mspawn - вкл/выкл авто-выбора спавна")
        AL.chat_msg("/mafk - вкл/выкл анти-AFK (Ctrl 1.5с)")
        AL.chat_msg("/afk [mix/1-11] - паттерн Anti-AFK")
        AL.chat_msg("/autostart - вкл/выкл автозапуска")
        AL.chat_msg("/tg <token> <chat_id> - настроить Telegram")
        AL.chat_msg("/tgadmin <ник> - добавить/удалить админа")
        AL.chat_msg("/tgstatus - статус Telegram")
        AL.chat_msg("/tgtest - тест Telegram")
        AL.chat_msg("/alhelp - эта справка")
        AL.chat_msg("/rec <сек> - быстрый реконнект")
        AL.chat_msg("/fastrec - вкл/выкл быстрого реконнекта")
        AL.chat_msg("/fk - вкл/выкл Anti-Ticket")
    end)
end
