-- Вывод отчётов CefPacketAnalyzer
-- Формирует: packets_stream.txt (поток-лог всех пакетов, append),
-- packets_table.html (таблица в CP1251 для встроенного интерфейса),
-- packets_data.json (все записи текущего прогона в UTF-8),
-- packets_summary.txt (сводка по категориям).
local state = require("CefPacketAnalyzer.state")
local classify = require("CefPacketAnalyzer.classify")
local encUtils = require("CefPacketAnalyzer.enc_utils")
local M = {}

local streamFile  = "packets_stream.txt"
local tableFile   = "packets_table.html"
local dataFile    = "packets_data.json"
local summaryFile = "packets_summary.txt"
local uniqueFile  = "packets_unique_table.html"
local dataLineFile = "packets_data.jsonl"

-- Предохранитель размера живых лог-файлов (packets_data.jsonl и packets_stream.txt):
-- если файл вырос выше maxLogSize, выполняется авто-ротация без ожидания upload,
-- чтобы при длительных сбоях выгрузки папка output не разрасталась на диске.
local maxLogSize = 96 * 1024 * 1024
local sizeCheckCounter = 0
local sizeCheckEvery = 200

-- Конвертация UTF-8-строки в CP1251 (для HTML с charset windows-1251)
local function toCp1251(text)
    return encUtils.utf8ToBytesCp(text)
end

-- Экранирование HTML
local function escHtml(s)
    s = tostring(s or "")
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    return s
end

-- Экранирование одиночных кавычек для Lua-строк в HTML-таблице (не применяем - без скриптов)
local function fullPath(name)
    local dir = state.state.outputDir or os.getenv("TEMP")
    return dir .. "\\" .. name
end

-- Ячейка "Команда / URL окна" по записи пакета
local function cefCell(r)
    local cell = ""
    if r.cmd and r.cmd ~= "" then
        cell = cell .. "<div class=\"cef-cmd\">" .. escHtml(r.cmd) .. "</div>"
    end
    if r.uiUrl and r.uiUrl ~= "" then
        cell = cell .. "<div class=\"cef-url\">" .. escHtml(r.uiUrl) .. "</div>"
    end
    if r.win then
        local w = r.win
        cell = cell .. string.format("<div class=\"cef-win\">окно %s x %s (x=%s, y=%s)</div>",
            tostring(w.w or "-"), tostring(w.h or "-"), tostring(w.x or "-"), tostring(w.y or "-"))
    end
    if r.dataKeys and #r.dataKeys > 0 then
        cell = cell .. "<details><summary>Данные (" .. #r.dataKeys .. ")</summary><div class=\"cef-keys\">"
        for i = 1, #r.dataKeys do
            if i > 1 then
                cell = cell .. ", "
            end
            cell = cell .. escHtml(r.dataKeys[i])
        end
        cell = cell .. "</div></details>"
    end
    return cell
end

-- Безопасное открытие файла
local function openWrite(name, mode)
    local fh, err = io.open(fullPath(name), mode or "w")
    if not fh then
        state.log("Ошибка записи " .. name .. ": " .. tostring(err))
        return nil
    end
    return fh
end

-- Одна строка потока
local function streamLine(rec)
    local evs = ""
    if rec.events and #rec.events > 0 then
        evs = " событие=\"" .. rec.events[1] .. "\""
    end
    return string.format("[%s] %s id=%-4d size=%-6d cat=%s%s категория=\"%s\"",
        rec.dateStr, rec.dir, rec.id, rec.size, rec.category, evs, rec.categoryTitle or rec.category)
end

-- Поток всегда дописывается в один постоянно открытый файл,
-- чтобы не тратить время на открытие/закрытие на каждый пакет.
local streamHandle = nil

local function getStreamHandle()
    if streamHandle then
        return streamHandle
    end
    local fh, err = io.open(fullPath(streamFile), "a")
    if not fh then
        state.log("Ошибка записи потока: " .. tostring(err))
        return nil
    end
    streamHandle = fh
    return fh
end

-- Буфер строк потока: flush раз в несколько пакетов, чтобы не бить по диску
-- на каждый пакет (это происходит в игровом потоке и съедает FPS).
local streamBuf = ""
local streamBufN = 0
local streamFlushEvery = 50

