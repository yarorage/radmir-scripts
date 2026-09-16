-- MechWorkByYaroRage v1.1.4
-- Автозавершение миниигры починки транспорта (Радмир CRMP).
-- v1.1.4: в блоке «Авто-подбор подъехавших машин» добавлен ручной
-- режим: /repair кидается не автоматически, а по клику правой
-- кнопки мыши (ПКМ) ближайшему водителю в том же радиусе; после
-- отправки водитель «замораживается» на паузу из GUI (optNearDelaySec)
-- — следующий клик берёт следующего по близости, после паузы можно
-- выбрать того же снова.
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
script_version("1.1.4")

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

local fsc = 1

-- ---------- Настройки (привязка к GUI) ----------
-- Конфиг храним через чистый io.open (как в AutoLoginByYaroRage): встроенный
-- inifile на этой сборке падает exception'ом create_directories, который не
-- ловится pcall, поэтому inicfg не используем.
local iniFile = getGameDirectory() .. "\\moonloader\\MechWorkByYaroRage.ini"

local function loadSettings()
    local s = { enabled = true, delayMs = 3000, autoStart = true, startDelayMs = 300,
                autoRepair = true, repairCooldown = 4000,
                autoReply = true,
                replyText = "Починю быстро за хороший чай! Заранее спасибо!",
                cursorPick = false,
                cursorButton = 0x04,
                cursorDelayMs = 1000,
        nearRepair = false,
        nearRadiusM = 5,
        nearDelaySec = 30,
        manualRmb = false, -- ручной запрос /repair по ПКМ (v1.1.4)
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
    end
    -- защита от повреждённых значений старых версий (в ini попали байты
    -- EF BF BD = символы замены U+FFFD вместо CP1251): тогда берём дефолт
    local fffd = string.char(0xEF, 0xBF, 0xBD)
    if s.replyText and s.replyText:find(fffd, 1, true) then
        s.replyText = "Починю быстро за хороший чай! Заранее спасибо!"
    end
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
-- задержка после старта миниигры до отправки финиша, мс
local optDelayMs = imgui.ImInt(settings.delayMs)
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
-- текст автоответа (игрок его якобы сам пишет в чат)
-- imgui работает в UTF-8, а настройки лежат в CP1251 -> конвертируем
local optReplyText = imgui.ImBuffer(128)
optReplyText.v = u8(settings.replyText or "")
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

local showMenu = imgui.ImBool(false)

-- ---------- Состояние миниигры ----------
local state = {
    active = false,    -- миниигра сейчас идёт
    title = "",        -- название миниигры
    busy = false,      -- поток автозакрытия уже запущен
    autoStarting = false, -- поток авто-старта уже запущен
    lastRepair = 0,    -- время последнего автозапроса /repair (GetTickCount, мс)
    lastAutoReply = 0, -- время последнего автоответа в чат (GetTickCount, мс)
    cursorVisible = false, -- курсор выбора цели показан (по удержанию колесика)
    -- ---------- v1.1.1: авто-ремонт подъехавших в радиус ----------
    nearQueue = {},      -- таблица прошлых /repair: veh -> nowMs
    nearWaiting = false, -- ждём завершения текущей миниигры (после отправки /repair)
    nearSawActive = false, -- миниигра уже началась (для детекта конца)
    nearLockUntil = 0,   -- не отправлять раньше этого времени (GetTickCount)
    nearSentAt = 0      -- время последней отправки /repair в ближнем режиме (GetTickCount)
}

function saveSettings()
    local lines = {
        "enabled = " .. (optEnabled.v and "true" or "false"),
        "delayMs = " .. optDelayMs.v,
        "autoStart = " .. (optAutoStart.v and "true" or "false"),
        "startDelayMs = " .. optStartDelayMs.v,
        "autoRepair = " .. (optAutoRepair.v and "true" or "false"),
        "repairCooldown = " .. optRepairCooldown.v,
        "autoReply = " .. (optAutoReply.v and "true" or "false"),
        -- optReplyText.v в UTF-8 (imgui), в ini пишем CP1251
        "replyText = " .. toCp(optReplyText.v or ""),
        "cursorPick = " .. (optCursorPick.v and "true" or "false"),
        "cursorButton = " .. currentCursorVk(),
        "cursorDelayMs = " .. math.floor((optCursorDelaySec.v or 1.0) * 1000 + 0.5),
        "nearRepair = " .. (optNearRepair.v and "true" or "false"),
        "nearRadiusM = " .. optNearRadiusM.v,
        "nearDelaySec = " .. optNearDelaySec.v,
        "manualRmb = " .. (optManualRmb.v and "true" or "false"),
    }
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
    -- ждём регулируемую задержку (миниигра только что запустилась)
    if optDelayMs.v > 0 then wait(optDelayMs.v) end
    if state.active and optEnabled.v then
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
                    if okP and isP and pid and pid >= 1 then
                        cands[#cands + 1] = { veh = veh, pid = pid, d = dx * dx + dy * dy + dz * dz }
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

    -- самая близкая из тех, кому ещё не слали (или слали давно — машина снова подъехала)
    table.sort(cands, function(a, b) return a.d < b.d end)
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
            if okP and isPlayer and pid and pid >= 1 then
                state.lastRepair = nowMs()
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

-- автоответ на фразу начала ремонта (анти-дубль 5 сек)
function sendAutoReplyIfStarted(bs)
    if not optAutoReply.v then return false end
    if not payloadHasRepairStart(bs) then return false end
    if nowMs() - state.lastAutoReply < 5000 then return true end
    state.lastAutoReply = nowMs()
    local reply = optReplyText.v or ""
    if reply == "" then return true end
    -- imgui отдаёт текст в UTF-8, в чат нужен CP1251
    pcall(sampSendChat, toCp(reply))
    return true
end

--перестраховка: если фраза пришла не RPC-пакетом, а через стандартный
-- колбэк onServerMessage (текст в чате) - тоже отвечаем (анти-дубль 5 сек)
function onServerMessage(color, text)
    if not optAutoReply.v then return nil end
    if not text or text == "" then return nil end
    local hit = false
    for i = 1, #repairStartPhrases do
        if text:find(repairStartPhrases[i], 1, true) then hit = true break end
    end
    if not hit then return nil end
    if nowMs() - state.lastAutoReply < 5000 then return nil end
    state.lastAutoReply = nowMs()
    local reply = optReplyText.v or ""
    if reply == "" then return nil end
    -- imgui отдаёт текст в UTF-8, в чат нужен CP1251
    pcall(sampSendChat, toCp(reply))
    return nil
end

-- перехват всех входящих RPC (выполняется для каждого скрипта отдельно)
function onReceiveRpc(id, bs)
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
    if optAutoStart.v and txt:find("Interactions", 1, true) and txt:find("setInfo", 1, true) then
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
        if optEnabled.v and not state.busy then
            lua_thread.create(finishMinigameThread)
        end
        return
    end
    -- закрытие миниигры (команда HelloweenBuild без аргументов)
    if txt:find("HelloweenBuild", 1, true) then
        state.active = false
    end
end

-- ---------- Команда /mech ----------
local function toggleMenu()
    showMenu.v = not showMenu.v
end

-- ---------- Основной цикл ----------
function main()
    repeat wait(0) until isSampAvailable()
    wait(500)

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

        -- ---- отслеживание выбранной кнопки показа курсора ----
        local now = nowMs()
        local down = isVkDown(currentCursorVk())
        if down then
            if not mbDown then
                -- начало удержания
                mbDown = true
                mbDownAt = now
                mbProcessed = false
            elseif not mbProcessed and optCursorPick.v and now - mbDownAt >= optCursorDelaySec.v * 1000 then
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
                if optCursorPick.v and state.cursorVisible and held < optCursorDelaySec.v * 1000 and not showMenu.v then
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
            local rmbOk = optManualRmb.v and not showMenu.v and not state.active
                      and not state.cursorVisible and not (optCursorPick.v and currentCursorVk() == 0x02)
            if rmbDown and not rmbPrev and rmbOk then
                local okChat = pcall(sampIsChatInputActive)
                local okDlg = pcall(sampIsDialogActive)
                if (not okChat or not sampIsChatInputActive()) and (not okDlg or not sampIsDialogActive()) then
                    sendNearRepairManual()
                end
            end
            rmbPrev = rmbDown
        end

        -- ---------- v1.1.1: авто-ремонт подъехавших в радиус ----------
        -- авто-режим отключается, если включён ручной режим по ПКМ (v1.1.4)
        if optNearRepair.v and not optManualRmb.v and optEnabled.v and not state.active and not showMenu.v then
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

    -- защита от нулевого/некорректного разрешения: окно всегда видно и влезает в экран
    local winW = math.max(420, math.min(560 * fsc, resX - 20))
    local winH = math.max(360, math.min(680 * fsc, resY - 40))

    if showMenu.v then
        local changed = false
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - winW / 2, resY / 2 - winH / 2), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
        imgui.Begin(u8"MechWorkByYaroRage", showMenu, imgui.WindowFlags.NoCollapse)

        -- содержимое окна в прокручиваемой области: форма не обрезается
        -- ни на каком разрешении/масштабе DPI, окно всегда влезает в экран
        imgui.BeginChild(u8"##content", imgui.ImVec2(0, 0), false, imgui.WindowFlags.NoSavedSettings)

        imgui.TextWrapped(u8"Автозавершение миниигры починки транспорта")
        imgui.Separator()

        if imgui.Checkbox(u8"Авто-закрытие", optEnabled) then changed = true end

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
        imgui.Text(u8"Задержка перед закрытием:")
        if imgui.SliderInt(u8"   задержка, мс", optDelayMs, 0, 10000) then changed = true end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"После старта миниигры подождать это время и отправить успешный финиш")
        end

        imgui.Separator()
        imgui.Text(u8"Авто-ремонт:")
        if imgui.Checkbox(u8"   ремонт по сообщениям в чат", optAutoRepair) then changed = true end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Если игрок написал в чат «почини/чини/ремонт», скрипт сам отправит /repair <id> этому игроку")
        end
        imgui.PushItemWidth(120 * fsc)
        if imgui.SliderInt(u8"   пауза между запросами, мс", optRepairCooldown, 500, 20000) then changed = true end
        imgui.PopItemWidth()

        imgui.Separator()
        imgui.Text(u8"Выбор цели курсором:")
        if imgui.Checkbox(u8"   выбрать цель удержанием кнопки", optCursorPick) then changed = true end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Удерживайте выбранную кнопку (не отпуская) — появится курсор. Удержите ещё раз — курсор скроется. Короткий клик по машине отправит водителю /repair по его id")
        end
        imgui.PushItemWidth(220 * fsc)
        if imgui.Combo(u8"   кнопка##cursorBtn", optCursorButton, cursorButtonNames, nil, #cursorButtonList) then changed = true end
        imgui.PopItemWidth()
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Кнопка, удержанием которой показывается курсор: средняя/боковые кнопки мыши или клавиши")
        end
        imgui.PushItemWidth(220 * fsc)
        if imgui.SliderFloat(u8"   задержка показа, сек##cursorDelay", optCursorDelaySec, 0.1, 2.0, "%.1f") then changed = true end
        imgui.PopItemWidth()
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Сколько держать кнопку до появления курсора (0.1-2.0 сек). Клик короче этого времени = выбор машины")
        end

        imgui.Separator()
        imgui.Text(u8"Автоответ при ремонте:")
        if imgui.Checkbox(u8"   отвечать в чат при старте ремонта", optAutoReply) then changed = true end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Когда водитель принял ваш /repair, сервер пишет «Подойдите к капоту... У Вас есть 1 минута на ремонт» — скрипт отправит текст ниже в чат от имени персонажа")
        end
        imgui.PushItemWidth(300 * fsc)
        if imgui.InputText(u8"   текст ответа##replyText", optReplyText) then changed = true end
        imgui.PopItemWidth()

        -- Редактирование списка триггеров (сообщения, по которым шлём /repair)
        imgui.Text(u8"Триггеры авто-ремонта:")
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Если кто-то напишет в чат фразу из списка (целиком или её часть), скрипт отправит этому игроку /repair по его id")
        end
        imgui.PushItemWidth(280 * fsc)
        imgui.InputText(u8"   новая фраза##trig", triggerInput)
        imgui.PopItemWidth()
        imgui.SameLine(0, 10)
        if imgui.Button(u8"Добавить", imgui.ImVec2(100 * fsc, 0)) then
            addTriggerHint.v = not addTrigger(triggerInput.v)
            if not addTriggerHint.v then
                triggerInput.v = ""
            end
        end
        -- подсказка о неудачном добавлении
        if addTriggerHint.v then
            imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"   пустая или уже есть такая фраза")
        end
        -- список текущих триггеров с прокруткой (кнопка удаления)
        imgui.BeginChild(u8"##trigList", imgui.ImVec2(0, 150 * fsc))
        for i = 1, #repairTriggers do
            imgui.PushID(i)
            imgui.Text("  - " .. u8(repairTriggers[i]))
            imgui.SameLine(0, 20)
            if imgui.SmallButton(u8"удалить") then
                removeTrigger(i)
            end
            imgui.PopID()
        end
        imgui.EndChild()

        imgui.Separator()
        -- статус
        local status = u8"Миниигра не активна"
        if state.active then
            status = u8"Миниигра активна: " .. (state.title ~= "" and u8(state.title) or u8"без названия")
        end
        imgui.TextWrapped(status)
        imgui.Text(u8"Авто-закрытие: " .. (optEnabled.v and u8"включено" or u8"выключено"))
        imgui.Text(u8"Авто-старт: " .. (optAutoStart.v and u8"включён" or u8"выключен"))
        imgui.Text(u8"Авто-ремонт: " .. (optAutoRepair.v and u8"включён" or u8"выключен"))

        imgui.Separator()
        if imgui.Button(u8"Сохранить", imgui.ImVec2(200 * fsc, 34 * fsc)) then
            saveSettings()
            changed = false
        end

        imgui.Separator()
        imgui.Text(u8"Авто-подбор подъехавших машин:")
        imgui.Separator()
            if imgui.Checkbox(u8"   включить (автоматически)", optNearRepair) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Скрипт сам отправляет /repair каждой новой машине, подъехавшей в радиус. Не работает, пока включён ручной режим ниже")
            end
            if imgui.Checkbox(u8"   вручную: по правой кнопке (ПКМ)", optManualRmb) then changed = true end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Авто-кидание при этом отключается: /repair отправится ближайшему водителю в радиусе только по клику правой кнопкой мыши. Отправленный водитель замораживается на «паузу, сек» — следующий клик возьмёт следующего по близости, после паузы того же можно выбрать снова")
            end
            imgui.PushItemWidth(150 * fsc)
            if imgui.SliderInt(u8"   радиус, м", optNearRadiusM, 2, 20) then changed = true end
            if imgui.SliderInt(u8"   пауза, сек", optNearDelaySec, 5, 300) then changed = true end
            imgui.PopItemWidth()
            imgui.TextWrapped(u8"Подъехавшая в радиус машина-игрок один раз получит /repair. В авто-режиме скрипт сам последовательно ремонтирует машины (пауза между отправками — N сек), в ручном — только по клику ПКМ, ближайшему свободному водителю.")
            imgui.Separator()
            if imgui.Button(u8"Сохранить", imgui.ImVec2(200 * fsc, 34 * fsc)) then
                changed = true
            end
            imgui.SameLine()
            if imgui.Button(u8"Закрыть", imgui.ImVec2(200 * fsc, 34 * fsc)) then
                showMenu.v = false
            end

        imgui.EndChild()

        imgui.End()

        if changed then
            saveSettings()
            changed = false
        end
    end
end
