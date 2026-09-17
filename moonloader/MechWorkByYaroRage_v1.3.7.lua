-- MechWorkByYaroRage v1.3.7
-- v1.3.7: кнопка «Включить/Выключить чит» вынесена из-под заголовка окна
-- в отдельную строку (раньше скрывалась под шапкой на части разрешений/
-- DPI); чит по умолчанию выключен, старые настройки один раз переводятся
-- в выключенное состояние.
-- v1.3.6: GUI перегруппирован: фразы автоответа перенесены во вкладку
-- «Фразы», блоки фраз свёрнуты в раскрывающиеся заголовки (галочка,
-- исключения id и список фраз вместе), ползунки радиуса/паузы стоят
-- под своим авто-подбором, а не под ESP; в «Статус» добавлены счётчики.
-- v1.3.5: у каждого блока фраз своя галочка вкл/выкл и свой список
-- исключённых id (этим игрокам фразы блока не отправляются).
-- v1.3.4: диапазон задержки перед закрытием миниигры задаётся в секундах
-- от 0 до 20 (ползунки «от/до»).
-- v1.3.3: строгий цикл фраз без повторов до полного прохода списка; ESP не
-- зеркалится за спиной (метка рисуется только перед активной камерой).
-- v1.3.2: задержка каждой фразы выбирается случайно в диапазоне «от/до»
-- (два ползунка в GUI) — сообщения всегда уходят по-разному.
-- v1.3.1: все фразы уходят с задержкой 1 сек; ESP берёт машину цели
-- динамически и поднимает метку на корпус; добавлен блок фраз (2) на
-- серверное сообщение «Капот транспорта должен быть открыт».
-- v1.3.0: ESP-метка рисуется через SAMPFUNCS render* (в MoonImGui нет
-- GetBackgroundDrawList); исправлен блок исключённых id (кнопки «Добавить»
-- и «очистить всё» больше не конфликтуют по ID); перевод денег ловится
-- прямо в сырых байтах RPC id=93/101, а не только в onServerMessage.
-- Автозавершение миниигры починки транспорта (Радмир CRMP).
-- v1.1.4: в блоке «Авто-подбор подъехавших машин» добавлен ручной
-- режим: /repair кидается не автоматически, а по клику правой
-- кнопки мыши (ПКМ) ближайшему водителю в том же радиусе; после
-- отправки водитель «замораживается» на паузу из GUI (optNearDelaySec)
-- — следующий клик берёт следующего по близости, после паузы можно
-- выбрать того же снова.
-- v1.1.6: список исключённых id водителей (им не шлём /repair в авто-режиме,
-- по ПКМ и колесиком/курсором): если ближайшая машина в радиусе имеет
-- водителя с исключённым id, запрос уходит следующей по близости машине,
-- чей водитель не исключён. Список хранится в ini ключами excludeId1..N
-- v1.2.8: исправление авто-ответа на перевод денег. Реальный формат сервера
-- «<Ник> передал Вам деньги 4444 руб» (без знака $, после суммы слово
-- «руб»). Паттерн «передал [Вв]ам %$(%d+)» не совпадал с сообщением —
-- фраза на перевод не отправлялась. Теперь ловим «передал Вам деньги <сумма>».
-- v1.2.7: мастер-выключатель всего чита: кнопка в шапке окна «ВЫКЛЮЧИТЬ ЧИТ»/«ВКЛЮЧИТЬ ЧИТ»
-- включает/выключает все автоматизации одним кликом: автозавершение, авто-старт, авто-ответ и
-- деньги, курсор-пик, ПКМ-ремонт и авто-подбор. При выключении сбрасываются активные состояния.
-- Добавлена опция cheatEnabled (true/false) в ini.
-- v1.2.6: фразы автоответа расширены до 30 (добавление по одной и блоком из
-- многострочного поля, каждая строка = фраза); фразы по окончанию миниигры
-- (5 шт, отправляются через 1 сек после закрытия окна, /cancel на них никак
-- не влияет) и фразы-ответы на перевод денег «Игрок [Nick] передал Вам $N»
-- (5 шт до 4000 и 5 шт от 4001, КД 10 сек на каждую группу суммы). Все списки
-- фраз выбираются циклически случайным порядком без повторов в цикле (v1.2.2).
-- Новая вкладка GUI «Фразы». Обобщённый выбор фразы - pickCycleLine.
-- v1.2.5: GUI разбит на 5 вкладок (Миниигра/Ремонт/Курсор/Авто-подбор/Статус),
-- кнопки «Очистить всё» для триггеров и исключённых id, компактные кнопки «х»
-- вместо «удалить», горизонтальная панель вкладок сверху с подсветкой активной.
-- v1.2.4: буфер фраз автоответа расширен до 168 байт, что в UTF-8
-- даёт до 83 кириллических символов во фразе (было 128 байт / ~63
-- символа). В ini фразы по-прежнему сохраняются в CP1251.
-- v1.2.3: убран мигающий курсор при подключении/перезагрузке скрипта:
-- состояние imgui (ShowCursor/Process/DisableInput) сбрасывается в
-- первом же кадре main(), не дожидаясь игрового цикла (модуль imgui
-- по умолчанию стартует с ShowCursor=true).
-- v1.2.2: фразы автоответа воспроизводятся в цикле (случайный порядок
-- одного цикла, пока все N фраз не воспроизведутся — ни одна не
-- повторится, затем случайный порядок обновляется и цикл начинается
-- заново). Список фраз может быть любым до 10 штук.
-- v1.2.1: комбинация Space + ПКМ теперь срабатывает и при показанном
-- курсоре выбора цели (optCursorPick): /cancel уходит, а короткий клик ПКМ
-- при зажатом Space НЕ выбирает машину под курсором (только /cancel).
-- v1.2.0: комбинация Space + ПКМ (зажать пробел и кликнуть правой кнопкой
-- мыши) отправляет в чат команду /cancel — ручная отмена текущей миниигры
-- и ремонта. Срабатывает на фронте комбинации (каждый новый клик ПКМ при
-- зажатом Space шлёт команду), пропускается при открытом меню, показанном
-- курсоре выбора цели и вводе в чат/самп-диалог. При зажатом Space ручной
-- запрос /repair по ПКМ (v1.1.4) не отправляется, чтобы команды не конфликтовали.
-- v1.1.9: персонаж в «Эвакуаторе» (модель 525 = Towtruck, в списке Les -
-- «Эвакуатор») автоматически попадает в исключения и не получает /repair:
-- рантайм-фильтр отсекает водителей за рулём эвакуатора во всех режимах
-- (авто-радиус, ПКМ, курсор), а собственный id игрока, когда он сам сидит
-- в эвакуаторе, добавляется в список исключений (ini ключ excludeId) и
-- сохраняется там.
-- v1.1.8: время до успешного финиша миниигры задаётся диапазоном «от - до»
-- (мс): при КАЖДОЙ новой миниигре в нём выбирается случайное значение,
-- по истечении которого отправляется OnHelloweenBuildComplete и сервер
-- считает ремонт успешным. Старые конфиги с одиночным ключом delayMs
-- (фиксированная задержка) мигрируют в диапазон ±1000 мс вокруг него.
-- v1.1.7: приоритет мотоциклам при ремонте (авто и по ПКМ) - если в радиусе
-- есть мотоциклы, /repair сначала уходит им; при принятии заявки водителем
-- скрипт показывает только пользователю локальное сообщение (не в общий
-- чат): «Чиню <ник> (id) - <модель машины>» (имена моделей из LesCarNames.txt).
-- v1.1.5: автоответ — список фраз (до 10): игрок задаёт их через GUI,
-- в чат при старте ремонта уходит СЛУЧАЙНАЯ фраза из списка, но не та,
-- что была отправлена только что (одинаковое сообщение в чат дважды
-- подряд писать нельзя). Список хранится в ini ключами replyLine1..N
-- v1.1.3: автоответ при начале ремонта снова работает: RPC 101 (чат)
-- разбирался со сдвигом (id отправителя читался Int16 вместо BYTE),
-- из-за чего длина/текст ломались и фраза не отправлялась; теперь
-- фраза старта ремонта ищется прямо в сырых байтах пакета для RPC
-- 101 и 93 (плюс дубль через onServerMessage), варианты формулировок
-- расширены (минута/минуту/минут на ремонт, начните ремонт транспорта).
-- v1.1.2: меню переведено с вкладок на обычные секции (в этой сборке
-- нет API вкладок, из-за чего меню вообще не открывалось);
-- кнопка показа курсора настраивается (мышь/боковые/клавиши);
-- задержка показа курсора регулируется (0.1-2.0 сек).
-- v1.1.0: стабильные тайминги кликов через GetTickCount (вместо os.clock);
-- камера вращается при видимом курсоре (DisableInput=true без меню);
-- поиск цели курсором среди ближайших кандидатов с водителем-игроком;
-- кулдауны переведены на миллисекунды (wall-clock).
-- v1.0.9: автоответ при старте ремонта перенесён из onServerMessage (в нём
-- надпись «…1 минута на ремонт» НЕ приходит) в перехват чат-RPC id=101 -
-- проверка текста до фильтра системного playerId. В v1.0.8 автоответ
-- не срабатывал совсем, т.к. триггер стоял на несуществующем канале.
-- v1.0.8: кулдаун курсорного ремонта снижен со 4 сек до 0.5 сек (прежние
-- 4 сек совпадали с циклом ремонта ~3.5 сек - «через раз»); при видимом
-- курсоре без меню DisableInput = true — камера вращается вместе с мышью.
-- v1.0.7: автоответ по надписи «1 минута на ремонт», кулдаун 5 сек (см. v1.0.9).
-- v1.0.6: исправлен выбор цели колесиком (позиция машины читается из памяти,
-- getVehiclePosition в сборке отсутствует). Курсор показывается/прячется
-- удержанием колесика 1 сек без отпускания; короткий клик шлёт /repair.
-- v1.0.5: автовосстановление повреждённого replyText в настройках
-- (байты EF BF BD вместо CP1251) и применение дефолтного ответа.
-- v1.0.4: добавлена опция «показать курсор поверх экрана»: клик колесиком
-- по машине на экране отправляет /repair <id её водителя> автоматически.
-- v1.0.3: исправлена кодировка текста автоответа в GUI (imgui требует
-- UTF-8, настройки хранятся в CP1251) — убраны знаки «?» в поле ответа.
-- v1.0.2: добавлен автоответ в чат после того, как водитель принял заявку
-- /repair (сервер пишет «…1 минута на ремонт»): скрипт шлёт текст от имени
-- игрока, как будто тот сам печатает в чат. Опция в GUI.
-- Механика (по логу перехвата): сервер шлёт RX HelloweenBuild[2,"...",N],
-- где N - число нажатий SPACE, которые клиент должен был бы сделать.
-- От клиента при успехе отправляется OnHelloweenBuildComplete,
-- после чего сервер начисляет оплату и закрывает миниигру.
--
-- Скрипт перехватывает команду HelloweenBuild и сам закрывает миниигру:
-- ничего не нажимается, после регулируемой задержки (например 3 секунды)
-- отправляется OnHelloweenBuildComplete - сервер считает игру успешной.
--
-- Дополнительно: авто-старт (опция). Когда у капота машины появляется окно
-- Interactions с кнопками (48/153), скрипт сам нажимает нужную кнопку
-- (OnInteractionsClick), и мини-игра ремонта начинается автоматически.
--
-- Механизация сбора медоборудования (целитель CRMP).
-- Версия v1.0.1: приветствие одной строкой через ywelcome,
-- экранная надпись printStringNow убрана (мешала обзору).
-- Меню: /mech
script_name("MechWorkByYaroRage")
script_version("1.3.7")

require "moonloader"

local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8

local imgui = require "imgui"

local ffi = require "ffi"

local ywelcome = require "ywelcome"

-- ---------- DPI-коэффициент (как в CheatByYaroRage) ----------
local dpiUi = 1.0
do
    local ok, dpi = pcall(function()
        ffi.cdef[[
            int GetDpiForSystem(void);
            int GetSystemMetrics(int nIndex);
            int GetCursorPos(void* lpPoint);
            short GetAsyncKeyState(int vKey);
            unsigned int GetTickCount(void);
        ]]
        return ffi.C.GetDpiForSystem()
    end)
    if ok and type(dpi) == "number" and dpi > 0 then dpiUi = dpi / 96 end
    if dpiUi < 0.5 then dpiUi = 0.5 elseif dpiUi > 3.5 then dpiUi = 3.5 end
end

local user32 = ffi.load("user32")

-- нажата ли клавиша/кнопка с виртуальным кодом vk (мышь или клавиатура)
local function isVkDown(vk)
    if not vk or vk <= 0 then return false end
    local ok, res = pcall(function() return bit.band(user32.GetAsyncKeyState(vk), 0x8000) ~= 0 end)
    return ok and res
end

-- координаты курсора мыши (в физ. пикселях экрана)
local function getMouseScreenPos()
    local pt = ffi.new("int[2]")
    local ok = pcall(ffi.C.GetCursorPos, ffi.cast("void*", pt))
    if not ok then return -1, -1 end
    return tonumber(pt[0]), tonumber(pt[1])
end

-- стабильные миллисекунды (wall-clock, в отличие от os.clock = CPU-time)
local function nowMs()
    local ok, t = pcall(ffi.C.GetTickCount)
    if ok and type(t) == "number" then return t end
    return os.clock() * 1000
end

-- v1.1.5: зерно генератора случайных чисел (выбор фразы автоответа)
math.randomseed(nowMs())

local fsc = 1

-- ---------- Настройки (привязка к GUI) ----------
-- Конфиг храним через чистый io.open (как в AutoLoginByYaroRage): встроенный
-- inifile на этой сборке падает exception'ом create_directories, который не
-- ловится pcall, поэтому inicfg не используем.
local iniFile = getGameDirectory() .. "\\moonloader\\MechWorkByYaroRage.ini"

