-- Захват и разбор пакетов CefPacketAnalyzer
-- Слушает события lib.samp.events: onReceivePacket / onSendPacket / onServerMessage /
-- onGameText / onConnectionClosed / onConnectionLost. Читает байты RakNet-потока,
-- определяет текстовость, снимает контекст (позиция, курсор) и обновляет фазу игры.
local state = require("CefPacketAnalyzer.state")
local classify = require("CefPacketAnalyzer.classify")
local encUtils = require("CefPacketAnalyzer.enc_utils")

-- Маркеры фаз (литералы движка в CP1251) переводятся в UTF-8,
-- потому что record.text мы храним в UTF-8.
local MARK_LOADING = encUtils.bytesCpToUtf8("загрузк")
local MARK_SPAWN   = encUtils.bytesCpToUtf8("спавн")
local MARK_INGAME  = encUtils.bytesCpToUtf8("вошли в игру")

-- Таблица CP1251 0x80..0xBF -> кодовая точка Unicode (кавычки, тире, ё и пр.)
local CP_HI = {
    [0x80]=0x0402,[0x81]=0x0403,[0x82]=0x201A,[0x83]=0x0453,[0x84]=0x201E,
    [0x85]=0x2026,[0x86]=0x2020,[0x87]=0x2021,[0x88]=0x20AC,[0x89]=0x2030,
    [0x8A]=0x0409,[0x8B]=0x2039,[0x8C]=0x040A,[0x8D]=0x040C,[0x8E]=0x040B,
    [0x8F]=0x040F,[0x90]=0x0452,[0x91]=0x2018,[0x92]=0x2019,[0x93]=0x201C,
    [0x94]=0x201D,[0x95]=0x2022,[0x96]=0x2013,[0x97]=0x2014,[0x98]=0x0098,
    [0x99]=0x2122,[0x9A]=0x0459,[0x9B]=0x203A,[0x9C]=0x045A,[0x9D]=0x045C,
    [0x9E]=0x045B,[0x9F]=0x045F,[0xA0]=0x00A0,[0xA1]=0x040E,[0xA2]=0x045E,
    [0xA3]=0x0408,[0xA4]=0x00A4,[0xA5]=0x0490,[0xA6]=0x00A6,[0xA7]=0x00A7,
    [0xA8]=0x0401,[0xA9]=0x00A9,[0xAA]=0x0404,[0xAB]=0x00AB,[0xAC]=0x00AC,
    [0xAD]=0x00AD,[0xAE]=0x00AE,[0xAF]=0x0407,[0xB0]=0x00B0,[0xB1]=0x00B1,
    [0xB2]=0x0406,[0xB3]=0x0456,[0xB4]=0x0491,[0xB5]=0x00B5,[0xB6]=0x00B6,
    [0xB7]=0x00B7,[0xB8]=0x0451,[0xB9]=0x2116,[0xBA]=0x0454,[0xBB]=0x00BB,
    [0xBC]=0x0458,[0xBD]=0x0405,[0xBE]=0x0455,[0xBF]=0x0457,
}

