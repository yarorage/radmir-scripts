--============================================================================================
script_name("CheatByYaroRage")
script_author("YaroRage")
script_version("0.4.2")
--==================================[ НАСТРОЙКИ ЧИТА ]==============================================
require 'moonloader'
require "lib.sampfuncs"

local ywelcome         = require "ywelcome"
local fa 			= require 'fAwesome5'
local vKeys         = require('vKeys')
local ffi 			= require 'ffi'
local ev            = require("lib.samp.events")
local inicfg 		= require('inicfg')
local vector 		= require 'vector3d'
local memory 		= require 'memory'
local imgui 		= require('imgui')
local fsc = 1
-- DPI-масштаб Windows (4K, 150-200% и т.п.): UI подгоняется под него автоматически.
-- Базовый множитель — высота рендера / 1080. Если игра не покрывает весь экран
-- нативно (окно/неполноэкранный режим), дополнительно применяется DPI.
local dpiUi = 1.0
do
    local ok, dpi = pcall(function()
        ffi.cdef[[
            int GetDpiForSystem(void);
            int GetSystemMetrics(int nIndex);
        ]]
        return ffi.C.GetDpiForSystem()
    end)
    if ok and type(dpi) == "number" and dpi > 0 then dpiUi = dpi / 96 end
    -- Диапазон 100%..350% (0.5..3.5) с шагом 25%
    if dpiUi < 0.5 then dpiUi = 0.5 elseif dpiUi > 3.5 then dpiUi = 3.5 end
end
local encoding      = require("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- HotKey система
local hotkey = {}
if doesFileExist(getWorkingDirectory() .. "/lib/imgui_addons.lua") then
    hotkey = require("imgui_addons").HotKey
end

-- Профили конфигов
local profiles = {"Visual Only", "Legit PvP", "Biz Farmer", "Full Safe", "Rage", "Custom"}
local current_profile = 1

-- ===== ADMIN DETECTION (Radmir CRMP) =====
local admin_detection = imgui.ImBool(true)
local auto_spectator_check = imgui.ImBool(false)  -- Автоматическая проверка слежки
local admin_list = {}          -- {id = {nick, color, score, reason(post), date, dist}}
local chat_admins = {}         -- {ник = true} админы, выявленные по сообщениям сервера ("Администратор X ...")
local chat_detected_list = {}  -- {ник = {reason=..., date=...}} список выявленных по чату админов (для показа оффлайн)
local known_online = {}        -- {ник = pid} онлайн статус админов из списка known_admins
local spectator_list = {}      -- {id = {nick, time, dist, reason, date}}
local show_admin_hud = imgui.ImBool(false)
local admin_hud_pos = {x = 10, y = 10}
local resource_path = "moonloader/CheatByYaroRage/resource/"

-- Временный отладочный лог для диагностики детекта админов по чату
function debugLogStr(txt, hex)
    local fp = io.open("moonloader/CheatByYaroRage/resource/cheat_det_debug.log", "a")
    if fp then
        if hex then
            fp:write(os.date("%H:%M:%S") .. " | HEX[")
            for i = 1, #txt do
                fp:write(string.format("%02X ", string.byte(txt, i)))
            end
            fp:write("]\n")
        else
            fp:write(os.date("%H:%M:%S") .. " | " .. txt .. "\n")
        end
        fp:close()
    end
end

-- Точный список действующих администраторов (форум: RM RP 2.1 Список действующих администраторов)
-- При каждом включении чекера список перечитывается из файла resource/CheatAdminList.txt,
-- если файл повреждён или отсутствует — используется встроенный список ниже.
local known_admins = {
    -- Старшая администрация
    {nick = "Denis_Madborn",   post = "Заместитель Главного Администратора", date = "12.02.2024"},
    {nick = "Vadim_Kruvoshey", post = "Главный Администратор",               date = "04.01.2024"},
    -- Следящая администрация
    {nick = "Anyuta_Bennet",   post = "Зам. Главного Следящего за Криминальными структурами",     date = "13.11.2025"},
    {nick = "Daniil_Umberto",  post = "Главный Следящий за Государственными структурами",         date = "10.05.2025"},
    {nick = "Dmitriy_Carter",  post = "Зам. Главного Следящего за Государственными структурами",  date = "06.03.2026"},
    -- Админы 4 уровня
    {nick = "Alexey_Voskhod",      post = "Админ 4 уровня", date = "30.12.2025"},
    {nick = "Arkady_Kotow",        post = "Админ 4 уровня", date = "01.12.2025"},
    {nick = "Dover_Belly",         post = "Админ 4 уровня", date = "24.06.2026"},
    {nick = "Fura_Escobarov",      post = "Админ 4 уровня", date = "16.08.2026"},
    {nick = "Jaehaerys_Targaryen", post = "Админ 4 уровня", date = "05.11.2025"},
    {nick = "Lukas_Na_Offroad",    post = "Админ 4 уровня", date = "30.08.2026"},
    {nick = "Malloy_Mironov",      post = "Админ 4 уровня", date = "29.07.2026"},
    {nick = "May_Wong",            post = "Админ 4 уровня", date = "21.06.2025"},
    {nick = "Nekit_Morgan",        post = "Админ 4 уровня", date = "26.07.2025"},
    {nick = "Robert_Orlov",        post = "Админ 4 уровня", date = "01.08.2026"},
    {nick = "Santiago_Arxitektor", post = "Админ 4 уровня", date = "21.03.2026"},
    {nick = "Yakuto_Nakamura",     post = "Админ 4 уровня", date = "16.08.2026"},
    -- Админы 3 уровня
    {nick = "Aleksandr_Raskalov",  post = "Админ 3 уровня", date = "16.08.2026"},
    {nick = "Arina_Loving",        post = "Админ 3 уровня", date = "16.08.2026"},
    {nick = "Kris_Malinka",        post = "Админ 3 уровня", date = "29.08.2026"},
    {nick = "Lens_Loving",         post = "Админ 3 уровня", date = "16.08.2026"},
    {nick = "Leonardo_Johnson",    post = "Админ 3 уровня", date = "21.08.2026"},
    {nick = "Ria_Kubik",           post = "Админ 3 уровня", date = "12.07.2026"},
    {nick = "Roman_McDonald",      post = "Админ 3 уровня", date = "16.08.2026"},
    -- Админы 2 уровня
    {nick = "Aleshqa_Absolut",   post = "Админ 2 уровня", date = "04.08.2026"},
    {nick = "Alexander_Olimp",   post = "Админ 2 уровня", date = "31.07.2026"},
    {nick = "Ave_Cezar",         post = "Админ 2 уровня", date = "23.07.2026"},
    {nick = "Dima_Mafioznic",    post = "Админ 2 уровня", date = "16.08.2026"},
    {nick = "Lia_Winston",       post = "Админ 2 уровня", date = "31.07.2026"},
    {nick = "Matvei_Makeev",     post = "Админ 2 уровня", date = "04.08.2026"},
    {nick = "Paulo_Eskabaro",    post = "Админ 2 уровня", date = "16.08.2026"},
    {nick = "Sanya_Prorok",      post = "Админ 2 уровня", date = "16.08.2026"},
    {nick = "Vitya_Malishok",    post = "Админ 2 уровня", date = "16.08.2026"},
    {nick = "Well_Ts",           post = "Админ 2 уровня", date = "16.08.2026"},
    -- Админы 1 уровня
    {nick = "Alexey_Gordeev",    post = "Админ 1 уровня", date = "05.08.2026"},
    {nick = "Asu_Carteles",      post = "Админ 1 уровня", date = "30.07.2026"},
    {nick = "Cody_Extazyy",      post = "Админ 1 уровня", date = "17.08.2026"},
    {nick = "Genadiy_Margiela",  post = "Админ 1 уровня", date = "12.08.2026"},
    {nick = "Mishka_Shalun",    post = "Админ 1 уровня", date = "17.08.2026"},
    {nick = "Vadim_De_Fellow",   post = "Админ 1 уровня", date = "18.08.2026"},
    {nick = "Vitya_Malishok",    post = "Админ 1 уровня", date = "26.07.2026"},
    {nick = "Walter_Malkov",     post = "Админ 1 уровня", date = "15.08.2026"},
    {nick = "Willy_McLine",      post = "Админ 1 уровня", date = "21.08.2026"},
}

-- Файл дополнительных админов, выявленных детектором (не теряются при обновлении с сайта)
local new_admins_file = resource_path .. "CheatNewAdmins.txt"

-- Поиск админа в known_admins по нику (без учёта регистра)
local function findInKnownAdminList(nick)
    local target = string.lower(nick)
    for _, a in ipairs(known_admins) do
        if string.lower(a.nick) == target then
            return a
        end
    end
    return nil
end

-- Дозагрузка админов из файла новых (если ещё нет в списке)
local function mergeNewAdmins()
    local f = io.open(new_admins_file, "r")
    if not f then return end
    local data = f:read("*a")
    f:close()
    for line in data:gmatch("[^\r\n]+") do
        local nick, post, date = line:match("^(.-)|(.-)|(.-)$")
        if nick and #nick > 0 and not findInKnownAdminList(nick) then
            table.insert(known_admins, {nick = nick, post = post or "Админ (по сообщению сервера)", date = date or os.date("%d.%m.%Y")})
        end
    end
end

-- Сохранение нового админа в отдельный файл и добавление в known_admins
local function saveNewAdmin(nick, post, date)
    if findInKnownAdminList(nick) then return end
    date = date or os.date("%d.%m.%Y")
    table.insert(known_admins, {nick = nick, post = post or "Админ (по сообщению сервера)", date = date})
    local f = io.open(new_admins_file, "a")
    if f then
        f:write(nick .. "|" .. (post or "Админ (по сообщению сервера)") .. "|" .. date .. "\r\n")
        f:close()
    end
end

-- Загрузка внешнего списка админов из файла resource/CheatAdminList.txt
local function loadAdminListFile()
    local path = resource_path .. "CheatAdminList.txt"
    local f = io.open(path, "r")
    if not f then
        sampAddChatMessage("Cheat: не найден файл списка админов, использую встроенный список", -1)
        return false
    end
    local data = f:read("*a")
    f:close()
    local loaded = {}
    local counter = 0
    for line in data:gmatch("[^\r\n]+") do
        local nick, post, date = line:match("^(.-)|(.-)|(.-)$")
        if nick and #nick > 0 then
            counter = counter + 1
            table.insert(loaded, {nick = nick, post = post or "", date = date or ""})
        end
    end
    if counter > 0 then
        known_admins = loaded
        mergeNewAdmins()
        sampAddChatMessage("Cheat: список админов обновлён из файла (" .. counter .. ")" , -1)
        return true
    end
    return false
end

-- Функция проверки, является ли игрок админом (по точному списку или приписке)
local function isPlayerAdmin(id)
    if not sampIsPlayerConnected(id) then return false, nil, nil end
    local nick = sampGetPlayerNickname(id)

    -- Точное совпадение с официальным списком действующих администраторов (без учёта регистра)
    local low_nick = nick:lower()
    for _, a in ipairs(known_admins) do
        if low_nick == a.nick:lower() then
            return true, a.post, a.date
        end
    end

    -- Приписка "Администратор" / "Аdmin" в нике
    local low = nick:lower()
    if low:find("админ") or low:find("admin") then
        return true, "Ник с припиской Администратор", nil
    end

    -- Админ, выявленный по системному сообщению сервера ("Администратор X ...") без учёта регистра
    for chat_nick in pairs(chat_admins) do
        if low == chat_nick:lower() then
            return true, "Админ (по сообщению сервера)", nil
        end
    end

    return false, nil, nil
end

-- Поиск игрока по нику без учёта регистра (для чат-детекта админов)
function findPlayerByNickname(nick)
    local target = string.lower(nick)
    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) then
            local n = sampGetPlayerNickname(i) or ""
            if string.lower(n) == target then
                return i, n
            end
        end
    end
    return nil, nil
end

-- Обновление списка админов
function updateAdminList()
    admin_list = {}
    known_online = {}
    if not PLAYER_PED or not doesCharExist(PLAYER_PED) then
        return
    end

    -- Карта пула игроков: lower(ник) -> id (для быстрого поиска)
    local poolByNick = {}
    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) then
            local n = sampGetPlayerNickname(i) or ""
            if n ~= "" then
                local k = string.lower(n)
                if not poolByNick[k] then poolByNick[k] = i end
            end
        end
    end

    -- Статус «онлайн» для админов из официального списка (без репортов)
    for _, a in ipairs(known_admins) do
        local pid = poolByNick[string.lower(a.nick)]
        if pid and sampIsPlayerConnected(pid) then
            known_online[a.nick] = pid
        end
    end

    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) then
            local is_admin, post, date = isPlayerAdmin(i)
            if is_admin then
                local data = {
                    nick = sampGetPlayerNickname(i),
                    color = sampGetPlayerColor(i),
                    score = sampGetPlayerScore(i),
                    reason = post,
                    date = date,
                    dist = 0
                }
                -- Дистанция до нас
                local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                if my_id ~= i then
                    local _, ped = sampGetCharHandleBySampPlayerId(i)
                    if ped and doesCharExist(ped) then
                        local mx, my, mz = getCharCoordinates(PLAYER_PED)
                        local px, py, pz = getCharCoordinates(ped)
                        data.dist = math.floor(getDistanceBetweenCoords3d(mx, my, mz, px, py, pz))
                    end
                end
                admin_list[i] = data
            end
        end
    end

    -- Дополнительно: выявленные по сообщениям сервера админы, найденные напрямую по нику
    for nick in pairs(chat_admins) do
        local pid = poolByNick[string.lower(nick)]
        if pid and sampIsPlayerConnected(pid) and not admin_list[pid] then
            admin_list[pid] = {
                nick = nick,
                color = sampGetPlayerColor(pid),
                score = sampGetPlayerScore(pid),
                reason = "Админ (по сообщению сервера)",
                date = nil,
                dist = 0
            }
        end
    end