local function loadSettings()
    local s = { enabled = true, cheatEnabled = false, delayMs = 3000, autoStart = true, startDelayMs = 300,
                autoRepair = true, repairCooldown = 4000,
                autoReply = true,
               replyDelayMinSec = 1, replyDelayMaxSec = 2, -- v1.3.2: диапазон задержки фраз в чат (сек)
                replyLines = {}, -- список фраз автоответа (до 30, v1.1.5)
                finishLines = {}, -- v1.2.6: фразы по окончанию миниигры (до 5)
                moneyLowLines = {}, -- v1.2.6: фразы при переводе до 4000 (до 5)
                moneyHighLines = {}, -- v1.2.6: фразы при переводе от 4001 (до 5)
                hoodLines = {}, -- v1.3.1: фразы на сообщение «Капот транспорта должен быть открыт»
                cursorPick = false,
                cursorButton = 0x04,
                cursorDelayMs = 1000,
        nearRepair = false,
        nearRadiusM = 5,
        nearDelaySec = 30,
        manualRmb = false, -- ручной запрос /repair по ПКМ (v1.1.4)
        espLine = false, -- v1.2.9: ESP-линия от центра экрана к чинящейся машине
        espBox = false, -- v1.2.9: ESP-квадрат на капоте чинящейся машины
        espPanel = false, -- v1.2.9: ESP-плашка внизу экрана (id/ник/модель)
        -- v1.3.5: блоки фраз - вкл/выкл (галочка) и исключённые id по блокам
        blockOnReply = true, blockOnFinish = true, blockOnMoneyLow = true,
        blockOnMoneyHigh = true, blockOnHood = true,
        blockExclReply = {}, blockExclFinish = {}, blockExclMoneyLow = {},
        blockExclMoneyHigh = {}, blockExclHood = {},
        excludedIds = {}, -- v1.1.6: исключённые id водителей (им не шлём /repair)
                triggers = { "почини", "чини", "почин", "чин", "отремонтируй", "ремонт", "репа", "repair" } }
    local ok, f = pcall(io.open, iniFile, "r")
    if ok and f then
        local trig = {}
        for line in f:lines() do
            local k, v = line:match("^(%w+)%s*=%s*(.-)%s*$")
            if k then
                local tn = k:match("^trigger(%d+)$")
                if tn then
                    if v ~= "" then trig[tonumber(tn)] = v end
                else
                    if v == "true" then s[k] = true
                    elseif v == "false" then s[k] = false
                    else s[k] = tonumber(v) or v end
                end
            end
        end
        f:close()
        if #trig > 0 then s.triggers = {} for i = 1, #trig do if trig[i] then s.triggers[#s.triggers + 1] = trig[i] end end end
        -- v1.1.5/1.2.6: список фраз автоответа (ключи replyLine1..replyLine30)
        if s.replyLine1 or s.replyLine2 or s.replyLine3 then
            local rl = {}
            for ln = 1, 30 do
                local v = s["replyLine" .. ln]
                if v and v ~= "" then rl[#rl + 1] = v end
            end
            if #rl > 0 then s.replyLines = rl end
        end
        -- v1.2.6: фразы по окончанию миниигры (ключи finishLine1..5)
        local fl = {}
        for ln = 1, 5 do
            local v = s["finishLine" .. ln]
            if v and v ~= "" then fl[#fl + 1] = v end
        end
        if #fl > 0 then s.finishLines = fl end
        -- v1.2.6: фразы при переводе денег до 4000 (ключи moneyLowLine1..5)
        local mll = {}
        for ln = 1, 5 do
            local v = s["moneyLowLine" .. ln]
            if v and v ~= "" then mll[#mll + 1] = v end
        end
        if #mll > 0 then s.moneyLowLines = mll end
        -- v1.2.6: фразы при переводе денег от 4001 (ключи moneyHighLine1..5)
        local mhl = {}
        for ln = 1, 5 do
            local v = s["moneyHighLine" .. ln]
            if v and v ~= "" then mhl[#mhl + 1] = v end
        end
        if #mhl > 0 then s.moneyHighLines = mhl end
        -- v1.3.1: фразы на сообщение сервера «Капот транспорта должен быть открыт»
        local hl = {}
        for ln = 1, 5 do
            local v = s["hoodLine" .. ln]
            if v and v ~= "" then hl[#hl + 1] = v end
        end
        if #hl > 0 then s.hoodLines = hl end
        -- v1.1.6: исключённые id водителей (ключи excludeId1..N)
        local ei = {}
        local en = 1
        while s["excludeId" .. en] do
            local num = tonumber(s["excludeId" .. en])
            if num and num >= 1 and num <= 1004 and num == math.floor(num) then
                ei[#ei + 1] = num
            end
            en = en + 1
        end
        if #ei > 0 then s.excludedIds = ei end
        -- v1.3.5: исключённые id по блокам фраз (blockExcl<Блок>1..N)
        for _, bn in ipairs({ "Reply", "Finish", "MoneyLow", "MoneyHigh", "Hood" }) do
            local arr = {}
            local idx = 1
            while s["blockExcl" .. bn .. idx] do
                local num = tonumber(s["blockExcl" .. bn .. idx])
                if num and num >= 1 and num <= 1004 and num == math.floor(num) then
                    arr[#arr + 1] = num
                end
                idx = idx + 1
            end
            if #arr > 0 then s["blockExcl" .. bn] = arr end
        end
    end
    -- защита от повреждённых значений старых версий (в ini попали байты
    -- EF BF BD = символы замены U+FFFD вместо CP1251): тогда берём дефолт
    local fffd = string.char(0xEF, 0xBF, 0xBD)
    s.replyLines = s.replyLines or {}
    if #s.replyLines == 0 then
        -- старый формат: одна фраза replyText (v1.1.0-v1.1.4) - первая фраза
        if s.replyText and s.replyText ~= "" and not s.replyText:find(fffd, 1, true) then
            s.replyLines[1] = s.replyText
        end
        -- доводим список минимум до двух фраз (для выбора «не повторять»)
        local defs = {
            "Починю быстро за хороший чай! Заранее спасибо!",
            "Подгони машину поближе, начну ремонт!",
        }
        for i = 1, #defs do
            local dup = false
            for j = 1, #s.replyLines do
                if s.replyLines[j] == defs[i] then dup = true break end
            end
            if not dup and #s.replyLines < 2 then
                s.replyLines[#s.replyLines + 1] = defs[i]
            end
        end
    else
        -- вычищаем пустые/повреждённые (U+FFFD) фразы из сохранённого списка
        local tmp = {}
        for i = 1, #s.replyLines do
            local t = s.replyLines[i]
            if t and t ~= "" and not t:find(fffd, 1, true) then tmp[#tmp + 1] = t end
        end
        s.replyLines = tmp
    end
    if #s.replyLines == 0 then
        s.replyLines = { "Починю быстро за хороший чай! Заранее спасибо!", "Подгони машину поближе, начну ремонт!" }
    end
    -- v1.2.6: вычищаем пустые/повреждённые (U+FFFD) фразы новых списков
    -- и подставляем дефолтные, если пользователь ещё не задал свои
    local function cleanNewList(lst)
        local tmp = {}
        for i = 1, #(lst or {}) do
            local t = lst[i]
            if t and t ~= "" and not t:find(fffd, 1, true) then tmp[#tmp + 1] = t end
        end
        return tmp
    end
    s.finishLines = cleanNewList(s.finishLines)
    s.moneyLowLines = cleanNewList(s.moneyLowLines)
    s.moneyHighLines = cleanNewList(s.moneyHighLines)
    s.hoodLines = cleanNewList(s.hoodLines)
    if #s.finishLines == 0 then
        s.finishLines = {
            "Готово!",
            "Ремонт завершён",
            "Машина как новая",
            "Спасибо за ожидание!",
            "Можете забирать!",
        }
    end
    if #s.moneyLowLines == 0 then
        s.moneyLowLines = {
            "Спасибо за оплату!",
            "Принято, приятно иметь дело!",
            "Спасибо, приходите ещё!",
            "Оплата получена, спасибо!",
            "Благодарю за перевод!",
        }
    end
    if #s.moneyHighLines == 0 then
        s.moneyHighLines = {
            "Ого, спасибо за щедрую оплату!",
            "Большое спасибо за щедрый бонус!",
            "Ценю вашу щедрость, спасибо!",
            "Спасибо за отличную оплату!",
            "Приятно с вами работать, спасибо!",
        }
    end
    -- v1.3.1: фразы на просьбу сервера открыть капот (по умолчанию 2)
    if #s.hoodLines == 0 then
        s.hoodLines = {
            "Капот открываю, секунду!",
            "Уже открываю капот, начинаю ремонт!",
        }
    end
    -- v1.1.8: диапазон случайной задержки перед закрытием миниигры.
    -- Ключи delayMinMs/delayMaxMs (мс); в старых конфигах был только
    -- одиночный delayMs - разворачиваем его в диапазон ±1000 мс.
    if s.delayMinMs == nil and s.delayMaxMs == nil then
        if s.delayMs then
            s.delayMinMs = math.max(0, s.delayMs - 1000)
            s.delayMaxMs = s.delayMs + 1000
        else
            s.delayMinMs, s.delayMaxMs = 2000, 5000
        end
    end
    s.delayMinMs = tonumber(s.delayMinMs) or s.delayMinMs or 2000
    s.delayMaxMs = tonumber(s.delayMaxMs) or s.delayMaxMs or 5000
    if s.delayMinMs < 0 then s.delayMinMs = 0 end
    if s.delayMaxMs < 0 then s.delayMaxMs = 0 end
    if s.delayMaxMs > 20000 then s.delayMaxMs = 20000 end
    if s.delayMinMs > 20000 then s.delayMinMs = 20000 end
    if s.delayMinMs > s.delayMaxMs then s.delayMinMs = s.delayMaxMs end
    -- v1.3.2: диапазон задержки фраз в чат (секунды, 0..600)
    s.replyDelayMinSec = tonumber(s.replyDelayMinSec) or 1
    s.replyDelayMaxSec = tonumber(s.replyDelayMaxSec) or 2
    if s.replyDelayMinSec < 0 then s.replyDelayMinSec = 0 end
    if s.replyDelayMinSec > 600 then s.replyDelayMinSec = 600 end
    if s.replyDelayMaxSec < 0 then s.replyDelayMaxSec = 0 end
    if s.replyDelayMaxSec > 600 then s.replyDelayMaxSec = 600 end
    if s.replyDelayMinSec > s.replyDelayMaxSec then s.replyDelayMinSec = s.replyDelayMaxSec end
    return s
end
local settings = loadSettings()

-- ---------- Настраиваемая кнопка показа курсора ----------
-- Список кнопок: кнопки мыши (включая дополнительные боковые) и клавиши.
-- vk — виртуальный код Windows для GetAsyncKeyState.
local cursorButtonList = {
    { name = "Средняя (ММБ)",  vk = 0x04 },
    { name = "Боковая 1 (X1)", vk = 0x05 },
    { name = "Боковая 2 (X2)", vk = 0x06 },
    { name = "Левая (ЛМБ)",    vk = 0x01 },
    { name = "Правая (ПМБ)",   vk = 0x02 },
    { name = "Ctrl",           vk = 0x11 },
    { name = "Shift",          vk = 0x10 },
    { name = "Alt (меню)",     vk = 0x12 },
    { name = "Пробел",         vk = 0x20 },
}
local cursorButtonNames = {}
for i = 1, #cursorButtonList do cursorButtonNames[i] = u8(cursorButtonList[i].name) end

-- индекс кнопки в списке по её vk (1, если vk неизвестен)
local function cursorButtonIndex(vk)
    for i = 1, #cursorButtonList do
        if cursorButtonList[i].vk == vk then return i end
    end
    return 1
end

-- ---------- Триггеры авто-ремонта (редактируются в меню) ----------
-- Фразы храним в CP1251 (как сам файл и как тексты из чата), а в imgui
-- показываем через u8(). Ввод из InputText приходит в UTF-8, поэтому
-- перед сохранением декодируем через u8:decode.
local repairTriggers = settings.triggers
-- буфер ввода нового триггера в меню (imgui, UTF-8)
local triggerInput = imgui.ImBuffer(64)
-- флаг «была попытка добавить пустую/дубль» для подсказки в меню
local addTriggerHint = imgui.ImBool(false)

local function toCp(str)
    if not str or str == "" then return "" end
    local ok, res = pcall(u8.decode, u8, str)
    if ok and res then return res end
    return str
end

local function triggerExists(t)
    for i = 1, #repairTriggers do
        if repairTriggers[i]:lower() == t:lower() then return true end
    end
    return false
end

local function addTrigger(t)
    t = toCp(t)
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" or triggerExists(t) then return false end
    repairTriggers[#repairTriggers + 1] = t
    saveSettings()
    return true
end

local function removeTrigger(idx)
    if idx < 1 or idx > #repairTriggers then return end
    table.remove(repairTriggers, idx)
    saveSettings()
end

local optEnabled = imgui.ImBool(settings.enabled)
-- v1.2.7: мастер-выключатель всего чита (кнопка в шапке окна)
local optCheat = imgui.ImBool(settings.cheatEnabled)
-- v1.3.7: чит по умолчанию выключен. Для старых ini (cheatEnabled = true)
-- без метки cheatOffMigrated один раз принудительно выключаем чит.
if not settings.cheatOffMigrated then
    optCheat.v = false
    settings.cheatEnabled = false
end
-- задержка после старта миниигры до отправки финиша, мс
local optDelayMs = imgui.ImInt(settings.delayMs)
-- v1.3.4: диапазон случайной задержки перед закрытием миниигры, СЕКУНДЫ (0..20)
local optDelayMinSec = imgui.ImInt(math.max(0, math.min(20, math.floor((settings.delayMinMs or 0) / 1000 + 0.5))))
local optDelayMaxSec = imgui.ImInt(math.max(0, math.min(20, math.floor((settings.delayMaxMs or 0) / 1000 + 0.5))))
-- авто-старт ремонта при появлении окна Interactions
local optAutoStart = imgui.ImBool(settings.autoStart)
-- задержка после появления окна до клика, мс
local optStartDelayMs = imgui.ImInt(settings.startDelayMs)
-- авто-ремонт по сообщениям в чат («почини», «чини» и т.п.)
local optAutoRepair = imgui.ImBool(settings.autoRepair)
-- пауза между автозапросами /repair, мс
local optRepairCooldown = imgui.ImInt(settings.repairCooldown)
-- автоответ в чат после принятия заявки на ремонт
local optAutoReply = imgui.ImBool(settings.autoReply)
-- список входов фраз автоответа (до 30): каждое поле GUI привязано к
-- v1.2.4: поле вмещает до 83 кириллических символов (буфер 168 байт UTF-8)
-- v1.2.6: количество полей увеличено до 30, добавлена вставка блоком
-- своему буферу; imgui работает в UTF-8, в ini сохраняем CP1251 (v1.1.5)
local optReplyLines = {}
for i = 1, 30 do
    optReplyLines[i] = imgui.ImBuffer(168) -- v1.2.4: до 83 кириллических символов (UTF-8)
end
-- количество активных полей фраз (1..30, сколько задано в настройках)
local replyCount = imgui.ImInt(math.max(1, math.min(#(settings.replyLines or {}), 30)))
for i = 1, replyCount.v do
    optReplyLines[i].v = u8(settings.replyLines[i] or "")
end
-- v1.2.6: поле вставки блока фраз (каждая строка = отдельная фраза)
local replyBlockInput = imgui.ImBuffer(3072)
-- разбирает replyBlockInput по строкам и добавляет фразы в список (до 30);
-- возвращает true, если хоть одна фраза добавлена (поле при этом очищается)
local function addReplyBlock()
    local raw = toCp(replyBlockInput.v or "")
    raw = raw:gsub("\r\n", "\n")
    local any = false
    for line in raw:gmatch("[^\n]+") do
        local t = line:gsub("^%s+", ""):gsub("%s+$", "")
        if t ~= "" and replyCount.v < 30 then
            replyCount.v = replyCount.v + 1
            optReplyLines[replyCount.v].v = u8(t)
            any = true
        end
    end
    if any then replyBlockInput.v = "" end
    return any
end
-- v1.2.6: фразы по окончанию миниигры (до 5)
local optFinishLines = {}
for i = 1, 5 do optFinishLines[i] = imgui.ImBuffer(168) end
local finishCount = imgui.ImInt(math.max(1, math.min(#(settings.finishLines or {}), 5)))
for i = 1, finishCount.v do
    optFinishLines[i].v = u8(settings.finishLines[i] or "")
end
-- v1.2.6: фразы при переводе денег до 4000 (до 5)
local optMoneyLowLines = {}
for i = 1, 5 do optMoneyLowLines[i] = imgui.ImBuffer(168) end
local moneyLowCount = imgui.ImInt(math.max(1, math.min(#(settings.moneyLowLines or {}), 5)))
for i = 1, moneyLowCount.v do
    optMoneyLowLines[i].v = u8(settings.moneyLowLines[i] or "")
end
-- v1.2.6: фразы при переводе денег от 4001 (до 5)
local optMoneyHighLines = {}
for i = 1, 5 do optMoneyHighLines[i] = imgui.ImBuffer(168) end
local moneyHighCount = imgui.ImInt(math.max(1, math.min(#(settings.moneyHighLines or {}), 5)))
for i = 1, moneyHighCount.v do
    optMoneyHighLines[i].v = u8(settings.moneyHighLines[i] or "")
end
-- v1.3.1: фразы на сообщение «Капот транспорта должен быть открыт» (до 5)
local optHoodLines = {}
for i = 1, 5 do optHoodLines[i] = imgui.ImBuffer(168) end
local hoodCount = imgui.ImInt(math.max(1, math.min(#(settings.hoodLines or {}), 5)))
for i = 1, hoodCount.v do
    optHoodLines[i].v = u8(settings.hoodLines[i] or "")
end
-- режим выбора цели курсором: удержание колесика 1 сек -> показать/скрыть курсор,
-- короткий клик по машине -> /repair её водителю
local optCursorPick = imgui.ImBool(settings.cursorPick)
-- кнопка показа курсора (индекс в cursorButtonList) и задержка удержания, сек
local optCursorButton = imgui.ImInt(cursorButtonIndex(settings.cursorButton or 0x04))
local optCursorDelaySec = imgui.ImFloat((settings.cursorDelayMs or 1000) / 1000)
-- текущий виртуальный код выбранной кнопки
local function currentCursorVk()
    local it = cursorButtonList[optCursorButton.v]
    return (it and it.vk) or 0x04
end
local optNearRepair = imgui.ImBool(settings.nearRepair)    -- авто-ремонт заявок в радиусе
local optNearRadiusM = imgui.ImInt(settings.nearRadiusM) -- радиус в метрах
local optNearDelaySec = imgui.ImInt(settings.nearDelaySec) -- пауза между отправками, сек
-- ручной режим подбора: /repair по клику правой кнопки мыши (v1.1.4)
local optManualRmb = imgui.ImBool(settings.manualRmb)
-- v1.2.9: ESP-метки цели ремонта (линия/квадрат/плашка)
local optEspLine = imgui.ImBool(settings.espLine)
local optEspBox = imgui.ImBool(settings.espBox)
local optEspPanel = imgui.ImBool(settings.espPanel)
-- v1.3.2: диапазон задержки перед отправкой фраз в чат (секунды)
local optReplyDelayMin = imgui.ImInt(settings.replyDelayMinSec or 1)
local optReplyDelayMax = imgui.ImInt(settings.replyDelayMaxSec or 2)

-- ---------- v1.1.6: исключённые id водителей ----------
-- Им не шлём /repair ни в авто-режиме, ни по ПКМ, ни колесиком (курсором):
-- если ближайшая машина имеет исключённого водителя, запрос уходит следующей
-- по близости машине, чей водитель не исключён.
local excludedIds = {}
for i = 1, #(settings.excludedIds or {}) do
    excludedIds[#excludedIds + 1] = settings.excludedIds[i]
end
local excludeIdHint = ""       -- текст ошибки добавления id (для GUI)
local excludeIdInput = imgui.ImBuffer(16) -- поле ввода нового id в GUI

local function idExcluded(pid)
    for i = 1, #excludedIds do
        if excludedIds[i] == pid then return true end
    end
    return false
end

-- добавляет id в список; возвращает nil при успехе или строку-причину ошибки
local function addExcludedId(idText)
    local num = tonumber(idText)
    if not num or num ~= math.floor(num) or num < 1 or num > 1004 then
        return "id должен быть целым числом от 1 до 1004"
    end
    if idExcluded(num) then
        return "такой id уже есть в списке"
    end
    excludedIds[#excludedIds + 1] = num
    saveSettings()
    return nil
end

local function removeExcludedId(i)
    table.remove(excludedIds, i)
    saveSettings()
end

local activeTab = 1
local showMenu = imgui.ImBool(false)

-- ---------- Состояние миниигры ----------
local state = {
    active = false,    -- миниигра сейчас идёт
    title = "",        -- название миниигры
    busy = false,      -- поток автозакрытия уже запущен
    autoStarting = false, -- поток авто-старта уже запущен
    lastRepair = 0,    -- время последнего автозапроса /repair (GetTickCount, мс)
    lastAutoReply = 0, -- время последнего автоответа в чат (GetTickCount, мс)
    lastAutoReplyText = "", -- последняя отправленная фраза автоответа (CP1251, v1.1.5)
    replyCycle = { pool = {}, idx = 1 }, -- v1.2.2/1.2.6: пул фраз автоответа
    finishCycle = { pool = {}, idx = 1 }, -- v1.2.6: пул фраз по окончанию миниигры
    moneyLowCycle = { pool = {}, idx = 1 }, -- v1.2.6: пул фраз за деньги до 4000
    moneyHighCycle = { pool = {}, idx = 1 }, -- v1.2.6: пул фраз за деньги от 4001
    lastMoneyLow = 0,  -- v1.2.6: время последнего ответа за деньги до 4000 (GetTickCount)
    lastMoneyHigh = 0, -- v1.2.6: время последнего ответа за деньги от 4001 (GetTickCount)
    hoodCycle = { pool = {}, idx = 1 }, -- v1.3.1: пул фраз на просьбу открыть капот
    lastHood = 0, -- v1.3.1: время последнего ответа на просьбу открыть капот (GetTickCount)
    cursorVisible = false, -- курсор выбора цели показан (по удержанию колесика)
    -- ---------- v1.1.1: авто-ремонт подъехавших в радиус ----------
    nearQueue = {},      -- таблица прошлых /repair: veh -> nowMs
    nearWaiting = false, -- ждём завершения текущей миниигры (после отправки /repair)
    nearSawActive = false, -- миниигра уже началась (для детекта конца)
    nearLockUntil = 0,   -- не отправлять раньше этого времени (GetTickCount)
    nearSentAt = 0,      -- время последней отправки /repair в ближнем режиме (GetTickCount)
    pendingRepair = nil, -- v1.1.7: последняя отправленная заявка /repair (для уведомления)
    espTarget = nil, -- v1.2.9: цель ESP {pid, veh, at} (линия/квадрат/плашка)
}

-- ========== v1.3.5: блоки фраз - вкл/выкл и исключения по id ==========
-- Блоки фраз: автоответ на старт ремонта (reply), фразы по окончанию
-- миниигры (finish), ответы на перевод до 4000 / от 4001 (moneyLow/
-- moneyHigh) и ответ на просьбу открыть капот (hood). У каждого блока -
-- своя галочка (вкл/выкл) и свой список id, которым фразы не шлются.
-- Всё состояние блоков собрано в одну таблицу phraseBlocks, чтобы не
-- превысить лимит upvalue (60) в большой функции отрисовки GUI.
local phraseBlocks = {
    keys = { "reply", "finish", "moneyLow", "moneyHigh", "hood" },
    tag = { reply = "Reply", finish = "Finish", moneyLow = "MoneyLow", moneyHigh = "MoneyHigh", hood = "Hood" },
    title = {
        reply = "Автоответ на старт ремонта",
        finish = "Фразы по окончанию миниигры",
        moneyLow = "Ответ на перевод до 4000 руб",
        moneyHigh = "Ответ на перевод от 4001 руб",
        hood = "Ответ на просьбу открыть капот",
    },
    on = {},    -- ключ блока -> imgui.ImBool (галочка вкл/выкл)
    excl = {},  -- ключ блока -> список исключённых id
    input = {}, -- ключ блока -> поле ввода нового id (GUI)
    hint = {},  -- ключ блока -> текст ошибки ввода (GUI)
}
for _, key in ipairs(phraseBlocks.keys) do
    local tag = phraseBlocks.tag[key]
    local onVal = settings["blockOn" .. tag]
    if onVal == nil then onVal = true end
    phraseBlocks.on[key] = imgui.ImBool(onVal and true or false)
    local arr = {}
    local sarr = settings["blockExcl" .. tag]
    for i = 1, #(sarr or {}) do arr[#arr + 1] = sarr[i] end
    phraseBlocks.excl[key] = arr
    phraseBlocks.input[key] = imgui.ImBuffer(16)
    phraseBlocks.hint[key] = ""
end

-- id входит в список исключений блока?
local function blockExcluded(key, pid)
    local list = phraseBlocks.excl[key]
    if not list then return false end
    for i = 1, #list do
        if list[i] == pid then return true end
    end
    return false
end

-- можно ли отправлять фразы блока (галочка включена и игрок не исключён);
-- pid может быть nil - тогда проверяется только галочка.
local function blockAllowed(key, pid)
    local on = phraseBlocks.on[key]
    if on and not on.v then return false end
    if pid and blockExcluded(key, pid) then return false end
    return true
end

-- добавить id в список блока; nil при успехе либо строка-причина ошибки
local function addBlockExcludedId(key, idText)
    if not phraseBlocks.excl[key] then return "неизвестный блок" end
    local num = tonumber(idText)
    if not num or num ~= math.floor(num) or num < 1 or num > 1004 then
        return "id должен быть целым числом от 1 до 1004"
    end
    if blockExcluded(key, num) then
        return "такой id уже есть в списке"
    end
    phraseBlocks.excl[key][#phraseBlocks.excl[key] + 1] = num
    saveSettings()
    return nil
end
phraseBlocks.addExcludedId = addBlockExcludedId

-- v1.3.5: id клиента, которому шлём фразы ремонта: последняя отправленная
-- заявка /repair либо текущая ESP-цель. nil, если цель неизвестна.
local function currentTargetPid()
    local p = state.pendingRepair
    if p and p.pid and nowMs() - (p.at or 0) <= 300000 then return p.pid end
    local e = state.espTarget
    if e and e.pid and nowMs() - (e.at or 0) <= 300000 then return e.pid end
    return nil
end

-- v1.3.5: id игрока по тексту сообщения - ищем в тексте ник любого
-- подключённого игрока (для исключений в блоках переводов денег).
local function idFromRawText(raw)
    if type(raw) ~= "string" or raw == "" then return nil end
    if type(sampGetPlayerNickname) ~= "function" then return nil end
    local maxId = 1004
    if type(sampGetMaxPlayerId) == "function" then
        local okM, m = pcall(sampGetMaxPlayerId)
        if okM and tonumber(m) and tonumber(m) > 0 then maxId = tonumber(m) end
    end
    local hasConn = (type(sampIsPlayerConnected) == "function")
    for id = 0, maxId do
        local connected = true
        if hasConn then
            local okC, c = pcall(sampIsPlayerConnected, id)
            connected = (okC and c) and true or false
        end
        if connected then
            local okN, nick = pcall(sampGetPlayerNickname, id)
            if okN and nick and nick ~= "" and raw:find(nick, 1, true) then
                return id
            end
        end
    end
    return nil
end

-- v1.3.5: id отправителя перевода - читаем сырой текст пакета (93/101)
local function payloadMoneySenderId(bs)
    local okTotal, total = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not okTotal or not total or total <= 0 or total > 4096 then return nil end
    pcall(raknetBitStreamResetReadPointer, bs)
    local okR, raw = pcall(raknetBitStreamReadString, bs, total)
    pcall(raknetBitStreamResetReadPointer, bs)
    if not okR or not raw or raw == "" then return nil end
    return idFromRawText(raw)
end

-- v1.3.6: единая отрисовка списка фраз блока (поля ввода, кнопка «х»,
-- кнопка добавления). Возвращает true, если что-то изменилось.
local function drawPhraseList(lines, count, maxCount, idBase, labelPrefix, addLabel)
    local changedList = false
    imgui.PushItemWidth(280 * fsc)
    for i = 1, count.v do
        imgui.PushID(idBase + i)
        if imgui.InputText(u8("   " .. labelPrefix .. " " .. i .. "##phraseLine"), lines[i]) then changedList = true end
        imgui.SameLine(0, 6)
        if count.v > 1 then
            if imgui.SmallButton(u8"х") then
                for j = i, count.v - 1 do lines[j].v = lines[j + 1].v end
                lines[count.v].v = ""
                count.v = count.v - 1
                changedList = true
            end
        end
        imgui.PopID()
    end
    imgui.PopItemWidth()
    if count.v < maxCount then
        if imgui.Button(u8(addLabel), imgui.ImVec2(170 * fsc, 0)) then
            count.v = count.v + 1
            lines[count.v].v = ""
            changedList = true
        end
    end
    return changedList
end

function saveSettings()
    local lines = {
        "enabled = " .. (optEnabled.v and "true" or "false"),
        "cheatEnabled = " .. (optCheat.v and "true" or "false"),
        "cheatOffMigrated = true",
        "delayMs = " .. optDelayMs.v,
        "delayMinMs = " .. (optDelayMinSec.v * 1000),
        "delayMaxMs = " .. (optDelayMaxSec.v * 1000),
        "autoStart = " .. (optAutoStart.v and "true" or "false"),
        "startDelayMs = " .. optStartDelayMs.v,
        "autoRepair = " .. (optAutoRepair.v and "true" or "false"),
        "repairCooldown = " .. optRepairCooldown.v,
        "autoReply = " .. (optAutoReply.v and "true" or "false"),
        "replyDelayMinSec = " .. optReplyDelayMin.v,
        "replyDelayMaxSec = " .. optReplyDelayMax.v,
        "cursorPick = " .. (optCursorPick.v and "true" or "false"),
        "cursorButton = " .. currentCursorVk(),
        "cursorDelayMs = " .. math.floor((optCursorDelaySec.v or 1.0) * 1000 + 0.5),
        "nearRepair = " .. (optNearRepair.v and "true" or "false"),
        "nearRadiusM = " .. optNearRadiusM.v,
        "nearDelaySec = " .. optNearDelaySec.v,
        "manualRmb = " .. (optManualRmb.v and "true" or "false"),
        "espLine = " .. (optEspLine.v and "true" or "false"),
        "espBox = " .. (optEspBox.v and "true" or "false"),
        "espPanel = " .. (optEspPanel.v and "true" or "false"),
    }
    -- фразы автоответа (v1.1.5): replyLineN = <фраза>; replyText = первая
    -- непустая фраза (её ещё читают старые версии скрипта как одиночный ответ)
    local firstReply = ""
    for i = 1, replyCount.v do
        local t = toCp(optReplyLines[i].v or "")
        lines[#lines + 1] = "replyLine" .. i .. " = " .. t
        if firstReply == "" and t ~= "" then firstReply = t end
    end
    lines[#lines + 1] = "replyText = " .. firstReply
    -- v1.2.6: фразы по окончанию миниигры (finishLineN)
    for i = 1, finishCount.v do
        lines[#lines + 1] = "finishLine" .. i .. " = " .. toCp(optFinishLines[i].v or "")
    end
    -- v1.2.6: фразы при переводе денег до 4000 (moneyLowLineN)
    for i = 1, moneyLowCount.v do
        lines[#lines + 1] = "moneyLowLine" .. i .. " = " .. toCp(optMoneyLowLines[i].v or "")
    end
    -- v1.2.6: фразы при переводе денег от 4001 (moneyHighLineN)
    for i = 1, moneyHighCount.v do
        lines[#lines + 1] = "moneyHighLine" .. i .. " = " .. toCp(optMoneyHighLines[i].v or "")
    end
    -- v1.3.1: фразы на просьбу открыть капот (hoodLineN)
    for i = 1, hoodCount.v do
        lines[#lines + 1] = "hoodLine" .. i .. " = " .. toCp(optHoodLines[i].v or "")
    end
    -- v1.3.5: блоки фраз - галочка вкл/выкл и исключённые id
    for _, key in ipairs(phraseBlocks.keys) do
        local tag = phraseBlocks.tag[key]
        lines[#lines + 1] = "blockOn" .. tag .. " = " .. (phraseBlocks.on[key].v and "true" or "false")
        local list = phraseBlocks.excl[key]
        for i = 1, #list do
            lines[#lines + 1] = "blockExcl" .. tag .. i .. " = " .. list[i]
        end
    end
    -- исключённые id водителей (v1.1.6): excludeIdN = <id>
    for i = 1, #excludedIds do
        lines[#lines + 1] = "excludeId" .. i .. " = " .. excludedIds[i]
    end
    -- триггеры авто-ремонта: triggerN = <фраза>
    for i = 1, #repairTriggers do
        lines[#lines + 1] = "trigger" .. i .. " = " .. repairTriggers[i]
    end
    local ok, f = pcall(io.open, iniFile, "w")
    if ok and f then
        f:write(table.concat(lines, "\r\n"))
        f:close()
    end
end
-- v1.2.7: переключение мастер-выключателя всего чита (кнопка в шапке).
-- При выключении сбрасываем активные состояния, чтобы зависшие проверки
-- и потоки ничего не запустили/не отправили.
function setCheatMaster(v)
    optCheat.v = v
    if not v then
        state.active = false
        state.busy = false
        state.autoStarting = false
        state.pendingRepair = nil
        state.espTarget = nil
        state.nearWaiting = false
        state.nearSawActive = false
    end
    saveSettings()
end

-- ---------- Формирование и отправка TX id=215 ----------
-- Структура пакета (как в auth.lua): 215 | int32(2) | 0,0 | int32(длина имени) | имя | аргументы
local function int32_le_bytes(v)
    v = v % 4294967296
    return { v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256 }
end

-- OnInteractionsClick (клик по кнопке окна Interactions): int32(2), байт 100 ('d'), int32(код)
local name_inter = { string.byte("OnInteractionsClick", 1, 19) }
-- OnHelloweenBuildComplete (успешный финиш): после имени int32(0) - без аргументов
local name_comp = { string.byte("OnHelloweenBuildComplete", 1, 24) }

local function build_packet(name_bytes, args)
    local p = {}
    local function push(x) p[#p + 1] = x end
    for _, b in ipairs(int32_le_bytes(2)) do push(b) end
    push(0); push(0)
    for _, b in ipairs(int32_le_bytes(#name_bytes)) do push(b) end
    for _, b in ipairs(name_bytes) do push(b) end
    if args then
        for _, b in ipairs(args) do push(b) end
    end
    return p
end

local function send_packet(name_bytes, args)
    if not isSampAvailable() then return false end
    local body = build_packet(name_bytes, args)
    local full = { 215 }
    for i = 1, #body do full[#full + 1] = body[i] end
    local ok_bs, bs = pcall(raknetNewBitStream)
    if not ok_bs or not bs then return false end
    local ok_w = pcall(function()
        for i = 1, #full do raknetBitStreamWriteInt8(bs, full[i]) end
    end)
    if not ok_w then
        raknetDeleteBitStream(bs)
        return false
    end
    local ok_s = pcall(raknetSendBitStream, bs)
    raknetDeleteBitStream(bs)
    return ok_s == true
end

local function sendComplete()
    -- аргументов нет: int32(0)
    return send_packet(name_comp, { 0, 0, 0, 0 })
end

local function sendInteractionsClick(code)
    -- аргументы: int32(2), байт 100 ('d'), int32(код кнопки)
    local b = int32_le_bytes(code or 0)
    local args = { 2, 0, 0, 0, 100, b[1], b[2], b[3], b[4] }
    return send_packet(name_inter, args)
end

-- ---------- Чтение RX id=215 в текст ----------
local function readBodyText(bs)
    local len = 0
    local ok_len, l = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if ok_len and l and l > 0 then len = l end
    local txt = ""
    local max_len = math.min(len, 4096)
    for i = 1, max_len do
        local ok_b, b = pcall(raknetBitStreamReadInt8, bs)
        if not ok_b then break end
        if b >= 32 and b <= 255 then txt = txt .. string.char(b) end
    end
    pcall(raknetBitStreamResetReadPointer, bs)
    return txt
end

-- ---------- Поиск кода кнопки «Начать работу» в тексте setInfo ----------
-- Формат RX: interface('Interactions').setInfo('[[48,"Завершить работу"],[153,"Начать работу"]]')
-- Возвращает код кнопки, у которой подпись содержит «Начать»; иначе nil.
-- Кнопку «Завершить работу» (48) НЕ трогаем - она завершает работу механика в целом.
local function findStartButtonCode(txt)
    local code = nil
    local pos = 1
    while true do
        local s, e, c, lbl = txt:find('%[(%d+),%"([^"]+)%"]', pos)
        if not s then break end
        if lbl:find("Начать", 1, true) then
            code = tonumber(c)
            break
        end
        pos = e + 1
    end
    return code
end

-- ---------- Поток авто-старта ремонта ----------
local function startMinigameThread(code)
    -- ждём, пока окно Interactions отрисуется, затем кликаем «Начать работу»
    if optStartDelayMs.v > 0 then wait(optStartDelayMs.v) end
    if state.autoStarting and code and code ~= 48 then
        sendInteractionsClick(code)
    end
    state.autoStarting = false
end

-- ---------- Поток автозакрытия миниигры ----------
local function finishMinigameThread()
    state.busy = true
    -- v1.1.8: при КАЖДОЙ новой миниигре время до успешного финиша
    -- выбирается СЛУЧАЙНО в диапазоне от/до (мс), заданном игроком
    -- в GUI. Если границы совпали/выродились - берём это значение.
    local delayMin, delayMax = (optDelayMinSec.v or 0) * 1000, (optDelayMaxSec.v or 0) * 1000
    if delayMin > delayMax then delayMin, delayMax = delayMax, delayMin end
    if delayMin < 0 then delayMin = 0 end
    if delayMax < 0 then delayMax = 0 end
    local delay = delayMin
    if delayMax > delayMin then
        -- подсед от реального времени: каждое значение непредсказуемо
        math.randomseed(nowMs() + math.random(0, 32767))
        delay = delayMin + math.random(0, delayMax - delayMin)
    end
    if delay > 0 then wait(delay) end
    if state.active and optEnabled.v and optCheat.v then
        sendComplete()
    end
    state.busy = false
end

-- ---------- Выбор машины курсором (колесико -> /repair водителю) ----------
-- В режиме optCursorPick игрок наводит курсор мыши на машину на экране
-- и кликает колесиком: скрипт проецирует позиции машин на экран, берёт
-- ближайшую к курсору и шлёт /repair <id водителя>.
-- Позиция машины читается из памяти (как в LesByYaroRage): у нативных API
-- нет готовой функции, getVehiclePosition в этой сборке отсутствует.
local function getVehiclePos(veh)
    if type(getCarPointer) == "function" then
        local okP, ptr = pcall(getCarPointer, veh)
        if okP and ptr and ptr > 0x100000 and ptr < 0x40000000 then
            local okM, matrixPtr = pcall(readMemory, ptr + 0x14, 4, false)
            if okM and matrixPtr and matrixPtr > 0x100000 and matrixPtr < 0x40000000 then
                local posPtr = matrixPtr + 0x30
                local okX, x = pcall(readMemory, posPtr + 0, 4, false)
                local okY, y = pcall(readMemory, posPtr + 4, 4, false)
                local okZ, z = pcall(readMemory, posPtr + 8, 4, false)
                if okX and okY and okZ and x and y and z then
                    local of = (type(representIntAsFloat) == "function")
                    local function conv(v) if of then return representIntAsFloat(v) else return v end end
                    return conv(x), conv(y), conv(z)
                end
            end
        end
    end
    -- фолбэк: если есть нативная функция
    if type(getVehiclePosition) == "function" then
        local ok, x, y, z = pcall(getVehiclePosition, veh)
        if ok and x and y and z then return x, y, z end
    end
    return nil
end

-- ---------- v1.1.7: модели машин, мотоциклы, уведомление «Чиню ...» ----------
-- Названия моделей берём из ресурса LesByYaroRage\LesCarNames.txt (те же,
-- что показывает скрипт Les). Файл в CP1251, как и сам скрипт.
local vehicleNames = {}
do
    local dir = thisScript().directory
    local f = io.open(dir .. "\\LesByYaroRage\\LesCarNames.txt", "r")
    if not f then f = io.open(dir .. "\\LesCarNames.txt", "r") end
    if f then
        for ln in f:lines() do
            local eq = string.find(ln, "=", 1, true)
            if eq then
                local id = tonumber(string.sub(ln, 1, eq - 1))
                if id then vehicleNames[id] = string.sub(ln, eq + 1) end
            end
        end
        f:close()
    end
end

-- id модели транспорта: нативный getCarModel либо чтение из памяти
-- (CEntity.m_nModelIndex = ptr + 0x22), как в getVehiclePos
local function getModelId(veh)
    if type(getCarModel) == "function" then
        local ok, m = pcall(getCarModel, veh)
        if ok and m then return m end
    end
    if type(getCarPointer) == "function" and type(readMemory) == "function" then
        local okP, ptr = pcall(getCarPointer, veh)
        if okP and ptr and ptr > 0x100000 and ptr < 0x40000000 then
            local okM, model = pcall(readMemory, ptr + 0x22, 2, false)
            if okM and model and model > 0 and model < 1000 then return model end
        end
    end
    return nil
end

-- v1.1.7: мотоциклы получают /repair раньше машин (приоритет в радиусе)
local motoModels = {
    [448] = true, [461] = true, [462] = true, [463] = true, [468] = true,
    [521] = true, [522] = true, [523] = true, [581] = true, [586] = true,
}
local function isMoto(veh)
    local m = getModelId(veh)
    return m and motoModels[m] or false
end

-- название модели машины: имя из LesCarNames.txt, иначе заводское
local function vehicleDisplayName(veh)
    local model = getModelId(veh)
    if not model then return "" end
    local name = vehicleNames[model]
    if not name or name == "" then
        if type(getNameOfVehicleModel) == "function" then
            local okN, n = pcall(getNameOfVehicleModel, model)
            if okN and n then name = n end
        end
    end
    return name or ("ID:" .. model)
end

-- v1.1.7: водитель принял заявку /repair - показываем ТОЛЬКО пользователю
-- (не в общий чат): «Чиню <ник> (id) - <модель машины>». pid/veh заполняются
-- при каждой отправке /repair в state.pendingRepair.
local function notifyRepairAccepted()
    local p = state.pendingRepair
    if not p or not p.pid then return end
    -- заявка слишком старая (5 мин) - водитель так и не принял, забываем
    if nowMs() - p.at > 300000 then state.pendingRepair = nil return end
    state.pendingRepair = nil
    local nick = nil
    if type(sampGetPlayerNickname) == "function" then
        local okN, n = pcall(sampGetPlayerNickname, p.pid)
        if okN and n and n ~= "" then nick = n end
    end
    local msg
    if nick then
        msg = "Чиню " .. nick .. " (" .. p.pid .. ")"
    else
        msg = "Чиню id " .. p.pid
    end
    if p.veh then
        local modelName = vehicleDisplayName(p.veh)
        if modelName ~= "" then msg = msg .. " — " .. modelName end
    end
    if type(sampAddChatMessage) == "function" then
        pcall(sampAddChatMessage, msg, 0xFF00CCFF)
    end
end

-- ---------- v1.1.9: «Эвакуатор» (служебный транспорт механика) ----------
-- Модель 525 (Towtruck, в списке Les - «Эвакуатор»). Водителей за рулём
-- эвакуатора не чиним: служебный транспорт механика ремонту не подлежит.
local towtruckModels = { [525] = true }
-- персонаж игрока в «Эвакуаторе»? (используется статусом GUI и автоисключением)
local inTowtruck = false
-- машина, в которой сидит наш персонаж: натив getCarCharIsIn либо SAMPFUNCS
local function getMyCar()
    if type(getCarCharIsIn) == "function" then
        local ok, v = pcall(getCarCharIsIn, PLAYER_PED)
        if ok and v and v ~= 0 then return v end
    end
    if type(sampGetPlayerCarHandle) == "function" then
        local ok, v = pcall(sampGetPlayerCarHandle, 0)
        if ok and v and v ~= 0 then return v end
    end
    return nil
end
local function isTowtruck(veh)
    local m = getModelId(veh)
    return m and towtruckModels[m] or false
end
-- v1.1.9: раз в 0.5 сек проверяем, не сидит ли персонаж в эвакуаторе;
-- если да - его собственный id автоматически попадает в исключения
-- (и /repair ему не отправляется), как если бы он оставил это вручную.
local lastTowtruckCheck = 0
local function autoExcludeSelfInTowtruck()
    if nowMs() - lastTowtruckCheck < 500 then return end
    lastTowtruckCheck = nowMs()
    local myCar = getMyCar()
    inTowtruck = myCar and isTowtruck(myCar) or false
    if not inTowtruck then return end
    local selfId = 0
    if type(sampGetPlayerNickname) == "function" and type(sampGetPlayerIdByNickName) == "function" then
        local okN, nick = pcall(sampGetPlayerNickname, 0)
        if okN and nick and nick ~= "" then
            local okI, id = pcall(sampGetPlayerIdByNickName, nick)
            if okI and id then selfId = id or 0 end
        end
    end
    if selfId and selfId >= 1 and not idExcluded(selfId) then
        addExcludedId(selfId)
    end
end

-- ---------- v1.1.1: поиск ближайшей машины-игрока в радиусе метров ----------
-- машины игроков в радиусе radiusM вокруг персонажа игрока.
-- Возвращает veh, pid водителя (такой, которому ещё не слали /repair недавно).
local function findNearRepairTarget(radiusM, cooldownMs)
    -- cooldownMs — на сколько «замораживается» водитель после /repair
    -- (авто-режим: 300 сек; ручной по ПКМ: optNearDelaySec из GUI)
    cooldownMs = cooldownMs or 300000
    local okC, pcx, pcy, pcz = pcall(getCharCoordinates, PLAYER_PED)
    if not okC or not pcx or not pcy or not pcz then return nil end
    local okAv, vehicles = pcall(getAllVehicles)
    if not okAv or type(vehicles) ~= "table" then return nil end

    -- кандидаты: машины в радиусе с водителем-игроком
    local cands = {}
    for _, veh in pairs(vehicles) do
        local okV, vx, vy, vz = pcall(getVehiclePos, veh)
        if okV and vx and vy and vz then
            local dx, dy, dz = vx - pcx, vy - pcy, vz - pcz
            if dx * dx + dy * dy + dz * dz <= radiusM * radiusM then
                local okD, driver = pcall(getDriverOfCar, veh)
                if okD and driver and driver ~= 0 then
                    local okP, isP, pid = pcall(sampGetPlayerIdByCharHandle, driver)
                    -- v1.1.6: водители с исключённым id не получают /repair.
                    -- v1.1.9: водители за рулём «Эвакуатора» тоже не получают /repair
                    if okP and isP and pid and pid >= 1
                        and not idExcluded(pid) and not isTowtruck(veh) then
                        -- v1.1.7: помечаем мотоциклы - их чиним в первую очередь
                        cands[#cands + 1] = { veh = veh, pid = pid, moto = isMoto(veh), d = dx * dx + dy * dy + dz * dz }
                    end
                end
            end
        end
    end
    if #cands == 0 then return nil end

    -- чистим nearQueue от машин, которых уже нет в радиусе (уехали)
    local nowA = nowMs()
    for veh in pairs(state.nearQueue) do
        local still = false
        for _, c in ipairs(cands) do
            if c.veh == veh then still = true break end
        end
        if not still then state.nearQueue[veh] = nil end
    end

    -- v1.1.7: сначала мотоциклы, внутри группы — по близости к игроку
    table.sort(cands, function(a, b)
        if a.moto ~= b.moto then return a.moto end
        return a.d < b.d
    end)
    -- самая близкая из тех, кому ещё не слали (или слали давно — машина снова подъехала)
    for _, c in ipairs(cands) do
        local last = state.nearQueue[c.veh]
        if not last or nowA - last >= cooldownMs then
            state.nearQueue[c.veh] = nowA
            return c.veh, c.pid
        end
    end
    return nil
end

local function sendRepairByCursor()
    -- кулдаун 0.5 сек (wall-clock): защита от дубля и «через раз»
    if nowMs() - state.lastRepair < 500 then return end

    local mx, my = getMouseScreenPos()
    if mx < 0 or my < 0 then return end

    local okAv, vehicles = pcall(getAllVehicles)
    if not okAv or type(vehicles) ~= "table" then return end

    -- собираем все машины в радиусе 70 px и сортируем по расстоянию
    local cands = {}
    for _, veh in pairs(vehicles) do
        local vx, vy, vz = getVehiclePos(veh)
        if vx and vy and vz then
            local okS, sx, sy = pcall(convert3DCoordsToScreen, vx, vy, vz)
            if okS and sx and sy then
                local d = (sx - mx) ^ 2 + (sy - my) ^ 2
                if d <= 70 * 70 then
                    cands[#cands + 1] = { veh = veh, d = d }
                end
            end
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)

    -- среди 5 ближайших ищем первую с водителем-игроком
    for i = 1, math.min(#cands, 5) do
        local veh = cands[i].veh
        local okD, driver = pcall(getDriverOfCar, veh)
        if okD and driver and driver ~= 0 then
            local okP, isPlayer, pid = pcall(sampGetPlayerIdByCharHandle, driver)
            -- v1.1.6: исключённые id водителей пропускаем — берём следующего.
            -- v1.1.9: водителей за рулём «Эвакуатора» тоже пропускаем
            if okP and isPlayer and pid and pid >= 1
                and not idExcluded(pid) and not isTowtruck(veh) then
                state.lastRepair = nowMs()
                -- v1.1.7: запоминаем заявку для уведомления «Чиню ...»
                state.pendingRepair = { pid = pid, veh = veh, at = nowMs() }
                state.espTarget = { pid = pid, veh = veh, at = nowMs() }
                pcall(sampSendChat, "/repair " .. pid)
                return
            end
        end
    end
end

-- ---------- v1.1.4: ручной запрос /repair ближайшему в радиусе (по ПКМ) ----------
-- Клик правой кнопкой мыши шлёт /repair ближайшему водителю из машин-игроков
-- в радиусе optNearRadiusM. Отправленный водитель «замораживается» на паузу
-- optNearDelaySec (та же, что в GUI «Авто-подбор подъехавших машин»): пока
-- пауза не прошла, следующий клик выберет следующего по близости водителя,
-- а после паузы того же можно выбрать снова.
local function sendNearRepairManual()
    -- защита от сдвоенного клика
    if nowMs() - state.lastRepair < 300 then return end
    local vehId, pid = findNearRepairTarget(optNearRadiusM.v, optNearDelaySec.v * 1000)
    if pid then
        state.lastRepair = nowMs()
        -- v1.1.7: запоминаем заявку для уведомления «Чиню ...»
        state.pendingRepair = { pid = pid, veh = vehId, at = nowMs() }
        state.espTarget = { pid = pid, veh = vehId, at = nowMs() }
        pcall(sampSendChat, "/repair " .. pid)
    end
end

-- ---------- Авто-ремонт по сообщениям в чат ----------
-- Входящий чат приходит RPC id=101 (RPC_CHAT), структура:
-- int16 playerId, string8 text (байт длины + строка).
-- id игрока берём прямо из пакета - /repair отправляется по id, а не по нику.
-- чтение чат-RPC id=101 (SAMP 0.3.7): BYTE id отправителя, BYTE длина, строка.
-- В v1.1.2 id читался как Int16 (2 байта) - сдвиг на байт ломал длину/текст,
-- из-за чего автоответ на начало ремонта не отправлялся. Читаем с проверкой
-- размера пакета, чтобы не выйти за его конец.
local function chatTextValid(t)
    if not t or t == "" then return false end
    for i = 1, #t do
        if t:byte(i) < 32 then return false end
    end
    return true
end

local function readChatRpc(bs)
    pcall(raknetBitStreamResetReadPointer, bs)
    local okTotal, total = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not okTotal or type(total) ~= "number" then total = nil end

    -- основной формат: BYTE id, BYTE длина, строка (SAMP 0.3.7)
    pcall(raknetBitStreamResetReadPointer, bs)
    local okId, playerId = pcall(raknetBitStreamReadInt8, bs)
    local okLen, textLen = pcall(raknetBitStreamReadInt8, bs)
    if okId and okLen and playerId ~= nil and textLen and textLen > 0 and textLen <= 128
       and (not total or (2 + textLen) <= total) then
        local okT, t = pcall(raknetBitStreamReadString, bs, textLen)
        if okT and chatTextValid(t) then
            pcall(raknetBitStreamResetReadPointer, bs)
            return playerId, t
        end
    end

    -- запасной формат: Int16 id, BYTE длина, строка (старый вариант)
    pcall(raknetBitStreamResetReadPointer, bs)
    local okId16, pid16 = pcall(raknetBitStreamReadInt16, bs)
    local okLen16, len16 = pcall(raknetBitStreamReadInt8, bs)
    if okId16 and okLen16 and pid16 ~= nil and len16 and len16 > 0 and len16 <= 128
       and (not total or (3 + len16) <= total) then
        local okT16, t16 = pcall(raknetBitStreamReadString, bs, len16)
        if okT16 and chatTextValid(t16) then
            pcall(raknetBitStreamResetReadPointer, bs)
            return pid16, t16
        end
    end

    pcall(raknetBitStreamResetReadPointer, bs)
    return nil
end


-- автоответ в чат при старте ремонта: сервер пишет
-- «Подойдите к капоту и начните ремонт транспорта. У Вас есть 1 минута на ремонт.»
-- Значит водитель принял вашу заявку /repair и подъехал — скрипт отвечает
-- от имени персонажа обычным чат-сообщением. КУЛДАУН маленький (5 сек,
-- защита от дубля одной и той же надписи), а не 120 секунд — иначе при
-- частых заявках сообщение писалось бы только раз в 2 минуты.
--
-- ВАЖНО: фраза приходит как обычное чат-сообщение, поэтому в v1.1.3 она
-- ищется СРАЗУ В СЫРЫХ байтах пакета и для RPC id=101 (чат), и для id=93
-- (серверные сообщения) — так ответ не зависит от структуры полей пакета.
local repairStartPhrases = {
    "1 минута на ремонт",
    "минуту на ремонт",
    "минут на ремонт",
    "начните ремонт транспорта",
}

-- поиск фразы начала ремонта прямо в сыром буфере пакета
local function payloadHasRepairStart(bs)
    local okTotal, total = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not okTotal or not total or total <= 0 or total > 4096 then return false end
    pcall(raknetBitStreamResetReadPointer, bs)
    local okR, raw = pcall(raknetBitStreamReadString, bs, total)
    pcall(raknetBitStreamResetReadPointer, bs)
    if not okR or not raw or raw == "" then return false end
    for i = 1, #repairStartPhrases do
        if raw:find(repairStartPhrases[i], 1, true) then return true end
    end
    return false
end

-- v1.2.9: сумму перевода денег ищем прямо в сырых байтах пакета (id=93/101),
-- чтобы не зависеть от точного формата полей и от того, вызывался ли
-- стандартный onServerMessage. Формат: «<Ник> передал Вам деньги 4444 руб».
local function payloadMoneySum(bs)
    local okTotal, total = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not okTotal or not total or total <= 0 or total > 4096 then return nil end
    pcall(raknetBitStreamResetReadPointer, bs)
    local okR, raw = pcall(raknetBitStreamReadString, bs, total)
    pcall(raknetBitStreamResetReadPointer, bs)
    if not okR or not raw or raw == "" then return nil end
    local sum = raw:match("[Пп]ередал[аи]?%s+[Вв]ам деньги%s+(%d+)")
        or raw:match("[Вв]ам деньги%s+(%d+)")
        or raw:match("деньги%s+(%d+)%s*руб")
    if not sum then return nil end
    local n = tonumber(sum)
    if not n then return nil end
    return n
end

-- v1.3.3: строгий цикл фраз без повторов.
-- Список перемешивается своим генератором (LCG) - сторонние math.randomseed()
-- в других частях скрипта больше не сбивают порядок. Пул воспроизводится до
-- конца БЕЗ повторов: каждая фраза списка выдаётся ровно один раз, и только
-- когда все выданы - пул тасуется заново. Первая фраза нового пула не
-- совпадает с последней фразой предыдущего (нет повтора на стыке циклов).
-- st = { pool = {}, idx = 1 } - передаётся по ссылке (state.replyCycle и т.п.)
local cycleRngState = 0
local function cycleRandom(n)
    if n <= 1 then return 1 end
    cycleRngState = (1103515245 * cycleRngState + 12345) % 2147483648
    return (cycleRngState % n) + 1
end

local function shuffleCycle(pool, avoidFirst)
    for i = #pool, 2, -1 do
        local j = cycleRandom(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    if avoidFirst and #pool > 1 and pool[1] == avoidFirst then
        local j = cycleRandom(#pool - 1) + 1
        pool[1], pool[j] = pool[j], pool[1]
    end
end

local function pickCycleLine(list, st)
    local n = #list
    if n == 0 then return "" end
    if cycleRngState == 0 then
        cycleRngState = (math.floor(nowMs()) % 2147483647) + 1
    end
    -- пул пересоздаётся только если изменился состав списка (а не просто
    -- число), иначе текущий цикл продолжается и фразы не повторяются
    local sig = table.concat(list, "\n")
    if #st.pool ~= n or st.sig ~= sig then
        st.pool = {}
        for i = 1, n do st.pool[i] = i end
        shuffleCycle(st.pool, nil)
        st.idx = 1
        st.sig = sig
        st.lastIdx = nil
    end
    if st.idx > #st.pool then
        shuffleCycle(st.pool, st.lastIdx)
        st.idx = 1
    end
    local idx = st.pool[st.idx]
    st.idx = st.idx + 1
    st.lastIdx = idx
    return list[idx]
end

-- сбор непустых фраз из буферов GUI в список (CP1251)
local function collectPhrases(buffers, count)
    local list = {}
    for i = 1, count do
        local t = toCp(buffers[i].v or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if t ~= "" then list[#list + 1] = t end
    end
    return list
end

-- выбор случайной фразы автоответа и отправка её в чат (CP1251)
-- v1.3.2: задержка каждой фразы выбирается случайно в диапазоне
-- «от/до» (секунды) из GUI - поэтому сообщения уходят всегда по-разному.
local function randomPhraseDelayMs()
    local lo = tonumber(optReplyDelayMin.v) or 1
    local hi = tonumber(optReplyDelayMax.v) or lo
    if hi < lo then lo, hi = hi, lo end
    if lo < 0 then lo = 0 end
    if hi > 600 then hi = 600 end
    if hi < lo then hi = lo end
    if hi == lo then return lo * 1000 end
    return (lo + math.random(0, hi - lo)) * 1000
end

local function sendPhraseDelayed(text)
    if not text or text == "" then return end
    local delayMs = randomPhraseDelayMs()
    lua_thread.create(function()
        wait(delayMs)
        if not optCheat.v then return end
        pcall(sampSendChat, text)
    end)
end

local function pickAutoReplyLine(pid)
    if not blockAllowed("reply", pid) then return end
    local list = collectPhrases(optReplyLines, replyCount.v)
    if #list == 0 then return end
    sendPhraseDelayed(pickCycleLine(list, state.replyCycle))
end

-- v1.2.6: поток отправки фразы через 1 сек после закрытия окна миниигры.
-- /cancel - это отмена выбранного /repair, окно миниигры при нём не
-- закрывается, поэтому на неё этот поток никак не реагирует.
local function sendFinishReplyThread(pid)
    wait(randomPhraseDelayMs())
    if not optCheat.v or not optAutoReply.v then return end
    if state.active then return end -- уже началась новая миниигра
    if not blockAllowed("finish", pid) then return end
    local list = collectPhrases(optFinishLines, finishCount.v)
    if #list == 0 then return end
    pcall(sampSendChat, pickCycleLine(list, state.finishCycle))
end

-- v1.2.8: ответ на перевод денег: сервер шлёт «<Ник> передал Вам деньги N руб».
-- v1.2.6:
-- Если сумма до 4000 - свой пул фраз, от 4001 - свой. КД 10 сек на каждую
-- группу суммы: пока КД активен, повторные переводы не спамят чат.
-- v1.3.1: сервер просит открыть капот. Текст ищем в сырых байтах пакета
-- (id=93/101), как и фразу начала ремонта - так не зависим от формата полей.
local hoodTriggerPhrases = { "апот транспорта должен быть открыт" }

local function payloadHasHoodOpen(bs)
    local okTotal, total = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not okTotal or not total or total <= 0 or total > 4096 then return false end
    pcall(raknetBitStreamResetReadPointer, bs)
    local okR, raw = pcall(raknetBitStreamReadString, bs, total)
    pcall(raknetBitStreamResetReadPointer, bs)
    if not okR or not raw or raw == "" then return false end
    for i = 1, #hoodTriggerPhrases do
        if raw:find(hoodTriggerPhrases[i], 1, true) then return true end
    end
    return false
end

-- v1.3.1: ответ на просьбу открыть капот (фразы по циклу, КД 3 сек)
local function sendHoodReply()
    if not optCheat.v or not optAutoReply.v then return end
    if not blockAllowed("hood", currentTargetPid()) then return end
    local list = collectPhrases(optHoodLines, hoodCount.v)
    if #list == 0 then return end
    if nowMs() - state.lastHood < 3000 then return end
    state.lastHood = nowMs()
    sendPhraseDelayed(pickCycleLine(list, state.hoodCycle))
end

local function sendMoneyReply(sum, senderId)
    if not optCheat.v or not optAutoReply.v then return end
    if not blockAllowed((sum <= 4000) and "moneyLow" or "moneyHigh", senderId) then return end
    local list, st, lastField
    if sum <= 4000 then
        list = collectPhrases(optMoneyLowLines, moneyLowCount.v)
        st = state.moneyLowCycle
        lastField = "lastMoneyLow"
    else
        list = collectPhrases(optMoneyHighLines, moneyHighCount.v)
        st = state.moneyHighCycle
        lastField = "lastMoneyHigh"
    end
    if #list == 0 then return end
    if nowMs() - state[lastField] < 10000 then return end
    state[lastField] = nowMs()
    sendPhraseDelayed(pickCycleLine(list, st))
end


-- v1.2.2: автоответ на фразу начала ремонта (анти-дубль 5 сек, фразы по циклу)
function sendAutoReplyIfStarted(bs)
    if not optCheat.v then return false end
    if not payloadHasRepairStart(bs) then return false end
    -- v1.1.7: заявка принята - уведомление «Чиню <ник> (id) - <модель>»
    -- показываем всегда (независимо от включённого автоответа)
    local replyPid = currentTargetPid()
    notifyRepairAccepted()
    if not optAutoReply.v then return true end
    if nowMs() - state.lastAutoReply < 5000 then return true end
    state.lastAutoReply = nowMs()
    pickAutoReplyLine(replyPid)
    return true
end

--перестраховка: если фраза пришла не RPC-пакетом, а через стандартный
-- колбэк onServerMessage (текст в чате) - тоже отвечаем (анти-дубль 5 сек)
function onServerMessage(color, text)
    if not optCheat.v then return nil end
    -- v1.2.8: перевод денег: реальный формат «<Ник> передал Вам деньги 4444 руб»
    if text and text ~= "" then
        local sum = tonumber(text:match("[Пп]ередал[аи]?%s+[Вв]ам деньги%s+(%d+)"))
            or tonumber(text:match("[Вв]ам деньги%s+(%d+)"))
        if sum then
            sendMoneyReply(sum, idFromRawText(text))
            return nil
        end
        -- v1.3.1: сервер просит открыть капот
        if text:find("апот транспорта должен быть открыт", 1, true) then
            sendHoodReply()
            return nil
        end
    end
    if not optAutoReply.v then return nil end
    if not text or text == "" then return nil end
    local hit = false
    for i = 1, #repairStartPhrases do
        if text:find(repairStartPhrases[i], 1, true) then hit = true break end
    end
    if not hit then return nil end
    local replyPid = currentTargetPid()
    notifyRepairAccepted()
    if nowMs() - state.lastAutoReply < 5000 then return nil end
    state.lastAutoReply = nowMs()
    pickAutoReplyLine(replyPid)
    return nil
end

-- перехват всех входящих RPC (выполняется для каждого скрипта отдельно)
function onReceiveRpc(id, bs)
    if not optCheat.v then return end
    -- автоответ: фраза начала ремонта может прийти и чатом (101),
    -- и серверным сообщением (93) - проверяем оба ДО фильтра playerId
    if id == 101 or id == 93 then
        if sendAutoReplyIfStarted(bs) then
            pcall(raknetBitStreamResetReadPointer, bs)
            return
        end
        pcall(raknetBitStreamResetReadPointer, bs)
        -- v1.2.9: перевод денег (в том числе если onServerMessage не сработал)
        local msum = payloadMoneySum(bs)
        if msum then sendMoneyReply(msum, payloadMoneySenderId(bs)) end
        pcall(raknetBitStreamResetReadPointer, bs)
        -- v1.3.1: сервер просит открыть капот
        if payloadHasHoodOpen(bs) then sendHoodReply() end
        pcall(raknetBitStreamResetReadPointer, bs)
    end
    if id ~= 101 then return end

    local playerId, text = readChatRpc(bs)
    if not text then return end

    if not optAutoRepair.v then return end
    if state.active then return end
    if not playerId then return end
    if playerId < 0 or playerId > 1004 then return end

    -- не слать самому себе
    local selfId = -1
    pcall(function() selfId = sampGetPlayerIdByNickName(sampGetPlayerNickname(0)) end)
    if playerId == selfId then return end

    local t = text:lower()

    for i = 1, #repairTriggers do
        if t:find(repairTriggers[i]:lower(), 1, true) then
            -- кулдаун между запросами
            if nowMs() - state.lastRepair >= (optRepairCooldown.v or 4000) then
                state.lastRepair = nowMs()
                -- v1.1.7: запоминаем заявку (машину здесь не определяем -
                -- уведомление покажет только ник и id)
                state.pendingRepair = { pid = playerId, at = nowMs() }
                state.espTarget = { pid = playerId, at = nowMs() }
                pcall(sampSendChat, "/repair " .. playerId)
            end
            break
        end
    end
end

-- ---------- Перехват RX id=215 ----------
function onReceivePacket(id, bs)
    if id ~= 215 then return end
    local txt = readBodyText(bs)

    -- появление окна Interactions с кнопками работы: скрипт сам нажимает
    -- кнопку «Начать работу» (не трогая «Завершить работу»), чтобы миниигра
    -- ремонта стартовала автоматически
    if optCheat.v and optAutoStart.v and txt:find("Interactions", 1, true)
       and txt:find("setInfo", 1, true) then
        local code = findStartButtonCode(txt)
        if code and not state.autoStarting then
            state.autoStarting = true
            lua_thread.create(startMinigameThread, code)
        end
        return
    end

    -- старт миниигры: ... [2,"<название>",N] - иконки нажатий не нужны,
    -- просто начинаем таймер до финиша
    if txt:find("HelloweenBuild[", 1, true) then
        local title = txt:match('HelloweenBuild.%[2,"([^"]-)"')
        state.active = true
        state.autoStarting = false
        state.title = title or ""
        if optCheat.v and optEnabled.v and not state.busy then
            lua_thread.create(finishMinigameThread)
        end
        return
    end
    -- закрытие миниигры (команда HelloweenBuild без аргументов)
    if txt:find("HelloweenBuild", 1, true) then
        -- v1.2.6: миниигра шла и закрылась - через 1 сек отправляем фразу
        if optCheat.v and state.active and optAutoReply.v then
            local finishPid = currentTargetPid()
            lua_thread.create(function() sendFinishReplyThread(finishPid) end)
        end
        state.active = false
        -- v1.2.9: миниигра закончилась - снимаем ESP-метку цели
        state.espTarget = nil
    end
end

-- ---------- Команда /mech ----------
local function toggleMenu()
    showMenu.v = not showMenu.v
end

-- ---------- Основной цикл ----------
-- v1.2.9: ESP-метка цели ремонта. Функция объявляется заранее (локально),
-- а сам рендер вызывается каждый кадр в главном цикле ниже.
local drawRepairEsp

function main()
    -- v1.2.3: сразу гасим курсор, чтобы он не появлялся при загрузке/
    -- перезагрузке/переподключении (модуль imgui стартует с ShowCursor=true)
    imgui.ShowCursor = false
    imgui.Process = false
    imgui.DisableInput = false

    repeat wait(0) until isSampAvailable()
    wait(500)

    -- v1.2.3: после подключения состояние imgui ведёт уже основной цикл
    imgui.Process = true

    -- приветствие одной строкой через ywelcome (экранная надпись убрана)
    ywelcome("MechWorkByYaroRage", "Загружен. Меню: /mech")

    -- команда регистрируется только когда SA:MP уже доступен
    if sampRegisterChatCommand then
        sampRegisterChatCommand("mech", toggleMenu)
    end

    -- управление курсором/вводом imgui свойствами, как в CheatByYaroRage.
    -- В режиме «Выбор цели курсором» (optCursorPick) курсор появляется
    -- и прячется по удержанию выбранной кнопки (optCursorButton) на время
    -- optCursorDelaySec (без отпускания). Короткий клик (меньше этого времени)
    -- при отрисованном курсоре наводит его на машину и шлёт /repair <id>.
    local mbDown = false       -- кнопка сейчас зажата
    local mbDownAt = 0         -- время начала удержания (GetTickCount, мс)
    local mbProcessed = false  -- удержание уже обработано (показали/скрыли)
    -- ---------- v1.1.4: фронт правой кнопки для ручного запроса /repair ----------
    local rmbPrev = false      -- ПКМ была нажата на прошлом кадре
    -- ---------- v1.2.0: фронт комбинации Space + ПКМ для /cancel ----------
    local cancelPrev = false   -- комбинация Space+ПКМ была активна на прошлом кадре
    while true do
        -- Меню: imgui берёт ввод (DisableInput=false), курсор виден.
        -- Курсор без меню: ввод отдаётся игре (DisableInput=true), камера вращается.
        -- Ничего: курсор скрыт, ввод идёт игре.
        if showMenu.v then
            imgui.ShowCursor = true
            imgui.Process = true
            imgui.DisableInput = false
        elseif optCursorPick.v and state.cursorVisible then
            imgui.ShowCursor = true
            imgui.Process = true
            imgui.DisableInput = true    -- камера вращается при видимом курсоре
        else
            imgui.ShowCursor = false
            imgui.Process = true
            imgui.DisableInput = false
        end

        -- v1.1.9: персонаж в «Эвакуаторе» - автоисключение из автоматического
        -- ремонта (фильтр + запись собственного id в список исключений)
        autoExcludeSelfInTowtruck()

        -- ---- отслеживание выбранной кнопки показа курсора ----
        local now = nowMs()
        local down = isVkDown(currentCursorVk())
        if down then
            if not mbDown then
                -- начало удержания
                mbDown = true
                mbDownAt = now
                mbProcessed = false
            elseif not mbProcessed and optCheat.v and optCursorPick.v
                   and now - mbDownAt >= optCursorDelaySec.v * 1000 then
                -- удержание заданное время без отпускания: показать/скрыть курсор
                mbProcessed = true
                state.cursorVisible = not state.cursorVisible
            end
        else
            if mbDown then
                -- кнопка отпущена: если это был короткий клик (меньше задержки)
                -- при показанном курсоре - выбираем машину под курсором
                local held = now - mbDownAt
                mbDown = false
                mbProcessed = false
                -- v1.2.1: не выбираем цель, если только что ушёл /cancel (Space+ПКМ)
                if optCheat.v and optCursorPick.v and state.cursorVisible
                   and held < optCursorDelaySec.v * 1000
                   and not showMenu.v and not cancelPrev then
                    sendRepairByCursor()
                end
            end
        end

-- ---------- v1.1.4: ручной запрос /repair ближайшему (по ПКМ) ----------
        -- клик правой кнопкой (фронт нажатия) шлёт /repair ближайшему
        -- свободному водителю в радиусе. Пропускается при открытом меню,
        -- во время миниигры, при показанном курсоре выбора цели, при вводе
        -- в чат/самп-диалог и когда кнопкой ПКМ занят режим выбора цели.
        do
            local rmbDown = isVkDown(0x02)
            local rmbOk = optCheat.v and optManualRmb.v and not showMenu.v
                      and not state.active
                      and not state.cursorVisible and not (optCursorPick.v and currentCursorVk() == 0x02)
                      and not isVkDown(0x20) -- v1.2.0: зажат Space - ПКМ резервируется под /cancel
            if rmbDown and not rmbPrev and rmbOk then
                local okChat = pcall(sampIsChatInputActive)
                local okDlg = pcall(sampIsDialogActive)
                if (not okChat or not sampIsChatInputActive()) and (not okDlg or not sampIsDialogActive()) then
                    sendNearRepairManual()
                end
            end
            rmbPrev = rmbDown
        end

        -- ---------- v1.2.0: Space + ПКМ - команда /cancel в чат ----------
        -- зажать пробел и кликнуть правой кнопкой: в чат уходит /cancel
        -- (ручная отмена миниигры/ремонта). Фронт комбинации срабатывает
        -- один раз, повторные клики ПКМ при удержанном Space шлют снова.
        -- Пропускается при открытом меню и вводе в чат/самп-диалог.
        -- При показанном курсоре выбора цели команда тоже отправляется,
        -- а клик ПКМ при зажатом Space не выбирает машину под курсором.
        do
            local spDown = isVkDown(0x20)
            local rbDown = isVkDown(0x02)
            -- v1.2.1: работает и при показанном курсоре выбора цели
            local cancelOk = spDown and rbDown and not showMenu.v
            if cancelOk and not cancelPrev then
                local okChat = pcall(sampIsChatInputActive)
                local okDlg = pcall(sampIsDialogActive)
                if (not okChat or not sampIsChatInputActive()) and (not okDlg or not sampIsDialogActive()) then
                    pcall(sampSendChat, "/cancel")
                end
            end
            cancelPrev = cancelOk
        end

        -- ---------- v1.1.1: авто-ремонт подъехавших в радиус ----------
        -- авто-режим отключается, если включён ручной режим по ПКМ (v1.1.4)
        if optCheat.v and optNearRepair.v and not optManualRmb.v
           and optEnabled.v and not state.active and not showMenu.v then
            local nowB = nowMs()
            if state.nearWaiting then
                -- миниигра началась? фиксируем для детекта её окончания
                if state.active then state.nearSawActive = true end
                -- миниигра завершилась (была активна и пропала)
                if state.nearSawActive and not state.active then
                    state.nearWaiting = false
                    state.nearSawActive = false
                    state.nearLockUntil = nowB + optNearDelaySec.v * 1000
                end
                -- защита от «вечного ожидания»: заявка не принята и
                -- миниигра не началась за 60 сек — снимаем блокировку
                if not state.nearSawActive and not state.active
                    and state.nearSentAt and nowB - state.nearSentAt >= 60000 then
                    state.nearWaiting = false
                    state.nearSawActive = false
                end
            end
            -- если не ждём завершения и кулдаун прошёл — ищем следующую машину
            if not state.nearWaiting and nowB >= state.nearLockUntil then
                local vehId, pid = findNearRepairTarget(optNearRadiusM.v)
                if pid then
                    state.nearWaiting = true
                    state.nearSawActive = false
                    state.lastRepair = nowB
                    state.nearSentAt = nowB
                    -- v1.1.7: запоминаем заявку для уведомления «Чиню ...»
                    state.pendingRepair = { pid = pid, veh = vehId, at = nowB }
                    state.espTarget = { pid = pid, veh = vehId, at = nowB }
                    pcall(sampSendChat, "/repair " .. pid)
                end
            end
        end

        -- v1.2.9: ESP-метка цели ремонта (рисуем поверх игры каждый кадр)
        if drawRepairEsp then pcall(drawRepairEsp) end

        wait(0)
    end
end

-- ---------- v1.2.9: ESP-метка цели ремонта (линия/квадрат/плашка) ----------
-- Рисует маркер поверх экрана по state.espTarget: машина, которую скрипт
-- в данный момент чинит (отправка /repair, миниигра). Ведёт до закрытия
-- миниигры или таймаута 5 минут.
-- ВАЖНО: MoonImGui не имеет списков фоновой/передней отрисовки
-- (GetBackgroundDrawList/GetForegroundDrawList отсутствуют), поэтому рисуем
-- средствами SAMPFUNCS render* - так же, как это делает LesByYaroRage.
local espFont = nil

local function ensureEspFont(scale)
    if espFont then return true end
    if type(renderCreateFont) ~= "function" then return false end
    local size = math.floor(9 * (scale or 1) + 0.5)
    if size < 6 then size = 6 end
    if size > 22 then size = 22 end
    local ok, f = pcall(renderCreateFont, "Arial", size, 13)
    if ok and f then espFont = f return true end
    return false
end

drawRepairEsp = function()
    if not optCheat.v or not (optEspLine.v or optEspBox.v or optEspPanel.v) then return end
    local et = state.espTarget
    if not et or not et.pid then return end
    -- таймаут цели: заявка старше 5 минут и не принята - забываем
    if nowMs() - et.at > 300000 then state.espTarget = nil return end
    -- v1.3.1: машину цели определяем динамически - водитель мог пересесть,
    -- а сохранённый et.veh мог быть переиспользован игрой под другой транспорт
    local veh = et.veh
    if type(sampGetPlayerCarHandle) == "function" then
        local okPv, pv = pcall(sampGetPlayerCarHandle, et.pid)
        if okPv and pv and pv ~= 0 then
            local okE2, ex2 = pcall(doesVehicleExist, pv)
            if okE2 and ex2 then veh = pv end
        end
    end
    -- если машина исчезла (уехала/разрушена) - снимаем метку
    if veh then
        local okE, exists = pcall(doesVehicleExist, veh)
        if not okE or not exists then state.espTarget = nil return end
    end
    local sc = fsc or 1
    local okR, resX, resY = pcall(getScreenResolution)
    if not okR or not resX or not resY then resX, resY = 1920, 1080 end
    local okV, vx, vy, vz
    if veh then okV, vx, vy, vz = pcall(getVehiclePos, veh) end
    local okScr = false
    local sx, sy = 0, 0
    if veh and okV and vx and vy and vz then
        -- v1.3.3: convert3DCoordsToScreen отдаёт ЗЕРКАЛЬНЫЕ координаты, если
        -- машина за спиной. Поэтому метку рисуем только когда цель перед
        -- активной камерой (скалярное произведение направления камеры > 0).
        local inFront = true
        if type(getActiveCameraCoordinates) == "function" and type(getActiveCameraPointAt) == "function" then
            local okC, camX, camY, camZ = pcall(getActiveCameraCoordinates)
            local okP, lookX, lookY, lookZ = pcall(getActiveCameraPointAt)
            if okC and okP and camX and lookX then
                local dirX, dirY, dirZ = lookX - camX, lookY - camY, lookZ - camZ
                inFront = (vx - camX) * dirX + (vy - camY) * dirY + (vz - camZ) * dirZ > 0
            end
        end
        if inFront then
            -- +0.9 м: метка ложится на корпус машины, а не на уровень земли
            local okS, X, Y = pcall(convert3DCoordsToScreen, vx, vy, vz + 0.9)
            if okS and X and Y and X == X and Y == Y and X > -100 and X < 9000 and Y > -100 and Y < 8000 then
                sx, sy, okScr = X, Y, true
            end
        end
    end
    -- линия от низа экрана к машине
    if optEspLine.v and okScr and type(renderDrawLine) == "function" then
        pcall(renderDrawLine, resX / 2, resY, sx, sy, 2.0 * sc, 0xFF3FF0FF)
    end
    -- квадрат на капоте
    if optEspBox.v and okScr and type(renderDrawBoxWithBorder) == "function" then
        local hs = 26 * sc
        pcall(renderDrawBoxWithBorder, sx - hs, sy - hs, hs * 2, hs * 2, nil, 2, 0xFF3FF0FF)
    end
    -- плашка внизу экрана с данными водителя
    if optEspPanel.v then
        local nick = nil
        if type(sampGetPlayerNickname) == "function" then
            local okN, n = pcall(sampGetPlayerNickname, et.pid)
            if okN and n and n ~= "" then nick = n end
        end
        local model = ""
        if veh then model = vehicleDisplayName(veh) end
        local line = "id " .. et.pid .. (nick and (" | " .. nick) or "") .. (model ~= "" and (" | " .. model) or "")
        local pw = math.min(resX - 20, 420 * sc)
        local ph = 26 * sc
        local px = resX / 2 - pw / 2
        local py = resY - ph - 12 * sc
        if type(renderDrawBox) == "function" then
            pcall(renderDrawBox, px, py, pw, ph, 0xC00D0D1F)
        end
        if type(renderDrawBoxWithBorder) == "function" then
            pcall(renderDrawBoxWithBorder, px, py, pw, ph, nil, 1, 0xFF3FF0FF)
        end
        if ensureEspFont(sc) and type(renderFontDrawText) == "function" then
            local tx, ty = px + 8 * sc, py + ph / 2 - 6 * sc
            if type(renderGetFontDrawTextLength) == "function" and type(renderGetFontDrawHeight) == "function" then
                local okL, tl = pcall(renderGetFontDrawTextLength, espFont, line)
                local okH, th = pcall(renderGetFontDrawHeight, espFont)
                if okL and okH and type(tl) == "number" and type(th) == "number" then
                    tx = px + (pw - tl) / 2
                    ty = py + (ph - th) / 2
                end
            end
            pcall(renderFontDrawText, espFont, line, tx, ty, 0xFFFFFFFF)
        end
    end
end

-- ---------- GUI ----------
function imgui.OnDrawFrame()
    local resX, resY = getScreenResolution()
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
    imgui.GetIO().FontGlobalScale = fsc

    -- окно всегда видно и влезает в экран
    local winW = math.max(440, math.min(580 * fsc, resX - 20))
    local winH = math.max(440, math.min(740 * fsc, resY - 40))

    if showMenu.v then
        local changed = false
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - winW / 2, resY / 2 - winH / 2), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
        imgui.Begin(u8"MechWorkByYaroRage", showMenu, imgui.WindowFlags.NoCollapse)

        -- ===== ШАПКА: МАСТЕР-ПЕРЕКЛЮЧАТЕЛЬ ВСЕГО ЧИТА =====
        -- v1.3.7: кнопка вынесена из-под заголовка окна в отдельную строку —
        -- раньше на части разрешений/DPI она уходила под шапку и была не видна.
        do
            local cheatBw = winW - 24 * fsc
            local cheatBh = 30 * fsc
            if optCheat.v then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.80, 0.18, 0.18, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.0, 0.25, 0.25, 1.0))
            else
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.65, 0.20, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.20, 0.85, 0.25, 1.0))
            end
            if imgui.Button(optCheat.v and u8"ВЫКЛЮЧИТЬ ЧИТ" or u8"ВКЛЮЧИТЬ ЧИТ", imgui.ImVec2(cheatBw, cheatBh)) then
                setCheatMaster(not optCheat.v)
            end
            imgui.PopStyleColor(2)
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Один клик включает или выключает всю работу чита. Пока чит выключен, скрипт ничего не делает")
            end
        end
        imgui.TextColored(optCheat.v and imgui.ImVec4(0.35, 0.85, 0.40, 1) or imgui.ImVec4(1.0, 0.55, 0.30, 1),
            optCheat.v and u8"Чит включён" or u8"Чит выключен (по умолчанию)")
        imgui.Separator()

        -- ===== ПАНЕЛЬ ВКЛАДОК =====
        local tabNames = { u8"Миниигра", u8"Ремонт", u8"Курсор", u8"Подбор", u8"Фразы", u8"Статус" }
        local tabCount = #tabNames
        local tabW = (winW - 4 * (tabCount - 1)) / tabCount
        for i = 1, tabCount do
            if i > 1 then imgui.SameLine(0, 4) end
            -- активная вкладка — другой цвет кнопки
            if activeTab == i then
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.26, 0.50, 0.80, 1))
            else
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.18, 0.18, 0.24, 1))
            end
            if imgui.Button(tabNames[i], imgui.ImVec2(tabW, 28 * fsc)) then
                activeTab = i
            end
            imgui.PopStyleColor(1)
        end

        imgui.Separator()
        imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 3)

        -- ===== СОДЕРЖИМОЕ ВКЛАДОК =====
        -- контент занимает всё оставшееся окно, кроме нижней полосы кнопок:
        -- отрицательный размер = оставшаяся высота окна минус 46*fsc (кнопки)
        imgui.BeginChild(u8"##tabs", imgui.ImVec2(0, -46 * fsc), false, imgui.WindowFlags.NoSavedSettings)

        if activeTab == 1 then
            -- ====== ВКЛАДКА «МИНИИГРА» ======
            imgui.TextWrapped(u8"Автозавершение миниигры починки транспорта")
            imgui.Separator()

            if imgui.Checkbox(u8"Авто-закрытие", optEnabled) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Миниигра «Ремонт» будет автоматически завершена через случайную задержку")
            end

            imgui.Separator()
            imgui.Text(u8"Авто-старт ремонта:")
            if imgui.Checkbox(u8"   кликать «Начать работу»", optAutoStart) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"При появлении окна Interactions у капота машины скрипт сам нажмёт кнопку, и миниигра начнётся")
            end
            imgui.PushItemWidth(120 * fsc)
            if imgui.SliderInt(u8"   задержка до клика, мс", optStartDelayMs, 0, 3000) then changed = true end
            imgui.PopItemWidth()

            imgui.Separator()
            imgui.Text(u8"Случайная задержка перед закрытием:")
            imgui.PushItemWidth(120 * fsc)
            if imgui.SliderInt(u8"   от, сек", optDelayMinSec, 0, 20) then changed = true end
            if imgui.SliderInt(u8"   до, сек", optDelayMaxSec, 0, 20) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"При КАЖДОЙ новой миниигре время до успешного финиша выбирается случайно в этом диапазоне")
            end
            imgui.PopItemWidth()

            imgui.Separator()
            imgui.TextWrapped(u8"Примечание: Space + ПКМ = /cancel (прервать текущую миниигру)")

        elseif activeTab == 2 then
            -- ====== ВКЛАДКА «РЕМОНТ» ======
            imgui.TextWrapped(u8"Автоматический ремонт по запросам в чат и триггерам")
            imgui.Separator()

            imgui.Text(u8"Авторемонт по чату:")
            if imgui.Checkbox(u8"   включить (почини / чини / ремонт)", optAutoRepair) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Если игрок написал в чат «почини/чини/ремонт», скрипт сам отправит /repair <id> этому игроку")
            end
            imgui.PushItemWidth(120 * fsc)
            if imgui.SliderInt(u8"   пауза между запросами, мс", optRepairCooldown, 500, 20000) then changed = true end
            imgui.PopItemWidth()

            imgui.Separator()
            -- триггеры (свой ID-контекст, иначе кнопки конфликтуют с блоком исключений)
            imgui.PushID(9001)
            imgui.Text(u8"Триггеры авто-ремонта:")
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Если кто-то напишет в чат фразу из списка (целиком или её часть), скрипт отправит этому игроку /repair по его id")
            end
            imgui.PushItemWidth(260 * fsc)
            imgui.InputText(u8"   новая фраза##trig", triggerInput)
            imgui.PopItemWidth()
            imgui.SameLine(0, 6)
            if imgui.Button(u8"Добавить", imgui.ImVec2(90 * fsc, 0)) then
                addTriggerHint.v = not addTrigger(triggerInput.v)
                if not addTriggerHint.v then triggerInput.v = "" end
            end
            if addTriggerHint.v then
                imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"   пустая или уже есть такая фраза")
            end
            -- список триггеров с кнопкой «Очистить всё»
            if #repairTriggers > 0 then
                imgui.SameLine(0, 20)
                if imgui.SmallButton(u8"очистить всё") then
                    for _ = 1, #repairTriggers do table.remove(repairTriggers, 1) end
                    saveSettings()
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Удалить все триггеры из списка")
                end
            end
            imgui.BeginChild(u8"##trigList", imgui.ImVec2(0, 130 * fsc), true)
            for i = 1, #repairTriggers do
                imgui.PushID(i)
                imgui.Text("  " .. u8(repairTriggers[i]))
                imgui.SameLine(0, 20)
                if imgui.SmallButton(u8"х") then
                    removeTrigger(i)
                end
                imgui.PopID()
            end
            imgui.EndChild()
            imgui.PopID()

            imgui.Separator()
            -- исключённые id
            imgui.PushID(9002)
            imgui.Text(u8"Исключить id водителей (им не шлём /repair):")
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Игроки из списка не получают /repair ни в авто-режиме, ни по ПКМ, ни колесиком. Запрос уйдёт следующему по близости")
            end
            imgui.PushItemWidth(120 * fsc)
            imgui.InputText(u8"   новый id##excId", excludeIdInput)
            imgui.PopItemWidth()
            imgui.SameLine(0, 6)
            if imgui.Button(u8"Добавить", imgui.ImVec2(90 * fsc, 0)) then
                local hint = addExcludedId(excludeIdInput.v)
                excludeIdHint = hint or ""
                if not hint then excludeIdInput.v = "" end
            end
            if excludeIdHint ~= "" then
                imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"   " .. u8(excludeIdHint))
            end
            -- список исключённых с кнопкой «Очистить всё»
            if #excludedIds > 0 then
                imgui.SameLine(0, 20)
                if imgui.SmallButton(u8"очистить всё##exc") then
                    for _ = 1, #excludedIds do table.remove(excludedIds, 1) end
                    saveSettings()
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Удалить все исключённые id")
                end
            end
            imgui.BeginChild(u8"##excIdList", imgui.ImVec2(0, 100 * fsc), true)
            for i = 1, #excludedIds do
                imgui.PushID(200 + i)
                imgui.Text("  id " .. excludedIds[i])
                imgui.SameLine(0, 20)
                if imgui.SmallButton(u8"х") then
                    removeExcludedId(i)
                end
                imgui.PopID()
            end
            imgui.EndChild()
            imgui.PopID()

        elseif activeTab == 3 then
            -- ====== ВКЛАДКА «КУРСОР» ======
            imgui.TextWrapped(u8"Ручной выбор цели ремонта курсором: удерживайте кнопку — появится курсор, короткий клик по машине — /repair её водителю.")
            imgui.Separator()

            imgui.Text(u8"Выбор цели курсором:")
            if imgui.Checkbox(u8"   включить", optCursorPick) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Удерживайте выбранную кнопку — появится курсор. Короткий клик по машине = /repair её водителю. Space+ПКМ = /cancel")
            end
            imgui.PushItemWidth(220 * fsc)
            if imgui.Combo(u8"   кнопка##cursorBtn", optCursorButton, cursorButtonNames, nil, #cursorButtonList) then changed = true end
            if imgui.SliderFloat(u8"   задержка показа, сек##cursorDelay", optCursorDelaySec, 0.1, 2.0, "%.1f") then changed = true end
            imgui.PopItemWidth()

            imgui.Separator()
            imgui.TextWrapped(u8"Фразы автоответа и ответы на переводы денег настраиваются во вкладке «Фразы».")

        elseif activeTab == 4 then
            -- ====== ВКЛАДКА «ПОДБОР» ======
            imgui.TextWrapped(u8"Как скрипт выбирает машину для /repair: автоматически в радиусе или вручную по правой кнопке.")
            imgui.Separator()

            imgui.Text(u8"Авто-подбор в радиусе:")
            if imgui.Checkbox(u8"   включить (автоматически)", optNearRepair) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Скрипт сам отправляет /repair каждой новой машине, подъехавшей в радиус")
            end
            imgui.PushItemWidth(150 * fsc)
            if imgui.SliderInt(u8"   радиус, м", optNearRadiusM, 2, 20) then changed = true end
            if imgui.SliderInt(u8"   пауза, сек", optNearDelaySec, 5, 300) then changed = true end
            imgui.PopItemWidth()

            imgui.Spacing()
            imgui.Text(u8"Ручной выбор:")
            if imgui.Checkbox(u8"   по правой кнопке (ПКМ)", optManualRmb) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Авто-кидание отключается: /repair отправится ближайшему свободному водителю только по клику ПКМ")
            end

            imgui.Separator()
            if imgui.CollapsingHeader(u8"ESP-метка цели ремонта##espHead") then
                imgui.TextWrapped(u8"Подсветка машины, которую чиним сейчас (текущая цель /repair).")
                imgui.Spacing()
                if imgui.Checkbox(u8"линия от низа экрана", optEspLine) then changed = true end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Показывать линию от низа экрана к целевой машине")
                end
                if imgui.Checkbox(u8"квадрат на капоте", optEspBox) then changed = true end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Показывать квадрат на капоте целевой машины")
                end
                if imgui.Checkbox(u8"плашка с данными", optEspPanel) then changed = true end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Плашка внизу экрана: id водителя, ник и модель машины")
                end
            end

            imgui.Separator()
            imgui.TextWrapped(u8"Подъехавшая в радиус машина-игрок один раз получит /repair. Приоритет — мотоциклам. Водители с исключённым id пропускаются.")

        elseif activeTab == 5 then
            -- ====== ВКЛАДКА «ФРАЗЫ» ======
            imgui.TextWrapped(u8"Все фразы, которые скрипт пишет в чат: автоответ на старт ремонта, финиш миниигры, ответы на переводы денег и на просьбу открыть капот.")
            imgui.Separator()

            if imgui.Checkbox(u8"Отправлять фразы в чат (общий выключатель)", optAutoReply) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Главный выключатель: пока галочка снята, ни один блок фраз не отправляется. Отдельные блоки включаются ниже")
            end
            imgui.Spacing()
            imgui.Text(u8"Задержка перед каждым сообщением, сек (от и до):")
            imgui.PushItemWidth(150 * fsc)
            if imgui.SliderInt(u8"   от##repDelayMin", optReplyDelayMin, 0, 60) then changed = true end
            if imgui.SliderInt(u8"   до##repDelayMax", optReplyDelayMax, 0, 60) then changed = true end
            imgui.PopItemWidth()
            imgui.TextWrapped(u8"Перед отправкой каждой фразы задержка выбирается случайно в этом диапазоне — сообщения уходят по-разному.")
            imgui.Separator()

            for bi = 1, #phraseBlocks.keys do
                local key = phraseBlocks.keys[bi]
                imgui.PushID(7300 + bi)
                if imgui.CollapsingHeader(u8(phraseBlocks.title[key] .. (phraseBlocks.on[key].v and "" or "   [ОТКЛЮЧЕНО]") .. "##blk")) then
                    if imgui.Checkbox(u8"   блок включён", phraseBlocks.on[key]) then changed = true end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip(u8"Снимите галочку — фразы этого блока не отправляются")
                    end
                    imgui.Spacing()

                    imgui.Text(u8"Исключить id (этим игрокам фразы блока не шлются):")
                    imgui.PushItemWidth(90 * fsc)
                    imgui.InputText(u8"   новый id##blockExcId", phraseBlocks.input[key])
                    imgui.PopItemWidth()
                    imgui.SameLine(0, 6)
                    if imgui.Button(u8"Добавить", imgui.ImVec2(90 * fsc, 0)) then
                        local hint = phraseBlocks.addExcludedId(key, phraseBlocks.input[key].v)
                        phraseBlocks.hint[key] = hint or ""
                        if not hint then phraseBlocks.input[key].v = "" end
                    end
                    if phraseBlocks.hint[key] ~= "" then
                        imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"   " .. u8(phraseBlocks.hint[key]))
                    end
                    if #phraseBlocks.excl[key] > 0 then
                        if imgui.SmallButton(u8"очистить всё##blockExcClear") then
                            for _ = 1, #phraseBlocks.excl[key] do table.remove(phraseBlocks.excl[key], 1) end
                            saveSettings()
                        end
                        imgui.BeginChild(u8"##blockExcList", imgui.ImVec2(0, 54 * fsc), true)
                        for i = 1, #phraseBlocks.excl[key] do
                            imgui.PushID(20 + i)
                            imgui.Text("  id " .. phraseBlocks.excl[key][i])
                            imgui.SameLine(0, 20)
                            if imgui.SmallButton(u8"х") then
                                table.remove(phraseBlocks.excl[key], i)
                                saveSettings()
                            end
                            imgui.PopID()
                        end
                        imgui.EndChild()
                    end
                    imgui.Spacing()

                    if key == "reply" then
                        imgui.TextWrapped(u8"Вставить сразу несколько фраз: каждая непустая строка ниже станет отдельной фразой (до 30).")
                        imgui.PushItemWidth(280 * fsc)
                        imgui.InputTextMultiline(u8"   новые фразы##replyBlock", replyBlockInput, imgui.ImVec2(0, 60 * fsc), 0)
                        imgui.PopItemWidth()
                        imgui.SameLine(0, 6)
                        if imgui.Button(u8"Вставить блок", imgui.ImVec2(150 * fsc, 0)) then
                            if addReplyBlock() then changed = true end
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip(u8"Каждая непустая строка поля добавится в список фраз до максимума 30. После вставки поле очищается")
                        end
                        if drawPhraseList(optReplyLines, replyCount, 30, 100, "фраза", "Добавить фразу") then changed = true end
                    elseif key == "finish" then
                        imgui.Text(u8"Фразы по окончанию миниигры:")
                        if drawPhraseList(optFinishLines, finishCount, 5, 300, "финиш", "Добавить фразу") then changed = true end
                    elseif key == "moneyLow" then
                        imgui.Text(u8"Фразы при переводе денег до 4000 руб:")
                        if drawPhraseList(optMoneyLowLines, moneyLowCount, 5, 400, "до 4000", "Добавить фразу") then changed = true end
                    elseif key == "moneyHigh" then
                        imgui.Text(u8"Фразы при переводе денег от 4001 руб:")
                        if drawPhraseList(optMoneyHighLines, moneyHighCount, 5, 500, "от 4001", "Добавить фразу") then changed = true end
                    elseif key == "hood" then
                        imgui.Text(u8"Фразы на «Капот транспорта должен быть открыт»:")
                        if drawPhraseList(optHoodLines, hoodCount, 5, 600, "капот", "Добавить фразу") then changed = true end
                    end
                end
                imgui.PopID()
            end
        elseif activeTab == 6 then
            -- ====== ВКЛАДКА «СТАТУС» ======
            imgui.TextWrapped(u8"Текущее состояние скрипта")
            imgui.Separator()

            local status = u8"Миниигра не активна"
            if state.active then
                status = u8"Миниигра активна: " .. (state.title ~= "" and u8(state.title) or u8"без названия")
            end
            imgui.TextWrapped(status)

            imgui.Separator()
            imgui.Text(u8"Авто-закрытие: " .. (optEnabled.v and u8"вкл" or u8"выкл"))
            imgui.SameLine(0, 20)
            imgui.Text(u8"Авто-старт: " .. (optAutoStart.v and u8"вкл" or u8"выкл"))
            imgui.SameLine(0, 20)
            imgui.Text(u8"Авторемонт: " .. (optAutoRepair.v and u8"вкл" or u8"выкл"))

            imgui.Text(u8"Задержка: " .. optDelayMinSec.v .. u8"–" .. optDelayMaxSec.v .. u8" сек")
            imgui.SameLine(0, 20)
            imgui.Text(u8"Пауза ремонта: " .. optRepairCooldown.v .. u8" мс")

            imgui.Text(u8"Цель курсором: " .. (optCursorPick.v and u8"вкл" or u8"выкл"))
            imgui.SameLine(0, 20)
            imgui.Text(u8"Авто-подбор: " .. (optNearRepair.v and u8"вкл" or u8"выкл"))

            if inTowtruck then
                imgui.Separator()
                imgui.TextColored(imgui.ImVec4(1, 0.8, 0.2, 1), u8"Вы в «Эвакуаторе»: ваш id в списке исключений — /repair вам не отправляется")
            end

            imgui.Separator()
            local enabledBlocks = 0
            for bi = 1, #phraseBlocks.keys do
                if phraseBlocks.on[phraseBlocks.keys[bi]].v then enabledBlocks = enabledBlocks + 1 end
            end
            local totalPhrases = replyCount.v + finishCount.v + moneyLowCount.v + moneyHighCount.v + hoodCount.v
            imgui.TextWrapped(u8"Фразы: " .. totalPhrases .. u8" шт., блоков включено " .. enabledBlocks .. u8" из " .. #phraseBlocks.keys .. u8"  |  Триггеры: " .. #repairTriggers .. u8" шт.  |  Исключено id: " .. #excludedIds .. u8" шт.")
            if not optAutoReply.v then
                imgui.TextColored(imgui.ImVec4(1, 0.5, 0.3, 1), u8"Фразы выключены общим выключателем (вкладка «Фразы»)")
            end
        end

        imgui.EndChild() -- ##tabs

        -- ===== НИЖНЯЯ ПОЛОСА: СОХРАНИТЬ / ЗАКРЫТЬ =====
        imgui.PopStyleVar(1) -- FrameRounding
        imgui.Separator()
        local btnW = (winW - 20) / 2
        if imgui.Button(u8"Сохранить", imgui.ImVec2(btnW, 34 * fsc)) then
            saveSettings()
            changed = false
        end
        imgui.SameLine()
        if imgui.Button(u8"Закрыть", imgui.ImVec2(btnW, 34 * fsc)) then
            showMenu.v = false
        end

        if changed then
            saveSettings()
            changed = false
        end

        imgui.End()
    end

end