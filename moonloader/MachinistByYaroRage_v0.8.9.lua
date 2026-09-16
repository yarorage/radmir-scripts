-- MachinistByYaroRage v0.8.0
-- Автопилот машиниста метро (Radmir CRMP).
-- Персонаж уже сидит в поезде и НЕ выходит: смены идут кругами
-- (Союзная <-> Больничная), автопилот только ведёт состав.
-- Управление идёт НАТИВНО по полной логике рабочего mashinist.lua (порт всего
-- ведущего цикла): газ = setGameKeyState(16,255), тормоз = setGameKeyState(14,255)
-- + writeMemory(0xB73458+0x1C), точная остановка = setTrainSpeed(car, spd/1.1-1),
-- а направление считается по знаку реальной скорости (getCarSpeed) и пишется в
-- keysData исходящего vehicle sync (0x08 accel вперёд / 0x20 decel назад / 0 стоп).
-- Гейт всего блока — нативный isCharInAnyTrain(PLAYER_PED): вне поезда скрипт
-- НЕ трогает ни клавиши, ни keysData (иначе в обычном авто не заводился двигатель).
-- CEF-команда OnPlayerClientSideKey на Radmir не двигает поезд, поэтому не
-- используется. Работает при свёрнутой игре (клавиши пишутся в память напрямую).
--
-- Проверено по дампам CEF-пакетов (00:48..00:54 14.09.2026):
--   - интерфейс 'Machinist' шлёт setSemaphoreState / setStation / setSpeed;
--   - цикл: semaphores [0,0,0,0] = стоим на станции (dist ~5..17), затем [1,1,1,1] = можно ехать;
--   - speed: code 0 = разгоняйся (W), 2 = снижай (S), 1 = держи (нейтраль);
--     вилка setSpeed ("54-63") — разрешённые км/ч на участке, при коде 1 бот
--     сам подруливает W/S, чтобы удержать скорость в вилке (штрафы за выход);
--   - диалога «Работа машиниста» и OnDialogResponse в сессии НЕТ — персонаж в поезде;
--   - setMoney растёт на 8125 за станцию — смена идёт сама по кругу.
--
-- Команды: /mq — меню, /mqstart — старт, /mqstop — стоп, /mqtg — тест телеграма, /mqadmins — список админов, /mqdiag — диагностика CEF-чата.
--
-- v0.6.0 — ЧИСТАЯ КОНСОЛЬ: диагностическая печать управляется флагом dbg_log.
-- Шумные print-ы (TX215 на каждый исходящий пакет, сводки RX215 раз в 5 сек,
-- main-сводка с wall-gap раз в 5 сек) были добавлены для бисекции фризов и
-- больше не нужны — теперь печатаются только при dbg_log=1 в config.ini.
-- События уровня «админ в чате»/«открылось окно» и ошибки остаются всегда.
-- В config.ini (MachinistByYaroRage\config\MachinistByYaroRage.ini) добавлен
-- параметр dbg_log: =1 — телеметрия движка (packets/тики), =0/отсутствует —
-- тихая работа.
-- v0.6.7 — ДИАГНОСТИКА СКОРОСТИ И НАВЕЧНЫЙ КЭШ НИКОВ.
-- 1) MACH: мини-дамп Machinist-состояния в moonloader.log каждые 5 сек
--    ВСЕГДА (без dbg_log): lo/hi/mid скорости, станция, семафоры, текст
--    последнего RX-пакета. Нужно, чтобы понять почему бот держит 40 км/ч
--    вместо вилки setSpeed (подозрение: вилка не доезжает до driveThread).
-- 2) knownIdNick: кэш «id игрока -> ник» из голосового чата теперь НЕ
--    сбрасывается при removeVoiceChatEntry — один раз услышав админа,
--    распознаём его по CEF-пузырям даже когда он не в голосовом канале.
--    Заодно кэш добавляется и при addVoiceChatEntry (и раньше).
-- 3) dbg_log начал сохраняться в config.ini (save_config его затирал).
-- v0.6.6 — ПОЛНЫЙ ПОРТ ВЕДУЩЕГО ЦИКЛА ИЗ mashinist.lua.
-- В v0.6.5 движение поезда не работало: он не ехал. Причина — цикл с интервалом
-- 150 мс и управление «по оценке» (st.speed_est = вывод дистанции setStation).
-- Рабочий mashinist.lua ведёт поезд по-другому, и теперь вся его логика
-- перенесена в наш скрипт вместо прежней:
--   - цикл КАЖДЫЙ кадр (wait(0)), а не раз в 150 мс;
--   - реальная скорость из getCarSpeed(локомотив)*3.67, а не из дистанции;
--   - газ = setGameKeyState(16,255), пока скорость ниже середины вилки setSpeed
--     (как в эталоне; writeMemory на газ НЕ нужен);
--   - тормоз = setGameKeyState(14,255) + writeMemory(0xB73458+0x1C,1,255,false);
--   - точная остановка = setTrainSpeed(car, max(0, spd/1.1-1));
--   - дистанция цели = чекпоинт сервера (onSetRaceCheckpoint), иначе st.station_dist;
--   - прогноз остановки stopDistance = distance - ((speed/35)*last_distance)/1.2;
--   - keysData по ЗНАКУ реальной скорости: >0 -> 0x08 (accel), <0 -> 0x20 (decel),
--     0 -> 0; как в mashinist.lua (это критично — состав едет, когда в sync виден accel).
-- ПУСК ДВИГАТЕЛЯ В ОБЫЧНОМ АВТО ПОЧИНЕН: гейт всего блока — нативный
-- isCharInAnyTrain(PLAYER_PED). Вне поезда скрипт не трогает ни клавиши, ни
-- keysData, поэтому W для старта двигателя больше не блокируется.
-- Убрана мёртвая функция isBlocked() и неиспользуемые опции вкладки «Ведение».
-- v0.6.5 — НАТИВНОЕ УПРАВЛЕНИЕ ПОЕЗДОМ (из mashinist.lua).
-- CEF-команда OnPlayerClientSideKey на Radmir НЕ двигает поезд (поэтому
-- cef.send_key_w/s убраны из водительского цикла). Движение поезда идёт так,
-- как делает рабочий mashinist.lua:
-- CEF-команда OnPlayerClientSideKey на Radmir НЕ двигает поезд (поэтому
-- cef.send_key_w/s убраны из водительского цикла). Движение поезда идёт так,
-- как делает рабочий mashinist.lua:
--   1) нажатия газ/тормоз — writeMemory(0xB73458+0x20/+0x1C, 1, 255, false)
--      + setGameKeyState(16/14) на кадр;
--   2) направление движения сервер читает из keysData исходящего vehicle
--      sync: бит 0x08 (accel) когда состав движется вперёд, 0 — стоит
--      (хук ev.onSendVehicleSync из lib.samp.events, по образцу cheat'a).
-- Сброс клавиш (write 0) добавлен во все ветки простоя/паузы/остановки,
-- чтобы после торможения у поезда не висел нажатый газ.
-- Значение keysData (drive.keys) меняется в драйв-цикле по оценке скорости
-- (st.speed_est), нативный getCarSpeed не трогаем (даёт фризы MoonRage).
-- v0.6.4 — ГОЛОСОВОЙ ДЕТЕКТ АДМИНОВ + FALLBACK id->НИК.
--    1) Кэш id->ник из CEF-команды addVoiceChatEntry: если sampGetPlayerNameById
--       на Radmir не возвращает ник автора пузыря, берём его из кэша голоса.
--    2) Если в голосовой канал зашёл игрок из CheatAdminList.txt — шлётся
--       уведомление в Telegram (с кулдауном 25 сек на повторного идиота).
--    3) dbg_log печатает add/remove голоса для диагностики.
-- v0.6.3 — ФИКС ОПРОСА TELEGRAM + ДИАГНОСТИКА АДМИН-ДЕТЕКТА.
-- 1) На Radmir опрос Telegram был выключен (tg_poll_enable=0 по умолчанию),
--    из-за чего команды из лички бота (/chat и др.) НЕ ДОХОДИЛИ до игры:
--    в лог падало «Опрос Telegram отключён». Теперь в GUI добавлен чекбокс
--    «Опрос Telegram» (вкладка телеграма) — он пишет tg_poll_enable в
--    config.ini и сразу запускает поток опроса. По умолчанию флаг оставлен
--    выключенным, но включение теперь очевидно и сохраняется.
-- 2) Диагностика детекта админов (/mqdiag) переведена на ВРЕМЕННОЕ окно
--    (60 сек) и теперь печатает в лог НИК автора пузыря (sampGetPlayerNameById)
--    и его id. Раньше окно считало 8 сообщений — на Radmir поток системных
--    пузырей «открыл транспорт» съедал его до того, как напишет живой игрок.
--    Так видно, почему не срабатывает матч по списку CheatAdminList.txt, когда
--    в тексте пузыря ника нет (пакет приходит как setPlayerChatBubble(115, 'игорь', ...)).
-- v0.6.2 — СТРУКТУРНЫЙ РАЗБОР RX-ПАКЕТОВ (фикс «не видит кабину»).
-- Раньше onReceivePacket читал ВЕСЬ пакет сплошным буфером (ReadBuffer +
-- ffi.string) и искал "Machinist" в сырых байтах — при двоичном формате CEF
-- (byte id + int16 + int32 + int8 число строк + строки) текст команды НЕ
-- находился, поэтому кабина машиниста не определялась и/или команды не
-- парсились. Теперь разбор как в рабочем скрипте mashinist.lua:
--   raknetBitStreamIgnoreBits(8) (id) -> ReadInt16()==2 -> ReadInt32() ->
--   ReadInt8() (количество строк) -> для каждой [ReadInt32 длина + строка].
-- Формат подтверждён декодированием bodyHex из дампов (packets_data.jsonl):
--   D7 0200 02000000 01 3C000000 "interface('Machinist')...".
-- Это же чтение используют CheatByYaroRage и SimByYaroRage на этом сервере.
-- v0.6.1 — ПРИНУДИТЕЛЬНЫЙ РЕЖИМ КАБИНЫ: параметр force_cab=1 в config.ini
-- (чекбокс на вкладке «Общие» в /mq). Когда включён, inCabNow() всегда
-- возвращает true — автопилот стартует и ведёт состав, даже если CEF-пакеты
-- интерфейса 'Machinist' (setSpeed / setSemaphoreState) по какой-то причине
-- не приходят и детект кабины не срабатывает. Предназначен для случаев, когда
-- персонаж точно в кабине, а пакеты кабины на сервере не видны.
-- v0.5.9 — УБРАН НАТИВНЫЙ СИГНАЛ КАБИНЫ isCharInAnyCar (источник фризов ~1.2 сек).
-- v0.5.8 добавила isCharInAnyCar() для мгновенного определения кабины, но на
-- установленном MoonRage.dll v0.0.29 вызов вешает SAMP-поток на ~1.1-1.6 сек
-- (замер: тик драйв-потока упал с ~7/с до 1/с, wall-gap 1125-1625 мс; игра
-- превратилась в ~1 кадр/с). Причина: antiticket зовёт её редко (только на
-- OnPlayerEnterArea), а мы — каждый тик драйв-потока.
-- ФИКС: isCharInAnyCar полностью убран (и ever_received_machinist). Кабина
-- определяется ТОЛЬКО по свежим RX-пакетам интерфейса 'Machinist': по дампам
-- CefPacketAnalyzer они приходят каждые 1-2 сек, пока интерфейс открыт
-- (68 пакетов за 1.25 мин), поэтому CEF-детект столь же мгновенный.
-- v0.5.8 — ОПРЕДЕЛЕНИЕ КАБИНЫ ЧЕРЕЗ isCharInAnyCar.
-- В v0.5.7 кабина определялась ТОЛЬКО по CEF-пакетам 'Machinist' — считалось,
-- что первый пакет придёт не сразу, поэтому добавляли нативный сигнал.
-- Попытка: быстрый memory-сигнал isCharInAnyCar() — resolvePattern,
-- ped + 0x58C, как isCharInAnyTrain(PLAYER_PED) в эталонных скриптах.
-- НО на установленном MoonRage.dll v0.0.29 этот вызов оказался дорогим
-- (~1.2 сек/вызов, фриз игры) — снято в v0.5.9 (см. выше).
-- v0.5.7 — УБРАНЫ ВСЕ НАТИВНЫЕ game-ВЫЗОВЫ (источник фризов ~1с).
-- Диагностика бисекцией: v0.5.4 без нативных вызовов = 100 тиков/с, max
-- wall-gap 62 мс (ноль фризов); v0.5.5/v0.5.6 с getCarSpeed/getCarModel/
-- storeCarCharIsInNoSave = gap 922-1000 мс каждые ~5 сек (фриз «раз в секунды»).
-- На движке MoonRage каждый нативный game-вызов вешает поток SAMP на
-- ~900-1000 мс (getCurrentVehicleId гоняет цикл по 2000 транспортов).
-- ФИКС: из скрипта удалены ВСЕ нативные вызовы (getCarSpeed, getCarModel,
-- storeCarCharIsInNoSave, doesVehicleExist, getDriverOfCar). Скорость —
-- только по оценке дистанции st.speed_est. Кабина — только по свежим
-- RX-пакетам интерфейса 'Machinist' (любой такой пакет = мы в кабине;
-- cab_timeout увеличен до 120 с, пакеты приходят каждые 1-2 сек, пока
-- интерфейс открыт). В GUI убран чекбокс «Реальная скорость (getCarSpeed)».
-- v0.2.0 — ТЕЛЕГРАМ ПОЛНОСТЬЮ НЕБЛОКИРУЮЩИЙ (НУЛЕВОЙ ФРИЗ ОТ СЕТИ).
-- Требование: ни малейшего фриза от скрипта, даже 0.1 сек. Кортежи
-- ssl.https/ltn12 в MoonLoader исполняются на потоке SAMP и блокируют
-- рендер на всё время запроса. Вся работа с сетью переведена на фоновый
-- process curl.exe через WinExec (асинхронный запуск без ожидания):
--   * sendMessage — fire-and-forget, тело в JSON-файле;
--   * getUpdates — fire-and-forget, ответ curl пишет в tg_tmp\\updates.json,
--     результат читается отдельно (локально, мгновенно).
-- Итог: поток SAMP НЕ выполняет ни одного HTTP-вызова, фризов нет вообще.
-- v0.1.0 — УБРАН ОСТАТОЧНЫЙ ФРИЗ ОТ PERIODIC Telegram-ПОЛЛИНГА.
-- Хотя в v0.0.9 long-poll убран (timeout=0), каждый getUpdates всё равно
-- синхронно исполняется на потоке SAMP: корутина send_async не выносит
-- ssl.https с потока игры, просто прячет в очередь. Сеть до api.telegram.org
-- может тянуться секунды -> «раз в несколько секунд фриз на 3-5 сек».
-- Фикс (v0.1.0):
--   * периодический опрос ВЫКЛЮЧЕН по умолчанию (tg_poll_enable=0); включать
--     только для удалённого управления;
--   * REQUEST_TIMEOUT снижен 5 -> 2 сек (макс. время одного фриза);
--   * каждый сетевой запрос замеряется (>500 мс -> в лог).
-- v0.0.9 — ИСПРАВЛЕН КОРЕНЬ ЛАГА: блокирующий HTTPS long-poll Telegram.
-- v0.0.8 — ДИАГНОСТИЧЕСКАЯ. Флаги бисекции в config.ini:
--   dbg_no_thread = 1   — не создавать поток автопилота (driveThread)
--   dbg_no_events  = 1   — выключить разбор CEF-пакетов (onReceivePacket)
--   dbg_no_gui     = 1   — не трогать imgui (хук OnDrawFrame/Process/ShowCursor)
--   dbg_no_chat    = 1   — не показывать приветственные сообщения в чате
script_name("MachinistByYaroRage")
script_version("0.8.9")
script_author("YaroRage")

