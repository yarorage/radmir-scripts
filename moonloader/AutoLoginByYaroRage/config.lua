-- Конфигурация AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local utils = require("AutoLoginByYaroRage.utils")
local M = {}

-- Схема конфигурации с валидацией
local CONFIG_SCHEMA = {
    Password = { type = "string", default = "", encrypt = true },
    SpawnChoice = { type = "boolean", default = true },
    ScriptActive = { type = "boolean", default = true },
    AutoRestart = { type = "boolean", default = true },
    MafkEnabled = { type = "boolean", default = false },
    TelegramBotToken = { type = "string", default = "", validate = function(v) return #v == 0 or v:match("^%d+:.+$") end },
    TelegramChatId = { type = "string", default = "", validate = function(v) return #v == 0 or v:match("^%-?%d+$") end },
    AdminNames = { type = "string", default = "" },
    AdminColorPattern = { type = "string", default = "" },
    FastReconnectEnabled = { type = "boolean", default = true },
    PacketAuth = { type = "boolean", default = true },
    CefDialogCloseTx = { type = "boolean", default = true },
    Profiles = { type = "string", default = "{}" }, -- JSON encoded profiles
    CurrentProfile = { type = "string", default = "default" },
    DiscordWebhook = { type = "string", default = "", validate = function(v) return #v == 0 or v:match("^https://discord%.com/api/webhooks/") end },
    AutoSkipCutscenes = { type = "boolean", default = true },
    AutoSkipDialogs = { type = "boolean", default = true },
    SkipDialogDelay = { type = "number", default = 500 },
    AutoScreenshotAdmin = { type = "boolean", default = true },
    AutoHealEnabled = { type = "boolean", default = false },
    AutoArmorEnabled = { type = "boolean", default = false },
    HealThreshold = { type = "number", default = 50 },
    ArmorThreshold = { type = "number", default = 50 },
    HealAmount = { type = "number", default = 100 },
    ArmorAmount = { type = "number", default = 100 },
    HealCooldown = { type = "number", default = 5000 },
    AutoUpdateEnabled = { type = "boolean", default = true },
    UpdateCheckInterval = { type = "number", default = 3600 },
    GitHubRepo = { type = "string", default = "yarorage/radmir-scripts" },
}

-- Парсинг INI файла
local function parse_ini(content)
    local result = {}
    local current_section = "DEFAULT"
    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$") -- trim
        if line ~= "" and not line:match("^;") and not line:match("^#") then
            local section = line:match("^%[(.+)%]$")
            if section then
                current_section = section
                result[current_section] = result[current_section] or {}
            else
                local key, value = line:match("^([^=]+)%s*=%s*(.*)$")
                if key then
                    key = key:match("^%s*(.-)%s*$")
                    value = value:match("^%s*(.-)%s*$")
                    if not result[current_section] then
                        result[current_section] = result[current_section] or {}
                    end
                    -- Remove quotes if present
                    if value:match('^".*"$') or value:match("^'.*'$") then
                        value = value:sub(2, -2)
                    end
                    result[current_section][key] = value
                end
            end
        end
    end
    return result
end

-- Валидация и приведение типов
local function validate_and_cast(key, value)
    local schema = CONFIG_SCHEMA[key]
    if not schema then return value end -- Unknown keys pass through
    
    if schema.type == "boolean" then
        if value == "true" or value == "1" or value == "yes" then return true
        elseif value == "false" or value == "0" or value == "no" then return false
        else return schema.default end
    elseif schema.type == "string" then
        if schema.validate and not schema.validate(value) then
            AL.log("Config validation failed for " .. key .. ": " .. tostring(value))
            return schema.default
        end
        return value
    end
    return value
end

local function ensure_config_exists()
    local s = AL.state
    if not doesFileExist(s.config_file) then
        local f = io.open(s.config_file, "w")
        if f then
            f:write("[AutoLoginByYaroRage]\n")
            for key, schema in pairs(CONFIG_SCHEMA) do
                local val = schema.default
                if schema.encrypt and val ~= "" then
                    val = utils.encrypt_password(val)
                end
                f:write(string.format('%s = %s\n', key, schema.type == "string" and '"' .. val .. '"' or tostring(val)))
            end
            f:close()
            AL.log("Создан дефолтный конфиг")
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
        AL.log("Не удалось открыть конфиг: " .. s.config_file)
        return
    end

    local content = f:read("*a")
    f:close()

    local parsed = parse_ini(content)
    local section = parsed.DEFAULT or parsed.AutoLoginByYaroRage or {}
    
    for key, schema in pairs(CONFIG_SCHEMA) do
        local raw = section[key]
        if raw ~= nil then
            local validated = validate_and_cast(key, raw)
            if key == "Password" and validated ~= "" then
                s.password = utils.decrypt_password(validated)
            elseif key == "Profiles" then
                local dkjson = require("dkjson")
                s.profiles = dkjson.decode(validated) or {}
            elseif key == "CurrentProfile" then
                s.current_profile = validated
            elseif key == "CefDialogCloseTx" then
                s.cef_dialog_close_tx = validated
            else
                s[key:lower()] = validated
            end
        else
            -- Use default
            if key == "Password" then
                s.password = schema.default
            elseif key == "Profiles" then
                s.profiles = {}
            elseif key == "CurrentProfile" then
                s.current_profile = schema.default
            elseif key == "CefDialogCloseTx" then
                s.cef_dialog_close_tx = schema.default
            else
                s[key:lower()] = schema.default
            end
        end
    end

    -- Handle AdminNames specially (comma-separated)
    if section.AdminNames then
        s.admin_names = {}
        for name in section.AdminNames:gmatch("[^,]+") do
            local trimmed = name:match("^%s*(.-)%s*$")
            if trimmed and #trimmed > 0 then
                table.insert(s.admin_names, trimmed)
            end
        end
    end

    -- Load active profile data
    local active = s.profiles[s.current_profile]
    if active then
        s.password = active.password or ""
        s.my_nick = active.nick or ""
    end

    AL.log("Конфиг загружен")
end

function M.save()
    local s = AL.state
    local f = io.open(s.config_file, "w")
    if not f then
        AL.log("Ошибка записи конфига!")
        return
    end

    -- Save current profile data
    s.profiles[s.current_profile] = {
        password = s.password,
        nick = s.my_nick
    }
    local dkjson = require("dkjson")

    f:write("; AutoLoginByYaroRage Configuration\n")
    f:write("; Generated at " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    
    f:write("[AutoLoginByYaroRage]\n")
    for key, schema in pairs(CONFIG_SCHEMA) do
        local val
        if key == "Password" then
            val = utils.encrypt_password(s.password)
        elseif key == "AdminNames" then
            val = table.concat(s.admin_names or {}, ",")
        elseif key == "Profiles" then
            val = dkjson.encode(s.profiles)
        elseif key == "CurrentProfile" then
            val = s.current_profile
        elseif key == "CefDialogCloseTx" then
            val = s.cef_dialog_close_tx
        else
            val = s[key:lower()]
        end
        
        if schema.type == "string" then
            f:write(string.format('%s = "%s"\n', key, val))
        else
            f:write(string.format('%s = %s\n', key, tostring(val)))
        end
    end
    f:close()

    AL.log("Конфиг сохранён")
end

function M.update_mafk_config()
    M.save()
end

-- Export schema for external use
M.CONFIG_SCHEMA = CONFIG_SCHEMA

return M