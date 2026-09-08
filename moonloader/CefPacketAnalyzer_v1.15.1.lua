-- CefPacketAnalyzer v1.15.1
-- Анализатор CEF-пакетов Radmir CRMP.
-- Перехватывает RakNet-пакеты (в первую очередь id=215 - команды интерфейса,
-- id=61 - диалоги) и текстовые потоки, классифицирует их по базе знаний
-- интерфейса Радмира, определяет момент возникновения (фаза игры) и формирует
-- отчёты в папке на один уровень выше папки с игрой: <родитель>\CefPacketAnalyzer\output:
--   packets_stream.txt  - поток всех пакетов (append)
--   packets_table.html  - таблица пакетов с анализом (CP1251)
--   packets_data.json   - все записи текущего прогона (UTF-8)
--   packets_summary.txt - сводка по категориям (UTF-8)
--   packets_unique_table.html - итоговая таблица без дублей, сгруппированная по категориям (CP1251)
-- Команды: /cpa, /cpa save, /cpa clear, /cpa log on|off, /cpa len N, /cpa status.
script_name("CefPacketAnalyzer")
script_version("1.15.1")

require "moonloader"
require "lib.samp.events"

local state   = require("CefPacketAnalyzer.state")
local capture = require("CefPacketAnalyzer.capture")
local output  = require("CefPacketAnalyzer.output")
local upload  = require("CefPacketAnalyzer.upload")

-- Автоматический режим: каждая захваченная запись сразу дописывается
-- в поток-лог и в JSON-lines (переживают даже жёсткий краш игры).
capture.setEmit(function(rec)
    if state.state.enabled then
        pcall(output.appendStream, rec)
        pcall(output.appendData, rec)
    end
end)

-- ---------- Настройка папки отчётов ----------
-- По умолчанию отчёты кладутся на один уровень выше папки с игрой,
-- в отдельную папку CefPacketAnalyzer\output (можно отключить в state.lua).
-- getWorkingDirectory() в MoonLoader возвращает папку moonloader,
-- поэтому корень игры берём из getGameDirectory().
local function parentDirectory(path)
    path = tostring(path):gsub("[\\/]+$", "")
    local parent = path:match("^(.*)[\\/][^\\/]+$")
    return parent or path
end

local function gameRootDirectory()
    local ok, gameDir = pcall(getGameDirectory)
    if ok and gameDir and tostring(gameDir) ~= "" then
        return tostring(gameDir)
    end
    -- если getGameDirectory недоступен - поднимаемся на два уровня от папки moonloader
    local wd = getWorkingDirectory() and getWorkingDirectory() or (os.getenv("TEMP") or "C:\\")
    return parentDirectory(wd) or wd
end

local function setupOutputDir()
    local base = gameRootDirectory()
    if state.state.outputOneLevelAbove then
        base = parentDirectory(base) or base
    end
    local dir = base .. "\\CefPacketAnalyzer\\output"
    local ok = pcall(createDirectory, dir)
    if not ok then
        -- пробуем создать родительскую папку первым
        pcall(createDirectory, base .. "\\CefPacketAnalyzer")
        pcall(createDirectory, dir)
    end
    if doesDirectoryExist and doesDirectoryExist(dir) then
        state.state.outputDir = dir
    else
        state.state.outputDir = base .. "\\CefPacketAnalyzer"
        pcall(createDirectory, state.state.outputDir)
    end
    state.state.startTime = os.date("%Y-%m-%d %H:%M:%S")
    state.log("Папка отчётов: " .. state.state.outputDir)
end

-- ---------- Команды ----------
local function printHelp()
    state.chat("команды: /cpa save|clear|log on|off|len <N>|status|upload on|off|now|url <адрес>|on|off")
end