require "moonloader"

local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8

local imgui = require "imgui"
local ffi = require "ffi"
local bit = require "bit"

-- Перехват исходящих vehicle sync (патч клавиш управления поездом).
-- Реализация взята из рабочего mashinist.lua: на Radmir сервер читает
-- нажатия газ/тормоз НЕ из CEF-команды OnPlayerClientSideKey, а из битов
-- keysData в vehicle sync (SampKeys: бит 0x08 accel_zoomOut = газ,
-- бит 0x20 decel_jump = тормоз). Без этого скрипт газует, но поезд стоит.
local evOk, ev = pcall(require, "lib.samp.events")
if not evOk or type(ev) ~= "table" then
    ev = nil
end

local state_mod = require "MachinistByYaroRage.state"
local cef = require "MachinistByYaroRage.cef"
local admin = require "MachinistByYaroRage.admin"
local telegram = require "MachinistByYaroRage.telegram"
local ywelcome = require "ywelcome"

local st = state_mod.state

-- Отправка уведомления в телеграм. ВАЖНО: метод tg живёт на МОДУЛЕ
-- (state_mod), а st — это таблица данных (state_mod.state), где tg нет.
local function sendTg(text)
    if type(state_mod.tg) ~= "function" then return end
    state_mod.tg(text)
end

-- Приведение строки к валидному UTF-8 (Telegram API принимает ТОЛЬКО
-- UTF-8; icinity v0.5.0: ник/текст из игры приходят в CP1251).
-- Если строка уже валидный UTF-8 — оставляем как есть; иначе считаем,
-- что это CP1251 (локальная кодировка), и перекодируем в UTF-8.
local function ensureUtf8(s)
    if type(s) ~= "string" then s = tostring(s) end
    local n = #s
    if n == 0 then return s end
    -- Проверка на валидность UTF-8 (без внешних библиотек).
    local ok = true
    local i = 1
    while i <= n do
        local c = s:byte(i)
        if c < 0x80 then
            i = i + 1
        elseif c >= 0xC2 and c <= 0xDF then
            local c2 = s:byte(i + 1)
            if not c2 or c2 < 0x80 or c2 > 0xBF then ok = false break end
            i = i + 2
        elseif c >= 0xE0 and c <= 0xEF then
            local c2, c3 = s:byte(i + 1), s:byte(i + 2)
            if not c3 or c2 < 0x80 or c2 > 0xBF or c3 < 0x80 or c3 > 0xBF then ok = false break end
            if (c == 0xE0 and c2 < 0xA0) or (c == 0xED and c2 > 0x9F) then ok = false break end
            i = i + 3
        elseif c >= 0xF0 and c <= 0xF4 then
            local c2, c3, c4 = s:byte(i + 1), s:byte(i + 2), s:byte(i + 3)
            if not c4 or c2 < 0x80 or c2 > 0xBF or c3 < 0x80 or c3 > 0xBF or c4 < 0x80 or c4 > 0xBF then ok = false break end
            if (c == 0xF0 and c2 < 0x90) or (c == 0xF4 and c2 > 0x8F) then ok = false break end
            i = i + 4
        else
            ok = false
            break
        end
    end
    if ok then return s end
    -- Не UTF-8: перекодируем из CP1251 (локальная кодировка) в UTF-8.
    local okEnc, res = pcall(function() return u8:encode(s) end)
    if okEnc and res then return res end
    return s
end

-- Кэш масштаба GUI: считаем DPI/разрешение не каждый кадр, а только при
-- смене разрешения (или раз в 500 мс) — GetSystemMetrics на каждый кадр
-- при открытом меню даёт лишнюю нагрузку на слабых машинах.
local fscCache = { resX = 0, resY = 0, at = 0, fsc = 1 }
-- ВНИМАНИЕ: нативные game-вызовы в этом скрипте НЕ используются вообще.
-- Каждый вызов getCarSpeed/storeCarCharIsInNoSave/getCarModel на движке
-- MoonRage вешает поток игры на ~900-1000 мс (подтверждено замерами: в
-- v0.5.5/v0.5.6 max wall-gap 922-1000 мс каждые ~5 с; после снятия всех
-- нативных вызовов gap падает до ~62 мс, тиков 100/с). Скорость и кабину
-- определяем ТОЛЬКО по оценке дистанции (st.speed_est) и по свежим
-- пакетам интерфейса 'Machinist' (RX id=215) — это бесплатно и без фризов.
-- Последний вывод ошибки GUI (анти-фриз: не печатать одну и ту же ошибку
-- отрисовки каждый кадр — печать в консоль/лог на каждый кадр вешает игру).
local lastGuiErrPrint = 0
-- Диагностика детекта админов: пока текущее время меньше chatDiagUntil,
-- все входящие сообщения (пузыри, свои, серверные) пишутся в лог с ником
-- автора. Окно задаётся командой /mqdiag и измеряется ВРЕМЕНЕМ (60 сек), а не
-- количеством сообщений — на Radmir системные пузыри («открыл транспорт»)
-- идут потоком и мгновенно съедали прежний счётчик из 8 штук.
local chatDiagUntil = 0
local chatDiagCount = 0

-- Forward-объявления хука отрисовки: toggleMenu и main вызываются раньше,
-- чем объявлены сами функции в секции GUI, поэтому объявляем локальные здесь.
local prevOnDraw = nil
local uiWrapper = nil

-- ---------- DPI и масштаб GUI (как в MechWork/Cheat) ----------
local dpiUi = 1.0
do
    local ok, dpi = pcall(function()
        ffi.cdef[[
            int GetDpiForSystem(void);
            int GetSystemMetrics(int nIndex);
            unsigned long GetTickCount(void);
        ]]
        return ffi.C.GetDpiForSystem()
    end)
    if ok and type(dpi) == "number" and dpi > 0 then dpiUi = dpi / 96 end
    if dpiUi < 0.5 then dpiUi = 0.5 elseif dpiUi > 3.5 then dpiUi = 3.5 end
end
local fsc = 1

-- Wall-clock время (мс) через GetTickCount — для замеров реального gap между
-- тиками main. os.clock() здесь меряет CPU-время процесса, а оно при D3D-фризе
-- не растёт (поток стоит), поэтому счётчик WallClock нужен отдельно.
local function wallClockMs()
    return tonumber(ffi.C.GetTickCount())
end

-- Сид генератора случайных чисел: без него math.random() даёт одинако-
-- вую последовательность при каждом запуске, и "человечность" не меняется.
do
    local ok, seed = pcall(function()
        return (os.time() or 0) + tonumber(ffi.C.GetTickCount())
    end)
    if ok and seed then math.randomseed(seed) end
end

-- ---------- Переменные GUI ----------
local showMenu = imgui.ImBool(false)
local optEnabled = imgui.ImBool(st.enabled)
local optForceCab = imgui.ImBool(st.force_cab)
local optAutoDrive = imgui.ImBool(st.auto_drive)
local optNotify = imgui.ImBool(st.notify_telegram)
local optOverspeed = imgui.ImBool(st.overspeed)
local optTgPoll = imgui.ImBool(st.tg_poll_enable)
local inpToken = imgui.ImBuffer(128)
local inpChat = imgui.ImBuffer(64)
local inpAdmins = imgui.ImBuffer(512)
inpToken.v = st.tg_bot_token
inpChat.v = st.tg_chat_id
-- Номер открытой вкладки меню (как в CheatByYaroRage: кнопки-вкладки сверху).
local menuTab = imgui.ImInt(1)

-- ---------- Рабочее состояние автопилота ----------
local drive = {
    tickThread = nil,
    lastAction = "нет",
    phase = "IDLE",
    stopped = false,
    station_arrived = false,      -- v0.8.1: поезд прибыл на станцию
    station_arrive_time = nil,    -- v0.8.1: момент прибытия (os.time)
    station_left = false,          -- v0.8.1: поезд тронулся со станции
    in_cab = false,
    in_train = false,
    keys = 0,
    stop_preview = 0,
}

-- Диагностика времени БД-записи конфига (мс, символ "s" в строке лога).
local saveDiagMs = 0
local lastSavedSig = nil
local startTgPoll -- forward declaration (saveAll поднимает опрос при включении)

local function saveAll()
    -- Ленивое сохранение: если значения не менялись с прошлой записи,
    -- НЕ трогаем файлы вовсе (запись INI + CheatAdminList.txt может быть
    -- очень дорогой на этой машине и вешать кадр).
    local sig = table.concat({ tostring(optEnabled.v), tostring(optForceCab.v), tostring(optAutoDrive.v), tostring(optNotify.v),
        tostring(optOverspeed.v),
        tostring(optTgPoll.v),
        tostring(inpToken.v), tostring(inpChat.v), tostring(inpAdmins.v) })
    if sig == lastSavedSig then return false end
    lastSavedSig = sig
    local saveT = os.clock()
    st.enabled = optEnabled.v
    st.force_cab = optForceCab.v
    st.auto_drive = optAutoDrive.v
    st.notify_telegram = optNotify.v
    st.overspeed = optOverspeed.v
    st.tg_poll_enable = optTgPoll.v
    st.tg_bot_token = inpToken.v
    st.tg_chat_id = inpChat.v
    -- Поле «Админы» одноразовое: введённые ники автоматически уходят в конец
    -- основного списка CheatAdminList.txt, а поле очищается (admin_names в
    -- INI больше не хранится — единственный источник списка это файл).
    if inpAdmins.v and #inpAdmins.v > 0 then
        state_mod.append_admin_names(inpAdmins.v)
        inpAdmins.v = ""
    end
    state_mod.save_config()
    saveDiagMs = saveDiagMs + (os.clock() - saveT) * 1000
    -- Включение опроса Telegram из GUI сразу поднимает фоновый поток (без
    -- перезагрузки скрипта). Выключение обрабатывается в самом tgPollLoop.
    if st.tg_poll_enable and startTgPoll then startTgPoll() end
    return true
end

-- ---------- Полевые статусы для GUI (экранированные u8) ----------
local phaseTitle = {
    IDLE = u8"ожидание",
    DRIVE = u8"ведение поезда",
    STOP = u8"остановка",
    DISABLED = u8"выключен",
}
-- ---------- События SA:MP (глобальные функции, как в MechWork) ----------
-- ВАЖНО: startBot/stopBot объявлены ЗДЕСЬ (forward), а реализация ниже
-- присваивает их в эти же переменные БЕЗ local — иначе processChatText
-- (объявлена ниже) захватила бы свою nil-переменную и падала с
-- "attempt to call upvalue 'stopBot' (a nil value)" при админ-сообщении.
local startBot
local stopBot
-- v0.8.0: снимок состояния функций в момент выключения чита. Пока чит
-- выключен — хранит, что было включено, чтобы кнопка «Включить чита»
-- вернула всё в том же виде. nil = чит никогда не выключался кнопкой.
local cheatOffState = nil

-- Диагностика приёма CEF-пакетов: сколько 215-пакетов в секунду, их размер
-- и сколько времени уходит на чтение. Выводится в лог раз в 5 секунд, чтобы
-- найти источник лага (переименование скрипта лаг убирает, значит дело в нас).
local rxDiag = {
    count = 0,
    bytes = 0,
    usTotal = 0,
    lastLog = os.clock(),
    lastTime = os.clock(),
}

