-- Вспомогательные функции перекодировки для CefPacketAnalyzer
-- Скрипты moonloader хранятся и выполняются в CP1251: строковые литералы движка
-- содержат байты CP1251. Отчёты пишутся в UTF-8 (json/summary/stream) и в CP1251
-- (html). Здесь собраны безопасные конвертации на базе модуля encoding moonloader.
local M = {}

local function getEncoding()
    local ok, enc = pcall(require, "encoding")
    if ok and enc then
        return enc
    end
    return nil
end

-- Строка в байтах CP1251 (литерал движка) -> строка в UTF-8
function M.bytesCpToUtf8(s)
    local enc = getEncoding()
    if not enc then
        return tostring(s or "")
    end
    local ok, res = pcall(function()
        return enc.UTF8:encode(enc.CP1251:decode(tostring(s or "")))
    end)
    if ok and res then
        return res
    end
    return tostring(s or "")
end

-- Строка в UTF-8 -> байты CP1251 (для файлов с charset windows-1251)
function M.utf8ToBytesCp(s)
    local enc = getEncoding()
    if not enc then
        return tostring(s or "")
    end
    local ok, res = pcall(function()
        return enc.CP1251:encode(enc.UTF8:decode(tostring(s or "")))
    end)
    if ok and res then
        return res
    end
    return tostring(s or "")
end

return M