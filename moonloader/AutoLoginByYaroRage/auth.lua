-- Модуль авторизации AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local utils = require("AutoLoginByYaroRage.utils")
local reconnect = require("AutoLoginByYaroRage.reconnect")
local M = {}

local s = AL.state
local function log(msg)
    AL.log("[AUTH] " .. tostring(msg))
end

M.chatlog_parser_thread = function()
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

    local chatlog_path = find_chatlog_path()
    log("Путь к chatlog.txt: " .. tostring(chatlog_path))
    local file_handle = nil
    local file_pos = 0
    local last_inode = nil
    local initialized = false

    local function reopen_file()
        if file_handle then
            file_handle:close()
        end
        file_handle = io.open(chatlog_path, "r")
        if file_handle then
            file_handle:seek("set", file_pos)
            local info = file_handle:seek("end")
            file_pos = info or 0
            file_handle:seek("set", file_pos)
        end
    end

    local function check_rotation()
        -- Check if file was rotated (size decreased)
        local attr = file_handle and file_handle:seek("end") or 0
        if attr and attr < file_pos then
            log("chatlog: detected rotation, reopening")
            reopen_file()
            return true
        end
        return false
    end

    reopen_file()
    log("chatlog: initialized (pos=" .. tostring(file_pos) .. ")")

    while true do
        wait(2000)
        if s.script_active and chatlog_path and doesFileExist(chatlog_path) then
            if not file_handle then reopen_file() end
            if file_handle then
                -- Check for rotation
                check_rotation()
                
                -- Read new data incrementally
                local new_data = file_handle:read("*a")
                if new_data and #new_data > 0 then
                    file_pos = file_pos + #new_data
                    local low = new_data:lower()
                    
                    local wait_match = low:match("подождите%s+(%d+)%s+секунд")
                    if wait_match then
                        s.pending_server_wait_seconds = tonumber(wait_match) or 0
                        log("Сервер просит подождать " .. tostring(s.pending_server_wait_seconds) .. " сек. ждём реконнект")
                    end
                    
                    if not s.is_reconnecting
                        and low:find("вы отключены от сервера")
                        and not low:find("переподключение к серверу")
                        and not low:find("переподключение к серверу chatlog.txt") then
                        log("Переподключение к серверу chatlog.txt")
                        s.is_spawned = false
                        s.player_in_world = false
                        s.is_logging_in = false
                        s.waiting_for_spawn_choice = false
                        s.spawn_timer_seconds = 0
                        if s.pending_server_wait_seconds > 0 then
                            local wait_sec = s.pending_server_wait_seconds
                            s.pending_server_wait_seconds = 0
                            log("Ожидание /rec " .. tostring(wait_sec))
                            reconnect._internal.mark_manual_reconnect("WaitRequest", wait_sec)
                        else
                            reconnect.trigger_reconnect("ChatlogDisconnect")
                        end
                    end

                    -- CONNECTION REJECTED / Unacceptable NickName -> /rec 3
                    if low:find("connection rejected") or low:find("unacceptable nickname") then
                        log("CONNECTION REJECTED (NickName), выполняю /rec 3")
                        reconnect.do_fast_reconnect(3)
                    end
                end
            end
        end
    end
end

function M.is_password_form_visible()
    if s.force_password_form and not s.password_form_closed then
        if s.is_spawned then return false end
        return true
    end
    return false
end

function M.close_password_form()
    if s.password ~= "" then
        s.password_form_closed = true
        log("Форма пароля закрыта")
    end
end

function M.force_show_password_form()
    s.force_password_form = true
    s.password_form_closed = false
    utils.play_auth_sounds_if_needed()
    log("Принудительно открываем форму авторизации")
end

function M.schedule_autologin_after_reconnect()
    s.pending_autologin = true
    s.is_logging_in = false
    s.login_submitted = false
    s.is_spawned = false
    if s.password ~= "" then
        s.force_password_form = false
    end
    s.password_form_closed = false
    s.last_login_attempt = 0
    log("Автовход запланирован после реконнекта")
end

function M.on_password_saved()
    if s.password ~= "" then
        s.force_password_form = false
    end
    s.password_form_closed = false
    s.pending_autologin = true
    s.is_spawned = false
    s.is_logging_in = false
    s.last_login_attempt = 0
    if s.password ~= "" and s.my_nick ~= "" and isSampAvailable() then
        lua_thread.create(function()
            for attempt = 1, 8 do
                wait(2500)
                if s.is_spawned or not s.script_active or s.password == "" then return end
                if s.is_logging_in or s.login_submitted then return end
                M._internal.perform_login()
            end
        end)
    end
    log("Пароль сохранён, вход запланирован")
