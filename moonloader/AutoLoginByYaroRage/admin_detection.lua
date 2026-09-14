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

local KICK_VERBS = {
    "кикнул", "кикнула", "кикает",
    "kick", "kicked", "ban", "banned",
    "забанил", "забанила",
    "исключил", "исключила",
    "выгнал", "выгнала",
    "выкинул", "удалил",
}

function M.is_admin_kick_of_self(text)
    local s = AL.state
    local nick = (s.my_nick or ""):lower()
    if #nick == 0 then return false end
    local lower_text = (text or ""):lower()

    -- 1. Сообщение принадлежит администратору
    local has_admin = lower_text:find("администратор", 1, true)
        or lower_text:find("administrator", 1, true)
        or lower_text:find("admin", 1, true)
    if not has_admin then return false end

    -- 2. Содержит глагол кика
    local has_kick_verb = false
    for _, verb in ipairs(KICK_VERBS) do
        if lower_text:find(verb, 1, true) then has_kick_verb = true break end
    end
    if not has_kick_verb then return false end

    -- 3. Упоминается наш ник
    if not lower_text:find(nick, 1, true) then return false end
    return true
end

function M.handle_admin_kick(source_text, where)
    if not M.is_admin_kick_of_self(source_text) then return end
    local s = AL.state
    AL.log(where .. ": админ кикнул нас, выполняю реконнект")
    s.is_spawned = false
    local reconnect = require("AutoLoginByYaroRage.reconnect")
    reconnect.trigger_reconnect("admin_kick")
end

return M
