-- Модуль состояния и конфигурации MachinistByYaroRage.
-- Хранит настройки в INI-файле в папке скрипта: MachinistByYaroRage\config\MachinistByYaroRage.ini.
-- Список админов дополнительно читается из MachinistByYaroRage\config\CheatAdminList.txt.
local M = {}

M.script_name = "MachinistByYaroRage"
M.version = "0.9.6"

-- getWorkingDirectory() возвращает путь БЕЗ завершающего разделителя
-- (например, "...\moonloader"), поэтому добавляем "\\" явно — иначе пути
-- склеиваются в мусор ("...\moonloaderMachinistByYaroRage\config\").
local WD = getWorkingDirectory():gsub("[\\/]+$", "") .. "\\"
local CONFIG_DIR = WD .. "MachinistByYaroRage\\config\\"
local CONFIG_FILE = CONFIG_DIR .. "MachinistByYaroRage.ini"
local ADMIN_FILE = CONFIG_DIR .. "CheatAdminList.txt"

-- Состояние бота (фазовый автомат):
-- 'IDLE' — ожидание
-- 'DRIVE' — ведение поезда по рекомендациям сервера
-- 'STOP' — остановка на станции
-- 'DISABLED' — выключен
M.state = {
    enabled = true,           -- глобальный вкл/выкл бота
    force_cab = false,        -- принудительно считать, что мы в кабине (v0.6.1):
                              -- автопилот включается, даже если CEF-пакеты
                              -- интерфейса 'Machinist' не приходят
    auto_drive = true,        -- автоведение W/S по setSpeed
    notify_telegram = true,   -- отправлять уведомления в телеграм
    tg_bot_token = "",
    tg_chat_id = "",
    admin_names = "", -- ДОПОЛНИТЕЛЬНЫЙ ручной список админов (GUI, через запятую).
                      -- Основной список скачивается из config\CheatAdminList.txt.
    tap_interval = 0.45,      -- интервал импульсов клавиши W/S (сек)
    stop_dist = 25,           -- дистанция начала торможения (метры)
    keep_speed = true,        -- держать скорость в вилке setSpeed при коде 1
    speed_hysteresis = 3,     -- гистерезис вилки скорости (км/ч)
    stop_speed = 0.6,         -- порог скорости «поезд стоит» (м/с)
    overspeed = false,        -- режим «Превышать скорость»: ехать выше вилки,
                              -- но успеть сбросить скорость до штрафа
    overspeed_extra = 25,      -- на сколько км/ч выше верхней границы вилки ехать
    overspeed_guard = 1,      -- за сколько секунд до конца таймера штрафа вернуться в вилку
    station_stop_radius = 15, -- v0.8.1: радиус «прибытия на станцию» (метры)
    station_dwell = 5,        -- v0.8.1: секунды стоянки перед отправлением
    brake_decel = 2.0,          -- v0.8.2: замедление состава при торможении (м/с^2)
    brake_margin = 6,           -- v0.8.2: запас к тормозному пути (метры)
    stop_overshoot = 50,        -- v0.9.7: сколько МЕТРОВ проехать ЗА стоп-точкой
                                --        станции (докрутка до серверного триггера)
    stop_crawl = 10,            -- v0.9.7: скорость докрутки за стоп-точку (км/ч)
    need_go = false,          -- v0.8.1: сервер требует движения («Увеличьте скорость»)

    phase = "IDLE",
    arrived_at = 0,           -- момент, когда поезд остановился

    -- текущие данные от сервера (обновляются из RX 215)
    semaphores = {0, 0, 0, 0}, -- семафоры станций [1,1,1,1] / [0,0,0,0]
    speed_range = "0-0",      -- рекомендуемый диапазон скорости "54-63"
    speed_lo = 0,             -- нижняя граница вилки скорости (км/ч)
    speed_hi = 0,             -- верхняя граница вилки скорости (км/ч)
    speed_code = 1,           -- 0 увеличить, 1 ок, 2 снизить
    station_name = "",
    station_dist = -1,        -- дистанция до станции (метры)
    money = 0,
    last_dist = -1,
    last_dist_time = 0,
    speed_est = 0,            -- оценка скорости (м/с) по убыванию дистанции
    speed_est_at = 0,         -- v0.9.6: WallClock последней оценки (мс), затухание 2.5 с
    use_game_speed = false,   -- НЕ используется (v0.5.7): нативный getCarSpeed
                              -- давал фриз ~1 сек на этом движке; скорость всегда
                              -- берётся из оценки по дистанции. Поле оставлено для
                              -- совместимости со старыми конфигами.

    -- имитация поведения живого человека (v0.2.3):
    --   * реакция на смену команд сервера со случайной задержкой;
    --   * разброс интервалов между нажатиями (human_jitter, % от tap_interval);
    --   * широкий мёртвый допуск удержания скорости (киестерезис колеблется);
    --   * редкие осечки (пропуск нажатия) и лёгкие корректировки.
    humanize = true,          -- вкл/выкл имитацию человека
    human_reaction = 350,     -- базовая задержка реакции на смену команды (мс)
    human_jitter = 25,        -- разброс интервала нажатий в процентах (0-50)

    info_timer = "",
    info_timer_sec = nil,     -- секунды из InformationTimer (для штрафа превышения)
    info_timer_until = 0,     -- v0.9.6: unix-момент окончания info_timer (0 = нет)
    overspeed_fine = false,   -- сервер запустил таймер штрафа за превышение
    overspeed_timer = 0,      -- unix-момент окончания таймера штрафа (0 = нет)
    last_rx_text = "",

    -- метки времени для оценки скорости (WallClock, миллисекунды)
    last_dist_ms = 0,

    -- контроль присутствия в кабине машиниста.
    -- Кабина определяется ТОЛЬКО по свежим RX-пакетам интерфейса 'Machinist'
    -- (setSpeed / setSemaphoreState — приходят каждые 1-2 сек, пока интерфейс
    -- открыт). Нативный isCharInAnyCar() убран в v0.5.9: на установленном
    -- MoonRage.dll v0.0.29 его вызов вешает SAMP-поток на ~1.2 сек.
    in_cab = false,           -- определена по CEF-пакетам интерфейса 'Machinist'
    last_pkt_time = 0,        -- os.time() последнего пакета интерфейса
    cab_timeout = 8,        -- кол-во сек без пакетов, считаем, что вышли из кабины

    -- Диагностические флаги бисекции лага (v0.0.8+):
    -- каждый снимает нагрузку с конкретного слоя скрипта, чтобы по
    -- экспериментам пользователя найти источник D3D-фриза (игра рисует
    -- ~0.2 кадра/с при загруженном скрипте, хотя onReceivePacket почти пуст).
    --   dbg_no_thread = 1 — не создавать поток автопилота (driveThread)
    --   dbg_no_events = 1 — выключить разбор CEF-пакетов (onReceivePacket)
    --   dbg_no_gui    = 1 — не трогать imgui (хук OnDrawFrame/Process/ShowCursor)
    --   dbg_no_chat   = 1 — не показывать приветственные сообщения в чате
    --   dbg_log       = 1 — печатать TX215 на каждый пакет и сводки RX215/main
    --                        каждые 5 сек (шумно, включать только для диагностики)
    dbg_no_thread = false,
    dbg_no_events = false,
    dbg_no_gui = false,
    dbg_no_chat = false,
    dbg_log = false,

    -- Опрос Telegram-команд (getUpdates). По умолчанию ВКЛЮЧЕН (tg_poll_enable=1):
    -- каждый вызов сетевая работа ssl.https выполняется синхронно в потоке
    -- SAMP и на время запроса (до timeout 2 сек) замораживает игру. Выключать
    -- из GUI (вкладка «Телеграм и админы», чекбокс «Опрос Telegram»), если
    -- управление автопилотом из Telegram не нужно (tg_poll_enable = 0).
    tg_poll_enable = true,
}

local function save_config()
    local ok, err = pcall(function()
        if not doesDirectoryExist(CONFIG_DIR) then createDirectory(CONFIG_DIR) end
        local f = io.open(CONFIG_FILE, "w")
        if not f then return end
        local s = M.state
        f:write("[MachinistByYaroRage]\n")
        f:write("enabled=" .. (s.enabled and "1" or "0") .. "\n")
        f:write("force_cab=" .. (s.force_cab and "1" or "0") .. "\n")
        f:write("auto_drive=" .. (s.auto_drive and "1" or "0") .. "\n")
        f:write("notify_telegram=" .. (s.notify_telegram and "1" or "0") .. "\n")
        f:write("tg_bot_token=" .. s.tg_bot_token .. "\n")
        f:write("tg_chat_id=" .. s.tg_chat_id .. "\n")
        f:write("tap_interval=" .. tostring(s.tap_interval) .. "\n")
        f:write("stop_dist=" .. tostring(s.stop_dist) .. "\n")
        f:write("keep_speed=" .. (s.keep_speed and "1" or "0") .. "\n")
        f:write("use_game_speed=" .. (s.use_game_speed and "1" or "0") .. "\n")
        f:write("humanize=" .. (s.humanize and "1" or "0") .. "\n")
        f:write("human_reaction=" .. tostring(s.human_reaction) .. "\n")
        f:write("human_jitter=" .. tostring(s.human_jitter) .. "\n")
        f:write("speed_hysteresis=" .. tostring(s.speed_hysteresis) .. "\n")
        f:write("stop_speed=" .. tostring(s.stop_speed) .. "\n")
        f:write("overspeed=" .. (s.overspeed and "1" or "0") .. "\n")
        f:write("overspeed_extra=" .. tostring(s.overspeed_extra) .. "\n")
        f:write("overspeed_guard=" .. tostring(s.overspeed_guard) .. "\n")
        f:write("stop_overshoot=" .. tostring(s.stop_overshoot) .. "\n")
        f:write("stop_crawl=" .. tostring(s.stop_crawl) .. "\n")
        f:write("dbg_no_thread=" .. (s.dbg_no_thread and "1" or "0") .. "\n")
        f:write("dbg_no_events=" .. (s.dbg_no_events and "1" or "0") .. "\n")
        f:write("dbg_no_gui=" .. (s.dbg_no_gui and "1" or "0") .. "\n")
        f:write("dbg_no_chat=" .. (s.dbg_no_chat and "1" or "0") .. "\n")
f:write("dbg_log=" .. (s.dbg_log and "1" or "0") .. "\n")
        f:write("tg_poll_enable=" .. (s.tg_poll_enable and "1" or "0") .. "\n")
        f:close()
    end)
    if not ok then
        print("[" .. M.script_name .. "] Ошибка сохранения конфига: " .. tostring(err))
    end
end

M.save_config = save_config

local function line_value(line)
    -- Возвращаем ЗНАЧЕНИЕ (вторую группу), а не имя ключа: у string.find
    -- третьим возвратом идёт ПЕРВАЯ группа ([^=]+), т.е. ключ — из-за этого
    -- в конфиг попадало "tg_bot_token" вместо токена после перезагрузки.
    local _, _, _, v = line:find("^([^=]+)=(.*)$")
    return v
end

local function load_config()
    local ok, err = pcall(function()
        local f = io.open(CONFIG_FILE, "r")
        if not f then return end
        local s = M.state
        for line in f:lines() do
            line = line:gsub("\r", "")
            local v = line_value(line)
            if v ~= nil then
                v = v:gsub("\r", "")
                local k = line:lower()
                if k:find("^enabled") then s.enabled = v == "1"
                elseif k:find("^force_cab") then s.force_cab = v == "1"
                elseif k:find("^auto_drive") then s.auto_drive = v == "1"
                elseif k:find("^notify_telegram") then s.notify_telegram = v == "1"
                elseif k:find("^tg_bot_token") then s.tg_bot_token = v
                elseif k:find("^tg_chat_id") then s.tg_chat_id = v
                elseif k:find("^tap_interval") then s.tap_interval = tonumber(v) or 0.45
                elseif k:find("^stop_dist") then s.stop_dist = tonumber(v) or 25
                elseif k:find("^stop_overshoot") then s.stop_overshoot = tonumber(v) or 50
                elseif k:find("^stop_crawl") then s.stop_crawl = tonumber(v) or 10
                elseif k:find("^keep_speed") then s.keep_speed = v == "1"
                elseif k:find("^use_game_speed") then s.use_game_speed = v == "1"
                elseif k:find("^humanize") then s.humanize = v == "1"
                elseif k:find("^human_reaction") then s.human_reaction = tonumber(v) or 350
                elseif k:find("^human_jitter") then s.human_jitter = tonumber(v) or 25
                elseif k:find("^speed_hysteresis") then s.speed_hysteresis = tonumber(v) or 3
                elseif k:find("^overspeed_guard") then s.overspeed_guard = tonumber(v) or 1
                elseif k:find("^overspeed_extra") then s.overspeed_extra = tonumber(v) or 8
                elseif k:find("^overspeed") then s.overspeed = v == "1"
                elseif k:find("^stop_speed") then s.stop_speed = tonumber(v) or 0.6
                elseif k:find("^dbg_no_thread") then s.dbg_no_thread = v == "1"
                elseif k:find("^dbg_no_events") then s.dbg_no_events = v == "1"
                elseif k:find("^dbg_no_gui") then s.dbg_no_gui = v == "1"
                elseif k:find("^dbg_no_chat") then s.dbg_no_chat = v == "1"
                elseif k:find("^dbg_log") then s.dbg_log = v == "1"
                elseif k:find("^tg_poll_enable") then s.tg_poll_enable = v == "1"
                end
            end
        end
        f:close()
    end)
    if not ok then
        print("[" .. M.script_name .. "] Ошибка загрузки конфига: " .. tostring(err))
    end

    -- Fallback: настройки ТГ из AutoLoginByYaroRage, если в своём конфиге пусто.
    -- Это позволяет не дублировать токен/чат в двух скриптах.
    -- Проверяем оба варианта: правильный путь и старый «мусорный» (без разделителя),
    -- на случай если AutoLogin ещё писал настройки со старым багом конкатенации.
    local s = M.state
    if s.tg_bot_token == "" or s.tg_chat_id == "" then
        local bases = {
            WD .. "AutoLoginByYaroRage",
            getWorkingDirectory() .. "AutoLoginByYaroRage",
        }
        for _, base in ipairs(bases) do
            local al_cfg = base .. "\\config\\AutoLoginSettings.ini"
            local f2 = io.open(al_cfg, "r")
            if f2 then
                for line in f2:lines() do
                    line = line:gsub("\r", ""):gsub('"', "")
                    local k, v = line:match("^(%w+)%s*=%s*(.*)$")
                    if k == "TelegramBotToken" and s.tg_bot_token == "" then
                        s.tg_bot_token = v
                    elseif k == "TelegramChatId" and s.tg_chat_id == "" then
                        s.tg_chat_id = v
                    end
                end
                f2:close()
            end
            if s.tg_bot_token ~= "" and s.tg_chat_id ~= "" then break end
        end
    end
end

M.load_config = load_config

-- Пути к файлам конфигурации (для других модулей, например admin.lua).
M.config_dir = CONFIG_DIR
M.config_file = CONFIG_FILE
M.admin_file = ADMIN_FILE

-- Дописывает в config\CheatAdminList.txt ники, которых там ещё нет
-- (список берётся из GUI-поля «Админы» — через запятую).
function M.append_admin_names(commaList)
    if not commaList or #commaList == 0 then return end
    local add = {}
    for name in commaList:gmatch("[^,;]+") do
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        if #name > 0 then add[#add + 1] = name end
    end
    if #add == 0 then return end
    local f = io.open(ADMIN_FILE, "rb")
    local existing = ""
    if f then existing = f:read("*a"); f:close() end
    local existingLower = existing:lower()
    local out = existing
    local appended = false
    for _, name in ipairs(add) do
        if not existingLower:find(name:lower(), 1, true) then
            if #out > 0 and not out:match("\r?\n$") then out = out .. "\n" end
            out = out .. name .. "\n"
            appended = true
        end
    end
    if appended then
        local ok_w, err_w = pcall(function()
            if not doesDirectoryExist(CONFIG_DIR) then createDirectory(CONFIG_DIR) end
local fw = io.open(ADMIN_FILE, "wb")
                if fw then fw:write(out); fw:close() end
        end)
        if not ok_w then print("[" .. M.script_name .. "] Ошибка записи CheatAdminList.txt: " .. tostring(err_w)) end
    end
end

-- Уведомление в телеграме о действии бота.
-- Полностью асинхронно: отправка выполняется фоновым curl.exe (WinExec),
-- поток SAMP не блокируется сетью (никакого ssl.https в Lua).
function M.tg(text)
    if not M.state.notify_telegram then return end
    if M.state.tg_bot_token == "" or M.state.tg_chat_id == "" then return end
    local ok_tg, telegram = pcall(require, "MachinistByYaroRage.telegram")
    if ok_tg and telegram then
        local ok_send, err = telegram.send_async(M.state.tg_bot_token, M.state.tg_chat_id, text)
        -- локальная ошибка запуска (нет curl/токена/доступа к файлу) обязана
        -- попасть в лог — раньше такие отказы молча терялись.
        if ok_send == false then
            print("[MachinistByYaroRage] Telegram не отправлен: " .. tostring(err))
        end
    else
        print("[MachinistByYaroRage] Модуль telegram недоступен")
    end
end

-- Сброс игрового состояния при выходе из машиниста
-- Удаление ника админа: из файла CheatAdminList.txt и из ручного списка
-- admin_names (INI). Используется кнопкой-крестиком в GUI.
function M.remove_admin_name(nick)
    if not nick or #nick == 0 then return end
    nick = nick:gsub("^%s+", ""):gsub("%s+$", "")
    local target = nick:lower()
    local s = M.state

    -- Убрать из ручного списка (admin_names через запятую/точку с запятой) в INI.
    if s.admin_names and #s.admin_names > 0 then
        local keep = {}
        for n in s.admin_names:gmatch("[^,;]+") do
            n = n:gsub("^%s+", ""):gsub("%s+$", "")
            if #n > 0 and n:lower() ~= target then keep[#keep + 1] = n end
        end
        s.admin_names = table.concat(keep, ",")
    end

    -- Переписать файл без строк, где первое слово совпадает с ником.
    local f = io.open(ADMIN_FILE, "rb")
    if not f then return end
    local data = f:read("*a")
    f:close()
    local out = {}
    for line in data:gmatch("[^\r\n]+") do
        local first = line:match("^%s*([^%s|,;]+)")
        if first and first:lower() ~= target then out[#out + 1] = line end
    end
    if #out > 0 then
        local ok_w, err_w = pcall(function()
            if not doesDirectoryExist(CONFIG_DIR) then createDirectory(CONFIG_DIR) end
            local fw = io.open(ADMIN_FILE, "wb")
            if fw then fw:write(table.concat(out, "\r\n") .. "\r\n"); fw:close() end
        end)
        if not ok_w then print("[" .. M.script_name .. "] Ошибка записи CheatAdminList.txt: " .. tostring(err_w)) end
    else
        local ok_w, err_w = pcall(function()
            local fw = io.open(ADMIN_FILE, "wb")
            if fw then fw:write(""); fw:close() end
        end)
        if not ok_w then print("[" .. M.script_name .. "] Ошибка очистки CheatAdminList.txt: " .. tostring(err_w)) end
    end
end

function M.reset()
    local s = M.state
    s.phase = "IDLE"
    s.in_cab = false
    s.info_timer = ""
    s.info_timer_sec = nil
    s.info_timer_until = 0
    s.overspeed_fine = false
    s.overspeed_timer = 0
    s.need_go = false
    s.semaphores = {0, 0, 0, 0}
    s.speed_range = "0-0"
    s.speed_lo = 0
    s.speed_hi = 0
    s.speed_code = 1
    s.station_name = ""
    s.station_dist = -1
    s.last_dist = -1
    s.last_dist_ms = 0
    s.speed_est = 0
    s.speed_est_at = 0
end

return M