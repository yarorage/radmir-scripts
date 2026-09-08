-- Модуль обнаружения админов AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local M = {}

function M.learn_admin_name(text)
    local s = AL.state
    local name = text:match("^Администратор%s+([%w_]+)")
    if name and #name > 0 then
        for _, existing in ipairs(s.admin_names) do
            if existing:lower() == name:lower() then return end
        end
        table.insert(s.admin_names, name)
    end
end

function M.has_known_admin(text)
    local s = AL.state
    if #s.admin_names == 0 then return false end
    local lower_text = text:lower()
    for _, name in ipairs(s.admin_names) do
        local lname = name:lower()
        -- Exact word match using word boundaries
        if lower_text:find("%f[%w]" .. lname .. "%f[^%w]") then
            return true
        end
    end
    return false
end

function M.is_ooc_message(text)
    return text:find("%(%(") and text:find("%)%)")
end

function M.extract_ooc_name(text)
    return text:match("%{v:([%w_]+)%}")
end

function M.is_admin_message(color, text)
    local s = AL.state
    local lower_text = text:lower()

    if lower_text:find("^Администратор%s") or lower_text:find("^administrator%s") then
        M.learn_admin_name(text)
        return true
    end

    if M.has_known_admin(text) then return true end

    if M.is_ooc_message(text) then
        local ooc_name = M.extract_ooc_name(text)
        if ooc_name then
            for _, name in ipairs(s.admin_names) do
                if name:lower() == ooc_name:lower() then return true end
            end
        end
    end

    if s.admin_color_pattern and color then
        local color_str = tostring(color)
        if color_str:find(s.admin_color_pattern) then return true end
    end

    return false
end

function M.handle_admin_kick(source_text, where)
    local s = AL.state
    if not M.has_known_admin(source_text) then return end
    AL.log(where .. ": Обнаружен админ в игре")
    
    -- Take screenshot if enabled
    if s.auto_screenshot_admin then
        local utils = require("AutoLoginByYaroRage.utils")
        local filename = "admin_detected_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
        utils.take_screenshot(filename)
        AL.log("Screenshot saved: " .. filename)
    end
    
    -- Send to Telegram/Discord if enabled
    if s.tg_enabled then
        local telegram = require("AutoLoginByYaroRage.telegram")
        local safe_text = source_text:gsub("<[^>]+>", ""):sub(1, 500)
        telegram.send_message("[Admin Detected] " .. safe_text)
    end
    if #s.discord_webhook > 0 then
        local telegram = require("AutoLoginByYaroRage.telegram")
        telegram.discord_send(s.discord_webhook, "Admin detected!", {{title="Admin Kick", description=source_text:sub(1, 1000), color=15158332}})
    end
    
    s.is_spawned = false
    local reconnect = require("AutoLoginByYaroRage.reconnect")
    reconnect.trigger_reconnect("admin_kick")
end

return M
