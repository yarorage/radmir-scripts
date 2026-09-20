-- Модуль детектирования админов для MachinistByYaroRage.
-- Адаптирован из AutoLoginByYaroRage/admin_detection.lua (без своей state-зависимости).
local M = {}

local state = require("MachinistByYaroRage.state")

-- v0.9.3: нижний регистр кириллицы CP1251. Lua string.lower() трогает
-- только ASCII, поэтому серверное «Вы тут»/«Администратор» не находилось
-- байт-чувствительным поиском по «вы тут»/«администратор» — детект админов
-- работал вхолостую. Приводим верхний регистр А-Я (байты 0xC0..0xDF)
-- к нижнему а-я (0xE0..0xFF), остальные байты не трогаем.
local function casefoldCyr(s)
    if not s or #s == 0 then return s end
    return (s:gsub("[\128-\255]", function(ch)
        local b = ch:byte()
        if b >= 0xC0 and b <= 0xDF then return string.char(b + 32) end
        return ch
    end))
end

-- v1.2.8: экспортируем регистронезависимое приведение кириллицы наружу,
-- чтобы фильтры главного скрипта (например «на паузе N сек.») тоже им
-- пользовались вместо string.lower().
M.casefold = casefoldCyr

-- Результат парсинга: список имён.
local function parse_admin_names(str)
    local names = {}
    if not str or #str == 0 then return names end
    for name in str:gmatch("[^,;]+") do
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        if #name > 0 then names[#names + 1] = name end
    end
    return names
end

-- Чтение ников админов из файла config\CheatAdminList.txt.
-- В файле лежат очищенные ники (по одному на строку), но на всякий случай
-- строки формата "Ник|звание|дата" тоже понимаем: берём первое поле.
local fileCache = nil
local function read_file_names()
    local f = io.open(state.admin_file, "rb")
    if not f then return {} end
    local data = f:read("*a")
    f:close()
    if fileCache and fileCache.src == data then return fileCache.list end
    -- Ники в файле латиницей (ASCII), но читаем аккуратно: декодируем CP1251,
    -- чтобы корректно пережить возможные кириллические ники.
    local text = data
    local ok_enc, enc = pcall(require, "encoding")
    if ok_enc and enc and enc.CP1251 and enc.CP1251.decode then
        local ok_dec, decoded = pcall(enc.CP1251.decode, enc.CP1251, data)
        if ok_dec and decoded then text = decoded end
    end
    local names = {}
    for line in text:gmatch("[^\r\n]+") do
        line = line:gsub("%s*$", "")
        if #line > 0 then
            -- отделяем первый столбец (ник) от возможных "|звание|дата",
            -- либо берём токен до запятой/точки с запятой/пробела (защита от мусора)
            local nick = line:match("^%s*([^%s|,;]+)")
            if nick and #nick > 0 then names[#names + 1] = nick end
        end
    end
    fileCache = { src = data, list = names }
    return names
end