-- Общая проверка ЛЮБОГО чат-сообщения на админа. Источники: серверные
-- сообщения (onServerMessage — на этом сервере не вызывается), пузыри других
-- игроков (setPlayerChatBubble) и СОБСТВЕННЫЕ отправленные сообщения
-- (onSendPacket 207) — свои сервер обратно не эхоирует, поэтому детект
-- собственного текста идёт здесь, и самопроверка работает.
local function processChatText(label, text, authorNick, skipDiag)
    if not text or #text == 0 then return end
    if st.dbg_no_events then return end
    -- skipDiag=true (из /mqtest) идёт МИМО диагностики: тест должен всегда
    -- выполнять полный детект и слать уведомление, а не печататься в лог.
    if not skipDiag and os.time() < chatDiagUntil then
        chatDiagCount = chatDiagCount + 1
        print("[MachinistByYaroRage] чат-diag#" .. tostring(chatDiagCount) ..
            " [" .. label .. " '" .. text .. "']" ..
            (authorNick and #authorNick > 0 and (" автор=" .. authorNick) or " автор=?" ) ..
            " notify=" .. tostring(optNotify.v) ..
            " tg=" .. tostring(st.tg_bot_token ~= "" and st.tg_chat_id ~= "") ..
            " events=" .. tostring(not st.dbg_no_events))
        return
    end
    if not optNotify.v then return end
    if st.tg_bot_token == "" or st.tg_chat_id == "" then return end
    -- матч по тексту: ник админа в тексте / OOC / слово «администратор»
    -- v0.7.2: админские «вызовы»/анти-бот проверки («Администратор X для Y
    -- Вы тут? Напишите в чат /report - 1») имеют приоритет: извлекаем ник
    -- админа напрямую и фильтруем по адресату «для <мой ник>».
    local who = admin.parse_admin_call(text, st.my_nick) or
                admin.is_admin_message(text)
    -- матч по автору пузыря (ник других игроков, если sampGetPlayerNameById доступен)
    if not who and authorNick and #authorNick > 0 then
        local known = admin.has_known_admin(authorNick)
        if known then who = known end
    end
    if not who then return end
    sendTg(u8"ВНИМАНИЕ! В чате админ!\nКто: " .. ensureUtf8(who) .. u8"\nСообщение: " .. ensureUtf8(text))
    if optEnabled.v then stopBot() end
    -- Игровой отклик + строка в журнал, чтобы результат был виден сразу
    -- и проверялся по moonloader.log без перезапусков.
    pcall(sampAddChatMessage, u8:decode(u8"Machinist: админ '" .. ensureUtf8(tostring(who)) ..
        u8"', уведомление отправлено"), 0xAAFFAA)
    print("[MachinistByYaroRage] Админ-сообщение [" .. label .. "]: " ..
        tostring(who) .. u8" | " .. text)
end

-- Кэш «id игрока -> ник» из голосового чата (addVoiceChatEntry). Используется
-- как fallback при определении автора пузыря, когда sampGetPlayerNameById
-- на Radmir не отдаёт ник. Объявлен ВЫШЕ handleChatBubble (upvalue).
local voiceIdNick = {}
-- v0.6.7: навечный кэш id->ник (не сбрасывается при removeVoiceChatEntry).
-- Один раз узнав ник по голосу, запоминаем на всю сессию.
local knownIdNick = {}

-- v0.6.8: обратный кэш id -> ник (для сопоставления пузырей чата с админами).
-- ID на Radmir меняются часто, поэтому кэш обновляется сканером каждые 10 сек.
local adminIdByCurrentId = {}

-- v0.6.8: фоновый сканер SAMP-пула. Каждые 10 сек обходит все id 0..2000,
-- вызывает sampGetPlayerNameById(id) и сверяет результат со списком админов.
-- Если ник совпадает с CheatAdminList — помечает id в adminIdByCurrentId.
local adminScanDiag = { last = 0 }
local function adminScanTick(nowWall)
    if not isSampAvailable() then return end
    if nowWall - adminScanDiag.last < 10000 then return end
    adminScanDiag.last = nowWall
    local found = false
    -- v0.7.0: перебор пула через sampIsPlayerConnected + sampGetPlayerNickname
    -- (на Radmir sampGetPlayerNameById отдаёт N/A; sampGetPlayerNickname
    -- для неподключённых id крашится, потому проверка подключения обязательна).
    for id = 0, 1000 do
        local okC, conn = pcall(sampIsPlayerConnected, id)
        if okC and conn then
            local okN, name = pcall(sampGetPlayerNickname, id)
            if okN and type(name) == "string" and #name > 0 and name ~= "N/A" then
                knownIdNick[id] = name
                local who = admin.has_known_admin(name)
                if who then
                    adminIdByCurrentId[id] = who
                    if not found then
                        found = true
                        print("[MachinistByYaroRage] scan-id: [" .. tostring(id) .. "] " .. name)
                    end
                end
            end
        end
    end
    -- v0.7.1: собственный персонаж в SAMP-пуле не числится
    -- (sampIsPlayerConnected(свой_id) даёт false), поэтому
    -- резолвим свой id через sampGetPlayerIdByCharHandle(PLAYER_PED).
    local okMy, isMy, myId = pcall(sampGetPlayerIdByCharHandle, PLAYER_PED)
    if okMy and isMy and type(myId) == "number" and myId >= 0 then
        local okN2, myNick = pcall(sampGetPlayerNickname, myId)
        if okN2 and type(myNick) == "string" and #myNick > 0 and myNick ~= "N/A" then
            knownIdNick[myId] = myNick
            st.my_nick = myNick
            local myWho = admin.has_known_admin(myNick)
            if myWho then
                adminIdByCurrentId[myId] = myWho
                print("[MachinistByYaroRage] scan-self: [" .. tostring(myId) .. "] " .. myNick)
            end
        end
    end
end

local function handleChatBubble(b)
    if not b or not b.text then return end
    -- ник автора пузыря из SAMP-списка, если доступен (может быть "N/A").
    -- Если SAMP-пул не отдал ник (игрок вне зоны стрима/кастомный сервер),
    -- подставляем ник из кэша голосового чата (addVoiceChatEntry), иначе
    -- остаётся пустая строка — в диагностике это видно как "автор=?".
    local nick = ""
    -- v0.6.7: сначала ищем в навечном кэше (однажды зафиксированный ник)
    if knownIdNick[b.id] then nick = knownIdNick[b.id] end
    local okN, n = nil, nil
    if #nick == 0 then
        local okC2, conn2 = pcall(sampIsPlayerConnected, b.id)
        if okC2 and conn2 then
            okN, n = pcall(sampGetPlayerNickname, b.id)
        end
    end
    if #nick == 0 and okN and type(n) == "string" and #n > 0 and n ~= "N/A" then nick = n end
    if #nick == 0 and voiceIdNick[b.id] then nick = voiceIdNick[b.id] end
    processChatText("пузырь#" .. tostring(b.id), b.text, nick)
end

-- Обработка команд голосового чата (HUD). Цели:
-- 1) при addVoiceChatEntry(Ник, id) кэшируем пару id->ник — она используется
--    как fallback для пузырей чата (sampGetPlayerNameById на Radmir может
--    быть пустым);
-- 2) если заговорил игрок из списка админов — шлём уведомление в Telegram
--    (с кулдауном: пакеты add/remove приходят пачками, спам гасим).
local voiceNotice = { last = 0, lastId = 0 }
local function handleVoiceChat(v)
    if not v then return end
    if v.action == "add" and v.id then
        if v.nick and #v.nick > 0 then
            voiceIdNick[v.id] = v.nick
            knownIdNick[v.id] = v.nick
        end
        -- детект админа в голосовом канале
        if optNotify.v and st.tg_bot_token ~= "" and st.tg_chat_id ~= "" then
            local who = admin.is_admin_message(v.nick or "")
            if who then
                local now = os.time()
                if now - voiceNotice.last >= 25 or v.id ~= voiceNotice.lastId then
                    voiceNotice.last = now
                    voiceNotice.lastId = v.id
                    sendTg(u8"ВНИМАНИЕ! Админ говорит в голосовом чате\nКто: " .. ensureUtf8(who))
                    if optEnabled.v then stopBot() end
                    pcall(sampAddChatMessage, u8:decode(u8"Machinist: голосовой чат — админ '" ..
                        ensureUtf8(tostring(who)) .. u8"', уведомление отправлено"), 0xAAFFAA)
                    print("[MachinistByYaroRage] Голосовой админ: " .. tostring(who))
                end
            end
        end
    end
    if v.action == "remove" and v.ids then
        for _, i in ipairs(v.ids) do
            voiceIdNick[i] = nil
        end
    end
    -- v0.6.7: knownIdNick НЕ очищается — ник запоминается на всю сессию.
    if st.dbg_log then
        if v.action == "add" then
            print("[MachinistByYaroRage] голос: +" .. tostring(v.nick or ("id " .. tostring(v.id or "?"))))
        else
            print("[MachinistByYaroRage] голос: -" .. table.concat(v.ids or {}, ","))
        end
    end
end

-- Уведомление о ВНЕЗАПНО открывшемся окне/диалоге: срабатывает только во
-- время работы автопилота. Дубли одного и того же окна и частые повторы
-- гасим кулдауном, чтобы не спамить чат и телеграм.
local windowNotice = { last = 0, lastSig = "", cooldown = 25 }
local function notifyWindowOpened(desc)
    if not optEnabled.v then return end
    if desc == windowNotice.lastSig then return end
    local nowT = os.time()
    if nowT - windowNotice.last < windowNotice.cooldown then return end
    windowNotice.last = nowT
    windowNotice.lastSig = desc
    -- всегда сообщаем в игровом чате
    pcall(sampAddChatMessage, u8:decode(u8"Machinist: открылось окно — " .. ensureUtf8(desc)), 0xFFFFAA)
    -- и в телеграм, если включены уведомления
    if optNotify.v and st.tg_bot_token ~= "" and st.tg_chat_id ~= "" then
        sendTg(u8"ВНИМАНИЕ! Открылось окно: " .. ensureUtf8(desc))
    end
    print("[MachinistByYaroRage] Окно-детект: " .. desc)
end