end
function checkSpectators()
    spectator_list = {}
    if not PLAYER_PED or not doesCharExist(PLAYER_PED) then
        return
    end
    for id, admin_data in pairs(admin_list) do
        if sampIsPlayerConnected(id) then
            local _, ped = sampGetCharHandleBySampPlayerId(id)
            if ped and doesCharExist(ped) then
                local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                if id ~= my_id then
                    local mx, my, mz = getCharCoordinates(PLAYER_PED)
                    local px, py, pz = getCharCoordinates(ped)
                    local dist = getDistanceBetweenCoords3d(mx, my, mz, px, py, pz)
                    if dist < 100 then  -- Увеличен радиус для админов
                        table.insert(spectator_list, {
                            id = id,
                            nick = admin_data.nick,
                            dist = math.floor(dist),
                            time = os.date("%H:%M:%S"),
                            reason = admin_data.reason,
                            date = admin_data.date
                        })
                    end
                end
            end
        end
    end
end

local window = imgui.ImBool(false)
local ignore = false
local aiming = 3
local silent = false

-- Горячие клавиши для функций
local hotkeys = {
    airbrake = {v = {vKeys.VK_RSHIFT}},
    flipcar = {v = {vKeys.VK_OEM_3}},
    sbivx = {v = {vKeys.VK_B}},
    capturebiz = {v = {}},
    godcar = {v = {}},
    enginecar = {v = {}},
    speedhack = {v = {vKeys.VK_MENU}},
    eyefish = {v = {}},
    ifastconnect = {v = {}},
    noReload = {v = {}},
    antistun = {v = {}},
    shotmax = {v = {}},
    damageinf = {v = {}},
    clickwarp = {v = {}},
    pslide = {v = {}},
    trigger = {v = {}},
    cbz5 = {v = {}},
    legit = {v = {}},
    fullskillgun = {v = {}},
    allowBunnyhop = {v = {}},
    NoAnimationMoney = {v = {}},
    silentmode = {v = {}},
    nodamage = {v = {}},
    autokick = {v = {}},
}

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

local font = renderCreateFont("Arial", 8, 12)
local font2 = renderCreateFont("Tahoma", 10, 5)

function GetBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

-- НАСТРОЙКИ.

local mcheat = imgui.ImBool(false)
-- Автопояс: управляется галкой Autorem во вкладке Машины (см. tfirst)

-- ФУНКЦИИ.

local clickwarp = imgui.ImBool(false)
local sbivx = imgui.ImBool(false)
local SpeedHack = imgui.ImBool(false)
local SpeedSmooth = imgui.ImInt(15)
local fullskillgun = imgui.ImBool(false)
local trigger = imgui.ImBool(false)
local airbrake = imgui.ImBool(false)
local Speed = imgui.ImFloat(1.0)
local Dist = imgui.ImFloat(50.0)
local Fov = imgui.ImFloat(5.0)
local cbz5 = imgui.ImBool(false)
local nodamage = imgui.ImBool(false)
local autokick = imgui.ImBool(false)
local damageinf = imgui.ImBool(false)
local capturebiz = imgui.ImBool(false)
local messages = {}
local buffer = {}
local str = imgui.ImBuffer(2048)
local fakeChatColor = -1
local enginecar = imgui.ImBool(false)
local legit = imgui.ImBool(false)
local noReload = imgui.ImBool(false)
local shotmax = imgui.ImBool(false)
local antistun = imgui.ImBool(false)
local ifastconnect = imgui.ImBool(false)
local eyefish = imgui.ImBool(false)
local allowBunnyhop = imgui.ImBool(false)
local NoAnimationMoney = imgui.ImBool(false)
local godcar = imgui.ImBool(false)
local silentmode = imgui.ImInt(3)
local pslide = imgui.ImBool(false)
local flipcar = imgui.ImBool(false)

-- НОВЫЕ ФУНКЦИИ
local flycar = imgui.ImBool(false)
local flycar_speed = imgui.ImFloat(50.0)
local flycar_brake = imgui.ImFloat(1.0)
local coordmaster = imgui.ImBool(false)
local coordmaster_step = imgui.ImFloat(5.0)
local coordmaster_delay = imgui.ImInt(20)
local coordmaster_height = imgui.ImFloat(120.0)
local autocapture = imgui.ImBool(false)
local autocapture_time = imgui.ImBuffer("13:00:00", 10)
local autocapture_ms = imgui.ImInt(0)
local anticrasher = imgui.ImBool(false)
local anti_detonator = imgui.ImBool(false)
local anti_roll = imgui.ImBool(false)
local anti_trailer = imgui.ImBool(false)
local anti_vortex = imgui.ImBool(false)

local nametags_dist_slider = imgui.ImInt(8)
local tdtext_dist_slider = imgui.ImInt(8)
local chatbubbles_dist_slider = imgui.ImInt(6)
local fog_dist_slider = imgui.ImInt(350)
local lods_dist_slider = imgui.ImInt(150)
local tfirst = imgui.ImBool(false)
local tsecond = imgui.ImBool(false)
local triggermode = imgui.ImInt(3)

local mainIni = inicfg.load({
    CheatByYaroRage =
    {
		clickwarp = false,
		sbivx = false,
		allowBunnyhop = false,
        SpeedHack = false,
        SpeedSmooth = 15,
		fullskillgun = false,
		eyefish = false,
		trigger = false,
		airbrake = false,
		autokick = false,
		pslide = false,
		tfirst = false,
		tsecond = false,
		Speed = 1.0,
		Dist = 50.0,
		triggermode = 3,
		silentmode = 3,
		legit = false,
		cbz5 = false,
		nodamage = false,
		capturebiz = false,
		ifastconnect = false,
		enginecar = false,
		noReload = false,
		antistun = false,
		shotmax = false,
		godcar = false,
		NoAnimationMoney = false,
		Fov = 5.0,
		damageinf = false,
		nametags_dist = 8,
		tdtext_dist = 8,
		chatbubbles_dist = 6,
		fog_dist = 350,
		lods_dist = 150,
		-- Новые функции
		flycar = false,
		flycar_speed = 50.0,
		flycar_brake = 1.0,
		coordmaster = false,
		coordmaster_step = 5.0,
		coordmaster_delay = 20,
		coordmaster_height = 120.0,
		autocapture = false,
		autocapture_time = "13:00:00",
		autocapture_ms = 0,
		anticrasher = false,
		anti_detonator = false,
		anti_roll = false,
		anti_trailer = false,
		anti_vortex = false,
		admin_detection = true,
		auto_spectator_check = false,
		show_admin_hud = false,
		theme = 0,
		profile = 0,
		menuTab = 1,
    }
}, 'CheatByYaroRage/CheatByYaroRage.ini')

godcar.v = mainIni.CheatByYaroRage.godcar or false
NoAnimationMoney.v = mainIni.CheatByYaroRage.NoAnimationMoney or false
clickwarp.v = mainIni.CheatByYaroRage.clickwarp or false
sbivx.v = mainIni.CheatByYaroRage.sbivx or false
SpeedHack.v = mainIni.CheatByYaroRage.SpeedHack or false
SpeedSmooth.v = mainIni.CheatByYaroRage.SpeedSmooth or 15
fullskillgun.v = mainIni.CheatByYaroRage.fullskillgun or false
pslide.v = mainIni.CheatByYaroRage.pslide or false
trigger.v = mainIni.CheatByYaroRage.trigger or false
autokick.v = mainIni.CheatByYaroRage.autokick or false
airbrake.v = mainIni.CheatByYaroRage.airbrake or false
Speed.v = mainIni.CheatByYaroRage.Speed or 1.0
ifastconnect.v = mainIni.CheatByYaroRage.ifastconnect or false
enginecar.v = mainIni.CheatByYaroRage.enginecar or false
noReload.v = mainIni.CheatByYaroRage.noReload or false
allowBunnyhop.v = mainIni.CheatByYaroRage.allowBunnyhop or false
eyefish.v = mainIni.CheatByYaroRage.eyefish or false
antistun.v = mainIni.CheatByYaroRage.antistun or false
shotmax.v = mainIni.CheatByYaroRage.shotmax or false
Dist.v = mainIni.CheatByYaroRage.Dist or 50.0
silentmode.v = mainIni.CheatByYaroRage.silentmode or 3
Fov.v = mainIni.CheatByYaroRage.Fov or 5.0
legit.v = mainIni.CheatByYaroRage.legit or false
cbz5.v = mainIni.CheatByYaroRage.cbz5 or false
nodamage.v = mainIni.CheatByYaroRage.nodamage or false
capturebiz.v = mainIni.CheatByYaroRage.capturebiz or false
damageinf.v = mainIni.CheatByYaroRage.damageinf or false
tfirst.v = mainIni.CheatByYaroRage.tfirst or false
tsecond.v = mainIni.CheatByYaroRage.tsecond or false
triggermode.v = mainIni.CheatByYaroRage.triggermode or 3
flipcar.v = mainIni.CheatByYaroRage.flipcar or false

-- Новые
flycar.v = mainIni.CheatByYaroRage.flycar or false
flycar_speed.v = mainIni.CheatByYaroRage.flycar_speed or 50.0
flycar_brake.v = mainIni.CheatByYaroRage.flycar_brake or 1.0
coordmaster.v = mainIni.CheatByYaroRage.coordmaster or false
coordmaster_step.v = mainIni.CheatByYaroRage.coordmaster_step or 5.0
coordmaster_delay.v = mainIni.CheatByYaroRage.coordmaster_delay or 20
coordmaster_height.v = mainIni.CheatByYaroRage.coordmaster_height or 120.0
autocapture.v = mainIni.CheatByYaroRage.autocapture or false
autocapture_time.v = mainIni.CheatByYaroRage.autocapture_time or "13:00:00"
autocapture_ms.v = mainIni.CheatByYaroRage.autocapture_ms or 0
anticrasher.v = mainIni.CheatByYaroRage.anticrasher or false
anti_detonator.v = mainIni.CheatByYaroRage.anti_detonator or false
anti_roll.v = mainIni.CheatByYaroRage.anti_roll or false
anti_trailer.v = mainIni.CheatByYaroRage.anti_trailer or false
anti_vortex.v = mainIni.CheatByYaroRage.anti_vortex or false

nametags_dist_slider.v = mainIni.CheatByYaroRage.nametags_dist or 8
tdtext_dist_slider.v = mainIni.CheatByYaroRage.tdtext_dist or 8
chatbubbles_dist_slider.v = mainIni.CheatByYaroRage.chatbubbles_dist or 6
fog_dist_slider.v = mainIni.CheatByYaroRage.fog_dist or 350
lods_dist_slider.v = mainIni.CheatByYaroRage.lods_dist or 150

admin_detection.v = mainIni.CheatByYaroRage.admin_detection or true
auto_spectator_check.v = mainIni.CheatByYaroRage.auto_spectator_check or false
show_admin_hud.v = mainIni.CheatByYaroRage.show_admin_hud or false

-- Справочник всех настраиваемых переменных для профилей (объявлен ДО save()).
local profile_vars = {
	godcar = godcar, NoAnimationMoney = NoAnimationMoney, clickwarp = clickwarp,
	sbivx = sbivx, SpeedHack = SpeedHack, SpeedSmooth = SpeedSmooth,
	fullskillgun = fullskillgun, pslide = pslide, trigger = trigger,
	autokick = autokick, airbrake = airbrake, Speed = Speed,
	ifastconnect = ifastconnect, enginecar = enginecar, noReload = noReload,
	allowBunnyhop = allowBunnyhop, eyefish = eyefish, antistun = antistun,
	shotmax = shotmax, Dist = Dist, silentmode = silentmode, Fov = Fov,
	legit = legit, cbz5 = cbz5, nodamage = nodamage, capturebiz = capturebiz,
	damageinf = damageinf, tfirst = tfirst, tsecond = tsecond,
	triggermode = triggermode, flipcar = flipcar,
	flycar = flycar, flycar_speed = flycar_speed, flycar_brake = flycar_brake,
	coordmaster = coordmaster, coordmaster_step = coordmaster_step,
	coordmaster_delay = coordmaster_delay, coordmaster_height = coordmaster_height,
	autocapture = autocapture, autocapture_time = autocapture_time,
	autocapture_ms = autocapture_ms,
	anticrasher = anticrasher, anti_detonator = anti_detonator,
	anti_roll = anti_roll, anti_trailer = anti_trailer, anti_vortex = anti_vortex,
	nametags_dist = nametags_dist_slider, tdtext_dist = tdtext_dist_slider,
	chatbubbles_dist = chatbubbles_dist_slider, fog_dist = fog_dist_slider,
	lods_dist = lods_dist_slider,
	admin_detection = admin_detection, auto_spectator_check = auto_spectator_check,
	show_admin_hud = show_admin_hud,
}

ffi.cdef[[
    typedef struct _SYSTEMTIME {
        uint16_t wYear;
        uint16_t wMonth;
        uint16_t wDayOfWeek;
        uint16_t wDay;
        uint16_t wHour;
        uint16_t wMinute;
        uint16_t wSecond;
        uint16_t wMilliseconds;
    } SYSTEMTIME;

    void __stdcall GetLocalTime(SYSTEMTIME*);
]]
local active = false
local hour, minute, second, ms

local fog_dist = ffi.cast('float *', 0x00B7C4F0)
local lods_dist = ffi.cast('float *', 0x00858FD8)

local showmenu = 1
local favskin = 0

local FAKE = {
    name = '',
    id = -1,
}

local MOP = false
local pow = 0.7
local poww = 1.9

function ev.onSendCommand(text)
    if text:match('/id (%d+)') then
        local playerId = text:match('/id (%d+)')
        if tonumber(playerId) == FAKE.id then
            sampAddChatMessage(FAKE.name..' {66CC66}id '..FAKE.id, -1)
            return false
        end
    end
end

function intToHex(int)
    local HEX = bit.tohex(int)
    return HEX
end

local ClanPlayer = 0
local start, cl = false, false
local socket = require('socket')

local f_ini = getGameDirectory().."\\moonloader\\config\\CheatByYaroRage\\settingstime.ini"
ini = {
    settings = {
        activate = false,
        x = 300,
        y = 300,
        color = "FFFFFF",
        msColor = "?3?3?3",
        fontsize = 12
    }
}
local config = inicfg.load(nil, f_ini)

