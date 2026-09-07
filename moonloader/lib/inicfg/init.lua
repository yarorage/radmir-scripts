-- Minimal inicfg module stub for mimgui compatibility

local ffi = require 'ffi'
local M = {}

function M.load(path)
    local file = io.open(path, 'r')
    if not file then return {} end
    local content = file:read('*a')
    file:close()
    
    local result = {}
    local current_section = 'main'
    result[current_section] = {}
    
    for line in content:gmatch('[^\r\n]+') do
        line = line:match('^%s*(.-)%s*$')
        if line ~= '' and not line:match('^;') and not line:match('^#') then
            local section = line:match('^%[(.+)%]$')
            if section then
                current_section = section
                result[current_section] = result[current_section] or {}
            else
                local key, value = line:match('^([^=]+)%s*=%s*(.*)$')
                if key then
                    key = key:match('^%s*(.-)%s*$')
                    value = value:match('^%s*(.-)%s*$')
                    if value:match('^%d+$') then
                        value = tonumber(value)
                    elseif value:match('^%d+%.%d+$') then
                        value = tonumber(value)
                    elseif value:lower() == 'true' then
                        value = true
                    elseif value:lower() == 'false' then
                        value = false
                    end
                    result[current_section][key] = value
                end
            end
        end
    end
    return result
end

function M.save(data, path)
    local lines = {}
    for section, values in pairs(data) do
        table.insert(lines, '[' .. section .. ']')
        for key, value in pairs(values) do
            local str_value
            if type(value) == 'boolean' then
                str_value = value and 'true' or 'false'
            else
                str_value = tostring(value)
            end
            table.insert(lines, key .. ' = ' .. str_value)
        end
        table.insert(lines, '')
    end
    
    local file = io.open(path, 'w')
    if file then
        file:write(table.concat(lines, '\r\n'))
        file:close()
        return true
    end
    return false
end

return {
    load = M.load,
    save = M.save
}
