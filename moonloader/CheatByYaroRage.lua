local password = '74108520'
--============================================================================================
script_name("UltraHack")
script_author("YaroRage")
script_version("1.0")
--==================================[Библиотеки]==============================================
require 'moonloader'
require "lib.sampfuncs"

local ywelcome         = require "ywelcome"
local dlstatus 		= require('moonloader').download_status
local fa 			= require 'fAwesome5'
local vKeys         = require('vKeys')
local ffi 			= require 'ffi'
local ev            = require("lib.samp.events")
local inicfg 		= require('inicfg')
local vector 		= require 'vector3d'
local memory 		= require 'memory'
local mem 			= require 'memory'
local imgui 		= require('imgui')
local encoding      = require("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local window = imgui.ImBool(false)
local str = imgui.ImBuffer(256)
local messages = {}
local color = -1
local buffer = {0, "test"}
local sync = false

local ignore = false
local aiming = false
local silent = false

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

local font = renderCreateFont("Arial", 8, 12)

function GetBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

--> Имгуи.

local mcheat = imgui.ImBool(false)
local autorem = false -- AutoRem

--> Конфиг.

local clickwarp = imgui.ImBool(false)
local sbivx = imgui.ImBool(false)
local SpeedHack = imgui.ImBool(false)
local SpeedSmooth = imgui.ImInt(15)
local fullskillgun = imgui.ImBool(false)
local trigger = imgui.ImBool(false)
local airbrake = imgui.ImBool(false)
local Speed = imgui.ImFloat(0)
local Dist = imgui.ImFloat(0)
local Fov = imgui.ImFloat(0)
local cbz5 = imgui.ImBool(false)
local nodamage = imgui.ImBool(false)
local autokick = imgui.ImBool(false)
local damageinf = imgui.ImBool(false)
local capturebiz = imgui.ImBool(false)
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

local nametags_dist_slider = imgui.ImInt(8)
local tdtext_dist_slider = imgui.ImInt(8)
local chatbubbles_dist_slider = imgui.ImInt(6)
local fog_dist_slider = imgui.ImInt(350)
local lods_dist_slider = imgui.ImInt(150)
local tfirst = imgui.ImBool(false)
local tsecond = imgui.ImBool(false)
local triggermode = imgui.ImInt(3)

local mainIni = inicfg.load({
    MultiCheat =
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
		Speed = 0.0,
		Dist = 0.0,
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
		Fov = 0.0,
		damageinf = false,
		nametags_dist = 8,
		tdtext_dist = 8,
		chatbubbles_dist = 6,
		fog_dist = 350,
		lods_dist = 150
    }
}, 'MultiCheat_YaroRage/MultiCheat.ini')

godcar.v = mainIni.MultiCheat.godcar or false
NoAnimationMoney.v = mainIni.MultiCheat.NoAnimationMoney or false
clickwarp.v = mainIni.MultiCheat.clickwarp or false
sbivx.v = mainIni.MultiCheat.sbivx or false
SpeedHack.v = mainIni.MultiCheat.SpeedHack or false
SpeedSmooth.v = mainIni.MultiCheat.SpeedSmooth or 15
fullskillgun.v = mainIni.MultiCheat.fullskillgun or false
pslide.v = mainIni.MultiCheat.pslide or false
trigger.v = mainIni.MultiCheat.trigger or false
autokick.v = mainIni.MultiCheat.autokick or false
airbrake.v = mainIni.MultiCheat.airbrake or false
Speed.v = mainIni.MultiCheat.Speed or 0.0
ifastconnect.v = mainIni.MultiCheat.ifastconnect or false
enginecar.v = mainIni.MultiCheat.enginecar or false
noReload.v = mainIni.MultiCheat.noReload or false
allowBunnyhop.v = mainIni.MultiCheat.allowBunnyhop or false
eyefish.v = mainIni.MultiCheat.eyefish or false
antistun.v = mainIni.MultiCheat.antistun or false
shotmax.v = mainIni.MultiCheat.shotmax or false
Dist.v = mainIni.MultiCheat.Dist or 0.0
silentmode.v = mainIni.MultiCheat.silentmode or 3
Fov.v = mainIni.MultiCheat.Fov or 0.0
legit.v = mainIni.MultiCheat.legit or false
cbz5.v = mainIni.MultiCheat.cbz5 or false
nodamage.v = mainIni.MultiCheat.nodamage or false
capturebiz.v = mainIni.MultiCheat.capturebiz or false
damageinf.v = mainIni.MultiCheat.damageinf or false
tfirst.v = mainIni.MultiCheat.tfirst or false
tsecond.v = mainIni.MultiCheat.tsecond or false
triggermode.v = mainIni.MultiCheat.triggermode or 3