--> Main
--> Инициализация и команды (вынесено из main, чтобы уложиться в лимит upvalues)
local function mainInit()

	ywelcome("CheatByYaroRage", "Меню: /cheat или N (долгое нажатие 1 сек)")

	clearAnim()
	lua_thread.create(ClickWP)
	lua_thread.create(SmoothAimBot)
	lua_thread.create(SmoothAimBott)

	save()
	mergeNewAdmins()

    last_spectator_check = 0  -- для авто-проверки слежки
	
    if config == nil then
        local f = io.open(f_ini, "w")
        if f then f:close() end
        if inicfg.save(ini, f_ini) then
            config = inicfg.load(nil, f_ini)
        end
    end

	imgui.Process = false

	set_dist(3, fog_dist_slider.v)
	set_dist(4, lods_dist_slider.v)

	nametags_server_settings = sampGetServerSettingsPtr() + 39
	nametags_allowed_dist = 250
	set_dist(0, nametags_dist_slider.v)

	sampRegisterChatCommand("cheat", function()
        mcheat.v = not mcheat.v
    end)
    
    sampRegisterChatCommand("fake", function()
        window.v = true
    end)

	sampRegisterChatCommand("rec", function(arg)
		if tonumber(arg) then
			lua_thread.create(function()
				if sampIsDialogActive() then
					sampCloseCurrentDialogWithButton(0)
				end

				printStringNow("Reconnect in ~r~"..arg.."  ~w~sec.", 1600)

				if sampGetGamestate() ~= GAMESTATE_RESTARTING then
					sampSetGamestate(GAMESTATE_DISCONNECTED)
					sampDisconnectWithReason(0)
				end

				wait(arg * 1000)
				sampSetGamestate(GAMESTATE_WAIT_CONNECT)
			end)
		else
			printStringNow("Wrong ~r~[~w~value~r~]", 1600)
		end
	end)

	sampRegisterChatCommand('ctime', cmd_stime)

	sampRegisterChatCommand('skin', function(arg)
		if #arg > 0 then
			local skinid = tonumber(arg)
			if skinid == 0 then
				favskin = 0
			else
				favskin = skinid
				_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
				set_player_skin(id, favskin)
			end
		end
	end)

	sampRegisterChatCommand('chelp', function()
		sampShowDialog(9999, "{FFFFFF}CheatByYaroRage by YaroRage.", '/cheat - Открыть/Закрыть меню\n/chelp - Показать это меню\n/fake - Открыть фейк чат\n/rec - Реконнект через N сек\n/ctime - Настройка времени на экране\n/skin - Установить скин\n/slp - Телепорт вверх\n/autorem - Авто /rem при входе в машину\n/wolic - WOLIC (проход сквозь стены)\n/pcol - Цвет игрока по ID\n/st /sw - Время/Погода\n/fakepl - Фейк игрок (id, имя, цвет, скин)\n/clan - Считать игроков в клане\n/fix - Починить машину\n/breakecar - Сломать машину\nAlt + 1 - Замок 1\nAlt + 2 - Замок 4\nN (1 сек) - Меню', "OK", "", 0)
	end)

	sampRegisterChatCommand('slp', function()
		local x, y, z = getCharCoordinates(PLAYER_PED)
		setCharCoordinates(PLAYER_PED, x , y , z + 1.5)
	end)

    sampRegisterChatCommand('sc', function(arg)
        if arg:match('%d+:%d+:%d+:%d+') then
            hour, minute, second, ms = arg:match('(%d+):(%d+):(%d+):(%d+)')
            hour, minute, second, ms = tonumber(hour), tonumber(minute), tonumber(second), tonumber(ms)
            active = true
        else
            ywelcome("CheatByYaroRage", 'Формат: ЧЧ:ММ:СС:МС')
        end
    end)
    time = ffi.new('SYSTEMTIME')

	sampRegisterChatCommand('autorem', function()
		tfirst.v = not tfirst.v
		if tfirst.v then
			ywelcome("CheatByYaroRage", 'Autorem - ВКЛ.')
		else
			ywelcome("CheatByYaroRage", 'Autorem - ВЫКЛ.')
		end
		save()
	end)

	sampRegisterChatCommand("wolic", function()
		wolic = not wolic
		if wolic then
			ywelcome("CheatByYaroRage", 'WOLIC - ВКЛ.')
		else
			ywelcome("CheatByYaroRage", 'WOLIC - ВЫКЛ.')
		end
	end)

    sampRegisterChatCommand('pcol', function(arg)
        sampAddChatMessage(intToHex(sampGetPlayerColor(tonumber(arg))), sampGetPlayerColor(tonumber(arg)))
    end)

	sampRegisterChatCommand("st", cmdSetTime)
	sampRegisterChatCommand("sw", cmdSetWeather)

	sampRegisterChatCommand('fakepl', function(arg)
        local pattern = '(%d+), (.+), (%d+), (%d+)'
        if arg:find(pattern) then
            local playerId, newname, playercolor, skinId = arg:match(pattern)
            if sampIsPlayerConnected(tonumber(playerId)) then
                FAKE.id, FAKE.name = tonumber(playerId), newname
                sampSetPlayerName(tonumber(playerId), newname)
                sampSetPlayerSkin(tonumber(playerId), tonumber(skinId))
                sampSetPlayerColor(tonumber(playerId), getPlayerColor(tonumber(playercolor)))
            else
                sampAddChatMessage('Игрок с ID "'..tonumber(playerId)..'" не найден!', -1)
            end
        else
            sampAddChatMessage('Неверный формат! /fakepl id, имя, цвет, скин', -1)
        end
    end)

	sampRegisterChatCommand('clan', function(arg)
        local player = '(%d+)'
        if arg:find(player) then
			lua_thread.create(function()
				local maxplayers = sampGetMaxPlayerId(false)
				local PlayerColor = sampGetPlayerColor(arg)
				for i = 0, maxplayers do
					if sampGetPlayerColor(i) == PlayerColor then
						ClanPlayer = ClanPlayer + 1
					end
				end
				ywelcome("CheatByYaroRage", 'Игроков в клане - '..ClanPlayer)
				ClanPlayer = 0
			end)
		else
			ywelcome("CheatByYaroRage", 'Ошибка! Укажите ID игрока.')
		end
	end)

-- Команды /fix и /breakecar передаются на сервер как есть (серверные).
	lua_thread.create(function() 
        while true do
            wait(0)
            if pslide.v then
                if ignore then
                    setGameKeyState(6, 0)
                    setGameKeyState(17, 256)
                end
            end
        end
    end)

end

