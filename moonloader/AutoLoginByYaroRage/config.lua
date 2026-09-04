-- Модуль конфигурации AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local M = {}

local function ensure_config_exists()
    local s = AL.state
    if not doesFileExist(s.config_file) then
        local f = io.open(s.config_file, "w")
        if f then
            f:write('Password = ""\n')
            f:write('SpawnChoice = true\n')
            f:write('ScriptActive = true\n')
            f:write('AutoRestart = true\n')
            f:write('MafkEnabled = false\n')
            f:write('TelegramBotToken = "5964346019:AAFmzZsSnRjGqRT1R36XIYtRa-WKwiqlZvo"\n')
            f:write('TelegramChatId = "257942964"\n')
            f:write('AdminNames = ""\n')
            f:write('AdminColorPattern = ""\n')
            f:write('AntiTicketEnabled = true\n')
            f:write('FastReconnectEnabled = true\n')
            f:close()
            AL.log("Настройки по умолчанию записаны")
        else
            AL.log("Ошибка создания конфига!")
        end
    end
end

function M.load()
    local s = AL.state
    ensure_config_exists()

    local f = io.open(s.config_file, "r")
    if not f then
        AL.log("Не удалось открыть файл: " .. s.config_file)
        return
    end

    local content = f:read("*a")
    f:close()

    local password = content:match('Password%s*=%s*"(.-)"')
    if password then s.password = password end

    local spawn_choice = content:match('SpawnChoice%s*=%s*(%a+)')
    if spawn_choice then s.spawn_choice = (spawn_choice ~= "false") end

    local script_active = content:match('ScriptActive%s*=%s*(%a+)')
    if script_active then s.script_active = (script_active ~= "false") end

    local auto_restart = content:match('AutoRestart%s*=%s*(%a+)')
    if auto_restart then s.auto_restart = (auto_restart ~= "false") end

    local mafk = content:match('MafkEnabled%s*=%s*(%a+)')
    if mafk then s.mafk_active = (mafk == "true") end

    local tg_token = content:match('TelegramBotToken%s*=%s*"(.-)"')
    if tg_token and #tg_token > 0 then s.tg_bot_token = tg_token end

    local tg_chat = content:match('TelegramChatId%s*=%s*"(.-)"')
    if tg_chat and #tg_chat > 0 then s.tg_chat_id = tg_chat end

    local admin_names = content:match('AdminNames%s*=%s*"(.-)"')
    if admin_names and #admin_names > 0 then
        s.admin_names = {}
        for name in admin_names:gmatch("[^,]+") do
            table.insert(s.admin_names, name:match("^%s*(.-)%s*$"))
        end
    end

    local admin_color = content:match('AdminColorPattern%s*=%s*"(.-)"')
    if admin_color and #admin_color > 0 then
        s.admin_color_pattern = admin_color
    end

    local anti_ticket = content:match('AntiTicketEnabled%s*=%s*(%a+)')
    if anti_ticket then s.anti_ticket_enabled = (anti_ticket == "true") end

    local fast_rec = content:match('FastReconnectEnabled%s*=%s*(%a+)')
    if fast_rec then s.fast_reconnect_enabled = (fast_rec == "true") end

    AL.log("Конфиг загружен")
end

function M.save()
    local s = AL.state
    local f = io.open(s.config_file, "w")
    if not f then
        AL.log("Ошибка записи конфига!")
        return
    end

    f:write(string.format('Password = "%s"\n', s.password))
    f:write(string.format('SpawnChoice = %s\n', tostring(s.spawn_choice)))
    f:write(string.format('ScriptActive = %s\n', tostring(s.script_active)))
    f:write(string.format('AutoRestart = %s\n', tostring(s.auto_restart)))
    f:write(string.format('MafkEnabled = %s\n', tostring(s.mafk_active)))
    f:write(string.format('TelegramBotToken = "%s"\n', s.tg_bot_token))
    f:write(string.format('TelegramChatId = "%s"\n', s.tg_chat_id))
    f:write(string.format('AdminNames = "%s"\n', table.concat(s.admin_names or {}, ",")))
    f:write(string.format('AdminColorPattern = "%s"\n', s.admin_color_pattern or ""))
    f:write(string.format('AntiTicketEnabled = %s\n', tostring(s.anti_ticket_enabled)))
    f:write(string.format('FastReconnectEnabled = %s\n', tostring(s.fast_reconnect_enabled)))
    f:close()

    AL.log("Конфиг сохранён")
end

function M.update_mafk_config()
    local s = AL.state
    if not doesFileExist(s.config_file) then return end

    local f = io.open(s.config_file, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()

    content = content:gsub('MafkEnabled%s*=%s*%a+', string.format('MafkEnabled = %s', tostring(s.mafk_active)))

    f = io.open(s.config_file, "w")
    if f then
        f:write(content)
        f:close()
    end
end

return M
