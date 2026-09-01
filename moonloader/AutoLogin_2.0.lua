--[[
    AutoLogin 2.0 (fixed)
    MoonLoader 0.26-beta5 + SAMPFUNCS + SAMP.Lua
    RADMIR CRMP (CEF)
]]

local ffi = require('ffi')
local sampevents = require('lib.samp.events')

ffi.cdef[[
    void keybd_event(uint8_t bVk, uint8_t bScan, uint32_t dwFlags, uintptr_t dwExtraInfo);
    void mouse_event(uint32_t dwFlags, int32_t dx, int32_t dy, uint32_t dwData, uintptr_t dwExtraInfo);
    int SetCursorPos(int X, int Y);
    void* LoadKeyboardLayoutA(const char* pwszKLID, uint32_t Flags);
    void* ActivateKeyboardLayout(void* hkl, uint32_t Flags);
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow(void);
    uint32_t GetWindowThreadProcessId(void* hWnd, uint32_t* lpdwProcessId);
    int IsIconic(void* hWnd);
    short GetAsyncKeyState(int vKey);
    uint32_t GetKeyboardLayout(uint32_t idThread);
    int MessageBeep(uint32_t uType);
    int PlaySoundA(const char* pszSound, void* hmod, uint32_t fdwSound);
]]

local user32 = ffi.load("user32")
local winmm = ffi.load("winmm")

local KEYEVENTF_KEYDOWN = 0x0
local KEYEVENTF_KEYUP   = 0x2
local MOUSEEVENTF_LEFTDOWN = 0x02
local MOUSEEVENTF_LEFTUP   = 0x04
local SND_ALIAS = 0x00010000
local SND_ASYNC = 0x0001

local script_name = "AutoLogin"
local config_folder = getWorkingDirectory() .. "\\config\\AutoLogin"
local config_file = config_folder .. "\\AutoLoginSettings.ini"

local password = ""
local spawn_choice = true
local script_active = true
local is_logging_in = false
local is_spawned = false
local player_in_world = false
local player_nick = ""
local chatlog_path = nil

local waiting_for_spawn_choice = false
local current_dialog_id = -1
local spawn_timer_seconds = 0
local reconnect_cooldown_until = 0
local pending_autologin = false
local last_login_attempt = 0
local is_reconnecting = false

-- CloseMenuPause эмуляция при открытии OnPlayerOpenMenuPause:
-- окно для авторизации + ещё 5 секунд после входа
local CLOSE_MENU_EMUL_AFTER_SEC = 5
local close_menu_emul_until = 0
local last_close_menu_emul = 0
local login_submitted = false   -- пароль введён в CEF и пакет 215 ждём на вход

local btn_x, btn_y, btn_w, btn_h = 0, 0, 0, 0
local last_lbutton_state = false

local pass_input_active = true
local temp_password = ""
local show_password_chars = true
local force_password_form = false
local password_form_error = ""
local password_form_closed = false
local reconnect_watch_active = false
local reconnect_watch_until = 0
local saw_loading_after_rec = false
local saw_queue_after_rec = false

local pass_btn_x, pass_btn_y, pass_btn_w, pass_btn_h = 0, 0, 0, 0
local pass_field_x, pass_field_y, pass_field_w, pass_field_h = 0, 0, 0, 0
local eye_btn_x, eye_btn_y, eye_btn_w, eye_btn_h = 0, 0, 0, 0
local close_btn_x, close_btn_y, close_btn_w, close_btn_h = 0, 0, 0, 0
local last_pass_lbutton_state = false

local mafk_active = false
local mafk_hold_start = 0
local mafk_notify_until = 0
local auto_restart = true
local function mafk_flag_path()
    local folder = (thisScript and thisScript().folder) or getWorkingDirectory()
    return folder .. "\\..\\mafk_on.flag"
end

local function update_mafk_config()
    if not doesDirectoryExist(config_folder) then createDirectory(config_folder) end
    local content = ""
    if doesFileExist(config_file) then
        local fr = io.open(config_file, "r")
        if fr then content = fr:read("*all") fr:close() end
    end
    local newval = 'MafkEnabled = ' .. tostring(mafk_active)
    if content:find('MafkEnabled%s*=') then
        content = content:gsub('MafkEnabled%s*=%s*%a+', newval)
    else
        content = content .. '\n' .. newval
    end
    local fw = io.open(config_file, "w")
    if fw then fw:write(content) fw:close() end
end

local function sync_mafk_flag()
    if auto_restart and mafk_active then
        local f = io.open(mafk_flag_path(), "w")
        if f then
            f:write("1")
            f:close()
        end
    else
        if doesFileExist(mafk_flag_path()) then
            os.remove(mafk_flag_path())
        end
    end
    update_mafk_config()
end

-- forward declarations
local wait_for_game_focus
local schedule_autologin_after_reconnect
local perform_login
local on_password_saved
local close_password_form
local is_password_form_visible
local mark_queue_seen
local start_reconnect_watch
local mark_manual_reconnect
local emulate_loading_close_auth
local emulate_close_menu_pause
local emulate_reconnect_ui_cleanup
local finish_reconnect
local in_close_menu_emul_window

local ywelcome_status, ywelcome = pcall(require, "ywelcome")
if not ywelcome_status then
    ywelcome_status, ywelcome = pcall(require, "ywelcom")
end

local encoding = require 'encoding'
encoding.default = 'CP1251'

local function log(msg)
    print(string.format("[%s] %s", script_name, msg))
end

in_close_menu_emul_window = function()
    if is_reconnecting then
        return true
    end
    return close_menu_emul_until > 0 and os.clock() < close_menu_emul_until
end

finish_reconnect = function(reason)
    if is_reconnecting then
        close_menu_emul_until = os.clock() + CLOSE_MENU_EMUL_AFTER_SEC
        log("reconnect end (" .. tostring(reason) .. ") — CloseMenu window 5s")
    end
    is_reconnecting = false
end

local function chat_msg(msg)
    sampAddChatMessage(string.format("{FFCC00}[%s] {FFFFFF}%s", script_name, msg), -1)
end

local function get_current_keyboard_layout_name()
    local hwnd = user32.GetForegroundWindow()
    local threadId = user32.GetWindowThreadProcessId(hwnd, nil)
    local hkl = user32.GetKeyboardLayout(threadId)
    local langID = bit.band(tonumber(ffi.cast("uint32_t", hkl)), 0xFFFF)
    if langID == 0x0419 then return "RU"
    elseif langID == 0x0409 then return "EN"
    else return string.format("%04X", langID) end
end

local function is_shift_pressed()
    return (user32.GetAsyncKeyState(0x10) < 0)
end

local function play_gta_confirm_sound()
    winmm.PlaySoundA("SystemAsterisk", nil, bit.bor(SND_ALIAS, SND_ASYNC))
end

is_password_form_visible = function()
    return (password == "" or force_password_form) and not password_form_closed
end

