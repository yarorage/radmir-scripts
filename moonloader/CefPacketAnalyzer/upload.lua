-- Отправка агрегатов на сервер (вебхук Apps Script / Google Sheets)
-- Клиент раз в uploadEvery секунд (с джиттером) отправляет сводку: ник игрока,
-- счётчики категорий и событий, список открытых окон по URL и уникальные типы
-- пакетов. Пакет маленький, отправка редкая, чтобы не грузить игру и не
-- упираться в лимиты Google. Ник идёт в UTF-8 (JSON).
local state = require("CefPacketAnalyzer.state")
local encUtils = require("CefPacketAnalyzer.enc_utils")

local M = {}

local nextUploadAt = 0
local pendingPayload = nil
local fails = 0
local nickUtf8 = nil
local nickChecked = false
local poolReady = false

-- Родительская папка файла/пути
local function parentDirectory(path)
    path = tostring(path or ""):gsub("[\\/]+$", "")
    return path:match("^(.*)[\\/][^\\/]+$") or path
end

-- Папка отложенных агрегатов: рядом с выходной папкой отчётов,
-- например <корень игры>\CefPacketAnalyzer\pending (если outputDir
-- вообще не задан — рядом с working directory).
local function pendingDirectory()
    local out = state.state.outputDir
    if not out or out == "" then
        local ok, wd = pcall(getWorkingDirectory)
        out = tostring(ok and wd or ".")
    end
    return (parentDirectory(out) or out) .. "\\pending"
end

-- Запись агрегата файлом для фоновой отправки ПК-сборщиком.
-- Сеть в игровом потоке НЕ используется вообще, поэтому фризов нет.
-- Файл подхватывает collect_cefpackets.ps1 и отправляет на вебхук.
local function savePending(payload)
    local okEnc, body = pcall(function()
        local dkjson = require("dkjson")
        return dkjson.encode(payload)
    end)
    if not okEnc or not body or body == "" then
        return false, "не удалось собрать JSON агрегата"
    end
    local dir = pendingDirectory()
    pcall(createDirectory, dir)
    local file = dir .. "\\aggregate_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999)) .. ".json"
    local fh, ferr = io.open(file, "w")
    if not fh then
        return false, "не удалось открыть файл агрегата: " .. tostring(ferr)
    end
    fh:write(body)
    fh:close()
    state.log("Агрегат сохранён для фоновой отправки: " .. file)
    return true, file
end