--> Главный цикл (вынесено из main, чтобы уложиться в лимит upvalues)
local function mainLoop()
	local n_press_time = 0

	while true do
		wait(0)

		-- Admin Detection обновление (каждые 2 сек, работает и без чекбокса детекции — для трекера онлайн)
		do
			local cur_time = os.clock()
			if not last_admin_check or cur_time - last_admin_check >= 2.0 then
				updateAdminList()
				if admin_detection.v then
					checkSpectators()
				end
				last_admin_check = cur_time
			end
		end

		-- Auto Spectator Check (каждые 5 сек)
		if auto_spectator_check.v then
			local cur_time = os.clock()
			if not last_spectator_check or cur_time - last_spectator_check >= 5.0 then
				checkSpectators()
				last_spectator_check = cur_time
			end
		end

		if pslide.v and isCharOnFoot(PLAYER_PED) and getCurrentCharWeapon(PLAYER_PED) == 24 and not sampIsChatInputActive() and not sampIsCursorActive() and not sampIsDialogActive() then
            if not aiming then
                setGameKeyState(6, 0)
            end
            if isKeyDown(vKeys.VK_RBUTTON) and not aiming then
                lua_thread.create(function() 
                    silent = true
                    wait(500)
                    silent = false
                end)
                ignore = true
                aiming = true
                wait(200)
                ignore = false
                wait(100)
                if not isKeyDown(vKeys.VK_RBUTTON) then
                    setGameKeyState(18, 256)
                end
            elseif not isKeyDown(vKeys.VK_RBUTTON) and aiming then
                aiming = false
            end
        end

		SmoothAimBott()

		if sampGetPlayerAnimationId(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) == 1537 and autokick.v then
            sync = true
        end

		if isKeyDown(VK_LMENU) and isKeyJustPressed(VK_1) and not sampIsChatInputActive() and not sampIsDialogActive()  then
			sampProcessChatInput('/lock 1')
		end

		if isKeyDown(VK_LMENU) and isKeyJustPressed(VK_2) and not sampIsChatInputActive() and not sampIsDialogActive()  then
			sampProcessChatInput('/lock 4')
		end

		if isKeyJustPressed(VK_N) and not sampIsChatInputActive() and not sampIsDialogActive() then
			if mcheat.v then
				mcheat.v = false
			else
				local press_start = os.clock()
				local opened = false
				while isKeyDown(VK_N) do
					if os.clock() - press_start >= 1.0 then
						mcheat.v = true
						opened = true
						break
					end
					wait(0)
				end
				if not opened and not mcheat.v then
					-- короткое нажатие - ничего не делаем
				end
			end
		end

		if isKeyJustPressed(VK_F12) and not sampIsChatInputActive() and not sampIsDialogActive()  then
			thisScript():reload()
		end

		if favskin ~= 0 then
			nowskinid = getCharModel(PLAYER_PED)
			if nowskinid ~= favskin then
				_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
				set_player_skin(id, favskin)
			end
		end

		if trigger.v and not isCharOnAnyBike(PLAYER_PED) and not isCharDead(PLAYER_PED) then
			local int = readMemory(0xB6F3B8, 4, 0)
			int = int + 0x79C
			local intS = readMemory(int, 4, 0)
			if intS > 0 then
				local lol = 0xB73458
				lol = lol + 34
				writeMemory(lol, 4, 255, 0)
				wait(100)
				local int = readMemory(0xB6F3B8, 4, 0)
				int = int + 0x79C
				writeMemory(int, 4, 0, 0)
			end
		end

		if godcar.v and isCharInAnyCar(PLAYER_PED) then
			setCarProofs(storeCarCharIsInNoSave(PLAYER_PED), true, true, true, true, true)
		end

		if flipcar.v and isCharInAnyCar(PLAYER_PED) then
			local timerKey = 192 -- VK_OEM_3 (key with ~ and |, often Ъ on Russian keyboards)
			if isKeyDown(timerKey) then
				n_press_time = n_press_time + 1
				if n_press_time >= 50 then -- 0.5 seconds (50 * 10ms)
					local veh = storeCarCharIsInNoSave(PLAYER_PED)
					setVehicleForwardSpeed(veh, 0)
					setCarProofs(veh, false, false, false, false, false)
					setVehicleModel(veh, getVehicleModel(veh)) -- reset to original model to flip
					n_press_time = 0
				end
			else
				n_press_time = 0
			end
		end

		if NoAnimationMoney.v then
			memory.setuint8(5701879, 184, true)
			memory.copy(5701883, memory.strptr("???   "), 6, true)
			memory.setuint8(5701891, 235, true)
		end

		if fullskillgun.v then
			for i = 70, 79 do
				registerIntStat(i, 1000)
			end
		else
			for i = 70, 79 do
				registerIntStat(i, 0)
			end
		end

		if time then
			setTimeOfDay(time, 0)
		end

		if active then
			ffi.C.GetLocalTime(time)
			if time.wMilliseconds >= ms and time.wSecond >= second and time.wMinute >= minute and time.wHour >= hour then
				for i = 1, 5 do
					sampSendChat('/capture_biz')
				end
				active = false
			end
		end

		if airbrake.v and isKeyJustPressed(VK_RSHIFT) and isKeyCheckAvailable() then
			airbreakz = not airbreakz
			local zx, cx, zv = getCharCoordinates(PLAYER_PED)
			airBrkCoords = {
				zx, cx, zv, 0, 0, getCharHeading(PLAYER_PED)
			}
		end

		if airbrake.v and airbreakz then
			if isCharInAnyCar(PLAYER_PED) then
				heading = getCarHeading(storeCarCharIsInNoSave(PLAYER_PED))
			else
				heading = getCharHeading(PLAYER_PED)
			end

			bb, bbbb, bbb = getActiveCameraCoordinates()
			vv, vvvv, vv = getActiveCameraPointAt()
			mmm = getHeadingFromVector2d(vv - bb, vvvv - bbbb)

			if isCharInAnyCar(PLAYER_PED) then
				difference = 0.79
			else
				difference = 1
			end

			setCharCoordinates(PLAYER_PED, airBrkCoords[1], airBrkCoords[2], airBrkCoords[3] - difference)

			if isKeyDown(VK_W) and not sampIsChatInputActive() then
				airBrkCoords[1] = airBrkCoords[1] + 0.5 * math.sin(-math.rad(mmm))
				airBrkCoords[2] = airBrkCoords[2] + 0.5 * math.cos(-math.rad(mmm))

				if not isCharInAnyCar(PLAYER_PED) then
					setCharHeading(PLAYER_PED, mmm)
				else
					setCarHeading(storeCarCharIsInNoSave(PLAYER_PED), mmm)
				end
			elseif isKeyDown(VK_S) and not sampIsChatInputActive() then
				airBrkCoords[1] = airBrkCoords[1] - 0.5 * math.sin(-math.rad(heading))
				airBrkCoords[2] = airBrkCoords[2] - 0.5 * math.cos(-math.rad(heading))
			end

			if isKeyDown(VK_A) and not sampIsChatInputActive() then
				airBrkCoords[1] = airBrkCoords[1] - 0.5 * math.sin(-math.rad(heading - 90))
				airBrkCoords[2] = airBrkCoords[2] - 0.5 * math.cos(-math.rad(heading - 90))
			elseif isKeyDown(VK_D) and not sampIsChatInputActive() then
				airBrkCoords[1] = airBrkCoords[1] - 0.5 * math.sin(-math.rad(heading + 90))
				airBrkCoords[2] = airBrkCoords[2] - 0.5 * math.cos(-math.rad(heading + 90))
			end

			if isKeyDown(VK_UP) and not sampIsChatInputActive() then
				airBrkCoords[3] = airBrkCoords[3] + 0.5 / 2
			end

			if isKeyDown(VK_DOWN) and not sampIsChatInputActive() and airBrkCoords[3] > -95 then
				airBrkCoords[3] = airBrkCoords[3] - 0.5 / 2
			end

			if isKeyDown(VK_SPACE) and not sampIsChatInputActive() then
				airBrkCoords[3] = airBrkCoords[3] + 0.5 / 2
			end

			if isKeyDown(VK_LSHIFT) and not sampIsChatInputActive() and airBrkCoords[3] > -95 then
				airBrkCoords[3] = airBrkCoords[3] - 0.5 / 2
			end
		end

		if enginecar.v then
			if isCharInAnyCar(PLAYER_PED) then
				vcar = storeCarCharIsInNoSave(PLAYER_PED)
				switchCarEngine(vcar, true)
			end
		end

		if eyefish.v then
			local locked = false
			if isCurrentCharWeapon(PLAYER_PED, 34) and isKeyDown(2) then
				if not locked then
					cameraSetLerpFov(70.0, 70.0, 1000, 1)
					locked = true
				end
			else
				cameraSetLerpFov(101.0, 101.0, 1000, 1)
				locked = false
			end
		end

		if ifastconnect.v then
			writeMemory(sampGetBase() + 2964549, 2, 0, true)
		end

		if noReload.v then
			local weap = getCurrentCharWeapon(PLAYER_PED)
			local nbs = raknetNewBitStream()
			raknetBitStreamWriteInt32(nbs, weap)
			raknetBitStreamWriteInt32(nbs, 0)
			raknetEmulRpcReceiveBitStream(22, nbs)
			raknetDeleteBitStream(nbs)
		end

		if antistun.v and not isCharDead(PLAYER_PED) then
			local anim = {'DAM_armL_frmBK', 'DAM_armL_frmFT', 'DAM_armL_frmLT', 'DAM_armR_frmBK', 'DAM_armR_frmFT', 'DAM_armR_frmRT', 'DAM_LegL_frmBK', 'DAM_LegL_frmFT', 'DAM_LegL_frmLT', 'DAM_LegR_frmBK', 'DAM_LegR_frmFT', 'DAM_LegR_frmRT', 'DAM_stomach_frmBK', 'DAM_stomach_frmFT', 'DAM_stomach_frmLT', 'DAM_stomach_frmRT'}
			for k, v in pairs(anim) do
				if isCharPlayingAnim(PLAYER_PED, v) then
					setCharAnimSpeed(PLAYER_PED, v, 999)
				end
			end
		end

		if config and config.settings and (config.settings.activate or moving) then
			if moving then
				sampSetCursorMode(4)
				local x, y = getCursorPos()
				config.settings.x = x
				config.settings.y = y
				if isKeyJustPressed(0x01) then
					moving = false
					sampSetCursorMode(0)
					inicfg.save(config, f_ini)
				end
			end
			local date_table = os.date("*t")
			local ms = tostring(math.ceil(socket.gettime()*1000))
			local ms = tonumber(string.sub(ms, #ms-2, #ms))
			local hour, minute, second = date_table.hour, date_table.min, date_table.sec
			local result = string.format("%02d:%02d:%02d{" ..config.settings.msColor.. "}.%03d", hour, minute, second, ms)

			renderFontDrawText(font, result, config.settings.x, config.settings.y, "0xFF"..config.settings.color)
		end

		if SpeedHack.v then
			if isKeyDown(VK_MENU) and isCharInAnyCar(PLAYER_PED) then
				local veh = storeCarCharIsInNoSave(PLAYER_PED)
				local speed = getCarSpeed(veh)
				setCarForwardSpeed(veh, speed * 1.21)
			end
		end

		-- FlyCar
		if flycar.v and isCharInAnyCar(PLAYER_PED) then
			local veh = storeCarCharIsInNoSave(PLAYER_PED)
			if isKeyDown(VK_W) then
				setCarForwardSpeed(veh, getCarSpeed(veh) + flycar_speed.v * 0.1)
			end
			if isKeyDown(VK_S) then
				setCarForwardSpeed(veh, getCarSpeed(veh) - flycar_brake.v)
			end
			if isKeyDown(VK_SPACE) then
				local x, y, z = getCarCoordinates(veh)
				setCarCoordinates(veh, x, y, z + 0.5)
			end
			if isKeyDown(VK_LSHIFT) then
				local x, y, z = getCarCoordinates(veh)
				setCarCoordinates(veh, x, y, z - 0.5)
			end
			setCarCollision(veh, false)
		else
			if isCharInAnyCar(PLAYER_PED) then
				local veh = storeCarCharIsInNoSave(PLAYER_PED)
				setCarCollision(veh, true)
			end
		end

		-- CoordMaster (NTP teleport to marker)
		if coordmaster.v and isKeyJustPressed(VK_F5) then
			local blipX, blipY, blipZ = getTargetBlipCoordinates()
			if blipX and blipY then
				lua_thread.create(function()
					local px, py, pz = getCharCoordinates(PLAYER_PED)
					local dist = getDistanceBetweenCoords2d(px, py, blipX, blipY)
					local steps = math.ceil(dist / coordmaster_step.v)
					local angle = getHeadingFromVector2d(blipX - px, blipY - py)
					
					for i = 1, steps do
						if not coordmaster.v then break end
						local nx = px + coordmaster_step.v * math.sin(math.rad(angle))
						local ny = py + coordmaster_step.v * math.cos(math.rad(angle))
						setCharCoordinates(PLAYER_PED, nx, ny, coordmaster_height.v)
						px, py = nx, ny
						wait(coordmaster_delay.v)
					end
					setCharCoordinates(PLAYER_PED, blipX, blipY, blipZ)
					printStringNow(u8"~g~Телепорт завершен!", 2000)
				end)
			end
		end

		-- AutoCapture Biz
		if autocapture.v then
			local curTime = os.date("%H:%M:%S")
			local curMs = tonumber(string.format("%03d", math.floor(socket.gettime() * 1000) % 1000))
			if curTime == autocapture_time.v and curMs >= autocapture_ms.v then
				for i = 1, 5 do
					sampSendChat('/capture_biz')
				end
			end
		end

		-- Anti-Crashers
		if anticrasher.v then
			if anti_detonator.v then
				-- Handled in ev.onAimSync
			end
			if anti_roll.v then
				-- Handled in ev.onPlayerSync
			end
			if anti_trailer.v then
				-- Trailer crasher protection
			end
			if anti_vortex.v then
				-- Vortex crasher protection
			end
		end

		if mcheat.v then
			imgui.ShowCursor = true
			imgui.Process = true
			imgui.DisableInput = false
		elseif window.v then
			imgui.Process = true
			imgui.ShowCursor = true
			imgui.DisableInput = false
		elseif show_admin_hud.v and admin_detection.v then
			-- HUD рисуется через ImGui, поэтому держим кадры активными,
			-- но без курсора и без перехвата ввода
			imgui.Process = true
			imgui.ShowCursor = false
			imgui.DisableInput = true
		else
-- ImGui остаётся активным (для отрисовки HUD), но без курсора.
	-- Переключение ShowCursor/DisableInput выполняется в главном цикле.
	imgui.Process = true
	imgui.ShowCursor = false
	imgui.DisableInput = true
			imgui.ShowCursor = false
			imgui.DisableInput = false
		end
	end
end

--> Main
function main()
    repeat wait(0) until isSampAvailable()

	mainInit()
	mainLoop()
end

function cmd_stime()
    lua_thread.create(function()
        local dtext = u8"Время на экране\t" .. (config.settings.activate and "{45d900}ON\n" or "{ff0000}OFF\n")
        dtext = dtext .. u8"Размер шрифта:\t" .. config.settings.fontsize .. "\n"
        dtext = dtext .. u8"Цвет времени:\t{" .. config.settings.color .. "}||||||||||\n"
        dtext = dtext .. u8"Цвет миллисекунд:\t{" .. config.settings.msColor .. "}||||||||||\n"
        dtext = dtext .. u8"Перемещение окна"
        sampShowDialog(10, "{A77BCA}Time On Screen", dtext, "OK", "Отмена", DIALOG_STYLE_TABLIST)
        while sampIsDialogActive(10) do wait(0) end
        local result, button, list, input = sampHasDialogRespond(10)

        if result and button == 1 then
            if list == 0 then
                config.settings.activate = not config.settings.activate
                inicfg.save(config, f_ini)
                return true
            end

            if list == 1 then
                sampShowDialog(11, "{A77BCA}Time On Screen", u8"{FFFFFF}Введите размер шрифта:", "OK", "Отмена", DIALOG_STYLE_INPUT)
                while sampIsDialogActive(11) do wait(0) end
                local result, button, list, input = sampHasDialogRespond(11)
                if result then
                    if tonumber(input) then
                        config.settings.fontsize = tonumber(input)
                        font = renderCreateFont('Arial', config.settings.fontsize, 5)
                        inicfg.save(config, f_ini)
                        return true
                    else
                        ywelcome("CheatByYaroRage", "Неверный формат числа!")
                        return true
                    end
                else
                    return true
                end
            end

            if list == 2 then
                sampShowDialog(11, "{A77BCA}Time On Screen", u8"{FFFFFF}Введите цвет времени (HEX):\n{c3c3c3}Примеры: AE433D или A77BCA (или FFFFFF)", "OK", "Отмена", DIALOG_STYLE_INPUT)
                while sampIsDialogActive(11) do wait(0) end
                local result, button, list, input = sampHasDialogRespond(11)
                if result then
                    if not input:match("[^0-9A-Fa-f]+") then
                        config.settings.color = input
                        inicfg.save(config, f_ini)
                        return true
                    else
                        ywelcome("CheatByYaroRage", "Неверный формат цвета.")
                        return true
                    end
                else
                    return true
                end
            end

            if list == 3 then
                sampShowDialog(11, "{A77BCA}Time On Screen", u8"{FFFFFF}Введите цвет миллисекунд (HEX):\n{c3c3c3}Примеры: AE433D или A77BCA (или 858585)", "OK", "Отмена", DIALOG_STYLE_INPUT)
                while sampIsDialogActive(11) do wait(0) end
                local result, button, list, input = sampHasDialogRespond(11)
                if result then
                    if not input:match("[^0-9A-Fa-f]+") then
                        config.settings.msColor = input
                        inicfg.save(config, f_ini)
                        return true
                    else
                        ywelcome("CheatByYaroRage", "Неверный формат цвета.")
                        return true
                    end
                else
                    return true
                end
            end

            if list == 4 then
                moving = true
                ywelcome("CheatByYaroRage", "Переместите окно мышкой и нажмите ЛКМ.")
            end
        end
    end)
end

local camModes = {7, 8, 34, 45, 46, 51, 65}
function ev.onAimSync(playerId, data)
    for k, v in pairs(camModes) do
        if data.camMode == v then
            print("Player " .. playerId .. " use detonator crasher")
            return false
        end
    end
end

function onWindowMessage(msg, wparam, lparam)
	if msg == 261 and wparam == 13 then consumeWindowMessage(true, true) end
end

function ev.onPlayerSync(playerId, data)
	if data.weapon == 40 and data.keysData == 128 then
		print("Crasher "..playerId)
		emul_rpc('onPlayerStreamOut', { playerId })
		return false
	end
end

function get_dist(number)
	if number == 0 then
		return memory.getfloat(nametags_server_settings)
	end
	if number == 1 then
		return 20
	end
	if number == 2 then
		return 6
	end
	if number == 3 then
		return fog_dist[0]
	end
	if number == 4 then
		return lods_dist[0]
	end
end

function set_dist(number, value)
	value = tonumber(value)
	if number == 0 then
		if value > nametags_allowed_dist or value < 0 then
			return memory.setfloat(nametags_server_settings, nametags_allowed_dist)
		else
			return memory.setfloat(nametags_server_settings, value)
		end
	end
	if number == 1 then
		-- 3D Text distance - only update when slider changes, not every frame
		if mcheat.v then
			for i=0, 2048 do
				if sampIs3dTextDefined(i) then
					local text, col, posX, posY, posZ, dist, los, plid, vehid = sampGet3dTextInfoById(i)
					if dist ~= value then
						sampCreate3dTextEx(i, text, col, posX, posY, posZ, value, los, plid, vehid)
					end
				end
			end
		end
	end
	if number == 3 then
		if value > 3600.0 or value < 0 then return false end
		fog_dist[0] = value
	end
	if number == 4 then
		if value > 1000.0 or value < 0 then return false end
		lods_dist[0] = value
	end
end

function cmdSetTime(param)
	local hour = tonumber(param)
	if hour ~= nil and hour >= 0 and hour <= 23 then
	  time = hour
	  patch_samp_time_set(true)
	else
	  patch_samp_time_set(false)
	  time = nil
	end
end

function cmdSetWeather(param)
	local weather = tonumber(param)
	if weather ~= nil and weather >= 0 and weather <= 45 then
	  forceWeatherNow(weather)
	end
end

function patch_samp_time_set(enable)
	  if enable and default == nil then
		  default = readMemory(sampGetBase() + 0x9C0A0, 4, true)
		  writeMemory(sampGetBase() + 0x9C0A0, 4, 0x000008C2, true)
	  elseif enable == false and default ~= nil then
		  writeMemory(sampGetBase() + 0x9C0A0, 4, default, true)
		  default = nil
	 end
end

function isKeyCheckAvailable()
	return not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and not sampIsScoreboardOpen()
end

function ev.onSetPlayerPos(position)
	if wolic and position then
		return false
	end
end

function ev.onRemovePlayerFromVehicle()
	if wolic then
		return false
	end
end

--==================================[AimBot]=================================================

function fix(angle)
    if angle > math.pi then
        angle = angle - (math.pi * 2)
    elseif angle < -math.pi then
        angle = angle + (math.pi * 2)
    end
    return angle
end

function GetNearestPed(fov)
    local maxDistance = Dist.v
    local nearestPED = -1
    for i = 0, sampGetMaxPlayerId(true) do
        if sampIsPlayerConnected(i) then
            local find, handle = sampGetCharHandleBySampPlayerId(i)
            if find then
                if isCharOnScreen(handle) then
                    if not isCharDead(handle) then
                        local _, currentID = sampGetPlayerIdByCharHandle(PLAYER_PED)
                        local enPos = {GetBodyPartCoordinates(aiming, handle)}
                        local myPos = {getActiveCameraCoordinates()}
                        local vector = {myPos[1] - enPos[1], myPos[2] - enPos[2], myPos[3] - enPos[3]}
                        if isWidescreenOnInOptions() then coefficentZ = 0.0778 else coefficentZ = 0.103 end
                        local angle = {(math.atan2(vector[2], vector[1]) + 0.04253), (math.atan2((math.sqrt((math.pow(vector[1], 2) + math.pow(vector[2], 2)))), vector[3]) - math.pi / 2 - coefficentZ)}
                        local view = {fix(representIntAsFloat(readMemory(0xB6F258, 4, false))), fix(representIntAsFloat(readMemory(0xB6F248, 4, false)))}
                        local distance = math.sqrt((math.pow(angle[1] - view[1], 2) + math.pow(angle[2] - view[2], 2))) * 57.2957795131
                        if distance > fov then check = true else check = false end
                        if not check then
                            local myPos = {getCharCoordinates(PLAYER_PED)}
                            local distance = math.sqrt((math.pow((enPos[1] - myPos[1]), 2) + math.pow((enPos[2] - myPos[2]), 2) + math.pow((enPos[3] - myPos[3]), 2)))
                            if (distance < maxDistance) then
                                nearestPED = handle
                                maxDistance = distance
                            end
                        end
                    end
                end
            end
        end
    end
    return nearestPED
end

function SmoothAimBot()
    if cbz5.v and isKeyDown(VK_LBUTTON) then
        local handle = GetNearestPed(Fov.v)
        if handle ~= -1 then
            local myPos = {getActiveCameraCoordinates()}
            local enPos = {GetBodyPartCoordinates(aiming, handle)}
            local vector = {myPos[1] - enPos[1], myPos[2] - enPos[2], myPos[3] - enPos[3]}
            if isWidescreenOnInOptions() then coefficentZ = 0.0778 else coefficentZ = 0.103 end
            local angle = {(math.atan2(vector[2], vector[1]) + 0.04253), (math.atan2((math.sqrt((math.pow(vector[1], 2) + math.pow(vector[2], 2)))), vector[3]) - math.pi / 2 - coefficentZ)}
            local view = {fix(representIntAsFloat(readMemory(0xB6F258, 4, false))), fix(representIntAsFloat(readMemory(0xB6F248, 4, false)))}
            local difference = {angle[1] - view[1], angle[2] - view[2]}
            local smooth = {difference[1] / Speed.v, difference[2] / Speed.v}
            setCameraPositionUnfixed((view[2] + smooth[2]), (view[1] + smooth[1]))
        end
    end
    return false
end

function ev.onCreate3DText(id, col, pos, allowed_dist, los, plid, vehid, text)
	local custom_dist = tdtext_dist_slider.v or 8
	if custom_dist < allowed_dist then
		return {id, col, pos, custom_dist, los, plid, vehid, text}
	end
end

function ev.onPlayerChatBubble(id, col, allowed_dist, dur, text)
	local custom_dist = chatbubbles_dist_slider.v or 6
	if custom_dist < allowed_dist then
		return {id, col, custom_dist, dur, text}
	end
end

function set_player_skin(id, skin)
	local BS = raknetNewBitStream()
	raknetBitStreamWriteInt32(BS, id)
	raknetBitStreamWriteInt32(BS, skin)
	raknetEmulRpcReceiveBitStream(153, BS)
	raknetDeleteBitStream(BS)
end

-- Конвертация цвета игрока SAMP (0xRRGGBBAA) в ARGB (0xAARRGGBB) для отрисовки движком
function sampColorToArgb(col)
    local a = bit.band(col, 0xFF)
    local r = bit.band(bit.rshift(col, 24), 0xFF)
    local g = bit.band(bit.rshift(col, 16), 0xFF)
    local b = bit.band(bit.rshift(col, 8), 0xFF)
    return join_argb(a, r, g, b)
end

function join_argb(a, r, g, b)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function explode_argb(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xFF)
    local r = bit.band(bit.rshift(argb, 16), 0xFF)
    local g = bit.band(bit.rshift(argb, 8), 0xFF)
    local b = bit.band(argb, 0xFF)
    return a, r, g, b
end

function ev.onSendGiveDamage(id, data, data1, data2, data3)
	if shotmax.v then
		if data1 == 25 then
			return {id, 48, data1, data2, data3}
		end
	end
	if nodamage.v then
		_, pID = sampGetPlayerIdByCharHandle(PLAYER_PED)
		clist = sampGetPlayerColor(pID)
		clistplayer = sampGetPlayerColor(id)
		if clistplayer == clist then
			return false
		end
	end
	if damageinf.v then
		lua_thread.create(function ()
			_, ch = sampGetCharHandleBySampPlayerId(id)
			local nick = sampGetPlayerNickname(id)
			local _, playerid = sampGetPlayerIdByCharHandle(ch)

			if data3 == 9 then ox, oy, oz = 0, 0, 0.73
			elseif data3 == 8 then ox, oy, oz = 0.1, 0, -0.5
			elseif data3 == 7 then ox, oy, oz = -0.15, 0, -0.5
			elseif data3 == 6 then ox, oy, oz = 0.25, 0, 0.25
			elseif data3 == 5 then ox, oy, oz = -0.27, 0, 0.25
			elseif data3 == 4 then ox, oy, oz = 0, 0, 0
			elseif data3 == 3 then ox, oy, oz = 0, 0, 0.4
			else ox, oy, oz = 0, 0, 0 end

			x, y, z = getOffsetFromCharInWorldCoords(ch, ox, oy, oz)
			printStringNow(u8'~g~ Урон по - '..nick..'['..playerid..'] ~y~[+] ~r~-'..math.floor(data)..'HP', 1500)
			sampCreate3dTextEx('1', math.floor(data), 0xFFFFFFFF, x, y, z, 100, 1, -1, -1)
			wait(3000)
			sampDestroy3dText(1)
		end)
	end
end

function ev.onSendTakeDamage(id, data, data1, data2, data3)
	if damageinf.v and getCharHealth(PLAYER_PED) >= 1 then
		_, ch = sampGetCharHandleBySampPlayerId(id)
		local nick = sampGetPlayerNickname(id)
		local _, playerid = sampGetPlayerIdByCharHandle(PLAYER_PED)
		printStringNow(u8'~g~ Урон от - '..nick..'['..playerid..'] ~y~[-] ~r~-'..math.floor(data)..'HP', 1500)
	end
end

function getPlayerColor(playerId)
    local col = sampGetPlayerColor(playerId)
    local a, r, g, b = explode_argb(col)
    return join_argb(r, g, b, a)
end

function sampSetPlayerColor(playerId, color)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, playerId)
    raknetBitStreamWriteInt32(bs, color)
    raknetEmulRpcReceiveBitStream(72, bs)
    raknetDeleteBitStream(bs)
end

function sampSetPlayerName(playerId, name)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, playerId)
    raknetBitStreamWriteInt8(bs, #name)
    raknetBitStreamWriteString(bs, name)
    raknetBitStreamWriteInt8(bs, 1)
    raknetEmulRpcReceiveBitStream(11, bs)
    raknetDeleteBitStream(bs)
end

function sampSetPlayerSkin(playerId, skinId)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt32(bs, playerId)
    raknetBitStreamWriteInt32(bs, skinId)
    raknetEmulRpcReceiveBitStream(153, bs)
    raknetDeleteBitStream(bs)
end

function ev.onSendEnterVehicle(vehId, pass)
	if tfirst.v then
		lua_thread.create(function()
			-- Случайная задержка 0.5-3 с: чтобы у нескольких читеров ремень не надевался одновременно
			wait(math.random(500, 3000))
			result, handle = sampGetCarHandleBySampVehicleId(vehId)
			if result then
				sampProcessChatInput('/rem')
			end
		end)
	end
end

-- ИНТЕРФЕЙС
local search_text = imgui.ImBuffer(256)
local theme_selector = imgui.ImInt(0)
local themes = {
    u8"Классическая",
    u8"Тёмная",
    u8"Красная",
    u8"Фиолетовая",
    u8"Зелёная"
}
local profile_selector = imgui.ImInt(0)
local profile_name = imgui.ImBuffer(256)

local menuTab = imgui.ImInt(1)

-- Восстановление выбранной темы, профиля и вкладки после перезагрузки скрипта
theme_selector.v = mainIni.CheatByYaroRage.theme or 0
profile_selector.v = mainIni.CheatByYaroRage.profile or 0
menuTab.v = mainIni.CheatByYaroRage.menuTab or 1

function imgui.OnDrawFrame()
	resX, resY = getScreenResolution()
	-- Авто-учёт DPI Windows: на больших мониторах (4K при 150-200%) GUI растягивается
	-- по высоте экрана, а при смене масштаба Windows (100/125/150/200%) пересчитывается.
	local baseScale = resY / 1080
	local dpiFactor = 1
	do
		-- SM_CYSCREEN = 1: логическая высота экрана (без DPI). Если она заметно больше
		-- высоты рендера — игра работает в окне/не на весь экран, добавляем DPI-множитель.
		local ok, sysH = pcall(function() return ffi.C.GetSystemMetrics(1) end)
		if ok and type(sysH) == "number" and sysH > 0 then
			local physH = sysH * dpiUi
			if physH > resY * 1.05 then dpiFactor = dpiUi end
		end
	end
	fsc = baseScale * dpiFactor
	imgui.GetIO().FontGlobalScale = fsc
	
	local winW, winH = math.min(800 * fsc, resX - 20), math.min(560 * fsc, resY - 40)
	
	if mcheat.v then
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - winW / 2, resY / 2 - winH / 2), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'CheatByYaroRage', mcheat, imgui.WindowFlags.NoCollapse)

		-- Вкладки в одну строку в шапке окна
		local tabs = {
			u8'Аимбот',
			u8'Машины',
			u8'Игрок',
			u8'Визуал',
			u8'Бизнес',
			u8'FlyCar',
			u8'CoordMaster',
			u8'AutoCapture',
			u8'Anti-Crasher',
			u8'Admin',
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
		
		-- Верхняя панель: профиль и тема
		imgui.Text(u8"Профиль:")
		imgui.SameLine()
		imgui.PushItemWidth(110 * fsc)
		if imgui.Combo(u8"##profile", profile_selector, profiles) then
			loadProfile(profiles[profile_selector.v + 1])
		end
		imgui.PopItemWidth()
		imgui.SameLine()
		if imgui.Button(u8"Сохранить", imgui.ImVec2(86 * fsc, 25 * fsc)) then
			saveProfile(profiles[profile_selector.v + 1])
		end
		imgui.SameLine()
		imgui.Text(u8"Тема:")
		imgui.SameLine()
		imgui.PushItemWidth(110 * fsc)
		if imgui.Combo(u8"##theme", theme_selector, themes) then
			applyTheme(theme_selector.v)
			save()
		end
		imgui.PopItemWidth()
		imgui.SameLine()
		imgui.Separator()

		-- Активная вкладка
		if menuTab.v == 1 then drawAimTab()
		elseif menuTab.v == 2 then drawVehicleTab()
		elseif menuTab.v == 3 then drawPlayerTab()
		elseif menuTab.v == 4 then drawVisualTab()
		elseif menuTab.v == 5 then drawBizTab()
		elseif menuTab.v == 6 then drawFlyTab()
		elseif menuTab.v == 7 then drawCoordTab()
		elseif menuTab.v == 8 then drawAutoCaptureTab()
		elseif menuTab.v == 9 then drawAntiCrasherTab()
		elseif menuTab.v == 10 then drawAdminTab()
		end
		
		imgui.End()
	end
	
	if window.v then
        local resX, resY = getScreenResolution()
        local fsc = imgui.GetIO().FontGlobalScale
        local sizeX, sizeY = 300 * fsc, 150 * fsc
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - sizeX / 2, resY / 2 - sizeY / 2), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.Always)
        imgui.Begin(u8'Fake Chat', window)
        imgui.PushItemWidth(255 * fsc)
        if imgui.InputText("##inp1", str) then
            for k, v in ipairs(messages) do
                if rlower(v[2]):find(rlower(u8:decode(str.v))) then
                    buffer = messages[k]
                end
            end
        end
        if buffer[2] and imgui.Button(u8(buffer[2])) then
            str.v = u8(buffer[2])
            fakeChatColor = buffer[1]
        end
        if imgui.Button(u8"Отправить") then
            sampAddChatMessage(u8:decode(str.v), fakeChatColor)
        end
        imgui.PopItemWidth()
        imgui.End()
    end
