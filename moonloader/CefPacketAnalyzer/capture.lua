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

-- Перевод произвольной строки (UTF-8 на входе движка) в строку без ломаных байт
local function sanitizeUtf8(s)
    if not s then return "" end
    -- заменяем управляющие символы (байт 0 выносим отдельно: \0 ломает класс паттерна Lua)
    s = s:gsub("%z", " ")
    s = s:gsub("[\1\2\3\4\5\6\7\8\9\11\12\13\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]", " ")
    -- удаляем некорректные продолжения (например, 0x80..0xBF после ASCII) - оставляем как есть
    return s
end

-- Читаем тело пакета из bitstream и возвращаем текст + массив байт
local function readPacketBody(bs)
    local n = raknetBitStreamGetNumberOfBytesUsed(bs)
    if not n or n < 0 then
        return "", 0, 0
    end
    local bytes = {}
    for i = 1, n do
        local ok, b = pcall(raknetBitStreamReadInt8, bs)
        if ok and b and b ~= false then
            bytes[i] = b
        else
            bytes[i] = 0
        end
    end
    -- сбрасываем указатель чтения
    pcall(raknetBitStreamResetReadPointer, bs)
    local raw = {}
    for i = 1, #bytes do
        raw[i] = string.char(bytes[i] % 256)
    end
    local rawStr = table.concat(raw)
    return rawStr, #bytes, n
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

-- Снимок контекста для записи
local function snapshotContext()
    local px, py, pz = getPlayerPos()
    local cur, cx, cy = getCursorState()
    return {
        px = px,
        py = py,
        pz = pz,
        cursorOn = cur,
        cursorX = cx,
        cursorY = cy,
    }
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

-- Пользовательская заглушка: вызывается для каждой захваченной записи.
local emitCallback = nil

-- Основной обработчик захваченного пакета
-- dir: "RX"/"TX"; id: номер пакета; bs: bitstream; extra: строка-дополнение (для серверных сообщений)
local function onCapture(dir, id, bs, extra)
    local st = state.state

    if not st.enabled then
        return
    end

    local rawStr
    local bytes = {}
    local bodyLen = 0

    if bs then
        rawStr, bodyLen, totalBytes = readPacketBody(bs)
        if bodyLen > 0 then
            -- преобразуем байты для чтения текста
            local realBytes = {}
            for i = 1, bodyLen do
                realBytes[i] = rawStr:byte(i) or 0
            end
            bytes = realBytes
        end
    else
        rawStr = extra or ""
        bodyLen = #rawStr
        for i = 1, bodyLen do
            bytes[i] = rawStr:byte(i) or 0
        end
    end

    local text = ""
    if bodyLen > 0 then
        text = decodeBody(rawStr)
        text = sanitizeUtf8(text)
    end

    -- Определяем, текстовый ли это пакет (для потока и отбора)
    local isText = isTextBody(rawStr, st.minTextRun)
    if #text >= st.minTextRun then
        isText = true
    end

    -- Ограничиваем тело
    local bodyForStore = text
    if #bodyForStore > st.maxBodyLen then
        bodyForStore = bodyForStore:sub(1, st.maxBodyLen)
    end

    local ctx = snapshotContext()
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

    local record = {
        seq = st.seq,
        dir = dir,
        id = id,
        bodyLen = bodyLen,
        size = totalBytes or bodyLen,
        time = os.time(),
        dateStr = os.date("%Y-%m-%d %H:%M:%S"),
        text = bodyForStore,
        isText = isText,
        ctx = ctx,
        phaseAtCapture = st.phase,
        phaseName = state.phaseName(),
        -- Подпись для дедупликации в итоговой таблице
        sig = classify.signature(bodyForStore),
    }
    record.dedupKey = dir .. "|" .. tostring(id) .. "|" .. record.sig

    -- Классификация из базы знаний
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
    -- Точные байты тела (HEX) для ВСЕХ пакетов: нужны для разбора и анализа
    -- бинарных пакетов скриптами. Для длинных тел сохраняем первые 512 байт.
    if bodyLen > 0 then
        local h = {}
        local n = math.min(bodyLen, 512)
        for i = 1, n do
            h[i] = string.format("%02X", bytes[i] or 0)
        end
        record.bodyHex = table.concat(h)
    end
    -- Отдельно для TX-пакета интерфейса (id=215): полный hex без ограничения,
    -- одно в одно, как клиент отправил его на сервер. Плюс копия для сводки.
    if record.dir == "TX" and record.id == 215 and bodyLen > 0 then
        local h = {}
        for i = 1, bodyLen do
            h[i] = string.format("%02X", bytes[i] or 0)
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
    -- Ник игрока на сервере (из пакета авторизации) запоминаем в состоянии:
    -- последний логин считается текущим.
    if record.nick and record.nick ~= "" then
        st.gameNick = record.nick
    end

    updatePhase(record)

    -- Счётчики по категориям
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

    -- Глобальные агрегаты для сводки (полные, без влияния лимита записей)
    if dir == "RX" then
        st.totalRx = st.totalRx + 1
    elseif dir == "TX" then
        st.totalTx = st.totalTx + 1
    end
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
    -- Уникальные типы пакетов (как в итоговой таблице)
    local uniqueKey = record.dedupKey or (dir .. "|" .. tostring(id) .. "|" .. (record.sig or ""))
    local te = st.typeSeen[uniqueKey]
    if not te then
        te = { idx = #st.typeList + 1, n = 1 }
        st.typeSeen[uniqueKey] = te
        if #st.typeList < 600 then
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

    -- Добавляем запись с учётом лимита
    if #st.records < st.maxRecords then
        table.insert(st.records, record)
    end

    -- Автоматическая запись в файл происходит в emit-заглушке (настраивается в main)
    if emitCallback then
        emitCallback(record)
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
    getPlayerPos = getPlayerPos,
    snapshotContext = snapshotContext,
}

return C