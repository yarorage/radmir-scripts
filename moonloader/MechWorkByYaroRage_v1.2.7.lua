-- MechWorkByYaroRage v1.2.7
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
script_version("1.2.7")

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
    local s = { enabled = true, cheatEnabled = true, delayMs = 3000, autoStart = true, startDelayMs = 300,
                autoRepair = true, repairCooldown = 4000,
                autoReply = true,
                replyLines = {}, -- список фраз автоответа (до 30, v1.1.5)
                finishLines = {}, -- v1.2.6: фразы по окончанию миниигры (до 5)
                moneyLowLines = {}, -- v1.2.6: фразы при переводе до 4000 (до 5)
                moneyHighLines = {}, -- v1.2.6: фразы при переводе от 4001 (до 5)
                cursorPick = false,
                cursorButton = 0x04,
                cursorDelayMs = 1000,
        nearRepair = false,
        nearRadiusM = 5,
        nearDelaySec = 30,
        manualRmb = false, -- ручной запрос /repair по ПКМ (v1.1.4)
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
    if s.delayMaxMs > 10000 then s.delayMaxMs = 10000 end
    if s.delayMinMs > s.delayMaxMs then s.delayMinMs = s.delayMaxMs end
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
-- задержка после старта миниигры до отправки финиша, мс
local optDelayMs = imgui.ImInt(settings.delayMs)
-- v1.1.8: диапазон случайной задержки перед закрытием миниигры, мс
local optDelayMinMs = imgui.ImInt(settings.delayMinMs)
local optDelayMaxMs = imgui.ImInt(settings.delayMaxMs)
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
    cursorVisible = false, -- курсор выбора цели показан (по удержанию колесика)
    -- ---------- v1.1.1: авто-ремонт подъехавших в радиус ----------
    nearQueue = {},      -- таблица прошлых /repair: veh -> nowMs
    nearWaiting = false, -- ждём завершения текущей миниигры (после отправки /repair)
    nearSawActive = false, -- миниигра уже началась (для детекта конца)
    nearLockUntil = 0,   -- не отправлять раньше этого времени (GetTickCount)
    nearSentAt = 0,      -- время последней отправки /repair в ближнем режиме (GetTickCount)
    pendingRepair = nil, -- v1.1.7: последняя отправленная заявка /repair (для уведомления)
}