nametags_dist_slider.v = mainIni.MultiCheat.nametags_dist or 8
tdtext_dist_slider.v = mainIni.MultiCheat.tdtext_dist or 8
chatbubbles_dist_slider.v = mainIni.MultiCheat.chatbubbles_dist or 6
fog_dist_slider.v = mainIni.MultiCheat.fog_dist or 350
lods_dist_slider.v = mainIni.MultiCheat.lods_dist or 150

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

aiming = 3

local ClanPlayer = 0
local start, cl = false, false
local socket = require('socket')

local f_ini = getGameDirectory().."\\moonloader\\config\\MultiCheat_YaroRage\\settingstime.ini"
ini = {
    settings = {
        activate = false,
        x = 300,
        y = 300,
        color = "FFFFFF",
        msColor = "С3С3С3",
        fontsize = 12
    }
}
local config = inicfg.load(nil, f_ini)

--> Main
function main()
    repeat wait(0) until isSampAvailable()

	ywelcome("UltraHack", "Активация N (держите клавишу 1 секунду)")

	clearAnim()
	lua_thread.create(ClickWP)
	lua_thread.create(SmoothAimBot)
	lua_thread.create(SmoothAimBott)

	save()

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

	sampRegisterChatCommand("fake", function()
        window.v = true
    end)

	sampRegisterChatCommand("mrec", function(arg)
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

	sampRegisterChatCommand('mhelp', function()
		sampShowDialog(9999, "{FFFFFF}Команды мульти-чита by YaroRage.", '/mcheat - открыть меню мулти-чита\n/mhelp - открыть это меню\n/fake - фейк чатик для подделки скринов\n/rec - реконнект, перезайти в игру\n/ctime - время на экране в миллисекундах\n/skin - скинченжер(визуал)\n/slp - слапнуть самого себя\n/sc - каптилка по времени\n/autorem - включить/выключить автоматический ремень\n/wolic - езда без прав\n/pcol - пока не работает\n/st /sw - смена времени и погоды\n/fakepl - изменить ник, клист игроку (id, ник, id игрока у которого нужно взять цвет, id скина)\n/clan - кланчекер\n/fix - починить авто\n/breakecar - сломать авто или заспавнить его\nAlt + 1 - открыть личный авто\nAlt + 2 - открыть банды авто', "Я гей", "", 0)
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
            ywelcome("UltraHack", 'час:минута:секунда:милисекунда')
        end
    end)
    time = ffi.new('SYSTEMTIME')

	sampRegisterChatCommand('autorem', function()
		autorem = not autorem
		if autorem then
			ywelcome("UltraHack", 'Autorem - Включён.')
		else
			ywelcome("UltraHack", 'autorem - Выключен.')
		end
	end)

	sampRegisterChatCommand("wolic", function()
		wolic = not wolic
		if wolic then
			ywelcome("UltraHack", 'WOLIC - Включён.')
		else
			ywelcome("UltraHack", 'WOLIC - Выключен.')
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
                sampAddChatMessage('Игрок с айди "'..tonumber(playerId)..'" не найден!', -1)
            end
        else
            sampAddChatMessage('Команда введена неверно! /fakepl id, ник, id игрока у которого нужно взять цвет, id скина', -1)
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
				ywelcome("UltraHack", 'Игроков с указанным клистом - '..ClanPlayer)
				ClanPlayer = 0
			end)
		else
			ywelcome("UltraHack", 'Ошибка! Укажите ID игрока.')
		end
	end)

	sampRegisterChatCommand('fix', function(arg)
		if isCharInAnyCar(PLAYER_PED) then
			fX,fY,fZ = getCharCoordinates(PLAYER_PED)
			veh = storeCarCharIsInNoSave(PLAYER_PED)
			setCarCoordinates(veh, fX, fY, fZ)
			vehhp = arg and arg:match("(%d+)")
			lua_thread.create(function()
				if vehhp ~= nil then
					setCarHealth(veh, vehhp)
					setVirtualKeyDown(VK_RETURN, true)
					wait(20)
					setVirtualKeyDown(VK_RETURN, false)
				else
					setCarHealth(veh, 1000)
					setVirtualKeyDown(VK_RETURN, true)
					wait(20)
					setVirtualKeyDown(VK_RETURN, false)
				end
			end)
		end
	end)

	sampRegisterChatCommand('breakecar', function()
		if isCharInAnyCar(PLAYER_PED) then
			fX,fY,fZ = getCharCoordinates(PLAYER_PED)
			veh = storeCarCharIsInNoSave(PLAYER_PED)
			setCarCoordinates(veh, fX, fY, fZ)
			lua_thread.create(function()
				setCarHealth(veh, 100)
				setVirtualKeyDown(VK_RETURN, true)
				wait(20)
				setVirtualKeyDown(VK_RETURN, false)
			end)
		end
	end)

	sampRegisterChatCommand('mcheat', function()
		mcheat.v = not mcheat.v
	end)

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

	local n_press_time = 0

	while true do
		wait(0)

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
					-- Если удерживали меньше секунды, но меню было закрыто — можно оставить пустым или добавить другое действие
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

		if trigger.v and not isCharOnAnyBike(playerPed) and not isCharDead(playerPed) then
			local int = readMemory(0xB6F3B8, 4, 0)
			int=int + 0x79C
			local intS = readMemory(int, 4, 0)
			if intS > 0 then
				local lol = 0xB73458
				lol=lol + 34
				writeMemory(lol, 4, 255, 0)
				wait(100)
				local int = readMemory(0xB6F3B8, 4, 0)
				int=int + 0x79C
				writeMemory(int, 4, 0, 0)
			end
		end

		if godcar.v and isCharInAnyCar(PLAYER_PED) then
			setCarProofs(storeCarCharIsInNoSave(PLAYER_PED), true, true, true, true, true)
		end

		if NoAnimationMoney.v then
			mem.setuint8(5701879, 184, true)
			mem.copy(5701883, mem.strptr("‰–ј   "), 6, true)
			mem.setuint8(5701891, 235, true)
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

		if mcheat.v then
			imgui.ShowCursor = true
			imgui.Process = true
		elseif window.v then
			imgui.Process = true
			imgui.ShowCursor = true
		else
			imgui.Process = false
			imgui.ShowCursor = false
		end
	end
