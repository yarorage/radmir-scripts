-- Модуль Telegram для MachinistByYaroRage.
--
-- ПОЛНОСТЬЮ НЕБЛОКИРУЮЩИЙ (v0.2.0). Вся сеть выполняется отдельным
-- процессом curl.exe, запускаемым через WinExec (асинхронный запуск без
-- ожидания завершения). Поток SAMP НЕ блокируется HTTPS вообще:
--   * ssl.https/ltn12 НЕ используются (в MoonLoader они выполняются
--     синхронно в корутине на потоке игры и замораживают рендер);
--   * тела запросов пишутся во временный JSON-файл в папке скрипта;
--   * curl выполняет HTTPS сам, один раз, без видимого окна;
--   * ответ getUpdates сохраняется в файл и читается отдельно (async).
--
-- Ограничение: если curl.exe отсутствует (старые Windows), уведомления
-- просто не отправляются — но это НИКОГДА не фризит игру.
local M = {}

local ffi = require "ffi"

-- Папка временных файлов модуля (создаётся при необходимости).
-- getWorkingDirectory() возвращает путь без завершающего "\\" — добавляем его явно,
-- иначе папка склеивается в мусор ("...\moonloaderMachinistByYaroRage\tg_tmp\").
local TG_DIR = getWorkingDirectory():gsub("[\\/]+$", "") .. "\\MachinistByYaroRage\\tg_tmp\\"

-- Проверка наличия curl.exe и объявление WinExec.
local winExecOk = false
do
    local ok_cdef = pcall(function()
        ffi.cdef[[
            unsigned int WinExec(const char* lpCmdLine, int uCmdShow);
        ]]
    end)
    winExecOk = ok_cdef
end

local curlPath = ""
do
    for _, p in ipairs({
        "C:\\Windows\\System32\\curl.exe",
        "C:\\Windows\\SysWOW64\\curl.exe",
        "C:\\Windows\\curl.exe",
    }) do
        if doesFileExist(p) then
            curlPath = p
            break
        end
    end
end

-- Запуск команды в фоне через WinExec. WinExec не ждёт завершения процесса,
-- поэтому поток игры фризится самое большее на миллисекунды создания
-- процесса. Команда выполняется скрыто (uCmdShow=0).
local function runBg(cmdline)
    if not winExecOk then
        print("[MachinistByYaroRage] WinExec недоступен")
        return false
    end
    local ok, code = pcall(function()
        return ffi.C.WinExec(cmdline, 0)
    end)
    if not ok then
        print("[MachinistByYaroRage] Ошибка WinExec: " .. tostring(code))
        return false
    end
    -- код >31 означает успешное создание процесса
    if type(code) == "number" and code > 31 then return true end
    print("[MachinistByYaroRage] Не удалось запустить curl (код " .. tostring(code) .. ")")
    return false
end

-- Извлечение числа из строки (заменяет tonumber для пограничных случаев).
local function num(s)
    local n = tonumber(s)
    if n then return n end
    local m = s:match("%d+")
    if m then return tonumber(m) end
    return nil
end

local function writeUtf8File(path, content)
    local dir = TG_DIR
    if not doesDirectoryExist(dir) then
        pcall(createDirectory, dir)
    end
    local f = io.open(path, "wb")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

-- Отправка сообщения: fire-and-forget через curl.exe. НИКОГДА не ждёт
-- ответа — игра не фризит. Тело JSON записывается в файл (UTF-8), чтобы
-- не пробивать юникод через командную строку.
function M.send(token, chat_id, text)
    if not token or token == "" then return false, "нет токена" end
    if not chat_id or chat_id == "" then return false, "нет чата" end
    if not text or #text == 0 then return false, "пустое сообщение" end
    if curlPath == "" then
        print("[MachinistByYaroRage] curl.exe не найден — Telegram отключён")
        return false, "нет curl"
    end
    local ok_json, dkjson = pcall(require, "dkjson")
    if not ok_json then return false, "dkjson недоступен" end
    local body = dkjson.encode({
        chat_id = chat_id,
        text = text,
        disable_web_page_preview = true,
    })
    local bodyPath = TG_DIR .. "send.json"
    if not writeUtf8File(bodyPath, body) then return false, "нет доступа к tg_tmp" end
    -- Предыдущий ответ curl оставляем для валидации настроек (важно для
    -- диагностики: если в send_resp.json от Telegram API придёт ошибка —
    -- это неправильный токен/chat_id).
    local respPath = TG_DIR .. "send_resp.json"
    local url = "https://api.telegram.org/bot" .. token .. "/sendMessage"
    -- curl в фоне: -s тихо, -m 10 максимум 10 сек, окно скрыто.
    -- -o сохраняет ответ API в send_resp.json (см. выше).
    local cmdline = '"' .. curlPath .. '" -s -m 10 -X POST "' .. url ..
        '" -H "Content-Type: application/json" --data-binary "@' .. bodyPath ..
        '" -o "' .. respPath .. '"'
    runBg(cmdline)
    return true
end

-- Алиас: полная асинхронность из коробки (на самом деле send уже async).
function M.send_async(token, chat_id, text)
    return M.send(token, chat_id, text)
end

-- Опрос апдейтов (fire-and-forget): запускает в фоне getUpdates, ответ
-- curl сохраняет в tg_updates.json. Возвращает ЗАПИСАННЫЙ ранее ответ
-- (чтобы команды обрабатывались без блокировки). Сразу возвращает nil,
-- реальный результат подтягивается следующим вызовом read_updates().
function M.get_updates(token, offset)
    if not token or token == "" then return nil end
    if curlPath == "" then return nil end
    local url = "https://api.telegram.org/bot" .. token .. "/getUpdates" ..
        "?timeout=0&offset=" .. tostring(offset or 0) .. "&limit=10"
    local outPath = TG_DIR .. "updates.json"
    local cmdline = '"' .. curlPath .. '" -s -m 10 -o "' .. outPath ..
        '" "' .. url .. '"'
    runBg(cmdline)
    return nil
end

-- Чтение последнего сохранённого ответа getUpdates. Вызывается отдельно,
-- без сети: только локальное чтение файла (мгновенно, без фризов).
function M.read_updates()
    local path = TG_DIR .. "updates.json"
    local f = io.open(path, "rb")
    if not f then return nil end
    local body = f:read("*a")
    f:close()
    if not body or #body == 0 then return nil end
    local ok_json, dkjson = pcall(require, "dkjson")
    if not ok_json then return nil end
    local ok_dec, data = pcall(dkjson.decode, body)
    if not ok_dec or type(data) ~= "table" or not data.result then return nil end
    return data.result
end

-- Полная очистка последних команд перед следующим запуском (по желанию).
function M.clear_response()
    os.remove(TG_DIR .. "updates.json")
end

return M