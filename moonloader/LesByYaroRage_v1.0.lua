require "lib.moonloader"
require "lib.sampfuncs"

local sampEvents = require 'lib.samp.events'
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = "CP1251"
u8 = encoding.UTF8
local vkeys = require 'vkeys'
local gkeys = require 'game.keys'
local vector3d = require 'vector3d'
local memory = require 'memory'
local ffi = require 'ffi'
local json = require 'json'
ffi.cdef[[
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow(void);
    int IsIconic(void* hWnd);
    short GetAsyncKeyState(int vKey);
]]
local user32 = ffi.load("user32")

local function safeReadMemory(addr, size, signed)
    if not addr or addr < 0x10000 or addr > 0x7FFFFFFF then return nil end
    local ok, val = pcall(readMemory, addr, size, signed)
    if not ok then return nil end
    return val
end

local function safeReadFloat(addr)
    local raw = safeReadMemory(addr, 4, false)
    if not raw then return nil end
    local ok, val = pcall(representIntAsFloat, raw)
    if not ok then return nil end
    return val
end

local CONFIG_FILE = thisScript().directory .. "\\les_config.json"

local defaultConfig = {
    Wh = false,
    WhPlayers = false,
    HeadDot = false,
    ShowDistance = false,
    DistAnimals = 250.0,
    DistCars = 0.0,
    DistPlayers = 0.0,
    DistPickups = 0.0,
    LineAnimals = false,
    LineCars = false,
    LinePlayers = false,
    LineCorpses = false,
    EspTush = false,
    EspCars = false,
    EspPickups = false,
    Aim = false,
    AimPlayers = false,
    Aim_Smoothing = 5.0,
    Aim_FOV = 3.0,
    Aim_VisibleCheck = false,
    Aim_Humanize = false,
    Aim_Jitter = 0.0,
    Aim_RandomDelay = 0,
    Aim_OffsetX = 0.0,
    Aim_OffsetY = 0.0,
    AutoY = false,
    AutoY_Sleep = 600,
    AutoY_DownTime = 300,
    Clear = false,
    ClearFol = false,
    DbgObjs = false,
    Triggerbot = false,
    Triggerbot_Delay = 50,
    Triggerbot_FOV = 2.0,
    NoRecoil = false,
    NoSpread = false,
    Key_Menu = 0x4C,
    Key_AimToggle = 0x00,
    Key_EspToggle = 0x00,
}

local function loadConfig()
    local f = io.open(CONFIG_FILE, "r")
    if f then
        local content = f:read("*a")
        f:close()
        local ok, data = pcall(json.decode, content)
        if ok and data then return data end
    end
    return defaultConfig
end

local function saveConfig(cfg)
    local f = io.open(CONFIG_FILE, "w")
    if f then
        f:write(json.encode(cfg))
        f:close()
        return true
    end
    return false
end

local Ohota

local function applyConfig(cfg)
    Ohota.Wh.v = cfg.Wh or false
    Ohota.WhPlayers.v = cfg.WhPlayers or false
    Ohota.HeadDot.v = cfg.HeadDot or false
    Ohota.ShowDistance.v = cfg.ShowDistance or false
    Ohota.DistAnimals.v = cfg.DistAnimals or 250.0
    Ohota.DistCars.v = cfg.DistCars or 0.0
    Ohota.DistPlayers.v = cfg.DistPlayers or 0.0
    Ohota.DistPickups.v = cfg.DistPickups or 0.0
    Ohota.LineAnimals.v = cfg.LineAnimals or false
    Ohota.LineCars.v = cfg.LineCars or false
    Ohota.LinePlayers.v = cfg.LinePlayers or false
    Ohota.LineCorpses.v = cfg.LineCorpses or false
    Ohota.EspTush.v = cfg.EspTush or false
    Ohota.EspCars.v = cfg.EspCars or false
    Ohota.EspPickups.v = cfg.EspPickups or false
    Ohota.Aim.v = cfg.Aim or false
    Ohota.AimPlayers.v = cfg.AimPlayers or false
    Ohota.Aim_Smoothing.v = cfg.Aim_Smoothing or 5.0
    Ohota.Aim_FOV.v = cfg.Aim_FOV or 3.0
    Ohota.Aim_VisibleCheck.v = cfg.Aim_VisibleCheck or false
    Ohota.Aim_Humanize.v = cfg.Aim_Humanize or false
    Ohota.Aim_Jitter.v = cfg.Aim_Jitter or 0.0
    Ohota.Aim_RandomDelay.v = cfg.Aim_RandomDelay or 0
    Ohota.Aim_OffsetX.v = cfg.Aim_OffsetX or 0.0
    Ohota.Aim_OffsetY.v = cfg.Aim_OffsetY or 0.0
    Ohota.AutoY.v = cfg.AutoY or false
    Ohota.Clear.v = cfg.Clear or false
    Ohota.ClearFol.v = cfg.ClearFol or false
    Ohota.DbgObjs.v = cfg.DbgObjs or false
end

local function gatherConfig()
    return {
        Wh = Ohota.Wh.v,
        WhPlayers = Ohota.WhPlayers.v,
        HeadDot = Ohota.HeadDot.v,
        ShowDistance = Ohota.ShowDistance.v,
        DistAnimals = Ohota.DistAnimals.v,
        DistCars = Ohota.DistCars.v,
        DistPlayers = Ohota.DistPlayers.v,
        DistPickups = Ohota.DistPickups.v,
        LineAnimals = Ohota.LineAnimals.v,
        LineCars = Ohota.LineCars.v,
        LinePlayers = Ohota.LinePlayers.v,
        LineCorpses = Ohota.LineCorpses.v,
        EspTush = Ohota.EspTush.v,
        EspCars = Ohota.EspCars.v,
        EspPickups = Ohota.EspPickups.v,
        Aim = Ohota.Aim.v,
        AimPlayers = Ohota.AimPlayers.v,
        Aim_Smoothing = Ohota.Aim_Smoothing.v,
        Aim_FOV = Ohota.Aim_FOV.v,
        Aim_VisibleCheck = Ohota.Aim_VisibleCheck.v,
        Aim_Humanize = Ohota.Aim_Humanize.v,
        Aim_Jitter = Ohota.Aim_Jitter.v,
        Aim_RandomDelay = Ohota.Aim_RandomDelay.v,
        Aim_OffsetX = Ohota.Aim_OffsetX.v,
        Aim_OffsetY = Ohota.Aim_OffsetY.v,
        AutoY = Ohota.AutoY.v,
        AutoY_Sleep = waitWaitClickY.v,
        AutoY_DownTime = waitDownClickY.v,
        Clear = Ohota.Clear.v,
        ClearFol = Ohota.ClearFol.v,
        DbgObjs = Ohota.DbgObjs.v,
        Triggerbot = Ohota.Triggerbot.v,
        Triggerbot_Delay = Ohota.Triggerbot_Delay.v,
        Triggerbot_FOV = Ohota.Triggerbot_FOV.v,
        NoRecoil = Ohota.NoRecoil.v,
        NoSpread = Ohota.NoSpread.v,
        Key_Menu = defaultConfig.Key_Menu,
    }
end

local function game_has_focus()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    return hwnd ~= nil and user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd
end

