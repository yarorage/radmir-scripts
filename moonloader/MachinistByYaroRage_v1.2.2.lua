-- MachinistByYaroRage v1.0.2
-- v1.0.2 — СТОЯНКА ТОЛЬКО ДО КОМАНДЫ СЕРВЕРА (фикс «уезжает мимо станции»):
--   1) раньше состав отправлялся сам через dwell (5 с) — то есть УЕЗЖАЛ со
--      станции ДО команды, и следующий таймер «Остановитесь на станции» уже
--      не мог его вернуть (дистанция переключалась на следующую станцию, и
--      торможение по ней не работало). Теперь едем с места только по
--      «Увеличьте скорость» (goCmd); автоотправление — лишь аварийное, через
--      st.station_release_delay (30 с) и только когда команд нет вообще;
--   2) докрутка больше НЕ сдвигает уже стоящий состав: без серверной команды
--      она начинается только если состав ещё катится (speed > 3), поэтому
--      «набрал 10 км/ч, поехал вперёд и уехал» больше не повторяется;
--   3) если пришёл «Остановитесь на станции», а дистанция setStation уже
--      переключилась на следующую станцию (проехали), тормозим сразу в пол —
--      не проезжаем станцию из-за «дальней» дистанции.
-- v0.9.7 — ДОКРУТКА ЗА СТОП-ТОЧКУ СТАНЦИИ: состав больше не встаёт ПЕРЕД
-- серверным триггером станции. Когда он замедлился у станции (команда
-- «Остановитесь на станции» / «Ожидайте отправления» либо серверная дистанция
-- подошла к нулю), он проезжает ещё stop_overshoot метров (по умолчанию 50)
-- на скорости stop_crawl км/ч (по умолчанию 10) — ровно настолько, чтобы
-- пересечь триггер и станция засчиталась, — и только потом встаёт.
-- v0.9.6 — ПОЛНОСТЬЮ БЕЗНАТИВНЫЙ КАДРОВЫЙ ПУТЬ (фикс фризов В ПОЕЗДЕ) и рабочая
-- логика серверных таймеров:
--   1) из driveTick убраны ВСЕ нативные game-вызовы (storeCarCharIsInNoSave,
--      getCarSpeed, getCharCoordinates, getDistanceBetweenCoords3d, setTrainSpeed) —
--      на MoonRage каждый такой вызов вешает поток SAMP на ~900-1000 мс, поэтому
--      «при появлении поезда всё безбожно лагало». Скорость считается по убыванию
--      дистанции setStation (st.speed_est, пакет раз в секунду), дистанция —
--      st.station_dist, газ/тормоз/keysData пишутся напрямую (клавиши + память);
--   2) починен парсер InformationTimer: реальный формат «InformationTimer ["...",N,0]»
--      содержит пробел и перевод строки, старый паттерн их не допускал и f.info_timer
--      был всегда nil — таймеры штрафа/остановки не работали. Теперь храним дедлайн;
--   3) станция: всю дорогу едем «в пол» (максимум вилки), у станции — позднее
--      плавное торможение по физической кривой, без «ползания» 1 км/ч за 50 м.
-- Автопилот машиниста метро (Radmir CRMP).
-- Персонаж уже сидит в поезде и НЕ выходит: смены идут кругами
-- (Союзная <-> Больничная), автопилот только ведёт состав.
-- Управление идёт БЕЗНАТИВНО по логике рабочего mashinist.lua: газ =
-- setGameKeyState(16,255), тормоз = setGameKeyState(14,255) + writeMemory(0xB73458+0x1C),
-- а направление считается по знаку оценённой скорости (st.speed_est) и пишется в
-- keysData исходящего vehicle sync (0x08 accel вперёд / 0x20 decel назад / 0 стоп).
-- Гейт всего блока — безнативный CEF-детект inCabNow(): вне поезда (в обычной машине)
-- пакетов интерфейса 'Machinist' нет, скрипт не трогает ни клавиши, ни keysData, ни
-- нативные вызовы (иначе в обычном авто не заводился двигатель и были фризы).
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
script_version("1.2.2")
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
local optNotify = imgui.ImBool(st.notify_telegram)
local optOverspeed = imgui.ImBool(st.overspeed)
local optSpeedMult = imgui.ImFloat(st.speed_mult and st.speed_mult > 0 and st.speed_mult or 1.0)
local optSpeedBoost = imgui.ImFloat(st.speed_boost and st.speed_boost > 1.0 and st.speed_boost or 1.0)
local optTgPoll = imgui.ImBool(st.tg_poll_enable)
local inpToken = imgui.ImBuffer(128)
local inpChat = imgui.ImBuffer(64)
local inpAdmins = imgui.ImBuffer(512)
local inpMyNick = imgui.ImBuffer(64)   -- ник собственного персонажа (v1.2.1)
inpToken.v = st.tg_bot_token
inpChat.v = st.tg_chat_id
inpMyNick.v = st.my_nick
-- Номер открытой вкладки меню (как в CheatByYaroRage: кнопки-вкладки сверху).
local menuTab = imgui.ImInt(1)

-- ---------- Рабочее состояние автопилота ----------
-- ---------- Автопилот: состояния ----------
local drive = {
    tickThread = nil,
    lastAction = "Нет",
    phase = "IDLE",
    stopped = false,
    station_arrived = false,
    station_arrive_time = nil,
    station_left = false,
    in_cab = false,
    in_train = false,
    keys = 0,
    stop_preview = 0,
    crawl_start = nil,
    crawl_done = false,
    -- Overspeed (превышение скорости)
    overspeed_active = false,
    overspeed_until = 0,
    overspeed_target_speed = 0,
    overspeed_brake_started = false,
    -- Station stop timer (остановка на станции N сек)
    station_stop_active = false,
    station_stop_until = 0,
    station_stop_duration = 0,
    station_stop_force_brake = false,
}

-- Диагностика времени БД-записи конфига (мс, символ "s" в строке лога).
local saveDiagMs = 0
local lastSavedSig = nil
local startTgPoll -- forward declaration (saveAll поднимает опрос при включении)