mark_queue_seen = function(source)
    if saw_queue_after_rec then
        return
    end
    saw_queue_after_rec = true
    reconnect_watch_active = false
    log("Очередь на сервер (" .. tostring(source) .. ") — watchdog снят")
end

local function find_chatlog_path()
    local userprofile = os.getenv("USERPROFILE")
    local possible_folders = {"Documents", "Документы"}
    if userprofile then
        for _, folder in ipairs(possible_folders) do
            local path = userprofile .. "\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
            if doesFileExist(path) then return path end
        end
    end
    local drives = {"C", "D", "E", "F", "G", "H"}
    for _, drive in ipairs(drives) do
        for _, folder in ipairs(possible_folders) do
            local path = drive .. ":\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
            if doesFileExist(path) then return path end
        end
    end
    if userprofile then
        for _, folder in ipairs(possible_folders) do
            local default_path = userprofile .. "\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
            if doesDirectoryExist(userprofile .. "\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP") then
                return default_path
            end
        end
    end
    return "D:\\Documents\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
end

local function save_config()
    if not doesDirectoryExist(config_folder) then createDirectory(config_folder) end
    local file = io.open(config_file, "w")
    if file then
        file:write(string.format('Password = "%s"\nSpawnChoice = %s\nScriptActive = %s\nAutoRestart = %s\nMafkEnabled = %s\n', password, tostring(spawn_choice), tostring(script_active), tostring(auto_restart), tostring(mafk_active)))
        file:close()
        log("Конфигурация сохранена.")
    else
        log("Ошибка записи конфига!")
    end
end

local function ensure_config_exists()
    if not doesDirectoryExist(config_folder) then createDirectory(config_folder) end
    local file = io.open(config_file, "w")
    if file then
        file:write('Password = ""\nSpawnChoice = true\nScriptActive = true\nAutoRestart = true\nMafkEnabled = false\n')
        file:close()
    end
end

local function load_config()
    if doesFileExist(config_file) then
        local f = io.open(config_file, "r")
        if f then
            local content = f:read("*all")
            f:close()
            local pass_match = content:match('Password%s*=%s*"(.-)"')
            if pass_match and #pass_match > 0 then
                password = pass_match
                if ywelcome_status and type(ywelcome) == "function" then
                    ywelcome(script_name, "Скрипт запущен. Файл конфигурации с паролем {33FF33}найден{FFFFFF}. Используйте /alhelp для справки.")
                end
            else
                if ywelcome_status and type(ywelcome) == "function" then
                    ywelcome(script_name, "Скрипт запущен. Файл конфигурации с паролем {FF3333}не найден{FFFFFF}. Введите пароль в форме на экране.")
                end
            end
            local spawn_match = content:match('SpawnChoice%s*=%s*(%a+)')
            spawn_choice = (spawn_match ~= "false")
            local active_match = content:match('ScriptActive%s*=%s*(%a+)')
            script_active = (active_match ~= "false")
            local restart_match = content:match('AutoRestart%s*=%s*(%a+)')
            auto_restart = (restart_match ~= "false")
            local mafk_match = content:match('MafkEnabled%s*=%s*(%a+)')
            mafk_active = (mafk_match == "true")
        end
    else
        ensure_config_exists()
        if ywelcome_status and type(ywelcome) == "function" then
            ywelcome(script_name, "Скрипт запущен. Файл конфигурации с паролем {FF3333}не найден{FFFFFF}. Введите пароль в форме на экране.")
        end
    end
end

local function trigger_reconnect()
    local now = os.clock()
    if is_reconnecting then
        log("Реконнект уже идёт — пропуск")
        return
    end
    if now < reconnect_cooldown_until then
        log("Реконнект пропущен (cooldown)")
        return
    end
    reconnect_cooldown_until = now + 25
    is_reconnecting = true
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    login_submitted = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    pending_autologin = true
    chat_msg("{FF3333}Триггер сработал! Выполняем реконнект...")
    log("trigger_reconnect()")
    start_reconnect_watch()

    lua_thread.create(function()
        wait(600)
        pcall(wait_for_game_focus)
        wait(300)

        local ip, port = sampGetCurrentServerAddress()
        local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
        if hwnd ~= nil and user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd then
            user32.keybd_event(0x7A, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x7A, 0, KEYEVENTF_KEYUP, 0)
            log("Реконнект: F11 (один раз). Ждём AuthorizationT, пароль не вводим вслепую.")
            wait(800)
            emulate_reconnect_ui_cleanup()
        elseif ip and port then
            pcall(function() sampDisconnectWithReason(false) end)
            wait(1000)
            sampConnectToServer(ip, port)
            log("Реконнект: sampConnectToServer")
            wait(800)
            emulate_reconnect_ui_cleanup()
        else
            sampSendChat("/rec 3")
            log("Реконнект: /rec 3")
            wait(800)
            emulate_reconnect_ui_cleanup()
        end

        wait(60000)
        if is_reconnecting then
            finish_reconnect("timeout 60s")
        end
    end)
end

local function register_commands()
    sampRegisterChatCommand("setpass", function(arg)
        if arg:len() == 0 then
            chat_msg("Использование: /setpass <пароль>")
            return
        end
        password = arg
        save_config()
        chat_msg("Пароль успешно установлен.")
        on_password_saved()
    end)

    sampRegisterChatCommand("mspawn", function()
        spawn_choice = not spawn_choice
        save_config()
        local status = spawn_choice and "{33FF33}Да (Enter)" or "{FF3333}Нет (Esc)"
        chat_msg("Переключить спавн на точке выхода: " .. status)
    end)

    sampRegisterChatCommand("alogin", function()
        script_active = not script_active
        save_config()
        local status = script_active and "{33FF33}Включен" or "{FF3333}Выключен"
        chat_msg("Автологин: " .. status)
    end)

    sampRegisterChatCommand("mafk", function()
        mafk_active = not mafk_active
        mafk_notify_until = os.clock() + 4
        play_gta_confirm_sound()
        if mafk_active then
            player_in_world = true
        end
        local status = mafk_active and "{33FF33}Включен" or "{FF3333}Выключен"
        chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} режим: " .. status)
        sync_mafk_flag()
    end)

    sampRegisterChatCommand("autostart", function()
        auto_restart = not auto_restart
        save_config()
        local status = auto_restart and "{33FF33}Включен" or "{FF3333}Выключен"
        chat_msg("Автозапуск игры при mafk: " .. status)
        sync_mafk_flag()
    end)

    sampRegisterChatCommand("alhelp", function()
        chat_msg("Список команд скрипта:")
        chat_msg("/setpass <пароль> — установить пароль для входа")
        chat_msg("/alogin — включить или выключить автологин")
        chat_msg("/mspawn — переключить спавн на точке выхода")
        chat_msg("/mafk — включить/выключить анти-AFK (или удержание прав. Ctrl 1.5с)")
        chat_msg("/autostart — включить/выключить автозапуск игры при активном mafk")
        chat_msg("/alhelp — показать эту справку")
    end)