imgui.GetIO().Fonts:Clear()
local _fontCands = {
    'C:\\Windows\\Fonts\\segoeui.ttf',
    'C:\\Windows\\Fonts\\arial.ttf',
    getFolderPath(0x14) .. '\\Arial.ttf',
}
local _fontLoaded = false
for _, _fp in ipairs(_fontCands) do
    local _ok = pcall(function()
        imgui.GetIO().Fonts:AddFontFromFileTTF(_fp, 16, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end)
    if _ok then _fontLoaded = true break end
end
if _fontLoaded then
    pcall(function() imgui.GetIO().Fonts:Build() end)
else
    imgui.GetIO().Fonts:AddFontDefault()
end

local ImVec2 = imgui.ImVec2
local ImVec4 = imgui.ImVec4
local ImGuiStyle = imgui.GetStyle()
local ImGuiColors = ImGuiStyle.Colors
local ImGuiClr = imgui.Col

local waitDownClickY = imgui.ImInt(300)
local waitWaitClickY = imgui.ImInt(600)

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
function GetBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

local dbgLog = thisScript().directory .. "\\les_dbg.txt"
local function dbg(msg)
    local fh = io.open(dbgLog, 'a')
    if fh then fh:write(os.date('%H:%M:%S') .. ' | ' .. msg .. '\n') fh:close() end
end

local AutoYLastSetFill = 0
local AutoYPresses = 0
local animalLastState = {}

local _dbgScanAt = 0
local _dbgScreen = {}
local _dbgObjs = {}
local _probeId = 613

local _sweepRun = false
local _sweepCursor = 1
local _sweepBandW = 5
local _sweepLast = 0
local _sweepTotal = 0
local _sweepMin = 1
local _sweepMax = 1024
local _sweepBudget = 500

local Clicker = {}
function Clicker:new(Button, Sleep, DownTime)
    local obj = {}
    obj.Button = Button
    obj.Sleep = Sleep or 600
    obj.DownTime = DownTime or 300
    obj.Allow = false
    obj.thread = nil
    obj.lastClick = 0
    obj.minInterval = 50

    function obj:Start()
        self.Allow = true
        self.thread = lua_thread.create(function()
            while self.Allow do
                if game_has_focus() then
                    local now = os.clock() * 1000
                    local keyState = user32.GetAsyncKeyState(self.Button)
                    if keyState >= 0 then
                        if now - self.lastClick >= self.minInterval then
                            setVirtualKeyDown(self.Button, true)
                            wait(self.DownTime)
                            setVirtualKeyDown(self.Button, false)
                            self.lastClick = now
                        end
                    end
                end
                wait(self.Sleep)
            end
            self.thread = nil
        end)
    end

    function obj:Stop()
        self.Allow = false
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end

local Menu = {
    windowState = imgui.ImBool(false);
}

local MODEL_DEER = 15555
local MODEL_BEAR = 15556

Ohota = {
    Wh = imgui.ImBool(false),
    WhPlayers = imgui.ImBool(false),
    HeadDot = imgui.ImBool(false),
    ShowDistance = imgui.ImBool(false),
    DistAnimals = imgui.ImFloat(250.0),
    DistCars = imgui.ImFloat(0.0),
    DistPlayers = imgui.ImFloat(0.0),
    DistPickups = imgui.ImFloat(0.0),
    LineAnimals = imgui.ImBool(false),
    LineCars = imgui.ImBool(false),
    LinePlayers = imgui.ImBool(false),
    LineCorpses = imgui.ImBool(false),
    EspTush = imgui.ImBool(false),
    EspCars = imgui.ImBool(false),
    EspPickups = imgui.ImBool(false),
    Aim = imgui.ImBool(false),
    AimPlayers = imgui.ImBool(false),
    Aim_silent = imgui.ImBool(false),
    AimHandle = nil,
    Aim_Smoothing = imgui.ImFloat(5.0),
    Aim_FOV = imgui.ImFloat(3.0),
    Aim_VisibleCheck = imgui.ImBool(false),
    Aim_Humanize = imgui.ImBool(false),
    Aim_Jitter = imgui.ImFloat(0.0),
    Aim_RandomDelay = imgui.ImInt(0),
    Aim_OffsetX = imgui.ImFloat(0.0),
    Aim_OffsetY = imgui.ImFloat(0.0),
    AutoY = imgui.ImBool(false),
    AutoY_Clicker = nil,
    Clear = imgui.ImBool(false),
    ClearFol = imgui.ImBool(false),
    DbgObjs = imgui.ImBool(false),
    Triggerbot = imgui.ImBool(false),
    Triggerbot_Delay = imgui.ImInt(50),
    Triggerbot_FOV = imgui.ImFloat(2.0),
    NoRecoil = imgui.ImBool(false),
    NoSpread = imgui.ImBool(false),
    FolApplied = false,
    FolBldTimer = 0,
    FolTimer = 0,
    FirstApplied = false,
    LastTargetHandle = nil,
    _aimLastShot = 0,
    _triggerbotTimer = 0,
}

Ohota.Wh.v = false
Ohota.WhPlayers.v = false
Ohota.HeadDot.v = false
Ohota.ShowDistance.v = false
Ohota.LineAnimals.v = false
Ohota.LineCars.v = false
Ohota.LinePlayers.v = false
Ohota.EspTush.v = false
Ohota.EspCars.v = false
Ohota.Aim.v = false
Ohota.AimPlayers.v = false
Ohota.AutoY.v = false
Ohota.Clear.v = false
Ohota.ClearFol.v = false
Ohota.DbgObjs.v = false
Ohota.FirstApplied = false

function imgui_Menu_windowState(arg)
    Menu.windowState.v = not Menu.windowState.v
    imgui.ShowCursor = Menu.windowState.v
    if Menu.windowState.v and not Ohota.FirstApplied then
        Ohota.FirstApplied = true
        Ohota.Wh.v = true
        Ohota.EspTush.v = true
        Ohota.HeadDot.v = true
        Ohota.ShowDistance.v = true
        Ohota.Aim.v = true
        Ohota.AutoY.v = true
        Ohota.Clear.v = true
    end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded then return end
    while not isSampAvailable() do wait(100) end

    local cfg = loadConfig()
    applyConfig(cfg)

    Ohota.AutoY_Clicker = Clicker:new(vkeys.VK_Y, cfg.AutoY_Sleep or 600, cfg.AutoY_DownTime or 300)

    sampRegisterChatCommand("les", imgui_Menu_windowState)
    sampRegisterChatCommand("lesr", function()
        thisScript():reload()
    end)

    local okY, yw = pcall(require, "ywelcome")
    if okY and type(yw) == "function" then
        yw("Les", u8"Охота от YaroRage. Управление: удерживайте L 1 сек, или /les")
    end

    local VK_L = 0x4C
    lua_thread.create(function()
        local prev_down = false
        local hold_start = 0
        local fired = false
        while true do
            wait(20)
            local down = (user32.GetAsyncKeyState(VK_L) < 0)
            local menuOpen = Menu.windowState.v

            if down and not prev_down then
                if menuOpen then
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                    fired = true
                    hold_start = 0
                else
                    hold_start = os.clock()
                    fired = false
                end
            elseif down and prev_down then
                if not menuOpen and not fired and hold_start > 0 and (os.clock() - hold_start) >= 0.5 then
                    fired = true
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                end
            else
                hold_start = 0
                fired = false
            end
            prev_down = down
        end
    end)

    local VK_F6 = 0x75
    local VK_F7 = 0x76
    local VK_F8 = 0x77
    local VK_F9 = 0x78
    lua_thread.create(function()
        local prev6, prev7, prev8, prev9 = false, false, false, false
        while true do
            wait(20)
            local d6 = (user32.GetAsyncKeyState(VK_F6) < 0)
            local d7 = (user32.GetAsyncKeyState(VK_F7) < 0)
            local d8 = (user32.GetAsyncKeyState(VK_F8) < 0)
            local d9 = (user32.GetAsyncKeyState(VK_F9) < 0)
            if Ohota.DbgObjs.v and game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                if d6 and not prev6 then _probeId = _probeId - 1; probeBuilding(_probeId) end
                if d7 and not prev7 then _probeId = _probeId + 1; probeBuilding(_probeId) end
                if d8 and not prev8 then
                    _sweepRun = not _sweepRun
                    if _sweepRun then
                        _sweepTotal = 0
                        if _sweepCursor < _sweepMin or _sweepCursor > _sweepMax then _sweepCursor = _sweepMin end
                    end
                end
                if d9 and not prev9 then
                    if _sweepBandW == 5 then _sweepBandW = 1
                    elseif _sweepBandW == 1 then _sweepBandW = 10
                    elseif _sweepBandW == 10 then _sweepBandW = 25
                    else _sweepBandW = 5 end
                end
            end
            if _sweepRun and Ohota.DbgObjs.v and (os.clock() - _sweepLast) >= 0.4 then
                _sweepLast = os.clock()
                _sweepTotal = _sweepTotal + 1
                if _sweepTotal > _sweepBudget then
                    _sweepRun = false; _sweepTotal = 0
                else
                    pcall(sweepOne, _sweepCursor)
                    _sweepCursor = _sweepCursor + 1
                    if _sweepCursor > _sweepMax then _sweepCursor = _sweepMin end
                end
            end
            prev6, prev7, prev8, prev9 = d6, d7, d8, d9
        end
    end)

    font_whGreen = renderCreateFont('Arial', 7, 13)
    font_dbg = renderCreateFont('Arial', 7, 13)

    imgui.Process = true
    imgui.ShowCursor = false

    if Ohota.ClearFol.v then pcall(applyFoliageClear) end

    while true do
        wait(0)

        local sw, sh = getScreenResolution()
        local playerX, playerY, playerZ = getCharCoordinates(playerPed)

        local animals = {}
        local players = {}
        local deadAnimals = {}
        local aimCandidates = {}

        for _, value in pairs(getAllChars()) do
            if doesCharExist(value) and value ~= PLAYER_PED and isCharOnScreen(value) then
                local modelid = getCharModel(value)
                local posX, posY, posZ = getCharCoordinates(value)
                local _X, _Y = convert3DCoordsToScreen(posX, posY, posZ)
                local dist = math.sqrt((posX - playerX)^2 + (posY - playerY)^2 + (posZ - playerZ)^2)
                local health = getCharHealth(value)
                local hx, hy, hz = GetBodyPartCoordinates(8, value)
                local hxx, hyy = convert3DCoordsToScreen(hx, hy, hz)

                local isAnimal = (modelid == MODEL_DEER or modelid == MODEL_BEAR)
                local isPlayer = false
                local resPid, pid = sampGetPlayerIdByCharHandle(value)
                if resPid then isPlayer = true end

                local okScreen = (_X ~= nil and _Y ~= nil and _X == _X and _Y == _Y
                                  and _X > -50 and _X < 8050 and _Y > -50 and _Y < 6050)
                local okHead = (hxx ~= nil and hyy ~= nil and hxx == hxx and hyy == hyy
                                and hxx > -50 and hxx < 8050 and hyy > -50 and hyy < 6050)

                if health > 0 then
                    if isAnimal then
                        table.insert(animals, {
                            handle = value, modelid = modelid, posX = posX, posY = posY, posZ = posZ,
                            screenX = _X, screenY = _Y, dist = dist, health = health,
                            headX = hxx, headY = hyy, okScreen = okScreen, okHead = okHead
                        })
                    elseif isPlayer then
                        table.insert(players, {
                            handle = value, modelid = modelid, posX = posX, posY = posY, posZ = posZ,
                            screenX = _X, screenY = _Y, dist = dist, health = health,
                            headX = hxx, headY = hyy, okScreen = okScreen, okHead = okHead,
                            pid = pid
                        })
                    end
                else
                    if isAnimal then
                        table.insert(deadAnimals, {
                            handle = value, modelid = modelid, posX = posX, posY = posY, posZ = posZ,
                            headX = hxx, headY = hyy, okHead = okHead
                        })
                    end
                end

                if (Ohota.Aim.v and isAnimal) or (Ohota.AimPlayers.v and isPlayer) then
                    table.insert(aimCandidates, {
                        handle = value, isAnimal = isAnimal, isPlayer = isPlayer,
                        posX = posX, posY = posY, posZ = posZ,
                        headX = hx, headY = hy, headZ = hz,
                        headScreenX = hxx, headScreenY = hyy,
                        screenX = _X, screenY = _Y, dist = dist,
                        okScreen = okScreen, okHead = okHead
                    })
                end
            end
        end

        if Ohota.EspTush.v and type(renderEspTush) == "function" then pcall(renderEspTush) end
        if Ohota.EspCars.v and type(renderEspCars) == "function" then pcall(renderEspCars) end
        if Ohota.WhPlayers.v and type(renderEspPlayers) == "function" then pcall(renderEspPlayers) end
        if Ohota.EspPickups.v and type(renderEspPickups) == "function" then pcall(renderEspPickups) end

        if Ohota.ClearFol.v then
            if not Ohota.FolApplied then
                Ohota.FolApplied = true
                Ohota.FolTimer = os.clock()
                Ohota.FolBldTimer = 0
                pcall(applyFoliageClear)
            elseif (os.clock() - (Ohota.FolTimer or 0)) > 2.0 then
                Ohota.FolTimer = os.clock()
                pcall(applyFoliageClear)
            end
            if (os.clock() - (Ohota.FolBldTimer or 0)) > 5.0 then
                Ohota.FolBldTimer = os.clock()
                pcall(sendRemoveBuildingRPCs)
            end
        else
            if Ohota.FolApplied or next(_folHidden) ~= nil then
                Ohota.FolApplied = false
                pcall(restoreFoliage)
            end
        end

        if Ohota.DbgObjs.v then
            if (os.clock() - _dbgScanAt) > 1.5 then
                _dbgScanAt = os.clock()
                dbg('--- Скан объектов ---')
                pcall(dbgObjectsScan)
            end
            pcall(dbgObjectsRender)
            renderFontDrawText(font_dbg, u8'Текущий ID: ' .. _probeId .. '  (F6 - / F7 +)', 12, 105, 0xFFFF66FF)
            if _sweepRun then
                local _bs = math.floor((_sweepCursor - 1) / _sweepBandW) * _sweepBandW + 1
                local _be = math.min(_bs + _sweepBandW - 1, _sweepMax)
                renderFontDrawText(font_dbg, string.format(u8'Скан: ID %d-%d (F8 старт, F9 шаг=%d) курсор=%d',
                    _bs, _be, _sweepBandW, _sweepCursor), 12, 118, 0xFF66FF00)
            else
                renderFontDrawText(font_dbg, string.format(u8'Скан остановлен (F8 запуск, шаг=%d, F9 смена)', _sweepBandW), 12, 118, 0xFF66FF00)
            end
            for _i, _line in ipairs(_dbgScreen) do
                renderFontDrawText(font_dbg, _line, 12 + ((_i - 1) % 2) * 330, 130 + math.floor((_i - 1) / 2) * 13, 0xFFFFFF00)
            end
        end

        local shouldRenderAimExtras = (doesCharExist(Ohota.AimHandle) and Ohota.AimHandle ~= nil)

        if Ohota.Wh.v or Ohota.LineAnimals.v or Ohota.WhPlayers.v or Ohota.LinePlayers.v or Ohota.HeadDot.v or Ohota.ShowDistance.v then
            for _, a in ipairs(animals) do
                if a.okScreen and (Ohota.DistAnimals.v <= 0 or a.dist <= Ohota.DistAnimals.v) then
                    if Ohota.Wh.v then
                        if a.modelid == MODEL_DEER then
                            if a.health == 100 then
                                renderFontDrawText(font_whGreen, u8'Олень(3)', a.screenX, a.screenY, 0xFF00FF00)
                            elseif a.health == 65 then
                                renderFontDrawText(font_whGreen, u8'Олень(2)', a.screenX, a.screenY, 0xFFFF9D00)
                            elseif a.health == 30 then
                                renderFontDrawText(font_whGreen, u8'Олень(1)', a.screenX, a.screenY, 0xFFFF0000)
                            end
                        elseif a.modelid == MODEL_BEAR then
                            if a.health == 100 then
                                renderFontDrawText(font_whGreen, u8'Медведь(7)', a.screenX, a.screenY, 0xFF00FF00)
                            elseif a.health == 85 then
                                renderFontDrawText(font_whGreen, u8'Медведь(6)', a.screenX, a.screenY, 0xFF55E100)
                            elseif a.health == 70 then
                                renderFontDrawText(font_whGreen, u8'Медведь(5)', a.screenX, a.screenY, 0xFFAAC300)
                            elseif a.health == 55 then
                                renderFontDrawText(font_whGreen, u8'Медведь(4)', a.screenX, a.screenY, 0xFFFFA500)
                            elseif a.health == 40 then
                                renderFontDrawText(font_whGreen, u8'Медведь(3)', a.screenX, a.screenY, 0xFFFF6E00)
                            elseif a.health == 25 then
                                renderFontDrawText(font_whGreen, u8'Медведь(2)', a.screenX, a.screenY, 0xFFFF3700)
                            elseif a.health == 10 then
                                renderFontDrawText(font_whGreen, u8'Медведь(1)', a.screenX, a.screenY, 0xFFFF0000)
                            end
                        end
                        if Ohota.LineAnimals.v and not shouldRenderAimExtras and a.okHead then
                            renderDrawLine(sw/2, sh/2, a.headX, a.headY, 1.0, 0xFFFFFF00)
                        end
                    end
                    if Ohota.HeadDot.v and a.okHead then
                        renderDrawBoxWithBorder(a.headX, a.headY, 3, 3, 0xFF00FF00, 1, 0xFF00FF00)
                    end
                    if Ohota.ShowDistance.v and Ohota.Wh.v then
                        renderFontDrawText(font_whGreen, string.format(u8"%.0f м", a.dist), a.screenX, a.screenY - 10, 0xFFFFFFFF)
                    end
                end
            end

            for _, p in ipairs(players) do
                if p.okScreen and (Ohota.DistPlayers.v <= 0 or p.dist <= Ohota.DistPlayers.v) then
                    if Ohota.WhPlayers.v then
                        renderFontDrawText(font_whGreen, u8"Игрок", p.screenX, p.screenY, 0xFF00CCFF)
                    end
                    if Ohota.LinePlayers.v and not shouldRenderAimExtras and p.okHead then
                        renderDrawLine(sw/2, sh/2, p.headX, p.headY, 1.0, 0xFF00CCFF)
                    end
                    if Ohota.HeadDot.v and p.okHead then
                        renderDrawBoxWithBorder(p.headX, p.headY, 3, 3, 0xFF00FF00, 1, 0xFF00FF00)
                    end
                    if Ohota.ShowDistance.v and Ohota.WhPlayers.v then
                        renderFontDrawText(font_whGreen, string.format(u8"%.0f м", p.dist), p.screenX, p.screenY - 10, 0xFFFFFFFF)
                    end
                end
            end
        end

        if Ohota.LineCorpses.v then
            for _, d in ipairs(deadAnimals) do
                if d.okHead then
                    renderDrawLine(sw/2, sh/2, d.headX, d.headY, 2.0, 0xFF0000FF)
                    local _cdist = math.sqrt((d.posX-playerX)^2 + (d.posY-playerY)^2 + (d.posZ-playerZ)^2)
                    renderFontDrawText(font_whGreen, string.format(u8"Труп %.0fм", _cdist), d.headX + 8, d.headY - 8, 0xFF0000FF)
                end
            end
        end

        if Ohota.Clear.v then
            for _, a in ipairs(animals) do
                local state = animalLastState[a.handle]
                local now = os.time()
                if not state then
                    animalLastState[a.handle] = {x = a.posX, y = a.posY, z = a.posZ, lastMoveTime = now}
                else
                    local moved = (math.abs(a.posX - state.x) > 0.01 or
                                   math.abs(a.posY - state.y) > 0.01 or
                                   math.abs(a.posZ - state.z) > 0.01)
                    if moved then
                        state.x = a.posX; state.y = a.posY; state.z = a.posZ
                        state.lastMoveTime = now
                    else
                        if now - state.lastMoveTime >= 20 then
                            deleteChar(a.handle)
                            animalLastState[a.handle] = nil
                        end
                    end
                end
            end
        end

        local camMode = safeReadMemory(0xB6F1A8, 1, false)
        local aiming = camMode and (camMode == 53 or camMode == 55 or camMode == 7 or camMode == 8)
        local isSpectator = camMode and (camMode == 46 or camMode == 47)
        local aimAnimals = Ohota.Aim.v and not isSpectator
        local aimPlayers = Ohota.AimPlayers.v and not isSpectator
        local smoothing = Ohota.Aim_Smoothing.v
        local aimFOV = Ohota.Aim_FOV.v
        local visibleCheck = Ohota.Aim_VisibleCheck.v
        local humanize = Ohota.Aim_Humanize.v
        local jitter = Ohota.Aim_Jitter.v
        local randomDelay = Ohota.Aim_RandomDelay.v
        local offsetX = Ohota.Aim_OffsetX.v
        local offsetY = Ohota.Aim_OffsetY.v

        if aiming and (aimAnimals or aimPlayers) then
            local width, heigth = getScreenResolution()
            local fov = getCameraFov() * 0.0174530
            local coeficent = width / fov
            local distance = (aimFOV * 0.0174530) * coeficent
            local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)

            renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)

            local candidates = {}
            local maxScreenDist = 0
            local max3DDist = 0

            for _, c in ipairs(aimCandidates) do
                local isAn = c.isAnimal
                local isPl = c.isPlayer
                if (aimAnimals and isAn) or (aimPlayers and isPl) then
                    local wposX, wposY = c.headScreenX, c.headScreenY
                    local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)
                    if inBox then
                        local canSee = true
                        if visibleCheck then
                            local px, py, pz = getCharCoordinates(playerPed)
                            canSee = isLineOfSightClear(px, py, pz, c.posX, c.posY, c.posZ, true, false, false, true, false, false, false)
                        end
                        if canSee then
                            local screenDist = math.sqrt((wposX - width_crosshair)^2 + (wposY - heigth_crosshair)^2)
                            local dist3D = c.dist
                            table.insert(candidates, {c.handle, screenDist, dist3D, c.headX, c.headY, c.headZ})
                            if screenDist > maxScreenDist then maxScreenDist = screenDist end
                            if dist3D > max3DDist then max3DDist = dist3D end
                        end
                    end
                end
            end

            local bestScore = math.huge
            for _, cand in ipairs(candidates) do
                local scrNorm = (maxScreenDist > 0) and (cand[2] / maxScreenDist) or 0
                local distNorm = (max3DDist > 0) and (cand[3] / max3DDist) or 0
                local score = scrNorm + distNorm
                if score < bestScore then
                    bestScore = score
                    Ohota.AimHandle = cand[1]
                end
            end
        elseif aiming and (Ohota.AimHandle ~= nil) then
            if aimAnimals or aimPlayers then
                local width, heigth = getScreenResolution()
                local fov = getCameraFov() * 0.0174530
                local coeficent = width / fov
                local distance = (aimFOV * 0.0174530) * coeficent
                local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)
                local x, y, z = GetBodyPartCoordinates(8, Ohota.AimHandle)
                local wposX, wposY = convert3DCoordsToScreen(x, y, z)

                renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)
                local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)

                local canSee = true
                if visibleCheck then
                    local px, py, pz = getCharCoordinates(playerPed)
                    local tx, ty, tz = getCharCoordinates(Ohota.AimHandle)
                    canSee = isLineOfSightClear(px, py, pz, tx, ty, tz, true, false, false, true, false, false, false)
                end

                if inBox and doesCharExist(Ohota.AimHandle) and isCharOnScreen(Ohota.AimHandle) and canSee then
                    local cx, cy, cz = getActiveCameraCoordinates()
                    local vect = {fX = cx - x, fY = cy - y, fZ = cz - z}
                    local screenAspectRatio = safeReadFloat(0xC3EFA4)
                    local crosshairOffset = {
                        safeReadFloat(0xB6EC10),
                        safeReadFloat(0xB6EC14)
                    }
                    if not screenAspectRatio then screenAspectRatio = 1.3333 end
                    if not crosshairOffset[1] then crosshairOffset[1] = 0.5 end
                    if not crosshairOffset[2] then crosshairOffset[2] = 0.5 end

                    local mult = math.tan(getCameraFov() * 0.5 * 0.017453292)
                    local fz = 3.14159265 - math.atan2(1.0, mult * ((0.5 - crosshairOffset[1]) * (2 / screenAspectRatio)))
                    local fx = 3.14159265 - math.atan2(1.0, mult * 2 * (crosshairOffset[2] - 0.5))

                    local camMode2 = safeReadMemory(0xB6F1A8, 1, false)
                    if not camMode2 or not (camMode2 == 53 or camMode2 == 55) then
                        fx = 3.14159265 / 2
                        fz = 3.14159265 / 2
                    end

                    local ax = math.atan2(vect.fY, -vect.fX) - 3.14159265 / 2
                    local az = math.atan2(math.sqrt(vect.fX * vect.fX + vect.fY * vect.fY), vect.fZ)

                    local finalAz = az - fz
                    local finalFx = fx - ax

                    local currentAz = safeReadFloat(0xB6F178)
                    local currentFx = safeReadFloat(0xB6F17C)
                    if not currentAz then currentAz = finalAz end
                    if not currentFx then currentFx = finalFx end

                    local smoothFactor = 1.0 / math.max(smoothing, 1.0)
                    finalAz = currentAz + (finalAz - currentAz) * smoothFactor
                    finalFx = currentFx + (finalFx - currentFx) * smoothFactor

                    if humanize then
                        if jitter > 0 then
                            finalAz = finalAz + (math.random() - 0.5) * jitter * 0.01
                            finalFx = finalFx + (math.random() - 0.5) * jitter * 0.01
                        end
                        if offsetX ~= 0 then
                            finalAz = finalAz + (math.random() - 0.5) * offsetX * 0.01
                        end
                        if offsetY ~= 0 then
                            finalFx = finalFx + (math.random() - 0.5) * offsetY * 0.01
                        end
                    end

                    setCameraPositionUnfixed(finalAz, finalFx)
                end
                if not doesCharExist(Ohota.AimHandle) then
                    Ohota.AimHandle = nil
                end
            else
                Ohota.AimHandle = nil
            end
        else
            Ohota.AimHandle = nil
        end

        if Ohota.LastTargetHandle ~= Ohota.AimHandle then
            Ohota.LastTargetHandle = Ohota.AimHandle
        end

        if Ohota.Triggerbot.v and aiming then
            local target = Ohota.AimHandle
            if target and doesCharExist(target) and isCharOnScreen(target) then
                local hx, hy, hz = GetBodyPartCoordinates(8, target)
                local hxx, hyy = convert3DCoordsToScreen(hx, hy, hz)
                local width, height = getScreenResolution()
                local crosshairX, crosshairY = width / 2, height / 2
                local dist = math.sqrt((hxx - crosshairX)^2 + (hyy - crosshairY)^2)
                local fovRadius = (Ohota.Triggerbot_FOV.v * 0.0174530) * (width / (getCameraFov() * 0.0174530))
                if dist <= fovRadius then
                    if os.clock() - Ohota._triggerbotTimer >= (Ohota.Triggerbot_Delay.v / 1000) then
                        setGameKeyState(16, -128)
                        wait(10)
                        setGameKeyState(16, 0)
                        Ohota._triggerbotTimer = os.clock()
                    end
                end
            end
        end

        if not Menu.windowState.v then
            imgui.ShowCursor = false
        else
            imgui.ShowCursor = true
        end
    end