end

function M.reset_login_state()
    s.is_logging_in = false
    s.login_submitted = false
    s.last_close_menu_emul = 0
end

M._internal = {}

M.type_password = function()
	local __bw = function(ms)
		local t = os.clock()
		while (os.clock() - t) * 1000 < ms do end
	end
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
	for i = 1, #s.password do
		local ch = s.password:sub(i, i)
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
				user32.keybd_event(0x10, 0, 0, 0)
				__bw(25)
			end
			user32.keybd_event(vkey, 0, 0, 0)
			__bw(30)
			user32.keybd_event(vkey, 0, 2, 0)
			__bw(30)
			if needs_shift then
				user32.keybd_event(0x10, 0, 2, 0)
				__bw(25)
			end
		end
		__bw(40)
	end
log("Пароль введён полностью")
end

-- ---------------------------------------------------------------
-- Пакетная авторизация: прямая отправка OnAuthorizationStart (id=215)
-- через raknetSendBitStream (полный пакет с первым байтом D7).
-- Проверена на RADMIR CRMP: сервер принимает пароль без ввода в форму.
-- ---------------------------------------------------------------
local auth_pas = { string.byte("OnAuthorizationStart", 1, 20) }

local function int32_le_bytes(v)
    v = v % 4294967296
    return { v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256 }
end