-- Устаревший синхронный канал (HTTPS из игрового потока). Оставлен на время
-- тестов фонового режима; при успешной проверке его удалить.
-- ВАЖНО: Apps Script вебхук выполняет doPost на первом же POST, а в ответ
-- отдаёт 302 (редирект на служебный echo-URL). Повторять запрос по Location
-- нельзя: echo-URL не принимает POST (405). Успехом считается 2xx и 302.
local function httpPost(url, body)
    local headers = {
        ["Content-Type"] = "text/plain;charset=utf-8",
        ["Content-Length"] = tostring(#body),
    }
    if string.sub(url, 1, 8) == "https://" then
        local okSsl, sslHttps = pcall(require, "ssl.https")
        if not okSsl then
            state.log("Модуль ssl.https недоступен — отправка на https невозможна")
            return nil, "модуль ssl.https недоступен (нужен LuaSec)"
        end
        local okLtn, ltn12 = pcall(require, "ltn12")
        if not okLtn or not ltn12 or not ltn12.source or not ltn12.source.string then
            return nil, "модуль ltn12 недоступен"
        end
        return pcall(sslHttps.request, {
            url = url,
            method = "POST",
            headers = headers,
            source = ltn12.source.string(body),
        })
    end
    local okHttp, socketHttp = pcall(require, "socket.http")
    if not okHttp then
        return nil, "модуль socket.http недоступен"
    end
    socketHttp.TIMEOUT = 3
    return pcall(socketHttp.request, {
        url = url,
        method = "POST",
        headers = headers,
        source = body,
    })
end

local function sendPayload(payload)
    local url = state.state.uploadUrl
    if not url or url == "" then
        return false
    end
    local okEnc, body = pcall(function()
        local dkjson = require("dkjson")
        return dkjson.encode(payload)
    end)
    if not okEnc or not body or body == "" then
        return false
    end
    local okReq, statusMsg, code = httpPost(url, body)
    if not okReq then
        return false, "сетевая ошибка: " .. tostring(statusMsg)
    end
    if not code or not (tostring(code):match("^2") or code == 302) then
        return false, "ответ сервера: " .. tostring(code or "нет кода") .. " (" .. tostring(statusMsg) .. ")"
    end
    return true
end

-- После успешной отправки подчищаем локальные данные, чтобы не копились:
-- сбрасываем записи/счётчики и удаляем лог-файлы (всё уже ушло в Google).
-- Операция раз в ~10 минут, лёгкая, фризов не даёт.
local function cleanAfterUpload()
    local st = state.state
    if not st.autoCleanAfterUpload then
        return
    end
    local ok, output = pcall(require, "CefPacketAnalyzer.output")
    state.resetSession()
    if ok and output and output.rotateLogs then
        pcall(output.rotateLogs)
    end
end

local function randomBetween(a, b)
    return a + math.random() * (b - a)
end

-- Ник игрока в UTF-8. Приоритет — ник из CEF-пакета авторизации (точный,
-- берём из окна входа username=). Запасной вариант — системный ник из движка
-- (байты CP1251, переводим в UTF-8).
local function localNick()
    local st = state.state
    if not poolReady then
        return nil
    end
    if st.gameNick and st.gameNick ~= "" then
        return st.gameNick
    end
    if nickChecked then
        return nickUtf8
    end
    nickChecked = true
    local pid
    if PLAYER_PED and sampGetPlayerIdByCharHandle then
        local ok, res, resPid = pcall(sampGetPlayerIdByCharHandle, PLAYER_PED)
        pid = resPid or res
    end
    if pid and sampGetPlayerNickname then
        local ok2, nick = pcall(sampGetPlayerNickname, pid)
        if ok2 and nick and #nick > 0 then
            nickUtf8 = encUtils.bytesCpToUtf8(nick)
        end
    end
    return nickUtf8
end

-- Собираем агрегаты из глобальных счётчиков сессии (полные: не зависят от
-- лимита records, поэтому таблица и отправляемые пакеты не расходятся).
-- Большие списки урезаем до PAYLOAD_CAP: меньше JSON, меньше фриз при encode.
local PAYLOAD_CAP = 300
local function trimList(list, cap)
    if not list or #list <= cap then
        return list
    end
    local out = {}
    for i = #list - cap + 1, #list do
        out[#out + 1] = list[i]
    end
    return out
end

local function buildPayload()
    local st = state.state

    -- Категории и события берём из полного агрегата по всем пакетам.
    local byCat = {}
    local byEvent = {}
    for cat, cnt in pairs(st.counters) do
        byCat[cat] = cnt.count
        if cnt.events then
            for ev, e in pairs(cnt.events) do
                byEvent[ev] = (byEvent[ev] or 0) + e.count
            end
        end
    end

    -- Окна по URL-адресу (все пакеты, а не только хранимые записи).
    local byUrl = {}
    for u, n in pairs(st.urlCounts) do
        byUrl[u] = n
    end

    return {
        script = "CefPacketAnalyzer",
        version = "1.15.3",
        nick = localNick() or "unknown",
        ts = os.time(),
        ts_text = os.date("%Y-%m-%d %H:%M:%S"),
        start = st.startTime,
        phase = st.phase,
        packets = st.totalPackets,
        cef = st.totalCef,
        dialogs = st.totalDialog,
        text = st.totalText,
        counts = { rx = st.totalRx or 0, tx = st.totalTx or 0 },
        by_cat = byCat,
        by_event = byEvent,
        by_url = byUrl,
        types = trimList(st.typeList, PAYLOAD_CAP),
        cef_cmds = trimList(st.cefCmdList, PAYLOAD_CAP),
        tx_hex = trimList(st.txHexList, PAYLOAD_CAP),
    }
end

-- Текущий канал отправки: фоновый (файл) по умолчанию, синхронный — резерв.
local function doSend(payload)
    if state.state.backgroundUpload == false then
        return sendPayload(payload)
    end
    return savePending(payload)
end

-- Плановый тик: вызывается из главного цикла, сам решает, когда отправлять.
function M.tick()
    local st = state.state
    if not st.uploadEnabled then
        return
    end
    if not localNick() then
        return
    end
    local now = os.time()
    if now < nextUploadAt then
        return
    end
    local jitter = st.uploadJitter or 0
    nextUploadAt = now + (st.uploadEvery or 600) + randomBetween(-jitter, jitter)
    if nextUploadAt < now + 60 then
        nextUploadAt = now + 60
    end

    local payload = pendingPayload or buildPayload()
    local okSend, detail = doSend(payload)
    if okSend then
        pendingPayload = nil
        fails = 0
        cleanAfterUpload()
    else
        fails = fails + 1
        pendingPayload = payload
        if fails <= 3 then
            state.log("Ошибка фоновой отправки агрегата (попытка " .. fails .. ", причина: " .. tostring(detail) .. ")")
        end
    end
end

-- Принудительная отправка прямо сейчас (команда /cpa upload now)
-- Возвращает: okSend (bool), detail (причина отказа, если есть).
function M.force()
    local payload = buildPayload()
    local okSend, detail = doSend(payload)
    if okSend then
        pendingPayload = nil
        fails = 0
        cleanAfterUpload()
    else
        pendingPayload = payload
        fails = fails + 1
    end
    return okSend, detail
end

-- Сброс планировщика (команда /cpa clear)
function M.reset()
    nextUploadAt = 0
    pendingPayload = nil
    fails = 0
end

-- Статус для команды /cpa upload
function M.statusText()
    local st = state.state
    local link = st.uploadUrl
    if link and link ~= "" and #link > 60 then
        link = link:sub(1, 57) .. "..."
    end
    return string.format(
        "отправка: %s | режим: %s | адрес: %s | интервал: %d сек (±%d) | ник: %s",
        st.uploadEnabled and "вкл" or "выкл",
        st.backgroundUpload == false and "синхронно (резерв)" or "фон. сборщиком",
        link and link ~= "" and link or "не задан",
        st.uploadEvery or 600,
        st.uploadJitter or 0,
        localNick() or "не подключён"
    )
end

-- сигнал о готовности SAMP-пула игроков (пул создан - можно обращаться к SAMP-API).
-- Открывается в main при первом onServerMessage, закрывается на onDisconnect.
function M.setPoolReady(ok)
    poolReady = ok == true
end

function M.isPoolReady()
    return poolReady
end

return M