-- Перехват отправляемых CEF-пакетов (TX 215). На Radmir чат при отправке
-- уходит именно CEF-командой (SAMP 207 занят periodic-пустышкой из нулей).
-- Пока только диагностика: длина + читаемая часть + HEX, чтобы понять, какой
-- командой уходит сообщение и где в пакете лежит текст.
local txBuf = ffi.new("char[512]")
function onSendPacket(id, bs)
    if id ~= 215 then return end
    if st.dbg_no_events then return end
    local okLen, rawLen = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not okLen or type(rawLen) ~= "number" or rawLen <= 0 then return end
    local n = math.min(math.max(rawLen, 2), 512)
    local okR = pcall(raknetBitStreamReadBuffer, bs, txBuf, n)
    pcall(raknetBitStreamResetReadPointer, bs)
    if not okR then return end
    local txt = ffi.string(txBuf, n)
    -- неинтересные periodic-«нулевые» пакеты-пустышки пропускаем
    local allZero = true
    for i = 1, math.min(n, 16) do
        if txt:byte(i) ~= 0 then allZero = false break end
    end
    if allZero then return end
    -- читаемая маска: печатные байты как есть, остальное точками
    local m = math.min(n, 120)
    local asc = {}
    for i = 1, m do
        local b = txt:byte(i)
        if b >= 32 and b <= 126 then asc[#asc + 1] = string.char(b) else asc[#asc + 1] = "." end
    end
    local hx = {}
    for i = 1, math.min(n, 24) do
        hx[#hx + 1] = string.format("%02X", txt:byte(i))
    end
    -- печать каждого TX-пакета только при включённой диагностике (dbg_log),
    -- иначе консоль засоряется на каждый исходящий CEF-пакет
    if st.dbg_log then
        print("[MachinistByYaroRage] TX215 len=" .. tostring(rawLen) ..
            " txt=\"" .. table.concat(asc) .. "\" hex=" .. table.concat(hx, " "))
    end
end

function onReceivePacket(id, bs)
    if id ~= 215 then return end
    if not isSampAvailable() then return end

    -- Структурный разбор RX-пакета CEF (id=215). Формат подтверждён
    -- декодированием bodyHex в дампах CefPacketAnalyzer (packets_data.jsonl,
    -- 15.09.2026) и рабочим скриптом mashinist.lua:
    --   [byte id=0xD7][int16 2][int32 2][int8: число строк]
    --   [int32: длина строки][строка] ... (повторяется)
    -- Пример: D7 0200 02000000 01 3C000000 "interface('Machinist')...".
    -- ВАЖНО: bitstream в onReceivePacket приходит целиком (байт id ещё в
    -- потоке, а параметр id уже извлечён для сравнения) — пропускаем его
    -- IgnoreBits(8), как делает mashinist.lua. Читаем строки структурно
    -- (ReadInt16/Int32/Int8/ReadString), а не сплошным ReadBuffer: это
    -- единственный способ извлечь чистый текст команды без бинарного мусора.
    local t0 = os.clock()
    local txt = ""
    pcall(raknetBitStreamIgnoreBits, bs, 8)
    local okI16, i16 = pcall(raknetBitStreamReadInt16, bs)
    local gotBytes = 0
    if okI16 and i16 == 2 then
        pcall(raknetBitStreamReadInt32, bs)
        local okCnt, cnt = pcall(raknetBitStreamReadInt8, bs)
        if okCnt and type(cnt) == "number" and cnt > 0 and cnt < 64 then
            for i = 1, cnt do
                local okLn, ln = pcall(raknetBitStreamReadInt32, bs)
                if okLn and type(ln) == "number" and ln > 0 and ln < 16384 then
                    local okS, s = pcall(raknetBitStreamReadString, bs, ln)
                    if okS and type(s) == "string" and #s > 0 then
                        if #txt > 0 then txt = txt .. "\n" end
                        txt = txt .. s
                        gotBytes = gotBytes + #s
                    else
                        break
                    end
                else
                    break
                end
            end
        end
    end
    rxDiag.usTotal = rxDiag.usTotal + (os.clock() - t0) * 1000000
    rxDiag.count = rxDiag.count + 1
    rxDiag.bytes = rxDiag.bytes + gotBytes

    -- раз в 5 секунд печатаем сводку в лог
    local now = os.clock()
    if now - rxDiag.lastLog >= 5 then
        local span = now - rxDiag.lastTime
        local pps = rxDiag.count / (span or 1)
        local avgBytes = rxDiag.count > 0 and (rxDiag.bytes / rxDiag.count) or 0
        local avgUs = rxDiag.count > 0 and (rxDiag.usTotal / rxDiag.count) or 0
        if st.dbg_log then
            print(string.format(
                "[MachinistByYaroRage] RX215: %d пакетов за %.1fс (%.1f/с), ср. %d байт, чтение avg %.1f мкс",
                rxDiag.count, span, pps, avgBytes, avgUs))
        end
        rxDiag.count = 0
        rxDiag.bytes = 0
        rxDiag.usTotal = 0
        rxDiag.lastLog = now
        rxDiag.lastTime = now
    end

    if #txt == 0 then return end

    -- Флаг бисекции dbg_no_events: пакеты приходим и считаем в rxDiag, но ничего
    -- не парсим — скрипт становится полностью пассивным к CEF-трафику.
    if st.dbg_no_events then return end

    -- Пузыри чата (window.setPlayerChatBubble): чат на этом сервере идёт только
    -- через CEF, onServerMessage не вызывается — детект админов здесь.
    local bubbleOk, bubble = pcall(cef.parse_chat_bubble, txt)
    if bubbleOk and bubble then handleChatBubble(bubble) end

    -- Голосовой чат (interface('Hud').addVoiceChatEntry/removeVoiceChatEntry):
    -- кэшируем id->ник и детектим админов в голосовых каналах.
    local voiceOk, voice = pcall(cef.parse_voice_chat, txt)
    if voiceOk and voice then handleVoiceChat(voice) end

    -- Внезапно открывшееся окно/диалог (addDialogInQueue / PlayerInteraction /
    -- Quests): уведомляем во время работы автопилота.
    local winOk, winDesc = pcall(cef.parse_window_open, txt)
    if winOk and winDesc then notifyWindowOpened(winDesc) end

-- Быстрый отсев чужих CEF-интерфейсов: парсим только данные машиниста.
    if not txt:find("Machinist", 1, true) and not txt:find("InformationTimer", 1, true) then
        -- v0.7.2: админские вызовы идут отдельным CEF-каналом (не пузырём
        -- setPlayerChatBubble и не onServerMessage), поэтому детектим их
        -- напрямую по маркерам (Администратор/вы тут//report) и прогоняем
        -- через processChatText: telegram-уведомление + stopBot (кто рядом).
        if admin.parse_admin_call(txt, st.my_nick) then
            processChatText("адм-вызов", txt)
        end
        return
    end
    st.last_rx_text = txt

    -- Пакет интерфейса 'Machinist' приходит ТОЛЬКО когда персонаж в кабине
    -- машиниста, поэтому любой такой RX-пакет = мы в кабине. Обновляем флаг
    -- и время ДО разбора полей: даже если в пакете нет распознанных команд,
    -- кабина не должна «отваливаться».
    st.in_cab = true
    st.last_pkt_time = os.time()

    -- Парсим состояние машиниста
    local f = cef.parse_state_text(txt)
    if not f then return end

    if f.semaphores then
        st.semaphores = f.semaphores
    end
    if f.speed_range then
        st.speed_range = f.speed_range
    end
    if f.speed_lo ~= nil then
        st.speed_lo = f.speed_lo
    end
    if f.speed_hi ~= nil then
        st.speed_hi = f.speed_hi
    end
    if f.speed_code ~= nil then
        st.speed_code = f.speed_code
    end
    if f.station_name then
        -- оценка скорости по убыванию дистанции (м/с); dt считается по
        -- WallClock (GetTickCount, мс), а не os.time() — последний имеет
        -- гранулярность 1 сек и внутри одной секунды не меняется.
        if st.last_dist >= 0 and st.station_dist >= 0 and f.station_dist and st.last_dist_ms > 0 then
            local nowMs = wallClockMs()
            local dt = (nowMs - st.last_dist_ms) / 1000
            if dt > 0.05 then
                local est = (st.station_dist - f.station_dist) / dt
                if est < 0 then est = 0 end
                st.speed_est = est
                st.last_dist_ms = nowMs
            end
        end
        st.station_name = f.station_name
        if f.station_dist then
            st.last_dist = st.station_dist
            st.station_dist = f.station_dist
            if st.last_dist_ms == 0 then st.last_dist_ms = wallClockMs() end
        end
    end
    if f.money then
        st.money = f.money
    end
    if f.info_timer then
        st.info_timer = f.info_timer
        st.info_timer_sec = f.info_timer_sec
    end
    -- v0.8.1: таймеры штрафа делим на ДВА разных (оба содержат «штраф»):
    --   «Снизьте скорость до штрафа», N  — превышение вилки, нужно ТОРМОЗИТЬ;
    --   «Увеличьте скорость до штрафа», N — поезд стоит/едет медленно, нужно
    --     РАЗГОНЯТЬСЯ (серверный сигнал «поехали!», чаще всего на станции:
    --     после посадки сервер ждёт, что состав уедет).
    -- Раньше оба таймера шли при overspeed_fine, поэтому на «Увеличьте скорость
    -- до штрафа» автопилот «мёртво» стоял (нейтраль/тормоз), сервер повторял
    -- таймер 15->1 и снимал состав с маршрута. Теперь «Увеличьте скорость»
    -- выставляем как st.need_go (нужно РАЗГОНЯТЬСЯ), а штраф превышения —
    -- только по «Снизьте скорость до штрафа». Оба обрабатываем даже без режима
    -- «Превышать скорость» (станции работают и без него).
    -- Таймер «Снизьте скорость» обновляем, только если пришёл ПЕРВЫЙ/меньший
    -- остаток либо предыдущий таймер уже истёк (защита от повтора одного числа).
    st.need_go = false
    if f.info_timer then
        if f.info_timer:find("Снизьте скорость", 1, true) then
            -- v0.8.3: таймер штрафа признаём ВСЕГДА — сервер штрафует за
            -- физическое превышение вилки даже при обычной езде (уклон, спуск,
            -- инерция), а значит скрипт обязан планово сбросить скорость,
            -- а не игнорировать подсказку, пока включён только режим
            -- «Превышать скорость».
            local sec = f.info_timer_sec or 15
            local remaining = st.overspeed_timer > 0 and (st.overspeed_timer - os.time()) or 0
            if st.overspeed_timer == 0 or st.overspeed_timer <= os.time() or sec < remaining then
                st.overspeed_fine = true
                st.overspeed_timer = os.time() + sec
                print(string.format(
                    '[MachinistByYaroRage] FINE: найдено «Снизьте скорость до штрафа», остаток %d c',
                    sec))
            end
        elseif f.info_timer:find("Увеличьте скорость", 1, true) then
            -- сервер требует разгона: снимаем штраф превышения и включаем need_go
            st.need_go = true
            st.overspeed_fine = false
            st.overspeed_timer = 0
        else
            st.overspeed_fine = false
            st.overspeed_timer = 0
        end
    end
    -- v0.6.7: всегда-работающий мини-дамп Machinist-состояния (раз в 5 сек)
    do
        local nowDiag = wallClockMs()
        if not st._lastMachDiag then st._lastMachDiag = 0 end
        if nowDiag - st._lastMachDiag >= 5000 then
            local mid = st.speed_lo + ((st.speed_hi - st.speed_lo) / 2)
            if mid <= 0 then mid = 40 end
            local txT = ''
            if st.last_rx_text then txT = st.last_rx_text:sub(1, 120) end
            print(string.format(
                '[MachinistByYaroRage] MACH: lo=%d hi=%d mid=%.0f code=%s st=%s/%s sem=%s txt=%s',
                st.speed_lo, st.speed_hi, mid, tostring(st.speed_code),
                tostring(st.station_name), tostring(st.station_dist),
                table.concat(st.semaphores, ','),
                txT))
            st._lastMachDiag = nowDiag
        end
    end


    -- Включили автовождение, когда интерфейс машиниста уже активен
    if optEnabled.v and optAutoDrive.v and st.semaphores[1] ~= nil and
       drive.phase == "IDLE" then
        drive.phase = "DRIVE"
        drive.lastAction = u8"старт ведения"
    end
end

-- Детект сообщений админов -> уведомление в телеграм и остановка автопилота.
-- Глобальный хук: вызывается MoonLoader'ом при каждом чат-сообщении сервера.
-- На Radmir серверный чат сюда НЕ приходит (основной поток — в пузырях CEF и
-- в собственных отправленных сообщениях), хук оставлен для совместимости.
function onServerMessage(color, text)
    processChatText("сервер", text)
end

-- Проверка что локальный игрок находится в кабине локомотива.
-- Основной сигнал — свежие RX-пакеты интерфейса 'Machinist' (setSpeed /
-- setSemaphoreState и т.п.): они приходят ~раз в 1-2 сек, пока интерфейс
-- кабины открыт (замерено по дампам CefPacketAnalyzer: 68 пакетов за
-- 1.25 мин, интервалы 1-2 сек). Любой такой пакет = мы в кабине, держим
-- флаг ещё cab_timeout секунд.
-- ВАЖНО: нативный isCharInAnyCar() НЕ используется вовсе — на установленном
-- движке MoonRage.dll v0.0.29 его вызов вешает SAMP-поток на ~1.2 сек
-- (замерено: при v0.5.8 тик драйв-потока упал с ~7/с до 1/с, wall-gap
-- 1125-1625 мс; antiticket тоже зовёт его, но только на OnPlayerEnterArea,
-- поэтому заметного фриза нет). CEF-детект кабины мгновенный (пакет приходит
-- в первую же секунду), нативный сигнал не даёт выигрыша, только фризы.
local function inCabNow()
    -- Принудительный режим (force_cab): считаем, что мы в кабине всегда —
    -- автопилот стартует и ведёт, даже если CEF-пакеты 'Machinist' не приходят.
    if st.force_cab then return true end
    return st.in_cab and (os.time() - st.last_pkt_time) <= st.cab_timeout
end

-- ---------- Ведение поезда (порт из рабочего mashinist.lua) ----------
-- На Radmir состав двигается ТОЛЬКО нативными средствами:
--   1) газ — setGameKeyState(16,255) на кадр, пока скорость ниже середины
--      вилки setSpeed (как в mashinist.lua: press_gas там не вызывается,
--      writeMemory на газ не нужен);
--   2) тормоз — setGameKeyState(14,255) + writeMemory(0xB73458+0x1C,1,255,false);
--   3) точная остановка — setTrainSpeed(car, max(0, spd/1.1-1));
--   4) направление сервер читает из keysData исходящего vehicle sync:
--      бит 0x08 (accel) когда состав движется вперёд, 0x20 (decel) назад,
--      0 — стоит. key считается по ЗНАКУ реальной скорости (getCarSpeed) —
--      это критично: поезд начинает ехать только когда в sync виден accel.
-- Весь автопилот гейтится НАТИВНОЙ isCharInAnyTrain(PLAYER_PED): вне поезда
-- скрипт НЕ трогает ни клавиши, ни keysData — поэтому в обычном автомобиле
-- двигатель заводится нормально (в v0.6.5 releaseKeysNative() каждые 150 мс
-- обнулял W/S и блокировал запуск двигателя).

-- Целевой чекпоинт: сервер ставит race checkpoint по маршруту состава.
local driveCp = { x = 0, y = 0, z = 0 }
local driveCpFinish = false

-- Нажать газ (игровая клавиша W), как в mashinist.lua — без writeMemory.
local function pressGasNative()
    -- Газ — только игровая клавиша W (как в mashinist.lua: их цикл
    -- на разгоне жмёт setGameKeyState(16, 255), accel пишет лишь тормоз).
    -- Настоящий accel для сервера уходит через drive.keys в onSendVehicleSync.
    pcall(setGameKeyState, 16, 255)
end

-- Нажать тормоз (S): игровая клавиша + память (как press_brake в mashinist.lua).
local function pressBrakeNative()
    pcall(setGameKeyState, 14, 255)
    pcall(writeMemory, 0xB73458 + 0x1C, 1, 255, false)
end

-- Отпустить W/S (только на границе выхода из поезда; игра сама очищает клавиатуру).
local function releaseKeysNative()
    pcall(writeMemory, 0xB73458 + 0x20, 1, 0, false)
    pcall(writeMemory, 0xB73458 + 0x1C, 1, 0, false)
    pcall(setGameKeyState, 16, 0)
    pcall(setGameKeyState, 14, 0)
end

-- Нативно ли игрок в поезде (гейт всего автопилота).
local function inTrainNow()
    local ok, res = pcall(isCharInAnyTrain, PLAYER_PED)
    return ok and res == true
end

