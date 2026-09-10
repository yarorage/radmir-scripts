-- Модуль утилит AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local ffi = require("ffi")
local M = {}

local MOUSEEVENTF_LEFTDOWN = 0x02
local MOUSEEVENTF_LEFTUP = 0x04

local GAME_WINDOW_CLASS = "Grand theft auto San Andreas"

-- Единый масштаб интерфейса (все разрешения, в т.ч. 4K, независимо от масштаба Windows)
-- База 1920x1080: берём наименьшее отношение, клэп 0.6..3.0
function M.get_ui_scale()
    local sw, sh = getScreenResolution()
    local s = math.min(sw / 1920.0, sh / 1080.0)
    -- DPI: в окне на HiDPI экране разрешение рендера меньше физического, домножаем
    local dpiScale = 1.0
    local ok, dpi = pcall(function() return user32.GetDpiForSystem() end)
    if ok and type(dpi) == "number" and dpi > 0 then dpiScale = dpi / 96 end
    local ok2, sysH = pcall(function() return user32.GetSystemMetrics(1) end)
    if ok2 and type(sysH) == "number" and sysH > 0 and sysH * dpiScale > sh * 1.05 then
        s = s * dpiScale
    end
    -- Диапазон 100%..350% (0.5..3.5) с шагом 25%
    if s < 0.5 then s = 0.5 elseif s > 3.5 then s = 3.5 end
    return s
end

function M.sc(v)
    return math.floor(v * M.get_ui_scale() + 0.5)
end

function M.get_current_keyboard_layout_name()
    local fg = user32.GetForegroundWindow()
    local thread = user32.GetWindowThreadProcessId(fg, nil)
    local layout = user32.GetKeyboardLayout(thread)
    local id = tonumber(ffi.cast("unsigned int", layout)) % 0x10000
    if id == 0x0419 then return "RU"
    elseif id == 0x0409 then return "EN"
    else return "UNKNOWN_" .. string.format("%04X", id) end
end

function M.is_shift_pressed()
    return bit.band(user32.GetKeyState(0x10), 0x8000) ~= 0
end

function M.play_gta_confirm_sound()
    winmm.PlaySoundA("SystemAsterisk", nil, bit.bor(0x00010000, 0x0001))
end