end

-- Вкладки меню (вынесены из imgui.OnDrawFrame для обхода лимита 60 upvalues)

function drawAimTab()
			-- ВКЛАДКА: АИМБОТ
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'Аимбот')
				imgui.BeginChild("##AimChild", imgui.ImVec2(0, 0), true)
				imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"Настройки AimBot")
				imgui.Separator()
				
				sbox(u8'Legit AimBot (LMB)', cbz5)
				imgui.TextDisabled(u8'Плавное наведение на ЛКМ')
				if imgui.SliderFloat(u8"Скорость##aim", Speed, 0.1, 50.0, '%.1f') then save() end
				if imgui.SliderFloat(u8"Дистанция##aim", Dist, 1.0, 200.0, '%.1f') then save() end
				if imgui.SliderFloat(u8"FOV##aim", Fov, 0.1, 30.0, '%.1f') then save() end
				
				imgui.NewLine()
				imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"Silent Aim")
				imgui.Separator()
				if imgui.Button(u8'LITE', silentmode, 1) then silentmode.v = 1; save() end
				imgui.SameLine()
				if imgui.Button(u8'RAGE', silentmode, 2) then silentmode.v = 2; save() end
				imgui.SameLine()
				if imgui.Button(u8'ВЫКЛ', silentmode, 3) then silentmode.v = 3; save() end
				
				imgui.NewLine()
				imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"TriggerBot")
				imgui.Separator()
				if imgui.Button(u8'Режим 1 (наведение)') then triggermode.v = 1; save() end
				imgui.SameLine()
				if imgui.Button(u8'Режим 2 (автострелба)') then triggermode.v = 2; save() end
				imgui.SameLine()
				if imgui.Button(u8'ВЫКЛ') then triggermode.v = 3; save() end
				
				imgui.NewLine()
				sbox(u8'NoSpread', nodamage)
				imgui.TextDisabled(u8'Убрать разброс пуль (требует перезахода)')
				sbox(u8'NoReload', noReload)
				imgui.TextDisabled(u8'Без перезарядки')
				sbox(u8'FastDeagle', pslide)
				imgui.TextDisabled(u8'Быстрая стрельба из Дигла (ПКМ)')
				
				imgui.EndChild()
			end