end

local function click_password_field()
    local screen_w, screen_h = getScreenResolution()
    local target_x = math.floor(screen_w * 0.20)
    local target_y = math.floor(screen_h * 0.76)

    user32.SetCursorPos(target_x, target_y)
    wait(50)
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    wait(50)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
    wait(50)
end

wait_for_game_focus = function()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    if hwnd ~= nil then
        while true do
            if user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd then
                break
            end
            wait(500)
        end
    end
end

local function clear_input_field()
    click_password_field()
    wait(200)
    user32.keybd_event(0x11, 0, KEYEVENTF_KEYDOWN, 0)
    wait(50)
    user32.keybd_event(0x41, 0, KEYEVENTF_KEYDOWN, 0)
    wait(50)
    user32.keybd_event(0x41, 0, KEYEVENTF_KEYUP, 0)
    user32.keybd_event(0x11, 0, KEYEVENTF_KEYUP, 0)
    wait(100)
    user32.keybd_event(0x08, 0, KEYEVENTF_KEYDOWN, 0)
    wait(50)
    user32.keybd_event(0x08, 0, KEYEVENTF_KEYUP, 0)
    wait(200)
end

local function type_password()
    local shift_map = {
        ['!'] = 0x31, ['@'] = 0x32, ['#'] = 0x33, ['$'] = 0x34, ['%'] = 0x35,
        ['^'] = 0x36, ['&'] = 0x37, ['*'] = 0x38, ['('] = 0x39, [')'] = 0x30,
        ['_'] = 0xBD, ['+'] = 0xBB, ['{'] = 0xDB, ['}'] = 0xDD, ['|'] = 0xDC,
        [':'] = 0xBA, ['"'] = 0xDE, ['<'] = 0xBC, ['>'] = 0xBE, ['?'] = 0xBF,
        ['~'] = 0xC0,
    }
    local normal_map = {
        ['-'] = 0xBD, ['='] = 0xBB, ['['] = 0xDB, [']'] = 0xDD, ['\\'] = 0xDC,
        [';'] = 0xBA, ["'"] = 0xDE, [','] = 0xBC, ['.'] = 0xBE, ['/'] = 0xBF,
        ['`'] = 0xC0, [' '] = 0x20,
    }
    for i = 1, #password do
        local ch = password:sub(i, i)
        local vkey = 0
        local needs_shift = false
        if ch >= 'a' and ch <= 'z' then
            vkey = string.byte(ch) - 32
        elseif ch >= 'A' and ch <= 'Z' then
            vkey = string.byte(ch)
            needs_shift = true
        elseif ch >= '0' and ch <= '9' then
            vkey = string.byte(ch)
        elseif shift_map[ch] then
            vkey = shift_map[ch]
            needs_shift = true
        elseif normal_map[ch] then
            vkey = normal_map[ch]
        end
        if vkey ~= 0 then
            if needs_shift then
                user32.keybd_event(0x10, 0, KEYEVENTF_KEYDOWN, 0)
                wait(25)
            end
            user32.keybd_event(vkey, 0, KEYEVENTF_KEYDOWN, 0)
            wait(30)
            user32.keybd_event(vkey, 0, KEYEVENTF_KEYUP, 0)
            wait(30)
            if needs_shift then
                user32.keybd_event(0x10, 0, KEYEVENTF_KEYUP, 0)
                wait(25)
            end
        end
        wait(40)
    end
end

emulate_loading_close_auth = function()
    if is_spawned or login_submitted or is_logging_in then
        log("Loading[3000] пропуск (уже вход/выход)")
        return
    end
    local ok, err = pcall(function()
        local bs = raknetNewBitStream()
        local bytes = {
            2, 0, 4, 0, 0, 0, 2,
            7, 0, 0, 0, 76, 111, 97, 100, 105, 110, 103,
            6, 0, 0, 0, 91, 51, 48, 48, 48, 93
        }
        for i = 1, #bytes do
            raknetBitStreamWriteInt8(bs, bytes[i])
        end
        raknetEmulPacketReceiveBitStream(215, bs)
        raknetDeleteBitStream(bs)
    end)
    if ok then
        log("Эмуляция Loading[3000] x1 (reconnect)")
    else
        log("Эмуляция Loading[3000] ошибка: " .. tostring(err))
    end
end

emulate_close_menu_pause = function(times)
    if is_spawned or login_submitted then
        log("CloseMenuPause пропуск (уже вход/выход)")
        return
    end
    times = times or 1
    local ok, err = pcall(function()
        for n = 1, times do
            local bs = raknetNewBitStream()
            local bytes = {
                2, 0, 0, 0, 0, 0,
                22, 0, 0, 0,
                79, 110, 80, 108, 97, 121, 101, 114, 67, 108, 111, 115, 101, 77, 101, 110, 117, 80, 97, 117, 115, 101,
                0, 0, 0, 0
            }
            for i = 1, #bytes do
                raknetBitStreamWriteInt8(bs, bytes[i])
            end
            raknetEmulPacketReceiveBitStream(215, bs)
            raknetDeleteBitStream(bs)
            if n < times then
                wait(80)
            end
        end
    end)
    if ok then
        log("Эмуляция OnPlayerCloseMenuPause x" .. tostring(times))
    else
        log("Эмуляция OnPlayerCloseMenuPause ошибка: " .. tostring(err))
    end
end

emulate_reconnect_ui_cleanup = function()
    emulate_loading_close_auth()
end