-- Хук исходящего vehicle sync: подкладываем keysData (как в mashinist.lua).
-- Патчим ТОЛЬКО когда автопилот включён и игрок реально в поезде — иначе
-- в обычном автомобиле подмена keysData ломает движение/запуск двигателя.
if ev then
    function ev.onSendVehicleSync(data)
        if type(data) ~= "table" then return end
        if not optEnabled.v then return end
        if not drive.in_train then return end
        data.keysData = drive.keys or 0
    end

    -- Чекпоинт-цель состава (сервер шлёт по маршруту).
    function ev.onSetRaceCheckpoint(_type, pos, _nextPos, _size)
        if type(pos) == "table" then
            driveCp.x, driveCp.y, driveCp.z = pos.x or 0, pos.y or 0, pos.z or 0
        end
        driveCpFinish = _type == 1
    end

    function ev.onDisableRaceCheckpoint()
        driveCpFinish = false
    end
end

-- Поток автопилота — порт цикла из mashinist.lua:
--   bot.state        -> optEnabled.v (наше включение автопилота)
--   isCharInAnyTrain -> drive.in_train (нативный гейт)
--   bot.distance     -> st.station_dist (дистанция до станции из setStation)
--   bot.speed.min/max-> st.speed_lo/st.speed_hi (вилка setSpeed, км/ч)
--   checkpoint       -> driveCp (чекпоинт сервера, если есть)
-- Цикл идёт КАЖДЫЙ кадр (wait(0)), как в эталоне, а не по tap_interval —
-- газ/тормоз должны держаться постоянно, а не раз в 150-450 мс.
local function driveThread()
    if st.dbg_no_thread then
        print("[MachinistByYaroRage] driveThread пропущен (dbg_no_thread=1)")
        drive.tickThread = nil
        return
    end
    local timer = os.clock()
    local lastDistance = 0
    while optEnabled.v do
        wait(0)

        -- ГЛАВНОЕ: не трогаем ничего, когда игрок вне поезда. Ветка «не в
        -- поезде» НЕ зовёт releaseKeysNative()/writeMemory — иначе в обычном
        -- автомобиле каждые 150 мс обнуляются W/S и двигатель не заводится.
        local inTrain = inTrainNow()
        drive.in_train = inTrain
        if not inTrain then
            if drive.phase == "DRIVE" or drive.phase == "STOP" then
                drive.phase = "IDLE"
            end
            drive.keys = 0
            drive.lastAction = u8"вне поезда"
        else
            drive.phase = "DRIVE"
            drive.lastAction = u8"ведение"
            -- Реальная скорость состава. Нативные вызовы в эталоне работают
            -- без фризов (mashinist.lua сам так ездит), поэтому переносим их
            -- как есть: car это локомотив под игроком.
            local ok, car = pcall(storeCarCharIsInNoSave, PLAYER_PED)
            local speed = 0
            if ok and type(car) == "number" and car > 0 then
                local ok2, spd = pcall(getCarSpeed, car)
                if ok2 and type(spd) == "number" then speed = spd * 3.67 end
            end
            -- v0.8.1: снимаем серверное требование «Увеличьте скорость до штрафа»,
            -- как только поезд реально поехал (скорость вошла в вилку).
            if st.need_go and speed >= math.max(5, (st.speed_lo or 0) * 0.8) then
                st.need_go = false
            end
            -- v0.8.1: снимаем флаги стоянки при начале движения, чтобы не
            -- «застрять» в зацикленном прибытии на станцию.
            if speed >= 10 then
                drive.station_arrived = false
                drive.station_arrive_time = nil
                drive.station_left = false
            end

            -- Дистанция до цели: если сервер выставил чекпоинт — до него,
            -- иначе остаток пути до станции из setStation (st.station_dist).
            local x, y, z = 0, 0, 0
            local ok3, cx, cy, cz = pcall(getCharCoordinates, PLAYER_PED)
            if ok3 then x, y, z = cx, cy, cz end
            local distance
            if driveCpFinish or (driveCp.x ~= 0 or driveCp.y ~= 0 or driveCp.z ~= 0) then
                local okd, d = pcall(getDistanceBetweenCoords3d, x, y, z, driveCp.x, driveCp.y, driveCp.z)
                distance = okd and math.max(0, d - 1) or 99999
            else
                distance = st.station_dist and st.station_dist >= 0 and st.station_dist or 99999
            end

            -- v0.7.4: цель вне станции — МАКСИМУМ вилки минус 1 км/ч; при
            -- обнаружении станции, если скоростной режим не запрещает движение
            -- (speed_code == 1 «газ» или код ещё не пришёл), едем на СРЕДНЕЙ
            -- скорости диапазона (lo + (hi-lo)/2) — как в MACH-диагностике.
            -- Fallback: если вилка ещё не пришла (hi<=0) — берём lo, иначе 40.
            local target = (st.speed_hi and st.speed_hi > 0) and (st.speed_hi - 1)
                or ((st.speed_lo and st.speed_lo > 0) and st.speed_lo or 40)

            -- Зона станции: считаем торможение ТОЛЬКО когда станция близко.
            -- v0.7.9: убрана хрупкая эвристика (station_dist - distance в 0..35):
            -- чекпоинт сервера стоит прямо на станции, поэтому разница всегда ~0,
            -- nearStation было ВСЕГДА true и режим превышения не работал вовсе.
            -- Теперь: финиш-чекпоинт -> зона 500 м, чекпоинта нет (setStation)
            -- -> зона 300 м, обычный чекпоинт на перегоне -> false (едем выше вилки).
            local nearStation = false
            if driveCpFinish then
                nearStation = distance < 500
            elseif driveCp.x == 0 and driveCp.y == 0 and driveCp.z == 0 then
                nearStation = distance < 300
            end

            -- v0.7.4: при обнаружении станции держим допустимую скорость = среднюю
            -- диапазона, если скоростной режим не запрещает (speed_code не «стоп»
            -- и не «тормоз»). Средняя = lo + (hi-lo)/2 (как в MACH-диагностике).
            -- v0.8.2: умный автопилот — физика торможения и таймеры сервера.
            -- Из CEF-пакетов интерфейса 'Machinist' известна вся картина:
            --   setSpeed("39-45",2) — вилка допустимой скорости и код;
            --   setStation("Больничная",697,1) — станция и ДИСТАНЦИЯ до неё;
            --   InformationTimer["Ожидайте отправления",15] и др. — таймеры.
            -- Скрипт по реальному замедлению состава считает тормозной путь
            -- (за сколько метров какую скорость можно погасить), знает, успеет
            -- ли остановиться на станции, держит тормозную кривую и потому
            -- маршрут проходится максимально быстро и без штрафов.
            -- v0.8.4: на станционной зоне цель НЕ занижаем до середины вилки —
            -- состав должен ехать на максимуме (hi-1), а плавность подъезда
            -- к станции обеспечивает физическая кривая vStop ниже. Раньше
            -- целевая была серединой диапазона (lo + (hi-lo)/2), из-за чего
            -- при широких вилках (например 2..150) состав полз на ~76 км/ч
            -- всю 800-метровую зону и «вообще не превышал скорость».
            -- «Станция впереди»: штатная зона (чекпоинт) ЛИБО серверная
            -- дистанция setStation меньше 800 м. Раньше торможение начиналось
            -- только в зоне 500/300 м — при 130 км/ч (путь ~326 м) и зоне 300 м
            -- без чекпоинта состав не успевал. Теперь тормозим по кривой СРАЗУ.
            local stationAhead = nearStation
                or (st.station_dist and st.station_dist >= 0 and st.station_dist < 800)
            -- Физика: замедление состава a (м/с^2), запас пути brakeMargin (м).
            local brakeA = (st.brake_decel and st.brake_decel > 0) and st.brake_decel or 2.0
            local brakeMargin = (st.brake_margin and st.brake_margin >= 0) and st.brake_margin or 6
            -- v0.8.5: ПЛАВНОЕ торможение «как у живого игрока».
            -- Раньше кривая строилась на максимальном замедлении (brake_flag
            -- 2.0 м/с^2): состав до последнего нёсся на целевой, потом резко
            -- «валился» тормозом 180..255 — жёстко и палевно. Теперь две кривые:
            --   vLim  — КОМФОРТНАЯ (aComf ~55% от реального замедления):
            --           скорость, при которой состав плавно погасит к станции.
            --           Ограничение «подкрадывается» с ~600 м и скорость тянется
            --           к нулю у самой станции — как едет человек.
            --   vHard — ЖЁСТКАЯ (max замедление brakeA): настоящий предел,
            --           при превышении которого встать уже не успеем. Экстренный
            --           тормоз применяется только здесь и при дедлайне сервера.
            local stationKnown = st.station_dist and st.station_dist >= 0
            -- v0.8.4: цель тормозной кривой — СТАНЦИЯ, а не чекпоинт-маркер.
            -- Сервер ставит race checkpoint (маркер) ПЕРЕД станцией (например
            -- на входной стрелке), и если гасить скорость по дистанции до
            -- маркера — состав останавливается за 300+ метров до станции.
            -- Пока серверная дистанция станции больше дистанции до маркера,
            -- кривую строим от станции.
            local brakeDist = stationKnown and math.max(distance, st.station_dist) or distance
            local aComf = brakeA * 0.75
            local vLimMs = math.sqrt(math.max(0, 2 * aComf
                * math.max(0, (stationAhead and brakeDist or 99999) - brakeMargin)))
            local vLim = vLimMs * 3.6
            local vHardMs = math.sqrt(math.max(0, 2 * brakeA
                * math.max(0, (stationAhead and brakeDist or 99999) - brakeMargin)))
            local vHard = vHardMs * 3.6
            local speedMsNow = math.max(0, speed / 3.6)
            local brakePathNow = (speedMsNow * speedMsNow) / (2 * brakeA) + brakeMargin
            -- Серверные таймеры: пока висит «Ожидайте отправления» или «Садитесь
            -- в поезд» с остатком — стоим ровно столько, сколько требует сервер
            -- (раньше — фиксированные 5 секунд station_dwell).
            local timerText = st.info_timer or ""
            local stayTimed = (timerText:find("Ожидайте отправления", 1, true)
                or timerText:find("Садитесь в поезд", 1, true))
                and st.info_timer_sec and st.info_timer_sec > 0
            if stationAhead then
                drive.stop_preview = brakeDist - brakePathNow
                if timer < os.clock() then
                    lastDistance = distance
                    timer = os.clock() + 1
                end
                -- v0.8.6: ОСТАНАВЛИВАЕМСЯ окончательно только по серверной команде
                -- «Остановитесь на станции» (либо состав уже стоит прямо в самом
                -- триггере станции — запасной случай при глюке). Раньше прибытие
                -- считалось по радиусу 15 м от станции/маркера, и состав вставал
                -- за десяток метров до триггера — станция не защитывалась.
                local stopCmd = timerText:find("Остановитесь на станции", 1, true)
                    and st.info_timer_sec and st.info_timer_sec > 0
                -- v0.8.8: точка остановки смещена на ~20 м ЗА маркер станции.
                -- Когда нос состава вошёл в триггер (station_dist <= 5),
                -- начинаем отсчёт ПРОЙДЕННОГО пути по координатам и встаём
                -- только после 20 м за маркером (раньше состав останавливался
                -- прямо на маркере). Последние метры — на совсем малой
                -- скорости, с плавным дотормаживанием.
                local passLen = 0
                if stationKnown and st.station_dist <= 5 then
                    local curX, curY = x, y
                    if drive._passMk then
                        local dx = curX - (drive._passPx or curX)
                        local dy = curY - (drive._passPy or curY)
                        drive._passLen = (drive._passLen or 0) + math.sqrt(dx * dx + dy * dy)
                        drive._passPx, drive._passPy = curX, curY
                        passLen = drive._passLen
                    else
                        drive._passMk = true
                        drive._passLen = 0
                        drive._passPx, drive._passPy = curX, curY
                    end
                else
                    drive._passMk = nil
                    drive._passLen = 0
                end
                local atTrigger = (stationKnown and st.station_dist <= 8
                    and passLen >= 20) or (not stationKnown and distance <= 3)
                -- v0.8.7: штраф за превышение вилки обрабатываем и на станции.
                -- Раньше станционная ветка «съедала» таймер «Снизьте скорость
                -- до штрафа»: на подъезде состав держался выше вилки (code=2),
                -- и сервер штрафовал (получен реальный штраф).
                local fineMsSt = (st.speed_hi and st.speed_hi > 1)
                    and ((st.speed_hi - 1) / 3.6) or nil
                local fineActiveSt = st.overspeed_fine
                    and st.overspeed_timer > os.time()
                local speedMsSt = math.max(0, speed / 3.6)
                local fineLeftSt = fineActiveSt
                    and math.max(0, st.overspeed_timer - os.time()) or 0
                local vExcessSt = fineLeftSt > 0
                    and math.max(0, speedMsSt - (fineMsSt or 9999)) or 0
                local aNeededSt = vExcessSt > 0
                    and ((vExcessSt / fineLeftSt) * 1.15) or 0
                local fineBrakeSt = fineActiveSt
                    and (vExcessSt > 0.3) and (aNeededSt >= 0.45 or vExcessSt >= 2.5)
                if stopCmd and speed < 5 then
                    -- Команда сервера висит, состав уже погасил скорость — стоянка.
                    if not drive.station_arrived then
                        drive.station_arrived = true
                        drive.station_arrive_time = os.time()
                    end
                    local dwellLeft
                    if stopCmd then
                        -- Команда «Остановитесь на станции» ещё активна: стоим,
                        -- пока сервер не сменит её на «Ожидайте отправления».
                        dwellLeft = 60
                    elseif stayTimed then
                        dwellLeft = st.info_timer_sec
                    else
                        local dwell = st.station_dwell or 5
                        dwellLeft = dwell - (os.time() - (drive.station_arrive_time or os.time()))
                    end
                    -- Страховка от «застрявшего» таймера сервера: после 45 секунд
                    -- стоянки отправляемся сами (для конечной станции — только по
                    -- команде сервера need_go).
                    dwellLeft = math.min(dwellLeft,
                        45 - (os.time() - (drive.station_arrive_time or os.time())))
                    -- Пора трогаться: сервер требует скорость (need_go), либо
                    -- таймер ожидания закончился/не задан (но не уезжаем сами
                    -- с финишной станции круга).
                    if st.need_go or (not driveCpFinish and not (dwellLeft > 0)) then
                        -- Отправление: тормоз 0, фаза DRIVE, газ до цели.
                        drive.station_arrived = false
                        drive.station_arrive_time = nil
                        drive.phase = "DRIVE"
                        pcall(writeMemory, 0xB73458 + 0x1C, 1, 0, false)
                        pcall(setGameKeyState, 14, 0)
                        local goTarget = (st.speed_hi and st.speed_hi > 0)
                            and (st.speed_hi - 1)
                            or ((st.speed_lo and st.speed_lo > 0) and st.speed_lo or 40)
                        if speed < goTarget then pressGasNative() end
                        drive.lastAction = st.need_go
                            and u8"отправление (сервер требует скорость)"
                            or u8"отправление после стоянки"
                    else
                        -- Стоянка: лёгкий тормоз удерживает состав; время стоянки —
                        -- из таймера сервера (обновляется каждым пакетом) или из
                        -- настроек station_dwell.
                        drive.phase = "STOP"
                        pcall(writeMemory, 0xB73458 + 0x1C, 1, 30, false)
                        pcall(setGameKeyState, 14, 30)
                        drive.lastAction = u8"стоянка на станции (ост. " ..
                            tostring(math.max(0, math.ceil(dwellLeft))) .. u8" с)"
                    end
                elseif not stopCmd and atTrigger and speed < 5 then
                    -- Оказались прямо в триггере станции, а команда остановки так
                    -- и не пришла (глюк сервера) — встаём и ждём отправления.
                    if not drive.station_arrived then
                        drive.station_arrived = true
                        drive.station_arrive_time = os.time()
                    end
                    local dwellLeft = math.min(st.station_dwell or 5, 45)
                    if st.need_go or (not driveCpFinish and not (dwellLeft > 0)) then
                        drive.station_arrived = false
                        drive.station_arrive_time = nil
                        drive.phase = "DRIVE"
                        pcall(writeMemory, 0xB73458 + 0x1C, 1, 0, false)
                        pcall(setGameKeyState, 14, 0)
                        local goTarget = (st.speed_hi and st.speed_hi > 0)
                            and (st.speed_hi - 1)
                            or ((st.speed_lo and st.speed_lo > 0) and st.speed_lo or 40)
                        if speed < goTarget then pressGasNative() end
                        drive.lastAction = u8"отправление после стоянки"
                    else
                        drive.phase = "STOP"
                        pcall(writeMemory, 0xB73458 + 0x1C, 1, 30, false)
                        pcall(setGameKeyState, 14, 30)
                        drive.lastAction = u8"стоянка в триггере станции (ост. " ..
                            tostring(math.max(0, math.ceil(dwellLeft))) .. u8" с)"
                    end
                elseif (stopCmd or atTrigger) and speed >= 4 then
                    -- v0.8.8: точка остановки достигнута (проехали 20 м за
                    -- маркер либо пришла команда сервера), а скорость ещё не
                    -- нулевая — ПЛАВНО дотормаживаем слабым тормозом: без
                    -- резкого рывка и без палевного звука торможения.
                    local softBrake = speed >= 60 and 150 or 40
                    pcall(writeMemory, 0xB73458 + 0x1C, 1, softBrake, false)
                    pcall(setGameKeyState, 14, softBrake)
                    drive.lastAction = u8"мягкое дотормаживание на станции"
                elseif fineBrakeSt then
                    -- Плавный сброс к вилке (штраф «Снизьте скорость»): aNeeded
                    -- 0.45..2.6 -> тормоз 150..255, как на перегоне.
                    local bLevel
                    if aNeededSt >= 2.6 then
                        bLevel = 255
                    else
                        bLevel = math.floor(150 + math.max(0, math.min(1, (aNeededSt - 0.45) / 2.15)) * 105)
                    end
                    pcall(writeMemory, 0xB73458 + 0x1C, 1, bLevel, false)
                    pcall(setGameKeyState, 14, bLevel)
                    drive.lastAction = u8"плавный сброс к вилке на станции (штраф)"
                elseif speed > vHard + 1 or (stopCmd and speed >= 60) then
                    -- Не успеваем встать даже при максимальном замедлении, либо
                    -- сервер уже командует «Остановитесь на станции», а скорость
                    -- ещё далека от нуля — экстренный тормоз (максимальный/200).
                    local hardStop = stopCmd
                        and st.info_timer_sec and st.info_timer_sec <= 15
                    local brakeLevel = hardStop and 255 or 200
                    pcall(writeMemory, 0xB73458 + 0x1C, 1, brakeLevel, false)
                    pcall(setGameKeyState, 14, brakeLevel)
                    if ok and type(car) == "number" and car > 0 then
                        local vDesired = math.min(speedMsNow, vHardMs)
                            * (brakeDist / math.max(1, brakePathNow))
                        if speedMsNow > vDesired + 0.5 then
                            pcall(setTrainSpeed, car, math.max(0, vDesired - 0.2))
                        end
                    end
                    drive.lastAction = u8"экстренное торможение до станции"
                elseif speed > vLim + 1 then
                    -- Плавное замедление по комфортной кривой: тормоз мягко
                    -- растёт от 60 к 150 с глубиной превышения над vLim — как
                    -- игрок, заранее сбрасывающий скорость на станции. 255 не
                    -- используем, setTrainSpeed-резерв тоже (слишком резкий).
                    local frac = math.max(0, math.min(1,
                        (speed - vLim) / math.max(1, vHard - vLim)))
                    local brakeLevel = math.floor(90 + 110 * frac)
                    -- v0.8.8: на малой скорости (35 км/ч и ниже) тормоз мягкий —
                    -- состав плавно дотормаживается без резкого рывка и без
                    -- палевного звука тормоза.
                    if speed < 35 then brakeLevel = math.min(brakeLevel, 60) end
                    pcall(writeMemory, 0xB73458 + 0x1C, 1, brakeLevel, false)
                    pcall(setGameKeyState, 14, brakeLevel)
                    drive.lastAction = u8"плавное торможение до станции"
                else
                    -- v0.8.6: Пока нет команды «Остановитесь на станции» — едем
                    -- максимально быстро, но не быстрее комфортной кривой. Возле
                    -- самой станции кривая уже уходит в ноль, а нам нужно ДОЕХАТЬ
                    -- до триггера: в последних метрах цель не ниже 8 км/ч, состав
                    -- подползает и таки въезжает в триггер, где сервер и даёт
                    -- команду остановиться.
                    local creepActive = stationKnown and st.station_dist <= 30
                    local allowed = math.min(target,
                        math.max(vLim, creepActive and 8 or 0))
                    if speed < allowed then
                        pressGasNative()
                        drive.lastAction = creepActive
                            and u8"подползание к триггеру станции"
                            or u8"разгон"
                    else
                        drive.lastAction = u8"выжим/нейтраль на станции"
                    end
                end
            else
                -- Вне зоны станции: разгон до обычной цели или режим превышения.
                -- v0.8.3: ПЛАНОВОЕ торможение по таймеру штрафа («Снизьте
                -- скорость до штрафа»). Раньше скрипт ставил цель = вилке и
                -- ждал последней секунды таймера — на 150+ км/ч за 1 секунду
                -- сбросить физически невозможно, поэтому сервер штрафовал.
                -- Теперь каждый кадр считается НЕОБХОДИМОЕ замедление: сколько
                -- м/с^2 нужно, чтобы к моменту окончания таймера плавно войти
                -- в вилку (с запасом x1.15 на неточность физики состава), и
                -- тормозим ВЕСЬ период штрафного таймера, а не в последний
                -- момент. Плюс ограничен потолок разгона в режиме превышения:
                -- выше скорости, которую успеем плавно сбросить обратно в
                -- вилку за типовое окно таймера (12 сек), не разгоняемся.
                drive.stop_preview = 0
                local useTarget = target
                -- v0.8.3: предел вилки и активный штраф определяем ВСЕГДА,
                -- независимо от режима «Превышать скорость»: при физическом
                -- превышении (уклон/инерция) таймер штрафа обрабатывается
                -- в любом режиме, иначе штраф сервера гарантирован.
                local fineMs = (st.speed_hi and st.speed_hi > 1)
                    and ((st.speed_hi - 1) / 3.6) or nil
                local activeFine = st.overspeed_fine
                    and st.overspeed_timer > os.time()
                local speedMs = math.max(0, speed / 3.6)
                local needGo = st.need_go
                if needGo then
                    st.overspeed_fine = false
                    st.overspeed_timer = 0
                    activeFine = false
                end
                -- Остаток таймера штрафа и насколько ещё превышаем вилку.
                local fineLeft = activeFine and math.max(0, st.overspeed_timer - os.time()) or 0
                local vExcess = fineLeft > 0 and math.max(0, speedMs - (fineMs or 9999)) or 0
                -- Необходимое замедление: превышение / оставшиеся секунды (x1.15).
                local aNeeded = vExcess > 0 and ((vExcess / fineLeft) * 1.15) or 0
                -- Тормозим сразу, как только без него к концу таймера не успеть
                -- (а не когда скорость УЖЕ катастрофически над вилкой).
                local fineBrake = activeFine
                    and (vExcess > 0.3) and (aNeeded >= 0.45 or vExcess >= 2.5)
                if st.overspeed and fineMs then
                    if activeFine then
                        useTarget = fineMs * 3.6
                    else
                        local overspeedTarget = fineMs * 3.6 + (st.overspeed_extra or 8)
                        -- Потолок превышения: не выше скорости, которую реально
                        -- успеем сбросить в вилку за 12 c (окно типового таймера
                        -- штрафа) при подтверждённом замедлении состава brakeA.
                        local vCeil = fineMs * 3.6 + brakeA * 0.8 * 12 * 3.6
                        useTarget = math.max(target + 1, math.min(overspeedTarget, vCeil))
                    end
                end
                if needGo then
                    -- сервер требует движения: газ до обычной цели
                    if speed < target then
                        pressGasNative()
                        drive.lastAction = u8"разгон (сервер требует скорость)"
                    else
                        drive.lastAction = u8"набор/нейтраль"
                    end
                elseif fineBrake then
                    -- Плавный сброс к вилке: aNeeded 0.45..2.6 -> тормоз 150..255.
                    local bLevel
                    if aNeeded >= 2.6 then
                        bLevel = 255
                    else
                        bLevel = math.floor(150 + math.max(0, math.min(1, (aNeeded - 0.45) / 2.15)) * 105)
                    end
                    pcall(writeMemory, 0xB73458 + 0x1C, 1, bLevel, false)
                    pcall(setGameKeyState, 14, bLevel)
                    drive.lastAction = u8"плавный сброс скорости к вилке (штраф)"
                elseif speed < useTarget then
                    pressGasNative()
                    drive.lastAction = u8"разгон"
                else
                    drive.lastAction = u8"набор/нейтраль"
                end
            end

            -- v0.8.5: диагностика подъезда к станции (раз в 5 сек) — чтобы по
            -- логу видеть, куда едет состав: дистанция от станции, до маркера,
            -- значения кривых и признак прибытия. Числа, кириллица не мешает.
            do
                local nowDiag = wallClockMs()
                if not drive._lastDriveDiag then drive._lastDriveDiag = 0 end
                if nowDiag - drive._lastDriveDiag >= 5000 then
                    drive._lastDriveDiag = nowDiag
                    print(string.format(
                        '[MachinistByYaroRage] DRIVE: spd=%d tgt=%d distCp=%d stDist=%s brDist=%s vLim=%s vHard=%s ahead=%s arr=%s needGo=%s',
                        math.floor(speed * 10) / 10, math.floor(target * 10) / 10,
                        math.floor(distance), tostring(st.station_dist),
                        tostring(stationAhead and math.floor(brakeDist) or '-'),
                        tostring(stationAhead and math.floor(vLim) or '-'),
                        tostring(stationAhead and math.floor(vHard) or '-'),
                        tostring(stationAhead), tostring(drive.station_arrived),
                        tostring(st.need_go)))
                end
            end

            -- keysData: как в mashinist.lua — знак реальной скорости.
            --   0x08 (accel) = вперёд, 0x20 (decel) = назад, 0 = стоит.
            if speed > 0 then
                drive.keys = 8
            elseif speed < 0 then
                drive.keys = 32
            else
                drive.keys = 0
            end
        end
    end
    drive.tickThread = nil
