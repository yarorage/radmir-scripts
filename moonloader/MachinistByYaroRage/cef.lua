-- Модуль работы с CEF-пакетами (id = 215, 0xD7).
-- Поддерживает отправку OnPlayerClientSideKey (клавиши W=87, S=83 для
-- управления поездом) и разбор состояния интерфейса 'Machinist'.
-- Формат TX подтверждён по дампам:
--   [215][int32 2][0][0][int32 len][имя][int32 2][0x64][int32 vk]
-- Отправка через raknetSendBitStream (как в AutoLoginByYaroRage/restore.lua).
local M = {}

local encoding = require "encoding"
local u8 = encoding.UTF8

-- ---------- Отправка ----------

-- Сборка байтов пакета CEF id=215.
local function build_bytes(name, args)
    local p = {}
    local function push(x) p[#p + 1] = x end
    local function push_int32(v)
        v = v % 4294967296
        push(v % 256)
        push(math.floor(v / 256) % 256)
        push(math.floor(v / 65536) % 256)
        push(math.floor(v / 16777216) % 256)
    end
    push(215)
    push_int32(2)
    push(0); push(0)
    push_int32(#name)
    for i = 1, #name do push(string.byte(name, i)) end
    if args then
        for _, b in ipairs(args) do push(b) end
    end
    return p
end

-- Отправка готового байтового массива как CEF-пакета.
local function send_bytes(bytes)
    if not bytes or #bytes == 0 then return false end
    local ok_bs, bs = pcall(raknetNewBitStream)
    if not ok_bs or not bs then return false end
    local ok_w = pcall(function()
        for i = 1, #bytes do
            raknetBitStreamWriteInt8(bs, bytes[i])
        end
    end)
    if not ok_w then
        raknetDeleteBitStream(bs)
        return false
    end
    local ok_s = pcall(raknetSendBitStream, bs)
    raknetDeleteBitStream(bs)
    return ok_s == true
end

-- Имитация нажатия клавиши через CEF (OnPlayerClientSideKey).
-- Клавиши: 87 = W (газ), 83 = S (тормоз), 69 = E, 16 = ничего.
local function build_key_packet(vk)
    local name = "OnPlayerClientSideKey"
    local args = {
        2, 0, 0, 0,          -- заголовок аргументов
        0x64, vk % 256, math.floor(vk / 256) % 256, math.floor(vk / 65536) % 256, math.floor(vk / 16777216) % 256,
    }
    return build_bytes(name, args)
end

function M.send_key(vk)
    return send_bytes(build_key_packet(vk))
end

function M.send_key_w()
    return M.send_key(87) -- W = газ
end

function M.send_key_s()
    return M.send_key(83) -- S = тормоз
end

-- ---------- Разбор входящих данных ----------

-- Аргумент команды вида setXxx('[...]') или setXxx([ ... ]).
local function cmdArg(text, cmd)
    local s, e = text:find(cmd, 1, true)
    if not s then return nil end
    local open = text:find("(", s, true)
    if not open then return nil end
    local depth = 0
    local last = nil
    for i = open, #text do
        local c = text:sub(i, i)
        if c == "(" then depth = depth + 1
        elseif c == ")" then
            depth = depth - 1
            if depth == 0 then last = i break end
        end
    end
    if not last then return nil end
    return text:sub(open + 1, last - 1)
end

-- Все значения int из подстроки (для семафоров).
local function parseInts(str)
    local out = {}
    for n in str:gmatch("%d+") do
        out[#out + 1] = tonumber(n)
    end
    return out
end

-- Извлечение данных машиниста из входящего текста CEF (RX id=215).
-- Возвращает таблицу полей или nil, если текст не относится к машинисту.
-- Источник: дампы интерфейса 'Machinist' от 14.09.2026:
--   interface('Machinist').setSemaphoreState('[1,1,1,1]')
--   interface('Machinist').setStation('["Больничная", 697, 1]')
--   interface('Machinist').setSpeed('["39-45", 2]')
--   interface('Machinist').setMoney(121875)
function M.parse_state_text(txt)
    if not txt or #txt == 0 then return nil end
    local fields = {}

    -- Комбинированный пакет: интерфейс 'Machinist8' шлёт всё состояние одним
    -- вызовом без отдельных функций:
    --   Machinist8[[1,1,1,1],["54-63",0],["Союзная",759,0],8125]
    -- Формат подтверждён по дампу 14.09.2026 (единственное вхождение, но
    -- сервер может переключиться на него в любой момент).
    local sem, lo, hi, code, name, dist, stcode, money =
        txt:match('Machinist8%[%[([%d%s,]+)%]%s*,%s*%["?(%d+)-(%d+)"?%s*,%s*(%-?%d+)%]%s*,%s*%["([^"]+)"%s*,%s*(%-?%d+)%s*,%s*(%-?%d+)%]%s*,%s*(%-?%d+)%]')
    if sem and lo and hi then
        fields.semaphores = parseInts(sem)
        fields.speed_range = lo .. "-" .. hi
        fields.speed_lo = tonumber(lo)
        fields.speed_hi = tonumber(hi)
        fields.speed_code = tonumber(code) or 1
        fields.station_name = name
        fields.station_dist = tonumber(dist)
        fields.station_code = tonumber(stcode) or 0
        fields.money = tonumber(money)
        return fields
    end

    -- семафоры
    local semArg = cmdArg(txt, "setSemaphoreState")
    if semArg then
        local nums = parseInts(semArg)
        if #nums == 4 then
            fields.semaphores = nums
        end
    end

    -- скорость и её код (вилка "мин-макс" км/ч, код: 0=газ, 1=ок, 2=тормоз).
    -- В дампах диапазон всегда в кавычках: setSpeed('["39-45", 2]') — раньше
    -- regex их не учитывал и скорость вообще не разбиралась (бот ехал вслепую).
    local speedArg = cmdArg(txt, "setSpeed")
    if speedArg then
        local lo, hi, code = speedArg:match('%["(%d+)-(%d+)"%s*,%s*(%-?%d+)')
        if not lo then lo, hi, code = speedArg:match("%[(%d+)-(%d+)%s*,%s*(%-?%d+)") end
        if not hi then lo, hi = speedArg:match('%["(%d+)-(%d+)') end
        if lo and hi then
            fields.speed_range = lo .. "-" .. hi
            fields.speed_lo = tonumber(lo)
            fields.speed_hi = tonumber(hi)
            fields.speed_code = tonumber(code) or 1
        end
    end

    -- станция
    local stationArg = cmdArg(txt, "setStation")
    if stationArg then
        local name, dist, code = stationArg:match('%["([^"]+)"%s*,%s*(%-?%d+)%s*,%s*(%-?%d+)')
        if not dist then name, dist, code = stationArg:match('%["([^"]+)"%s*,%s*(%-?%d+)') end
        if name then
            fields.station_name = name
            fields.station_dist = tonumber(dist)
            fields.station_code = tonumber(code) or 0
        end
    end

    -- деньги (setMoney(8125))
    local moneyArg = cmdArg(txt, "setMoney")
    if moneyArg then
        local n = moneyArg:match("(%d+)")
        if n then fields.money = tonumber(n) end
    end

    -- таймер-подсказка: InformationTimer ["Остановитесь на станции",25,0]
    -- v0.7.6: таймер штрафа за превышение («Увеличьте скорость до штрафа», N
    -- секунд) шлёт и число — сохраняем его в info_timer_sec для режима
    -- «Превышать скорость».
    -- v0.9.6: РЕАЛЬНЫЙ формат пакета — «InformationTimer ["...",N,0]»: между
    -- именем и скобкой стоит ПРОБЕЛ, а строки пакета склеены переводом строки
    -- (\n). Старый паттерн требовал кавычку сразу после «InformationTimer», не
    -- находил таймер вообще (f.info_timer ВСЕГДА nil) — поэтому ни штраф за
    -- превышение, ни команда остановки на станции не работали.
    local info, info_sec = txt:match('InformationTimer%s*%[%s*"([^"]+)"%s*,%s*(%-?%d+)')
    if not info then info = txt:match('InformationTimer%s*%[%s*"([^"]+)"') end
    if info then
        fields.info_timer = info
        if info_sec then fields.info_timer_sec = tonumber(info_sec) end
    end

    local found = fields.semaphores or fields.speed_range or fields.station_name or
                  fields.money or fields.info_timer
    if not found then return nil end
    return fields
end

-- Парсинг голосового чата (HUD). На Radmir голосовые каналы показываются
-- так:
--   interface('Hud').addVoiceChatEntry([0,"Artemon_Pahomov",518,0,"",565])
--   interface('Hud').removeVoiceChatEntry([[518,565]])
-- add возвращает { id, nick } (кто ЗАШЁЛ в голосовой канал/начал говорить),
-- remove — только массив id (вышел). Ник из add используем и как запасной
-- источник «id игрока -> ник» для пузырей чата (sampGetPlayerNameById на
-- Radmir может не заполняться).
local VOICE_ADD = "addVoiceChatEntry"
local VOICE_REMOVE = "removeVoiceChatEntry"

function M.parse_voice_chat(txt)
    if not txt or #txt == 0 then return nil end
    -- addVoiceChatEntry([TYPE,"Ник",ID,статус,"",канал])
    local a = txt:find(VOICE_ADD, 1, true)
    if a then
        local rest = txt:sub(a + #VOICE_ADD)
        local typ, nick, id = rest:match("%s*%(%s*%[%s*([%d%-]+)%s*,%s*['\"]([^'\"]+)['\"]%s*,%s*(%d+)")
        if id then
            return { action = "add", id = tonumber(id), nick = nick, type = typ }
        end
        return { action = "add", id = nil, nick = nick }
    end
    -- removeVoiceChatEntry([[id,канал],...])
    local r = txt:find(VOICE_REMOVE, 1, true)
    if r then
        local ids = {}
        for m in txt:gmatch("%[%s*(%d+)%s*,%s*(%d+)%s*%]") do
            ids[#ids + 1] = tonumber(m)
        end
        if #ids > 0 then return { action = "remove", ids = ids } end
    end
    return nil
end

-- Парсинг всплывающего сообщения чата (пузыря):
--   window.setPlayerChatBubble(132, 'текст', 13434879, 7.50, 8000)
--   window.setPlayerChatBubble(114, 'текст', -1, 5.00, 524000)  -- цвет может быть ОТРИЦАТЕЛЬНЫМ!
-- Чат на Radmir идёт ТОЛЬКО такими CEF-командами (onServerMessage не
-- вызывается — подтверждено диагностикой v0.4.0).
-- Возвращает { id, text, color, dist, time } или nil.
function M.parse_chat_bubble(txt)
    if not txt or #txt == 0 then return nil end
    local id, text, color, dist, time = txt:match(
        "setPlayerChatBubble%s*%(%s*(%d+)%s*,%s*['\"](.-)['\"]%s*,%s*(%-?%d+)%s*,%s*([%d%.%-]+)%s*,%s*(%d+)%s*%)")
    if not id then return nil end
    return {
        id = tonumber(id),
        text = text,
        color = tonumber(color),
        dist = tonumber(dist),
        time = tonumber(time),
    }
end

-- Парсинг команд «перед игроком открылось окно/диалог». На Radmir окна
-- приходят такими CEF-командами:
--   window.addDialogInQueue('[216,"Заголовок",0,"ОК","Отмена","текст"]', ...)
--   PlayerInteraction... / interface('PlayerInteraction').onServerResponse(...)
--   Quests / QuestsTalks
-- Возвращает таблицу { sig, short, long } или nil:
--   sig   — подпись для дедупликации (тип + id + заголовок);
--   short — короткая строка для игрового чата;
--   long  — подробное многострочное описание для Telegram.
local WINDOW_CMDS = {
    { name = "addDialogInQueue", label = "диалог" },
    { name = "PlayerInteraction", label = "окно взаимодействия" },
    { name = "QuestsTalks", label = "окно разговора" },
    { name = "Quests", label = "окно квестов" },
}

-- Поиск имени команды как отдельного слова (чтобы «Quests» не находилось
-- внутри «QuestsTalks»). Возвращает позицию или nil.
local function find_word(txt, name, pos)
    while true do
        local hit = txt:find(name, pos, true)
        if not hit then return nil end
        local prev = hit > 1 and txt:sub(hit - 1, hit - 1) or ""
        local nxt  = txt:sub(hit + #name, hit + #name)
        if not prev:match("[%w_]") and not nxt:match("[%w_]") then
            return hit
        end
        pos = hit + 1
    end
end

-- Достаёт содержимое первой строки в кавычках (одинарных или двойных).
-- Возвращает (содержимое, остаток_строки) или nil, если закрывающей
-- кавычки нет. Экранированные кавычки не считаются закрывающими.
local function take_quoted(s)
    if not s or #s == 0 then return nil end
    local i = s:find("['\"]")
    if not i then return nil end
    local q = s:sub(i, i)
    local buf, esc = {}, false
    for j = i + 1, #s do
        local ch = s:sub(j, j)
        if esc then
            buf[#buf + 1] = ch
            esc = false
        elseif ch == "\\" then
            buf[#buf + 1] = ch
            esc = true
        elseif ch == q then
            return table.concat(buf), s:sub(j + 1)
        else
            buf[#buf + 1] = ch
        end
    end
    return nil
end

-- Разбирает полезную нагрузку диалога (JSON-массив внутри строки):
--   '[216,"Заголовок",0,"ОК","Отмена","текст"]'
-- Запятые внутри строк не считаются разделителями, \n и \" разэкранируются.
-- Возвращает массив полей (числа — как числа, строки — как строки).
local function split_fields(s)
    local fields, cur, inStr, esc = {}, {}, false, false
    for i = 1, #s do
        local ch = s:sub(i, i)
        if esc then
            if ch == "n" then cur[#cur + 1] = "\n"
            elseif ch == "t" then cur[#cur + 1] = "\t"
            else cur[#cur + 1] = ch end
            esc = false
        elseif ch == "\\" and inStr then
            esc = true
        elseif ch == "\"" then
            inStr = not inStr
        elseif ch == "," and not inStr then
            fields[#fields + 1] = table.concat(cur)
            cur = {}
        else
            cur[#cur + 1] = ch
        end
    end
    fields[#fields + 1] = table.concat(cur)
    for i, f in ipairs(fields) do
        local nf = tonumber(f)
        if nf then fields[i] = nf end
    end
    return fields
end

-- Склеивает кнопки из двух полей (пропускает «0» и пустые).
local function join_buttons(b1, b2)
    local btns = {}
    if type(b1) == "string" and #b1 > 0 and b1 ~= "0" then btns[#btns + 1] = b1 end
    if type(b2) == "string" and #b2 > 0 and b2 ~= "0" then btns[#btns + 1] = b2 end
    if #btns == 0 then return nil end
    return table.concat(btns, " / ")
end

-- Диалог addDialogInQueue: [id, заголовок, стиль, кнопка1, кнопка2, текст...].
local function describe_dialog(c, after)
    local payload = take_quoted(after)
    if not payload or #payload == 0 then return nil end
    payload = payload:gsub("^%s*[%[%(]", ""):gsub("[%]%)]%s*$", "")
    local f = split_fields(payload)
    local id    = f[1]
    local title = type(f[2]) == "string" and f[2] or ""
    local text  = ""
    for k = 6, #f do
        text = text .. tostring(f[k])
    end
    local lines = { c.label .. ": \"" .. title .. "\"" }
    local btns = join_buttons(f[4], f[5])
    if btns then lines[#lines + 1] = "Кнопки: " .. btns end
    if #text > 0 then lines[#lines + 1] = "Текст: " .. text end
    return {
        sig   = c.label .. "|" .. tostring(id) .. "|" .. title,
        short = c.label .. ": '" .. title .. "'",
        long  = table.concat(lines, "\n"),
    }
end

-- Прочие окна (PlayerInteraction/QuestsTalks/Quests): собираем до трёх
-- читаемых надписей, которые идут после команды в кавычках.
local function describe_generic(c, after)
    if #after > 0 and (after:sub(1, 1) == "'" or after:sub(1, 1) == "\"") then
        after = after:sub(2)
    end
    local parts = {}
    local rest  = after
    for _ = 1, 3 do
        local piece, tail = take_quoted(rest)
        if not piece then break end
        piece = piece:gsub("\"", "'"):gsub("^%s+", ""):gsub("%s+$", "")
        if #piece > 0 and #piece <= 300 then parts[#parts + 1] = piece end
        rest = tail or ""
    end
    if #parts == 0 then return nil end
    return {
        sig   = c.label .. "|" .. table.concat(parts, "|"),
        short = c.label .. ": '" .. parts[1] .. "'",
        long  = c.label .. "\n" .. table.concat(parts, "\n"),
    }
end

function M.parse_window_open(txt)
    if not txt or #txt == 0 then return nil end
    local found = nil
    for _, c in ipairs(WINDOW_CMDS) do
        local pos = 1
        while true do
            local hit = find_word(txt, c.name, pos)
            if not hit then break end
            local after = txt:sub(hit + #c.name)
            local desc
            if c.name == "addDialogInQueue" then
                desc = describe_dialog(c, after)
            else
                desc = describe_generic(c, after)
            end
            if desc then
                if found then
                    found.sig   = found.sig .. " | " .. desc.sig
                    found.short = found.short .. " + " .. desc.short
                    found.long  = found.long .. "\n\n" .. desc.long
                else
                    found = desc
                end
            end
            pos = hit + #c.name
        end
    end
    return found
end

-- ---------- Автовыбор «Жалоба на игрока» (окно /report) ----------
-- После команды /report клиент открывает CEF-диалог выбора типа запроса
-- (addDialogInQueue «Выберите тип запроса»). Если игрок отошёл, нужно
-- автоматически выбрать пункт «Жалоба на игрока», чтобы жалоба дошла до
-- администратора. Формат TX-ответа подтверждён реальными пакетами
-- Sonya_Tekilla (15.09.2026, разбор hex): всем пунктам списка клиент шлёт
--   [0x64][int32 0][0x64][int32 1][0x64][int32 индекс][0x73][int32 len][байты строки]
-- а строка выглядит как  <p style="color: #">1. Жалоба на игрока</p>  (CP1251,
-- номер пункта «1.» подставляет сам клиент).

-- Сборка TX-ответа OnDialogResponse: index — номер пункта (с 0),
-- text_html — строка пункта (как её отправляет клиент, CP1251).
local function build_dialog_response(index, text_html)
    local len = #text_html
    local args = {
        8, 0, 0, 0,   -- префикс: 2 * число параметров (4 параметра)
        0x64, 0, 0, 0, 0,   -- параметр 1 = 0
        0x64, 1, 0, 0, 0,   -- параметр 2 = 1 (кнопка «Отправить»)
        0x64, index % 256, math.floor(index / 256) % 256,
              math.floor(index / 65536) % 256, math.floor(index / 16777216) % 256,
        0x73, len % 256, math.floor(len / 256) % 256,
              math.floor(len / 65536) % 256, math.floor(len / 16777216) % 256,
    }
    for i = 1, len do
        args[#args + 1] = string.byte(text_html, i)
    end
    return build_bytes("OnDialogResponse", args)
end

-- Отправка ответа диалогу OnDialogResponse.
function M.send_dialog_response(index, text_html)
    if not text_html or #text_html == 0 then return false end
    return send_bytes(build_dialog_response(index, text_html))
end

-- Определение окна выбора типа запроса (/report) с пунктом «Жалоба на игрока».
-- Возвращает { index, text } для send_dialog_response либо nil.
local REPORT_ITEM = "Жалоба на игрока"
local REPORT_TITLE = "Выберите тип запроса"

function M.parse_report_dialog(txt)
    if not txt or #txt == 0 then return nil end
    if not txt:find("addDialogInQueue", 1, true) then return nil end
    -- пункт и заголовок условия надёжнее искать по подстрокам: заголовок
    -- может идти с цветовым кодом {FFCD00} перед текстом.
    if not txt:find(REPORT_ITEM, 1, true) then return nil end
    if not txt:find(REPORT_TITLE, 1, true) then return nil end
    -- «Жалоба на игрока» — первый пункт (индекс 0). Номер «1.» в начале
    -- строки подставляет сам клиент, как в реальном TX-пакете.
    return { index = 0, text = '<p style="color: #">1. ' .. REPORT_ITEM .. '</p>' }
end

return M
