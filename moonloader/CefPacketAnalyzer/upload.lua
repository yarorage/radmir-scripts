-- Отправка агрегатов на сервер (вебхук Apps Script / Google Sheets)
-- Клиент раз в uploadEvery секунд (с джиттером) отправляет сводку: ник игрока,
-- счётчики категорий и событий, список открытых окон по URL и уникальные типы
-- пакетов. Пакет маленький, отправка редкая, чтобы не грузить игру и не
-- упираться в лимиты Google. Ник идёт в UTF-8 (JSON).
--
-- КАНАЛ ПО УМОЛЧАНИЮ — неблокирующий движковый async.httpPost: запрос
-- выполняется в фоновом потоке движка MoonRage (WinHTTP, пул потоков),
-- игровой поток при этом не блокируется, фризов нет, внешние процессы и окна
-- не запускаются. Результат приходит в callback, накапливается в общей
-- очереди и разбирается в главном цикле (tick). Если async недоступен
-- (старый движок) — автоматический фолбэк на фоновый файл pending/ для
-- ПК-сборщика. Синхронный отправитель оставлен только как ручной резерв
-- (backgroundUpload == false).
local state = require("CefPacketAnalyzer.state")
local encUtils = require("CefPacketAnalyzer.enc_utils")

local M = {}

local nextUploadAt = 0
local pendingPayload = nil
local fails = 0