local function build_password_packet(password)
    local p = {}
    local function push(x) p[#p + 1] = x end
    for i = 1, 4 do push(int32_le_bytes(2)[i]) end
    push(0); push(0)
    for i = 1, 4 do push(int32_le_bytes(#auth_pas)[i]) end
    for i = 1, #auth_pas do push(auth_pas[i]) end
    for i = 1, 4 do push(int32_le_bytes(2)[i]) end
    push(string.byte("s"))
    for i = 1, 4 do push(int32_le_bytes(#password)[i]) end
    for i = 1, #password do push(string.byte(password, i)) end
    return p
end

function M.send_password_packet(pw)
    local password = pw or s.password
    if not password or password == "" then
        log("пакет: пароль не задан")
        return false
    end
    if not isSampAvailable() then
        log("пакет: SA:MP недоступен, отправка пропущена")
        return false
    end
    local body = build_password_packet(password)
    local full = {}
    full[1] = 215
    for i = 1, #body do full[#full + 1] = body[i] end
    local ok_bs, bs = pcall(raknetNewBitStream)
    if not ok_bs or not bs then
        log("пакет: raknetNewBitStream недоступен")
        return false
    end
    local ok_w, err_w = pcall(function()
        for i = 1, #full do
            raknetBitStreamWriteInt8(bs, full[i])
        end
    end)
    if not ok_w then
        raknetDeleteBitStream(bs)
        log("пакет: ошибка записи битстрима: " .. tostring(err_w))
        return false
    end
    local ok_s, res_s = pcall(raknetSendBitStream, bs)
    raknetDeleteBitStream(bs)
    log(string.format("пакет: OnAuthorizationStart отправлен (%d байт, пароль %d симв.), ok=%s, результат=%s",
        #full, #password, tostring(ok_s), tostring(res_s)))
    return ok_s
end

local last_packet_send = 0

M._internal.perform_login = function()
    if not s.script_active then return end
    if s.password == "" then
        M.force_show_password_form()
        return
    end
    if s.packetauth then
        -- Пакетный вход: отправляем строго по факту окна авторизации,
        -- не раньше (иначе пакет уходит в никуда до прихода AuthorizationS)
        if s.cef_auth_window_seen and not s.is_spawned then
            local now = os.clock()
            if now - last_packet_send >= 5 then
                last_packet_send = now
                log("perform_login: пакетная отправка (окно авторизации)")
                lua_thread.create(function()
                    wait(500)
                    if not s.is_spawned then
                        M.send_password_packet(s.password)
                    end
                end)
            end
        else
            log("perform_login: пакетный режим, окна нет (cef="
                .. tostring(s.cef_auth_window_seen) .. ", spawned=" .. tostring(s.is_spawned) .. ")")
        end
        return
    end
    s.login_requested = true
    log("perform_login: запрошен вход в игру")
end

M._internal.perform_login_sequence_legacy = function()
    local login_start = os.clock()
    local LOGIN_TIMEOUT = 30 -- seconds
    local ui_mod = require("AutoLoginByYaroRage.ui")

    ui_mod.setLoading(true, "Выполняю вход...")

    utils.wait_for_focus()
    wait(1200)
    if s.is_spawned then
        s.is_logging_in = false
        return
    end

    local hkl = user32.LoadKeyboardLayoutA("00000409", 1)
    if hkl ~= nil then
        user32.ActivateKeyboardLayout(hkl, 0)
    end
    wait(300)

    local sw, sh = getScreenResolution()
    log(string.format("Разрешение: %dx%d", sw, sh))

    -- Адаптивные координаты клика по полю пароля
    -- Пробуем определить позицию окна авторизации CEF, иначе относительные координаты
    local click_x, click_y = utils.get_password_field_pos(sw, sh)
    user32.SetCursorPos(click_x, click_y)
    wait(50)
    user32.mouse_event(0x02, 0, 0, 0, 0)
    wait(50)
    user32.mouse_event(0x04, 0, 0, 0, 0)
    wait(50)
    wait(200)

    -- Вставляем пароль из буфера обмена: Ctrl+A, Ctrl+V
    -- (посимвольный ввод с Shift ронял клиент SA-MP)
    utils.set_clipboard_text(s.password)
    user32.keybd_event(0x11, 0, 0, 0)
    wait(50)
    user32.keybd_event(0x41, 0, 0, 0)
    wait(50)
    user32.keybd_event(0x41, 0, 2, 0)
    user32.keybd_event(0x11, 0, 2, 0)
    wait(100)
    user32.keybd_event(0x11, 0, 0, 0)
    wait(50)
    user32.keybd_event(0x56, 0, 0, 0)
    wait(50)
    user32.keybd_event(0x56, 0, 2, 0)
    user32.keybd_event(0x11, 0, 2, 0)
    wait(200)

    ui_mod.setLoading(true, "Отправляю пароль... ждём вход")

    user32.keybd_event(0x0D, 0, 0, 0)
    wait(30)
    user32.keybd_event(0x0D, 0, 2, 0)
    s.login_submitted = true
    s.close_menu_emul_until = 0
    s.reconnect_watch_active = false
    log("Пароль введён. CEF-пакет 215 ждём после входа в мир")

    -- Ждём спавна с таймаутом
    local wait_start = os.clock()
    while not s.is_spawned and os.clock() - wait_start < 15 do
        wait(200)
        if os.clock() - login_start > LOGIN_TIMEOUT then
            log("perform_login: время вышло " .. LOGIN_TIMEOUT .. "s, сброс")
            s.is_logging_in = false
            s.login_submitted = false
            return
        end
    end

    if not s.is_spawned then
        log("perform_login_legacy: не дождались спавна, сброс")
        s.is_logging_in = false
        s.login_submitted = false
        ui_mod.setLoading(false)
    else
        ui_mod.setLoading(false)
        s.is_logging_in = false
    end
end

M._internal.perform_login_sequence = function()
    local login_start = os.clock()
    local LOGIN_TIMEOUT = 30 -- seconds
    local RETRY_INTERVAL = 10 -- seconds
    local ui_mod = require("AutoLoginByYaroRage.ui")

    ui_mod.setLoading(true, "Отправляю пароль пакетом...")

    wait(600)
    if s.is_spawned then
        s.is_logging_in = false
        return
    end

    M.send_password_packet(s.password)

    s.login_submitted = true
    s.force_password_form = false
    s.password_form_closed = true
    s.close_menu_emul_until = 0
    s.reconnect_watch_active = false

    -- Ждём появления в мире, при необходимости повторяем отправку
    local last_send = os.clock()
    while not s.is_spawned and os.clock() - login_start < LOGIN_TIMEOUT do
        wait(500)
        if os.clock() - login_start > LOGIN_TIMEOUT then
            log("perform_login: время вышло " .. LOGIN_TIMEOUT .. "s, сброс")
            s.is_logging_in = false
            s.login_submitted = false
            ui_mod.setLoading(false)
            return
        end
        if os.clock() - last_send >= RETRY_INTERVAL then
            last_send = os.clock()
            M.send_password_packet(s.password)
        end
    end

    ui_mod.setLoading(false)
    s.is_logging_in = false
    s.login_submitted = false
end

M._internal.login_worker_thread = function()
    while true do
        wait(250)
        if s.script_active and s.login_requested then
            if s.password == "" then
                s.login_requested = false
                M.force_show_password_form()
            elseif not s.is_logging_in and not s.login_submitted and not s.is_spawned and isSampAvailable() then
                s.login_requested = false
                s.is_logging_in = true
                s.login_submitted = false
                s.last_close_menu_emul = 0
                s.close_menu_emul_until = 0
                s.reconnect_watch_active = false
                log("perform_login: старт ввода")
                if s.packetauth then
                    M._internal.perform_login_sequence()
                else
                    M._internal.perform_login_sequence_legacy()
                end
            end
        end
    end
end

return M
