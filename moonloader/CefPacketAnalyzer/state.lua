-- Состояние и настройки CefPacketAnalyzer
-- Модуль хранит настройки сбора, текущую игровую фазу и статистику по пакетам.
local M = {}

-- Описания игровых фаз (в какой момент возникает пакет)
M.PHASE_RU = {
    idle        = "вне игры / не подключён",
    connecting  = "подключение к серверу",
    loading     = "экран загрузки",
    login       = "авторизация (окно входа)",
    spawn_select = "выбор точки спавна",
    in_world    = "в игровом мире",
    reconnecting = "переподключение",
    unknown     = "фаза не определена",
}

-- Описания направлений
M.DIR_RU = {
    RX = "приём от сервера",
    TX = "отправка на сервер",
}

-- Строки-литералы движка хранятся в CP1251, а отчёты пишутся в UTF-8:
-- заранее переводим русские описания фаз и направлений в UTF-8.
local encUtils = require("CefPacketAnalyzer.enc_utils")
for k, v in pairs(M.PHASE_RU) do
    M.PHASE_RU[k] = encUtils.bytesCpToUtf8(v)
end
for k, v in pairs(M.DIR_RU) do
    M.DIR_RU[k] = encUtils.bytesCpToUtf8(v)
end

M.state = {
    -- Настройки сбора
    enabled      = true,   -- вкл/выкл сбор
    verboseStream = true,  -- справка: поток-файл ведётся всегда во время сбора
    maxBodyLen   = 4096,   -- максимум сохраняемого текста тела пакета
    maxRecords   = 20000,  -- максимум записей в памяти (в поток отчётов пишется всё)
    minTextRun   = 12,     -- минимальная длина читабельной строки, чтобы пакет считался текстовым
    parseJson    = true,   -- пытаться разбирать JSON в теле пакета
    outputOneLevelAbove = true, -- складывать отчёты на уровень выше папки с игрой
    outputFolder = nil,    -- корневая папка отчётов (выставляется в main)
    outputDir    = nil,    -- папка с отчётами

    -- Настройки отправки агрегатов на сервер (вебхук Apps Script / Google Sheets)
    uploadEnabled = true, -- собирать и отправлять агрегаты (только если задан uploadUrl)
    uploadUrl     = "https://script.google.com/macros/s/AKfycby2dKcrUs2_D0TBEtRV75L5VnFFpfnMXEyasPc9vqOQMeXszqO_VUan0gL518X04XVpbQ/exec", -- адрес вебхука
    backgroundUpload = true, -- фоновый режим: агрегат пишется файлом в pending/, отправку делает ПК-сборщик (в игре сеть не используется). false = старый синхронный канал.
    uploadEvery   = 600,  -- базовый интервал отправки, сек (10 минут)
    uploadJitter  = 180,  -- случайный разброс интервала ±сек (защита от синхронных пиков)
    -- Подчистка локальных данных после успешной отправки: записи и лог-файлы
    -- сбрасываются, чтобы не копились на клиенте. Все данные уже в Google.
    autoCleanAfterUpload = true,

    -- Состояние сессии
    startTime    = nil,
    seq          = 0,      -- сквозной номер захваченного пакета
    connected    = false,
    phase        = "idle",
    spawned      = false,
    cursorOn     = false,
    lastPosX     = 0,
    lastPosY     = 0,
    lastPosZ     = 0,
    gameNick     = nil,   -- ник игрока на сервере из CEF-пакета авторизации (UTF-8)

    -- Записи и статистика
    records      = {},     -- записи текущей сессии (ограничено maxRecords)
    counters     = {},     -- агрегат по категориям: cat -> {count, first, last, events={}}
    totalPackets = 0,
    totalCef     = 0,      -- пакеты id=215
    totalDialog  = 0,      -- пакеты id=61
    totalText    = 0,      -- текстовые пакеты

    -- Глобальные агрегаты для сводки: считаются для КАЖДОГО пакета независимо
    -- от лимита records, чтобы таблица и отправляемые пакеты не расходились.
    totalRx         = 0,   -- принято от сервера (все пакеты)
    totalTx         = 0,   -- отправлено на сервер (все пакеты)
    urlCounts       = {},  -- url окна -> количество (все пакеты)
    cefCmdList      = {},  -- уникальные CEF-команды: {cmd, url, n}
    cefCmdSeen      = {},  -- ключ cmd|url -> запись в cefCmdList
    typeList        = {},  -- уникальные типы пакетов: {dir, id, category, cmd, url, count}
    typeSeen        = {},  -- dedupKey -> {idx, n}
    txHexList       = {},  -- все TX-пакеты id=215: {ts, dateStr, len, hex, cmd, url} (история, не только сводка)
}

function M.log(msg)
    print("[CefPacketAnalyzer] " .. tostring(msg))
end

function M.chat(msg)
    if isSampAvailable and isSampAvailable() then
        sampAddChatMessage("{66CCFF}[CefPkt]{FFFFFF} " .. tostring(msg), -1)
    end
end

-- Полное сбрасывание счётчиков и записей (при новом захвате)
function M.resetSession()
    local s = M.state
    s.seq = 0
    s.records = {}
    s.counters = {}
    s.totalPackets = 0
    s.totalCef = 0
    s.totalDialog = 0
    s.totalText = 0
    s.totalRx = 0
    s.totalTx = 0
    s.urlCounts = {}
    s.cefCmdList = {}
    s.cefCmdSeen = {}
    s.typeList = {}
    s.typeSeen = {}
    s.txHexList = {}
    s.connected = false
    s.phase = "idle"
    s.spawned = false
    s.cursorOn = false
end

-- Человекопонятное имя фазы
function M.phaseName()
    return M.PHASE_RU[M.state.phase] or M.PHASE_RU.unknown
end

return M