end

-- ---------- Команды ----------
local function toggleMenu()
    if st.dbg_no_gui then
        pcall(sampAddChatMessage, u8:decode(u8"Machinist: GUI отключён (dbg_no_gui=1)"), 0xAAAAFF)
        return
    end
    showMenu.v = not showMenu.v
    if showMenu.v then
        -- подхватываем хук отрисовки только ПОКА меню открыто
        local cur = imgui.OnDrawFrame
        if cur ~= uiWrapper then prevOnDraw = cur end
        imgui.OnDrawFrame = uiWrapper
    else
        -- меню закрыли: возвращаем хук тому, кто был до нас
        if imgui.OnDrawFrame == uiWrapper then
            imgui.OnDrawFrame = prevOnDraw
        end
        prevOnDraw = nil
    end
end

startBot = function()
    -- v0.8.0: «Включить чита» возвращает ВСЕ функции, которые были включены
    -- в момент выключения (снимок делается в stopBot). Если снимка нет
    -- (например, /mqstart без предварительного выключения) — включаем
    -- автопилот как раньше, остальные опции остаются как были.
    if cheatOffState then
        optEnabled.v = cheatOffState.enabled
        optForceCab.v = cheatOffState.force_cab
        optAutoDrive.v = cheatOffState.auto_drive
        optNotify.v = cheatOffState.notify
        optOverspeed.v = cheatOffState.overspeed
        optTgPoll.v = cheatOffState.tg_poll
        cheatOffState = nil
    else
        optEnabled.v = true
    end
    saveAll()
    if optEnabled.v and not drive.tickThread and not st.dbg_no_thread then
        drive.tickThread = lua_thread.create(driveThread)
    end
    local restored = 0
    if optForceCab.v then restored = restored + 1 end
    if optAutoDrive.v then restored = restored + 1 end
    if optNotify.v then restored = restored + 1 end
    if optOverspeed.v then restored = restored + 1 end
    if optTgPoll.v then restored = restored + 1 end
    local ok, err = pcall(sampAddChatMessage, u8:decode(u8"Machinist: чит включён (автопилот: " ..
        (optEnabled.v and u8"он" or u8"выкл") .. u8", восстановлено функций: " ..
        tostring(restored) .. u8")"), 0xAAFFAA)
