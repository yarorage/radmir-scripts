-- AutoLoginByYaroRage v2.14.5
-- Автор: YaroRage
script_name("AutoLoginByYaroRage")
script_author("YaroRage")
script_version("2.14.5")

require 'moonloader'
local ffi = require('ffi')

-- Fallback для sampfuncs/samp.events
local sampfuncs_ok, sampfuncs = pcall(require, 'lib.sampfuncs')
if not sampfuncs_ok then
    sampfuncs = {}
    function sampfuncs.writeMemory(...) return false end
    function sampfuncs.readMemory(...) return 0 end
    print("[AutoLogin] sampfuncs not available, using fallback")
end

local sampevents_ok, sampevents = pcall(require, 'lib.samp.events')
if not sampevents_ok then
    sampevents = {}
    setmetatable(sampevents, {
        __index = function(_, key)
            return function(...) end
        end
    })
    print("[AutoLogin] lib.samp.events not available, using fallback")
end

ffi.cdef[[
    void keybd_event(unsigned char bVk, unsigned char bScan, unsigned long dwFlags, unsigned long long dwExtraInfo);
    void mouse_event(unsigned long dwFlags, unsigned long dx, unsigned long dy, unsigned long dwData, long long dwExtraInfo);
    int SetForegroundWindow(void* hWnd);
    int SetCursorPos(int X, int Y);
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow();
    int IsIconic(void* hwnd);
    short GetAsyncKeyState(int vKey);
    short GetKeyState(int nVirtKey);
    unsigned long GetKeyboardLayout(unsigned long idThread);
    unsigned long GetWindowThreadProcessId(void* hWnd, unsigned long* lpdwProcessId);
    void* LoadKeyboardLayoutA(const char* pwszKLID, unsigned long Flags);
    void* ActivateKeyboardLayout(void* hkl, unsigned long Flags);
    int OpenClipboard(void* hWndNewOwner);
    int EmptyClipboard();
    int CloseClipboard();
    void* GetClipboardData(unsigned int uFormat);
    void* SetClipboardData(unsigned int uFormat, void* hMem);
    int IsClipboardFormatAvailable(unsigned int format);
    unsigned long long GlobalAlloc(unsigned int uFlags, unsigned long long dwBytes);
    void* GlobalLock(unsigned long long hMem);
    int GlobalUnlock(unsigned long long hMem);
    int PlaySoundA(const char* pszSound, void* hmod, unsigned long fdwSound);
    int mciSendStringA(const char* lpstrCommand, char* lpstrReturnString, unsigned int uReturnLength, void* hwndCallback);
    int PostMessageA(void* hWnd, unsigned int Msg, unsigned long long wParam, long long lParam);
    int MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char* lpMultiByteStr, int cbMultiByte, wchar_t* lpWideCharStr, int cchWideChar);
    int WideCharToMultiByte(unsigned int CodePage, unsigned long dwFlags, const wchar_t* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, const char* lpDefaultChar, int* lpUsedDefaultChar);
    unsigned int GetDpiForSystem();
    int GetSystemMetrics(int nIndex);
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
local restore_mod = require("AutoLoginByYaroRage.restore")
local ui_mod = require("AutoLoginByYaroRage.ui")

local s = AL.state
s.config_folder = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\config"
s.config_file = s.config_folder .. "\\AutoLoginSettings.ini"
s.AUTH_SOUND_PATH = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\resource\\authSound.mp3"
s.AUTH_SOUND1_PATH = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\resource\\authSound1.mp3"
s.AUTH_SOUND2_PATH = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\resource\\authSound2.mp3"

if not doesDirectoryExist(s.config_folder) then
    createDirectory(s.config_folder)
end

local reconnect_keywords = {
    "лимит на подключение", "запрещено на сервере", "time limit", "disconnected",
    "античит", "anti-cheat", "anti cheat", "блокировка", "читер", "cheat",
    "много попыток", "превышение лимит", "too many", "limit", "attempts", "try again",
    "заблокирован", "вы забанены", "были забанены", "аккаунт забанен",
    "забанили", "забанил", "выдал бан", "получил бан", "бан навсегда",
    "банлист", "бан-лист", "block", "banned",
}

local queue_keywords = {
    "ваша позиция", "position in queue", "queue position", "стоите в очереди",
    "waiting for", "подождите", "estimated time", "потребуется секунд",
    "players ahead", "статус позиции", "your position", "ваша позиция",
}

local function should_reconnect_text(text)
    local lower = text:lower()
    for _, kw in ipairs(reconnect_keywords) do
        if lower:find(kw) then return true end
    end
    return false
end

local function parse_queue_info(text)
    local lower = text:lower()
    local updated = false
    
    -- Pattern: "Position in queue: 5" or "ваша позиция: 5" or "Queue: 5/100"
    local pos = lower:match("position in queue%s*:?%s*(%d+)") 
        or lower:match("ваша позиция%s*:?%s*(%d+)")
        or lower:match("queue%s*:?%s*(%d+)%s*/")
        or lower:match("your position%s*:?%s*(%d+)")
        or lower:match("ваша позиция%s*:?%s*(%d+)")
    if pos then
        s.queue_position = tonumber(pos) or 0
        updated = true
    end
    
    -- Pattern: "Estimated time: 5 min" or "потребуется секунд: 5"
    local eta = lower:match("estimated time%s*:?%s*(%d+)")
        or lower:match("потребуется секунд%s*:?%s*(%d+)")
    if eta then
        s.queue_eta = tonumber(eta) or 0
        updated = true
    end
    
    -- Pattern: "5/100 players ahead" or "players ahead: 5"
    local total = lower:match("(%d+)%s*/%s*(%d+)%s*players ahead")
        or lower:match("players ahead%s*:?%s*(%d+)")
    if total then
        s.queue_total = tonumber(total) or 0
        updated = true
    end
    
    if updated then
        s.queue_detected = true
        AL.log(string.format("Queue: pos=%d eta=%d total=%d", s.queue_position, s.queue_eta, s.queue_total))
    end
end

-- CEF-диалоги, которые нужно закрывать И триггерить реконнект
-- ДО логина (s.is_spawned == false):
local close_cef_before_login_keywords = {
    "лимит попыток",      -- Лимит попыток авторизации
    "limit attempts",     -- Limit attempts
    "too many attempts",  -- Too many attempts
    "попыток исчерпан",   -- Попыток исчерпано
    "time limit",         -- Time limit
    "время авторизации",  -- Время авторизации
    "auth time limit",    -- Auth time limit
    "time expired",       -- Time expired
    "timeout",            -- Timeout
}

-- В ЛЮБОЕ время (даже после спавна):
local close_cef_anytime_keywords = {
    "anti-cheat",         -- Anti-cheat
    "anti cheat",         -- Anti cheat
    "античит",            -- Античит
    "анти-чит",           -- Анти-чит
    "cheat detected",     -- Cheat detected
    "forbidden",          -- Forbidden
    "запрещен",           -- Запрещен
    "banned",             -- Banned
}

local function should_close_cef_before_login(text)
    local lower = text:lower()
    for _, kw in ipairs(close_cef_before_login_keywords) do
        if lower:find(kw) then return kw end
    end
    return nil
end

local function should_close_cef_anytime(text)
    local lower = text:lower()
    -- Команды конфигурации интерфейса (updateConfiguration*) не являются диалогами
    if lower:find("updateconfiguration") then return nil end
    for _, kw in ipairs(close_cef_anytime_keywords) do
        if lower:find(kw) then return kw end
    end
    return nil
end

function sampevents.onServerMessage(color, text)
    local lower_text = text:lower()

    local wait_match = lower_text:match("подождите%s+(%d+)%s+секунд")
    if wait_match then
        s.pending_server_wait_seconds = tonumber(wait_match) or 0
        AL.log("Сервер просит подождать " .. tostring(s.pending_server_wait_seconds) .. " сек. ждём реконнект")
    end

    if (not s.saw_queue_after_rec) and (
        lower_text:find("вы не подключены к")
        or (lower_text:find("подождите") and lower_text:find("подключения"))
        or lower_text:find("в очереди")
    ) then
        reconnect_mod._internal.mark_queue_seen("chat")
    end

    if lower_text:find("the server is restarting")
        or lower_text:find("сервер перезагружается")
        or lower_text:find("подключение к серверу") then
        s.is_spawned = false
        s.is_logging_in = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
        s.pending_autologin = true
    end

    admin_det.handle_admin_kick(text, "чат")
    
    parse_queue_info(text)

    if lower_text:find("не удалось подключиться")
        or lower_text:find("потеря соединения")
        or lower_text:find("разрыв соединения")
        or lower_text:find("вы отключены от сервера")
        or lower_text:find("connection lost")
        or lower_text:find("server closed the connection")
        or lower_text:find("lost connection to the server") then
        s.is_spawned = false
        s.player_in_world = false
        s.is_logging_in = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
        AL.log("разрыв соединения: " .. text:sub(1, 80))
        if s.pending_server_wait_seconds > 0 then
            local wait_sec = s.pending_server_wait_seconds
            s.pending_server_wait_seconds = 0
            AL.log("Ожидание /rec " .. tostring(wait_sec))
            reconnect_mod._internal.mark_manual_reconnect("WaitRequest", wait_sec)
        else
            reconnect_mod.trigger_reconnect("DisconnectText")
        end
        return
    end


    if lower_text:find("unacceptable nickname")
        or lower_text:find("choose another nick")
        or lower_text:find("use only a-z") then
        AL.log("ник отклонён, реконнект: " .. text:sub(1, 80))
        reconnect_mod.trigger_reconnect("NickReject")
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
        AL.log("connection reject (" .. text:sub(1, 80) .. ")")
        auth.schedule_autologin_after_reconnect()
    end

    if should_reconnect_text(text) and not s.is_reconnecting and not s.is_spawned then
        AL.log("Обнаружен-реконнект: " .. text:sub(1, 80))
        reconnect_mod.trigger_reconnect("ChatReconnect")
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
    if s.restore_active then
        AL.log("Восстановление позиции: пользователь ответил вручную (dialogId=" .. dialogId .. ", button=" .. button .. ")")
        restore_mod.reset()
    end
end

function sampevents.onServerJoin()
    s.is_spawned = false
    s.player_in_world = false
    s.is_logging_in = false
    s.waiting_for_spawn_choice = false
    s.spawn_timer_seconds = 0
    s.spawn_timer_running = false
    restore_mod.reset()
    s.pending_autologin = true
    s.last_login_attempt = 0
    AL.log("onServerJoin")
    auth.schedule_autologin_after_reconnect()

    if s.password ~= "" and not s.force_password_form then
        lua_thread.create(function()
            for attempt = 1, 6 do
                wait(2000)
                if s.is_spawned or not s.script_active or s.password == "" then return end
                if not s.is_logging_in then
                    AL.log(string.format("onServerJoin: вход #%d", attempt))
                    s.last_login_attempt = 0
                    auth._internal.perform_login()
                end
            end
        end)
    end
end

function sampevents.onConnectionClosed()
    AL.log("onConnectionClosed")
    if s.is_reconnecting then return end
    s.is_spawned = false
    s.player_in_world = false
    s.is_logging_in = false
    s.waiting_for_spawn_choice = false
    s.spawn_timer_seconds = 0
    s.spawn_timer_running = false
    reconnect_mod.trigger_reconnect("ConnectionClosed")
end

function sampevents.onConnectionLost()
    AL.log("onConnectionLost")
    if s.is_reconnecting then return end
    s.is_spawned = false
    s.player_in_world = false
    s.is_logging_in = false
    s.waiting_for_spawn_choice = false
    s.spawn_timer_seconds = 0
    s.spawn_timer_running = false
    reconnect_mod.trigger_reconnect("ConnectionLost")
end

function onReceivePacket(id, bs)
    if id == 32 or id == 33 then
        if s.is_reconnecting then return true end
    end


    local len = raknetBitStreamGetNumberOfBytesUsed(bs)
    local pkt_log = string.format("[PKT] id=%d size=%d", id, len)

    local text = ""
    local max_len = math.min(len, 4096)
    for i = 1, max_len do
        local ok_byte, byte = pcall(raknetBitStreamReadInt8, bs)
        if not ok_byte then break end
        if byte >= 32 and byte <= 255 then
            text = text .. string.char(byte)
        end
    end
    raknetBitStreamResetReadPointer(bs)

    local is_real = s.cef_emul_depth == 0

    -- Детект диалога «Восстановление позиции»
    if id == 215 then
        restore_mod.handle_received(id, text, is_real)
    end

    -- Универсальный детектор авторизации: AuthorizationS/A/B/C/...
    -- Собираем букву вида и полный HEX пакета для диагностики.
    local auth_kind = nil
    local auth_letter = nil
    if id == 215 and text:find('Authorization', 1, true) then
        auth_letter = text:match('Authorization([%a_]+)')
        if auth_letter then
            auth_kind = "Authorization" .. auth_letter
            s.cef_auth_kind = auth_letter
        end
    end
    local auth_hex = ""
    if auth_kind then
        local hex_n = raknetBitStreamGetNumberOfBytesUsed(bs)
        if hex_n and hex_n > 0 then
            local parts = {}
            for i = 1, hex_n do
                local ok_b, b = pcall(raknetBitStreamReadInt8, bs)
                parts[i] = string.format("%02X", ok_b and b or 0)
            end
            auth_hex = table.concat(parts, " ")
        end
        raknetBitStreamResetReadPointer(bs)
    end

    if id == 215 and auth_kind then
        AL.log(pkt_log .. " CEF-AUTH[" .. auth_kind .. "] HEX: " .. auth_hex)
    elseif id == 215 then
        AL.log(pkt_log .. " CEF: " .. text:sub(1, 300))
    elseif id == 61 then
        AL.log(pkt_log .. " DIALOG: " .. text:sub(1, 300))
    elseif text:find('Authorization') then
        AL.log(pkt_log .. " AUTH: " .. text:sub(1, 300))
    elseif id == 6 or id == 32 or id == 33 or id == 34 or id == 35 then
        AL.log(pkt_log)
    end

    if id == 215 then
        local should_handle = false

        local matched_anytime = should_close_cef_anytime(text)
        if matched_anytime then
            should_handle = true
            AL.log("CEF anti-cheat dialog (anytime), kw=" .. matched_anytime .. ": " .. text:sub(1, 200))
        elseif not s.is_spawned then
            local matched_before = should_close_cef_before_login(text)
            if matched_before then
                should_handle = true
                AL.log("CEF limit dialog (before login), kw=" .. matched_before .. ": " .. text:sub(1, 200))
            end
        end

        if should_handle then
            s.cef_limit_seen = true
            reconnect_mod._internal.handle_auth_limit_cef()
            return true
        end
    end

    if text:find('Authorization') and text:find('"auth"') then
        if is_real then
            s.cef_auth_window_seen = true
            s.cef_loading_seen = false
            -- Парсим позицию CEF-окна авторизации из пакета
            local cef_x = text:match('"x"%s*:%s*([%d%.]+)')
            local cef_y = text:match('"y"%s*:%s*([%d%.]+)')
            local cef_w = text:match('"width"%s*:%s*([%d%.]+)')
            local cef_h = text:match('"height"%s*:%s*([%d%.]+)')
            if cef_x and cef_y and cef_w and cef_h then
                utils.update_cef_auth_pos(tonumber(cef_x), tonumber(cef_y), tonumber(cef_w), tonumber(cef_h))
            end
        end
        local parsed = text:match('"auth"%s*,%s*"([^"]+)')
        if parsed and #parsed > 0 then
            if s.my_nick ~= parsed then
                s.my_nick = parsed
                AL.log("Ник: " .. s.my_nick)
            end
            if s.password ~= "" then
                s.force_password_form = false
                s.password_form_closed = true
            end
            s.is_logging_in = false
            if s.is_reconnecting then
                reconnect_mod._internal.finish_reconnect("Authorization")
            end
            if s.password ~= "" and not s.is_spawned and not s.login_submitted then
                AL.log("Authorization: пройдена")
                utils.play_auth_sounds_if_needed()
                auth._internal.perform_login()
            end
        end
    end

    admin_det.handle_admin_kick(text, "пакет")

    -- CONNECTION REJECTED / Unacceptable NickName (пакет CEF/другое) -> /rec 3
    if text:find("CONNECTION REJECTED") or text:find("Unacceptable NickName") then
        AL.log("Пакет: CONNECTION REJECTED (NickName), выполняю /rec 3")
        reconnect_mod.do_fast_reconnect(3)
    end

    if text:find('OnPlayerOpenMenuPause', 1, true) then
        if is_real then
            s.cef_open_menu_pause_seen = true
        end
        s.saw_menu_pause_after_esc = true
        if not s.login_submitted and not s.is_spawned and not s.is_logging_in then
            if reconnect_mod._internal.in_close_menu_emul_window() then
                local now = os.clock()
                if (now - s.last_close_menu_emul) >= 0.15 then
                    s.last_close_menu_emul = now
                    lua_thread.create(function()
                        wait(50)
                        if not s.login_submitted and not s.is_spawned and not s.is_logging_in then
                            reconnect_mod._internal.emulate_close_menu_pause(1)
                        end
                    end)
                end
            end
        end
    end

    if text:find('OnPlayerCloseMenuPause', 1, true) and is_real then
        s.cef_close_menu_pause_seen = true
        s.cef_open_menu_pause_seen = false
    end

    if text:find('GameText') and (text:find('~y~') or text:find('Загрузка') or text:find('загрузка')) then
        if text:find('Загрузка') or text:find('загрузка') or text:find('Loading') then
            if is_real then
                s.cef_loading_seen = true
            end
            s.saw_loading_after_rec = true
            lua_thread.create(reconnect_mod._internal.post_loading_login_watch)
        end
    end

    if text:find('Loading') and text:find('3000') and is_real then
        s.cef_loading_seen = true
        s.saw_loading_after_rec = true
        if s.is_logging_in or s.is_spawned then return end
    end

    if text:find('setPlayerNickName')
        or text:find('игрок авторизован')
        or text:find('setPlayerConnectedStatus') then
        if is_real then
            s.cef_world_entered_seen = true
            s.cef_auth_window_seen = false
        end
        s.is_spawned = true
        s.player_in_world = true
        s.reconnect_watch_active = false
        AL.log("Вход в мир (setPlayerNickName/игрок авторизован)")
    end

    -- Вход в мир по CEF-маркерам интерфейса (после реконнекта сервер
    -- не шлёт setPlayerNickName, а возвращает игрока сразу командами интерфейса)
    if text:find('resetMapDynamicCategories', 1, true)
        or text:find('QuestsTalks', 1, true)
        or text:find('updateHungerLevel', 1, true)
        or text:find('removeVoiceChatEntry', 1, true) then
        if s.reconnect_watch_active and not s.is_spawned then
            s.is_spawned = true
            s.player_in_world = true
            s.reconnect_watch_active = false
            if s.is_reconnecting then
                reconnect_mod._internal.finish_reconnect("CEFWorldEnter")
            end
            AL.log("Вход в мир (CEF-интерфейс, реконнект)")
        end
    end

    if text:find('SelectSpawn') and (text:find('Выбор') or text:find('Выберите')) then
        if is_real then
            s.cef_spawn_select_seen = true
        end
        s.waiting_for_spawn_choice = true
        local dialog_id = text:match('SelectSpawn%s+(%d+)')
        if dialog_id then
            s.current_dialog_id = tonumber(dialog_id)
        else
            s.current_dialog_id = 0
        end
    end

    local is_wrong = text:find('неверный пароль') or text:find('неправильный пароль')
    if is_wrong then
        if is_real then
            s.cef_wrong_password_seen = true
        end
        AL.log("неверный пароль")
        s.force_password_form = true
        s.password_form_closed = false
        utils.play_auth_sounds_if_needed()
        ui_mod.setError("ошибка авторизации")
    end
    return true
end

function onWindowMessage(msg, wparam, lparam)
    if (msg == 0x0100 or msg == 0x0104) and wparam == 0x7A then
        reconnect_mod._internal.mark_manual_reconnect("F11", 3)
    end

    -- Кнопка «Изменить» в таймере восстановления позиции
    if s.restore_active and msg == 0x0201 then
        local x = bit.band(lparam, 0xFFFF)
        local y = bit.band(bit.rshift(lparam, 16), 0xFFFF)
        restore_mod.handle_click(x, y)
    end

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
        local ctrl_down = (user32.GetAsyncKeyState(0x11) < 0) or (bit.band(user32.GetKeyState(0x11), 0x8000) ~= 0)
        if msg == 0x0100 then
            if wparam == 0x08 then
                ui_mod.handle_backspace()
            elseif wparam == 0x0D then
                ui_mod.handle_enter()
            elseif wparam == 0x56 and ctrl_down then
                local ok_cb, cb = pcall(utils.get_clipboard_text)
                if not ok_cb or not cb then cb = "" end
                if #cb == 0 then
                    local ok_img, cb_img = pcall(ui_mod.get_clipboard_imgui)
                    if ok_img and cb_img and #cb_img > 0 then cb = cb_img end
                end
                if #cb > 0 then
                    if #ui_mod.PF.temp_password + #cb > 32 then
                        cb = cb:sub(1, 32 - #ui_mod.PF.temp_password)
                    end
                    ui_mod.handle_paste(cb)
                else
                    AL.log("Вставка: буфер обмена пуст")
                end
            elseif wparam == 0x43 and ctrl_down then
                ui_mod.handle_copy()
            end
        elseif msg == 0x0102 then
            local is_cv = (wparam == 0x56 or wparam == 0x76 or wparam == 0x43 or wparam == 0x63)
            if not (ctrl_down and is_cv) then
                if wparam >= 32 and wparam <= 126 and #ui_mod.PF.temp_password < 32 then
                    ui_mod.handle_char_input(string.char(wparam))
                end
            end
        end
    end
end

local function handle_cef_tx_packet(bs)
    local s = AL.state
    if not bs then return end
    local ok_len, len = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not ok_len or not len or len < 14 then return end
    local text = ""
    local max_n = math.min(len, 512)
    for i = 1, max_n do
        local ok_b, byte = pcall(raknetBitStreamReadInt8, bs)
        if not ok_b then break end
        if byte and byte >= 32 and byte <= 255 then
            text = text .. string.char(byte)
        end
    end
    raknetBitStreamResetReadPointer(bs)

    if text:find('OnPlayerDeviceLost', 1, true) then
        s.cef_device_lost_seen = true
        if not s.is_spawned and (s.is_reconnecting or s.is_logging_in or s.login_submitted) then
            AL.log("CEF-TX OnPlayerDeviceLost: сброс эмуляции CEF (без /rec)")
            s.cef_emul_depth = 0
            s.cef_loading_seen = false
            s.cef_auth_window_seen = false
            s.cef_open_menu_pause_seen = false
            s.cef_close_menu_pause_seen = false
            s.cef_world_entered_seen = false
            s.cef_spawn_select_seen = false
            s.cef_wrong_password_seen = false
            s.saw_loading_after_rec = false
            s.saw_queue_after_rec = false
            s.login_submitted = false
        end
        return
    end
    if text:find('EndedInitializeBrowser', 1, true) or text:find('OnPlayerDeviceRestore', 1, true) then
        s.cef_device_restore_seen = true
        s.cef_browser_initialized = true
        s.reconnect_watch_retries = 0
        AL.log("CEF-TX браузер жив: счётчик зависаний сброшен")
        if not s.is_spawned and not s.is_logging_in and not s.login_submitted and s.password ~= "" then
            AL.log("CEF-TX браузер жив: повторный автологин")
            auth.schedule_autologin_after_reconnect()
        end
        return
    end
    if text:find('MainMenu_OnPlayerOpen', 1, true) then
        AL.log("CEF-TX MainMenu открыто (оверлей) — флаги не трогаю")
        return
    end
    if s.cef_tx_log_enabled then
        AL.log("CEF-TX: " .. text:sub(1, 80))
    end
end

function onSendPacket(id, bs, priority, reliability, orderingChannel)
    if id == 215 then
        handle_cef_tx_packet(bs)
    end
    return true
end

local function timer_render_thread()
    local k = utils.get_ui_scale()
    local r_font = renderCreateFont("Arial", math.floor(14 * k + 0.5), 13)
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
                local msg_str = string.format("Anti-AFK: %s (Ctrl 1.5? /mafk)", status_str)
                local m_w = renderGetFontDrawTextLength(r_font, msg_str)
                local pad = math.floor(12 * k)
                local m_box_w = m_w + pad * 2
                local m_x = math.floor((sw - m_box_w) / 2)
                local m_y = math.floor(sh * 0.70)
                renderDrawBox(m_x - pad, m_y - math.floor(6 * k), m_box_w, math.floor(26 * k), 0xB0000000)
                renderFontDrawText(r_font, msg_str, m_x + math.floor((m_box_w - pad * 2 - m_w) / 2), m_y, 0xFFFFFFFF)
            end
            if s.waiting_for_spawn_choice and s.spawn_timer_seconds > 0 then
                local sw, sh = getScreenResolution()
                local text_str = string.format("Спавн: авто-выбор через %d сек.", s.spawn_timer_seconds)
                local text_w = renderGetFontDrawTextLength(r_font, text_str)
                local pad = math.floor(12 * k)
                local box_w = text_w + pad * 2
                local posX = math.floor((sw - box_w) / 2)
                local posY = 20
                renderDrawBox(posX - pad, posY - math.floor(6 * k), box_w, math.floor(28 * k), 0xCC000000)
                renderFontDrawText(r_font, text_str, posX + math.floor((box_w - pad * 2 - text_w) / 2), posY, 0xFFFFFF00)
            end
            restore_mod.render(r_font, k)
        end
    end
end

function main()
    while not isSampAvailable() do wait(100) end

    config.load()
    reconnect_mod.apply_fast_reconnect_patch()

    if s.password ~= "" then
        AL.chat_msg("Скрипт активен. Пароль: {33FF33}установлен{FFFFFF}. /alhelp")
    else
        AL.chat_msg("Скрипт активен. Пароль: {FF3333}не установлен{FFFFFF}.")
        s.force_password_form = true
        s.password_form_closed = false
        utils.play_auth_sounds_if_needed()
    end

    AL.log("Пароль: " .. (s.password ~= "" and "да" or "нет"))

    register_commands()
    reconnect_mod.register_commands()
    antiafk.register_commands()
    telegram.register_commands()

    lua_thread.create(auth.chatlog_parser_thread)
    lua_thread.create(timer_render_thread)
    lua_thread.create(auth._internal.login_worker_thread)
    lua_thread.create(antiafk.anti_afk_thread)
    lua_thread.create(antiafk.mafk_hotkey_thread)
    lua_thread.create(function()
        local cursor_was_on = false
        local cursor_saved = false
        while true do
            wait(100)
            local form_visible = auth.is_password_form_visible()
            if form_visible then
                if not cursor_saved then
                    -- Save cursor state: 0 = hidden, 1 = visible
                    s.cursor_was_visible = isCursorActive and isCursorActive() or false
                    cursor_saved = true
                end
                showCursor(true)
                cursor_was_on = true
            elseif cursor_was_on then
                showCursor(s.cursor_was_visible and true or false)
                cursor_was_on = false
                cursor_saved = false
            end
        end
    end)

    if s.tg_enabled then
        lua_thread.create(telegram.poll_thread)
    end

    -- Health/Armor monitoring thread
    lua_thread.create(function()
        local last_heal = 0
        local last_armor = 0
        while true do
            wait(100)
            if s.auto_heal_enabled or s.auto_armor_enabled then
                if not isCharDead(PLAYER_PED) then
                
                local hp = getCharHealth(PLAYER_PED)
                local armor = getCharArmour(PLAYER_PED)
                local now = os.clock() * 1000
                
                if s.auto_heal_enabled and hp < s.heal_threshold then
                    if now - last_heal > s.heal_cooldown then
                        setCharHealth(PLAYER_PED, math.min(s.heal_amount, 200))
                        last_heal = now
                        AL.log("Auto-heal: HP " .. hp .. " -> " .. math.min(s.heal_amount, 200))
                    end
                end
                
                if s.auto_armor_enabled and armor < s.armor_threshold then
                    if now - last_armor > s.heal_cooldown then
                        addArmourToChar(PLAYER_PED, s.armor_amount)
                        last_armor = now
                        AL.log("Auto-armor: Armor " .. armor .. " -> " .. math.min(armor + s.armor_amount, 100))
                    end
                end
                end
            end
        end
    end)

    -- ImGui render thread
    lua_thread.create(function()
        while true do
            wait(0)
            ui_mod.draw_settings_menu()
        end
    end)

    -- Auto-update check thread
    lua_thread.create(function()
        while true do
            wait(300000) -- 5 minutes
            utils.check_for_updates()
        end
    end)

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

    -- /al - открыть ImGui меню настроек
    sampRegisterChatCommand("al", function()
        ui_mod.toggle_settings()
    end)

    sampRegisterChatCommand("mspawn", function()
        s.spawn_choice = not s.spawn_choice
        AL.chat_msg("авто-выбор спавна: " .. (s.spawn_choice and "{33FF33}да" or "{FF3333}нет"))
    end)

    sampRegisterChatCommand("alogin", function()
        s.script_active = not s.script_active
        AL.chat_msg("Скрипт: " .. (s.script_active and "{33FF33}Вкл" or "{FF3333}Выкл"))
    end)

    sampRegisterChatCommand("autostart", function()
        s.auto_restart = not s.auto_restart
        AL.chat_msg("Автозапуск: " .. (s.auto_restart and "{33FF33}Вкл" or "{FF3333}Выкл"))
    end)

    sampRegisterChatCommand("alstatus", function()
        local s = AL.state
        AL.chat_msg("=== AutoLogin Status ===")
        AL.chat_msg("Login state: " .. tostring(s.login_state or "IDLE"))
        AL.chat_msg("Script active: " .. (s.script_active and "{33FF33}YES" or "{FF3333}NO"))
        AL.chat_msg("Has password: " .. (s.password ~= "" and "{33FF33}YES" or "{FF3333}NO"))
        AL.chat_msg("Is spawned: " .. (s.is_spawned and "{33FF33}YES" or "{FF3333}NO"))
        AL.chat_msg("Reconnecting: " .. (s.is_reconnecting and "{FF3333}YES" or "{33FF33}NO"))
        AL.chat_msg("Reconnect attempts: " .. tostring(s.reconnect_attempt_count))
        AL.chat_msg("Anti-AFK: " .. (s.mafk_active and "{33FF33}ON" or "{FF3333}OFF"))
        AL.chat_msg("Telegram: " .. (s.tg_enabled and "{33FF33}ON" or "{FF3333}OFF"))
        AL.chat_msg("Discord: " .. (#s.discord_webhook > 0 and "{33FF33}Set" or "{FF3333}Not set"))
        AL.chat_msg("Admin names: " .. (#s.admin_names > 0 and table.concat(s.admin_names, ", ") or "none"))
        if s.queue_detected then
            AL.chat_msg("Queue: pos=" .. tostring(s.queue_position) .. " eta=" .. tostring(s.queue_eta) .. "min total=" .. tostring(s.queue_total))
        end
    end)

    sampRegisterChatCommand("queue", function()
        local s = AL.state
        if s.queue_detected then
            AL.chat_msg("=== Queue Info ===")
            AL.chat_msg("Position: " .. tostring(s.queue_position))
            AL.chat_msg("ETA: " .. tostring(s.queue_eta) .. " min")
            AL.chat_msg("Total ahead: " .. tostring(s.queue_total))
        else
            AL.chat_msg("{FF3333}No queue detected")
        end
    end)

    sampRegisterChatCommand("profile", function(arg)
        local s = AL.state
        if not arg or #arg == 0 then
            AL.chat_msg("=== Profiles ===")
            AL.chat_msg("Current: " .. s.current_profile)
            for _, name in ipairs(AL.list_profiles()) do
                local mark = (name == s.current_profile) and " > " or "   "
                local prof = s.profiles[name]
                AL.chat_msg(mark .. name .. " (pass: " .. (prof.password ~= "" and "set" or "none") .. ")")
            end
            AL.chat_msg("Usage: /profile <name> - switch")
            AL.chat_msg("       /profile new <name> - create")
            AL.chat_msg("       /profile del <name> - delete")
            AL.chat_msg("       /profile save - save current")
            return
        end
        
        local args = {}
        for w in arg:gmatch("%S+") do table.insert(args, w) end
        local cmd = args[1]:lower()
        
        if cmd == "new" and args[2] then
            if s.profiles[args[2]] then
                AL.chat_msg("{FF3333}Profile already exists")
            else
                s.profiles[args[2]] = {password = "", nick = ""}
                AL.chat_msg("{33FF33}Profile created: " .. args[2])
            end
        elseif cmd == "del" and args[2] then
            if args[2] == "default" then
                AL.chat_msg("{FF3333}Cannot delete default profile")
            elseif s.profiles[args[2]] then
                AL.delete_profile(args[2])
                config.save()
                AL.chat_msg("{33FF33}Profile deleted: " .. args[2])
            else
                AL.chat_msg("{FF3333}Profile not found")
            end
        elseif cmd == "save" then
            AL.save_current_profile()
            config.save()
            AL.chat_msg("{33FF33}Profile saved: " .. s.current_profile)
        elseif s.profiles[cmd] then
            AL.set_active_profile(cmd)
            config.save()
            AL.chat_msg("{33FF33}Switched to profile: " .. cmd)
        else
            AL.chat_msg("{FF3333}Unknown profile or command")
        end
    end)

    sampRegisterChatCommand("dwebhook", function(arg)
        local s = AL.state
        if not arg or #arg == 0 then
            AL.chat_msg("Usage: /dwebhook <url> - Set Discord webhook")
            AL.chat_msg("       /dwebhook test - Test webhook")
            AL.chat_msg("       /dwebhook clear - Clear webhook")
            return
        end
        
        if arg == "test" then
            if #s.discord_webhook > 0 then
                local telegram = require("AutoLoginByYaroRage.telegram")
                local ok = telegram.discord_send(s.discord_webhook, "Test from AutoLoginByYaroRage", {{title="Test", description="Discord webhook working!", color=3447003}})
                AL.chat_msg(ok and "{33FF33}Discord test sent!" or "{FF3333}Failed to send test")
            else
                AL.chat_msg("{FF3333}No webhook set")
            end
        elseif arg == "clear" then
            s.discord_webhook = ""
            config.save()
            AL.chat_msg("{33FF33}Discord webhook cleared")
        else
            s.discord_webhook = arg
            config.save()
            AL.chat_msg("{33FF33}Discord webhook set")
        end
    end)

    sampRegisterChatCommand("dstatus", function()
        local s = AL.state
        AL.chat_msg("Discord: " .. (#s.discord_webhook > 0 and "{33FF33}Set" or "{FF3333}Not set"))
    end)

    sampRegisterChatCommand("adminshot", function(arg)
        local s = AL.state
        if not arg or #arg == 0 then
            AL.chat_msg("Admin screenshot: " .. (s.auto_screenshot_admin and "{33FF33}ON" or "{FF3333}OFF"))
            return
        end
        
        if arg == "on" then
            s.auto_screenshot_admin = true
            config.save()
            AL.chat_msg("{33FF33}Admin screenshot ON")
        elseif arg == "off" then
            s.auto_screenshot_admin = false
            config.save()
            AL.chat_msg("{FF3333}Admin screenshot OFF")
        else
            AL.chat_msg("Usage: /adminshot [on|off]")
        end
    end)

    sampRegisterChatCommand("autoheal", function(arg)
        local s = AL.state
        if not arg or #arg == 0 then
            AL.chat_msg("Auto-heal: " .. (s.auto_heal_enabled and "{33FF33}ON" or "{FF3333}OFF") .. " (threshold: " .. s.heal_threshold .. "%)")
            AL.chat_msg("Auto-armor: " .. (s.auto_armor_enabled and "{33FF33}ON" or "{FF3333}OFF") .. " (threshold: " .. s.armor_threshold .. "%)")
            AL.chat_msg("Cooldown: " .. s.heal_cooldown .. "ms")
            return
        end
        
        local args = {}
        for w in arg:gmatch("%S+") do table.insert(args, w) end
        local cmd = args[1]:lower()
        
        if cmd == "heal" then
            s.auto_heal_enabled = not s.auto_heal_enabled
            config.save()
            AL.chat_msg("Auto-heal: " .. (s.auto_heal_enabled and "{33FF33}ON" or "{FF3333}OFF"))
        elseif cmd == "armor" then
            s.auto_armor_enabled = not s.auto_armor_enabled
            config.save()
            AL.chat_msg("Auto-armor: " .. (s.auto_armor_enabled and "{33FF33}ON" or "{FF3333}OFF"))
        elseif cmd == "threshold" and args[2] then
            local val = tonumber(args[2])
            if val and val >= 10 and val <= 100 then
                s.heal_threshold = val
                config.save()
                AL.chat_msg("Heal threshold: " .. val .. "%")
            else
                AL.chat_msg("Threshold must be 10-100")
            end
        elseif cmd == "armorthreshold" and args[2] then
            local val = tonumber(args[2])
            if val and val >= 10 and val <= 100 then
                s.armor_threshold = val
                config.save()
                AL.chat_msg("Armor threshold: " .. val .. "%")
            else
                AL.chat_msg("Threshold must be 10-100")
            end
        elseif cmd == "cooldown" and args[2] then
            local val = tonumber(args[2])
            if val and val >= 1000 and val <= 30000 then
                s.heal_cooldown = val
                config.save()
                AL.chat_msg("Cooldown: " .. val .. "ms")
            else
                AL.chat_msg("Cooldown must be 1000-30000ms")
            end
        else
            AL.chat_msg("Usage: /autoheal [heal|armor|threshold <val>|armorthreshold <val>|cooldown <ms>]")
        end
    end)

    sampRegisterChatCommand("updatecheck", function()
        AL.chat_msg("Проверка обновлений...")
        utils.check_for_updates()
    end)

    sampRegisterChatCommand("loglevel", function(arg)
        local s = AL.state
        if not arg or #arg == 0 then
            local levels = {"DEBUG", "INFO", "WARN", "ERROR"}
            AL.chat_msg("Log level: " .. levels[(s.log_level or 2) + 1])
            AL.chat_msg("File logging: " .. (s.log_to_file and "{33FF33}ON" or "{FF3333}OFF"))
            return
        end
        
        local levels = {debug=0, info=1, warn=2, error=3}
        local level = levels[arg:lower()]
        if level then
            utils.set_log_level(level)
            AL.chat_msg("Log level set to " .. arg:upper())
        elseif arg == "file" then
            s.log_to_file = not s.log_to_file
            config.save()
            AL.chat_msg("File logging: " .. (s.log_to_file and "{33FF33}ON" or "{FF3333}OFF"))
        else
            AL.chat_msg("Usage: /loglevel [debug|info|warn|error|file]")
        end
    end)

    sampRegisterChatCommand("runtests", function()
        AL.chat_msg("Запуск тестов...")
        utils.run_tests()
    end)

    sampRegisterChatCommand("alhelp", function()
        AL.chat_msg("=== AutoLogin Commands ===")
        AL.chat_msg("/setpass <pass> - Set password")
        AL.chat_msg("/alogin - Toggle script")
        AL.chat_msg("/mspawn - Toggle auto-spawn")
        AL.chat_msg("/mafk - Toggle Anti-AFK")
        AL.chat_msg("/afk [mix/1-11] - Set AFK mode")
        AL.chat_msg("/fk - Toggle Anti-Ticket")
        AL.chat_msg("/autostart - Toggle auto-restart")
        AL.chat_msg("/rec <sec> - Fast reconnect")
        AL.chat_msg("/fastrec - Toggle fast reconnect patch")
        AL.chat_msg("/tg <token> <chat_id> - Setup Telegram")
        AL.chat_msg("/tgadmin <name> - Add/remove admin")
        AL.chat_msg("/tgstatus - Telegram status")
        AL.chat_msg("/tgtest - Test Telegram")
        AL.chat_msg("/dwebhook <url> - Set Discord webhook")
        AL.chat_msg("/dwebhook test - Test Discord webhook")
        AL.chat_msg("/dwebhook clear - Clear Discord webhook")
        AL.chat_msg("/dstatus - Discord status")
        AL.chat_msg("/queue - Show queue info")
        AL.chat_msg("/adminshot [on|off] - Admin screenshot")
        AL.chat_msg("/autoheal [heal|armor|threshold <val>|armorthreshold <val>|cooldown <ms>] - Auto-heal/armor")
        AL.chat_msg("/updatecheck - Check for updates")
        AL.chat_msg("/loglevel [debug|info|warn|error|file] - Log level")
        AL.chat_msg("/runtests - Run unit tests")
        AL.chat_msg("/alstatus - Show status")
        AL.chat_msg("/al - Open ImGui settings")
        AL.chat_msg("/profile [name|new <name>|del <name>|save] - Profiles")
        AL.chat_msg("/alhelp - This help")
    end)
end