function saveSettings()
    local lines = {
        "enabled = " .. (optEnabled.v and "true" or "false"),
        "cheatEnabled = " .. (optCheat.v and "true" or "false"),
        "delayMs = " .. optDelayMs.v,
        "delayMinMs = " .. optDelayMinMs.v,
        "delayMaxMs = " .. optDelayMaxMs.v,
        "autoStart = " .. (optAutoStart.v and "true" or "false"),
        "startDelayMs = " .. optStartDelayMs.v,
        "autoRepair = " .. (optAutoRepair.v and "true" or "false"),
        "repairCooldown = " .. optRepairCooldown.v,
        "autoReply = " .. (optAutoReply.v and "true" or "false"),
        "cursorPick = " .. (optCursorPick.v and "true" or "false"),
        "cursorButton = " .. currentCursorVk(),
        "cursorDelayMs = " .. math.floor((optCursorDelaySec.v or 1.0) * 1000 + 0.5),
        "nearRepair = " .. (optNearRepair.v and "true" or "false"),
        "nearRadiusM = " .. optNearRadiusM.v,
        "nearDelaySec = " .. optNearDelaySec.v,
        "manualRmb = " .. (optManualRmb.v and "true" or "false"),
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
    local delayMin, delayMax = optDelayMinMs.v or 0, optDelayMaxMs.v or 0
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

-- v1.2.2/1.2.6: циклический пул: фразы списка перемешиваются (Фишер-Йетса),
-- затем воспроизводятся в этом случайном порядке без повторов; когда пул
-- исчерпан - тасуются заново. При изменении количества фраз пул пересоздаётся.
-- st = { pool = {}, idx = 1 } - передаётся по ссылке (state.replyCycle и т.п.)
local function pickCycleLine(list, st)
    if #list == 0 then return "" end
    if #st.pool ~= #list then
        st.pool = {}
        for i = 1, #list do st.pool[i] = i end
        for i = #st.pool, 2, -1 do
            local j = math.random(i)
            st.pool[i], st.pool[j] = st.pool[j], st.pool[i]
        end
        st.idx = 1
    end
    if st.idx > #st.pool then
        for i = #st.pool, 2, -1 do
            local j = math.random(i)
            st.pool[i], st.pool[j] = st.pool[j], st.pool[i]
        end
        st.idx = 1
    end
    local idx = st.pool[st.idx]
    st.idx = st.idx + 1
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
local function pickAutoReplyLine()
    local list = collectPhrases(optReplyLines, replyCount.v)
    if #list == 0 then return end
    pcall(sampSendChat, pickCycleLine(list, state.replyCycle))
end

-- v1.2.6: поток отправки фразы через 1 сек после закрытия окна миниигры.
-- /cancel - это отмена выбранного /repair, окно миниигры при нём не
-- закрывается, поэтому на неё этот поток никак не реагирует.
local function sendFinishReplyThread()
    wait(1000)
    if not optCheat.v or not optAutoReply.v then return end
    if state.active then return end -- уже началась новая миниигра
    local list = collectPhrases(optFinishLines, finishCount.v)
    if #list == 0 then return end
    pcall(sampSendChat, pickCycleLine(list, state.finishCycle))
end

-- v1.2.6: ответ на перевод денег «Игрок [Nick] передал Вам $N».
-- Если сумма до 4000 - свой пул фраз, от 4001 - свой. КД 10 сек на каждую
-- группу суммы: пока КД активен, повторные переводы не спамят чат.
local function sendMoneyReply(sum)
    if not optCheat.v or not optAutoReply.v then return end
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
    pcall(sampSendChat, pickCycleLine(list, st))
end


-- v1.2.2: автоответ на фразу начала ремонта (анти-дубль 5 сек, фразы по циклу)
function sendAutoReplyIfStarted(bs)
    if not optCheat.v then return false end
    if not payloadHasRepairStart(bs) then return false end
    -- v1.1.7: заявка принята - уведомление «Чиню <ник> (id) - <модель>»
    -- показываем всегда (независимо от включённого автоответа)
    notifyRepairAccepted()
    if not optAutoReply.v then return true end
    if nowMs() - state.lastAutoReply < 5000 then return true end
    state.lastAutoReply = nowMs()
    pickAutoReplyLine()
    return true
end

--перестраховка: если фраза пришла не RPC-пакетом, а через стандартный
-- колбэк onServerMessage (текст в чате) - тоже отвечаем (анти-дубль 5 сек)
function onServerMessage(color, text)
    if not optCheat.v then return nil end
    -- v1.2.6: перевод денег «Игрок [Nick] передал Вам $5000»
    if text and text ~= "" then
        local sum = tonumber(text:match("передал [Вв]ам %$(%d+)"))
        if sum then
            sendMoneyReply(sum)
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
    notifyRepairAccepted()
    if nowMs() - state.lastAutoReply < 5000 then return nil end
    state.lastAutoReply = nowMs()
    pickAutoReplyLine()
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
            lua_thread.create(sendFinishReplyThread)
        end
        state.active = false
    end
end

-- ---------- Команда /mech ----------
local function toggleMenu()
    showMenu.v = not showMenu.v
end

-- ---------- Основной цикл ----------
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
                    pcall(sampSendChat, "/repair " .. pid)
                end
            end
        end

        wait(0)
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

        -- ===== ШАПКА: КНОПКА ВКЛЮЧЕНИЯ/ВЫКЛЮЧЕНИЯ ВСЕГО ЧИТА =====
        -- v1.2.7: мастер-переключатель всех функций (как в Les/Machinist):
        -- красная «Выключить чит» при включённом, зелёная «Включить чит» при выключенном.
        local _tH = imgui.GetTextLineHeightWithSpacing()
        local _oy = imgui.GetCursorPosY()
        local _bW = 150 * fsc
        local _bH = 24 * fsc
        if optCheat.v then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.80, 0.18, 0.18, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.0, 0.25, 0.25, 1.0))
        else
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.15, 0.65, 0.20, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.20, 0.85, 0.25, 1.0))
        end
        imgui.SetCursorPosX(imgui.GetWindowWidth() - _bW - 34 * fsc)
        imgui.SetCursorPosY(_oy - _tH - _bH * 0.5)
        if imgui.Button(optCheat.v and u8"ВЫКЛЮЧИТЬ ЧИТ" or u8"ВКЛЮЧИТЬ ЧИТ", imgui.ImVec2(_bW, _bH)) then
            setCheatMaster(not optCheat.v)
        end
        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Выключить или включить весь чит одним кликом")
        end
        imgui.SetCursorPos(imgui.ImVec2(0.0, _oy))
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
            if imgui.SliderInt(u8"   от, мс", optDelayMinMs, 0, 10000) then changed = true end
            if imgui.SliderInt(u8"   до, мс", optDelayMaxMs, 0, 10000) then changed = true end
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
            -- триггеры
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

            imgui.Separator()
            -- исключённые id
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

        elseif activeTab == 3 then
            -- ====== ВКЛАДКА «КУРСОР» ======
            imgui.TextWrapped(u8"Ручной выбор цели курсором + автоответ")
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
            imgui.Text(u8"Автоответ при ремонте:")
            if imgui.Checkbox(u8"   отправлять фразу при старте ремонта", optAutoReply) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Когда водитель принял ваш /repair, скрипт отправит в чат случайную фразу из списка. Фраза не повторяется дважды подряд")
            end
            imgui.TextWrapped(u8"Вставить сразу несколько фраз: каждая строка ниже станет отдельной фразой (до 30)")
            imgui.PushItemWidth(280 * fsc)
            imgui.InputTextMultiline(u8"   новые фразы##replyBlock", replyBlockInput, imgui.ImVec2(0, 70 * fsc), 0)
            imgui.PopItemWidth()
            imgui.SameLine(0, 6)
            if imgui.Button(u8"Вставить блок", imgui.ImVec2(160 * fsc, 0)) then
                if addReplyBlock() then changed = true end
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Каждая непустая строка поля добавится в список фраз до максимума 30. После вставки поле очищается")
            end
            imgui.PushItemWidth(280 * fsc)
            for i = 1, replyCount.v do
                imgui.PushID(100 + i)
                if imgui.InputText(u8("   фраза " .. i .. "##replyLine"), optReplyLines[i]) then changed = true end
                imgui.SameLine(0, 6)
                if replyCount.v > 1 then
                    if imgui.SmallButton(u8"х") then
                        for j = i, replyCount.v - 1 do
                            optReplyLines[j].v = optReplyLines[j + 1].v
                        end
                        optReplyLines[replyCount.v].v = ""
                        replyCount.v = replyCount.v - 1
                        changed = true
                    end
                end
                imgui.PopID()
            end
            imgui.PopItemWidth()
            if replyCount.v < 30 then
                if imgui.Button(u8"Добавить фразу", imgui.ImVec2(170 * fsc, 0)) then
                    replyCount.v = replyCount.v + 1
                    optReplyLines[replyCount.v].v = ""
                    changed = true
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Добавить ещё одно поле для фразы (всего до 30)")
                end
            end

        elseif activeTab == 4 then
            -- ====== ВКЛАДКА «АВТО-ПОДБОР» ======
            imgui.TextWrapped(u8"Автоматический /repair для подъехавших машин в радиусе")
            imgui.Separator()

            if imgui.Checkbox(u8"включить (автоматически)", optNearRepair) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Скрипт сам отправляет /repair каждой новой машине, подъехавшей в радиус")
            end
            if imgui.Checkbox(u8"вручную: по правой кнопке (ПКМ)", optManualRmb) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Авто-кидание отключается: /repair отправится ближайшему свободному водителю только по клику ПКМ")
            end

            imgui.PushItemWidth(150 * fsc)
            if imgui.SliderInt(u8"   радиус, м", optNearRadiusM, 2, 20) then changed = true end
            if imgui.SliderInt(u8"   пауза, сек", optNearDelaySec, 5, 300) then changed = true end
            imgui.PopItemWidth()

            imgui.Separator()
            imgui.TextWrapped(u8"Подъехавшая в радиус машина-игрок один раз получит /repair. Приоритет — мотоциклам. Водители с исключённым id пропускаются.")

        elseif activeTab == 5 then
            -- ====== ВКЛАДКА «ФРАЗЫ» ======
            imgui.TextWrapped(u8"Фразы по окончанию миниигры и ответы на перевод денег (формат «Игрок [Nick] передал Вам $5000»)")
            imgui.Separator()

            imgui.Text(u8"Фразы по окончанию миниигры (через 1 сек после закрытия):")
            imgui.PushItemWidth(280 * fsc)
            for i = 1, finishCount.v do
                imgui.PushID(300 + i)
                if imgui.InputText(u8("   финиш " .. i .. "##finishLine"), optFinishLines[i]) then changed = true end
                imgui.SameLine(0, 6)
                if finishCount.v > 1 then
                    if imgui.SmallButton(u8"х") then
                        for j = i, finishCount.v - 1 do
                            optFinishLines[j].v = optFinishLines[j + 1].v
                        end
                        optFinishLines[finishCount.v].v = ""
                        finishCount.v = finishCount.v - 1
                        changed = true
                    end
                end
                imgui.PopID()
            end
            imgui.PopItemWidth()
            if finishCount.v < 5 then
                if imgui.Button(u8"Добавить финиш", imgui.ImVec2(170 * fsc, 0)) then
                    finishCount.v = finishCount.v + 1
                    optFinishLines[finishCount.v].v = ""
                    changed = true
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Добавить ещё одно поле для фразы (всего до 5)")
                end
            end

            imgui.Separator()
            imgui.Text(u8"Фразы при переводе денег до 4000$:")
            imgui.PushItemWidth(280 * fsc)
            for i = 1, moneyLowCount.v do
                imgui.PushID(400 + i)
                if imgui.InputText(u8("   до 4000 " .. i .. "##moneyLowLine"), optMoneyLowLines[i]) then changed = true end
                imgui.SameLine(0, 6)
                if moneyLowCount.v > 1 then
                    if imgui.SmallButton(u8"х") then
                        for j = i, moneyLowCount.v - 1 do
                            optMoneyLowLines[j].v = optMoneyLowLines[j + 1].v
                        end
                        optMoneyLowLines[moneyLowCount.v].v = ""
                        moneyLowCount.v = moneyLowCount.v - 1
                        changed = true
                    end
                end
                imgui.PopID()
            end
            imgui.PopItemWidth()
            if moneyLowCount.v < 5 then
                if imgui.Button(u8"Добавить до 4000", imgui.ImVec2(170 * fsc, 0)) then
                    moneyLowCount.v = moneyLowCount.v + 1
                    optMoneyLowLines[moneyLowCount.v].v = ""
                    changed = true
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Добавить ещё одно поле для фразы (всего до 5)")
                end
            end

            imgui.Separator()
            imgui.Text(u8"Фразы при переводе денег от 4001$:")
            imgui.PushItemWidth(280 * fsc)
            for i = 1, moneyHighCount.v do
                imgui.PushID(500 + i)
                if imgui.InputText(u8("   от 4001 " .. i .. "##moneyHighLine"), optMoneyHighLines[i]) then changed = true end
                imgui.SameLine(0, 6)
                if moneyHighCount.v > 1 then
                    if imgui.SmallButton(u8"х") then
                        for j = i, moneyHighCount.v - 1 do
                            optMoneyHighLines[j].v = optMoneyHighLines[j + 1].v
                        end
                        optMoneyHighLines[moneyHighCount.v].v = ""
                        moneyHighCount.v = moneyHighCount.v - 1
                        changed = true
                    end
                end
                imgui.PopID()
            end
            imgui.PopItemWidth()
            if moneyHighCount.v < 5 then
                if imgui.Button(u8"Добавить от 4001", imgui.ImVec2(170 * fsc, 0)) then
                    moneyHighCount.v = moneyHighCount.v + 1
                    optMoneyHighLines[moneyHighCount.v].v = ""
                    changed = true
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(u8"Добавить ещё одно поле для фразы (всего до 5)")
                end
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

            imgui.Text(u8"Задержка: " .. optDelayMinMs.v .. u8"–" .. optDelayMaxMs.v .. u8" мс")
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
            imgui.TextWrapped(u8"Фразы: " .. replyCount.v .. u8" шт.  |  Триггеры: " .. #repairTriggers .. u8" шт.  |  Исключений: " .. #excludedIds .. u8" шт.")
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