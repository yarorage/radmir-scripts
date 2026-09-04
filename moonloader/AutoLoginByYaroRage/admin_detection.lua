-- Модуль определения админов AutoLoginByYaroRage
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
        if lower_text:find(name:lower()) then
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

    if lower_text:find("^администратор%s") or lower_text:find("^administrator%s") then
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
    AL.log(where .. ": обнаружено удаление от админа")
    s.is_spawned = false
    local reconnect = require("AutoLoginByYaroRage.reconnect")
    reconnect.trigger_reconnect("admin_kick")
end

return M