end

function cmd_stime()
    lua_thread.create(function()
        local dtext = "Отображать время на экране\t" .. (config.settings.activate and "{45d900}ON\n" or "{ff0000}OFF\n")
        local dtext = dtext .. "Размер шрифта:\t" .. config.settings.fontsize .. "\n"
        local dtext = dtext .. "Цвет времени:\t{" .. config.settings.color .. "}||||||||||\n"
        local dtext = dtext .. "Цвет миллисекунд:\t{" .. config.settings.msColor .. "}||||||||||\n"
        local dtext = dtext .. "Изменить положение"
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
                sampShowDialog(11, "{A77BCA}Time On Screen", "{FFFFFF}Введите новое значение шрифта:", "OK", "Отмена", DIALOG_STYLE_INPUT)
                while sampIsDialogActive(11) do wait(0) end
                local result, button, list, input = sampHasDialogRespond(11)
                if result then
                    if tonumber(input) then
                        config.settings.fontsize = tonumber(input)
                        font = renderCreateFont('Arial', config.settings.fontsize, 5)
                        inicfg.save(config, f_ini)
                        return true
                    else
                        ywelcome("UltraHack", "Значение должно быть числом!")
                        return true
                    end
                else
                    return true
                end
            end

            if list == 2 then
                sampShowDialog(11, "{A77BCA}Time On Screen", "{FFFFFF}Введите новое значение цвета:\n{c3c3c3}Например: AE433D или A77BCA (по умолчанию FFFFFF)", "OK", "Отмена", DIALOG_STYLE_INPUT)
                while sampIsDialogActive(11) do wait(0) end
                local result, button, list, input = sampHasDialogRespond(11)
                if result then
                    if not input:match("[а-яА-ЯЁё]+") then
                        config.settings.color = input
                        inicfg.save(config, f_ini)
                        return true
                    else
                        ywelcome("UltraHack", "Неправильный ввод.")
                        return true
                    end
                else
                    return true
                end
            end

            if list == 3 then
                sampShowDialog(11, "{A77BCA}Time On Screen", "{FFFFFF}Введите новое значение цвета:\n{c3c3c3}Например: AE433D или A77BCA (по умолчанию 858585)", "OK", "Отмена", DIALOG_STYLE_INPUT)
                while sampIsDialogActive(11) do wait(0) end
                local result, button, list, input = sampHasDialogRespond(11)
                if result then
                    if not input:match("[а-яА-ЯЁё]+") then
                        config.settings.msColor = input
                        inicfg.save(config, f_ini)
                        return true
                    else
                        ywelcome("UltraHack", "Неправильный ввод.")
                        return true
                    end
                else
                    return true
                end
            end

            if list == 4 then
                moving = true
                ywelcome("UltraHack", "Нажмите ЛКМ для сохранения положения.")
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
		if mcheat.v then
			for i=0, 2048 do
				if sampIs3dTextDefined(i) then
					local text, col, posX, posY, posZ, dist, los, plid, vehid = sampGet3dTextInfoById(i)
					sampCreate3dTextEx(i, text, col, posX, posY, posZ, value, los, plid, vehid)
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
		_, pID = sampGetPlayerIdByCharHandle(playerPed)
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
			printStringNow('~g~ Урон по - '..nick..'['..playerid..'] ~y~[+] ~r~-'..math.floor(data)..'HP', 1500)
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
		local _, playerid = sampGetPlayerIdByCharHandle(playerPed)
		printStringNow('~g~ Получен урон от - '..nick..'['..playerid..'] ~y~[-] ~r~-'..math.floor(data)..'HP', 1500)
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
	if autorem then
		lua_thread.create(function()
			result, handle = sampGetCarHandleBySampVehicleId(vehId)
			if result then
				wait(5000)
				sampProcessChatInput('/rem')
			end
		end)
	end
end

--> Имгуи
function imgui.OnDrawFrame()
	resX, resY = getScreenResolution()
	if mcheat.v then
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - 475 / 2, resY / 2 - 412 / 2), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowSize(imgui.ImVec2(475, 670), imgui.Cond.FirstUseEver)
		imgui.Begin('', mcheat, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar)

		imgui.BeginChild("##MainGroup", imgui.ImVec2(475, 670), true, imgui.WindowFlags.NoScrollbar)
			imgui.BeginGroup()
				sbox(u8'Авто кик при ноке', autokick)
				imgui.TextQuestion(u8'Будет кикать при ноке')
				sbox('ClickWarp', clickwarp)
				imgui.TextQuestion(u8'Активация на колёсико мышки.')
				imgui.NewLine()
				if imgui.RadioButton('Trigger 1', triggermode, 1) then
					triggermode.v = 1
					save()
				end
				imgui.SameLine()
				if imgui.RadioButton('Trigger 2', triggermode, 2) then
					triggermode.v = 2
					save()
				end
				if imgui.RadioButton(u8'Выключить Trigger', triggermode, 3) then
					triggermode.v = 3
					save()
				end
				imgui.NewLine()
				if imgui.RadioButton('Silent Aim LITE', silentmode, 1) then
					silentmode.v = 1
					save()
				end
				if imgui.RadioButton('Silent Aim RAGE', silentmode, 2) then
					silentmode.v = 2
					save()
				end
				if imgui.RadioButton(u8'Выключить Silent Aim', silentmode, 3) then
					silentmode.v = 3
					save()
				end
				imgui.NewLine()
				sbox(u8'Сбив на [B].', sbivx)
				imgui.TextQuestion(u8'Нажимая на кнопку [B] вы будете снимать фриз сервера и сбивать анимацию.')
				sbox(u8'FullSkillGun', fullskillgun)
				imgui.TextQuestion(u8'Клео скиллы.')
				sbox(u8'Полуслайд', pslide)
				imgui.TextQuestion(u8'Автоматический полуслайд при выстреле.')
				sbox(u8'AirBrake', airbrake)
				imgui.TextQuestion(u8'Аирбрейк.')
				sbox(u8'SpeedHack', SpeedHack)
				imgui.TextQuestion(u8'Ускорение на авто.')
				imgui.PushItemWidth(90)
				if imgui.SliderInt('Smooth', SpeedSmooth, 0, 80) then
					save()
				end
				sbox('NoDamage', nodamage)
				imgui.TextQuestion(u8'Урон не будет проходить.')
				sbox(u8'Каптур БЗ по таблу/payday', capturebiz)
				imgui.TextQuestion(u8'При появлении в чате надписи о завершении капта - флудит /capture_biz.')
				sbox(u8'Damage Informer', damageinf)
				imgui.TextQuestion(u8'Дамаг информер на экране.')
				sbox('LegitAimBot', cbz5)
				if imgui.SliderFloat("SpeedAim", Speed, 0.0, 50.0, '%.1f') then
					save()
				end
				if imgui.SliderFloat("DistAim", Dist, 0.0, 100.0, '%.1f') then
					save()
				end
				if imgui.SliderFloat("FovAim", Fov, 0.0, 100.0, '%.1f') then
					save()
				end
				sbox('LegitAimBot V2', legit)
			imgui.EndGroup()

			imgui.SameLine(230)

			imgui.BeginGroup()
				imgui.PushItemWidth(120)
				if imgui.SliderInt('NAMETAGS', nametags_dist_slider, 0, nametags_allowed_dist) then
					set_dist(0, nametags_dist_slider.v)
					save()
				end
				if imgui.SliderInt('3D TEXT', tdtext_dist_slider, 0, 30) then
					set_dist(1, tdtext_dist_slider.v)
					save()
				end
				if imgui.SliderInt('CHAT BUBBLES', chatbubbles_dist_slider, 0, 30) then
					set_dist(2, chatbubbles_dist_slider.v)
					save()
				end
				if imgui.SliderInt('LODS', lods_dist_slider, 0, 1000) then
					set_dist(4, lods_dist_slider.v)
					save()
				end
				sbox(u8'NoReload.', noReload)
				imgui.TextQuestion(u8'Стрельба без перезарядки.')
				sbox(u8'Ездить с выкл. двигателем.', enginecar)
				imgui.TextQuestion(u8'Езда без бензина.')
				sbox(u8"Увел. урон с дробовика.", shotmax)
				sbox(u8"Анти-Стан.", antistun)
				sbox(u8"AntiBunnyhop", allowBunnyhop)
				sbox(u8"Рыбий глаз.", eyefish)
				sbox("FastConnect", ifastconnect)
				sbox(u8'GMCar', godcar)
				sbox(u8'NoAnimationMoney', NoAnimationMoney)
				imgui.TextQuestion(u8'Деньги капают на счет без анимации (т.е. капают сразу).')
				if imgui.Button('FIX', imgui.ImVec2(70, 35)) then
					sampProcessChatInput('/fix')
				end
				imgui.SameLine()
				if imgui.Button('BREAK', imgui.ImVec2(70, 35)) then
					sampProcessChatInput('/breakecar')
				end
				imgui.SameLine()
				if imgui.Button('FAKE CHAT', imgui.ImVec2(70, 35)) then
					sampProcessChatInput('/fake')
					mcheat.v = false
				end
				imgui.EndGroup()
			imgui.EndChild()
		imgui.End()
	end

	if window.v then
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 300, 150
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - sizeX / 2, resY / 2 - sizeY / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.Begin('Fake', window)
        imgui.PushItemWidth(255)
        if imgui.InputText("##inp1", str) then
            for k, v in ipairs(messages) do
                if rlower(v[2]):find(rlower(u8:decode(str.v))) then
                    buffer = messages[k]
                end
            end
        end
        if imgui.Button(u8(buffer[2])) then
            str.v = u8(buffer[2])
            color = buffer[1]
        end
        if imgui.Button("Send") then
            sampAddChatMessage(u8:decode(str.v), color)
        end
        imgui.PopItemWidth()
        imgui.End()
    end