start_reconnect_watch = function()
    reconnect_watch_active = true
    reconnect_watch_until = os.clock() + 20
    saw_loading_after_rec = false
    saw_queue_after_rec = false
    log("Watchdog реконнекта: 20 сек (ждём Загрузка / очередь)")
    lua_thread.create(function()
        while reconnect_watch_active and os.clock() < reconnect_watch_until do
            wait(500)
            if saw_loading_after_rec or saw_queue_after_rec or is_spawned or login_submitted then
                reconnect_watch_active = false
                log("Watchdog: ок (загрузка/очередь/спавн/вход) — F11 не нужен")
                return
            end
        end
        if reconnect_watch_active
            and not saw_loading_after_rec
            and not saw_queue_after_rec
            and not is_spawned
            and not login_submitted
            and not is_logging_in then
            reconnect_watch_active = false
            log("Watchdog: 20с без загрузки и без очереди — принудительный F11")
            is_spawned = false
            is_logging_in = false
            lua_thread.create(function()
                if login_submitted or is_spawned then return end
                pcall(wait_for_game_focus)
                wait(200)
                local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
                if hwnd ~= nil then
                    user32.keybd_event(0x7A, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(50)
                    user32.keybd_event(0x7A, 0, KEYEVENTF_KEYUP, 0)
                    log("Watchdog: F11 отправлен")
                    wait(800)
                    if login_submitted or is_spawned then return end
                    emulate_reconnect_ui_cleanup()
                end
                is_spawned = false
                pending_autologin = true
                start_reconnect_watch()
            end)
        else
            reconnect_watch_active = false
        end
    end)
end

mark_manual_reconnect = function(reason)
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    login_submitted = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    pending_autologin = true
    last_login_attempt = 0
    close_menu_emul_until = os.clock() + CLOSE_MENU_EMUL_AFTER_SEC
    log("Ручной реконнект (" .. tostring(reason) .. ") — is_spawned=false")
    start_reconnect_watch()
    lua_thread.create(function()
        wait(800)
        emulate_reconnect_ui_cleanup()
    end)
end

on_password_saved = function()
    is_spawned = false
    is_logging_in = false
    pending_autologin = true
    last_login_attempt = 0
    force_password_form = false
    password_form_error = ""
    password_form_closed = true
    log("Пароль сохранён — пробуем автовход в открытую CEF-форму")
    lua_thread.create(function()
        wait(300)
        if not is_spawned and password ~= "" and script_active then
            perform_login()
        end
        for i = 1, 2 do
            wait(2000)
            if is_spawned or password == "" or not script_active then return end
            if not is_logging_in then
                log("Повтор автовхода после установки пароля #" .. tostring(i))
                perform_login()
            end
        end
    end)
end

close_password_form = function()
    local retry_old_password = (force_password_form or password_form_error ~= "") and password ~= ""
    password_form_closed = true
    force_password_form = false
    password_form_error = ""
    pass_input_active = false
    temp_password = ""
    log("Закрываем форму ввода пароля")
    if retry_old_password and script_active then
        log("Пробуем войти старым паролем, если он уже был сохранён")
        last_login_attempt = 0
        is_logging_in = false
        login_submitted = false
        is_spawned = false
        pending_autologin = true
        lua_thread.create(function()
            wait(400)
            if not is_spawned and password ~= "" and script_active then
                perform_login()
            end
        end)
    end
end

perform_login = function()
    if not script_active then return end
    if password == "" then
        log("perform_login: пароль пустой")
        return
    end
    if is_logging_in then
        log("perform_login: уже идёт ввод")
        return
    end
    if is_spawned then
        log("perform_login: is_spawned=true, выход")
        return
    end
    local now = os.clock()
    if now - last_login_attempt < 2.5 then
        log("perform_login: антиспам")
        return
    end
    last_login_attempt = now
    is_logging_in = true
    pending_autologin = false
    close_menu_emul_until = 0
    reconnect_watch_active = false
    log("Ввод пароля...")

    lua_thread.create(function()
        pcall(wait_for_game_focus)
        wait(1200)
        if is_spawned then
            is_logging_in = false
            return
        end
        local hkl = user32.LoadKeyboardLayoutA("00000409", 1)
        if hkl ~= nil then
            user32.ActivateKeyboardLayout(hkl, 0)
        end
        wait(300)
        clear_input_field()
        wait(200)
        type_password()
        wait(200)
        user32.keybd_event(0x0D, 0, KEYEVENTF_KEYDOWN, 0)
        wait(30)
        user32.keybd_event(0x0D, 0, KEYEVENTF_KEYUP, 0)
        login_submitted = true
        close_menu_emul_until = 0
        reconnect_watch_active = false
        log("Пароль введен. CEF-пакет 215 ждём для входа в игру")
        wait(600)
        is_logging_in = false
    end)
end

schedule_autologin_after_reconnect = function()
    pending_autologin = true
    is_spawned = false
    is_logging_in = false
    log("schedule: ждём пакет AuthorizationT[auth] (без слепого ввода)")
    lua_thread.create(function()
        for i = 1, 40 do
            if is_spawned or not script_active then
                pending_autologin = false
                return
            end
            wait(1000)
        end
        pending_autologin = false
        log("schedule: timeout ожидания формы")
    end)
end

function sampevents.onServerMessage(color, text)
    local lower_text = text:lower()
    if (not saw_queue_after_rec) and (
        lower_text:find("нет свободных мест")
        or (lower_text:find("очеред") and lower_text:find("сервер"))
        or lower_text:find("в очереди")
    ) then
        mark_queue_seen("chat")
    end
    if lower_text:find("the server is restarting")
        or lower_text:find("подключение к")
        or lower_text:find("присоединились к")
        or lower_text:find("подключились")
        or lower_text:find("connecting to") then
        is_spawned = false
        is_logging_in = false
        waiting_for_spawn_choice = false
        spawn_timer_seconds = 0
        pending_autologin = true
    end
    if is_reconnecting then return end
    if lower_text:find("вы отключены от сервера")
        or lower_text:find("соединение потеряно")
        or lower_text:find("соединение разорвано")
        or lower_text:find("connection lost")
        or lower_text:find("server closed the connection")
        or lower_text:find("lost connection to the server") then
        is_spawned = false
        player_in_world = false
        is_logging_in = false
        waiting_for_spawn_choice = false
        spawn_timer_seconds = 0
        log("Дисконнект по сообщению чата: " .. text:sub(1, 80))
        trigger_reconnect()
    end
end

function sampevents.onSendDialogResponse(dialogId, button, listboxId, input)
    if waiting_for_spawn_choice and dialogId == current_dialog_id then
        if button == 0 or button == 1 then
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            is_spawned = true
            player_in_world = true
        end
    end
end

function onReceivePacket(id, bs)
    if id == 32 or id == 33 then
        log(string.format("Дисконнект-пакет id=%d", id))
        if is_reconnecting then
            log("Игнор пакета дисконнекта — идёт реконнект")
            return
        end
        is_spawned = false
        player_in_world = false
        is_logging_in = false
        waiting_for_spawn_choice = false
        spawn_timer_seconds = 0
        trigger_reconnect()
        return
    end

    local text = ""
    local len = raknetBitStreamGetNumberOfBytesUsed(bs)
    for i = 1, len do
        local byte = raknetBitStreamReadInt8(bs)
        if byte >= 32 and byte <= 255 then
            text = text .. string.char(byte)
        end
    end
    raknetBitStreamResetReadPointer(bs)

    if text:find('OnPlayerOpenMenuPause', 1, true) then
        if login_submitted or is_spawned or is_logging_in then
            log("OnPlayerOpenMenuPause ignored (login in progress/done)")
        elseif in_close_menu_emul_window() then
            local now = os.clock()
            if (now - last_close_menu_emul) >= 0.15 then
                last_close_menu_emul = now
                log("OnPlayerOpenMenuPause -> emulate CloseMenuPause")
                lua_thread.create(function()
                    wait(50)
                    if login_submitted or is_spawned or is_logging_in then return end
                    emulate_close_menu_pause(1)
                end)
            else
                log("OnPlayerOpenMenuPause ignored (debounce)")
            end
        end
    end

    if not script_active or password == "" then return end

    if text:find('GameText') and (text:find('Загрузка') or text:find('~y~')) then
        if text:find('Загрузка') or text:find('Loading') then
            saw_loading_after_rec = true
            reconnect_watch_active = false
            log("Пакет Загрузка/GameText — watchdog снят")
        end
    end
    if text:find('~y~Загрузка') or (text:find('Загрузка') and text:find('10000')) then
        saw_loading_after_rec = true
        reconnect_watch_active = false
        log("Пакет Загрузка — watchdog снят")
    end

    if text:find('Loading') and text:find('3000') then
        saw_loading_after_rec = true
        reconnect_watch_active = false
        is_logging_in = false
        log("Loading[3000] (UI/загрузка) — is_spawned не меняем")
    end

    if text:find('setPlayerNickName')
        or text:find('Добро пожаловать')
        or text:find('setPlayerConnectedStatus') then
        if #player_nick == 0 then
            local kw = text:find('setPlayerNickName', 1, true)
            if kw then
                local tail = text:sub(kw + #'setPlayerNickName')
                local nick = tail:match('([%w%p_%-%[%]%.]+%s*)$')
                if nick then
                    nick = nick:gsub('%s+$', ''):gsub('^%s+', '')
                    nick = nick:gsub('[%c]+', '')
                    if #nick > 0 and nick:find('%a') then
                        player_nick = nick
                    end
                end
            end
        end
        is_logging_in = false
        pending_autologin = false
        if not waiting_for_spawn_choice then
            is_spawned = true
            player_in_world = true
            finish_reconnect("login ok")
            log("Авторизация пройдена (успешный вход в мир)")
            return
        end
    end

    if not is_reconnecting then
        local low = text:lower()
        if low:find("вы отключены от сервера") then
            is_spawned = false
            player_in_world = false
            is_logging_in = false
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            log("Дисконнект по тексту пакета")
            trigger_reconnect()
            return
        end
    end

    local lower_err = text:lower()
    local is_kick_dialog =
        text:find("Вы ввели неправильный пароль")
        or text:find("Вы ввели неправильный пароль 3 раза")
        or text:find("вы были кикнуты")
        or text:find("заблокирован")
        or (lower_err:find("подозрительн") and lower_err:find("программ"))
        or lower_err:find("сторонняя программа")
        or (lower_err:find("заблокир") and (lower_err:find("античит") or lower_err:find("чит")))
        or (lower_err:find("подозрительн") and lower_err:find("действи"))
        or lower_err:find("вы были кикнуты")
        or lower_err:find("you have been kicked")

    if lower_err:find("the server is restarting")
        or lower_err:find("подключение к")
        or lower_err:find("connecting to") then
        is_kick_dialog = false
    end

    if is_kick_dialog and not is_reconnecting then
        lua_thread.create(function()
            is_spawned = false
            player_in_world = false
            is_logging_in = false
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            wait_for_game_focus()
            wait(200)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYUP, 0)
            wait(400)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYUP, 0)
            wait(800)
            reconnect_cooldown_until = os.clock() + 5
            trigger_reconnect()
        end)
        return
    end

    if waiting_for_spawn_choice then
        local low = text:lower()
        if low:find("вы появились на")
            or low:find("вернулись на место")
            or low:find("позиция восстановлена") then
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            is_spawned = true
            player_in_world = true
            log("Точка спавна выбрана — таймер закрыт")
        end
    end

    if text:find("Диалог точки спавна")
        or text:find("Восстановление позиции")
        or text:find("хотите вернуться на место последнего выхода") then
        lua_thread.create(function()
            wait(150)
            current_dialog_id = sampGetCurrentDialogId and sampGetCurrentDialogId() or -1
            is_spawned = false
            waiting_for_spawn_choice = true
            spawn_timer_seconds = 15
            log("Диалог точки спавна — таймер 15 сек")
            while waiting_for_spawn_choice and spawn_timer_seconds > 0 do
                wait(1000)
                if waiting_for_spawn_choice then
                    spawn_timer_seconds = spawn_timer_seconds - 1
                end
            end
            if waiting_for_spawn_choice then
                waiting_for_spawn_choice = false
                spawn_timer_seconds = 0
                is_spawned = true
                player_in_world = true
                wait_for_game_focus()
                wait(200)
                if spawn_choice then
                    user32.keybd_event(0x0D, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(50)
                    user32.keybd_event(0x0D, 0, KEYEVENTF_KEYUP, 0)
                else
                    user32.keybd_event(0x1B, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(50)
                    user32.keybd_event(0x1B, 0, KEYEVENTF_KEYUP, 0)
                end
            end
        end)
        return
    end

    if text:find('SelectSpawn') and (text:find('Автовокзал г. Южный') or text:find('Южный')) then
        log("SelectSpawn: выбираем «Автовокзал г. Южный»")
        lua_thread.create(function()
            wait(400)
            pcall(wait_for_game_focus)
            wait(200)
            local sw, sh = getScreenResolution()
            local points = {
                {0.28, 0.58},
                {0.30, 0.55},
                {0.26, 0.60},
                {0.32, 0.56},
            }
            for _, p in ipairs(points) do
                local x = math.floor(sw * p[1])
                local y = math.floor(sh * p[2])
                user32.SetCursorPos(x, y)
                wait(40)
                user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
                wait(40)
                user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
                wait(80)
            end
            wait(250)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYUP, 0)
            wait(200)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYUP, 0)
            log("SelectSpawn: клик + Space по «Автовокзал г. Южный»")
            is_spawned = true
            player_in_world = true
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
        end)
        return
    end

    if is_spawned then return end

    if text:find('setError') and (text:find('password') or text:find('"password"') or text:find('Password')) then
        local low = text:lower()
        local is_wrong = text:find('неправильный пароль')
            or text:find('неверный пароль')
            or low:find('wrong password')
            or low:find('invalid password')
            or low:find('incorrect password')
            or text:find('setError')
        if is_wrong then
            log("CEF: неверный пароль — открываем форму ввода")
            is_spawned = false
            player_in_world = false
            is_logging_in = false
            login_submitted = false
            finish_reconnect("wrong password")
            pending_autologin = false
            force_password_form = true
            password_form_closed = false
            password_form_error = "Пароль неверный, введите другой"
            temp_password = ""
            pass_input_active = true
            return
        end
    end

    local is_auth_form =
        (text:find('Authorization') and text:find('"auth"'))
        or text:find('OnAuthorizationStart')
        or text:find('OnAuthorizationStarts')
        or text:find('recovery-password')

    local looks_like_password_form =
        text:find('Введите пароль')
        or text:find('Поле пароля')
        or text:find('форма авторизации')
        or text:find('ожидания формы')

    if is_auth_form or looks_like_password_form then
        finish_reconnect("auth form")
        is_spawned = false
        player_in_world = false
        is_logging_in = false
        pending_autologin = false
        last_login_attempt = 0
        if password == "" or force_password_form then
            log("CEF-форма авторизации, пароля нет — ждём ввод в GUI")
            force_password_form = true
            password_form_closed = false
            pass_input_active = true
        else
            log("CEF-форма авторизации — ввод пароля")
            perform_login()
        end
    end