end

function drawVehicleTab()
			-- ВКЛАДКА: ТРАНСПОРТ
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'Транспорт')
				imgui.BeginChild("##VehChild", imgui.ImVec2(0, 0), true)
				
				sbox(u8'AirBrake', airbrake)
				imgui.TextDisabled(u8'Полет/ходьба в воздухе (RShift)')
				sbox(u8'FlipCar (Del)', flipcar)
				imgui.TextDisabled(u8'Переворот машины клавишей Del (удержание 0.5с)')
				sbox(u8'GM Car', godcar)
				imgui.TextDisabled(u8'Неуязвимая машина')
				sbox(u8'EngineCar', enginecar)
				imgui.TextDisabled(u8'Всегда заведенный двигатель')
				sbox(u8'SpeedHack (Alt)', SpeedHack)
				imgui.TextDisabled(u8'Ускорение машины на Alt')
				if imgui.SliderInt(u8'Смут##speed', SpeedSmooth, 1, 100) then save() end
				
				imgui.Separator()
				sbox(u8'Autorem', tfirst)
				imgui.TextDisabled(u8'Авто /rem при входе в машину (случайная задержка 0.5-3 с)')
				
				if imgui.Button(u8'FIX Машину', imgui.ImVec2(95 * fsc, 35 * fsc)) then sampProcessChatInput('/fix') end
				imgui.SameLine()
				if imgui.Button(u8'BREAK Машину', imgui.ImVec2(95 * fsc, 35 * fsc)) then sampProcessChatInput('/breakecar') end
				
				imgui.EndChild()
			end
end

function drawPlayerTab()
			-- ВКЛАДКА: ИГРОК
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'Игрок')
				imgui.BeginChild("##PlayerChild", imgui.ImVec2(0, 0), true)
				
				sbox(u8'FullSkillGun', fullskillgun)
				imgui.TextDisabled(u8'Максимальный скилл оружия')
				sbox(u8'AntiStun', antistun)
				imgui.TextDisabled(u8'Анти-стан от ударов')
				sbox(u8'AntiBunnyhop', allowBunnyhop)
				imgui.TextDisabled(u8'Разрешить баннихоп')
				sbox(u8'EyeFish', eyefish)
				imgui.TextDisabled(u8'Зум прицела (ПКМ на снайперке)')
				sbox(u8'FastConnect', ifastconnect)
				imgui.TextDisabled(u8'Быстрое подключение к серверу')
				sbox(u8'NoAnimationMoney', NoAnimationMoney)
				imgui.TextDisabled(u8'Без анимации отдачи денег')
				sbox(u8'ShotMax', shotmax)
				imgui.TextDisabled(u8'Максимальный урон (дробовик -> 48 урона)')
				sbox(u8'Damage Informer', damageinf)
				imgui.TextDisabled(u8'Показывать урон в 3D тексте')
				
				imgui.EndChild()
			end
end

function drawVisualTab()
			-- ВКЛАДКА: ВИЗУАЛЫ
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'Визуалы')
				imgui.BeginChild("##VisualChild", imgui.ImVec2(0, 0), true)
				
				imgui.TextColored(imgui.ImVec4(0.3, 1, 0.3, 1), u8"Дистанции отрисовки")
				imgui.Separator()
				imgui.PushItemWidth(120 * fsc)
				if imgui.SliderInt(u8'NickTags', nametags_dist_slider, 0, nametags_allowed_dist) then set_dist(0, nametags_dist_slider.v); save() end
				if imgui.SliderInt(u8'3D Text', tdtext_dist_slider, 0, 50) then set_dist(1, tdtext_dist_slider.v); save() end
				if imgui.SliderInt(u8'Chat Bubbles', chatbubbles_dist_slider, 0, 50) then set_dist(2, chatbubbles_dist_slider.v); save() end
				if imgui.SliderInt(u8'LODs', lods_dist_slider, 0, 2000) then set_dist(4, lods_dist_slider.v); save() end
				if imgui.SliderInt(u8'Fog', fog_dist_slider, 0, 5000) then set_dist(3, fog_dist_slider.v); save() end
				imgui.PopItemWidth()
				
				imgui.NewLine()
				sbox(u8'SbivX (B)', sbivx)
				imgui.TextDisabled(u8'Очистка анимаций (клавиша B)')
				
				imgui.EndChild()
			end
end

function drawBizTab()
			-- ВКЛАДКА: БИЗНЕС
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'Бизнес')
				imgui.BeginChild("##BizChild", imgui.ImVec2(0, 0), true)
				
				sbox(u8'AutoCapture Biz', capturebiz)
				imgui.TextDisabled(u8'Автозахват биза по таймеру')
				if imgui.Button(u8'Fake Chat', imgui.ImVec2(70 * fsc, 35 * fsc)) then sampProcessChatInput('/fake'); mcheat.v = false end
				
				imgui.EndChild()
			end
end

function drawFlyTab()
			-- ВКЛАДКА: FLYCAR
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'FlyCar')
				imgui.BeginChild("##FlyChild", imgui.ImVec2(0, 0), true)
				
				sbox(u8'FlyCar', flycar)
				imgui.TextDisabled(u8'Полет на машине (W/S/Space/LShift)')
				if imgui.SliderFloat(u8'Скорость полета', flycar_speed, 1.0, 200.0, '%.1f') then save() end
				if imgui.SliderFloat(u8'Торможение', flycar_brake, 0.1, 10.0, '%.1f') then save() end
				
				imgui.EndChild()
			end
end


function drawCoordTab()
			-- ВКЛАДКА: COORDMASTER
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'CoordMaster')
				imgui.BeginChild("##CoordChild", imgui.ImVec2(0, 0), true)
				
				sbox(u8'CoordMaster (F5)', coordmaster)
				imgui.TextDisabled(u8'Телепорт к маркеру на карте по F5')
				if imgui.SliderFloat(u8'Шаг', coordmaster_step, 1.0, 20.0, '%.1f') then save() end
				if imgui.SliderInt(u8'Задержка (мс)', coordmaster_delay, 10, 100) then save() end
				if imgui.SliderFloat(u8'Высота', coordmaster_height, 50.0, 500.0, '%.1f') then save() end
				
				imgui.EndChild()
			end
end

function drawAutoCaptureTab()
			-- ВКЛАДКА: AUTO CAPTURE
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'AutoCapture')
				imgui.BeginChild("##AutoCapChild", imgui.ImVec2(0, 0), true)
				
				sbox(u8'AutoCapture Biz', autocapture)
				imgui.TextDisabled(u8'Автозахват биза по точному времени')
				imgui.PushItemWidth(100 * fsc)
				if imgui.InputText(u8'Время##autocap', autocapture_time) then save() end
				imgui.TextDisabled(u8'Формат: ЧЧ:ММ:СС')
				if imgui.SliderInt(u8'Миллисекунды', autocapture_ms, 0, 999) then save() end
				imgui.PopItemWidth()
				
				imgui.EndChild()
			end
end

function drawAntiCrasherTab()
			-- ВКЛАДКА: ANTI-CRASHER
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'Anti-Crasher')
				imgui.BeginChild("##AntiCrashChild", imgui.ImVec2(0, 0), true)
				
				sbox(u8'Вкл. защиту', anticrasher)
				imgui.TextDisabled(u8'Глобальное включение анти-крашеров')
				if anticrasher.v then
					sbox(u8'Anti Detonator', anti_detonator)
					imgui.TextDisabled(u8'Защита от крашера детонатором')
					sbox(u8'Anti Roll', anti_roll)
					imgui.TextDisabled(u8'Защита от Roll крашера')
					sbox(u8'Anti Trailer', anti_trailer)
					imgui.TextDisabled(u8'Защита от трейлер крашера')
					sbox(u8'Anti Vortex', anti_vortex)
					imgui.TextDisabled(u8'Защита от вихря крашера')
				end
				
				imgui.EndChild()
			end
end

function drawAdminTab()
			-- ВКЛАДКА: ADMIN DETECTION (Radmir CRMP)
			do
			    imgui.TextColored(imgui.ImVec4(0.9, 0.9, 0.9, 1), u8'Admin Detection')
				imgui.BeginChild("##AdminDetectChild", imgui.ImVec2(0, 0), true)
				
if imgui.Checkbox(u8'Вкл. детекцию админов', admin_detection) then
					if admin_detection.v then
						loadAdminListFile()
						updateAdminList()
					end
					save()
				end
				imgui.TextDisabled(u8'Поиск по точному списку администраторов (список проверяется при включении)')
				sbox(u8'Авто-проверка слежки', auto_spectator_check)
				imgui.TextDisabled(u8'Автоматически проверять слежку каждые 5 сек')
				sbox(u8'Показать HUD админов', show_admin_hud)
				imgui.TextDisabled(u8'Отображать список админов на экране')
				
				imgui.Separator()
				imgui.TextColored(imgui.ImVec4(1, 0.5, 0.5, 1), u8"Найденные админы (должность | ник | дата назначения):")
				
				if next(admin_list) then
					for _, data in pairs(admin_list) do
						imgui.Text(string.format(u8"  %s | %s | %s", u8(data.reason or "-"), u8(data.nick), u8(data.date or "-")))
					end
				else
					imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), u8"  Админы не найдены")
				end

				if next(chat_detected_list) then
					imgui.Separator()
					imgui.TextColored(imgui.ImVec4(1, 0.7, 0.5, 1), u8"Выявленные по сообщениям сервера (не найденные среди игроков):")
					for nick, det in pairs(chat_detected_list) do
						imgui.Text(string.format(u8"  %s | %s | %s", u8(det.reason or "-"), u8(nick), u8(det.date or "-")))
					end
				end

				imgui.Separator()
				local online_cnt = 0
				for _ in pairs(known_online) do online_cnt = online_cnt + 1 end
				imgui.TextColored(imgui.ImVec4(1, 1, 0.5, 1), string.format(u8"Онлайн админов из списка: %d / %d", online_cnt, #known_admins))
				imgui.BeginChild("##AdminOnlineChild", imgui.ImVec2(0, 200 * fsc), true)
				for _, a in ipairs(known_admins) do
					if known_online[a.nick] then
						imgui.TextColored(imgui.ImVec4(0.4, 1, 0.4, 1), string.format(u8"[Он] %s | %s", u8(a.nick), u8(a.post or "-")))
					end
				end
				imgui.TextDisabled(u8"-- оффлайн --")
				for _, a in ipairs(known_admins) do
					if not known_online[a.nick] then
						imgui.TextDisabled(string.format(u8"  %s | %s", u8(a.nick), u8(a.post or "-")))
					end
				end
				imgui.EndChild()

				imgui.TextDisabled(u8"В базе админов: " .. #known_admins)
				if imgui.Button(u8"Пересобрать список с форума", imgui.ImVec2(220 * fsc, 25 * fsc)) then
					local ok = os.execute('start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\\Документы\\Default Project\\admin_parser\\admin_update.ps1"')
					if ok then
						sampAddChatMessage("Чит: обновление списка админов запущено, дождитесь завершения парсера.", -1)
					else
						sampAddChatMessage("Чит: не удалось запустить обновление списка админов.", -1)
					end
				end
				imgui.SameLine()
				if imgui.Button(u8"Перечитать список из файла", imgui.ImVec2(210 * fsc, 25 * fsc)) then
					loadAdminListFile()
					updateAdminList()
				end
				imgui.SameLine()
				if imgui.Button(u8"Проверить слежку", imgui.ImVec2(120 * fsc, 25 * fsc)) then
					checkSpectators()
				end
				
				imgui.Separator()
				imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"Потенциальные наблюдатели (спект/камера):")
				
				if #spectator_list > 0 then
					for _, data in ipairs(spectator_list) do
						imgui.Text(string.format(u8"  %s [%d] | %dm | %s", u8(data.nick), data.id, data.dist, data.time))
					end
				else
					imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), u8"  Никто не следит")
				end
				
				imgui.EndChild()
			end
end


