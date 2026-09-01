-- ?? Библиотека ylog.lua для красивого логирования от YaroRage

local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

--- @param scriptname string Название скрипта или имя файла без расширения
--- @param message   string Текст сообщения после "by"
return function(scriptname, message)
    local COLOR_GREEN = '{45D900}' -- Зелёный [Имя]
    local COLOR_RED   = '{E64F42}' -- Красный [YaroRage]
    local COLOR_WHITE = '{FFFFFF}' -- Белый [Текст]

    sampAddChatMessage(
        string.format('%s%s %sby %sYaroRage:%s %s',
            COLOR_GREEN, scriptname,
            COLOR_WHITE,
            COLOR_RED,
            COLOR_WHITE,
            message),
        -1
    )
end