end

--> Подсказка
function imgui.TextQuestion(text)
	local war = (fa.ICON_FA_INFO_CIRCLE.. u8(' Подсказка:'))
	if imgui.IsItemHovered() then
		imgui.BeginTooltip()
		imgui.PushTextWrapPos(450)
		imgui.TextColored(imgui.ImVec4(1.15, 0.18, 0.22, 1), war)
		imgui.TextUnformatted(text)
		imgui.PopTextWrapPos()
		imgui.EndTooltip()
	end
end

--> Централизация текста.
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

--> Имгуи тема.
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
	colors[clr.WindowBg] = ImVec4(0.15, 0.18, 0.22, 0)
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
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
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

--> КликВарп.

function ClickWP()
	Matrix3X3 = require "matrix3x3"
	Vector3D = require "vector3d"

	if not isSampfuncsLoaded() then return end

	initializeRender()

	while true do
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
								renderFontDrawText(font2, "Зажми правую кнопку мыши для того чтоб сесть в машину.", sx, sy - hoffs * 3, color)
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
		wait(0)
		removePointMarker()
	end
end

function initializeRender()
	font = renderCreateFont("Tahoma", 10, FCR_BOLD + FCR_BORDER)
	font2 = renderCreateFont("Arial", 8, FCR_ITALICS + FCR_BORDER)
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
		if capturebiz.v and (text:find('Текущее время:') or text:find('(.+) захватили бизнес (.+)') or text:find('Попытка (.+) захватить бизнес (.+) провалилась') or text:find('(.+) захватили территорию (.+)') or text:find('Попытка (.+) захватить территорию (.+) провалилась')) then
			for i = 1, 4 do
				sampSendChat('/capture_biz')
				for a = 1, 5 do
					setVirtualKeyDown(0x0D, true)
					wait(0)
					setVirtualKeyDown(0x0D, false)
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
	if seat == 0 then warpCharIntoCar(playerPed, car)
	else warpCharIntoCarAsPassenger(playerPed, car, seat - 1)
	end
	restoreCameraJumpcut()
	return true