-- Кэш распарсенных имён: объединяем файловый список и ручной admin_names.
local cachedNames = nil
local function getAdminNames()
    local manual = state.state.admin_names or ""
    if not cachedNames or cachedNames.manual ~= manual then
        local names = {}
        for _, n in ipairs(parse_admin_names(manual)) do names[#names + 1] = n end
        for _, n in ipairs(read_file_names()) do
            local dup = false
            local lower = n:lower()
            for _, e in ipairs(names) do
                if e:lower() == lower then dup = true break end
            end
            if not dup then names[#names + 1] = n end
        end
        cachedNames = { manual = manual, list = names }
    end
    return cachedNames.list
end

-- Экспорт списка для GUI/команд: показывает реальный список админов,
-- который использует детект (файл + ручной список).
M.get_admin_names = getAdminNames

-- Проверка совпадения имени как ЦЕЛОГО слова в тексте.
-- Lua 5.1 не имеет %f, поэтому границу проверяем вручную.
local function wordFind(text, needle)
    if not needle or #needle == 0 then return false end
    local pos = 1
    while true do
        local s = text:find(needle, pos, true)
        if not s then return false end
        local e = s + #needle - 1
        local before = s > 1 and text:sub(s - 1, s - 1) or ""
        local after = e < #text and text:sub(e + 1, e + 1) or ""
        local function isWordChar(c)
            if c == "" then return false end
            return c:match("%w") ~= nil and c:find("%p") == nil
        end
        if not isWordChar(before) and not isWordChar(after) then
            return true
        end
        pos = e + 1
    end
end

-- Проверка вхождения известного админа в текст (целым словом).
function M.has_known_admin(text)
    if not text then return false end
    local names = getAdminNames()
    if #names == 0 then return false end
    local lower = text:lower()
    for _, name in ipairs(names) do
        if name and #name > 0 then
            if wordFind(lower, name:lower()) then return name end
        end
    end
    return false
end

-- Проверка, что текст похож на объявление об администраторе.
-- v0.9.3: префиксы заданы в нижнем регистре, поиск по приведённому
-- тексту — иначе серверное «Администратор» не находилось по маске.
local PREFIXES = { "администратор", "administrator" }

function M.has_admin_prefix(text)
    if not text then return false end
    local lower = casefoldCyr(text:lower())
    for _, p in ipairs(PREFIXES) do
        if lower:find(p, 1, true) then return true end
    end
    return false
end

-- Извлечение ника из OOC-сообщения вида (( Имя: текст )) или [Имя: текст]
function M.extract_ooc_name(text)
    if not text then return nil end
    local name = text:match("%(%(%s*(.-)%s*:)") or
                 text:match("%[%s*(.-)%s*:") or
                 text:match("%{(.-)%:") or
                 text:match("^%s*(%S+):")
    if name then
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        if #name > 0 then return name end
    end
    return nil
end

-- Главная проверка: является ли сообщение админским.
-- Возвращает имя админа или false.
-- v0.7.2: распознавание админских мписков/анти-бот проверок вида
--   «Администратор <ник_админа> для <ник_персонажа> Вы тут?
--    Напишите в чат /report - 1 я тут»
-- Берём ник админа после слова «Администратор»/«Administrator» и, если
-- передан myNick, оставляем только обращения «для <мой ник>» (иначе это
-- чужой вызов). Возвращает ник админа или true (маркер найден), либо nil.
function M.parse_admin_call(text, myNick)
    if not text or #text == 0 then return nil end
    local lower = casefoldCyr(text:lower())
    -- v1.1.5: маркером вызова считаются ТОЛЬКО реальные проверки игрока
    -- («Вы тут?», просьба написать /report, капча «2+2»), а НЕ слово
    -- «администратор»/«administrator» — из-за него ловились наказания другим
    -- игрокам («заблокировал чат игроку X»), объявления [INFO] и т.п.
    local hasCall = false
    for _, m in ipairs({ "вы тут", "ты тут", "вы бот", "ты бот",
        "вы не бот", "ты не бот", "/report", "2+2", "бот?" }) do
        if lower:find(m, 1, true) then hasCall = true break end
    end
    -- ник админа сразу после слова «Администратор»
    local admin = text:match("[Аа]дминистратор[%s:%-—]*([А-Яа-яA-Za-z0-9_]+)")
            or text:match("[Aa]dministrator[%s:%-—]*([А-Яа-яA-Za-z0-9_]+)")
    -- адресат «для <ник>» (регистр буквы «д» — любой); чужой адресат -> nil
    local addr = text:match("[Дд]ля%s*[:%-—]?%s*([А-Яа-яA-Za-z0-9_]+)")
    local meMention = false
    if myNick and #myNick > 0 then meMention = wordFind(lower, casefoldCyr(myNick:lower())) end
    if addr and myNick and #myNick > 0 then
        if casefoldCyr(addr:lower()) ~= casefoldCyr(myNick:lower()) then
            return nil -- обращение к другому игроку
        end
    end
    -- даже при наличии маркера вызова убеждаемся, что текст адресован именно
    -- нашему персонажу: упоминание нашего ника, «для <мой ник>», явный признак
    -- администратора или личное обращение от известного админа.
    if hasCall then
        if addr or meMention then
            return admin or true
        end
        local oocName = M.extract_ooc_name(text)
        -- личное обращение от известного админа засчитываем только когда
        -- в тексте упомянут НАШ ник (иначе это чужой диалог/наказание).
        if meMention and oocName and M.has_known_admin(oocName) then
            return admin or true
        end
        return nil -- маркер был, но адресовано не нам / нет нашего ника
    end
    return nil
end

function M.is_admin_message(text, myNick)
    if not text or #text == 0 then return false end
    -- v1.1.5: раньше ловился ЛЮБОЙ текст, где упомянут ник известного админа
    -- (наказание «игроку X», анонсы [INFO] и т.п.). Теперь админ-сообщение —
    -- это только личное обращение от известного админа: OOC-форма
    -- (( Ник_админа: ... )) / [Ник_админа: ...] / {Ник_админа: ...},
    -- либо формат «ник_админа ответил Вам: ...».
    -- v1.2.0: OOC от админа засчитываем, только если в тексте упомянут
    -- НАШ ник (иначе это чужой диалог админа с другим игроком).
    local lower = casefoldCyr(text:lower())
    local meMention = (myNick and #myNick > 0)
        and wordFind(lower, casefoldCyr(myNick:lower()))
    local name = M.extract_ooc_name(text)
    if name then
        local known = M.has_known_admin(name)
        if known and meMention then return known end
    end
    local nm = text:match("^(%S+)%s+ответил%s+Вам%s*:")
    if nm then
        local known = M.has_known_admin(nm)
        -- «ответил Вам» — это всегда обращение к НАМ, ник не обязателен.
        if known then return known end
    end
    return false
end

-- Сброс кеша списка админов (после добавления/удаления через GUI), чтобы
-- повторный вызов get_admin_names() перечитал файл и ручной список.
function M.invalidate()
    fileCache = nil
    cachedNames = nil
end

return M