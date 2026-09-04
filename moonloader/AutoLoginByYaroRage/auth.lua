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
    while not isSampAvailable() do wait(100) end
    wait(500)
    while true do
        wait(0)
        if not s.script_active then wait(1000); goto continue end
        if not s.force_password_form and s.password ~= "" and not s.is_logging_in and not s.is_spawned and s.pending_autologin then
            local now = os.clock()
            if (now - s.last_login_attempt) >= 1.5 then
                s.last_login_attempt = now
                s.pending_autologin = false
                log("chatlog_parser: попытка входа")
                M._internal.perform_login()
            end
        end
        ::continue::
    end
end

function M.is_password_form_visible()
    if s.force_password_form and not s.password_form_closed then
        if s.is_spawned then
            return false
        end
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
    log("Форма пароля принудительно открыта")
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
    log("Автологин запланирован после реконнекта")
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
    log("Пароль сохранён, автологин запланирован")
end

function M.reset_login_state()
    s.is_logging_in = false
    s.login_submitted = false
    s.last_close_menu_emul = 0
end

M._internal = {}

M._internal.perform_login = function()
    if not s.script_active then return end
    if s.password == "" then
        M.force_show_password_form()
        return
    end
    if s.is_logging_in or s.login_submitted then return end
    if not isSampAvailable() then return end

    s.is_logging_in = true
    s.login_submitted = false
    s.last_close_menu_emul = 0
    log("perform_login: попытка входа")

    local function try_click()
        if not s.script_active then return false end
        if s.is_spawned then return false end
        if not utils.is_scoreboard_or_dialog_open() then
            local clicked = utils.try_close_dialog_fast()
            if clicked then return true end
        end
        return false
    end

    local base_delay = 100
    local max_attempts = 25
    local attempt = 0
    local last_attempt_time = 0

    while s.script_active and not s.is_spawned and attempt < max_attempts do
        wait(0)
        local now = os.clock()
        if (now - last_attempt_time) * 1000 >= base_delay then
            last_attempt_time = now
            attempt = attempt + 1
            local clicked = try_click()
            if clicked then
                s.login_submitted = true
                log("perform_login: диалог закрыт, вход запущен")
                break
            end
            if not s.is_spawned then
                local clipboard_ok, clip = pcall(utils.get_clipboard_text)
                if not clipboard_ok then clip = "" end
                local pass_text = s.password
                if #pass_text > 0 and #clip == 0 then
                    pcall(utils.set_clipboard_text, pass_text)
                    wait(20)
                end
                if not s.is_spawned then
                    pcall(utils.send_paste_command)
                end
            end
        end
    end

    if not s.is_spawned then
        s.is_logging_in = false
        s.login_submitted = false
        log("perform_login: таймаут, сброс")
    end
end

return M
