-- Модуль общего состояния AutoLoginByYaroRage
local M = {}

M.state = {
    -- Настройки
    script_name = "AutoLoginByYaroRage",
    config_folder = nil,
    config_file = nil,

    -- Авторизация (current active)
    password = "",
    spawn_choice = true,
    script_active = true,
    my_nick = "",

    -- Account Profiles
    profiles = {},
    current_profile = "default",

    -- Discord Webhook
    discord_webhook = "",

    -- State Machine: login/spawn states
    login_state = "IDLE",  -- IDLE, LOGGING_IN, WAITING_SPAWN, SPAWNED, RECONNECTING

    -- Реконнект
    reconnect_attempt_count = 0,
    reconnect_pause_until = 0,
    reconnect_cooldown_until = 0,
    reconnect_watch_active = false,
    reconnect_watch_start_time = 0,
    saw_loading_after_rec = false,
    saw_queue_after_rec = false,
    saw_menu_pause_after_esc = false,
    pending_autologin = false,
    last_login_attempt = 0,
    pending_server_wait_seconds = 0,

    -- Queue parsing
    queue_position = 0,
    queue_eta = 0,
    queue_total = 0,
    queue_detected = false,

-- CEF-флаги (окно авторизации: сброс состояния при входе)
    packetauth = true,                      -- вход через RakNet-пакет OnAuthorizationStart (без ввода в форму)
    cef_auth_kind = nil,                    -- буква окна авторизации: S, A, B, C ...
    cef_auth_window_seen = false,       -- флаг окна авторизации (Authorization "auth" / OnAuthorizationStart)
    cef_loading_seen = false,           -- Loading[3000] (загрузка)
    cef_open_menu_pause_seen = false,   -- OnPlayerOpenMenuPause (окно паузы открыто)
    cef_close_menu_pause_seen = false,  -- OnPlayerCloseMenuPause (окно паузы закрыто)
    cef_world_entered_seen = false,     -- Вход в мир (setPlayerNickName / игрок авторизован)
    cef_spawn_select_seen = false,      -- SelectSpawn (выбор спавна)
    cef_wrong_password_seen = false,    -- setError "неверный пароль"
    cef_limit_seen = false,             -- лимит попыток / бан / сообщение CEF
    cef_device_lost_seen = false,       -- OnPlayerDeviceLost (браузер потерян)
    cef_device_restore_seen = false,    -- OnPlayerDeviceRestore (браузер восстановлен)
    cef_browser_initialized = false,    -- EndedInitializeBrowser (CEF готов)
    cef_tx_log_enabled = true,          -- логировать исходящие CEF (TX id=215)
    cef_dialog_close_tx = true,         -- закрывать диалоги-лимиты CEF-пакетом вместо Esc
    cef_emul_depth = 0,                 -- глубина эмуляции кликов CEF (для проверки реального времени)

-- Спавн
    waiting_for_spawn_choice = false,
    current_dialog_id = -1,
    spawn_timer_seconds = 0,
    spawn_timer_running = false,

    -- Восстановление позиции
    restore_active = false,
    restore_timer_seconds = 15,
    restore_deadline = 0,
    restore_answered = false,
    restore_btn_rect = nil,
    restore_last_lmb = false,

    -- UI
    force_password_form = false,
    password_form_closed = false,
    render_disabled = true,
    render_disabled_until = 0,
    cursor_was_visible = false,

    -- Admin screenshot
    auto_screenshot_admin = true,

    -- Авторизация (внутреннее)
    CLOSE_MENU_EMUL_AFTER_SEC = 5,
    close_menu_emul_until = 0,
    last_close_menu_emul = 0,
    login_submitted = false,

    -- Anti-AFK
    mafk_active = false,
    mafk_hold_start = 0,
    mafk_notify_until = 0,
    afk_mode = 0,
    auto_restart = true,

    -- Telegram
    tg_bot_token = "",
    tg_chat_id = "",
    tg_last_update_id = 0,
    tg_enabled = false,
    tg_last_send_time = 0,

    -- Админы
    admin_names = {},
    admin_color_pattern = nil,


    -- Fast Reconnect (из RecconnectByYaroRage)
    fast_reconnect_enabled = false,

    -- Health/Armor monitoring
    auto_heal_enabled = false,
    auto_armor_enabled = false,
    heal_threshold = 50,
    armor_threshold = 50,
    heal_amount = 100,
    armor_amount = 100,
    heal_cooldown = 5000,

    -- Auto-updater
    auto_update_enabled = true,
    update_check_interval = 3600,
    github_repo = "yarorage/radmir-scripts",
    current_version = script_version(),
    last_update_check = 0,

    -- Logging
    log_level = 2, -- 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
    log_to_file = true,
    log_file_max_size = 1024 * 1024, -- 1MB
    log_file_path = nil,

    -- Дистанция рейкаста
    RAYCAST_DISTANCE = 2.0,
    RAYCAST_ANGLE_OFFSET = math.pi / 4,

    -- Debug
    debug_step = 0,
}

M.state.AUTH_SOUND_PATH = nil

function M.log(msg)
    local line = string.format("[%s] [AutoLogin] %s", os.date("%H:%M:%S"), tostring(msg))
    print(line)
    local s = M.state
    if s and s.config_folder and #s.config_folder > 0 then
        pcall(function()
            local f = io.open(s.config_folder .. "\\AutoLoginByYaroRage.log", "a")
            if f then
                f:write(line, "\n")
                f:close()
            end
        end)
    end