-- ТЕМЫ ОФОРМЛЕНИЯ
function applyTheme(theme_id)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    
    if theme_id == 0 then -- Классическая
        colors[clr.WindowBg] = ImVec4(0.15, 0.18, 0.22, 1)
        colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1)
        colors[clr.FrameBg] = ImVec4(0.2, 0.25, 0.29, 1)
        colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
        colors[clr.TitleBgActive] = ImVec4(0.08, 0.1, 0.12, 1)
        colors[clr.CheckMark] = ImVec4(1.15, 0.28, 0.22, 1)
        colors[clr.SliderGrab] = ImVec4(1.15, 0.18, 0.22, 1)
        colors[clr.Button] = ImVec4(0.2, 0.25, 0.29, 1)
        colors[clr.ButtonHovered] = ImVec4(1.15, 0.18, 0.22, 1)
        colors[clr.ButtonActive] = ImVec4(1.15, 0.28, 0.22, 1)
        colors[clr.Header] = ImVec4(0.2, 0.25, 0.29, 0.55)
        colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.8)
        colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1)
    elseif theme_id == 1 then -- Тёмная
        colors[clr.WindowBg] = ImVec4(0.08, 0.08, 0.08, 1)
        colors[clr.ChildWindowBg] = ImVec4(0.1, 0.1, 0.1, 1)
        colors[clr.FrameBg] = ImVec4(0.15, 0.15, 0.15, 1)
        colors[clr.TitleBg] = ImVec4(0.04, 0.04, 0.04, 1)
        colors[clr.TitleBgActive] = ImVec4(0.06, 0.06, 0.06, 1)
        colors[clr.CheckMark] = ImVec4(0.8, 0.8, 0.8, 1)
        colors[clr.SliderGrab] = ImVec4(0.6, 0.6, 0.6, 1)
        colors[clr.Button] = ImVec4(0.2, 0.2, 0.2, 1)
        colors[clr.ButtonHovered] = ImVec4(0.3, 0.3, 0.3, 1)
        colors[clr.ButtonActive] = ImVec4(0.4, 0.4, 0.4, 1)
        colors[clr.Header] = ImVec4(0.15, 0.15, 0.15, 1)
        colors[clr.HeaderHovered] = ImVec4(0.25, 0.25, 0.25, 1)
        colors[clr.HeaderActive] = ImVec4(0.35, 0.35, 0.35, 1)
    elseif theme_id == 2 then -- Красная
        colors[clr.WindowBg] = ImVec4(0.15, 0.05, 0.05, 1)
        colors[clr.ChildWindowBg] = ImVec4(0.18, 0.08, 0.08, 1)
        colors[clr.FrameBg] = ImVec4(0.3, 0.1, 0.1, 1)
        colors[clr.TitleBg] = ImVec4(0.4, 0.05, 0.05, 1)
        colors[clr.TitleBgActive] = ImVec4(0.5, 0.1, 0.1, 1)
        colors[clr.CheckMark] = ImVec4(1, 0.3, 0.3, 1)
        colors[clr.SliderGrab] = ImVec4(1, 0.2, 0.2, 1)
        colors[clr.Button] = ImVec4(0.4, 0.1, 0.1, 1)
        colors[clr.ButtonHovered] = ImVec4(0.6, 0.15, 0.15, 1)
        colors[clr.ButtonActive] = ImVec4(0.8, 0.2, 0.2, 1)
        colors[clr.Header] = ImVec4(0.4, 0.1, 0.1, 0.55)
        colors[clr.HeaderHovered] = ImVec4(0.6, 0.15, 0.15, 0.8)
        colors[clr.HeaderActive] = ImVec4(0.8, 0.2, 0.2, 1)
    elseif theme_id == 3 then -- Фиолетовая
        colors[clr.WindowBg] = ImVec4(0.1, 0.05, 0.15, 1)
        colors[clr.ChildWindowBg] = ImVec4(0.12, 0.08, 0.18, 1)
        colors[clr.FrameBg] = ImVec4(0.2, 0.1, 0.3, 1)
        colors[clr.TitleBg] = ImVec4(0.3, 0.1, 0.4, 1)
        colors[clr.TitleBgActive] = ImVec4(0.4, 0.15, 0.5, 1)
        colors[clr.CheckMark] = ImVec4(0.8, 0.3, 1, 1)
        colors[clr.SliderGrab] = ImVec4(0.7, 0.2, 0.9, 1)
        colors[clr.Button] = ImVec4(0.25, 0.1, 0.35, 1)
        colors[clr.ButtonHovered] = ImVec4(0.4, 0.15, 0.55, 1)
        colors[clr.ButtonActive] = ImVec4(0.6, 0.2, 0.8, 1)
        colors[clr.Header] = ImVec4(0.3, 0.1, 0.4, 0.55)
        colors[clr.HeaderHovered] = ImVec4(0.5, 0.2, 0.6, 0.8)
        colors[clr.HeaderActive] = ImVec4(0.7, 0.3, 0.8, 1)
    elseif theme_id == 4 then -- Зелёная
        colors[clr.WindowBg] = ImVec4(0.05, 0.15, 0.05, 1)
        colors[clr.ChildWindowBg] = ImVec4(0.08, 0.18, 0.08, 1)
        colors[clr.FrameBg] = ImVec4(0.1, 0.3, 0.1, 1)
        colors[clr.TitleBg] = ImVec4(0.05, 0.4, 0.05, 1)
        colors[clr.TitleBgActive] = ImVec4(0.1, 0.5, 0.1, 1)
        colors[clr.CheckMark] = ImVec4(0.3, 1, 0.3, 1)
        colors[clr.SliderGrab] = ImVec4(0.2, 0.8, 0.2, 1)
        colors[clr.Button] = ImVec4(0.1, 0.4, 0.1, 1)
        colors[clr.ButtonHovered] = ImVec4(0.15, 0.6, 0.15, 1)
        colors[clr.ButtonActive] = ImVec4(0.2, 0.8, 0.2, 1)
        colors[clr.Header] = ImVec4(0.1, 0.4, 0.1, 0.55)
        colors[clr.HeaderHovered] = ImVec4(0.15, 0.6, 0.15, 0.8)
        colors[clr.HeaderActive] = ImVec4(0.2, 0.8, 0.2, 1)
    end
end

-- Центрирование текста.
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

--> AutoSave
function sbox(name, imguiname)
	if imgui.Checkbox(''..name, imguiname) then
		save()
	end
end

-- Применение стиля.
function apply_custom_style()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
	style.FramePadding = ImVec2(5, 5)
	style.WindowTitleAlign = ImVec2(0.5, 0.5)
	style.WindowPadding = ImVec2(8, 8)
	style.ChildWindowRounding = 9
	style.FrameRounding = 6

	colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1)
	colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1)
	colors[clr.WindowBg] = ImVec4(0.15, 0.18, 0.22, 1)
	colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1)
	colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border] = ImVec4(0.43, 0.43, 0.5, 0.5)
	colors[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
	colors[clr.FrameBg] = ImVec4(0.2, 0.25, 0.29, 1)
	colors[clr.FrameBgHovered] = ImVec4(0.12, 0.2, 0.28, 1)
	colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1)
	colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
	colors[clr.TitleBgCollapsed] = ImVec4(0, 0, 0, 0.51)
	colors[clr.TitleBgActive] = ImVec4(0.08, 0.1, 0.12, 1)
	colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1)
	colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
	colors[clr.ScrollbarGrab] = ImVec4(1.15, 0.28, 0.22, 1)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1)
	colors[clr.ComboBg] = ImVec4(0.2, 0.25, 0.29, 1)
	colors[clr.CheckMark] = ImVec4(1.15, 0.28, 0.22, 1)
	colors[clr.SliderGrab] = ImVec4(1.15, 0.18, 0.22, 1)
	colors[clr.SliderGrabActive] = ImVec4(1.15, 0.28, 0.22, 1)
	colors[clr.Button] = ImVec4(0.2, 0.25, 0.29, 1)
	colors[clr.ButtonHovered] = ImVec4(1.15, 0.18, 0.22, 1)
	colors[clr.ButtonActive] = ImVec4(1.15, 0.28, 0.22, 1)
	colors[clr.Header] = ImVec4(0.2, 0.25, 0.29, 0.55)
	colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.8)
	colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1)
	colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1)
	colors[clr.CloseButton] = ImVec4(0.4, 0.39, 0.38, 0.16)
	colors[clr.CloseButtonHovered] = ImVec4(0.4, 0.39, 0.38, 0.39)
	colors[clr.CloseButtonActive] = ImVec4(0.4, 0.39, 0.38, 1)
	colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1)
	colors[clr.PlotLinesHovered] = ImVec4(1, 0.43, 0.35, 1)
	colors[clr.PlotHistogram] = ImVec4(0.9, 0.7, 0, 1)
	colors[clr.PlotHistogramHovered] = ImVec4(1, 0.6, 0, 1)
	colors[clr.TextSelectedBg] = ImVec4(0.25, 1, 0, 0.43)
	colors[clr.ModalWindowDarkening] = ImVec4(0.8, 0.8, 0.8, 0.15)
end
apply_custom_style()

-------------------------------------------------------------

--> Functions
function clearAnim()
    lua_thread.create(function()
        while true do wait(0)
			if sbivx.v then
				if isKeyJustPressed(VK_B) and not sampIsCursorActive() then
					if not isCharInAnyCar(PLAYER_PED) then clearCharTasksImmediately(PLAYER_PED) setPlayerControl(playerHandle, 1) freezeCharPosition(PLAYER_PED, false) end
				end
			end
		end
	end)
end

local russian_characters = {
    [168] = '?', [184] = '?', [192] = '?', [193] = '?', [194] = '?', [195] = '?', [196] = '?', [197] = '?', [198] = '?', [199] = '?', [200] = '?', [201] = '?', [202] = '?', [203] = '?', [204] = '?', [205] = '?', [206] = '?', [207] = '?', [208] = '?', [209] = '?', [210] = '?', [211] = '?', [212] = '?', [213] = '?', [214] = '?', [215] = '?', [216] = '?', [217] = '?', [218] = '?', [219] = '?', [220] = '?', [221] = '?', [222] = '?', [223] = '?', [224] = '?', [225] = '?', [226] = '?', [227] = '?', [228] = '?', [229] = '?', [230] = '?', [231] = '?', [232] = '?', [233] = '?', [234] = '?', [235] = '?', [236] = '?', [237] = '?', [238] = '?', [239] = '?', [240] = '?', [241] = '?', [242] = '?', [243] = '?', [244] = '?', [245] = '?', [246] = '?', [247] = '?', [248] = '?', [249] = '?', [250] = '?', [251] = '?', [252] = '?', [253] = '?', [254] = '?', [255] = '?',
}

function rlower(s)
    s = tostring(s):lower()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:lower()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end

function find(s, p)
    return string.rlower(s):find(string.rlower(p))
end

-- Глобальные require для ClickWP
Matrix3X3 = require "matrix3x3"
Vector3D = require "vector3d"

function ClickWP()
	if not isSampfuncsLoaded() then return end

	initializeRender()

	while true do
		wait(1)
		while isPauseMenuActive() do
			if cursorEnabled then
				showCursor(false)
			end
			wait(100)
		end

		if triggermode.v ~= 3 then
			if triggermode.v == 1 then
				local _, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
				if _ and not isCharDead(ped) then
					local _, id = sampGetPlayerIdByCharHandle(ped)
					if _  and not sampIsPlayerPaused(id) then
						setGameKeyState(17, 255)
					end
				end
			elseif triggermode.v == 2 then
				if not isCharOnAnyBike(PLAYER_PED) and not isCharDead(PLAYER_PED) then
					local int = readMemory(0xB6F3B8, 4, 0)
					int = int + 0x79C
					local intS = readMemory(int, 4, 0)
					if intS > 0 then
						local _, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
						if _ and not isCharDead(ped) then
							local _, id = sampGetPlayerIdByCharHandle(ped)
						end

						local a = 0xB73458
						a = a + 34
						writeMemory(a, 4, 255, 0)
						wait(100)
						local int = readMemory(0xB6F3B8, 4, 0)
						int = int + 0x79C
						writeMemory(int, 4, 0, 0)
					end
				end
			end
		end

		if isKeyDown(VK_MBUTTON) and clickwarp.v then
			cursorEnabled = not cursorEnabled
			showCursor(cursorEnabled)

			while isKeyDown(VK_MBUTTON) do
				wait(80)
			end
		end
		if cursorEnabled and not mcheat.v and not window.v then
			local mode = sampGetCursorMode()
			if mode == 0 then
				showCursor(true)
			end
			local sx, sy = getCursorPos()
			local sw, sh = getScreenResolution()
			if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
				local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
				local camX, camY, camZ = getActiveCameraCoordinates()
				local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
				if result and colpoint.entity ~= 0 then
					local normal = colpoint.normal
					local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
					local zOffset = 300
					if normal[3] >= 0.5 then zOffset = 1 end
					local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3, true, true, false, true, false, false, false)
					if result then
						pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)
						local curX, curY, curZ  = getCharCoordinates(playerPed)
						local dist              = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
						local hoffs             = renderGetFontDrawHeight(font)
						sy = sy - 2
						sx = sx - 2
						renderFontDrawText(font, string.format("%0.2fm", dist), sx, sy - hoffs, 0xEEEEEEEE)
						local tpIntoCar = nil
						if colpoint.entityType == 2 then
							local car = getVehiclePointerHandle(colpoint.entity)
							if doesVehicleExist(car) and (not isCharInAnyCar(playerPed) or storeCarCharIsInNoSave(playerPed) ~= car) then
								displayVehicleName(sx, sy - hoffs * 2, getNameOfVehicleModel(getCarModel(car)))
								local color = 0xAAFFFFFF
								if isKeyDown(VK_RBUTTON) then
									tpIntoCar = car
									color = 0xFFFFFFFF
								end
								renderFontDrawText(font2, "????? ?????? ?????? ???? ??? ???? ???? ????? ? ??????.", sx, sy - hoffs * 3, color)
							end
						end
						createPointMarker(pos.x, pos.y, pos.z)
						if isKeyDown(VK_LBUTTON) and clickwarp.v then
							if tpIntoCar then
								if not jumpIntoCar(tpIntoCar) and clickwarp.v then
									teleportPlayer(pos.x, pos.y, pos.z)
								end
							else
								if isCharInAnyCar(playerPed) then
									local norm = Vector3D(colpoint.normal[1], colpoint.normal[2], 0)
									local norm2 = Vector3D(colpoint2.normal[1], colpoint2.normal[2], colpoint2.normal[3])
									rotateCarAroundUpAxis(storeCarCharIsInNoSave(playerPed), norm2)
									pos = pos - norm * 1.8
									pos.z = pos.z - 0.8
								end
								teleportPlayer(pos.x, pos.y, pos.z)
							end
							removePointMarker()
							while isKeyDown(keyApply) do wait(0) end
							showCursor(false)
						end
					end
				end
			end
		end
end
end

function initializeRender()
	-- font and font2 already created globally
end

function rotateCarAroundUpAxis(car, vec)
	local mat = Matrix3X3(getVehicleRotationMatrix(car))
	local rotAxis = Vector3D(mat.up:get())
	vec:normalize()
	rotAxis:normalize()
	local theta = math.acos(rotAxis:dotProduct(vec))
	if theta ~= 0 then
		rotAxis:crossProduct(vec)
		rotAxis:normalize()
		rotAxis:zeroNearZero()
		mat = mat:rotate(rotAxis, -theta)
	end
	setVehicleRotationMatrix(car, mat:get())