local function onCommand(param)
    local raw = tostring(param or "")
    local p = raw:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if p == "" or p == "help" then
        printHelp()
    elseif p == "save" then
        output.finalize()
        state.chat("Отчёты перезаписаны.")
    elseif p == "clear" or p == "new" then
        state.resetSession()
        output.clearOutput()
        upload.reset()
        state.state.startTime = os.date("%Y-%m-%d %H:%M:%S")
        state.chat("Сессия сбора очищена. Начну собирать заново.")
    elseif p == "log on" or p == "on" then
        state.state.enabled = true
        state.chat("Сбор включён. Все пакеты пишутся в поток автоматически.")
    elseif p == "log off" or p == "off" then
        state.state.enabled = false
        state.chat("Сбор выключен. Поток больше не дописывается.")
    elseif p == "log" then
        state.chat("Автозапись потока всегда включена во время сбора.")
    elseif p:match("^len%s+[%d]+$") then
        local n = tonumber(p:match("len%s+(%d+)"))
        state.state.maxBodyLen = n
        state.chat("Максимальный размер тела пакета: " .. n .. " байт.")
    elseif p == "status" then
        local st = state.state
        state.chat(string.format(
            "статус: %s | пакетов: %d | CEF: %d | диалогов: %d | текстовых: %d | фаза: %s",
            st.enabled and "вкл" or "выкл",
            st.totalPackets, st.totalCef, st.totalDialog, st.totalText,
            st.phase
        ))
    elseif p == "upload" or p == "upload on" then
        state.state.uploadEnabled = true
        state.chat(upload.statusText())
    elseif p == "upload off" then
        state.state.uploadEnabled = false
        state.chat("Отправка агрегатов выключена.")
    elseif p == "upload now" then
        local okSend, detail = upload.force()
        local st = state.state
        if okSend then
            if st.backgroundUpload == false then
                state.chat("Агрегат отправлен.")
            else
                state.chat("Агрегат сохранён для фоновой отправки (сборщик подхватит).")
            end
        else
            state.chat("Сохранить агрегат не удалось: " .. (detail or "неизвестная причина"))
        end
    elseif p:match("^upload%s+url%s+") then
        local url = raw:gsub("^%s*[Uu][Pp][Ll][Oo][Aa][Dd]%s+[Uu][Rr][Ll]%s+", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if url ~= "" then
            state.state.uploadUrl = url
            state.chat("Адрес вебхука задан. Отправка активна.")
        else
            state.chat("Нужен адрес: /cpa upload url <https://script.google.com/...>")
        end
    else
        printHelp()
    end
end

-- ---------- Команды ----------
local function registerCommands()
    if isSampfuncsLoaded and isSampfuncsLoaded() and sampRegisterChatCommand then
        sampRegisterChatCommand("cpa", onCommand)
    end
end

-- ---------- События lib.samp.events ----------
function onReceivePacket(id, bs)
    capture.onReceivePacket(id, bs)
end

function onSendPacket(id, bs)
    capture.onSendPacket(id, bs)
end

function onServerMessage(color, textMsg)
    capture.onServerMessage(color, textMsg)
end

function onGameText(textMsg, time, style)
    capture.onGameText(textMsg, time, style)
end

function onDisconnect(reason)
    state.state.connected = false
    state.state.phase = "idle"
    state.state.cursorOn = false
    pcall(output.finalize)
end

function onShowDialog(dialogId, styleId, title, button1, button2, textBox)
    capture.onCaptureMsg("[Диалог id=" .. tostring(dialogId) .. "] " .. tostring(title) .. " | " .. tostring(textBox))
end

-- ---------- Главный цикл ----------
function main()
    setupOutputDir()
    registerCommands()
    state.state.startTime = os.date("%Y-%m-%d %H:%M:%S")
    state.log("CefPacketAnalyzer v1.15.1 запущен. Команды: /cpa")

    -- В геймплее тяжёлые отчёты НЕ пересобираются (чтобы не лагать).
    -- Поток packets_stream.txt дописывается автоматически вживую,
    -- а полные отчёты — по /cpa save, при отключении и при выгрузке скрипта.
    while true do
        wait(0)
        -- редкая отправка агрегатов на сервер (троттлинг внутри upload)
        upload.tick()
    end
end

-- Финализация при выгрузке/перезагрузке скрипта.
-- ВАЖНО: полные отчёты при выходе НЕ пересобираются (buildHtml/unique/JSON
-- уже дописаны вживую на каждый пакет; пересборка в кадре на Ctrl+R и была
-- источником фриза). Только аккуратно закрываем потоки — это мгновенно.
function onScriptExit()
    pcall(output.closeStream)
end