-- Кодирование кодовой точки Unicode в UTF-8 (1-3 байта)
local function utf8Char(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(
            0xC0 + math.floor(cp / 0x40),
            0x80 + (cp % 0x40)
        )
    else
        return string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    end
end

-- Преобразование байта CP1251 в символ UTF-8 (кириллица и спецсимволы)
local function cpToUtf8(b)
    if b < 0x80 then
        return string.char(b)
    elseif b <= 0xBF then
        local cp = CP_HI[b]
        if cp then
            return utf8Char(cp)
        end
        return string.format("\\x%02X", b)
    else
        -- 0xC0..0xFF: кириллица CP1251 (А..Я, а..я)
        local code = b - 0xC0
        return utf8Char(0x410 + code)
    end
end

-- Приемлемые диапазоны Unicode для решения, что пара байтов — это UTF-8,
-- а не две буквы CP1251 (кириллица, типы типографики, деньги и латиница).
local function looksLikeUtf8(cp)
    if cp >= 0xA0 and cp <= 0x2AF then
        return true
    end
    if cp >= 0x370 and cp <= 0x4FF then
        return true
    end
    if cp >= 0x2000 and cp <= 0x20BF then
        return true
    end
    return false
end

-- Умный декодер тела: пакеты Radmir несут часть строк уже в UTF-8, часть в CP1251
-- (движок). Читаем байты по одному, распознавая оба варианта.
local function decodeBody(rawStr)
    local parts = {}
    local i, n = 1, #rawStr
    while i <= n do
        local b = rawStr:byte(i)
        local b2 = rawStr:byte(i + 1)
        if b >= 0xC2 and b <= 0xDF and b2 and b2 >= 0x80 and b2 <= 0xBF then
            -- возможный двухбайтовый UTF-8
            local cp = (b - 0xC0) * 0x40 + (b2 - 0x80)
            if looksLikeUtf8(cp) then
                parts[#parts + 1] = utf8Char(cp)
                i = i + 2
            else
                parts[#parts + 1] = cpToUtf8(b)
                i = i + 1
            end
        elseif b >= 0xE0 and b <= 0xEF then
            local b3 = rawStr:byte(i + 2)
            if b2 and b2 >= 0x80 and b2 <= 0xBF and b3 and b3 >= 0x80 and b3 <= 0xBF then
                local cp = (b - 0xE0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)
                if cp >= 0x800 and cp <= 0xFFFD and not (cp >= 0xD800 and cp <= 0xDFFF) then
                    parts[#parts + 1] = utf8Char(cp)
                    i = i + 3
                else
                    parts[#parts + 1] = cpToUtf8(b)
                    i = i + 1
                end
            else
                parts[#parts + 1] = cpToUtf8(b)
                i = i + 1
            end
        else
            parts[#parts + 1] = cpToUtf8(b)
            i = i + 1
        end
    end
    return table.concat(parts)
end

-- Обрезка строки до n байт без разрыва UTF-8-символа на границе:
-- обрезанная строка не должна оканчиваться серединой многобайтного символа,
-- иначе в JSON/HTML отчёты попадут битые байты.
local function subUtf8(s, n)
    if #s <= n then
        return s
    end
    local cut = s:sub(1, n)
    local b = s:byte(n)
    if b and b >= 0x80 then
        -- последний байт обрезки - часть многобайтного символа: откатываемся до начала
        local i = n
        while i > 1 do
            local c = s:byte(i)
            if c and c >= 0xC0 then
                return s:sub(1, i - 1)
            elseif c and c < 0x80 then
                break
            end
            i = i - 1
        end
        return cut
    end
    return cut
end

-- Перевод произвольной строки (UTF-8 на входе движка) в строку без ломаных байт
local function sanitizeUtf8(s)
    if not s then return "" end
    -- заменяем управляющие символы (байт 0 выносим отдельно: \0 ломает класс паттерна Lua)
    s = s:gsub("%z", " ")
    s = s:gsub("[\1\2\3\4\5\6\7\8\9\11\12\13\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]", " ")
    -- удаляем некорректные продолжения (например, 0x80..0xBF после ASCII) - оставляем как есть
    return s
end

-- Читаем тело пакета из bitstream и возвращаем строку байт + длину.
-- Чтение ограничено сверху READ_CAP байт: загружаемые страницы и крупные
-- CEF-тела не должны стоить в сетевом хуке больше одного-двух тактов.
-- Текст и HEX и так ограничены state.maxBodyLen (4096), поэтому потери нет.
local READ_CAP = 4096
local function readPacketBody(bs)
    local n = raknetBitStreamGetNumberOfBytesUsed(bs)
    if not n or n < 0 then
        return "", 0, 0
    end
    local readN = n
    if readN > READ_CAP then
        readN = READ_CAP
    end
    -- Читаем тело одним pcall (не на каждый байт): ошибки чтения битстрима
    -- ловятся здесь, а указатель сбрасываем ниже. Это заметно дешевле.
    local rawBuf = {}
    local ok = pcall(function()
        for i = 1, readN do
            local b = raknetBitStreamReadInt8(bs)
            if type(b) ~= "number" then
                rawBuf[i] = string.char(0)
            else
                rawBuf[i] = string.char(b % 256)
            end
        end
    end)
    -- сбрасываем указатель чтения
    pcall(raknetBitStreamResetReadPointer, bs)
    if not ok then
        return "", 0, 0
    end
    return table.concat(rawBuf), n, n
end

-- Определяем, является ли тело пакета "текстовым" (длинные печатные последовательности)
local function isTextBody(rawStr, minRun)
    local run = 0
    for i = 1, #rawStr do
        local b = rawStr:byte(i)
        if b >= 0x20 and b ~= 0x7F then
            run = run + 1
            if run >= minRun then
                return true
            end
        else
            run = 0
        end
    end
    return false
end

-- Декодируем байты в UTF-8-строку для отчёта (смесь UTF-8 и CP1251)
local decodeBytesForReport = decodeBody

-- Получить координаты игрока безопасно
local function getPlayerPos()
    local px, py, pz = 0, 0, 0
    local ok = pcall(function()
        if getCharCoordinates and PLAYER_PED then
            px, py, pz = getCharCoordinates(PLAYER_PED)
        end
    end)
    if not ok then
        return 0, 0, 0
    end
    return px or 0, py or 0, pz or 0
end

-- Получить положение курсора безопасно
local function getCursorState()
    local on = false
    local x, y = 0, 0
    local ok = pcall(function()
        if isCursorActive then
            on = isCursorActive()
        end
        if on and getCursorPos then
            x, y = getCursorPos()
        end
    end)
    return on, x or 0, y or 0
end

-- Снимок контекста для записи.
-- Кэшируется ~50 миллисекунд: getCharCoordinates/isCursorActive/getCursorPos -
-- это вызовы SAMPFUNCS, их нельзя дёргать на каждый пакет (служебные sync-пакеты
-- идут десятками в секунду), а на пустом пуле они потенциально опасны.
local lastCtxClock = 0
local ctxCache = nil
local function snapshotContext()
    local now = os.clock()
    if ctxCache and (now - lastCtxClock) < 0.05 then
        return ctxCache
    end
    lastCtxClock = now
    local px, py, pz = getPlayerPos()
    local cur, cx, cy = getCursorState()
    ctxCache = {
        px = px,
        py = py,
        pz = pz,
        cursorOn = cur,
        cursorX = cx,
        cursorY = cy,
    }
    return ctxCache
end

-- Обновление фазы игры по пакету (дополнительно к базе знаний)
local function updatePhase(record)
    local lowBody = tostring(record.text or ""):lower()
    local phase = state.state.phase

    if lowBody:find("authorization", 1, true) or lowBody:find("auth", 1, true) then
        phase = "login"
    elseif lowBody:find("selectspawn", 1, true) or lowBody:find(MARK_SPAWN, 1, true) then
        phase = "spawn_select"
    elseif lowBody:find("loading", 1, true) or lowBody:find(MARK_LOADING, 1, true) then
        phase = "loading"
    elseif lowBody:find("setplayernickname", 1, true) or lowBody:find(MARK_INGAME, 1, true) then
        phase = "in_world"
    elseif lowBody:find("onplayeropenmenupause", 1, true) then
        phase = "in_world"
    end

    if phase ~= state.state.phase then
        state.state.phase = phase
    end
end

-- Пользовательская заглушка: вызывается в главном цикле для каждой записи.
local emitCallback = nil

-- Очередь захваченных пакетов на обработку в главном цикле.
-- Пакеты попадают в хук СЕТЕВОГО ПОТОКА (onReceivePacket/onSendPacket),
-- а тяжёлая обработка (decodeBody, классификация по базе знаний, hex, JSON,
-- запись на диск) выполняется ТОЛЬКО в главном цикле с жёстким бюджетом
-- времени за кадр. Это исключает фризы в игровом потоке: хук лишь копит
-- дешёвые мини-записи, а главный цикл не даёт обработать больше, чем
-- укладывается в ~1-1.5 мс за кадр.
local pendingQueue = {}
local pendingHead = 1
local pendingTail = 1
local pendingCount = 0
local PENDING_CAP = 2000

-- Кэш текущей даты/времени. os.date вызывается на каждый содержательный
-- пакет в сетевом хуке - это системный вызов, который при потоковом спаме
-- пакетов нагружает игровой поток. Строка времени обновляется раз в секунду.
local cachedTimeVal = 0
local cachedDateStr = ""
local function cachedDateTime()
    local t = os.time()
    if t ~= cachedTimeVal then
        cachedTimeVal = t
        cachedDateStr = os.date("%Y-%m-%d %H:%M:%S")
    end
    return t, cachedDateStr
end

-- Содержательные пакеты (id 215/61/62/200, серверные сообщения/тексты/диалоги
-- или пакеты с текстовым телом) кладутся в очередь с минимумом полей.
-- Здесь же вычисляется isText - дешёвый линейный проход по телу (без разбора).
local function enqueuePending(seq, dir, id, bodyLen, totalBytes, rawStr, timeVal, dateStrVal, isTextVal)
    -- Защита от переполнения очереди при всплеске: если очередь растёт быстрее,
    -- чем её успевает разбирать главный цикл (потоковый спам при больших окнах),
    -- вытесняем самые старые записи. Счётчики при этом уже учтены.
    if pendingCount >= PENDING_CAP then
        -- вытесняем самый старый элемент
        pendingQueue[pendingHead] = nil
        pendingHead = pendingHead + 1
        pendingCount = pendingCount - 1
    end
    pendingQueue[pendingTail] = {
        seq = seq,
        dir = dir,
        id = id,
        bodyLen = bodyLen,
        size = totalBytes or bodyLen,
        time = timeVal,
        dateStr = dateStrVal,
        text = rawStr,
        isText = isTextVal,
    }
    pendingTail = pendingTail + 1
    pendingCount = pendingCount + 1
end

-- Обработка очереди в главном цикле: разбираем не больше maxCount записей
-- и не дольше budgetSec за один вызов. Возвращает число обработанных.
local function processPending(budgetSec, maxCount)
    local start = os.clock()
    local processed = 0
    while pendingCount > 0 do
        if processed >= maxCount then
            break
        end
        if os.clock() - start >= budgetSec then
            break
        end
        local pend = pendingQueue[pendingHead]
        pendingQueue[pendingHead] = nil
        pendingHead = pendingHead + 1
        pendingCount = pendingCount - 1
        if not pend then
            break
        end

        local st = state.state
        local dir = pend.dir
        local id = pend.id
        local bodyLen = pend.bodyLen
        local rawStr = pend.text or ""

        -- Полный разбор и классификация (уже вне сетевого потока)
        local text = ""
        if bodyLen > 0 then
            text = decodeBody(rawStr)
            text = sanitizeUtf8(text)
        end

        local isText = pend.isText or (#text >= (st.minTextRun or 6))

        -- Ограничиваем тело (по границе UTF-8, чтобы не писать битые байты)
        local bodyForStore = text
        if #bodyForStore > st.maxBodyLen then
            bodyForStore = subUtf8(bodyForStore, st.maxBodyLen)
        end

        local ctx = snapshotContext()

        local record = {
            seq = pend.seq,
            dir = dir,
            id = id,
            bodyLen = bodyLen,
            size = pend.size or bodyLen,
            time = pend.time,
            dateStr = pend.dateStr,
            text = bodyForStore,
            isText = isText,
            ctx = ctx,
            phaseAtCapture = st.phase,
            phaseName = state.phaseName(),
            sig = classify.signature(bodyForStore),
        }
        record.dedupKey = dir .. "|" .. tostring(id) .. "|" .. record.sig

        local cls = classify.classify(record)
        record.category = cls.category
        record.categoryTitle = cls.categoryTitle
        record.categoryDesc = cls.categoryDesc
        record.title = cls.title
        record.events = cls.events
        record.tokens = cls.tokens
        record.params = cls.params
        record.analysis = cls.analysis
        record.description = cls.description
        record.pktName = cls.pktName
        record.pktIdDesc = cls.pktIdDesc
        record.phaseHint = cls.phaseHint
        record.cmd = cls.cmd
        record.uiUrl = cls.url
        record.win = cls.win
        record.dataKeys = cls.dataKeys
        record.nick = cls.nick
        record.fn = cls.fn

        -- HEX строится по реально прочитанным байтам (rawStr усечён до READ_CAP,
        -- а bodyLen - полная длина по битстриму). Для длинных тел достаточно
        -- первых байт: все данные этого анализатора уже усекаются на 4096.
        local rawLen = #rawStr
        if rawLen > 0 then
            local h = {}
            local n = math.min(rawLen, 512)
            for i = 1, n do
                h[i] = string.format("%02X", rawStr:byte(i) or 0)
            end
            record.bodyHex = table.concat(h)
        end
        if record.dir == "TX" and record.id == 215 and rawLen > 0 then
            -- HEX тела TX 215 без ограничения раздувал бы агрегаты
            -- (st.txHexList до 500 записей по 8КБ), а dkjson-кодирование
            -- такого payload каждые ~10 минут в игровом потоке вызывало бы
            -- заметный фриз. Первых 2048 байт достаточно: такие пакеты
            -- почти всегда короткие команды интерфейса.
            local hexLen = math.min(rawLen, 2048)
            local h = {}
            for i = 1, hexLen do
                h[i] = string.format("%02X", rawStr:byte(i) or 0)
            end
            record.bodyHex = table.concat(h)
            local txEntry = {
                ts = record.time,
                dateStr = record.dateStr,
                dir = record.dir,
                id = record.id,
                len = bodyLen,
                hex = record.bodyHex,
                cmd = record.cmd or "",
                url = record.uiUrl or "",
            }
            local txList = st.txHexList or {}
            txList[#txList + 1] = txEntry
            if #txList > 500 then
                table.remove(txList, 1)
            end
            st.txHexList = txList
        end
        if record.nick and record.nick ~= "" then
            st.gameNick = record.nick
        end

        updatePhase(record)

        local cnt = st.counters[record.category] or {
            count = 0,
            first = record.dateStr,
            last = record.dateStr,
            events = {},
        }
        cnt.count = cnt.count + 1
        cnt.last = record.dateStr
        for _, ev in ipairs(record.events) do
            if not cnt.events[ev] then
                cnt.events[ev] = { count = 0 }
            end
            cnt.events[ev].count = cnt.events[ev].count + 1
        end
        st.counters[record.category] = cnt

        if record.uiUrl and record.uiUrl ~= "" then
            st.urlCounts[record.uiUrl] = (st.urlCounts[record.uiUrl] or 0) + 1
        end
        if record.id == 215 then
            local c = record.fn or record.cmd
            if c and c ~= "" then
                c = (c:gsub("^%s+", ""):gsub("%s+$", ""))
                local k = c .. "|" .. (record.uiUrl or "")
                local e = st.cefCmdSeen[k]
                if not e then
                    e = { cmd = c, url = record.uiUrl or "", n = 0 }
                    st.cefCmdSeen[k] = e
                    if #st.cefCmdList < 100 then
                        table.insert(st.cefCmdList, e)
                    end
                end
                e.n = e.n + 1
            end
        end
        local uniqueKey = record.dedupKey or (dir .. "|" .. tostring(id) .. "|" .. (record.sig or ""))
        local te = st.typeSeen[uniqueKey]
        if not te then
            -- Список типов ограничен сверху (600). Когда он заполнен, новые
            -- ключи в typeSeen не заводим, чтобы таблица-счётчик не росла
            -- бесконечно за долгую сессию.
            if #st.typeList < 600 then
                te = { idx = #st.typeList + 1, n = 1 }
                st.typeSeen[uniqueKey] = te
                table.insert(st.typeList, {
                    dir = dir,
                    id = id,
                    category = record.category,
                    cmd = record.cmd or "",
                    url = record.uiUrl or "",
                    count = 1,
                })
            end
        else
            te.n = te.n + 1
            if te.idx <= #st.typeList then
                st.typeList[te.idx].count = te.n
            end
        end

        if #st.records < st.maxRecords then
            table.insert(st.records, record)
        end

        if emitCallback then
            emitCallback(record)
        end

        processed = processed + 1
    end

    -- Компактизация головы очереди, чтобы не копить огромный хвост из nil
    if pendingHead > 512 and pendingCount > 0 then
        local rest = {}
        for i = 1, pendingCount do
            rest[i] = pendingQueue[pendingHead + i - 1]
        end
        pendingQueue = rest
        pendingHead = 1
        pendingTail = pendingCount + 1
    end

    return processed
end

-- Основной обработчик захваченного пакета
-- dir: "RX"/"TX"; id: номер пакета; bs: bitstream; extra: строка-дополнение (для серверных сообщений)
local function onCapture(dir, id, bs, extra)
    local st = state.state

    if not st.enabled then
        return
    end

    -- Хук минимизирован по стоимости. Сначала узнаём длину тела (property,
    -- микросекунды), решаем, принадлежит ли пакет содержательным, и ТОЛЬКО
    -- тогда читаем байты. Служебный поток (sync и пр.) не читается вообще:
    -- для него лишь счётчики. Вес самого хука — десятки микросекунд на пакет.
    local rawStr
    local bodyLen = 0
    local totalBytes = 0

    -- Дорогая текстовая инспекция применима только к небольшим телам;
    -- многокилометровые бинарные тела (быстрый путь) её не проходят.
    local minRun = st.minTextRun or 6
    local isContentId = (id == 215 or id == 61 or id == 62 or id == 200 or not bs)

    if bs then
        local n = raknetBitStreamGetNumberOfBytesUsed(bs)
        bodyLen = (type(n) == "number" and n >= 0) and n or 0
        totalBytes = bodyLen
        -- Содержательные пакеты читаем целиком; для остальных (при маленьком
        -- теле) читаем только для проверки на текстовость. Большие бинарные
        -- тела молча пропускаем по длине — разбор в очередь не идёт.
        if isContentId or (bodyLen > 0 and bodyLen <= 4096) then
            rawStr, bodyLen, totalBytes = readPacketBody(bs)
        end
    else
        rawStr = extra or ""
        bodyLen = #rawStr
        totalBytes = bodyLen
    end

    local isText = false
    if bodyLen > 0 and bodyLen <= 4096 then
        isText = isTextBody(rawStr, minRun)
    end

    -- Быстрый путь: служебные бинарные пакеты (sync, id 18-22, 207 и т.п.)
    -- идут потоком десятками в секунду и НЕ содержательны для анализатора.
    -- Для них считаем только счётчики и НЕ занимаем очередь.
    local isContent = isContentId or isText

    st.seq = st.seq + 1
    st.totalPackets = st.totalPackets + 1
    if id == 215 then
        st.totalCef = st.totalCef + 1
    end
    if id == 61 then
        st.totalDialog = st.totalDialog + 1
    end
    if isText then
        st.totalText = st.totalText + 1
    end
    if dir == "RX" then
        st.totalRx = st.totalRx + 1
    elseif dir == "TX" then
        st.totalTx = st.totalTx + 1
    end

    -- Содержательные пакеты кладём в очередь на обработку в главном цикле.
    -- Самое дорогое (разбор + классификация + запись) не выполняется здесь,
    -- поэтому сетевой поток и фризы не связаны со скриптом.
    if isContent then
        local tNow, dNow = cachedDateTime()
        enqueuePending(st.seq, dir, id, bodyLen, totalBytes, rawStr, tNow, dNow, isText)
    end
end

-- Публичные обработчики, вызываемые главным скриптом
local C = {
    onReceivePacket = function(id, bs)
        onCapture("RX", id, bs, nil)
    end,
    onSendPacket = function(id, bs)
        onCapture("TX", id, bs, nil)
    end,
    onServerMessage = function(color, textMsg)
        onCapture("RX", 0, nil, tostring(textMsg or ""))
    end,
    onGameText = function(textMsg, time, style)
        onCapture("RX", 0, nil, tostring(textMsg or ""))
    end,
    -- Синтетическая запись для показанного диалога (id=61).
    -- Строка msg - это байты CP1251 из движка, capture декодирует в UTF-8.
    onCaptureMsg = function(msg)
        onCapture("RX", 61, nil, tostring(msg or ""))
    end,
    onConnectionClosed = function() end,
    onConnectionLost = function() end,
    -- Установка заглушки: вызывается для каждой записи пакета (для автозаписи в файл)
    setEmit = function(fn)
        emitCallback = fn
    end,
    -- Обработка очереди пакетов в главном цикле с бюджетом времени и лимитом
    -- записей за один вызов (чтобы ни при каких условиях не было фриза).
    drain = function(budgetSec, maxCount)
        return processPending(budgetSec, maxCount)
    end,
    -- Принудительная досборка всей очереди (для /cpa save, clear, выгрузка)
    drainAll = function()
        -- Цикл до тех пор, пока очередь не выдохнется (processPending вернёт 0)
        while true do
            local n = processPending(10, 1000)
            if n == 0 then
                break
            end
        end
        -- компактизация после полного слива
        pendingQueue = {}
        pendingHead = 1
        pendingTail = 1
        pendingCount = 0
    end,
    getPlayerPos = getPlayerPos,
    snapshotContext = snapshotContext,
}

return C