end

function imgui.OnDrawFrame()
    local sw, sh = getScreenResolution()
    fsc = sh / 1080
    imgui.GetIO().FontGlobalScale = fsc
    if Menu.windowState.v then
        apply_custom_style()

        local mainWidth = 430 * fsc
        local mainHeight = 820 * fsc
        imgui.SetNextWindowSize(ImVec2(mainWidth, mainHeight), imgui.Cond.Always)
        imgui.SetNextWindowPos(ImVec2(sw / 2, sh / 2), imgui.Cond.Always, ImVec2(0.5, 0.5))

        imgui.Begin(u8'Охота by YaroRage', Menu.windowState, imgui.WindowFlags.NoResize)
            imgui.TextColored(imgui.ImVec4(0.30, 0.90, 0.35, 1.0), u8"Ohota By YaroRage")
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.60, 0.60, 0.60, 1.0))
            imgui.Text(u8"Охота - ESP, Аим, авто Y")
            imgui.PopStyleColor(1)
            imgui.Separator()

            if imgui.BeginTabBar("##MainTabs", imgui.TabBarFlags.NoCloseWithMiddleMouseButton) then
                if imgui.BeginTabItem(u8"WH / ESP") then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"Настройка Wallhack / ESP")
                    imgui.Separator()

                    if imgui.Checkbox(u8"WH животные", Ohota.Wh) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Отображение животных (олени 3-1, медведи 7-1)") end

                    if imgui.Checkbox(u8"WH трупы", Ohota.EspTush) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Рамка + название + дистанция для мертвых животных") end

                    if imgui.Checkbox(u8"WH транспорт", Ohota.EspCars) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Модель + здоровье + водитель + дистанция") end

                    if imgui.Checkbox(u8"WH игроки", Ohota.WhPlayers) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Ник + здоровье + броня + оружие + дистанция") end

                    if imgui.Checkbox(u8"ESP предметы/подбор", Ohota.EspPickups) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Отображение оружия, аптечек, патронов на земле") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"Линии и точки:")

                    if imgui.Checkbox(u8"Линия к животным", Ohota.LineAnimals) then end
                    if imgui.Checkbox(u8"Линия к транспорту", Ohota.LineCars) then end
                    if imgui.Checkbox(u8"Линия к игрокам", Ohota.LinePlayers) then end
                    if imgui.Checkbox(u8"Линия к трупам", Ohota.LineCorpses) then end

                    imgui.Separator()
                    if imgui.Checkbox(u8"Точка на голове", Ohota.HeadDot) then end
                    if imgui.Checkbox(u8"Расстояние", Ohota.ShowDistance) then end
                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"Дальность (0 = без огранич.):")
                    if imgui.SliderFloat(u8"Животные, м", Ohota.DistAnimals, 0.0, 500.0, '%.0f') then Ohota.DistAnimals.v = math.floor(Ohota.DistAnimals.v + 0.5) end
                    if imgui.SliderFloat(u8"Транспорт, м", Ohota.DistCars, 0.0, 500.0, '%.0f') then Ohota.DistCars.v = math.floor(Ohota.DistCars.v + 0.5) end
                    if imgui.SliderFloat(u8"Игроки, м", Ohota.DistPlayers, 0.0, 500.0, '%.0f') then Ohota.DistPlayers.v = math.floor(Ohota.DistPlayers.v + 0.5) end
                    if imgui.SliderFloat(u8"Предметы, м", Ohota.DistPickups, 0.0, 500.0, '%.0f') then Ohota.DistPickups.v = math.floor(Ohota.DistPickups.v + 0.5) end
                    imgui.EndTabItem()
                end

                if imgui.BeginTabItem(u8"Аим") then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"Настройка автонаведения")
                    imgui.Separator()

                    if imgui.Checkbox(u8"Аим на животных", Ohota.Aim) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Автонаведение на голову животных при прицеливании") end

                    if imgui.Checkbox(u8"Аим на игроков", Ohota.AimPlayers) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Автонаведение на голову игроков при прицеливании") end

                    if imgui.SliderFloat(u8"Сглаживание (1-20)", Ohota.Aim_Smoothing, 1.0, 20.0, '%.1f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Чем выше значение, тем медленнее поворот камеры") end

                    if imgui.SliderFloat(u8"FOV прицела (градусы)", Ohota.Aim_FOV, 0.5, 10.0, '%.1f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Радиус зоны захвата целей") end

                    if imgui.Checkbox(u8"Проверка видимости (LOS)", Ohota.Aim_VisibleCheck) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Не наводится на цель за стенами/объектами") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- Human-like (доп.) ---")
                    if imgui.Checkbox(u8"Человекоподобный аим", Ohota.Aim_Humanize) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Добавляет погрешность для имитации человека") end

                    if imgui.SliderFloat(u8"Дрожание (Jitter)", Ohota.Aim_Jitter, 0.0, 1.0, '%.2f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Случайное дрожание прицела (0-1.0)") end

                    if imgui.SliderInt(u8"Задержка выстрела (мс)", Ohota.Aim_RandomDelay, 0, 500) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Случайная пауза перед наведением") end

                    if imgui.SliderFloat(u8"Смещение X", Ohota.Aim_OffsetX, -1.0, 1.0, '%.2f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Горизонтальное отклонение от головы") end

                    if imgui.SliderFloat(u8"Смещение Y", Ohota.Aim_OffsetY, -1.0, 1.0, '%.2f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Вертикальное отклонение от головы") end

                    imgui.EndTabItem()
                end

                if imgui.BeginTabItem(u8"Утилиты") then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"Автоматические утилиты")
                    imgui.Separator()

                    if imgui.Checkbox(u8"Кнопка Y", Ohota.AutoY) then
                        if not Ohota.AutoY.v then
                            Ohota.AutoY_Clicker:Stop()
                        end
                    end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Автоматическое нажатие Y для охоты (спамер)") end

                    if imgui.SliderInt(u8"Интервал нажатия (мс)", waitWaitClickY, 100, 2000) then
                        if Ohota.AutoY_Clicker then Ohota.AutoY_Clicker.Sleep = waitWaitClickY.v end
                    end
                    if imgui.SliderInt(u8"Длительность нажатия (мс)", waitDownClickY, 50, 1000) then
                        if Ohota.AutoY_Clicker then Ohota.AutoY_Clicker.DownTime = waitDownClickY.v end
                    end

                    if imgui.Checkbox(u8"Удаление застрявших трупов (20 сек)", Ohota.Clear) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Удаляет животных, не двигающихся 20 секунд") end

                    if imgui.Checkbox(u8"Удаление кустов/деревьев", Ohota.ClearFol) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Скрывает растительность вокруг (опасно!)") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- Triggerbot ---")
                    if imgui.Checkbox(u8"Триггербот", Ohota.Triggerbot) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Автоматическая стрельба по целям в прицеле") end
                    if imgui.SliderInt(u8"Задержка выстрела (мс)", Ohota.Triggerbot_Delay, 0, 500) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Пауза между автоматическими выстрелами") end
                    if imgui.SliderFloat(u8"FOV триггербота", Ohota.Triggerbot_FOV, 0.5, 5.0, '%.1f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Радиус зоны для автоматического огня") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- NoRecoil / NoSpread ---")
                    if imgui.Checkbox(u8"Без отдачи (NoRecoil)", Ohota.NoRecoil) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Убирает отдачу оружия (экспериментально)") end
                    if imgui.Checkbox(u8"Без разброса (NoSpread)", Ohota.NoSpread) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Убирает разброс пуль (экспериментально)") end

                    imgui.EndTabItem()
                end

                if imgui.BeginTabItem(u8"Справка управл.") then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"Горячие клавиши и управление")
                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"Клавиши по умолчанию:")
                    imgui.Separator()

                    imgui.Text(u8"Меню (открыть/закрыть): L (удержать 1 сек)")
                    imgui.Text(u8"Отладка объектов: F6/F7 (ID), F8 (старт), F9 (шаг)")
                    imgui.Text(u8"Y: Автонажатие для охоты (спамер)")

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"VK коды для настройки клавиш:")
                    imgui.Text(u8"L = 0x4C  |  F1-F12 = 0x70-0x7B  |  Insert = 0x2D")
                    imgui.Text(u8"Home = 0x24  |  End = 0x23  |  PageUp = 0x21  |  PageDown = 0x22")
                    imgui.Text(u8"Numpad 0-9 = 0x60-0x69  |  NumLock = 0x90")

                    imgui.EndTabItem()
                end

                if imgui.BeginTabItem(u8"Отладка") then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"Инструменты отладки")
                    imgui.Separator()

                    if imgui.Checkbox(u8"Отладка объектов", Ohota.DbgObjs) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"Показ ID моделей объектов, лог в les_dbg.txt (F6/F7 ID, F8 старт)") end

                    imgui.Separator()
                    if imgui.Button(u8"Сохранить настройки", ImVec2(-1, 25)) then
                        saveConfig(gatherConfig())
                        print("[Les] Настройки сохранены")
                    end
                    imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.55, 1.0), u8"/les - меню, /lesr - перезагрузка")
                    imgui.EndTabItem()
                end

                imgui.EndTabBar()
            end
        imgui.End()
    end
    if not Menu.windowState.v and Ohota.FirstApplied then
        saveConfig(gatherConfig())
        Ohota.FirstApplied = false
    end