end

stopBot = function()
    -- v0.8.0: «Выключить чита» гасит ВСЕ функции разом: автопилот,
    -- принудительную кабину, автоведение, телеграм-уведомления, превышение
    -- и опрос Telegram. Перед выключением запоминаем, что было активно,
    -- чтобы кнопка «Включить чита» вернула всё в том же виде.
    local activeNow = optEnabled.v or optForceCab.v or optAutoDrive.v or
        optNotify.v or optOverspeed.v or optTgPoll.v
    if not activeNow then return end
    cheatOffState = {
        enabled = optEnabled.v,
        force_cab = optForceCab.v,
        auto_drive = optAutoDrive.v,
        notify = optNotify.v,
        overspeed = optOverspeed.v,
        tg_poll = optTgPoll.v,
    }
    optEnabled.v = false
    optForceCab.v = false
    optAutoDrive.v = false
    optNotify.v = false
    optOverspeed.v = false
    optTgPoll.v = false
    saveAll()
    -- Освобождаем газ/тормоз и сбрасываем состояние автопилота, чтобы поезд
    -- не продолжал движение после выключения (поток сам завершится: while
    -- optEnabled.v стал false).
    drive.keys = 0
    drive.phase = "IDLE"
    drive.lastAction = u8"чит выключен"
    drive.station_arrived = false
    drive.station_arrive_time = nil
    drive.station_left = false
    pcall(releaseKeysNative)
    local ok, err = pcall(sampAddChatMessage, u8:decode(u8"Machinist: чит выключен (все функции остановлены)"), 0xFFAAAA)
end

local function testTelegram()
    -- асинхронно: отправка в фоне не блокирует поток игры
    telegram.send_async(st.tg_bot_token, st.tg_chat_id, u8"Тест от MachinistByYaroRage v0.6.6")
    pcall(sampAddChatMessage, u8:decode(u8"Machinist: тестовое сообщение отправляется..."), 0xAAFFAA)
end

-- ---------- Управление через Telegram ----------
-- Команды бота (пишутся боту в личку):
--   /start  — включить автопилот
--   /stop   — выключить автопилот
--   /chat <текст> — отправить <текст> в игровой чат
--   /статус — прислать сводку состояния
-- Любое другое сообщение отправляется в игровой чат как обычная фраза.
local function tgReply(text)
    telegram.send_async(st.tg_bot_token, st.tg_chat_id, text)
end

local function handleTgCommand(text)
    if not text or #text == 0 then return end
    local t = text:gsub("^%s+", ""):gsub("%s+$", "")
    -- команда /chat <текст>
    if t:match("^/[Cc]hat%s") then
        local msg = t:match("^/[Cc]hat%s+(.*)$")
        if msg and #msg > 0 then
            -- sampSendChat ожидает кодировку по умолчанию (CP1251);
            -- текст из Telegram приходит в UTF-8, поэтому декодируем.
            pcall(sampSendChat, u8:decode(msg))
            tgReply(u8"[OK] Отправил в чат: " .. msg)
        end
        return
    end
    -- команда /start
    if t == "/start" or t == "/mqstart" then
        startBot()
        tgReply(u8"Автопилот включён")
        return
    end
    -- команда /stop
    if t == "/stop" or t == "/mqstop" then
        stopBot()
        tgReply(u8"Автопилот выключен")
        return
    end
    -- команда /статус
    if t == "/статус" or t == "/status" then
        local ph = phaseTitle[drive.phase] or drive.phase
        local line = u8"Фаза: " .. ph .. u8"\n"
        line = line .. u8"Действие: " .. drive.lastAction .. u8"\n"
        line = line .. u8"В кабине: " .. (inCabNow() and u8"да" or u8"нет") .. u8"\n"
        line = line .. u8"Скорость: " .. st.speed_range .. u8" км/ч, код " .. st.speed_code .. u8"\n"
        line = line .. u8"Станция: " .. ensureUtf8(st.station_name) .. u8", дистанция " .. st.station_dist .. u8" м\n"
        line = line .. u8"Деньги: " .. st.money
        tgReply(line)
        return
    end
    -- любое другое сообщение -> в игровой чат
    if not t:match("^/") then
        pcall(sampSendChat, u8:decode(t))
        tgReply(u8"Отправил в чат: " .. t)
    end
end

-- Поток опроса: опциональный, включается только флагом tg_poll_enable=1 в
-- config.ini. По умолчанию ВЫКЛЮЧЕН. Даже когда включён — НЕ блокирует
-- поток игры: getUpdates выполняется фоновым curl.exe (WinExec), а результат
-- просто читается из файла tg_tmp\\updates.json.
local tgOffset = 0
local tgPollThread = nil
local function tgPollLoop()
    while true do
        wait(5000)
        -- Выключение опроса из GUI: чекбокс сняли — поток тихо завершается
        if not st.tg_poll_enable then
            tgPollThread = nil
            print("[MachinistByYaroRage] Опрос Telegram остановлен (чекбокс снят)")
            return
        end
        -- 1) читаем ответ прошлого запроса (локально, мгновенно)
        local upd = telegram.read_updates()
        if type(upd) == "table" then
            for _, u in ipairs(upd) do
                local uid = u and u.update_id
                if uid then tgOffset = math.max(tgOffset, (tonumber(uid) or 0) + 1) end
                local msg = u and u.message
                local from = msg and msg.from
                local fromChat = msg and msg.chat
                local fromId = from and from.id or (fromChat and fromChat.id)
                local fromNick = from and from.username or (from and from.first_name) or ""
                -- реагируем только на сообщения от владельца (наш chat_id)
                if fromId and (tostring(fromId) == st.tg_chat_id or tostring(fromChat.id) == st.tg_chat_id) then
                    handleTgCommand(msg.text)
                end
            end
            telegram.clear_response()
        end
        -- 2) запускаем следующий опрос в фоне
        telegram.get_updates(st.tg_bot_token, tgOffset)
    end
end

function startTgPoll()
    if tgPollThread then return end
    if st.tg_bot_token == "" or st.tg_chat_id == "" then return end
    if not st.tg_poll_enable then
        print("[MachinistByYaroRage] Опрос Telegram отключён (tg_poll_enable=0 в config.ini)")
        return
    end
    tgPollThread = lua_thread.create(tgPollLoop)
    print("[MachinistByYaroRage] Опрос Telegram запущен (команды из лички бота работают)")
end

local function resetDrive()
    drive.phase = "IDLE"
    drive.lastAction = u8"сброс"
    drive.station_arrived = false
    drive.station_arrive_time = nil
    drive.station_left = false
    state_mod.reset()
end