end

function sampevents.onServerJoin()
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    pending_autologin = true
    last_login_attempt = 0
    log("onServerJoin — ждём CEF AuthorizationT / автовход")
    schedule_autologin_after_reconnect()
    if password ~= "" and not force_password_form then
        lua_thread.create(function()
            for attempt = 1, 6 do
                wait(2000)
                if is_spawned or not script_active or password == "" then return end
                if not is_logging_in then
                    log(string.format("onServerJoin: отложенный автовход #%d", attempt))
                    last_login_attempt = 0
                    perform_login()
                end
            end
        end)
    end
end

function sampevents.onConnectionClosed()
    log("sampevents.onConnectionClosed (packet 32)")
    if is_reconnecting then return end
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    trigger_reconnect()
end

function sampevents.onConnectionLost()
    log("sampevents.onConnectionLost (packet 33)")
    if is_reconnecting then return end
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    trigger_reconnect()
end

function onConnectionClosed()
    log("onConnectionClosed (global)")
    if is_reconnecting then return end
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    trigger_reconnect()
end

function onWindowMessage(msg, wparam, lparam)
    if (msg == 0x0100 or msg == 0x0104) and wparam == 0x7A then
        mark_manual_reconnect("F11")
    end

    if is_password_form_visible() and (msg == 0x0100 or msg == 0x0104) and wparam == 0x1B then
        close_password_form()
        return
    end

    if waiting_for_spawn_choice then
        if msg == 0x0100 or msg == 0x0104 then
            if wparam == 0x0D or wparam == 0x1B then
                waiting_for_spawn_choice = false
                spawn_timer_seconds = 0
                is_spawned = true
                player_in_world = true
                log("Таймер спавна закрыт (клавиша)")
            end
        elseif msg == 0x0201 then
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            is_spawned = true
            player_in_world = true
            log("Таймер спавна закрыт (ЛКМ)")
        end
    end

    if is_password_form_visible() and pass_input_active then
        if msg == 0x0100 then
            if wparam == 0x08 then
                if #temp_password > 0 then
                    temp_password = temp_password:sub(1, #temp_password - 1)
                end
            elseif wparam == 0x0D then
                if #temp_password > 0 then
                    password = temp_password
                    save_config()
                    play_gta_confirm_sound()
                    chat_msg("Пароль успешно установлен через графическую форму!")
                    on_password_saved()
                else
                    chat_msg("{FF3333}Пароль не может быть пустым!")
                end
            end
        elseif msg == 0x0102 then
            if wparam >= 32 and wparam <= 126 and #temp_password < 32 then
                temp_password = temp_password .. string.char(wparam)
            elseif wparam > 126 and #temp_password < 32 then
                temp_password = temp_password .. string.char(wparam)
            end
        end
    end
end

local function timer_render_thread()
    local r_font = renderCreateFont("Arial", 14, 13)
    while true do
        wait(0)

        if os.clock() < mafk_notify_until then
            local sw, sh = getScreenResolution()
            local status_str = mafk_active and "{33FF33}Включен" or "{FF3333}Выключен"
            local msg_str = string.format("Anti-AFK режим: %s (правый Ctrl 1.5с /mafk)", status_str)
            local m_w = renderGetFontDrawTextLength(r_font, msg_str)
            local m_box_w = m_w + 24
            local m_x = math.floor((sw - m_box_w) / 2)
            local m_y = math.floor(sh * 0.70)
            renderDrawBox(m_x - 12, m_y - 6, m_box_w, 26, 0xB0000000)
            renderFontDrawText(r_font, msg_str, m_x + (m_box_w - 24 - m_w) / 2, m_y, 0xFFFFFFFF)
        end

        if waiting_for_spawn_choice and spawn_timer_seconds > 0 then
            local sw, sh = getScreenResolution()
            local action_str = spawn_choice and "Да (Enter)" or "Нет (Esc)"
            local text_str = string.format("Авто-выбор спавна [%s] через: %d сек.", action_str, spawn_timer_seconds)
            local btn_str = "[ Изменить ]"
            local text_w = renderGetFontDrawTextLength(r_font, text_str)
            local btn_w_val = renderGetFontDrawTextLength(r_font, btn_str)
            local box_w = math.max(text_w, btn_w_val) + 24
            local posX = math.floor((sw - box_w) / 2)
            local posY = math.floor(sh * 0.28)
            renderDrawBox(posX - 12, posY - 6, box_w, 64, 0xAA000000)
            renderFontDrawText(r_font, text_str, posX + (box_w - 24 - text_w) / 2, posY, 0xFFFFFF00)
            btn_x = posX + (box_w - 24 - btn_w_val) / 2 - 6
            btn_y = posY + 26
            btn_w = btn_w_val + 12
            btn_h = 24
            local cursor_x, cursor_y = getCursorPos()
            local pad = 10
            local is_hovered = (cursor_x >= btn_x - pad and cursor_x <= btn_x + btn_w + pad and cursor_y >= btn_y - pad and cursor_y <= btn_y + btn_h + pad)
            local current_lbutton_state = (user32.GetAsyncKeyState(0x01) < 0)
            local btn_bg_color = is_hovered and 0x55FFFFFF or 0x33000000
            renderDrawBox(btn_x, btn_y, btn_w, btn_h, btn_bg_color)
            renderFontDrawText(r_font, btn_str, btn_x + 6, btn_y + 2, is_hovered and 0xFF33FF33 or 0xFFFFFFFF)
            -- фиксируем попадание в момент НАЖАТИЯ ЛКМ (не отпускания)
            if current_lbutton_state and not last_lbutton_state and is_hovered then
                spawn_btn_pressed = true
            end
            if last_lbutton_state and not current_lbutton_state then
                if spawn_btn_pressed then
                    spawn_btn_pressed = false
                    spawn_choice = not spawn_choice
                    save_config()
                    local status = spawn_choice and "{33FF33}Да (Enter)" or "{FF3333}Нет (Esc)"
                    chat_msg("Переключить спавн на точке выхода: " .. status)
                else
                    waiting_for_spawn_choice = false
                    spawn_timer_seconds = 0
                    is_spawned = true
                    player_in_world = true
                    log("Таймер спавна закрыт (ЛКМ по CEF)")
                end
            end
            last_lbutton_state = current_lbutton_state
        else
            last_lbutton_state = false
        end

        if is_password_form_visible() then
            local sw, sh = getScreenResolution()
            local form_w, form_h = 480, 210
            local form_x = math.floor((sw - form_w) / 2)
            local form_y = math.floor((sh - form_h) / 2)
            local pad = 18

            renderDrawBox(form_x + 5, form_y + 6, form_w, form_h, 0x50000000)
            renderDrawBox(form_x, form_y, form_w, form_h, 0xF0111118)
            renderDrawBox(form_x, form_y, form_w, 1, 0x40FFFFFF)
            renderDrawBox(form_x, form_y + form_h - 1, form_w, 1, 0x20FFFFFF)
            renderDrawBox(form_x, form_y, 1, form_h, 0x20FFFFFF)
            renderDrawBox(form_x + form_w - 1, form_y, 1, form_h, 0x20FFFFFF)

            local head_h = 48
            renderDrawBox(form_x, form_y, form_w, head_h, 0xF0181822)
            renderDrawBox(form_x, form_y + head_h - 2, form_w, 2, 0xFF6C5CE7)

            renderDrawBox(form_x + pad, form_y + 14, 28, 20, 0xFF6C5CE7)
            renderFontDrawText(r_font, "AL", form_x + pad + 5, form_y + 16, 0xFFFFFFFF)
            renderFontDrawText(r_font, "AutoLogin", form_x + pad + 36, form_y + 10, 0xFFFFFFFF)
            renderFontDrawText(r_font, "Введите пароль аккаунта", form_x + pad + 36, form_y + 26, 0xFF8B8BA0)

            local cursor_x, cursor_y = getCursorPos()
            local layout_name = get_current_keyboard_layout_name()

            local close_label = "Закрыть"
            local clw = renderGetFontDrawTextLength(r_font, close_label)
            close_btn_w = clw + 16
            close_btn_h = 24
            close_btn_x = form_x + form_w - pad - close_btn_w
            close_btn_y = form_y + 12
            local close_hovered = (cursor_x >= close_btn_x and cursor_x <= close_btn_x + close_btn_w and cursor_y >= close_btn_y and cursor_y <= close_btn_y + close_btn_h)
            renderDrawBox(close_btn_x, close_btn_y, close_btn_w, close_btn_h, close_hovered and 0xFF4A3040 or 0xFF2A2228)
            renderFontDrawText(r_font, close_label, close_btn_x + 8, close_btn_y + 4, close_hovered and 0xFFFF8A8A or 0xFFC8C8D8)

            local row_y = form_y + 64
            if password_form_error ~= "" then
                renderFontDrawText(r_font, password_form_error, form_x + pad, form_y + 54, 0xFFFF6B6B)
                row_y = form_y + 78
            end
            local row_h = 34

            local lay_w = 40
            renderDrawBox(form_x + pad, row_y, lay_w, row_h, 0xFF252532)
            local ll = renderGetFontDrawTextLength(r_font, layout_name)
            renderFontDrawText(r_font, layout_name, form_x + pad + (lay_w - ll) / 2, row_y + 9, 0xFFB8B8FF)

            pass_field_x = form_x + pad + lay_w + 8
            pass_field_y = row_y
            pass_field_w = 200
            pass_field_h = row_h
            local field_hovered = (cursor_x >= pass_field_x and cursor_x <= pass_field_x + pass_field_w and cursor_y >= pass_field_y and cursor_y <= pass_field_y + pass_field_h)
            renderDrawBox(pass_field_x, pass_field_y, pass_field_w, pass_field_h, pass_input_active and 0xFF2A2A3A or 0xFF1E1E28)
            local fb = pass_input_active and 0xFF6C5CE7 or 0x30FFFFFF
            renderDrawBox(pass_field_x, pass_field_y, pass_field_w, 1, fb)
            renderDrawBox(pass_field_x, pass_field_y + pass_field_h - 1, pass_field_w, 1, fb)
            renderDrawBox(pass_field_x, pass_field_y, 1, pass_field_h, fb)
            renderDrawBox(pass_field_x + pass_field_w - 1, pass_field_y, 1, pass_field_h, fb)

            local display_pass = (#temp_password > 0) and (show_password_chars and temp_password or string.rep("*", #temp_password)) or "Пароль..."
            local pass_color = #temp_password > 0 and 0xFFF0F0F5 or 0xFF6A6A7A
            renderFontDrawText(r_font, display_pass, pass_field_x + 10, pass_field_y + 9, pass_color)
            if pass_input_active and #temp_password > 0 and (os.clock() % 1.0) < 0.5 then
                local tw = renderGetFontDrawTextLength(r_font, display_pass)
                renderDrawBox(pass_field_x + 10 + tw + 2, pass_field_y + 8, 2, 18, 0xFF6C5CE7)
            end

            pass_btn_x = pass_field_x + pass_field_w + 8
            pass_btn_y = row_y
            pass_btn_w = 96
            pass_btn_h = row_h
            local btn_hovered = (cursor_x >= pass_btn_x and cursor_x <= pass_btn_x + pass_btn_w and cursor_y >= pass_btn_y and cursor_y <= pass_btn_y + pass_btn_h)
            renderDrawBox(pass_btn_x, pass_btn_y, pass_btn_w, pass_btn_h, btn_hovered and 0xFF7B6CF0 or 0xFF6C5CE7)
            local accept_label = "Принять"
            local alw = renderGetFontDrawTextLength(r_font, accept_label)
            renderFontDrawText(r_font, accept_label, pass_btn_x + (pass_btn_w - alw) / 2, pass_btn_y + 9, 0xFFFFFFFF)

            eye_btn_x = pass_btn_x + pass_btn_w + 8
            eye_btn_y = row_y
            eye_btn_w = 72
            eye_btn_h = row_h
            local eye_hovered = (cursor_x >= eye_btn_x and cursor_x <= eye_btn_x + eye_btn_w and cursor_y >= eye_btn_y and cursor_y <= eye_btn_y + eye_btn_h)
            renderDrawBox(eye_btn_x, eye_btn_y, eye_btn_w, eye_btn_h, eye_hovered and 0xFF353548 or 0xFF252532)
            local eye_text = show_password_chars and "Скрыть" or "Показ."
            local elw = renderGetFontDrawTextLength(r_font, eye_text)
            renderFontDrawText(r_font, eye_text, eye_btn_x + (eye_btn_w - elw) / 2, eye_btn_y + 9, 0xFFC8C8D8)

            local hint_y = row_y + 42
            local shift_active = is_shift_pressed()
            renderDrawBox(form_x + pad, hint_y, 48, 22, shift_active and 0xFF2D6A4F or 0xFF252532)
            local sl = renderGetFontDrawTextLength(r_font, "SHIFT")
            renderFontDrawText(r_font, "SHIFT", form_x + pad + (48 - sl) / 2, hint_y + 4, shift_active and 0xFF95D5B2 or 0xFF7A7A8A)
            renderFontDrawText(r_font, "Enter — подтвердить    Esc — закрыть", form_x + pad + 56, hint_y + 4, 0xFF7A7A8A)

            renderDrawBox(form_x, form_y + form_h - 26, form_w, 26, 0xF014141C)
            renderFontDrawText(r_font, "Пароль хранится локально в config/AutoLogin", form_x + pad, form_y + form_h - 20, 0xFF555568)

            local current_pass_lbutton_state = (user32.GetAsyncKeyState(0x01) < 0)
            if last_pass_lbutton_state and not current_pass_lbutton_state then
                if close_hovered then
                    close_password_form()
                elseif field_hovered then
                    pass_input_active = true
                elseif eye_hovered then
                    show_password_chars = not show_password_chars
                elseif not (cursor_x >= form_x and cursor_x <= form_x + form_w and cursor_y >= form_y and cursor_y <= form_y + form_h) then
                    pass_input_active = false
                end
            end
            local accept_clicked = (last_pass_lbutton_state and not current_pass_lbutton_state and btn_hovered)
            last_pass_lbutton_state = current_pass_lbutton_state

            if accept_clicked then
                if #temp_password > 0 then
                    password = temp_password
                    save_config()
                    play_gta_confirm_sound()
                    chat_msg("Пароль успешно установлен через графическую форму!")
                    on_password_saved()
                else
                    chat_msg("{FF3333}Пароль не может быть пустым!")
                end
            end
        end
    end
end

local function chatlog_parser_thread()
    local last_size = 0
    local initialized = false
    while true do
        wait(2000)
        if script_active and chatlog_path and doesFileExist(chatlog_path) then
            local file = io.open(chatlog_path, "r")
            if file then
                local content = file:read("*all") or ""
                file:close()
                local size = #content
                if not initialized then
                    last_size = size
                    initialized = true
                    log("chatlog: пропускаем историю (size=" .. tostring(size) .. ")")
                else
                    if size < last_size then
                        last_size = size
                    elseif size > last_size then
                        local new_part = content:sub(last_size + 1)
                        last_size = size
                        local low = new_part:lower()
                        if not is_reconnecting
                            and low:find("вы отключены от сервера")
                            and not low:find("восстановление позиции")
                            and not low:find("Дисконнект по НОВОЙ строке chatlog.txt") then
                            log("Дисконнект по НОВОЙ строке chatlog.txt")
                            is_spawned = false
                            player_in_world = false
                            is_logging_in = false
                            waiting_for_spawn_choice = false
                            spawn_timer_seconds = 0
                            trigger_reconnect()
                        end
                    end
                end
            end
        end
    end
end

function onSendCommand(command)
    if not command then return end
    local c = command:lower()
    if c:match("^rec%s+") or c == "rec" or c:match("^reconnect") then
        mark_manual_reconnect("/" .. command)
    end
end

function sampevents.onSendCommand(command)
    onSendCommand(command)
end

local function game_window_active()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    if hwnd == nil then return false end
    return user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd
end

local function anti_afk_thread()
    local keys = { 0x57, 0x44, 0x53, 0x41 }  -- W, D, S, A (порядок по заданию)
    local last_held = 0
    local hold_ms = math.random(1000, 3000)  -- одинаковое для всех кнопок в проходе
    local c_next_at = 0                      -- os.clock(), когда следующее нажатие C
    while true do
        wait(100)
        if not mafk_active then
            if last_held ~= 0 then
                user32.keybd_event(last_held, 0, KEYEVENTF_KEYUP, 0)
                last_held = 0
            end
        elseif player_in_world and game_window_active() then
            -- один проход: W -> D -> S -> A, каждая нажата/отпущена с одинаковым удержанием
            local aborted = false
            for i = 1, #keys do
                local k = keys[i]
                user32.keybd_event(k, 0, KEYEVENTF_KEYDOWN, 0)
                last_held = k
                wait(hold_ms)
                user32.keybd_event(k, 0, KEYEVENTF_KEYUP, 0)
                last_held = 0
                wait(400)
                if not mafk_active or not player_in_world or not game_window_active() then
                    aborted = true
                    break
                end
            end
            -- пересчёт одинакового времени удержания для следующего прохода
            hold_ms = math.random(1000, 3000)
            -- эмуляция C (простое нажатие) в рандомный интервал 1-5 сек
            if not aborted then
                local now = os.clock()
                if c_next_at == 0 then
                    c_next_at = now + math.random(1, 5)
                end
                if now >= c_next_at then
                    user32.keybd_event(0x43, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(50)
                    user32.keybd_event(0x43, 0, KEYEVENTF_KEYUP, 0)
                    c_next_at = now + math.random(1, 5)
                end
            end
        end
    end
end

local function mafk_hotkey_thread()
    local prev_down = (user32.GetAsyncKeyState(0xA3) < 0)
    local hold_until = 0
    while true do
        wait(25)
        local down = (user32.GetAsyncKeyState(0xA3) < 0)
        if down and not prev_down then
            hold_until = os.clock() + 1.5
        elseif not down and prev_down then
            if hold_until > 0 and os.clock() >= hold_until then
                mafk_active = not mafk_active
                mafk_notify_until = os.clock() + 4
                play_gta_confirm_sound()
                local status = mafk_active and "{33FF33}Включен" or "{FF3333}Выключен"
                chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} режим: " .. status)
                if mafk_active then
                    player_in_world = true
                    local spawn_state = is_spawned and "{33FF33}true" or "{FF3333}false"
                    local world_state = player_in_world and "{33FF33}true" or "{FF3333}false"
                    chat_msg(string.format("{FFCC00}[Anti-AFK]{FFFFFF} is_spawned=%s player_in_world=%s", spawn_state, world_state))
                end
                sync_mafk_flag()
            end
            hold_until = 0
        end
        prev_down = down
    end
end

local function nick_hotkey_thread()
    local prev_down = (user32.GetAsyncKeyState(0x30) < 0)
    local hold_until = 0
    while true do
        wait(25)
        local down = (user32.GetAsyncKeyState(0x30) < 0)
        if down and not prev_down then
            hold_until = os.clock() + 1
        elseif not down and prev_down then
            if hold_until > 0 and os.clock() >= hold_until then
                if not (sampIsChatInputActive and sampIsChatInputActive()) then
                    local nick = player_nick or ""
                    if #nick == 0 then
                        local ok1, r1 = pcall(function() return sampGetLocalPlayerNickName() end)
                        if ok1 and r1 and #r1 > 0 then
                            nick = r1
                        end
                    end
                    if #nick == 0 then
                        local ok2, id = pcall(function() return sampGetLocalPlayerId() end)
                        if ok2 and id then
                            local ok3, r3 = pcall(function() return sampGetPlayerNickName(id) end)
                            if ok3 and r3 and #r3 > 0 then
                                nick = r3
                            end
                        end
                    end
                    if #nick > 0 then
                        player_nick = nick
                        chat_msg("Ник игрока: " .. nick)
                    else
                        chat_msg("{FF3333}Ник пока не определён (появляется после входа в игру)")
                    end
                end
            end
            hold_until = 0
        end
        prev_down = down
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    load_config()
    register_commands()
    chatlog_path = find_chatlog_path()
    log("Путь к chatlog.txt определен: " .. tostring(chatlog_path))
    sync_mafk_flag()
    lua_thread.create(chatlog_parser_thread)
    lua_thread.create(timer_render_thread)
    lua_thread.create(anti_afk_thread)
    lua_thread.create(mafk_hotkey_thread)
    lua_thread.create(nick_hotkey_thread)
    while true do wait(10000) end
end