local function saveAll()
    -- Ленивое сохранение: если значения не менялись с прошлой записи,
    -- НЕ трогаем файлы вовсе (запись INI + CheatAdminList.txt может быть
    -- очень дорогой на этой машине и вешать кадр).
    local sig = table.concat({ tostring(optEnabled.v), tostring(optForceCab.v), tostring(optNotify.v),
        tostring(optOverspeed.v),
        tostring(optTgPoll.v),
        tostring(optSpeedMult.v),
        tostring(optSpeedBoost.v),
        tostring(inpToken.v), tostring(inpChat.v), tostring(inpAdmins.v), tostring(inpMyNick.v) })
    if sig == lastSavedSig then return false end
    lastSavedSig = sig
    local saveT = os.clock()
    st.enabled = optEnabled.v
    st.force_cab = optForceCab.v
    st.notify_telegram = optNotify.v
    st.overspeed = optOverspeed.v
    st.speed_mult = optSpeedMult.v and optSpeedMult.v > 0 and optSpeedMult.v or 1.0
    st.speed_boost = optSpeedBoost.v and optSpeedBoost.v > 1.0 and optSpeedBoost.v or 1.0
    st.tg_poll_enable = optTgPoll.v
    st.tg_bot_token = inpToken.v
    st.tg_chat_id = inpChat.v
    st.my_nick = (inpMyNick.v or ""):gsub("^%s+", ""):gsub("%s+$", "")
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
-- v0.9.1: /mqstop и кнопки «Автопилот» выключают ТОЛЬКО автопилот
-- (optEnabled). Раньше здесь жил снимок всех функций, который
-- восстанавливался при включении — из-за него уведомление об
-- админе гасило весь чит. Теперь снимок не нужен: функции не трогаются.

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
-- v1.1.2: дедуп уведомлений: одинаковые админ-вызовы, пришедшие разными
-- источниками (пузырь, сервер, чатлог), не слать в Telegram повторно.
-- Ключ = ник админа + текст; окно 45 сек, максимум 20 записей.
local recentNoticeKeys = {}

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
                admin.is_admin_message(text, st.my_nick)
    -- матч по автору пузыря (ник других игроков, если sampGetPlayerNameById доступен)
    if not who and authorNick and #authorNick > 0 then
        local known = admin.has_known_admin(authorNick)
        if known then who = known end
    end
    if not who then return end

    -- v1.1.2: дедуп повторных уведомлений
    local dupKey = tostring(who) .. "|" .. tostring(text)
    local nowDup = os.time()
    local dupFound = false
    for i = #recentNoticeKeys, 1, -1 do
        local it = recentNoticeKeys[i]
        if nowDup - it[2] > 45 then
            table.remove(recentNoticeKeys, i)
        elseif it[1] == dupKey then
            dupFound = true
        end
    end
    if dupFound then return end
    recentNoticeKeys[#recentNoticeKeys + 1] = { dupKey, nowDup }
    if #recentNoticeKeys > 20 then table.remove(recentNoticeKeys, 1) end
    sendTg(u8"ВНИМАНИЕ! В чате админ!\nКто: " .. ensureUtf8(who) .. u8"\nСообщение: " .. ensureUtf8(text))
    -- v0.9.1: stopBot() здесь убран — уведомление об админе больше не
    -- выключает чит; все функции продолжают работать.
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

-- v1.2.1: определение ника собственного персонажа через SAMP. Возвращает
-- ник или nil (SAMP недоступен / персонаж ещё не загружен). Используется
-- кнопкой «Автоопределить ник» в GUI вкладки «Телеграм».
local function detectMyNick()
    if not isSampAvailable() then return nil end
    local okMy, isMy, myId = pcall(sampGetPlayerIdByCharHandle, PLAYER_PED)
    if not okMy or not isMy or type(myId) ~= "number" or myId < 0 then return nil end
    local okN2, myNick = pcall(sampGetPlayerNickname, myId)
    if okN2 and type(myNick) == "string" and #myNick > 0 and myNick ~= "N/A" then
        return myNick
    end
    return nil
end

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
            -- v1.2.1: НЕ перезаписываем st.my_nick — ник собственного
            -- персонажа задаётся в GUI и хранится в конфиге (my_nick)
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
        -- детект админа в голосовом канале (v.nick — чистый ник, без текста)
        if optNotify.v and st.tg_bot_token ~= "" and st.tg_chat_id ~= "" then
            local who = admin.has_known_admin(v.nick or "")
            if who then
                local now = os.time()
                if now - voiceNotice.last >= 25 or v.id ~= voiceNotice.lastId then
                    voiceNotice.last = now
                    voiceNotice.lastId = v.id
                    sendTg(u8"ВНИМАНИЕ! Админ говорит в голосовом чате\nКто: " .. ensureUtf8(who))
                    -- v0.9.1: stopBot() убран — голосовой админ больше не выключает чит
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
    -- v0.9.2: parse_window_open вернул таблицу { sig, short, long }:
    -- short — короткая строка для игрового чата, long — подробное
    -- содержимое окна (заголовок, кнопки, текст) для Telegram.
    local sig = (type(desc) == "table" and desc.sig) or tostring(desc)
    if sig == windowNotice.lastSig then return end
    local nowT = os.time()
    if nowT - windowNotice.last < windowNotice.cooldown then return end
    windowNotice.last = nowT
    windowNotice.lastSig = sig
    local short = (type(desc) == "table" and desc.short) or tostring(desc)
    local long = (type(desc) == "table" and desc.long) or tostring(desc)
    -- всегда сообщаем в игровом чате (короткая строка)
    pcall(sampAddChatMessage, u8:decode(u8"Machinist: открылось окно — " .. ensureUtf8(short)), 0xFFFFAA)
    -- и подробное содержимое в телеграм, если включены уведомления
    if optNotify.v and st.tg_bot_token ~= "" and st.tg_chat_id ~= "" then
        local body = ensureUtf8(long)
        if #body > 3800 then body = body:sub(1, 3800) .. u8"\n… (обрезано)" end
        sendTg(u8"ОТКРЫЛОСЬ ОКНО:\n" .. body)
    end
    print("[MachinistByYaroRage] Окно-детект: " .. long)
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
    if not isSampAvailable() then return end
    -- v1.1.1: резервный тик из ВХОДЯЩЕГО сетевого потока. При полностью свёрнутом
    -- окне кадровый поток (wait(0)) и резерв из onSendVehicleSync молчат — игра
    -- редко генерирует кадры и исходящие синки. А RX-пакеты приходят всегда,
    -- независимо от рендера, поэтому ведение продолжается: состав не остаётся
    -- со старым keysData, не «едет сам», разгоняется и тормозит вовремя.
    if not st.dbg_no_thread and optEnabled.v then
        local rxtMs = wallClockMs()
        if rxtMs - (drive._lastTickMs or 0) >= 200 then
            driveTick()
        end
    end
    if id ~= 215 then return end

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
        -- через processChatText: telegram-уведомление (v0.9.1: чит при этом не выключается).
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
                st.speed_est_at = nowMs
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
    -- Информация о таймере-подсказке сервера (остановка/отправление).
    if f.info_timer then
        st.info_timer = f.info_timer
        st.info_timer_sec = f.info_timer_sec
        -- v0.9.6: дедлайн активности таймера — команда живёт N секунд
        -- (по умолчанию 15), после чего в driveTick она гаснет.
        st.info_timer_until = os.time() + (f.info_timer_sec and f.info_timer_sec > 0
            and f.info_timer_sec or 15)
    end
    -- v1.1.0: учёт таймера штрафа за превышение. Сервер ловит превышение вилки
    -- и запускает InformationTimer «Увеличьте скорость до штрафа», N секунд.
    -- Пока такой таймер активен, fineActive в driveTick вернёт скорость к вилке.
    if st.overspeed and f.info_timer then
        if f.info_timer:find("штраф", 1, true) then
            local sec = f.info_timer_sec or 15
            local remaining = st.overspeed_timer > 0 and (st.overspeed_timer - os.time()) or 0
            if st.overspeed_timer == 0 or st.overspeed_timer <= os.time() or sec < remaining then
                st.overspeed_fine = true
                st.overspeed_timer = os.time() + sec
                -- v1.1.5: запоминаем полную длительность окна штрафа, чтобы
                -- driveTick мог сбрасывать скорость равномерно на весь таймер.
                st.overspeed_timer_total = sec
            end
        else
            st.overspeed_fine = false
            st.overspeed_timer = 0
            st.overspeed_timer_total = 0
        end
    end
    --
end

-- v1.1.4: спидхак поезда. Адреса из SA Memory (BlastHack):
--   0xBA18FC = CVehicle ** (локальный транспорт игрока),
--   nVehicleClass на +0x590 (6 = поезд), fTrainSpeed (float) на +0x5A4.
-- Умножаем fTrainSpeed каждый газ-тик, но не выше целивый скорости
-- (allowed в м/с) — поезд реально разгоняется в N раз быстрее.
local function applyTrainBoost(limitMs)
    if not limitMs or limitMs <= 0 then return end
    local boost = (st.speed_boost and st.speed_boost > 1.0) and st.speed_boost or 1.0
    if boost <= 1.0 then return end
    local ok, vehPtr = pcall(readMemory, 0xBA18FC, 4, false)
    if not ok or not vehPtr or tonumber(vehPtr) == 0 then return end
    vehPtr = tonumber(vehPtr)
    local okC, cls = pcall(readMemory, vehPtr + 0x590, 4, false)
    if not okC or tonumber(cls) ~= 6 then return end -- не поезд
    local fts = ffi.cast("float*", vehPtr + 0x5A4) -- fTrainSpeed
    local cur = fts[0]
    -- v1.1.9: спидхак включается только когда состав РЕАЛЬНО катится вперёд
    -- (fTrainSpeed > 1 м/с примерно 3.6 км/ч). Раньше порог стоял на оценке
    -- скорости из setStation (speed >= 10), которая приходит раз в секунду и
    -- запаздывает на разгоне — поэтому спидхак «не работал». Защиту от разгона
    -- на стоянке держим по памяти: пока поезд стоит (fTrainSpeed около нуля)
    -- не трогаем, чтобы не накопить скорость на месте и не «выстрелить»
    -- назад/вперёд при отправлении.
    if cur <= 1.0 then return end
    local nv = cur * boost
    if nv > limitMs then nv = limitMs end
    if nv > cur then fts[0] = nv end
end

-- v1.2.2: жёсткий фриз поезда: принудительно держим fTrainSpeed = 0 через
-- память (как applyTrainBoost, только в ноль). Мгновенно гасит любую скорость
-- -- состав встаёт ровно там, где сервер прислал команду «Остановитесь на
-- станции», и не катится (ни вперёд, ни назад) при отпущенных клавишах.
local function hardFreezeTrain(active)
    if not active then return end
    local ok, vehPtr = pcall(readMemory, 0xBA18FC, 4, false)
    if not ok or not vehPtr or tonumber(vehPtr) == 0 then return end
    vehPtr = tonumber(vehPtr)
    local okC, cls = pcall(readMemory, vehPtr + 0x590, 4, false)
    if not okC or tonumber(cls) ~= 6 then return end -- не поезд
    local fts = ffi.cast("float*", vehPtr + 0x5A4)
    if fts[0] ~= 0 then fts[0] = 0 end
end

-- Нажать газ (игровая клавиша W), как в mashinist.lua — без writeMemory.
local function pressGasNative()
    -- Газ — только игровая клавиша W. Accel для сервера уходит через
    -- drive.keys в onSendVehicleSync (сам CEF-газ поезд не двигает).
    drive._gasPressed = true
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

-- v0.9.6: тормоз с заданным уровнем (0..255) — игровая клавиша S + прямая запись
-- в память (как press_brake в mashinist.lua, но с плавным уровнем).
local function setBrakeLevel(level)
    if level < 0 then level = 0 end
    if level > 255 then level = 255 end
    pcall(writeMemory, 0xB73458 + 0x1C, 1, level, false)
    pcall(setGameKeyState, 14, level)
end

-- v0.9.6: полностью отпустить тормоз.
local function releaseBrake()
    pcall(writeMemory, 0xB73458 + 0x1C, 1, 0, false)
    pcall(setGameKeyState, 14, 0)
end

-- ---------- Хук серверного чата (совместимость) ----------
-- Детект сообщений админов -> уведомление в телеграм и остановка автопилота.
-- Глобальный хук: вызывается MoonLoader'ом при каждом чат-сообщении сервера.
-- На Radmir серверный чат сюда НЕ приходит (основной поток — в пузырях CEF и
-- в собственных отправленных сообщениях), хук оставлен для совместимости.
function onServerMessage(color, text)
    processChatText("сервер", text)
end

-- Проверка, что локальный игрок находится в кабине локомотива.
-- Основной сигнал — свежие RX-пакеты интерфейса 'Machinist' (setSpeed /
-- setSemaphoreState и т.п.): они приходят ~раз в 1-2 сек, пока интерфейс
-- кабины открыт. Любой такой пакет = мы в кабине, держим флаг ещё
-- cab_timeout секунд. Нативный isCharInAnyCar() НЕ используется (на движке
-- MoonRage его вызов вешает SAMP-поток на ~1.2 сек).
local function inCabNow()
    -- Принудительный режим (force_cab): считаем, что мы в кабине всегда —
    -- автопилот стартует и ведёт, даже если CEF-пакеты 'Machinist' не приходят.
    if st.force_cab then return true end
    return st.in_cab and (os.time() - st.last_pkt_time) <= st.cab_timeout
end

-- Нативно ли игрок в поезде (гейт всего автопилота).
-- v0.9.5: НАТИВНЫЙ isCharInAnyTrain УБРАН ПОЛНОСТЬЮ. На движке MoonRage
-- каждый нативный game-вызов вешает поток SAMP на ~900-1000 мс (замер
-- v0.5.7), и даже опрос 5 раз/с (кэш v0.9.4) в обычной машине давал
-- постоянные фризы — поэтому v0.9.4 «не помог». Теперь «в поезде» =
-- безнативный CEF-детект inCabNow(): кабина активна, пока приходят свежие
-- RX-пакеты интерфейса 'Machinist' (каждые 1-2 с, cab_timeout). В обычной
-- машине интерфейса нет — пакетов нет — гейт мгновенно false, скрипт не
-- вызывает ни клавиш, ни keysData, ни нативных game-вызовов. Ноль фризов.
local function inTrainNow()
    return inCabNow()
end

-- Целевой чекпоинт: сервер ставит race checkpoint по маршруту состава.
local driveCp = { x = 0, y = 0, z = 0 }
local driveCpFinish = false

-- Хук исходящего vehicle sync: подкладываем keysData (как в mashinist.lua).
-- Патчим ТОЛЬКО когда автопилот включён и игрок реально в поезде — иначе
-- в обычном автомобиле подмена keysData ломает движение/запуск двигателя.
if ev then
    function ev.onSendVehicleSync(data)
        if type(data) ~= "table" then return end
        if not optEnabled.v then return end
        -- v0.9.0: резервный тик из исходящего vehicle sync. Если кадровый
        -- поток давно не тикал (свёрнутое окно, фриз, wall-gap >= 200 мс) —
        -- ведём состав прямо здесь: сетевые пакеты идут всегда, газ/тормоз
        -- пишутся нативно, keysData освежается перед самой отправкой.
        local nowMs = wallClockMs()
        if nowMs - (drive._lastTickMs or 0) >= 200 then
            driveTick()
        end
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
--   inCabNow()       -> drive.in_train (безнативный CEF-гейт кабины)
--   bot.distance     -> st.station_dist (дистанция до станции из setStation)
--   bot.speed.min/max-> st.speed_lo/st.speed_hi (вилка setSpeed, км/ч)
--   checkpoint       -> driveCp (чекпоинт сервера, если есть)
-- Цикл идёт КАЖДЫЙ кадр (wait(0)), как в эталоне, а не по tap_interval —
-- газ/тормоз должны держаться постоянно, а не раз в 150-450 мс.
-- ТИК АВТОПИЛОТА — ОДИН ПРОХОД ВЕДУЩЕГО ЦИКЛА (порт из mashinist.lua).
-- v0.9.6: полностью БЕЗНАТИВНЫЙ кадровый путь. Раньше каждый кадр звались
-- storeCarCharIsInNoSave / getCarSpeed / getCharCoordinates /
-- getDistanceBetweenCoords3d / setTrainSpeed; на движке MoonRage КАЖДЫЙ такой
-- вызов вешает поток SAMP на ~900-1000 мс — поэтому «при появлении поезда всё
-- безбожно лагало». Теперь все данные берутся из CEF-пакетов (скорость —
-- st.speed_est по убыванию дистанции setStation, дистанция — st.station_dist,
-- команды — таймеры InformationTimer), а газ/тормоз/keysData пишутся напрямую.
local function driveTick()
    if st.dbg_no_thread then return end
    drive._lastTickMs = wallClockMs()
    drive._gasPressed = false

    -- Вне поезда не трогаем ничего (кабина — только по свежим CEF-пакетам).
    local inTrain = inTrainNow()
    drive.in_train = inTrain
    if not inTrain then
        if drive.phase == "DRIVE" or drive.phase == "STOP" then
            drive.phase = "IDLE"
        end
        drive.keys = 0
        drive._useTarget = 0
        drive.lastAction = u8"вне поезда"
        return
    end
    drive.phase = "DRIVE"
    drive.lastAction = u8"ведение"

    -- ---------- Телеметрия из CEF (ноль нативных вызовов) ----------
    -- Оценка скорости приходит раз в секунду (setStation), держим её 2.5 с:
    -- если пакеты пропали (выход из сети/кабины) — считаем, что состав стоит.
    local nowMs = wallClockMs()
    local speed = 0
    if st.speed_est and st.speed_est > 0 and st.speed_est_at
        and (nowMs - st.speed_est_at) <= 2500 then
        speed = st.speed_est * 3.6
    end
    -- Серверное «Увеличьте скорость» снимаем, как только состав реально поехал.
    if st.need_go and speed >= math.max(5, (st.speed_lo or 0) * 0.8) then
        st.need_go = false
    end
    -- Начало движения сбрасывает флаги стоянки (защита от «зацикливания»).
    if speed >= 10 then
        drive.station_arrived = false
        drive.station_arrive_time = nil
        drive.station_left = false
    end
    local stationKnown = st.station_dist and st.station_dist >= 0
    local distance = stationKnown and st.station_dist or 99999
    local speedMs = math.max(0, speed / 3.6)

    -- ---------- Вилка сервера и обычная цель ----------
    -- Цель вне спецрежимов — максимум вилки минус 1 км/ч («топтать в пол»).
    local vLo = (st.speed_lo and st.speed_lo > 0) and st.speed_lo or 0
    local vHi = (st.speed_hi and st.speed_hi > 0) and st.speed_hi
        or (vLo > 0 and vLo or 40)
    local target = (vHi > 1) and (vHi - 1) or vHi
    -- Fix: target speed = max - 1 km/h
    target = (st.speed_hi and st.speed_hi > 0) and (st.speed_hi - 1) or target
    -- v1.1.3: множитель целевой скорости (GUI «Ведение»). Умножаем target:
    -- поезд дольше держит газ и активнее набирает скорость (выше вилки).
    -- Осознанный риск: сервер штрафует за превышение скоростного режима.
    local speedMult = (st.speed_mult and st.speed_mult > 0.5 and st.speed_mult < 5) and st.speed_mult or 1.0
    if speedMult > 1.0 and target > 5 then
        target = target * speedMult
    end

    -- ---------- Активные серверные таймеры ----------
    -- Активность считаем по дедлайну info_timer_until: сервер шлёт текст ОДИН
    -- раз, а следом идут пустые InformationTimer, которые его вытесняли.
    local nowSec = os.time()
    local timerActive = st.info_timer and st.info_timer ~= ""
        and st.info_timer_until and st.info_timer_until >= nowSec
    local timerText = timerActive and st.info_timer or ""
    local stopCmd = timerText ~= "" and timerText:find("Остановитесь", 1, true) ~= nil
    local stayCmd = timerText ~= "" and (timerText:find("Ожидайте отправления", 1, true) ~= nil
        or timerText:find("Садитесь в поезд", 1, true) ~= nil)
    -- goCmd — «Увеличьте скорость» БЕЗ «до штрафа»: штрафной таймер превышения
    -- («Увеличьте скорость до штрафа») не должен превращаться в разгон.
    local goCmd = timerText ~= "" and timerText:find("Увеличьте скорость", 1, true) ~= nil
        and timerText:find("до штрафа", 1, true) == nil
    local fineActive = st.overspeed_fine and st.overspeed_timer
        and st.overspeed_timer > nowSec
    -- v1.2.0: последние 3 секунды таймера штрафа — жёсткий сброс к вилке.
    local fineLeft = fineActive and math.max(0, st.overspeed_timer - nowSec) or 0
    local fineLast = fineActive and fineLeft <= 3

    -- ---------- Физика торможения ----------
    local brakeA = (st.brake_decel and st.brake_decel > 0) and st.brake_decel or 2.0
    local aComf = math.max(0.6, brakeA * 0.8)
    local brakeMargin = (st.brake_margin and st.brake_margin >= 0) and st.brake_margin or 6
    -- v1.1.9: подход к станции: за последние 250 м разрешено не больше
    -- 90 км/ч, выше лимита — экстренный полный тормоз (lvl 255).
    local stationCapDist = 250
    local stationCapKmh = 90

    local allowed = target
    local finePause = (not fineActive) and st.overspeed_timer and st.overspeed_timer > 0
        and (nowSec - st.overspeed_timer) < math.max(4, (st.overspeed_guard or 1) + 3)
    -- Режим «Превышать скорость»: топим выше вилки, но не выше скорости, которую
    -- успеем плавно сбросить обратно за типовое окно таймера штрафа (12 с).
    if st.overspeed and not fineActive and not finePause then
        local vCeil = vHi + brakeA * 0.8 * 12 * 3.6
        allowed = math.max(target, math.min(vHi + (st.overspeed_extra or 25), vCeil))
    end
    if finePause then
        -- после сброса штрафа ещё несколько секунд держим вилку
        allowed = math.min(allowed, target)
    end
    -- Штраф «Увеличьте скорость до штрафа»: превышение живёт, пока его успеваем
    -- плавно сбросить к вилке за overspeed_guard секунд ДО конца таймера (поезд
    -- не затормозит за последнюю секунду). Разрешённая скорость падает линейно:
    -- вилка + aComf * (остаток - guard), но не ниже вилки и не выше вилки+extra.
    if fineActive then
        local left = math.max(0, st.overspeed_timer - nowSec)
        local guard = (st.overspeed_guard and st.overspeed_guard > 0) and st.overspeed_guard or 1
        -- v1.1.5: спуск РАВНОМЕРНЫЙ на весь таймер штрафа: разрешённая скорость
        -- падает с вилки+extra до серверной вилки vHi линейно, к концу окна уже
        -- внутри лимита. Прежняя логика (сброс только за lead сек до конца) не
        -- успевала: поезд физически не может скинуть десятки км/ч за 2-3 сек,
        -- а при speed_mult > 1 цель target была выше лимита сервера и таймер
        -- штрафа перезапускался бесконечно.
        local total = st.overspeed_timer_total and st.overspeed_timer_total > 0
            and st.overspeed_timer_total or math.max(1, left)
        local span = math.max(1, total - guard)
        local frac = math.max(0, math.min(1, (left - guard) / span))
        local extra = (st.overspeed_extra and st.overspeed_extra > 0) and st.overspeed_extra or 25
        if fineLast then
            allowed = math.min(allowed, target)
            drive.lastAction = u8"резкий сброс к вилке (3 сек до конца таймера)"
        elseif st.overspeed then
            allowed = vHi + extra * frac
            if allowed > vHi + extra then allowed = vHi + extra end
            if allowed < vHi then allowed = vHi end
            drive.lastAction = u8"превышение, плавный сброс к вилке за весь таймер"
        else
            allowed = math.min(allowed, vHi + aComf * math.max(0, left - guard) * 3.6)
            if allowed < target then allowed = target end
            drive.lastAction = u8"плавный сброс к вилке (штраф)"
        end
    end
    -- Станция впереди: маркер — только СКИДЫВАНИЕ скорости перед станцией.
    -- Триггер остановки маркер НЕ заменяет: останавливаемся строго по таймеру
    -- «Остановитесь на станции» (stopCmd ниже). Кривую применяем, только когда
    -- состав с текущей скорости не успевает затормозить у маркера (v^2 > 2ad),
    -- чтобы не «ползать» на 10-20 км/ч задолго до станции в ожидании таймера.
    -- v1.2.2: подкат к станции. Маркер setStation и реальный серверный триггер
    -- остановки на станциях Radmir СДВИНУТЫ (на каждой станции по-своему),
    -- поэтому остановка «по маркеру» не работает: состав вставал у маркера,
    -- разгонялся заново «искать трейдер», и стоп получался как повезёт. Теперь
    -- с последних stop_crawl_zone метров катимся на stop_crawl км/ч (10) и НЕ
    -- останавливаемся, пока не придёт таймер «Остановитесь на станции» (он
    -- приходит именно на правильном триггере). В момент команды — жёсткий
    -- фриз поезда на stop_freeze_sec секунд (см. ниже).
    local crawl = (st.stop_crawl and st.stop_crawl > 0) and st.stop_crawl or 10
    local crawlZone = (st.stop_crawl_zone and st.stop_crawl_zone > 0) and st.stop_crawl_zone or 150
    if stationKnown and not stopCmd then
        local d = distance - brakeMargin
        if d < 0 then d = 0 end
        if speedMs * speedMs > 2 * aComf * math.max(1, d) then
            allowed = math.min(allowed, math.sqrt(2 * aComf * d) * 3.6)
        end
        if distance <= crawlZone and allowed < crawl then
            -- не встаём у смещённого маркера — катимся на 10 км/ч к триггеру
            allowed = crawl
            drive.lastAction = u8"подкат к станции (10 км/ч)"
        end
    end
    -- v1.1.9: экстренный сброс: за 250 м до станции скорость не выше 90 км/ч.
    -- Внутри зоны кривая (выше) и stopCmd доведут до полного стопа.
    if stationKnown and distance <= stationCapDist then
        allowed = math.min(allowed, stationCapKmh)
    end
    local stopping = false
    -- Команда сервера «Остановитесь на станции»: цель — полный стоп.
    local stopHard = false
    local stopFreezeSec = (st.stop_freeze_sec and st.stop_freeze_sec > 0) and st.stop_freeze_sec or 5
    if stopCmd then
        stopping = true
        stopHard = true
        -- v1.2.2: это и есть реальный триггер станции (может быть смещён
        -- относительно маркера). Скорость к моменту команды уже ~10 км/ч
        -- (подкат выше) — гасим до нуля и включаем жёсткий фриз fTrainSpeed=0.
        if drive.stop_freeze_until == nil then
            drive.stop_freeze_until = os.time() + stopFreezeSec
        end
        local d = distance - 3
        if d < 0 then d = 0 end
        local brakeTarget = math.sqrt(2 * aComf * d) * 3.6
        if speed > brakeTarget + 1 then
            allowed = math.min(allowed, brakeTarget)
        else
            allowed = 0
        end
        drive.lastAction = u8"остановка: фриз поезда на станции"
    end
    -- v1.2.2: жёсткий фриз: пока активен таймер, держим fTrainSpeed = 0 через
    -- память каждый кадр — поезд стоит мёртво, не катится назад/вперёд.
    if drive.stop_freeze_until and os.time() >= drive.stop_freeze_until then
        drive.stop_freeze_until = nil
    end
    if drive.stop_freeze_until then
        hardFreezeTrain(true)
    end
    -- v0.9.8: при «жёстком» стопе докрутка не нужна — состав уже проехал
    -- станцию, докрутка завершена принудительно, чтобы сработала стоянка.
    if stopHard then
        drive.crawl_start = nil
        drive.crawl_done = true
    end
    -- v0.9.7: ДОКРУТКА ЗА СТОП-ТОЧКУ. Серверный триггер станции часто стоит чуть
    -- ДАЛЬШЕ точки, где дистанция setStation дошла до нуля, поэтому состав
    -- вставал ПЕРЕД триггером и станция не засчитывалась. Теперь, как только
    -- состав замедлился у станции, едем ещё stop_overshoot метров на скорости
    -- stop_crawl км/ч (по умолчанию 50 м / 10 км/ч) и только потом встаём.
    local overshoot = (st.stop_overshoot and st.stop_overshoot >= 0) and st.stop_overshoot or 50
    local crawl = (st.stop_crawl and st.stop_crawl > 0) and st.stop_crawl or 10
    local crawlSec = math.max(1, math.floor(overshoot / (crawl / 3.6)))
    local nearStation = stationKnown and distance <= brakeMargin + 2
    -- v1.1.0: докрутка за стоп-точку отключена. Остановка — строго по таймеру
    -- сервера («Остановитесь на станции»), маркер/триггер станции тут ни при
    -- чём: именно докрутка давала «катится 10-15-20 км/ч» и «проезжает станцию
    -- полностью» в ожидании таймера. Остаёмся на месте после торможения.
    local crawlAllowed = false
    if crawlAllowed and not drive.crawl_done then
        -- Докрутку НАЧИНАЕМ только у ДВИЖУЩЕГОСЯ состава (speed > 1): если поезд
        -- уже встал, с места не трогаем — иначе получалось «встал, потом снова
        -- набрал 10 км/ч и поехал вперёд».
        if not drive.crawl_start and speed > 1 and speed <= crawl + 4 then
            drive.crawl_start = os.time()
        end
        if drive.crawl_start then
            if (os.time() - drive.crawl_start) < crawlSec then
                allowed = math.max(allowed, crawl)
                if not stopping then
                    drive.lastAction = u8"докрутка до триггера станции"
                end
            else
                drive.crawl_done = true
            end
        end
    end
    if speed >= 30 then
        drive.crawl_start = nil
        drive.crawl_done = false
    end
    drive._useTarget = allowed
    drive.stop_preview = stationKnown and math.max(0, distance - brakeMargin) or 0

    -- ---------- Стоянка на станции ----------
    -- Встали окончательно, если сервер скомандовал «Остановитесь на станции»,
    -- пришло «Ожидайте отправления»/«Садитесь в поезд» либо состав уже прошёл
    -- докрутку и стоит у самой стоп-точки станции (distance <= 3 м).
    local crawling = (drive.crawl_start ~= nil) and not drive.crawl_done
    local atStopPoint = stationKnown and (distance <= 3 or drive.crawl_done or stopHard)
    if speed < 3 and (stopCmd or stayCmd or atStopPoint) and not crawling then
        if not drive.station_arrived then
            drive.station_arrived = true
            drive.station_arrive_time = os.time()
        end
        -- v0.9.8: отправление ТОЛЬКО по серверной команде разгона. Раньше
        -- автоотправление по dwell (5 с) увозило состав до команды, и новый
        -- таймер «Остановитесь на станции» не мог его вернуть. Аварийная
        -- страховка — st.station_release_delay секунд без единой команды.
        local releaseDelay = (st.station_release_delay and st.station_release_delay > 0)
            and st.station_release_delay or 30
        local waited = drive.station_arrive_time
            and (os.time() - drive.station_arrive_time) >= releaseDelay
        local canGo = goCmd or st.need_go
            or (not stopCmd and not stayCmd and not timerActive
                and not driveCpFinish and waited)
        if canGo then
            drive.station_arrived = false
            drive.station_arrive_time = nil
            drive.crawl_start = nil
            drive.crawl_done = false
            drive.stop_freeze_until = nil
            drive.phase = "DRIVE"
            releaseBrake()
            if speed < target then pressGasNative() end
            drive.lastAction = goCmd and u8"отправление (сервер требует скорость)"
                or u8"отправление после стоянки"
        else
            drive.phase = "STOP"
            -- v1.2.2: тормоз-клавишу НЕ жмём: у GTA-поезда удержание S = задний
            -- ход, из-за неё состав ползёт назад на станции. Стоим за счёт
            -- жёсткого фриза fTrainSpeed = 0 (удерживается каждый кадр),
            -- поэтому на стоянке поезд не катится ни вперёд, ни назад.
            releaseBrake()
            hardFreezeTrain(true)
            drive.lastAction = u8"стоянка на станции (фриз)"
        end
        drive.keys = drive._gasPressed and 8 or 0
        return
    end

    -- ---------- Управление газом/тормозом ----------
    if goCmd then
        releaseBrake()
        if speed < target then
            pressGasNative()
            drive.lastAction = u8"разгон (сервер требует скорость)"
        else
            drive.lastAction = u8"набор/нейтраль"
        end
    elseif speed > allowed + 1.0 then
        -- Тормозим: уровень растёт с глубиной превышения — мягко, как игрок.
        local over = speed - allowed
        local span = math.max(10, allowed * 0.35)
        local lvl = math.floor(80 + math.min(1, over / span) * 150)
        -- Экстренно: оставшегося пути не хватит даже на максимальное замедление,
        -- либо приближаемся к станции выше лимита 90 км/ч, либо проскочили
        -- стоп-триггер станции (stopHard) — тормозим полностью (lvl 255).
        local hard = stationKnown and distance <= stationCapDist
            and (speedMs * speedMs > 2 * brakeA * math.max(1, distance - brakeMargin)
                 or speed > stationCapKmh + 2)
        -- v1.2.0: финальные метры остановки на станции (разрешено <= 15 км/ч)
        -- тормозим ПОЛНОСТЬЮ — мягкий lvl (~140) не успевал погасить 6-10 км/ч,
        -- и состав проезжал станцию. Следим именно за allowed (уже = brakeTarget).
        local stopApproach = stopCmd and allowed <= 15
        if hard or stopHard or stopApproach or fineLast or (fineActive and over > 25) then lvl = 255 end
        setBrakeLevel(lvl)
        if not stopping then drive.lastAction = u8"торможение" end
    elseif speed < allowed - 1.0 then
        releaseBrake()
        pressGasNative()
        if fineActive then
            drive.lastAction = u8"набор после сброса к вилке"
        elseif stationKnown and distance < 300 then
            drive.lastAction = u8"разгон до станции"
        else
            drive.lastAction = u8"разгон"
        end
    else
        releaseBrake()
    end

    -- v1.1.4: спидхак поезда (общий вызов для всех веток газа: старт,
    -- goCmd, обычный разгон). Работает только когда газ реально нажат
    -- и скорость ещё не достигла разрешённой — при торможении не
    -- вмешивается, тормозной путь не ломается.
    -- v1.1.9: порог «speed >= 10» (оценка setStation, раз в секунду) убран:
    -- он запаздывал на разгоне и спидхак «не работал». Gate теперь внутри
    -- applyTrainBoost по памяти (fTrainSpeed > 1 м/с = реальное движение
    -- вперёд) плюс исключение stayCmd («Ожидайте отправления»/«Садитесь
    -- в поезд»), чтобы на стоянке не накапливать скорость и не «выстреливать».
    if not stopping and not stopHard and not stayCmd and drive._gasPressed
        and speed < allowed - 0.5 then
        applyTrainBoost(allowed / 3.6)
    end

    -- ---------- keysData: направление для сервера ----------
    --   0x08 (accel) = вперёд, 0x20 (decel) = назад, 0 = стоит.
    if speed > 0.5 then
        drive.keys = 8
    elseif speed < -0.5 then
        drive.keys = 32
    else
        drive.keys = drive._gasPressed and 8 or 0
    end
end

-- driveTick видна ev-хукам (onSendVehicleSync и др.) как глобал:
-- хуки объявлены выше local function driveTick(), поэтому без этого
-- ссылка в них была бы нил-глобалом.
_G.driveTick = driveTick


-- Поток автопилота — КАДРОВЫЙ источник тиков (порт цикла из mashinist.lua):
--   bot.state        -> optEnabled.v (наше включение автопилота)
--   inCabNow()       -> drive.in_train (безнативный CEF-гейт кабины)
--   bot.distance     -> st.station_dist (дистанция до станции из setStation)
--   bot.speed.min/max-> st.speed_lo/st.speed_hi (вилка setSpeed, км/ч)
--   checkpoint       -> driveCp (чекпоинт сервера, если есть)
-- Каждый кадр зовём driveTick(). При свёрнутом окне (кадры почти не идут)
-- ведение продолжает резервный тик из ev.onSendVehicleSync.
function driveThread()
    if st.dbg_no_thread then
        print("[MachinistByYaroRage] driveThread пропущен (dbg_no_thread=1)")
        drive.tickThread = nil
        return
    end
    while optEnabled.v do
        wait(0)
        driveTick()
    end
    drive.tickThread = nil
end

-- Ensure driveThread is globally accessible for main()
_G.driveThread = driveThread

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
    -- v0.9.1: «Включить автопилот» включает ТОЛЬКО автопилот. Остальные
    -- функции (кабина, уведомления об админе, превышение, опрос Telegram)
    -- не трогаем: они продолжают работать, как были настроены.
    optEnabled.v = true
    saveAll()
    if optEnabled.v and not drive.tickThread and not st.dbg_no_thread then
        drive.tickThread = lua_thread.create(driveThread)
    end
    -- v1.1.9: меню при включении автопилота НЕ закрываем (убрано авто-закрытие
    -- из v1.0.8): при частых вкл/выкл из GUI окно пропадало само. Оставляем
    -- окно открытым — перехват клавиатуры/курсора активен на время меню.
    pcall(sampAddChatMessage, u8:decode(u8"Machinist: автопилот включён"), 0xAAFFAA)
end

stopBot = function()
    -- v0.9.1: «Выключить автопилот» / /mqstop останавливают ТОЛЬКО
    -- автопилот. Принудительная кабина, уведомления об админе, превышение
    -- и опрос Telegram продолжают работать в прежнем виде.
    if not optEnabled.v then return end
    optEnabled.v = false
    saveAll()
    -- Освобождаем газ/тормоз и сбрасываем состояние автопилота, чтобы поезд
    -- не продолжал движение после выключения (поток сам завершится: while
    -- optEnabled.v стал false).
    drive.keys = 0
    drive.phase = "IDLE"
    drive.lastAction = u8"автопилот выключен"
    drive.station_arrived = false
    drive.station_arrive_time = nil
    drive.station_left = false
    pcall(releaseKeysNative)
    pcall(sampAddChatMessage, u8:decode(u8"Machinist: автопилот выключен (остальные функции работают)"), 0xFFAAAA)
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
-- Путь к файлу ответа getUpdates (тот же, что строит модуль telegram.lua).
local tgTmpDir = getWorkingDirectory():gsub("[\\/]+$", "") .. "\\MachinistByYaroRage\\tg_tmp\\"
local tgUpdPath = tgTmpDir .. "updates.json"
-- v0.9.1: опрос ускорен. Раньше цикл ждал 5000 мс и каждый тик запускал
-- новый curl — при свёрнутом окне сообщения из лички бота доезжали до чата
-- по 10-20 секунд. Теперь интервал 900 мс, а в сети держим ТОЛЬКО один
-- запрос (флаг tgBusy): пока прошлый ответ не прочитан — новый getUpdates
-- не запускаем, поэтому зависшие curl и потерянные ответы исключены.
local tgBusy = false
local tgBusyAt = 0
local function tgPollLoop()
    while true do
        wait(900)
        -- Выключение опроса из GUI: чекбокс сняли — поток тихо завершается
        if not st.tg_poll_enable then
            tgPollThread = nil
            print("[MachinistByYaroRage] Опрос Telegram остановлен (чекбокс снят)")
            tgBusy = false
            return
        end
        -- 1) читаем ответ прошлого запроса (локально, мгновенно). Файл
        -- появляется только когда фоновый curl завершился: наличие файла
        -- = предыдущий запрос сделан, можно запускать следующий.
        local updPathExists = doesFileExist(tgUpdPath)
        if updPathExists then
            tgBusy = false
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
        elseif tgBusy and wallClockMs() - tgBusyAt > 12000 then
            -- Запроса нет 12+ сек (curl умер/таймаут/папка отсутствовала):
            -- сбрасываем флаг, чтобы опрос перезапустился.
            tgBusy = false
        end
        -- 2) следующий опрос: только когда предыдущий curl уже отработал
        if not tgBusy then
            if not doesDirectoryExist(tgTmpDir) then pcall(createDirectory, tgTmpDir) end
            tgBusy = true
            tgBusyAt = wallClockMs()
            telegram.get_updates(st.tg_bot_token, tgOffset)
        end
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