-- ---------- main ----------
function main()
    repeat wait(0) until isSampAvailable()
    wait(500)

    state_mod.load_config()
    optEnabled.v = st.enabled
    optForceCab.v = st.force_cab
    optAutoDrive.v = st.auto_drive
    optNotify.v = st.notify_telegram
    optOverspeed.v = st.overspeed
    optTgPoll.v = st.tg_poll_enable
    inpToken.v = st.tg_bot_token
    inpChat.v = st.tg_chat_id

    print(string.format("[MachinistByYaroRage] v0.8.0 флаги: no_thread=%d no_events=%d no_gui=%d no_chat=%d tg_poll=%d dbg_log=%d force_cab=%d",
        st.dbg_no_thread and 1 or 0, st.dbg_no_events and 1 or 0,
        st.dbg_no_gui and 1 or 0, st.dbg_no_chat and 1 or 0, st.tg_poll_enable and 1 or 0,
        st.dbg_log and 1 or 0, st.force_cab and 1 or 0))

    if sampRegisterChatCommand then
        sampRegisterChatCommand("mq", toggleMenu)
        sampRegisterChatCommand("mqstart", startBot)
        sampRegisterChatCommand("mqstop", stopBot)
        sampRegisterChatCommand("mqtg", testTelegram)
        -- Показать реальный список админов, который использует детект.
        sampRegisterChatCommand("mqadmins", function()
            local list = admin.get_admin_names()
            local buf = {}
            for i, n in ipairs(list) do
                if i > 10 then buf[#buf + 1] = "..." break end
                buf[#buf + 1] = n
            end
            pcall(sampAddChatMessage, u8:decode(u8"Machinist: админов в списке: " .. tostring(#list) ..
                u8". Первые: " .. table.concat(buf, ", ")), 0xAAFFAA)
        end)
        -- Включить диагностику админ-детекта: следующие 8 сообщений любого
        -- источника (сервер, пузыри CEF, свои отправленные) пишутся в лог.
        sampRegisterChatCommand("mqdiag", function()
            chatDiagUntil = os.time() + 60
            chatDiagCount = 0
            pcall(sampAddChatMessage, u8:decode(u8"Machinist: диагностика чата включена на 60 сек (все сообщения с ником автора — в moonloader.log)"), 0xAAAAFF)
        end)
        sampRegisterChatCommand("mqids", function()
            local okCmd, errCmd = pcall(function()
                local cnt = 0
                for _ in pairs(knownIdNick) do cnt = cnt + 1 end
                local adminCnt = 0
                for _ in pairs(adminIdByCurrentId) do adminCnt = adminCnt + 1 end
                print("[MachinistByYaroRage] /mqids: knownIdNick=" .. tostring(cnt)
                    .. " admin=" .. tostring(adminCnt))
                local lines = {}
                lines[#lines + 1] = u8"Известно id->ник: " .. tostring(cnt)
                    .. u8"  Админов: " .. tostring(adminCnt)
                if next(adminIdByCurrentId) then
                    lines[#lines + 1] = u8"Админы:"
                    local sorted = {}
                    for id, nick in pairs(adminIdByCurrentId) do sorted[#sorted + 1] = id end
                    table.sort(sorted)
                    for _, id in ipairs(sorted) do
                        lines[#lines + 1] = "  [" .. tostring(id) .. "] " .. adminIdByCurrentId[id]
                        print("[MachinistByYaroRage]   admin [" .. tostring(id) .. "] " .. adminIdByCurrentId[id])
                    end
                else
                    lines[#lines + 1] = u8"Админов ещё нет (скан не нашёл)."
                end
                -- выводим каждую строку отдельным sampAddChatMessage, чтобы
                -- не зависеть от поддержки \n в отрисовке Radmir
                for _, ln in ipairs(lines) do
                    pcall(sampAddChatMessage, u8:decode(ln), 0xAAFFAA)
                end
            end)
            if not okCmd then
                print("[MachinistByYaroRage] /mqids ERROR: " .. tostring(errCmd))
            end
        end)
        -- Самопроверка цепочки уведомлений: прогоняет тестовое сообщение с
        -- админским ником через общий детектор. Живой чат не нужен — свои
        -- сообщения сервер не эхоирует, иначе цепочку не проверить.
        sampRegisterChatCommand("mqtest", function()
            processChatText(u8"тест", "(( Sonya_Tekilla: работаем ))", "", true)
        end)
    end

    -- Приветственное сообщение при загрузке скрипта: одна строка с ywelcome
    if not st.dbg_no_chat then
        ywelcome("MachinistByYaroRage", "Загружен. Команды: /mq — меню, /mqstart — старт, /mqstop — стоп, /mqtg — тест телеграма, /mqadmins — список админов, /mqdiag — диагностика чата")
    else
        print("[MachinistByYaroRage] приветствие пропущено (dbg_no_chat=1)")
    end

    if optEnabled.v and not drive.tickThread and not st.dbg_no_thread then
        drive.tickThread = lua_thread.create(driveThread)
    elseif st.dbg_no_thread then
        print("[MachinistByYaroRage] поток автопилота не создан (dbg_no_thread=1)")
    end

    startTgPoll()

    -- Главный цикл: никакой активной работы, когда меню закрыто.
    -- Хук imgui держим ТОЛЬКО пока окно /mq открыто (иначе конфликтуем
    -- с MechWork/MetalDetector за imgui.OnDrawFrame и грузим игру).
    local uiRecheck = 0
    local guiWasOpen = false
    local mainDiag = { ticks = 0, lastLog = os.clock(), lastTime = os.clock(),
                       lastWall = wallClockMs(), maxGapWall = 0 }
    while true do
        wait(0)
        mainDiag.ticks = mainDiag.ticks + 1
        -- wall-clock gap между тиками: если игра рисует 0.2 кадра/с, то
        -- wait(0) будет отдавать управление раз в ~5 секунд, и maxGapWall
        -- покажет это напрямую (тайминги GetTickCount, не CPU os.clock).
        local curWall = wallClockMs()
        local gapWall = curWall - mainDiag.lastWall
        if gapWall > mainDiag.maxGapWall then mainDiag.maxGapWall = gapWall end
        mainDiag.lastWall = curWall
        adminScanTick(curWall)
        local nowc = os.clock()
        if nowc - mainDiag.lastLog >= 5 then
            local span = nowc - mainDiag.lastTime
            if st.dbg_log then
            print(string.format(
                "[MachinistByYaroRage] main: %d тиков за %.1fс (%.1f/с), max wall-gap %.0f мс | save мс: %.0f",
                mainDiag.ticks, span, mainDiag.ticks / (span or 1), mainDiag.maxGapWall, saveDiagMs))
        end
            mainDiag.ticks = 0
            mainDiag.maxGapWall = 0
            saveDiagMs = 0
            mainDiag.lastLog = nowc
            mainDiag.lastTime = nowc
            mainDiag.lastWall = wallClockMs()
        end
        if showMenu.v and not st.dbg_no_gui then
            imgui.Process = true
            imgui.ShowCursor = true
            guiWasOpen = true
            uiRecheck = uiRecheck + 1
            if uiRecheck >= 30 then
                uiRecheck = 0
                ensureUiHook()
            end
        elseif guiWasOpen then
            -- меню только что закрыли (кнопка «Закрыть», крестик окна или /mq):
            -- возвращаем курсор и обработку мыши, сохраняем изменения полей
            guiWasOpen = false
            imgui.Process = false
            imgui.ShowCursor = false
            saveAll()
        end
        -- Автовключение потока автопилота: галочка «Автопилот» в меню (optEnabled)
        -- должна запускать ведение сразу, как и /mqstart. Без этого включение
        -- через GUI в уже работающем скрипте не создавало бы поток и поезд не ехал.
        if optEnabled.v and not drive.tickThread and not st.dbg_no_thread then
            drive.tickThread = lua_thread.create(driveThread)
        end
    end
end

-- ---------- GUI ----------
-- Функция отрисовки нашего окна. Глобальный imgui.OnDrawFrame в сборке
-- перекрывается другими скриптами (MechWork грузится последним и не зовёт
-- предыдущую), поэтому мы держим свою обёртку, пока окно /mq открыто:
-- сначала чужая функция, потом наша. При закрытом меню хук не трогаем вовсе,
-- чтобы не конфликтовать с MechWork/MetalDetector и не грузить игру.
local renderUi = function()
    local resX, resY = getScreenResolution()
    local nowUi = wallClockMs()
    if fscCache.resX ~= resX or fscCache.resY ~= resY or nowUi - fscCache.at >= 500 then
        -- пересчёт масштаба: сменилось разрешение или прошло 0.5 с (на случай смены DPI)
        local baseScale = resY / 1080
        local dpiFactor = 1
        do
            local ok, sysH = pcall(function() return ffi.C.GetSystemMetrics(1) end)
            if ok and type(sysH) == "number" and sysH > 0 then
                local physH = sysH * dpiUi
                if physH > resY * 1.05 then dpiFactor = dpiUi end
            end
        end
        fsc = baseScale * dpiFactor
        fscCache.resX, fscCache.resY, fscCache.at, fscCache.fsc = resX, resY, nowUi, fsc
    else
        fsc = fscCache.fsc
    end
    if imgui.GetIO() then
        imgui.GetIO().FontGlobalScale = fsc
    end

    if not showMenu.v then return end

    -- Окно по центру, размер от масштаба (как в CheatByYaroRage).
    local winW, winH = math.min(560 * fsc, resX - 20), math.min(640 * fsc, resY - 40)
    imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - winW / 2, resY / 2 - winH / 2), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.FirstUseEver)
    imgui.Begin(u8"MachinistByYaroRage", showMenu, imgui.WindowFlags.NoCollapse)

    local okBody, errBody = pcall(function()
        -- ---------- Вкладки (как в CheatByYaroRage) ----------
        local tabs = {
            u8"Общие",
            u8"Ведение",
            u8"Телеграм",
            u8"Статус",
        }
        local tabCount = #tabs
        local perRow = math.max(1, math.floor((winW - 16 * fsc) / (148 * fsc + 8 * fsc)))
        for i = 1, tabCount do
            local tabActive = menuTab.v == i
            if tabActive then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.15, 0.28, 0.22, 1))
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
            end
            if imgui.Button(tabs[i], imgui.ImVec2(148 * fsc, 30 * fsc)) then menuTab.v = i end
            if tabActive then
                imgui.PopStyleColor(2)
            end
            if i < tabCount then
                if i % perRow == 0 then imgui.NewLine() else imgui.SameLine() end
            end
        end
        imgui.Separator()

        -- ---------- Панель действий: вкл/выкл всё / сохранить / закрыть ----------
        -- v0.8.0: ШАПКА — кнопка выключает ВСЕ функции разом (автопилот,
        -- принудительная кабина, автоведение, телеграм-уведомления, превышение,
        -- опрос Telegram) и запоминает, что было активно. Повторное включение
        -- возвращает всё в том же виде. Цвет: зелёный — чит работает,
        -- красный — выключен.
        if optEnabled.v then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.22, 0.62, 0.30, 1))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
        else
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.72, 0.18, 0.15, 1))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
        end
        if imgui.Button(optEnabled.v and u8"Выключить чита" or u8"Включить чита",
                        imgui.ImVec2(240 * fsc, 34 * fsc)) then
            if optEnabled.v then stopBot() else startBot() end
        end
        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Выключает вообще все функции скрипта (автопилот, кабина, ведение, телеграм, превышение, опрос Telegram); повторное включение возвращает их в прежнем виде")
        end
        imgui.Separator()
        if imgui.Button(u8"Сохранить", imgui.ImVec2(200 * fsc, 30 * fsc)) then
            saveAll()
            pcall(sampAddChatMessage, u8:decode(u8"Machinist: настройки сохранены"), 0xAAFFAA)
        end
        imgui.SameLine()
        if imgui.Button(u8"Закрыть", imgui.ImVec2(200 * fsc, 30 * fsc)) then
            -- закрываем меню ДО сохранения: даже если запись конфига упадёт,
            -- окно обязано закрыться (раньше saveAll кидал ошибку и окно оставалось)
            showMenu.v = false
            pcall(saveAll)
        end
        imgui.Separator()

        -- ---------- Общие ----------
        if menuTab.v == 1 then
            if imgui.Checkbox(u8"Автопилот", optEnabled) then end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Управляет поездом CEF-пакетами (работает и при свёрнутой игре)")
            end
            if imgui.Checkbox(u8"Принудительно в кабине", optForceCab) then end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Включать автопилот, даже если кабина не определена по CEF-пакетам 'Machinist'")
            end
            if imgui.Checkbox(u8"Автоведение W/S по подсказкам сервера", optAutoDrive) then end
            if imgui.Checkbox(u8"Уведомления в телеграм (админы и окна)", optNotify) then end
            imgui.TextWrapped(u8"Горячая клавиша меню — /mq")

        -- ---------- Ведение ----------
        elseif menuTab.v == 2 then
            imgui.TextWrapped(u8"Ведение: порт mashinist.lua. Скорость реальная (getCarSpeed), цель — чекпоинт сервера или дистанция до станции из setStation. Остановка по формуле stop_distance.")
            imgui.TextWrapped(u8"Мин/макс скорость: " .. st.speed_range .. u8" км/ч (код " .. st.speed_code .. u8")")
            imgui.Checkbox(u8"Превышать скорость", optOverspeed)
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Ехать выше вилки сервера (превышение рассчитывается само по таймеру штрафа) и за секунду до останова таймера тормозить обратно в вилку")
            end

        -- ---------- Телеграм и админы ----------
        elseif menuTab.v == 3 then
            imgui.PushItemWidth(280 * fsc)
            imgui.InputText(u8"Токен бота", inpToken)
            imgui.InputText(u8"Chat ID", inpChat)
                        imgui.Separator()
            imgui.TextWrapped(u8"Администраторы:")
            imgui.PushItemWidth(160 * fsc)
            imgui.InputText(u8"Ник админа", inpAdmins)
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(u8"Добавить админа", imgui.ImVec2(120 * fsc, 0)) then
                state_mod.append_admin_names(inpAdmins.v)
                inpAdmins.v = ""
                admin.invalidate()
            end
            imgui.SameLine()
            if imgui.Button(u8"Обновить весь список", imgui.ImVec2(170 * fsc, 0)) then
                admin.invalidate()
            end
            imgui.Separator()
            imgui.TextWrapped(u8"Список админов (крестик удаляет из списка):")
            imgui.BeginChild("admlist", imgui.ImVec2(300 * fsc, 160 * fsc), true)
            local adminsGui = admin.get_admin_names()
            local toRemove = nil
            if #adminsGui == 0 then
                imgui.Text(u8"Список пуст")
            end
            for i, nick in ipairs(adminsGui) do
                imgui.PushID(i)
                imgui.Text(nick)
                imgui.SameLine()
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.9, 0.25, 0.2, 1))
                if imgui.SmallButton(u8"X") then toRemove = nick end
                imgui.PopStyleColor()
                imgui.PopID()
            end
            imgui.EndChild()
            if toRemove then
                state_mod.remove_admin_name(toRemove)
                admin.invalidate()
            end
            imgui.TextWrapped(u8"Путь: moonloader\\MachinistByYaroRage\\config\\CheatAdminList.txt")
            imgui.Checkbox(u8"Опрос Telegram (ответы через чат)", optTgPoll)
            if imgui.Button(u8"Тест телеграма", imgui.ImVec2(200 * fsc, 30 * fsc)) then
                saveAll()
                startTgPoll()
                testTelegram()
            end

        -- ---------- Статус ----------
        elseif menuTab.v == 4 then
            imgui.TextWrapped(u8"Статус:")
            local ph = phaseTitle[drive.phase] or drive.phase
            imgui.Text(u8"Фаза: " .. ph .. u8" | В поезде: " .. (inTrainNow() and u8"да" or u8"нет") .. u8" | В кабине: " .. (inCabNow() and u8"да" or u8"нет"))
            imgui.Text(u8"Действие: " .. drive.lastAction)
            imgui.Text(u8"Скорость (рекомендация): " .. st.speed_range .. u8", код " .. st.speed_code)
            imgui.Text(u8"Прогноз остановки: " .. string.format("%.0f", drive.stop_preview) .. u8" м")
            if st.speed_est and st.speed_est > 0 then
                imgui.Text(u8"Скорость (оценка): " .. string.format("%.1f", st.speed_est * 3.6) .. u8" км/ч")
            end
            imgui.Text(u8"Станция: " .. ensureUtf8(st.station_name) .. u8", дистанция " .. st.station_dist .. u8" м")
            imgui.Text(u8"Деньги: " .. st.money)
            local sem = table.concat(st.semaphores or {}, ",")
            imgui.Text(u8"Семафоры: [" .. sem .. u8"]")
            if st.info_timer and #st.info_timer > 0 then
                imgui.Text(u8"Подсказка: " .. ensureUtf8(st.info_timer))
            end
        end
    end)
    -- Безусловный End: даже если тело бросило исключение, стек окон сходится
    -- (иначе на следующем кадре MoonImGui упадёт с "Mismatched Begin/End").
    imgui.End()
    if not okBody then
        local now = os.clock()
        if now - lastGuiErrPrint >= 5 then
            lastGuiErrPrint = now
            print("[MachinistByYaroRage] Ошибка отрисовки GUI: " .. tostring(errBody))
        end
    end
end

-- Обёртка: вызывает чужую функцию (если кто-то её поставил), затем нашу.
-- Всё обёрнуто в pcall: если любое исключение уйдёт наверх, on_draw_scene
-- в lib/imgui.lua не выполнит renderer:EndFrame() и imgui-контекст будет
-- сломан (игра зависнет на следующем кадре). Флаг inWrapper всегда сбрасывается.
local inWrapper = false
uiWrapper = function()
    if inWrapper then return end
    inWrapper = true
    if prevOnDraw then
        local ok, err = pcall(prevOnDraw)
        if not ok then prevOnDraw = nil end
    end
    local ok, err = pcall(renderUi)
    inWrapper = false
    if not ok then
        local now = os.clock()
        if now - lastGuiErrPrint >= 5 then
            lastGuiErrPrint = now
            print("[MachinistByYaroRage] Ошибка отрисовки GUI: " .. tostring(err))
        end
    end
end

-- Ставит нашу обёртку в глобальный callback и запоминает предыдущую функцию.
-- Вызывается из toggleMenu при ОТКРЫТИИ меню и из main каждые N тиков, чтобы
-- вернуть хук себе, если другой скрипт перекрыл его во время работы окна.
function ensureUiHook()
    local cur = imgui.OnDrawFrame
    if cur ~= uiWrapper then
        if cur ~= uiWrapper then prevOnDraw = cur end
        imgui.OnDrawFrame = uiWrapper
    end
end