end

function apply_custom_style()
    ImGuiStyle.WindowPadding = imgui.ImVec2(5.0, 5.0)
    ImGuiStyle.WindowRounding = 10.0
    ImGuiStyle.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    ImGuiStyle.ChildWindowRounding = 2.0
    ImGuiStyle.FrameRounding = 10.0
    ImGuiStyle.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    ImGuiStyle.ScrollbarSize = 13.0
    ImGuiStyle.ScrollbarRounding = 0
    ImGuiStyle.GrabMinSize = 8.0
    ImGuiStyle.GrabRounding = 1.0

    ImGuiColors[ImGuiClr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    ImGuiColors[ImGuiClr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    ImGuiColors[ImGuiClr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    ImGuiColors[ImGuiClr.TitleBg]                = ImVec4(RGBA(90, 224, 83, 1))
    ImGuiColors[ImGuiClr.TitleBgActive]          = ImVec4(RGBA(90, 224, 83, 1))
    ImGuiColors[ImGuiClr.TitleBgCollapsed]       = ImVec4(RGBA(90, 224, 83, 0.51))
    ImGuiColors[ImGuiClr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    ImGuiColors[ImGuiClr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
    ImGuiColors[ImGuiClr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
    ImGuiColors[ImGuiClr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    ImGuiColors[ImGuiClr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    ImGuiColors[ImGuiClr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.Separator]              = ImGuiColors[ImGuiClr.Border]
    ImGuiColors[ImGuiClr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    ImGuiColors[ImGuiClr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    ImGuiColors[ImGuiClr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    ImGuiColors[ImGuiClr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    ImGuiColors[ImGuiClr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    ImGuiColors[ImGuiClr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    ImGuiColors[ImGuiClr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    ImGuiColors[ImGuiClr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    ImGuiColors[ImGuiClr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    ImGuiColors[ImGuiClr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    ImGuiColors[ImGuiClr.ComboBg]                = ImGuiColors[ImGuiClr.PopupBg]
    ImGuiColors[ImGuiClr.Border]                 = ImVec4(RGBA(4, 212, 28, 1))
    ImGuiColors[ImGuiClr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    ImGuiColors[ImGuiClr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    ImGuiColors[ImGuiClr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    ImGuiColors[ImGuiClr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    ImGuiColors[ImGuiClr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    ImGuiColors[ImGuiClr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    ImGuiColors[ImGuiClr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    ImGuiColors[ImGuiClr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    ImGuiColors[ImGuiClr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    ImGuiColors[ImGuiClr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    ImGuiColors[ImGuiClr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    ImGuiColors[ImGuiClr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    ImGuiColors[ImGuiClr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    ImGuiColors[ImGuiClr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function RGBA(r, g, b, a)
    return r / 255, g / 255, b / 255, a
end

function drawCharBox(handle, color)
    if not doesCharExist(handle) then return end
    local hx, hy, hz = GetBodyPartCoordinates(8, handle)
    local hxx, hyy = convert3DCoordsToScreen(hx, hy, hz)
    if not hxx or not hyy or hxx <= 0 or hyy <= 0 then return end
    local fx, fy, fz = getCharCoordinates(handle)
    local fxx, fyy = convert3DCoordsToScreen(fx, fy, fz)
    if not fxx or not fyy then return end
    local h = math.max(math.abs(fyy - hyy), 12)
    h = math.min(h, 80)
    local w = h * 0.62
    local x0 = fxx - w / 2
    local y0 = hyy - h * 0.1
    renderDrawBoxWithBorder(x0, y0, w, h, color, 1, color)
end

function renderEspTush()
    if type(getAllChars) ~= "function" then return end
    for _, v in pairs(getAllChars()) do
        if doesCharExist(v) and v ~= PLAYER_PED then
            local m = getCharModel(v)
            if (m == MODEL_DEER or m == MODEL_BEAR) and getCharHealth(v) <= 0 then
                local lx, ly, lz = getCharCoordinates(v)
                local X, Y = convert3DCoordsToScreen(lx, ly, lz)
                if X and Y and X > 0 and X < 8000 and Y > 0 and Y < 6000 then
                    drawCharBox(v, 0xFFFF0000)
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local d = math.sqrt((lx-px)^2 + (ly-py)^2 + (lz-pz)^2)
                    local animalName = (m == MODEL_DEER) and u8"Олень" or u8"Медведь"
                    renderFontDrawText(font_whGreen, animalName .. u8" (труп)", X, Y, 0xFFFF0000)
                    renderFontDrawText(font_whGreen, string.format(u8"%.0f м", d), X, Y - 10, 0xFFFFAAAA)
                    local sw, sh = getScreenResolution()
                    local hx2, hy2, hz2 = GetBodyPartCoordinates(8, v)
                    local hX, hY = convert3DCoordsToScreen(hx2, hy2, hz2)
                    if hX and hY then
                        renderDrawLine(sw/2, sh/2, hX, hY, 1.0, 0xFFFF0000)
                    end
                end
            end
        end
    end
end

function renderEspPlayers()
    if not Ohota.WhPlayers.v or type(getAllChars) ~= "function" then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, v in pairs(getAllChars()) do
        if doesCharExist(v) and v ~= PLAYER_PED and isCharOnScreen(v) then
            local resPid, pid = sampGetPlayerIdByCharHandle(v)
            if resPid then
                local posX, posY, posZ = getCharCoordinates(v)
                local _X, _Y = convert3DCoordsToScreen(posX, posY, posZ)
                local dist = math.sqrt((posX - px)^2 + (posY - py)^2 + (posZ - pz)^2)

                if (Ohota.DistPlayers.v <= 0 or dist <= Ohota.DistPlayers.v) and _X and _Y and _X > -50 and _X < 8050 and _Y > -50 and _Y < 6050 then
                    local health = getCharHealth(v)
                    local armor = getCharArmour(v)
                    local weapon = getCurrentCharWeapon(v)
                    local weaponName = getWeaponName(weapon)
                    local nick = sampGetPlayerNickname(pid) or "Unknown"

                    local healthColor = 0xFF00FF00
                    if health < 50 then healthColor = 0xFFFFFF00 end
                    if health < 20 then healthColor = 0xFFFF0000 end

                    local yOffset = 0
                    renderFontDrawText(font_whGreen, nick, _X, _Y + yOffset, 0xFF00CCFF); yOffset = yOffset + 12
                    renderFontDrawText(font_whGreen, "HP: " .. health, _X, _Y + yOffset, healthColor); yOffset = yOffset + 12
                    if armor > 0 then
                        renderFontDrawText(font_whGreen, "AP: " .. armor, _X, _Y + yOffset, 0xFF00AAFF); yOffset = yOffset + 12
                    end
                    renderFontDrawText(font_whGreen, weaponName, _X, _Y + yOffset, 0xFFFFFFFF); yOffset = yOffset + 12
                    renderFontDrawText(font_whGreen, string.format(u8"%.0f м", dist), _X, _Y + yOffset, 0xFFFFAAAA)

                    if Ohota.LinePlayers.v then
                        local hx, hy, hz = GetBodyPartCoordinates(8, v)
                        local hX, hY = convert3DCoordsToScreen(hx, hy, hz)
                        local sw, sh = getScreenResolution()
                        if hX and hY then
                            renderDrawLine(sw/2, sh/2, hX, hY, 1.0, 0xFF00CCFF)
                        end
                    end
                end
            end
        end
    end
end

function getWeaponName(id)
    local names = {
        [0] = u8"Кулаки", [1] = u8"Кастет", [2] = u8"Клюшка", [3] = u8"Нож", [4] = u8"Бита", [5] = u8"Лопата",
        [6] = u8"Кий", [7] = u8"Кий с шипами", [8] = u8"Катана", [9] = u8"Бензопила", [10] = u8"Вибратор",
        [11] = u8"Сайга-12", [12] = u8"Дробь", [13] = u8"MP5", [14] = u8"АК-47", [15] = u8"M4", [16] = u8"Тек-9",
        [17] = u8"Ружье", [18] = u8"Граната", [19] = u8"Дыня", [20] = u8"СSlinky", [21] = u8"Огнемет",
        [22] = u8"Пистолет", [23] = u8"Пистолет с фонариком", [24] = u8"Дигл", [25] = u8"Дробовик", [26] = u8"СAWN (обрез)",
        [27] = u8"СAWN", [28] = u8"Узи (авто)", [29] = u8"MP5 (авто)", [30] = u8"AK-47 (авто)", [31] = u8"M4 (авто)",
        [32] = u8"Тек-9 (авто)", [33] = u8"Винтовка", [34] = u8"Снайперка", [35] = u8"РПГ", [36] = u8"РСО",
        [37] = u8"Огнемёт", [38] = u8"Миниган", [39] = u8"Бомба", [40] = u8"Детонатор",
        [41] = u8"Газон", [42] = u8"Огнетушитель", [43] = u8"Фото", [44] = u8"Очки", [45] = u8"Ночники",
        [46] = u8"Парашют", [47] = u8"Парашют2"
    }
    return names[id] or (u8"Оружие " .. id)
end

function renderEspPickups()
    if not Ohota.EspPickups.v or type(getAllPickups) ~= "function" then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, pickup in pairs(getAllPickups()) do
        if doesPickupExist(pickup) then
            local model = getPickupModel(pickup)
            local modelName = getPickupModelName(model) or ("ID:" .. model)
            local px2, py2, pz2 = getPickupCoordinates(pickup)
            local X, Y = convert3DCoordsToScreen(px2, py2, pz2)
            if X and Y and X > -50 and X < 8050 and Y > -50 and Y < 6050 then
                local dist = math.sqrt((px2 - px)^2 + (py2 - py)^2 + (pz2 - pz)^2)
                if Ohota.DistPickups.v <= 0 or dist <= Ohota.DistPickups.v then
                    local pickupType = getPickupType(pickup) or 0
                    local typeName = ""
                    if pickupType == 1 then typeName = u8"Оружие"
                    elseif pickupType == 2 then typeName = u8"Аптечка"
                    elseif pickupType == 3 then typeName = u8"Броня"
                    elseif pickupType == 4 then typeName = u8"Деньги"
                    elseif pickupType == 5 then typeName = u8"Патроны"
                    else typeName = u8"Тип " .. pickupType end

                    local color = 0xFFFFFF00
                    if pickupType == 1 then color = 0xFF00CCFF end
                    if pickupType == 2 then color = 0xFF00FF00 end
                    if pickupType == 3 then color = 0xFF00AAFF end

                    renderFontDrawText(font_whGreen, typeName .. ": " .. modelName, X, Y, color)
                    renderFontDrawText(font_whGreen, string.format(u8"%.0f м", dist), X, Y - 10, 0xFFFFAAAA)
                end
            end
        end
    end
end

function getPickupModelName(model)
    local names = {
        [330] = u8"Клюшка", [331] = u8"Двигатель", [332] = u8"Гаечный", [333] = u8"Бита",
        [334] = u8"Нож столовый", [335] = u8"Дробовик", [336] = u8"Бита2", [337] = u8"Дыня",
        [338] = u8"Кол", [339] = u8"Граната1", [340] = u8"Граната2", [341] = u8"Аптечка",
        [342] = u8"Газонокосилка", [343] = u8"Ракета-А", [344] = u8"Ракета-Б", [345] = u8"Связка",
        [346] = u8"Броня", [347] = u8"Гаечный2", [348] = u8"Детонатор", [349] = u8"Газон2",
        [350] = u8"Деньги", [351] = u8"Трава-BS", [352] = u8"Аптечка2", [353] = u8"Деньги2",
        [354] = u8"Камера", [355] = u8"Наушники", [356] = u8"Очки", [357] = u8"Гаечный3",
        [358] = u8"Рация", [359] = u8"Фиолет", [360] = u8"Белый", [361] = u8"Черный",
    }
    return names[model] or (u8"Модель " .. model)
end

local _vehPosOk = (type(getCarPointer) == "function")
function getVehiclePosByMemory(veh)
    if not _vehPosOk then return nil end
    local ptr = getCarPointer(veh)
    if ptr and ptr > 0x100000 and ptr < 0x40000000 then
        local matrixPtr = readMemory(ptr + 0x14, 4, false)
        if matrixPtr and matrixPtr > 0x100000 and matrixPtr < 0x40000000 then
            local posPtr = matrixPtr + 0x30
            local x = representIntAsFloat(readMemory(posPtr + 0, 4, false))
            local y = representIntAsFloat(readMemory(posPtr + 4, 4, false))
            local z = representIntAsFloat(readMemory(posPtr + 8, 4, false))
            if x and y and z then return x, y, z end
        end
    end
    return nil
end

function renderEspCars()
    if type(getAllVehicles) ~= "function" then return end
    if not _vehPosOk then return end
    for _, v in pairs(getAllVehicles()) do
        if doesVehicleExist(v) then
            local okC, vvx, vvy, vvz = pcall(getVehiclePosByMemory, v)
            if okC and vvx and vvy and vvz then
                local VX, VY = convert3DCoordsToScreen(vvx, vvy, vvz)
                if VX and VY and VX > 0 and VX < 8000 and VY > 0 and VY < 6000 then
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local d = math.sqrt((vvx-px)^2 + (vvy-py)^2 + (vvz-pz)^2)
                    if Ohota.DistCars.v > 0 and d <= Ohota.DistCars.v then
                        local model = getCarModel(v)
                        local modelName = getVehicleModelName(model) or ("ID:" .. model)
                        local health = getCarHealth(v)
                        local driver = getDriverOfCar(v)
                        local driverName = ""
                        if driver and driver ~= 0 then
                            local isPlayer, pid = sampGetPlayerIdByCharHandle(driver)
                            if isPlayer then
                                driverName = sampGetPlayerNickname(pid) or ""
                            else
                                driverName = "NPC"
                            end
                        end

                        local healthColor = 0xFF00FF00
                        if health < 500 then healthColor = 0xFFFFFF00 end
                        if health < 250 then healthColor = 0xFFFF0000 end

                        renderFontDrawText(font_whGreen, modelName, VX, VY, 0xFF00CCFF)
                        renderFontDrawText(font_whGreen, string.format("HP: %.0f", health/10), VX, VY + 12, healthColor)
                        if driverName ~= "" then
                            renderFontDrawText(font_whGreen, u8"Водитель: " .. driverName, VX, VY + 24, 0xFFFFFFFF)
                        end
                        renderFontDrawText(font_whGreen, string.format(u8"%.0f м", d), VX, VY - 10, 0xFFFFFFFF)
                        if Ohota.LineCars.v then
                            local sw, sh = getScreenResolution()
                            renderDrawLine(sw/2, sh/2, VX, VY, 1.0, 0xFF00CCFF)
                        end
                    end
                end
            end
        end
    end
end

function getVehicleModelName(id)
    local names = {
        [400] = "Landstalker", [401] = "Bravura", [402] = "Buffalo", [403] = "Linerunner",
        [404] = "Perennial", [405] = "Sentinel", [406] = "Dumper", [407] = "Firetruck",
        [408] = "Trashmaster", [409] = "Stretch", [410] = "Manana", [411] = "Infernus",
        [412] = "Voodoo", [413] = "Pony", [414] = "Mule", [415] = "Cheetah",
        [416] = "Ambulance", [417] = "Leviathan", [418] = "Moonbeam", [419] = "Esperanto",
        [420] = "Taxi", [421] = "Washington", [422] = "Bobcat", [423] = "Mr Whoopee",
        [424] = "BF Injection", [425] = "Hunter", [426] = "Premier", [427] = "Enforcer",
        [428] = "Securicar", [429] = "Banshee", [430] = "Predator", [431] = "Bus",
        [432] = "Rhino", [433] = "Barracks", [434] = "Hotknife", [435] = "Trailer",
        [436] = "Previon", [437] = "Coach", [438] = "Cabbie", [439] = "Stallion",
        [440] = "Rumpo", [441] = "RC Bandit", [442] = "Romero", [443] = "Packer",
        [444] = "Monster", [445] = "Admiral", [446] = "Squalo", [447] = "Seasparrow",
        [448] = "Pizzaboy", [449] = "Tram", [450] = "Trailer 2", [451] = "Turismo",
        [452] = "Speeder", [453] = "Reefer", [454] = "Tropic", [455] = "Flatbed",
        [456] = "Yankee", [457] = "Caddy", [458] = "Solair", [459] = "Berkley's RC Van",
        [460] = "Skimmer", [461] = "PCJ-600", [462] = "Faggio", [463] = "Freeway",
        [464] = "RC Baron", [465] = "RC Raider", [466] = "Glendale", [467] = "Oceanic",
        [468] = "Sanchez", [469] = "Sparrow", [470] = "Patriot", [471] = "Quad",
        [472] = "Coastguard", [473] = "Dinghy", [474] = "Hermes", [475] = "Sabre",
        [476] = "Rustler", [477] = "ZR-350", [478] = "Walton", [479] = "Regina",
        [480] = "Comet", [481] = "BMX", [482] = "Burrito", [483] = "Camper",
        [484] = "Marquis", [485] = "Baggage", [486] = "Dozer", [487] = "Maverick",
        [488] = "News Chopper", [489] = "Rancher", [490] = "FBI Rancher", [491] = "Virgo",
        [492] = "Greenwood", [493] = "Jetmax", [494] = "Hotring Racer", [495] = "Sandking",
        [496] = "Blistac", [497] = "Polmav", [498] = "Boxville", [499] = "Benson",
        [500] = "Mesa", [502] = "RC Goblin", [503] = "Hotring Racer A", [504] = "Hotring Racer B",
    }
    return names[id] or ("Vehicle:" .. id)
end

function dbgObjectsRender()
    local sw, sh = getScreenResolution()
    for _, o in ipairs(_dbgObjs) do
        local X, Y = convert3DCoordsToScreen(o.x, o.y, o.z)
        local TX, TY = convert3DCoordsToScreen(o.x, o.y, o.z + 6.0)
        if X and Y and TX and TY and X == X and Y == Y and TX == TX and TY == TY
           and X > -50 and X < 8050 and Y > -50 and Y < 6050
           and TX > -50 and TX < 8050 and TY > -50 and TY < 6050 then
            local h = math.max(math.abs(Y - TY), 8)
            h = math.min(h, 80)
            local w = h * 0.8
            local x0 = X - w / 2
            local y0 = TY - h * 0.05
            local color = 0xFFFFFF00
            if o.s then
                color = 0xFF00CCFF
            elseif TREE_SET[o.m] then
                color = 0xFF00FF00
            end
            renderDrawBoxWithBorder(x0, y0, w, h, color, 1, color)
            renderDrawLine(sw / 2, sh / 2, X, Y, 1.0, color)
            renderFontDrawText(font_dbg, tostring(o.m) .. (o.s and 'S' or ''), X, y0 - 14, color)
        end
    end
end

local TREE_MODEL_IDS = {
    613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,
    631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,
    647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,
    663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,
    679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,
    695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,
    711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,
    727,728,729,730,731,732,733,734,735,736,737,738,792,
    14460,16096,16097,18579,18580,18581,18582,18583,18584,18585,
    18586,18587,18588,18589,18590,18591,18592,18593,18594,18595,
    821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,837,838,839,840,
    841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,
    861,862,863,864,865,866,867,868,869,870,871,872,873,874,875,876,877,878,879,880,
    881,882,883,884,885,886,887,888,889,890,891,892,893,894,895,896,897,898,899,900
}
TREE_SET = {}
for _, m in ipairs(TREE_MODEL_IDS) do TREE_SET[m] = true end
local FOLIAGE_RADIUS = 120.0
local FOLIAGE_SINK = 500.0
local FOLIAGE_MAX_PER_PASS = 50
local FOLIAGE_MAX_RESTORE_PER_PASS = 50
local BUILDING_MAX_PER_PASS = 30
local _folBldPosX, _folBldPosY, _folBldPosZ = nil, nil, nil

local _objHideOk = (type(getAllObjects) == "function" and type(setObjectCoordinates) == "function"
                    and type(getObjectModel) == "function" and type(getObjectCoordinates) == "function")

local function isServerObject(obj)
    if not sampGetObjectSampIdByHandle then return false end
    local ok, r1, r2 = pcall(sampGetObjectSampIdByHandle, obj)
    if not ok then return false end
    if r1 == false then return false end
    if r1 == true then return true end
    if type(r1) == 'number' then return r1 >= 0 end
    return false
end

_folHidden = {}
local _folCheckAt = 0

function applyFoliageClear()
    if not _objHideOk then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local done = 0
    for _, obj in pairs(getAllObjects()) do
        if done >= FOLIAGE_MAX_PER_PASS then break end
        if doesObjectExist and doesObjectExist(obj) and not _folHidden[obj] then
            local isServer = isServerObject(obj)
            if not isServer then
                local om, m = pcall(getObjectModel, obj)
                if om and m and TREE_SET[m] then
                    local oc, _, cx, cy, cz = pcall(getObjectCoordinates, obj)
                    if oc then
                        local dx = cx - px; local dy = cy - py; local dz = cz - pz
                        if (dx*dx + dy*dy + dz*dz) <= (FOLIAGE_RADIUS * FOLIAGE_RADIUS) then
                            _folHidden[obj] = {cx, cy, cz}
                            local ok = pcall(setObjectCoordinates, obj, cx, cy, cz - FOLIAGE_SINK)
                            if ok then done = done + 1 end
                        end
                    end
                end
            end
        end
    end
    if (os.clock() - _folCheckAt) > 10 then
        _folCheckAt = os.clock()
        local count = 0
        for h in pairs(_folHidden) do
            count = count + 1
            if not (doesObjectExist and doesObjectExist(h)) then _folHidden[h] = nil end
        end
        if count > 500 then
            local removed = 0
            for h in pairs(_folHidden) do
                if removed >= count - 400 then break end
                _folHidden[h] = nil; removed = removed + 1
            end
        end
    end
end

function restoreFoliage()
    if not _objHideOk then return end
    local done = 0
    for h, coords in pairs(_folHidden) do
        if done >= FOLIAGE_MAX_RESTORE_PER_PASS then break end
        if doesObjectExist and doesObjectExist(h) then
            pcall(setObjectCoordinates, h, coords[1], coords[2], coords[3])
        end
        _folHidden[h] = nil
        done = done + 1
    end
end

function sendRemoveBuildingRPCs()
    if not _objHideOk then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local done = 0
    for _, obj in pairs(getAllObjects()) do
        if done >= BUILDING_MAX_PER_PASS then break end
        if doesObjectExist and doesObjectExist(obj) and not _folHidden[obj] then
            local isServer = isServerObject(obj)
            if not isServer then
                local om, m = pcall(getObjectModel, obj)
                if om and m and TREE_SET[m] then
                    local oc, _, cx, cy, cz = pcall(getObjectCoordinates, obj)
                    if oc then
                        local dx = cx - px; local dy = cy - py; local dz = cz - pz
                        if (dx*dx + dy*dy + dz*dz) <= (FOLIAGE_RADIUS * FOLIAGE_RADIUS) then
                            _folHidden[obj] = {cx, cy, cz}
                            local ok = pcall(setObjectCoordinates, obj, cx, cy, cz - FOLIAGE_SINK)
                            if ok then done = done + 1 end
                        end
                    end
                end
            end
        end
    end
end

function probeBuilding(id)
    if not _objHideOk then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, obj in pairs(getAllObjects()) do
        if doesObjectExist and doesObjectExist(obj) and not _folHidden[obj] then
            local isServer = isServerObject(obj)
            if not isServer then
                local om, m = pcall(getObjectModel, obj)
                if om and m and m == id then
                    local oc, _, cx, cy, cz = pcall(getObjectCoordinates, obj)
                    if oc then
                        local dx = cx - px; local dy = cy - py; local dz = cz - pz
                        if (dx*dx + dy*dy + dz*dz) <= (FOLIAGE_RADIUS * FOLIAGE_RADIUS) then
                            _folHidden[obj] = {cx, cy, cz}
                            pcall(setObjectCoordinates, obj, cx, cy, cz - FOLIAGE_SINK)
                            dbg('PROBE id=' .. id)
                            break
                        end
                    end
                end
            end
        end
    end
end

function sweepOne(id)
    probeBuilding(id)
end

function dbgObjectsScan()
    _dbgScreen = {}
    _dbgObjs = {}
    if not _objHideOk then
        _dbgScreen[1] = u8'Нет API объектов (getAllObjects недоступен)'
        return
    end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local radius = FOLIAGE_RADIUS
    local counts = {}
    local total, treeById, hiddenNow, serverCnt, withinRad = 0, 0, 0, 0, 0
    for _, obj in pairs(getAllObjects()) do
        if doesObjectExist and doesObjectExist(obj) then
            local om, m = pcall(getObjectModel, obj)
            if not (om and m) then m = 0 end
            if not counts[m] then counts[m] = { n = 0, s = 0, hid = 0, rad = 0 } end
            counts[m].n = counts[m].n + 1
            total = total + 1
            local oc, _, cx, cy, cz = pcall(getObjectCoordinates, obj)
            local dist = 1e9
            if oc then
                dist = math.sqrt((cx - px) ^ 2 + (cy - py) ^ 2 + (cz - pz) ^ 2)
            end
            if dist <= radius then counts[m].rad = counts[m].rad + 1; withinRad = withinRad + 1 end
            local isServer = isServerObject(obj)
            if isServer then counts[m].s = counts[m].s + 1; serverCnt = serverCnt + 1 end
            if _folHidden[obj] then counts[m].hid = counts[m].hid + 1; hiddenNow = hiddenNow + 1 end
            if TREE_SET[m] then treeById = treeById + 1 end
            if dist <= radius then
                _dbgObjs[#_dbgObjs + 1] = { m = m, x = cx, y = cy, z = cz, s = isServer }
            end
        end
    end
    _dbgScreen[1] = string.format(u8'Всего объектов: %d | В радиусе: %d | Деревьев: %d | Скрытых: %d | Серверных: %d',
        total, withinRad, treeById, hiddenNow, serverCnt)
    local sorted = {}
    for m, c in pairs(counts) do
        if c.n > 0 and (c.rad > 0 or c.s > 0) then
            sorted[#sorted + 1] = {
                n = c.n, r = c.rad,
                s = string.format('ID %d: x%d%s%s%s', m, c.n,
                    (c.rad > 0 and (u8' в радиусе=' .. c.rad) or ''),
                    (c.s > 0 and (u8' сервер=' .. c.s) or ''),
                    (c.hid > 0 and (u8' скрыт=' .. c.hid) or ''))
            }
        end
    end
    table.sort(sorted, function(a, b)
        if a.r ~= b.r then return a.r > b.r end
        return a.n > b.n
    end)
    local _shown = 0
    for _, row in ipairs(sorted) do
        if _shown >= 14 then break end
        _dbgScreen[#_dbgScreen + 1] = row.s
        _shown = _shown + 1
    end
    if #sorted > _shown then
        _dbgScreen[#_dbgScreen + 1] = u8'... ещё ' .. #sorted .. u8' (подробнее в les_dbg.txt)'
    end
    if #_dbgScreen < 2 then
        _dbgScreen[#_dbgScreen + 1] = u8'Объекты не найдены'
    end
end

function onReceivePacket(id, bs)
    if type(_cefLogReceive) == 'function' then pcall(_cefLogReceive, id, bs) end
    if id ~= 215 then return end
    local pk = ''
    for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do pk = pk .. string.char(raknetBitStreamReadInt8(bs)) end
    if Ohota.AutoY.v then
        if pk:find("setFill(0, 100)", 1, true) then
            Ohota.AutoY_Clicker:Stop()
            dbg("AUTOY stop-100")
        elseif pk:find("setFill(0, ", 1, true) then
            Ohota.AutoY_Clicker:Start()
            dbg("AUTOY start triggered")
            AutoYLastSetFill = os.clock()
        end
    end
end

function targetAtCoords(x, y, z)
    local cx, cy, cz = getActiveCameraCoordinates()
    local vect = { fX = cx - x, fY = cy - y, fZ = cz - z }

    local screenAspectRatio = safeReadFloat(0xC3EFA4)
    local crosshairOffset = {
        safeReadFloat(0xB6EC10),
        safeReadFloat(0xB6EC14)
    }
    if not screenAspectRatio then screenAspectRatio = 1.3333 end
    if not crosshairOffset[1] then crosshairOffset[1] = 0.5 end
    if not crosshairOffset[2] then crosshairOffset[2] = 0.5 end

    local mult = math.tan(getCameraFov() * 0.5 * 0.017453292)
    local fz = 3.14159265 - math.atan2(1.0, mult * ((0.5 - crosshairOffset[1]) * (2 / screenAspectRatio)))
    local fx = 3.14159265 - math.atan2(1.0, mult * 2 * (crosshairOffset[2] - 0.5))

    local camMode = safeReadMemory(0xB6F1A8, 1, false)
    if not camMode or not (camMode == 53 or camMode == 55) then
        fx = 3.14159265 / 2
        fz = 3.14159265 / 2
    end

    local ax = math.atan2(vect.fY, -vect.fX) - 3.14159265 / 2
    local az = math.atan2(math.sqrt(vect.fX * vect.fX + vect.fY * vect.fY), vect.fZ)

    setCameraPositionUnfixed(az - fz, fx - ax)
end