-- ---------- чатлог-детект (v1.1.2) ----------
-- Наблюдатель chatlog.txt: чатлог пишется SAMP всегда, даже когда игра свёрнута
-- и события пузырей/onSendPacket не приходят. Это резервный канал детекта админов.
-- Путь берём из USERPROFILE (Documents/Документы), как в AutoLoginByYaroRage.
local chatlogThread

local function chatlogFindPath()
    local up = os.getenv("USERPROFILE")
    local folders = { "Documents", "Документы" }
    local candidates = {}
    local function addCandidate(base)
        for _, fld in ipairs(folders) do
            candidates[#candidates + 1] = base .. "\\" .. fld ..
                "\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
        end
    end
    if up and #up > 0 then addCandidate(up) end
    for _, drv in ipairs({ "C", "D", "E", "F", "G", "H" }) do
        addCandidate(drv .. ":")
    end
    for _, p in ipairs(candidates) do
        if doesFileExist(p) then return p end
    end
    return nil
end

function chatlogWatchThread()
    local path = chatlogFindPath()
    if not path then
        print("[MachinistByYaroRage] chatlog.txt не найден, чатлог-детект отключён")
        return
    end
    print("[MachinistByYaroRage] чатлог-детект: " .. tostring(path))
    local fh = io.open(path, "rb")
    if not fh then
        print("[MachinistByYaroRage] не удалось открыть chatlog.txt, чатлог-детект отключён")
        return
    end
    -- Стартуем с конца файла: обрабатываем только НОВЫЕ строки (с момента загрузки).
    fh:seek("end")
    local pos = fh:seek("end")
    while true do
        wait(1200)
        if not fh then break end
        -- Ротация файла (chatlog пересоздаётся новым подключением): если размер
        -- стал меньше записанной позиции, переоткрываем и начинаем с нуля.
        local okE, eof = pcall(fh.seek, fh, "end")
        if okE and eof and eof < pos then
            pcall(fh.close, fh)
            fh = io.open(path, "rb")
            if not fh then break end
            pos = 0
        end
        local okS = pcall(fh.seek, fh, "set", pos or 0)
        if not okS then break end
        local okR, data = pcall(fh.read, fh, "*a")
        if okR and data and #data > 0 then
            pos = fh:seek("end") or pos
            for line in data:gmatch("[^\r\n]+") do
                -- Строки чатлога вида: [ЧЧ:ММ:СС] ТЕКСТ. Цвета {RRGGBB} не важны.
                local t = line:match("^%[%d%d:%d%d:%d%d%]%s*(.*)$") or line
                if #t > 0 then
                    -- Сабжайте как обычное чат-сообщение без автора (пузырь "чатлог").
                    processChatText("чатлог", t, nil)
                end
            end
        end
    end
end

-- ---------- main ----------
function main()
    repeat wait(0) until isSampAvailable()
    wait(500)

    state_mod.load_config()
    -- v1.2.1: если ник персонажа ещё не задан в конфиге — определить один раз
    if not st.my_nick or #st.my_nick == 0 then
        local autoNick = detectMyNick()
        if autoNick then
            st.my_nick = autoNick
            inpMyNick.v = autoNick
            state_mod.save_config()
        end
    end
    optEnabled.v = st.enabled
    optForceCab.v = st.force_cab
    optNotify.v = st.notify_telegram
    optOverspeed.v = st.overspeed
    optTgPoll.v = st.tg_poll_enable
    inpToken.v = st.tg_bot_token
    inpChat.v = st.tg_chat_id

    local okSv, sv = pcall(script_version)
    if not okSv or type(sv) ~= "string" or #sv == 0 then sv = "0.9.6" end
    print(string.format("[MachinistByYaroRage] v%s флаги: no_thread=%d no_events=%d no_gui=%d no_chat=%d tg_poll=%d dbg_log=%d force_cab=%d",
        tostring(sv), st.dbg_no_thread and 1 or 0, st.dbg_no_events and 1 or 0,
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

    -- v1.1.2: наблюдатель chatlog.txt (детект админа, когда игра свёрнута)
    if chatlogThread == nil and not st.dbg_no_events then
        chatlogThread = lua_thread.create(chatlogWatchThread)
    end

    -- Перезагрузка скрипта могла оставить от старого экземпляра глобальные
    -- imgui-флаги ShowCursor/Process и мёртвый хук OnDrawFrame (крэш или релоад
    -- с открытым /mq). Пока наше меню закрыто — возвращаем ввод и курсор игре.
    if not st.dbg_no_gui then
        ensureUiHook()
        if not showMenu.v then
            imgui.Process = false
            imgui.ShowCursor = false
        end
    end

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

        -- ---------- Панель действий: автопилот вкл/выкл / сохранить / закрыть ----------
        -- v0.9.1: ШАПКА — кнопка включает/выключает ТОЛЬКО автопилот.
        -- Остальные функции (кабина, уведомления об админе, превышение,
        -- опрос Telegram) не трогаются. Цвет: зелёный — автопилот работает,
        -- красный — выключен.
        if optEnabled.v then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.22, 0.62, 0.30, 1))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
        else
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.72, 0.18, 0.15, 1))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
        end
        if imgui.Button(optEnabled.v and u8"Выключить автопилот" or u8"Включить автопилот",
                        imgui.ImVec2(240 * fsc, 34 * fsc)) then
            if optEnabled.v then stopBot() else startBot() end
        end
        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Включает/выключает только автопилот. Кабина, уведомления об админе, превышение и опрос Telegram продолжают работать")
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
            if imgui.Checkbox(u8"Автопилот", optEnabled) then
                -- v1.1.9: галочка автопилота меню больше не закрывает
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Управляет поездом CEF-пакетами (работает и при свёрнутой игре)")
            end
            if imgui.Checkbox(u8"Принудительно в кабине", optForceCab) then end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Включать автопилот, даже если кабина не определена по CEF-пакетам 'Machinist'")
            end
            if imgui.Checkbox(u8"Уведомления в телеграм (админы и окна)", optNotify) then end
            imgui.TextWrapped(u8"Горячая клавиша меню — /mq")

        -- ---------- Ведение ----------
        elseif menuTab.v == 2 then
            imgui.TextWrapped(u8"Ведение: порт mashinist.lua, безнативные вызовы (ноль нативных game-функций). Скорость — оценка по дистанции setStation, цель — максимум вилки, у станции плавное торможение по физической кривой, стоп по команде сервера «Остановитесь на станции».")
            imgui.TextWrapped(u8"Мин/макс скорость: " .. st.speed_range .. u8" км/ч (код " .. st.speed_code .. u8")")
            imgui.Checkbox(u8"Превышать скорость", optOverspeed)
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Ехать выше вилки сервера (превышение рассчитывается само по таймеру штрафа) и за секунду до останова таймера тормозить обратно в вилку")
            end
            imgui.SliderFloat(u8"Множитель целевой скорости", optSpeedMult, 1.0, 2.0, "%.2f")
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Умножает целевую скорость поезда (1.00 = как есть, 1.30 = вилка +30%). Поезд активнее разгоняется и держит скорость выше вилки. Риск штрафов за превышение скоростного режима")
            end
            imgui.SliderFloat(u8"Спидхак разгона поезда", optSpeedBoost, 1.0, 5.0, "%.2f")
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Ускоряет набор скорости поезда (x1..x5): разгоняется в N раз быстрее, предел — серверная вилка. Вилку не меняет, на стоянке не срабатывает")
            end

        -- ---------- Телеграм и админы ----------
        elseif menuTab.v == 3 then
            imgui.PushItemWidth(280 * fsc)
            imgui.InputText(u8"Токен бота", inpToken)
            imgui.InputText(u8"Chat ID", inpChat)
            imgui.Separator()
            imgui.TextWrapped(u8"Ник персонажа (для уведомлений):")
            imgui.PushItemWidth(210 * fsc)
            imgui.InputText(u8"Ник", inpMyNick)
            imgui.PopItemWidth()
            if imgui.Button(u8"Автоопределить ник", imgui.ImVec2(210 * fsc, 0)) then
                local autoNick = detectMyNick()
                if autoNick then
                    inpMyNick.v = autoNick
                    saveAll()
                    pcall(sampAddChatMessage, u8:decode(u8"Machinist: ник определён: " .. autoNick), 0xAAFFAA)
                else
                    pcall(sampAddChatMessage, u8:decode(u8"Machinist: не удалось определить ник (SAMP недоступен)"), 0xFF8888)
                end
            end
            if imgui.Button(u8"Сохранить ник", imgui.ImVec2(210 * fsc, 0)) then
                saveAll()
                pcall(sampAddChatMessage, u8:decode(u8"Machinist: ник сохранён: " .. (st.my_nick or "")), 0xAAFFAA)
            end
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