end

function teleportPlayer(x, y, z)
	if isCharInAnyCar(playerPed) then
		setCharCoordinates(playerPed, x, y, z)
	end
	setCharCoordinatesDontResetAnim(playerPed, x, y, z)
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
                    login()
                end
            end
        end
    end
end

function login()
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 215)
    raknetBitStreamWriteInt16(bs, 2)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt32(bs, 18)
    raknetBitStreamWriteString(bs, 'OnPlayerStartLogin')
    raknetBitStreamWriteInt32(bs, 2)
    raknetBitStreamWriteInt8(bs, 115)
    raknetBitStreamWriteInt16(bs, password:len())
    raknetBitStreamWriteInt16(bs, 0)
    raknetBitStreamWriteString(bs, password)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
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

--> Если скрипт крашнется.
function onScriptTerminate(script, quit)
	if script == thisScript() then
		imgui.Process = false
		imgui.ShowCursor = false
		showCursor(false, false)
	end
end

--> Быстрое сохранение в ini
function save()
    inicfg.save({
        MultiCheat =
        {
			clickwarp = clickwarp.v,
			sbivx = sbivx.v,
			SpeedHack = SpeedHack.v,
			SpeedSmooth = SpeedSmooth.v,
			fullskillgun = fullskillgun.v,
			trigger = trigger.v,
			airbrake = airbrake.v,
			triggermode = triggermode.v,
			tfirst = tfirst.v,
			tsecond = tsecond.v,
			Speed = Speed.v,
			silentmode = silentmode.v,
			pslide = pslide.v,
			legit = legit.v,
			cbz5 = cbz5.v,
			nodamage = nodamage.v,
			capturebiz = capturebiz.v,
			eyefish = eyefish.v,
			ifastconnect = ifastconnect.v,
			autokick = autokick.v,
			enginecar = enginecar.v,
			noReload = noReload.v,
			godcar = godcar.v,
			NoAnimationMoney = NoAnimationMoney.v,
			antistun = antistun.v,
			allowBunnyhop = allowBunnyhop.v,
			shotmax = shotmax.v,
			Dist = Dist.v,
			Fov = Fov.v,
			damageinf = damageinf.v,
			nametags_dist = nametags_dist_slider.v,
			tdtext_dist = tdtext_dist_slider.v,
			chatbubbles_dist = chatbubbles_dist_slider.v,
			fog_dist = fog_dist_slider.v,
			lods_dist = lods_dist_slider.v
        }
    }, 'MultiCheat_YaroRage/MultiCheat.ini')
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
                _, player_id = sampGetPlayerIdByCharHandle(playerPed)
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

function ev.onSendBulletSync(data)
    if pslide.v and silent then
        local ped = GetNearestPed(3)
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
        silent = false
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