function M.set_clipboard_text(str)
    -- Записываем пароль в буфер: и Unicode (CF_UNICODETEXT), и ANSI (CF_TEXT)
    -- чтобы и кириллица вставлялась в поле CEF корректно
    user32.OpenClipboard(nil)
    user32.EmptyClipboard()

    -- Unicode: конвертируем ANSI/CP1251 в UTF-16
    if str and #str > 0 then
        local wlen = kernel32.MultiByteToWideChar(0, 0, str, -1, nil, 0)
        if wlen > 0 then
            local wbuf = ffi.new("wchar_t[?]", wlen)
            kernel32.MultiByteToWideChar(0, 0, str, -1, wbuf, wlen)
            local hMemW = kernel32.GlobalAlloc(0x0042, wlen * 2)
            if hMemW ~= 0 then
                local pMemW = kernel32.GlobalLock(hMemW)
                if pMemW ~= 0 then
                    ffi.copy(pMemW, wbuf, wlen * 2)
                    kernel32.GlobalUnlock(hMemW)
                    user32.SetClipboardData(13, ffi.cast("void*", hMemW))
                end
            end
        end
    end

    -- ANSI (CF_TEXT)
    local hMem = kernel32.GlobalAlloc(0x0042, #str + 1)
    if hMem ~= 0 then
        local pMem = kernel32.GlobalLock(hMem)
        if pMem ~= 0 then
            ffi.copy(pMem, str)
            kernel32.GlobalUnlock(hMem)
            user32.SetClipboardData(1, ffi.cast("void*", hMem))
        end
    end

    user32.CloseClipboard()
end

function M.get_clipboard_text()
    -- Чтение текста из буфера обмена: сначала CF_TEXT, затем CF_UNICODETEXT
    local function read_text(format)
        if not user32.IsClipboardFormatAvailable(format) then return nil end
        if not user32.OpenClipboard(nil) then return nil end
        local hData = user32.GetClipboardData(format)
        if hData == 0 then user32.CloseClipboard(); return nil end
        local pData = kernel32.GlobalLock(hData)
        if pData == 0 then user32.CloseClipboard(); return nil end
        local text = ffi.string(pData)
        kernel32.GlobalUnlock(hData)
        user32.CloseClipboard()
        return text
    end

    local text = read_text(1)
    if text and #text > 0 then return text end

    -- Если в буфере только Юникод (CF_UNICODETEXT), конвертируем в системную кодировку
    if not user32.IsClipboardFormatAvailable(13) then return nil end
    if not user32.OpenClipboard(nil) then return nil end
    local hData = user32.GetClipboardData(13)
    local result = nil
    if hData ~= 0 then
        local pData = kernel32.GlobalLock(hData)
        if pData ~= 0 then
            local pu = ffi.cast("const wchar_t*", pData)
            local len = 0
            while len < 65536 and pu[len] ~= 0 do len = len + 1 end
            if len > 0 then
                local buf = ffi.new("char[?]", len * 3 + 1)
                local n = kernel32.WideCharToMultiByte(0, 0, pu, len, buf, len * 3 + 1, nil, nil)
                if n > 0 then result = ffi.string(buf, n) end
            end
            kernel32.GlobalUnlock(hData)
        end
    end
    user32.CloseClipboard()
    return result
end

function M.get_game_hwnd()
    local h = user32.FindWindowA(GAME_WINDOW_CLASS, nil)
    if h == nil then return 0 end
    return h
end

function M.game_window_active()
    local hwnd = user32.FindWindowA(GAME_WINDOW_CLASS, nil)
    if hwnd == nil then return false end
    return user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd
end

function M.wait_for_game_focus()
    local hwnd = user32.FindWindowA(GAME_WINDOW_CLASS, nil)
    if hwnd ~= nil then
        while true do
            if user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd then
                break
            end
            wait(500)
        end
    end
end

M.wait_for_focus = M.wait_for_game_focus

function M.click_mouse(x, y)
    wait(100)
    user32.SetCursorPos(x, y)
    wait(80)
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    wait(30)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
    wait(50)
end

function M.click_xy(x, y)
    M.click_mouse(x, y)
end

function M.char_to_vk(ch)
    local byte = ch:byte()
    if byte >= 48 and byte <= 57 then return byte end
    if byte >= 65 and byte <= 90 then return byte end
    if byte >= 97 and byte <= 122 then return byte - 32 end
    local special = {
        ["-"] = 0xBD, ["="] = 0xBB, ["["] = 0xDB, ["]"] = 0xDD,
        ["\\"] = 0xDC, [";"] = 0xBA, ["'"] = 0xDE, [","] = 0xBC,
        ["."] = 0xBE, ["/"] = 0xBF, ["`"] = 0xC0,
        [" "] = 0x20,
    }
    return special[ch]
end

function M.send_char(vk, need_shift)
    if need_shift then user32.keybd_event(0x10, 0, 0, 0) end
    wait(25)
    user32.keybd_event(vk, 0, 0, 0)
    wait(30)
    user32.keybd_event(vk, 0, 2, 0)
    wait(30)
    if need_shift then user32.keybd_event(0x10, 0, 2, 0) end
end

function M.send_paste_command()
    user32.keybd_event(0x11, 0, 0, 0)
    user32.keybd_event(0x56, 0, 0, 0)
    user32.keybd_event(0x56, 0, 2, 0)
    user32.keybd_event(0x11, 0, 2, 0)
end

function M.send_enter()
    user32.keybd_event(0x0D, 0, 0, 0)
    wait(30)
    user32.keybd_event(0x0D, 0, 2, 0)
end

function M.send_key_down(vk)
    user32.keybd_event(vk, 0, 0, 0)
end

function M.send_key_up(vk)
    user32.keybd_event(vk, 0, 2, 0)
end

function M.send_key(vk)
    user32.keybd_event(vk, 0, 0, 0)
    user32.keybd_event(vk, 0, 2, 0)
end

function M.is_scoreboard_or_dialog_open()
    if isSampAvailable and isSampAvailable() then
        if sampIsDialogActive() then return true end
    end
    return false
end

function M.try_close_dialog_fast()
    if isSampAvailable and isSampAvailable() and sampIsDialogActive() then
        sampCloseCurrentDialogWithButton(0)
        return true
    end
    return false
end

function M.play_sound_mci(path)
    if not path or not doesFileExist(path) then return end
    local alias = "auth_snd_" .. tostring(os.clock()):gsub("%.", "")
    pcall(function()
        winmm.mciSendStringA('open "' .. path .. '" type mpegvideo alias ' .. alias, nil, 0, nil)
        winmm.mciSendStringA('play ' .. alias .. ' wait', nil, 0, nil)
        winmm.mciSendStringA('close ' .. alias, nil, 0, nil)
    end)
end

function M.play_auth_sounds_if_needed()
    if not M.game_window_active() then
        local s = AL.state
        lua_thread.create(function()
            M.play_sound_mci(s.AUTH_SOUND1_PATH)
            M.play_sound_mci(s.AUTH_SOUND2_PATH)
        end)
    end
end

-- Adaptive password field position detection
M.cef_auth_window_pos = {x = 0, y = 0, w = 0, h = 0}

function M.update_cef_auth_pos(x, y, w, h)
    M.cef_auth_window_pos = {x = x, y = y, w = w, h = h}
end

function M.get_password_field_pos(sw, sh)
    local pos = M.cef_auth_window_pos
    -- Если есть сохранённая позиция CEF-окна авторизации — используем её
    if pos.w > 0 and pos.h > 0 then
        -- Поле пароля обычно в нижней части CEF-окна, слева от центра
        local field_x = pos.x + math.floor(pos.w * 0.15)
        local field_y = pos.y + math.floor(pos.h * 0.72)
        return math.max(0, math.min(field_x, sw - 1)), math.max(0, math.min(field_y, sh - 1))
    end
    
    -- Fallback: относительные координаты (20% / 76%) с защитой от выхода за экран
    local default_x = math.floor(sw * 0.20)
    local default_y = math.floor(sh * 0.76)
    return math.max(0, math.min(default_x, sw - 1)), math.max(0, math.min(default_y, sh - 1))
end

-- Take screenshot using GTA SA's built-in function
function M.take_screenshot(filename)
    local filepath = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\resource\\" .. filename
    local ok, err = pcall(function()
        saveScreenshot(filepath)
    end)
    if ok then
        AL.log("Screenshot saved: " .. filepath)
    else
        AL.log("Screenshot failed: " .. tostring(err))
    end
    return ok, filepath
end

-- Password encryption (XOR + Base64)
local ENCRYPTION_KEY = "YaroRage2024AutoLoginKey"

local function xor_crypt(data, key)
    local result = {}
    for i = 1, #data do
        local c = data:byte(i)
        local k = key:byte((i - 1) % #key + 1)
        result[i] = string.char(bit.bxor(c, k))
    end
    return table.concat(result)
end

function M.encrypt_password(password)
    if not password or #password == 0 then return "" end
    local encrypted = xor_crypt(password, ENCRYPTION_KEY)
    -- Simple base64 encoding
    local b64 = require("base64")
    return b64.encode(encrypted)
end

function M.decrypt_password(encrypted)
    if not encrypted or #encrypted == 0 then return "" end
    local b64 = require("base64")
    local decoded = b64.decode(encrypted)
    if not decoded then return "" end
    return xor_crypt(decoded, ENCRYPTION_KEY)
end

-- Auto-updater
function M.check_for_updates()
    local s = AL.state
    if not s.auto_update_enabled then return false end
    
    local now = os.clock()
    if now - s.last_update_check < s.update_check_interval then
        return false
    end
    s.last_update_check = now
    
    local https = require("ssl.https")
    local ltn12 = require("ltn12")
    local dkjson = require("dkjson")
    
    local response_body = {}
    local url = "https://api.github.com/repos/" .. s.github_repo .. "/releases/latest"
    
    local params = {
        url = url,
        method = "GET",
        sink = ltn12.sink.table(response_body),
        verify = "none",
        headers = {
            ["User-Agent"] = "AutoLoginByYaroRage",
        },
    }
    
    local ok, code, headers = https.request(params)
    if ok and code == 200 then
        local data = dkjson.decode(table.concat(response_body))
        if data and data.tag_name then
            local latest = data.tag_name:gsub("v", "")
            local current = s.current_version or "0.0.0"
            
            if latest ~= current then
                AL.log("Update available: " .. latest .. " (current: " .. current .. ")")
                AL.chat_msg("{FFCC00}[Updater]{FFFFFF} Доступно обновление: v" .. latest .. " (текущая: v" .. current .. ")")
                
                if data.html_url then
                    AL.chat_msg("Скачать: " .. data.html_url)
                end
                
                if data.assets and #data.assets > 0 then
                    for _, asset in ipairs(data.assets) do
                        if asset.name:match("%.lua$") or asset.name:match("%.zip$") then
                            M.download_update(asset.browser_download_url, asset.name)
                            break
                        end
                    end
                end
                return true
            end
        end
    end
    return false
end

function M.download_update(url, filename)
    local https = require("ssl.https")
    local ltn12 = require("ltn12")
    
    local filepath = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\updates\\" .. filename
    local dir = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\updates\\"
    
    if not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
    
    local f = io.open(filepath, "wb")
    if not f then return false end
    
    local params = {
        url = url,
        method = "GET",
        sink = ltn12.sink.file(f),
        verify = "none",
    }
    
    local ok, code = https.request(params)
    f:close()
    if ok and code == 200 then
        AL.log("Update downloaded: " .. filepath)
        AL.chat_msg("{33FF33}Обновление скачано: " .. filename)
        AL.chat_msg("Перезагрузите скрипт для применения (/reload)")
        return true
    else
        AL.log("Download failed: " .. tostring(code))
        return false
    end
end

-- Logging system with levels
local LOG_LEVELS = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
}

local function init_log_file()
    local s = AL.state
    if s.log_file_path then return end
    
    local log_dir = getWorkingDirectory() .. "\\AutoLoginByYaroRage\\logs\\"
    if not doesDirectoryExist(log_dir) then
        createDirectory(log_dir)
    end
    
    local filename = "autologin_" .. os.date("%Y%m%d_%H%M%S") .. ".log"
    s.log_file_path = log_dir .. filename
    
    -- Write header
    local f = io.open(s.log_file_path, "w")
    if f then
        f:write(string.format("[%s] AutoLoginByYaroRage v%s started\n", os.date("%Y-%m-%d %H:%M:%S"), s.current_version or "2.0"))
        f:close()
    end
end

local function write_log_file(level_name, msg)
    local s = AL.state
    if not s.log_to_file then return end
    
    init_log_file()
    if not s.log_file_path then return end
    
    -- Check file size
    local f = io.open(s.log_file_path, "r")
    if f then
        local size = f:seek("end")
        f:close()
        if size > s.log_file_max_size then
            -- Rotate log file
            os.rename(s.log_file_path, s.log_file_path .. ".old")
            s.log_file_path = nil
            init_log_file()
        end
    end
    
    local f = io.open(s.log_file_path, "a")
    if f then
        f:write(string.format("[%s] [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level_name, msg))
        f:close()
    end
end

function M.log_debug(msg)
    local s = AL.state
    if (s.log_level or 2) <= LOG_LEVELS.DEBUG then
        AL.log("[DEBUG] " .. tostring(msg))
        write_log_file("DEBUG", msg)
    end
end

function M.log_info(msg)
    local s = AL.state
    if (s.log_level or 2) <= LOG_LEVELS.INFO then
        AL.log("[INFO] " .. tostring(msg))
        write_log_file("INFO", msg)
    end
end

function M.log_warn(msg)
    local s = AL.state
    if (s.log_level or 2) <= LOG_LEVELS.WARN then
        AL.log("[WARN] " .. tostring(msg))
        write_log_file("WARN", msg)
    end
end

function M.log_error(msg)
    local s = AL.state
    if (s.log_level or 2) <= LOG_LEVELS.ERROR then
        AL.log("[ERROR] " .. tostring(msg))
        write_log_file("ERROR", msg)
    end
end

function M.set_log_level(level)
    local s = AL.state
    if type(level) == "string" then
        level = LOG_LEVELS[level:upper()] or 2
    end
    s.log_level = level
    config.save()
end

-- ==================== Unit Tests ====================
local test_results = {passed = 0, failed = 0}

local function assert_equal(actual, expected, msg)
    if actual == expected then
        test_results.passed = test_results.passed + 1
        return true
    else
        test_results.failed = test_results.failed + 1
        AL.log("[TEST FAIL] " .. (msg or "") .. " - expected: " .. tostring(expected) .. ", got: " .. tostring(actual))
        return false
    end
end

local function assert_not_nil(value, msg)
    if value ~= nil then
        test_results.passed = test_results.passed + 1
        return true
    else
        test_results.failed = test_results.failed + 1
        AL.log("[TEST FAIL] " .. (msg or "") .. " - value is nil")
        return false
    end
end

local function assert_true(value, msg)
    if value == true then
        test_results.passed = test_results.passed + 1
        return true
    else
        test_results.failed = test_results.failed + 1
        AL.log("[TEST FAIL] " .. (msg or "") .. " - expected true, got " .. tostring(value))
        return false
    end
end

-- Test XOR encryption
local function test_xor_encryption()
    AL.log("Running XOR encryption tests...")
    
    local test_key = "test_key_123"
    local test_data = "Hello, World! Привет мир! 1234567890"
    
    local encrypted = xor_crypt(test_data, test_key)
    assert_not_nil(encrypted, "Encryption should return a string")
    assert_equal(#encrypted, #test_data, "Encrypted length should match original")
    
    local decrypted = xor_crypt(encrypted, test_key)
    assert_equal(decrypted, test_data, "Decryption should restore original data")
    
    -- Test with empty string
    assert_equal(xor_crypt("", test_key), "", "Empty string should remain empty")
    
    -- Test with special characters
    local special = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
    local enc = xor_crypt(special, test_key)
    local dec = xor_crypt(enc, test_key)
    assert_equal(dec, special, "Special characters should work")
end

-- Test password encryption/decryption
local function test_password_encryption()
    AL.log("Running password encryption tests...")
    
    local test_passwords = {"simple", "ComplexP@ss123", "Пароль123", "", "a", string.rep("a", 32)}
    
    for _, pwd in ipairs(test_passwords) do
        local encrypted = M.encrypt_password(pwd)
        if pwd ~= "" then
            assert_not_nil(encrypted, "Encryption should work for: " .. pwd)
            local decrypted = M.decrypt_password(encrypted)
            assert_equal(decrypted, pwd, "Password decryption should match: " .. pwd)
        else
            assert_equal(M.decrypt_password(encrypted), "", "Empty password should decrypt to empty")
        end
    end
    
    -- Test invalid base64
    assert_equal(M.decrypt_password("invalid!!!"), "", "Invalid base64 should return empty")
    assert_equal(M.decrypt_password(""), "", "Empty encrypted should return empty")
end

-- Test queue parsing
local function test_queue_parsing()
    AL.log("Running queue parsing tests...")
    
    local test_cases = {
        {text = "Position in queue: 5", pos = 5, eta = 0, total = 0},
        {text = "Ваша позиция в очереди: 10", pos = 10, eta = 0, total = 0},
        {text = "Queue: 3/50 players ahead", pos = 3, eta = 0, total = 50},
        {text = "Estimated time: 15 min", pos = 0, eta = 15, total = 0},
        {text = "Примерное время: 5", pos = 0, eta = 5, total = 0},
    }
    
    for _, tc in ipairs(test_cases) do
        local s = AL.state
        s.queue_position = 0
        s.queue_eta = 0
        s.queue_total = 0
        s.queue_detected = false
        
        parse_queue_info(tc.text)
        
        assert_equal(s.queue_position, tc.pos, "Queue position for: " .. tc.text)
        assert_equal(s.queue_eta, tc.eta, "Queue ETA for: " .. tc.text)
    end
end

-- Test admin name detection
local function test_admin_detection()
    AL.log("Running admin detection tests...")
    
    local admin_det = require("AutoLoginByYaroRage.admin_detection")
    local s = AL.state
    
    s.admin_names = {"Admin_Vasya", "Mod_Petya", "Test_Admin"}
    
    -- Test exact match
    assert_true(admin_det.has_known_admin("Hello Admin_Vasya"), "Should detect Admin_Vasya")
    assert_true(admin_det.has_known_admin("mod_petya is here"), "Should detect case insensitive")
end

-- Test config schema validation
local function test_config_validation()
    AL.log("Running config validation tests...")
    
    local config = require("AutoLoginByYaroRage.config")
    
    -- Test boolean parsing
    assert_equal(config.validate_and_cast("TestBool", "true"), true, "Boolean true")
    assert_equal(config.validate_and_cast("TestBool", "false"), false, "Boolean false")
    assert_equal(config.validate_and_cast("TestBool", "1"), true, "Boolean 1")
    assert_equal(config.validate_and_cast("TestBool", "0"), false, "Boolean 0")
    assert_equal(config.validate_and_cast("TestBool", "yes"), true, "Boolean yes")
    assert_equal(config.validate_and_cast("TestBool", "no"), false, "Boolean no")
    assert_equal(config.validate_and_cast("TestBool", "invalid"), false, "Boolean invalid defaults to false")
    
    -- Test string validation
    assert_equal(config.validate_and_cast("TestStr", "hello"), "hello", "String passthrough")
    
    -- Test telegram token validation
    assert_equal(config.validate_and_cast("TelegramBotToken", "123:abc"), "123:abc", "Valid token format")
    assert_equal(config.validate_and_cast("TelegramBotToken", "invalid"), "", "Invalid token format returns empty")
    
    -- Test telegram chat ID validation
    assert_equal(config.validate_and_cast("TelegramChatId", "12345"), "12345", "Valid chat ID")
    assert_equal(config.validate_and_cast("TelegramChatId", "-12345"), "-12345", "Valid negative chat ID")
    assert_equal(config.validate_and_cast("TelegramChatId", "abc"), "", "Invalid chat ID")
end

-- Test state machine transitions
local function test_state_machine()
    AL.log("Running state machine tests...")
    
    local AL_mod = require("AutoLoginByYaroRage.state")
    
    -- Test valid transitions
    AL_mod.set_login_state("LOGGING_IN")
    assert_equal(AL_mod.get_login_state(), "LOGGING_IN", "Set to LOGGING_IN")
    
    AL_mod.set_login_state("WAITING_SPAWN")
    assert_equal(AL_mod.get_login_state(), "WAITING_SPAWN", "Set to WAITING_SPAWN")
    
    AL_mod.set_login_state("SPAWNED")
    assert_equal(AL_mod.get_login_state(), "SPAWNED", "Set to SPAWNED")
    
    AL_mod.set_login_state("IDLE")
    assert_equal(AL_mod.get_login_state(), "IDLE", "Set to IDLE")
    
    -- Test is_in_state
    assert_true(AL_mod.is_in_state("IDLE"), "is_in_state IDLE")
end

-- Test profile management
local function test_profiles()
    AL.log("Running profile tests...")
    
    local s = AL.state
    s.profiles = {}
    s.current_profile = "default"
    s.profiles["default"] = {password = "pass1", nick = "nick1"}
    
    -- Test get_active_profile
    local active = AL.get_active_profile()
    assert_equal(active.password, "pass1", "Default profile password")
    
    -- Test set_active_profile
    s.profiles["test"] = {password = "pass2", nick = "nick2"}
    AL.set_active_profile("test")
    assert_equal(s.current_profile, "test", "Switched to test profile")
    assert_equal(s.password, "pass2", "Password switched")
    
    -- Test delete_profile
    AL.delete_profile("test")
    assert_equal(s.current_profile, "default", "Fallback to default")
end

-- Test reconnect attempt counting
local function test_reconnect_counter()
    AL.log("Running reconnect counter tests...")
    
    local reconnect = require("AutoLoginByYaroRage.reconnect")
    local s = AL.state
    s.reconnect_attempt_count = 0
    s.reconnect_pause_until = 0
    s.reconnect_cooldown_until = 0
    s.is_reconnecting = false
    
    -- First attempt
    reconnect.trigger_reconnect("test1")
    assert_equal(s.reconnect_attempt_count, 1, "First attempt count")
    
    -- Second attempt
    reconnect.trigger_reconnect("test2")
    assert_equal(s.reconnect_attempt_count, 2, "Second attempt count")
    
    -- Third attempt triggers pause
    reconnect.trigger_reconnect("test3")
    assert_equal(s.reconnect_attempt_count, 0, "Counter reset after 3 attempts")
    assert_true(s.reconnect_pause_until > os.clock(), "Pause set after 3 attempts")
end

-- Run all tests
M.run_tests = function()
    AL.log("=== Running Unit Tests ===")
    test_results = {passed = 0, failed = 0}
    
    test_xor_encryption()
    test_password_encryption()
    test_queue_parsing()
    test_admin_detection()
    test_config_validation()
    test_state_machine()
    test_profiles()
    test_reconnect_counter()
    
    AL.log(string.format("=== Tests Complete: %d passed, %d failed ===", test_results.passed, test_results.failed))
    
    if test_results.failed > 0 then
        AL.chat_msg(string.format("{FF3333}Тестов: %d passed, %d failed", test_results.passed, test_results.failed))
    else
        AL.chat_msg(string.format("{33FF33}All %d tests passed!", test_results.passed))
    end
    
    return test_results.failed == 0
end

-- Run tests command
M.run_tests_command = function()
    M.run_tests()
end

return M