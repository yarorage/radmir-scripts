-- Модуль общего состояния AutoLoginByYaroRage
local M = {}

M.state = {
    -- Настройки
    script_name = "AutoLoginByYaroRage",
    config_folder = nil,
    config_file = nil,

    -- Авторизация
    password = "",
    spawn_choice = true,
    script_active = true,
    is_logging_in = false,
    is_spawned = false,
    player_in_world = false,
    my_nick = "",

    -- Реконнект
    reconnect_attempt_count = 0,
    reconnect_pause_until = 0,
    reconnect_cooldown_until = 0,
    is_reconnecting = false,
    reconnect_watch_active = false,
    saw_loading_after_rec = false,
    saw_queue_after_rec = false,
    pending_autologin = false,
    last_login_attempt = 0,

    -- Спавн
    waiting_for_spawn_choice = false,
    current_dialog_id = -1,
    spawn_timer_seconds = 0,
    spawn_timer_running = false,

    -- UI
    force_password_form = false,
    password_form_closed = false,
    render_disabled = true,
    render_disabled_until = 0,

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
    tg_bot_token = "5964346019:AAFmzZsSnRjGqRT1R36XIYtRa-WKwiqlZvo",
    tg_chat_id = "257942964",
    tg_last_update_id = 0,
    tg_enabled = false,
    tg_last_send_time = 0,

    -- Админы
    admin_names = {},
    admin_color_pattern = nil,

    -- Anti-Ticket (из antiafk [1.1])
    anti_ticket_enabled = true,

    -- Fast Reconnect (из RecconnectByYaroRage)
    fast_reconnect_enabled = true,

    -- Дистанция рейкаста
    RAYCAST_DISTANCE = 2.0,
    RAYCAST_ANGLE_OFFSET = math.pi / 4,

    -- Debug
    debug_step = 0,
}

M.state.AUTH_SOUND_PATH = nil

function M.log(msg)
    print(string.format("[AutoLogin] %s", tostring(msg)))
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

return M
