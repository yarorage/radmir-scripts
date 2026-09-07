-- Обёртка json-совместимого модуля на базе dkjson
-- Используется скриптами, которым нужен require 'json' с encode/decode
local dkjson = require("dkjson")

local M = {}

function M.encode(o, opts)
    if opts then return dkjson.encode(o, opts) end
    return dkjson.encode(o)
end

function M.decode(str, pos, nullval, opts)
    local value, next_pos, err
    if opts then
        value, next_pos, err = dkjson.decode(str, pos, nullval, opts)
    else
        value, next_pos, err = dkjson.decode(str, pos, nullval)
    end
    if err then
        return nil, err
    end
    return value, next_pos
end

return M