end

function readFloatArray(ptr, idx)
	return representIntAsFloat(readMemory(ptr + idx * 4, 4, false))
end

function writeFloatArray(ptr, idx, value)
	writeMemory(ptr + idx * 4, 4, representFloatAsInt(value), false)
end

function getVehicleRotationMatrix(car)
	local entityPtr = getCarPointer(car)
	if entityPtr ~= 0 then
		local mat = readMemory(entityPtr + 0x14, 4, false)
		if mat ~= 0 then
			local rx, ry, rz, fx, fy, fz, ux, uy, uz
			rx = readFloatArray(mat, 0)
			ry = readFloatArray(mat, 1)
			rz = readFloatArray(mat, 2)

			fx = readFloatArray(mat, 4)
			fy = readFloatArray(mat, 5)
			fz = readFloatArray(mat, 6)

			ux = readFloatArray(mat, 8)
			uy = readFloatArray(mat, 9)
			uz = readFloatArray(mat, 10)
			return rx, ry, rz, fx, fy, fz, ux, uy, uz
		end
	end
end

function ev.onServerMessage(color, text)
	lua_thread.create(function()
		if capturebiz.v and (text:find(u8'Бизнес захвачен:') or text:find(u8'(.+) захватил бизнес (.+)') or text:find(u8'Бизнес (.+) захвачен (.+) (.+)') or text:find(u8'(.+) захватил бизнес (.+)') or text:find(u8'Бизнес (.+) захвачен (.+)')) then
			for i = 1, 4 do
				sampSendChat('/capture_biz')
				for a = 1, 5 do
					setVirtualKeyDown(0x0D, true)
					wait(0)
					setVirtualKeyDown(0x0D, false)
				end
			end
		end

		-- Детект администраторов по системным сообщениям сервера
		if admin_detection.v then
			local probe = text
			local found = nil
			for k = 1, 2 do
				local nick = probe:match("Администратор%s+([A-Za-z0-9_]+)")
				if nick then
					found = nick
					break
				end
				local ok, decoded = pcall(function() return u8:decode(text) end)
				if not ok then break end
				probe = decoded
			end
			if found and not chat_admins[found] then
				chat_admins[found] = true
				updateAdminList()
				if findInKnownAdminList(found) then
					-- Известный админ: молча отмечаем, что писал в чат (без сообщений)
					chat_detected_list[found] = {reason = "Писал в чат", date = os.date("%d.%m.%Y %H:%M:%S")}
				else
					-- Новый админ: добавляем в списки и отдельный файл, начинаем следить
					saveNewAdmin(found, "Админ (по сообщению сервера)", os.date("%d.%m.%Y"))
					chat_detected_list[found] = {reason = "Админ (по сообщению сервера)", date = os.date("%d.%m.%Y")}
					sampAddChatMessage("Чит: админ " .. found .. " выявлен по сообщению сервера и добавлен в список", -1)
				end
			end
		end
	end)

	table.insert(messages, {bit.rshift(color, 8), text})
    return true
end

function setVehicleRotationMatrix(car, rx, ry, rz, fx, fy, fz, ux, uy, uz)
	local entityPtr = getCarPointer(car)
	if entityPtr ~= 0 then
		local mat = readMemory(entityPtr + 0x14, 4, false)
		if mat ~= 0 then
			writeFloatArray(mat, 0, rx)
			writeFloatArray(mat, 1, ry)
			writeFloatArray(mat, 2, rz)

			writeFloatArray(mat, 4, fx)
			writeFloatArray(mat, 5, fy)
			writeFloatArray(mat, 6, fz)

			writeFloatArray(mat, 8, ux)
			writeFloatArray(mat, 9, uy)
			writeFloatArray(mat, 10, uz)
		end
	end
end

function displayVehicleName(x, y, gxt)
	x, y = convertWindowScreenCoordsToGameScreenCoords(x, y)
	useRenderCommands(true)
	setTextWrapx(640.0)
	setTextProportional(true)
	setTextJustify(false)
	setTextScale(0.33, 0.8)
	setTextDropshadow(0, 0, 0, 0, 0)
	setTextColour(255, 255, 255, 230)
	setTextEdge(1, 0, 0, 0, 100)
	setTextFont(1)
	displayText(x, y, gxt)
end

function createPointMarker(x, y, z)
	pointMarker = createUser3dMarker(x, y, z + 0.3, 4)
end

function removePointMarker()
	if pointMarker then
		removeUser3dMarker(pointMarker)
		pointMarker = nil
	end
end

function ev.onSendPlayerSync(data)
	if sync then
        local data_sync = samp_create_sync_data('player')
        pedcord = { getCharCoordinates(PLAYER_PED) }
        sync = false

        data_sync.position = {0, 0, 0}
        data_sync.send()

        data_sync.position = {pedcord[1], pedcord[2], pedcord[3]}
        data_sync.send()
    end

	if bit.band(data.keysData, 40) == 40 and allowBunnyhop.v then
		data.keysData = bit.bxor(data.keysData, 32)
	end
end

function getCarFreeSeat(car)
	if doesCharExist(getDriverOfCar(car)) then
		local maxPassengers = getMaximumNumberOfPassengers(car)
		for i = 0, maxPassengers do
			if isCarPassengerSeatFree(car, i) then
				return i + 1
			end
		end
		return nil
	else
		return 0
	end
end
function jumpIntoCar(car)
	local seat = getCarFreeSeat(car)

	if not seat then return false end
	if seat == 0 then warpCharIntoCar(PLAYER_PED, car)
	else warpCharIntoCarAsPassenger(PLAYER_PED, car, seat - 1)
	end
	restoreCameraJumpcut()
	return true
end

function teleportPlayer(x, y, z)
	if isCharInAnyCar(PLAYER_PED) then
		setCharCoordinates(PLAYER_PED, x, y, z)
	end
	setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z)
end

function setCharCoordinatesDontResetAnim(char, x, y, z)
	if doesCharExist(char) then
		local ptr = getCharPointer(char)
		setEntityCoordinates(ptr, x, y, z)
	end
end

function onReceivePacket(id, bs)
    if id == 215 then
        raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt16(bs) == 2 then
            local a = raknetBitStreamReadInt32(bs)
            local e = {}
            for i = 1, raknetBitStreamReadInt8(bs) do
                local l = raknetBitStreamReadInt32(bs)
                table.insert(e, raknetBitStreamReadString(bs, l))
            end
            if table.getn(e) > 0 then
                local text = e[1]
                if text == 'Auth' then
                    -- login removed
                end
            end
        end
    end
end

function setEntityCoordinates(entityPtr, x, y, z)
	if entityPtr ~= 0 then
		local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
		if matrixPtr ~= 0 then
			local posPtr = matrixPtr + 0x30
			writeMemory(posPtr + 0, 4, representFloatAsInt(x), false)
			writeMemory(posPtr + 4, 4, representFloatAsInt(y), false)
			writeMemory(posPtr + 8, 4, representFloatAsInt(z), false)
		end
	end
end

function showCursor(toggle)
	if toggle then
		sampSetCursorMode(CMODE_LOCKCAM)
	else
		sampToggleCursor(false)
	end
	cursorEnabled = toggle
end

-- Очистка ресурсов скрипта.
function onScriptTerminate(script, quit)
	if script == thisScript() then
		imgui.Process = false
		imgui.ShowCursor = false
		imgui.DisableInput = false
		showCursor(false, false)
	end
end

-- СОХРАНЕНИЕ НАСТРОЕК В INI
function save()
    local data = {}
    for k, v in pairs(profile_vars) do
        data[k] = v.v
    end
    data.theme = theme_selector.v
    data.profile = profile_selector.v
    data.menuTab = menuTab.v
    inicfg.save({CheatByYaroRage = data}, 'CheatByYaroRage/CheatByYaroRage.ini')
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require "ffi"
    local sampfuncs = require "sampfuncs"
    local raknet = require "samp.raknet"

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {"PlayerSyncData", raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {"VehicleSyncData", raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {"PassengerSyncData", raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {"AimSyncData", raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {"TrailerSyncData", raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {"UnoccupiedSyncData", raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {"BulletSyncData", raknet.PACKET.BULLET_SYNC, nil},
        spectator = {"SpectatorSyncData", raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = "struct " .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast("uintptr_t", ffi.new(data_type .. "*", data)))
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

-- Silent Aim implementation
function ev.onSendBulletSync(data)
    if silentmode.v == 1 then -- LITE
        if cbz5.v and isKeyDown(VK_LBUTTON) then
            local ped = GetNearestPed(Fov.v)
            if ped ~= -1 then
                local _, id = sampGetPlayerIdByCharHandle(ped)
                if _ then
                    local x, y, z = getCharCoordinates(ped)
                    data.targetType = 1
                    data.targetId = id
                    data.target = {x = x, y = y, z = z}
                    sampSendGiveDamage(id, 46.2, 24, 3)
                end
            end
        end
    elseif silentmode.v == 2 then -- RAGE
        if isKeyDown(VK_LBUTTON) then
            local ped = GetNearestPed(Fov.v)
            if ped ~= -1 then
                local _, id = sampGetPlayerIdByCharHandle(ped)
                if _ then
                    local x, y, z = getCharCoordinates(ped)
                    data.targetType = 1
                    data.targetId = id
                    data.target = {x = x, y = y, z = z}
                    sampSendGiveDamage(id, 46.2, 24, 3)
                end
            end
        end
    end
end

function SmoothAimBott()
    local speed = 100
    local fov = 20
    if legit.v and isKeyDown(vKeys.VK_RBUTTON) and not select(1, getCharPlayerIsTargeting(PLAYER_HANDLE)) then
        local handle = GetNearestPed(fov)
        if handle ~= -1 then
            local myPos = {getActiveCameraCoordinates()}
            local enPos = {GetBodyPartCoordinates(3, handle)}
            local vector = {myPos[1] - enPos[1], myPos[2] - enPos[2], myPos[3] - enPos[3]}
            if isWidescreenOnInOptions() then coefficentZ = 0.0778 else coefficentZ = 0.103 end
            local angle = {(math.atan2(vector[2], vector[1]) + 0.04253), (math.atan2((math.sqrt((math.pow(vector[1], 2) + math.pow(vector[2], 2)))), vector[3]) - math.pi / 2 - coefficentZ)}
            local view = {fix(representIntAsFloat(readMemory(0xB6F258, 4, false))), fix(representIntAsFloat(readMemory(0xB6F248, 4, false)))}
            local difference = {angle[1] - view[1], angle[2] - view[2]}
            local smooth = {difference[1] / speed, difference[2] / speed}
            setCameraPositionUnfixed((view[2] + smooth[2]), (view[1] + smooth[1]))
        end
    end
    return false
end

-- Профили конфигов
function loadProfile(name)
    local profile_ini = inicfg.load({
        CheatByYaroRage = {}
    }, 'CheatByYaroRage/profiles/' .. name .. '.ini')
    if profile_ini and profile_ini.CheatByYaroRage then
        for k, v in pairs(profile_ini.CheatByYaroRage) do
            if profile_vars[k] then
                profile_vars[k].v = v
            end
        end
        save()
        ywelcome("CheatByYaroRage", "Профиль '" .. name .. "' загружен!")
    else
        ywelcome("CheatByYaroRage", "Профиль '" .. name .. "' не найден!")
    end
end

function saveProfile(name)
    local profile_data = {}
    for k, v in pairs(profile_vars) do
        profile_data[k] = v.v
    end
    inicfg.save({CheatByYaroRage = profile_data}, 'CheatByYaroRage/profiles/' .. name .. '.ini')
    ywelcome("CheatByYaroRage", "Профиль '" .. name .. "' сохранен!")
end


local originalOnDrawFrame = imgui.OnDrawFrame
imgui.OnDrawFrame = function()
    originalOnDrawFrame()
    -- Admin HUD (рисуется каждый кадр, пока включён)
    if show_admin_hud.v and admin_detection.v then
        renderAdminHUD()
    end
end

-- Admin HUD рендер
function renderAdminHUD()
    local resX, resY = getScreenResolution()
    local x, y = admin_hud_pos.x, admin_hud_pos.y
    local line_h = 16

    -- Счётчик админов (admin_list — разреженная таблица с ключами-идами, # неприменим)
    local admin_cnt = 0
    for _ in pairs(admin_list) do admin_cnt = admin_cnt + 1 end

    -- Фон
    renderDrawBox(x - 5, y - 5, 280, 30 + admin_cnt * line_h + #spectator_list * line_h, 0xCC000000)
    
    -- Заголовок
    renderFontDrawText(font, "[ADMIN DETECTION]", x, y, 0xFFFFFFFF)
    y = y + line_h + 2
    
    -- Админы
    if admin_cnt > 0 then
        renderFontDrawText(font, "АДМИНЫ:", x, y, 0xFFFF0000)
        y = y + line_h
        for id, data in pairs(admin_list) do
            local txt = string.format("  %s | %s | %s", data.reason or "-", data.nick, data.date or "-")
            renderFontDrawText(font, txt, x, y, sampColorToArgb(data.color or 0xFFFFFFFF))
            y = y + line_h
        end
else
        renderFontDrawText(font, "АДМИНЫ: нет", x, y, 0xFF888888)
        y = y + line_h
    end

    y = y + 5
    
    -- Наблюдатели
    if #spectator_list > 0 then
        renderFontDrawText(font, "НАБЛЮДАТЕЛИ:", x, y, 0xFFFF6600)
        y = y + line_h
        for _, data in ipairs(spectator_list) do
            local txt = string.format("  %s [%d] | %dm | %s", data.nick, data.id, data.dist, data.time)
            renderFontDrawText(font, txt, x, y, 0xFFFFFF00)
            y = y + line_h
        end
    end
end

-- Применение сохранённой темы сразу при загрузке (иначе окно полупрозрачное)
applyTheme(mainIni.CheatByYaroRage.theme or 0)