-- Сброс буфера потока в файл
local function flushStream()
    if #streamBuf == 0 then return end
    local fh = getStreamHandle()
    if not fh then
        streamBuf = ""
        streamBufN = 0
        return
    end
    fh:write(streamBuf)
    fh:flush()
    streamBuf = ""
    streamBufN = 0
end

-- Размер файла через lfs (метаданные, без чтения данных)
local function getFileSize(name)
    local lfsOK, lfs = pcall(require, "lfs")
    if not lfsOK then
        return nil
    end
    local ok, attr = pcall(lfs.attributes, fullPath(name))
    if ok and attr and attr.size then
        return attr.size
    end
    return nil
end

-- Проверка лимита размера живых лог-файлов; при превышении - авто-ротация.
local function enforceLogSizeLimit()
    sizeCheckCounter = sizeCheckCounter + 1
    if sizeCheckCounter < sizeCheckEvery then
        return
    end
    sizeCheckCounter = 0
    for i = 1, 2 do
        local name = (i == 1) and dataLineFile or streamFile
        local size = getFileSize(name)
        if size and size > maxLogSize then
            M.rotateLogs()
            return
        end
    end
end

-- Дописываем запись в поток
function M.appendStream(rec)
    enforceLogSizeLimit()
    local line = streamLine(rec) .. "\n"
    if rec.text and #rec.text > 0 then
        line = line .. "\t" .. rec.text:gsub("\n", " ") .. "\n"
    end
    -- Точный hex тела (без искажений декодера) для TX-пакетов интерфейса.
    if rec.bodyHex and #rec.bodyHex > 0 then
        line = line .. "\tHEX (" .. math.floor(#rec.bodyHex / 2) .. " байт): " .. rec.bodyHex .. "\n"
    end
    streamBuf = streamBuf .. line
    streamBufN = streamBufN + 1
    if streamBufN >= streamFlushEvery then
        flushStream()
    end
end

-- Каждая запись сразу дописывается в JSON-lines (packets_data.jsonl).
-- Этот файл переживает даже жёсткий краш игры: данные не теряются,
-- полные отчёты достраиваются при штатном завершении (/cpa save, выход).
-- Буфер строк данных: flush раз в несколько пакетов, чтобы не бить по диску
-- на каждый пакет. Данные при штатном завершении сбрасываются в closeStream.
local dataBuf = ""
local dataBufN = 0
local dataFlushEvery = 20

local function getDataHandle()
    if dataHandle then
        return dataHandle
    end
    local fh, err = io.open(fullPath(dataLineFile), "a")
    if not fh then
        state.log("Ошибка записи данных: " .. tostring(err))
        return nil
    end
    dataHandle = fh
    return fh
end

-- Сброс буфера данных в файл
local function flushData()
    if #dataBuf == 0 then return end
    local fh = getDataHandle()
    if not fh then
        dataBuf = ""
        dataBufN = 0
        return
    end
    fh:write(dataBuf)
    fh:flush()
    dataBuf = ""
    dataBufN = 0
end

function M.appendData(rec)
    enforceLogSizeLimit()
    local ok, enc = pcall(function()
        local dkjson = require("dkjson")
        return dkjson.encode(rec)
    end)
    if ok and enc then
        dataBuf = dataBuf .. enc .. "\n"
        dataBufN = dataBufN + 1
        if dataBufN >= dataFlushEvery then
            flushData()
        end
    end
end

-- Закрывает открытые файлы (поток и JSON-lines) при завершении/выгрузке скрипта.
-- Объявлен после appendStream/appendData, чтобы обе функции сброса буферов
-- были доступны как upvalue.
function M.closeStream()
    flushStream()
    flushData()
    if streamHandle then
        pcall(function()
            streamHandle:close()
        end)
        streamHandle = nil
    end
    if dataHandle then
        pcall(function()
            dataHandle:close()
        end)
        dataHandle = nil
    end
end

-- Сбор статистики загрузок окон по URL
local function collectWindows()
    local st = state.state
    local map = {}
    for i = 1, #st.records do
        local r = st.records[i]
        local url = r.uiUrl
        if url and url ~= "" then
            local e = map[url]
            if not e then
                e = { url = url, count = 1, first = r.dateStr, last = r.dateStr, cats = {}, cmds = {} }
                map[url] = e
            else
                e.count = e.count + 1
                e.last = r.dateStr
            end
            local cat = r.category or "unknown"
            e.cats[cat] = (e.cats[cat] or 0) + 1
            if r.cmd and r.cmd ~= "" then
                e.cmds[r.cmd] = (e.cmds[r.cmd] or 0) + 1
            end
        end
    end
    local items = {}
    for url, e in pairs(map) do
        table.insert(items, e)
    end
    table.sort(items, function(a, b)
        return a.count > b.count
    end)
    return items
end

-- HTML-секция "Окна интерфейса по URL" (пустая, если окна не найдены)
local function buildWindowsSection()
    local items = collectWindows()
    if #items == 0 then
        return ""
    end
    local parts = {}
    parts[#parts + 1] = "<h2>Окна интерфейса (загрузки по URL)</h2>"
    parts[#parts + 1] = "<table><thead><tr><th>URL окна</th><th>Открываний</th><th>Категории</th><th>Команды</th><th>Первое / последнее</th></tr></thead><tbody>"
    for i = 1, #items do
        local e = items[i]
        local cats = {}
        for cat, n in pairs(e.cats) do
            local meta = classify.categoryMeta(cat)
            cats[#cats + 1] = meta.title .. " x" .. n
        end
        table.sort(cats)
        local cmds = {}
        for cmd, n in pairs(e.cmds) do
            cmds[#cmds + 1] = cmd .. " x" .. n
        end
        table.sort(cmds)
        parts[#parts + 1] = string.format(
            "<tr><td class=\"cef-url\">%s</td><td class=\"cnt\">%d</td><td>%s</td><td>%s</td><td>%s<br>последнее: %s</td></tr>",
            escHtml(e.url), e.count, escHtml(table.concat(cats, ", ")), escHtml(table.concat(cmds, ", ")),
            e.first, e.last
        )
    end
    parts[#parts + 1] = "</tbody></table>"
    return table.concat(parts, "\n")
end

-- Сборка HTML отчёта
local function buildHtml()
    local st = state.state
    local rows = {}
    local maxRows = math.min(#st.records, 3000)
    for i = 1, maxRows do
        local r = st.records[i]
        local cat = r.category or "unknown"
        local catTitle = classify.categoryMeta(cat).title
        local evs = ""
        if r.events and #r.events > 0 then
            evs = table.concat(r.events, ", ")
        end
        local idCell = tostring(r.id)
        if r.pktName and r.pktName ~= "" then
            idCell = r.pktName .. " (" .. tostring(r.id) .. ")"
        end
        local moment = r.phaseAtCapture .. " (" .. (r.phaseName or "") .. ")"
        if r.ctx then
            moment = moment .. "<br>поз: " .. string.format("%.1f;%.1f;%.1f", r.ctx.px or 0, r.ctx.py or 0, r.ctx.pz or 0)
            if r.ctx.cursorOn then
                moment = moment .. ", курсор вкл"
            end
        end
        local ai = ""
        if r.analysis and #r.analysis > 0 then
            ai = "<ul>"
            for _, a in ipairs(r.analysis) do
                ai = ai .. "<li>" .. escHtml(a) .. "</li>"
            end
            ai = ai .. "</ul>"
        end
        local params = ""
        if r.params and #r.params > 0 then
            params = "<details class=\"params\"><summary>Параметры (" .. #r.params .. ")</summary><ul>"
            for _, p in ipairs(r.params) do
                params = params .. "<li>" .. escHtml(p) .. "</li>"
            end
            params = params .. "</ul></details>"
        end
        local body = ""
        if r.text and #r.text > 0 then
            body = "<details class=\"body\"><summary>Тело (" .. r.bodyLen .. " байт)</summary><pre>" .. escHtml(r.text) .. "</pre></details>"
        end
        local whatWhy = escHtml((r.pktIdDesc or "")) .. "</td><td>" .. escHtml((r.description or ""))
        local cefHtml = cefCell(r)
        table.insert(rows, string.format(
            "<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td><td>%d</td>" ..
            "<td class=\"cat cat-%s\">%s</td><td>%s</td>" ..
            "<td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>",
            r.seq, r.dateStr, r.dir, idCell, r.size,
            cat, escHtml(catTitle),
            escHtml(evs),
            cefHtml,
            whatWhy,
            moment,
            ai .. params,
            body
        ))
    end
    local html = {}
    html[#html + 1] = "<!DOCTYPE html>"
    html[#html + 1] = "<html><head><meta charset=\"windows-1251\"><title>CefPacketAnalyzer - таблица пакетов</title>"
    html[#html + 1] = "<style>"
    html[#html + 1] = "body{background:#1a1d24;color:#dde3ea;font:13px/1.4 Segoe UI,Arial,sans-serif;margin:16px}"
    html[#html + 1] = "h1{font-size:18px;color:#5ab0ff;margin:0 0 4px}"
    html[#html + 1] = ".meta{color:#8fa3b8;font-size:12px;margin-bottom:12px}"
    html[#html + 1] = "table{border-collapse:collapse;width:100%;background:#20242e}"
    html[#html + 1] = "th,td{border:1px solid #343a48;padding:5px 7px;text-align:left;vertical-align:top;font-size:12px}"
    html[#html + 1] = "th{background:#2c3240;color:#aebcd0;position:sticky;top:0}"
    html[#html + 1] = "td.cat{white-space:nowrap;font-weight:600}"
    html[#html + 1] = ".cat-login{color:#ff9d5c}.cat-load{color:#5cabff}.cat-spawn{color:#ffd45c}"
    html[#html + 1] = ".cat-menu{color:#c78dff}.cat-dialog{color:#ff8a8a}.cat-world{color:#6fe4a0}"
    html[#html + 1] = ".cat-queue{color:#ffb0c8}.cat-limit{color:#ff5c5c}.cat-error{color:#ff5c5c}"
    html[#html + 1] = ".cat-inv{color:#9de4d2}.cat-money{color:#a9e06f}.cat-shop{color:#f0b28c}"
    html[#html + 1] = ".cat-donate{color:#e9a6ff}.cat-vehicle{color:#8ec9ff}.cat-house{color:#c9a25c}"
    html[#html + 1] = ".cat-job{color:#b5a0ff}.cat-police{color:#7f9bff}.cat-medic{color:#8ce0b0}"
    html[#html + 1] = ".cat-phone{color:#9cd6ff}.cat-social{color:#ffc48b}.cat-pet{color:#ffb26b}"
    html[#html + 1] = ".cat-map{color:#a2e0c4}.cat-hud{color:#a5d8c8}.cat-event{color:#ff9b9b}"
    html[#html + 1] = ".cat-casino{color:#f0e07a}.cat-media{color:#d8a5ff}.cat-settings{color:#b8c8e0}"
    html[#html + 1] = ".cat-html{color:#8df2a0}.cat-service{color:#7e8ea5}.cat-unknown{color:#8fa3b8}"
    html[#html + 1] = "details{margin-top:2px}pre{background:#15171e;border-radius:4px;padding:6px;white-space:pre-wrap;overflow-x:auto;font-family:Consolas,monospace;font-size:11px;max-height:220px;overflow-y:auto}"
    html[#html + 1] = ".cef-cmd{color:#6fe4a0;font-weight:600}.cef-url{color:#9cd6ff;word-break:break-all}.cef-win{color:#8fa3b8}.cef-keys{color:#b8c8e0}"
    html[#html + 1] = "h2{font-size:16px;color:#ffd45c;margin-top:24px}"
    html[#html + 1] = "</style></head><body>"
    html[#html + 1] = "<h1>CefPacketAnalyzer - таблица пакетов</h1>"
    local sTime = st.startTime or ""
    html[#html + 1] = "<div class=\"meta\">Старт: " .. escHtml(sTime) .. " | Время сбора: " .. os.date("%Y-%m-%d %H:%M:%S") ..
        " | Всего пакетов: " .. st.totalPackets ..
        " | CEF (215): " .. st.totalCef ..
        " | Диалогов (61): " .. st.totalDialog ..
        " | Текстовых: " .. st.totalText ..
        " | Фаза: " .. escHtml(state.phaseName()) .. "</div>"
    html[#html + 1] = "<table><thead><tr><th>№</th><th>Время</th><th>Нпр.</th><th>ID</th><th>Размер</th>" ..
        "<th>Категория</th><th>Событие</th><th>Команда / URL окна</th><th>Что делает / зачем</th><th>Момент</th><th>Анализ</th><th>Тело</th></tr></thead><tbody>"
    html[#html + 1] = table.concat(rows)
    html[#html + 1] = "</tbody></table>"
    html[#html + 1] = buildWindowsSection()
    html[#html + 1] = "</body></html>"
    return table.concat(html, "\n")
end

-- Запись HTML (в CP1251)
local function saveHtml(html)
    local fh = openWrite(tableFile, "w")
    if not fh then return end
    fh:write(toCp1251(html))
    fh:close()
end

-- Запись JSON (в UTF-8)
local function saveJson()
    local st = state.state
    local data = {
        meta = {
            startTime = st.startTime,
            savedAt = os.date("%Y-%m-%d %H:%M:%S"),
            totalPackets = st.totalPackets,
            totalCef = st.totalCef,
            totalDialog = st.totalDialog,
            totalText = st.totalText,
            phase = st.phase,
        },
        records = st.records,
    }
    local fh = openWrite(dataFile, "w")
    if not fh then return end
    local ok, enc = pcall(function()
        local dk = require("dkjson")
        return dk.encode(data, { indent = true })
    end)
    if ok and enc then
        fh:write(enc)
    else
        fh:write("{}")
    end
    fh:close()
end

-- Запись сводки (в UTF-8)
local function saveSummary()
    local st = state.state
    local lines = {}
    lines[#lines + 1] = "CefPacketAnalyzer - сводка по категориям пакетов"
    lines[#lines + 1] = "========================================"
    lines[#lines + 1] = "Сформировано: " .. os.date("%Y-%m-%d %H:%M:%S")
    lines[#lines + 1] = "Старт сессии: " .. tostring(st.startTime)
    lines[#lines + 1] = "Всего пакетов: " .. st.totalPackets ..
        " | CEF (215): " .. st.totalCef ..
        " | Диалогов (61): " .. st.totalDialog ..
        " | Текстовых: " .. st.totalText
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Категория | Кол-во | Первый | Последний | События"
    lines[#lines + 1] = "-------------------------------------------------"
    local cats = {}
    for cat in pairs(st.counters) do
        cats[#cats + 1] = cat
    end
    table.sort(cats)
    local total = 0
    for _, cat in ipairs(cats) do
        local c = st.counters[cat]
        total = total + c.count
        local evList = {}
        for ev, e in pairs(c.events) do
            evList[#evList + 1] = ev .. " x" .. e.count
        end
        table.sort(evList)
        local meta = classify.categoryMeta(cat)
        local title = (meta and meta.title) or cat
        local desc = (meta and meta.desc) or ""
        lines[#lines + 1] = string.format(
            "%-16s | %-6d | %s | %s | %s\n  %s",
            title, c.count, c.first, c.last, table.concat(evList, ", "), desc
        )
    end
    lines[#lines + 1] = "-------------------------------------------------"
    lines[#lines + 1] = "Итого по категориям: " .. total
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Фаза игры на момент сбора: " .. state.phaseName()
    local fh = openWrite(summaryFile, "w")
    if not fh then return end
    fh:write(table.concat(lines, "\n") .. "\n")
    fh:close()
end

-- Итоговая таблица: все типы пакетов без дублей, сгруппированные по категориям.
-- Дубль определяется по ключу "направление|id|каноническая подпись тела".
local function buildUniqueHtml()
    local st = state.state

    -- Дедупликация с сохранением порядка первого появления
    local seen = {}
    local uniq = {}
    local uniqueTotal = 0
    for i = 1, #st.records do
        local rec = st.records[i]
        local key = rec.dedupKey or (rec.dir .. "|" .. tostring(rec.id) .. "|" .. (rec.sig or ""))
        local e = seen[key]
        if not e then
            e = { rec = rec, count = 1, first = rec.dateStr, last = rec.dateStr }
            seen[key] = e
            table.insert(uniq, e)
            uniqueTotal = uniqueTotal + 1
        else
            e.count = e.count + 1
            e.last = rec.dateStr
        end
    end

    -- Группировка по категориям в порядке первого появления
    local catOrder = {}
    local catMap = {}
    for _, e in ipairs(uniq) do
        local cat = e.rec.category or "unknown"
        local group = catMap[cat]
        if not group then
            group = { cat = cat, items = {}, captures = 0 }
            catMap[cat] = group
            table.insert(catOrder, group)
        end
        group.items[#group.items + 1] = e
        group.captures = group.captures + e.count
    end

    -- Сортировка категорий: сначала более массовые, затем остальные; внутри группы - по числу повторов
    table.sort(catOrder, function(a, b)
        return a.captures > b.captures
    end)

    local rows = {}
    local rowNo = 0
    for _, group in ipairs(catOrder) do
        table.sort(group.items, function(a, b)
            return a.count > b.count
        end)
        local meta = classify.categoryMeta(group.cat)
        table.insert(rows, string.format(
            "<tr class=\"grp\"><td colspan=\"10\">%s (%d уникальных типов, %d захвачено) - %s</td></tr>",
            escHtml(meta.title), #group.items, group.captures, escHtml(meta.desc)
        ))
        for _, e in ipairs(group.items) do
            rowNo = rowNo + 1
            local r = e.rec
            local idCell = tostring(r.id)
            if r.pktName and r.pktName ~= "" then
                idCell = r.pktName .. " (" .. tostring(r.id) .. ")"
            end
            local evs = ""
            if r.events and #r.events > 0 then
                evs = table.concat(r.events, ", ")
            end
            local ai = ""
            if r.analysis and #r.analysis > 0 then
                ai = "<ul>"
                for _, a in ipairs(r.analysis) do
                    ai = ai .. "<li>" .. escHtml(a) .. "</li>"
                end
                ai = ai .. "</ul>"
            end
            local body = ""
            if r.text and #r.text > 0 then
                body = "<details class=\"body\"><summary>Пример тела</summary><pre>" .. escHtml(r.text) .. "</pre></details>"
            end
            local whatWhy = escHtml(r.pktIdDesc or "") .. "</td><td>" .. escHtml(r.description or "")
            table.insert(rows, string.format(
                "<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td><td class=\"cnt\">%d</td>" ..
                "<td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>",
                rowNo, idCell, r.dir, escHtml((r.title or "")), e.count,
                e.first .. "<br>последний: " .. e.last,
                escHtml(evs),
                cefCell(r),
                whatWhy,
                ai .. body
            ))
        end
    end

    local html = {}
    html[#html + 1] = "<!DOCTYPE html>"
    html[#html + 1] = "<html><head><meta charset=\"windows-1251\"><title>CefPacketAnalyzer - итоговая таблица (без дублей)</title>"
    html[#html + 1] = "<style>"
    html[#html + 1] = "body{background:#1a1d24;color:#dde3ea;font:13px/1.4 Segoe UI,Arial,sans-serif;margin:16px}"
    html[#html + 1] = "h1{font-size:18px;color:#5ab0ff;margin:0 0 4px}"
    html[#html + 1] = ".meta{color:#8fa3b8;font-size:12px;margin-bottom:12px}"
    html[#html + 1] = "table{border-collapse:collapse;width:100%;background:#20242e}"
    html[#html + 1] = "th,td{border:1px solid #343a48;padding:5px 7px;text-align:left;vertical-align:top;font-size:12px}"
    html[#html + 1] = "th{background:#2c3240;color:#aebcd0;position:sticky;top:0}"
    html[#html + 1] = "td.cnt{white-space:nowrap;font-weight:700;color:#5ab0ff}"
    html[#html + 1] = "tr.grp td{background:#283046;color:#ffd45c;font-weight:700;border-top:2px solid #4a5470}"
    html[#html + 1] = "pre{background:#15171e;border-radius:4px;padding:6px;white-space:pre-wrap;overflow-x:auto;font-family:Consolas,monospace;font-size:11px;max-height:180px;overflow-y:auto}"
    html[#html + 1] = "details{margin-top:2px}"
    html[#html + 1] = ".cef-cmd{color:#6fe4a0;font-weight:600}.cef-url{color:#9cd6ff;word-break:break-all}.cef-win{color:#8fa3b8}.cef-keys{color:#b8c8e0}"
    html[#html + 1] = "h2{font-size:16px;color:#ffd45c;margin-top:24px}"
    html[#html + 1] = "</style></head><body>"
    html[#html + 1] = "<h1>CefPacketAnalyzer - итоговая таблица пакетов</h1>"
    html[#html + 1] = "<div class=\"meta\">Сформировано: " .. os.date("%Y-%m-%d %H:%M:%S") ..
        " | Уникальных типов: " .. uniqueTotal ..
        " | Всего захвачено: " .. st.totalPackets ..
        " | Фаза: " .. escHtml(state.phaseName()) .. "</div>"
    html[#html + 1] = "<table><thead><tr><th>№</th><th>ID</th><th>Напр.</th><th>Описание</th><th>Сколько раз</th>" ..
        "<th>Первое / последнее</th><th>События</th><th>Команда / URL окна</th><th>Что делает / зачем</th><th>Анализ и пример тела</th></tr></thead><tbody>"
    html[#html + 1] = table.concat(rows)
    html[#html + 1] = "</tbody></table>"
    html[#html + 1] = buildWindowsSection()
    html[#html + 1] = "</body></html>"
    return table.concat(html, "\n")
end

-- Запись итоговой таблицы (в CP1251)
local function saveUniqueHtml(html)
    local fh = openWrite(uniqueFile, "w")
    if not fh then return end
    fh:write(toCp1251(html))
    fh:close()
end

-- Безопасная пересборка отчёта: сборка и запись отдельно в pcall, чтобы
-- ошибка в одной секции не убивала скрипт при /cpa save.
local function safeRebuild(buildFn, saveFn)
    local okB, data = pcall(buildFn)
    if okB then
        pcall(saveFn, data)
    else
        state.log("Ошибка сборки отчёта: " .. tostring(data))
    end
end

-- Полная пересборка всех отчётов (не используется в геймплее, оставлено для /cpa save)
function M.regenerate()
    local st = state.state
    if not st.outputDir then return end
    safeRebuild(buildHtml, saveHtml)
    pcall(saveJson)
    pcall(saveSummary)
    safeRebuild(buildUniqueHtml, saveUniqueHtml)
end

-- Полная ротация лог-файлов: закрыть открытые хэндлы и удалить файлы.
-- Данные уже отправлены на сервер, новые файлы создадутся сами при
-- следующих пакетах. Вызывается после успешной отправки агрегата
-- и автомобильной ротацией при превышении лимита размера.
--
-- Предохранитель от спама: сообщение логируется не чаще раза в минуту,
-- а если удалить файл не удалось (занят хэндлом скрипта или внешним
-- процессом) - файл принудительно обнуляется через открытие на запись,
-- чтобы папка output не разрасталась бесконечно.
local lastRotateLogAt = 0
local rotateLogEvery = 60

function M.rotateLogs()
    if not state.state.outputDir then return end
    M.closeStream()
    local okDelAll = true
    local errorDetail = nil
    for _, name in ipairs({ streamFile, tableFile, dataFile, summaryFile, uniqueFile, dataLineFile }) do
        local path = fullPath(name)
        local okDel = pcall(os.remove, path)
        if not okDel then
            -- план Б: обнулить содержимое файла, если удаление заблокировано
            local fh = io.open(path, "w")
            if fh then
                fh:write("")
                fh:close()
                okDel = true
            else
                okDelAll = false
                errorDetail = tostring(name)
            end
        end
    end
    local now = os.time()
    if now >= lastRotateLogAt + rotateLogEvery and (okDelAll or errorDetail) then
        lastRotateLogAt = now
        if okDelAll then
            state.log("Локи подчищены: " .. fullPath("."))
        else
            state.log("Не удалось очистить файл: " .. tostring(errorDetail))
        end
    end
end

-- Очистка файлов отчётов (новый прогон)
function M.clearOutput()
    M.closeStream()
    for _, name in ipairs({ streamFile, tableFile, dataFile, summaryFile, uniqueFile, dataLineFile }) do
        local fh = openWrite(name, "w")
        if fh then
            fh:write("")
            fh:close()
        end
    end
    state.log("Отчёты очищены: " .. fullPath("."))
end

-- Финализация при выгрузке/сохранении
function M.finalize()
    local st = state.state
    if not st.outputDir then return end
    safeRebuild(buildHtml, saveHtml)
    pcall(saveJson)
    pcall(saveSummary)
    safeRebuild(buildUniqueHtml, saveUniqueHtml)
    M.closeStream()
end

return M