-- Фоновый канал движка: результаты приходят из callback`а пула потоков и
-- складываются сюда, а в tick разбираются уже в главном потоке.
local asyncResults = {}
local asyncInFlight = false -- идёт ли сейчас неблокирующий запрос
local asyncSeq = 0          -- серийник запущенного запроса (для сопоставления)
local asyncStartedAt = 0    -- время запуска (сторож зависшего запроса)

-- Доступен ли неблокирующий HTTP-канал движка MoonRage
local function hasAsyncHttp()
    return type(async) == "table" and type(async.httpPost) == "function"
end

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
-- Это фолбэк, когда движок не даёт async.httpPost.
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

-- Синхронный резервный отправитель (HTTPS из игрового потока). Блокирует
-- игровой поток на доли секунды, поэтому используется ТОЛЬКО при
-- backgroundUpload == false (ручная диагностика).
-- ВАЖНО: Apps Script вебхук выполняет doPost на первом же POST, а в ответ
-- отдаёт 302 (редирект на служебный echo-URL). Повторять запрос по Location
-- нельзя: echo-URL не принимает POST. Успехом считается 2xx, 302 и 405.
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
        local okCall, code, respStatus = pcall(sslHttps.request, {
            url = url,
            method = "POST",
            headers = headers,
            source = ltn12.source.string(body),
        })
        if not okCall then
            return nil, "сетевая ошибка: " .. tostring(code)
        end
        -- pcall добавляет результат true перед значениями sslHttps.request,
        -- поэтому code уже число HTTP-кода, а не заголовки.
        return true, tostring(code or "нет кода") .. " " .. tostring(respStatus or ""), code
    end
    local okHttp, socketHttp = pcall(require, "socket.http")
    if not okHttp then
        return nil, "модуль socket.http недоступен"
    end
    socketHttp.TIMEOUT = 3
    local okCall, code, respStatus = pcall(socketHttp.request, {
        url = url,
        method = "POST",
        headers = headers,
        source = body,
    })
    if not okCall then
        return nil, "сетевая ошибка: " .. tostring(code)
    end
    return true, tostring(code or "нет кода") .. " " .. tostring(respStatus or ""), code
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
    -- Успех: 2xx, а также 302 (редирект echo-URL, как отдаёт Apps Script)
    -- и 405 (echo-URL не даёт POST после следовании редиректу).
    if not code or not (tostring(code):match("^2") or code == 302 or code == 405) then
        return false, "ответ сервера: " .. tostring(code or "нет кода") .. " (" .. tostring(statusMsg) .. ")"
    end
    return true
end

-- Неблокирующая отправка через движковый async.httpPost. Возвращает true —
-- запрос успешно запущен в фоне; результат придёт в asyncResults и будет
-- разобран в tick. Callback выполняет минимум работы: только кладёт ответ
-- в общую очередь (тяжёлая логика — чисты/логи — в главном потоке).
local function startAsync(payload)
    if not hasAsyncHttp() then
        return false, "async.httpPost недоступен на этом движке"
    end
    local okEnc, body = pcall(function()
        local dkjson = require("dkjson")
        return dkjson.encode(payload)
    end)
    if not okEnc or not body or body == "" then
        return false, "не удалось собрать JSON агрегата"
    end
    local url = state.state.uploadUrl
    if not url or url == "" then
        return false, "не задан адрес вебхука"
    end

    asyncSeq = asyncSeq + 1
    local mySeq = asyncSeq
    local okCall, err = pcall(async.httpPost, url, body, function(resp)
        local code = resp and resp.statusCode or 0
        -- Движок ставит success=true только для 2xx; для вебхука Apps Script
        -- редирект 302 — это нормальный ответ (echo-URL), 405 — тоже успех.
        local okSend = resp ~= nil and (
            resp.success or code == 302 or code == 405 or tostring(code):match("^2")
        )
        asyncResults[#asyncResults + 1] = {
            seq    = mySeq,
            ok     = okSend and true or false,
            code   = code,
            detail = (resp and (resp.success and "" or (resp.error or ""))) or "нет ответа",
        }
    end)
    if not okCall then
        return false, "ошибка запуска async.httpPost: " .. tostring(err)
    end

    asyncInFlight = true
    asyncStartedAt = os.time()
    return true
end

-- Забирает один накопленный ответ фонового канала (только для текущего
-- запущенного запроса). Для старых ответов (seq != asyncSeq) не трогает
-- флаг inFlight — это ответы уже неактуальных попыток.
local function drainAsync()
    if #asyncResults == 0 then
        return nil
    end
    local res = table.remove(asyncResults, 1)
    if res.seq == asyncSeq then
        asyncInFlight = false
    end
    return res
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

-- Ник игрока в UTF-8. Берём из входящего CEF-пакета: username= в URL окна
-- авторизации (login...) либо поле username/nick в JSON CEF-команды.
local function localNick()
    -- Ник берём ТОЛЬКО из входящего CEF-пакета (state.gameNick).
    -- СРЕДСТВА SAMP-API ЗДЕСЬ НЕ ИСПОЛЬЗУЕМ: пул игроков на входе в сервер
    -- может быть ещё не создан (риск AV), а в строках точный ник уже
    -- передаётся в CEF-командах setPlayerNickName / username=.
    local st = state.state
    if st.gameNick and st.gameNick ~= "" then
        return st.gameNick
    end
    return nil
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
        version = "1.2.3",
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

-- Основной канал: неблокирующий async движка. Если движок не даёт async —
-- фоновый файл pending/ (сборщик). Синхронный отправитель — только ручной
-- резерв (backgroundUpload == false).
-- Возвращает: okSend, detail, deferredSend. deferredSend == true — запрос лишь
-- стартован в фоне, подтверждение (и чистка) придёт через asyncResults.
local function doSend(payload)
    if state.state.backgroundUpload == false then
        local okReq, detail = sendPayload(payload)
        return okReq, detail, false
    end
    if hasAsyncHttp() then
        local okReq, detail = startAsync(payload)
        return okReq, detail, okReq and true or false
    end
    local okSave, detail = savePending(payload)
    return okSave, detail, false
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

    -- 1) Разбираем накопленные ответы фонового канала (если пришли).
    local res = drainAsync()
    if res ~= nil then
        if res.ok then
            pendingPayload = nil
            fails = 0
            cleanAfterUpload()
        else
            fails = fails + 1
            if fails <= 3 then
                local why = res.detail
                if why == nil or why == "" then
                    why = "код " .. tostring(res.code or 0)
                end
                state.log("Ошибка фоновой отправки агрегата (попытка " .. fails .. ": " .. tostring(why) .. ")")
            end
        end
    end

    -- 2) Сторож: если запрос "завис" дольше лимита — освобождаем inFlight,
    --    чтобы следующий тик запустил новую попытку.
    if asyncInFlight and os.time() - asyncStartedAt > 180 then
        asyncInFlight = false
        fails = fails + 1
    end

    -- 3) Проверяем интервал.
    local now = os.time()
    if now < nextUploadAt then
        return
    end
    local jitter = st.uploadJitter or 0
    nextUploadAt = now + (st.uploadEvery or 600) + randomBetween(-jitter, jitter)
    if nextUploadAt < now + 60 then
        nextUploadAt = now + 60
    end

    -- Запрос ещё в полёте — второй не запускаем.
    if asyncInFlight then
        return
    end

    local payload = pendingPayload or buildPayload()
    local okSend, detail, deferredSend = doSend(payload)
    if okSend then
        -- Для асинхронного канала очистка/сброс произойдут после подтверждения
        -- в drainAsync; pendingPayload храним, пока ответ не пришёл.
        if not deferredSend then
            pendingPayload = nil
            fails = 0
            cleanAfterUpload()
        end
    else
        fails = fails + 1
        pendingPayload = payload
        if fails <= 3 then
            state.log("Ошибка запуска фоновой отправки агрегата (попытка " .. fails .. ": " .. tostring(detail) .. ")")
        end
    end
end

-- Принудительная отправка прямо сейчас (команда /cpa upload now)
-- Возвращает: okSend (bool), detail (причина отказа, если есть).
function M.force()
    local payload = buildPayload()
    local okSend, detail, deferredSend = doSend(payload)
    if okSend then
        if not deferredSend then
            pendingPayload = nil
            fails = 0
            cleanAfterUpload()
        end
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
    asyncResults = {}
    asyncInFlight = false
    asyncStartedAt = 0
end

-- Статус для команды /cpa upload
function M.statusText()
    local st = state.state
    local link = st.uploadUrl
    if link and link ~= "" and #link > 60 then
        link = link:sub(1, 57) .. "..."
    end
    -- Ник из CEF хранится в UTF-8, а чат и литералы работают в CP1251
    -- (M.chat передаёт байты как есть). Перекодируем ник в CP1251,
    -- иначе кириллический ник в чате будет "кракозябрами".
    local nick = localNick()
    if nick and nick ~= "" then
        nick = encUtils.utf8ToBytesCp(nick)
    elseif nick == "" then
        nick = nil
    end
    if not nick or nick == "" then
        nick = "не подключён"
    end
    local mode = "синхронно (резерв)"
    if st.backgroundUpload ~= false then
        mode = hasAsyncHttp() and "фон. движком (async)" or "фон. сборщиком (файл)"
    end
    return string.format(
        "отправка: %s | режим: %s | адрес: %s | интервал: %d сек (±%d) | ник: %s",
        st.uploadEnabled and "вкл" or "выкл",
        mode,
        link and link ~= "" and link or "не задан",
        st.uploadEvery or 600,
        st.uploadJitter or 0,
        nick
    )
end

return M