end

function M.dlog(msg)
    M.state.debug_step = M.state.debug_step + 1
    print(string.format("[AutoLogin][%d][%.3f] %s", M.state.debug_step, os.clock(), tostring(msg)))
end

function M.chat_msg(msg)
    if isSampAvailable and isSampAvailable() then
        sampAddChatMessage(string.format("{33FF99}[AutoLogin]{FFFFFF} %s", tostring(msg)), -1)
    end
end

-- State Machine helpers
M.set_login_state = function(new_state)
    local s = M.state
    local old_state = s.login_state
    if old_state == new_state then return end
    
    -- Valid transitions
    local valid_transitions = {
        IDLE = {"LOGGING_IN", "RECONNECTING"},
        LOGGING_IN = {"WAITING_SPAWN", "IDLE", "RECONNECTING"},
        WAITING_SPAWN = {"SPAWNED", "IDLE", "RECONNECTING"},
        SPAWNED = {"IDLE", "RECONNECTING"},
        RECONNECTING = {"LOGGING_IN", "IDLE"},
    }
    
    local valid = false
    for _, v in ipairs(valid_transitions[old_state] or {}) do
        if v == new_state then valid = true; break end
    end
    
    if not valid and old_state ~= "IDLE" then
        M.log("State transition " .. old_state .. " -> " .. new_state .. " may be invalid")
    end
    
    s.login_state = new_state
    M.log("State: " .. old_state .. " -> " .. new_state)
    
    -- Sync legacy flags for backward compatibility
    if new_state == "LOGGING_IN" then
        s.is_logging_in = true
        s.is_spawned = false
        s.player_in_world = false
    elseif new_state == "WAITING_SPAWN" then
        s.is_logging_in = false
        s.waiting_for_spawn_choice = true
    elseif new_state == "SPAWNED" then
        s.is_spawned = true
        s.player_in_world = true
        s.is_logging_in = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
    elseif new_state == "IDLE" then
        s.is_logging_in = false
        s.is_spawned = false
        s.player_in_world = false
        s.waiting_for_spawn_choice = false
        s.spawn_timer_seconds = 0
        s.spawn_timer_running = false
        s.login_submitted = false
    elseif new_state == "RECONNECTING" then
        s.is_reconnecting = true
        s.is_logging_in = false
        s.is_spawned = false
        s.player_in_world = false
        s.waiting_for_spawn_choice = false
    end
end

M.get_login_state = function()
    return M.state.login_state
end

M.is_in_state = function(state)
    return M.state.login_state == state
end

M.reset_login_state = function()
    M.set_login_state("IDLE")
    M.state.reconnect_attempt_count = 0
    M.state.reconnect_pause_until = 0
    M.state.reconnect_cooldown_until = 0
    M.state.is_reconnecting = false
    M.state.reconnect_watch_active = false
    M.state.reconnect_watch_start_time = 0
    M.state.saw_loading_after_rec = false
    M.state.saw_queue_after_rec = false
    M.state.saw_menu_pause_after_esc = false
    M.state.pending_autologin = false
    M.state.last_login_attempt = 0
    M.state.pending_server_wait_seconds = 0
    M.state.cef_auth_window_seen = false
    M.state.cef_loading_seen = false
    M.state.cef_open_menu_pause_seen = false
    M.state.cef_close_menu_pause_seen = false
    M.state.cef_world_entered_seen = false
    M.state.cef_spawn_select_seen = false
    M.state.cef_wrong_password_seen = false
    M.state.cef_limit_seen = false
    M.state.cef_emul_depth = 0
    M.state.cef_device_lost_seen = false
    M.state.cef_device_restore_seen = false
    M.state.cef_browser_initialized = false
    M.state.restore_active = false
    M.state.restore_deadline = 0
    M.state.restore_answered = false
    M.state.restore_btn_rect = nil
    M.state.restore_last_lmb = false
end

-- Profile management
M.get_active_profile = function()
    local s = M.state
    return s.profiles[s.current_profile] or {password = "", nick = ""}
end

M.set_active_profile = function(name)
    local s = M.state
    if not s.profiles[name] then
        s.profiles[name] = {password = "", nick = ""}
    end
    s.current_profile = name
    local prof = s.profiles[name]
    s.password = prof.password or ""
    s.my_nick = prof.nick or ""
    M.log("Switched to profile: " .. name)
end

M.save_current_profile = function()
    local s = M.state
    s.profiles[s.current_profile] = {
        password = s.password,
        nick = s.my_nick
    }
    M.log("Profile saved: " .. s.current_profile)
end

M.delete_profile = function(name)
    local s = M.state
    if s.profiles[name] then
        s.profiles[name] = nil
        if s.current_profile == name then
            s.current_profile = "default"
            local prof = s.profiles["default"] or {password = "", nick = ""}
            s.password = prof.password or ""
            s.my_nick = prof.nick or ""
        end
        M.log("Profile deleted: " .. name)
    end
end

M.list_profiles = function()
    local s = M.state
    local list = {}
    for name, _ in pairs(s.profiles) do
        table.insert(list, name)
    end
    return list
end

return M
