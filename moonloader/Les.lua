require "lib.moonloader"
require "lib.sampfuncs"

-- Include
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
ffi.cdef[[
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow(void);
    int IsIconic(void* hWnd);
    short GetAsyncKeyState(int vKey);
]]
local user32 = ffi.load("user32")

local _cursorShown, _processOn = nil, nil
local function setCursorShown(v)
    v = v and true or false
    if _cursorShown == v then return end
    _cursorShown = v
    imgui.ShowCursor = v
end
local function setImguiProcess(v)
    v = v and true or false
    if _processOn == v then return end
    _processOn = v
    imgui.Process = v
end

local function game_has_focus()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    return hwnd ~= nil and user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd
end


-- ����� (��������������� ���������)
local _fontInitDone = false
imgui.BeforeDrawFrame = function()
    if _fontInitDone then return end
    _fontInitDone = true
    imgui.GetIO().Fonts:Clear()
local _fontCands = {
    'C:\\Windows\\Fonts\\segoeui.ttf',   -- ���������, ������ ����
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
if not _fontLoaded then
    imgui.GetIO().Fonts:AddFontDefault()
end
end

-- ������
local ImVec2 = imgui.ImVec2
local ImVec4 = imgui.ImVec4
local ImGuiStyle = imgui.GetStyle()
local ImGuiColors = ImGuiStyle.Colors
local ImGuiClr = imgui.Col

-- ���������
local waitDownClickY = 300
local waitWaitClickY = 600

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

-- ������� ������� �������� (��������� �� �������� �����)
local _dbgScanAt = 0
local _dbgScreen = {}
local _dbgObjs = {}   -- ������� � ������� ��� ���������: {m=, x=, y=, z=, s=}
local _probeId = 613  -- ������� ������ ����� �������� (F6/F7)

-- ���������� ����� �������� (F8 �����/����, F9 ������ ������).
-- ���� ������ �� ��� (����� ������ ������ samp.dll+0x12843), ������ �� ������.
local _sweepRun = false
local _sweepCursor = 1
local _sweepBandW = 5
local _sweepLast = 0
local _sweepTotal = 0
local _sweepMin = 1
local _sweepMax = 1024
local _sweepBudget = 500

-- ����� "������"
local Clicker = {}
function Clicker:new(Button, Sleep)
    local obj = {}
    obj.Button = Button
    obj.Sleep = Sleep
    obj.Allow = false
    obj.thread = nil

    function obj:Start()
        self.Allow = true
        self.thread = lua_thread.create(function()
            while self.Allow do
                if game_has_focus() then
                    setVirtualKeyDown(self.Button, true)
                    wait(waitDownClickY)
                    setVirtualKeyDown(self.Button, false)
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
-- ������ ��������
local MODEL_DEER = 15555
local MODEL_BEAR = 15556

local Ohota = {
    -- ����� / WH
    Wh = imgui.ImBool(false),          -- WH ����� ��������
    WhPlayers = imgui.ImBool(false),   -- WH ������� (�������)
    HeadDot = imgui.ImBool(false),     -- ����� �� ������
    ShowDistance = imgui.ImBool(false),-- ���������
    -- ��������� ����������� (0 = ���������)
    DistAnimals = imgui.ImFloat(250.0),-- ��������� �� ��������
    DistCars    = imgui.ImFloat(0.0),  -- ��������� �� ������� (����)
    DistPlayers = imgui.ImFloat(0.0),  -- ��������� �� ������� (����)
    -- ����� ��������
    LineAnimals = imgui.ImBool(false), -- ����� �� ����� ��������
    LineCars = imgui.ImBool(false),    -- ����� �� �����
    LinePlayers = imgui.ImBool(false), -- ����� �� �������
    -- ESP
    EspTush = imgui.ImBool(false),     -- WH ��� (������� ��������)
    EspCars = imgui.ImBool(false),     -- WH �����
    -- ������
    Aim = imgui.ImBool(false),         -- ��� �� ��������
    AimPlayers = imgui.ImBool(false),  -- ��� �� �������
    Aim_silent = imgui.ImBool(false),
    AimHandle = nil,
    -- ������
    AutoY = imgui.ImBool(false),
    AutoY_Clicker = Clicker:new(vkeys.VK_Y, waitWaitClickY),
    Clear = imgui.ImBool(false),       -- ������� ��������� ��� (20 �)
    ClearFol = imgui.ImBool(false),    -- ������� �������/������ ������
    DbgObjs = imgui.ImBool(false),     -- ������� ������� �������� �� ������
    FolApplied = false,
    FolBldTimer = 0,
    FirstApplied = false,
    LastTargetHandle = nil,
}

-- ������ �� CEF/D3D-������: �� ������ �������, ���� ���������� ������������.
_devBarrier = 0.0   -- �����, ������ �������� ������ ��������

function renderAllowed()
    return os.clock() >= _devBarrier
end

function onScriptD3DDeviceLost()
    _devBarrier = os.clock() + 1.0
end

function onScriptD3DDeviceRestore()
    _devBarrier = os.clock() + 0.6
end

-- ��� ������ ��������� �� ������� �������� ����
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
    setCursorShown(Menu.windowState.v)
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

-- ������� ����
function main()
    if not isSampLoaded() or not isSampfuncsLoaded then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("les", imgui_Menu_windowState)
    sampRegisterChatCommand("lesr", function()
        thisScript():reload()
    end)

    local okY, yw = pcall(require, "ywelcome")
    if okY and type(yw) == "function" then
        yw("Les", "����� � ����. ����: ��������� L 1 ���, ������� - ������� L / /les")
    end

    -- ���������� ���� �� L: �������� - ��������� 1 ���, �������� - �������
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
                -- ������ �������
                if menuOpen then
                    -- ���� ������� -> ������� ����� �� �������
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                    fired = true
                    hold_start = 0
                else
                    -- ���� ������� -> ������ ��������� ��� ��������
                    hold_start = os.clock()
                    fired = false
                end
            elseif down and prev_down then
                -- ��������� ������
                if not menuOpen and not fired and hold_start > 0 and (os.clock() - hold_start) >= 0.5 then
                    fired = true
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                end
            else
                -- ������ ��������
                hold_start = 0
                fired = false
            end
            prev_down = down
        end
    end)

    -- ����� ������� ��������: F6/F7 - �������, F8 - ���������� �����, F9 - ������ ������.
    -- �������� ������ ��� ���������� ������� (������ �� ��������� ��������).
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
                if d6 and not prev6 then
                    _probeId = _probeId - 1
                    probeBuilding(_probeId)
                end
                if d7 and not prev7 then
                    _probeId = _probeId + 1
                    probeBuilding(_probeId)
                end
                if d8 and not prev8 then
                    _sweepRun = not _sweepRun
                    if _sweepRun then
                        _sweepTotal = 0
                        if _sweepCursor < _sweepMin or _sweepCursor > _sweepMax then
                            _sweepCursor = _sweepMin
                        end
                    end
                end
                if d9 and not prev9 then
                    if _sweepBandW == 5 then _sweepBandW = 1
                    elseif _sweepBandW == 1 then _sweepBandW = 10
                    elseif _sweepBandW == 10 then _sweepBandW = 25
                    else _sweepBandW = 5 end
                end
            end
            -- ����������: ���� ������ �� ��� (0.4 �) � ��� �����, ����� �� ������ ������
            if _sweepRun and Ohota.DbgObjs.v and (os.clock() - _sweepLast) >= 0.4 then
                _sweepLast = os.clock()
                _sweepTotal = _sweepTotal + 1
                if _sweepTotal > _sweepBudget then
                    _sweepRun = false
                    _sweepTotal = 0
                else
                    pcall(sweepOne, _sweepCursor)
                    _sweepCursor = _sweepCursor + 1
                    if _sweepCursor > _sweepMax then _sweepCursor = _sweepMin end
                end
            end
            prev6, prev7, prev8, prev9 = d6, d7, d8, d9
        end
    end)

    -- ����� ��� ����� ��������
    font_whGreen = renderCreateFont('Arial', 7, 13)

    -- ����� ��� ������� ��������
    font_dbg = renderCreateFont('Arial', 7, 13)

    setImguiProcess(true)
    setCursorShown(false)

    -- ����������� �������� ��� ������, ���� ��������
    if Ohota.ClearFol.v then
        pcall(applyFoliageClear)
    end

    while true do
        wait(0)
        -- ������ �� CEF/D3D-������: ���� ���������� ������������/�����������������,
        -- ��������� ���������� � ������� (ESP/������/�����), � ��������� ������
        -- (setObjectCoordinates/RPC43 ������ �� ������������� D3D-������).
        if not renderAllowed() then goto continue end

        -- �������� ������ ESP (���������)
        if Ohota.EspTush.v and type(renderEspTush) == "function" then pcall(renderEspTush) end
        if Ohota.EspCars.v and type(renderEspCars) == "function" then pcall(renderEspCars) end
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
            -- ����������� �������/����� ����� (buildings) ������� ����� RPC 43
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

        -- ������� ������� �������� (��� � 1.5 c)
        if Ohota.DbgObjs.v then
            if (os.clock() - _dbgScanAt) > 1.5 then
                _dbgScanAt = os.clock()
                dbg('--- ���� �������� ������ ---')
                pcall(dbgObjectsScan)
            end
            pcall(dbgObjectsRender)
            renderFontDrawText(font_dbg, '����� ��������: ID ' .. _probeId .. '  (F6 ����� / F7 �����)', 12, 105, 0xFFFF66FF)
            if _sweepRun then
                local _bs = math.floor((_sweepCursor - 1) / _sweepBandW) * _sweepBandW + 1
                local _be = math.min(_bs + _sweepBandW - 1, _sweepMax)
                renderFontDrawText(font_dbg, string.format('���������: ���� %d-%d (F8 ����, F9 ������=%d) ������=%d',
                    _bs, _be, _sweepBandW, _sweepCursor), 12, 118, 0xFF66FF00)
            else
                renderFontDrawText(font_dbg, string.format('��������� ���� � F8 ����� (������=%d, F9 ������)', _sweepBandW), 12, 118, 0xFF66FF00)
            end
            local _sw, _sh = getScreenResolution()
            for _i, _line in ipairs(_dbgScreen) do
                renderFontDrawText(font_dbg, _line, 12 + ((_i - 1) % 2) * 330, 130 + math.floor((_i - 1) / 2) * 13, 0xFFFFFF00)
            end
        end

        -- WH ����� �������� + ������� + �����
        if Ohota.Wh.v or Ohota.LineAnimals.v or Ohota.WhPlayers.v or Ohota.LinePlayers.v or Ohota.HeadDot.v or Ohota.ShowDistance.v then
            for pairsId, value in pairs(getAllChars()) do
                if doesCharExist(value) and value ~= PLAYER_PED and isCharOnScreen(value) and getCharHealth(value) > 0 then
                    local modelid = getCharModel(value)
                    local posX, posY, posZ = getCharCoordinates(value)
                    local _X, _Y = convert3DCoordsToScreen(posX, posY, posZ)

                    local playerX, playerY, playerZ = getCharCoordinates(playerPed)
                    local X, Y = convert3DCoordsToScreen(playerX, playerY, playerZ)

                    local dist = math.sqrt((posX - playerX)^2 + (posY - playerY)^2 + (posZ - playerZ)^2)

                    local health = getCharHealth(value)
                    local hx, hy, hz = GetBodyPartCoordinates(8, value)
                    local hxx, hyy = convert3DCoordsToScreen(hx, hy, hz)

                    local isAnimal = (modelid == MODEL_DEER or modelid == MODEL_BEAR)
                    local shouldRenderAimExtras = (doesCharExist(Ohota.AimHandle) and Ohota.AimHandle == value)

                    -- ������ �� NaN/�������� ��������� (����� ���� �������)
                    local okScreen = (_X ~= nil and _Y ~= nil and _X == _X and _Y == _Y
                                      and _X > -50 and _X < 8050 and _Y > -50 and _Y < 6050)
                    local okHead = (hxx ~= nil and hyy ~= nil and hxx == hxx and hyy == hyy
                                    and hxx > -50 and hxx < 8050 and hyy > -50 and hyy < 6050)

                    -- WH �������
                    if Ohota.Wh.v and isAnimal and okScreen and (Ohota.DistAnimals.v > 0 and dist <= Ohota.DistAnimals.v) then
                        if modelid == MODEL_DEER then
                            if health == 100 then
                                renderFontDrawText(font_whGreen, '�����(3)', _X, _Y, 0xFF00FF00)
                            elseif health == 65 then
                                renderFontDrawText(font_whGreen, '�����(2)', _X, _Y, 0xFFFF9D00)
                            elseif health == 30 then
                                renderFontDrawText(font_whGreen, '�����(1)', _X, _Y, 0xFFFF0000)
                            end
                        elseif modelid == MODEL_BEAR then
                            if health == 100 then
                                renderFontDrawText(font_whGreen, '�������(7)', _X, _Y, 0xFF00FF00)
                            elseif health == 85 then
                                renderFontDrawText(font_whGreen, '�������(6)', _X, _Y, 0xFF55E100)
                            elseif health == 70 then
                                renderFontDrawText(font_whGreen, '�������(5)', _X, _Y, 0xFFAAC300)
                            elseif health == 55 then
                                renderFontDrawText(font_whGreen, '�������(4)', _X, _Y, 0xFFFFA500)
                            elseif health == 40 then
                                renderFontDrawText(font_whGreen, '�������(3)', _X, _Y, 0xFFFF6E00)
                            elseif health == 25 then
                                renderFontDrawText(font_whGreen, '�������(2)', _X, _Y, 0xFFFF3700)
                            elseif health == 10 then
                                renderFontDrawText(font_whGreen, '�������(1)', _X, _Y, 0xFFFF0000)
                            end
                        end
                        -- ����� �� �������
                        if Ohota.LineAnimals.v and not shouldRenderAimExtras and okHead then
                            local sw, sh = getScreenResolution()
                            renderDrawLine(sw/2, sh/2, hxx, hyy, 1.0, 0xFFFFFF00)
                        end
                    end

                    -- ����� �� �������
                    local isPlayer = false
                    local resPid, pid = sampGetPlayerIdByCharHandle(value)
                    if resPid then isPlayer = true end
                    if okScreen and isPlayer and (Ohota.DistPlayers.v > 0 and dist <= Ohota.DistPlayers.v) then
                        if Ohota.WhPlayers.v then
                            renderFontDrawText(font_whGreen, "�����", _X, _Y, 0xFF00CCFF)
                        end
                        if Ohota.LinePlayers.v and not shouldRenderAimExtras and okHead then
                            local sw, sh = getScreenResolution()
                            renderDrawLine(sw/2, sh/2, hxx, hyy, 1.0, 0xFF00CCFF)
                        end
                    end

                    -- ����� �� ������
                    if Ohota.HeadDot.v and okHead then
                        renderDrawBoxWithBorder(hxx, hyy, 3, 3, 0xFF00FF00, 1, 0xFF00FF00)
                    end

                    -- ��������� (������ ��� �������� ���������)
                    if Ohota.ShowDistance.v then
                        local _showDist = false
                        if isAnimal and Ohota.Wh.v and (Ohota.DistAnimals.v > 0 and dist <= Ohota.DistAnimals.v) then
                            _showDist = true
                        elseif isPlayer and Ohota.WhPlayers.v and (Ohota.DistPlayers.v > 0 and dist <= Ohota.DistPlayers.v) then
                            _showDist = true
                        end
                        if _showDist and okScreen then
                            renderFontDrawText(font_whGreen, string.format("%.0f �", dist), _X, _Y - 10, 0xFFFFFFFF)
                        end
                    end
                end
            end
        end

        -- ������ ��������� ��� (20 � ��� ��������)
        if Ohota.Clear.v then
            if not animalLastState then animalLastState = {} end
            for _, value in pairs(getAllChars()) do
                if value ~= PLAYER_PED and doesCharExist(value) then
                    local modelid = getCharModel(value)
                    if (modelid == MODEL_DEER or modelid == MODEL_BEAR) then
                        local curX, curY, curZ = getCharCoordinates(value)
                        local state = animalLastState[value]
                        local now = os.time()
                        if not state then
                            animalLastState[value] = {x = curX, y = curY, z = curZ, lastMoveTime = now}
                        else
                            local moved = (math.abs(curX - state.x) > 0.01 or
                                           math.abs(curY - state.y) > 0.01 or
                                           math.abs(curZ - state.z) > 0.01)
                            if moved then
                                state.x = curX; state.y = curY; state.z = curZ
                                state.lastMoveTime = now
                            else
                                if now - state.lastMoveTime >= 20 then
                                    deleteChar(value)
                                    animalLastState[value] = nil
                                end
                            end
                        end
                    end
                end
            end
        end

        -- ������ (���): ��������� �������� / ������
        local camMode = readMemory(0xB6F1A8, 1, false)
        local aiming = (camMode == 53 or camMode == 55 or camMode == 7 or camMode == 8)
        local aimAnimals = Ohota.Aim.v
        local aimPlayers = Ohota.AimPlayers.v

        if aiming and (Ohota.AimHandle == nil) and (aimAnimals or aimPlayers) then
            local width, heigth = getScreenResolution()
            local fov = getCameraFov() * 0.0174530
            local coeficent = width / fov
            local distance = 0.025 * coeficent
            local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)

            -- ��������� ���� �������
            renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)

            local candidates = {}
            local maxScreenDist = 0
            local max3DDist = 0

            for _, v in pairs(getAllChars()) do
                if doesCharExist(v) and isCharOnScreen(v) then
                    local modelid = getCharModel(v)
                    local isAn = (modelid == MODEL_DEER or modelid == MODEL_BEAR)
                    local isPl = false
                    if not isAn then
                        local r, p = sampGetPlayerIdByCharHandle(v)
                        if r then isPl = true end
                    end
                    -- ������ �� ���� ����
                    if (aimAnimals and isAn) or (aimPlayers and isPl) then
                        local x, y, z = GetBodyPartCoordinates(8, v)
                        local wposX, wposY = convert3DCoordsToScreen(x, y, z)
                        local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)
                        if inBox then
                            local screenDist = math.sqrt((wposX - width_crosshair)^2 + (wposY - heigth_crosshair)^2)
                            local cX, cY, cZ = getCharCoordinates(v)
                            local pX, pY, pZ = getCharCoordinates(playerPed)
                            local dist3D = math.sqrt((cX-pX)^2 + (cY-pY)^2 + (cZ-pZ)^2)
                            table.insert(candidates, {v, screenDist, dist3D, x, y, z})
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
                local distance = 0.025 * coeficent
                local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)
                local x, y, z = GetBodyPartCoordinates(8, Ohota.AimHandle)
                local wposX, wposY = convert3DCoordsToScreen(x, y, z)

                renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)
                local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)
                if inBox and doesCharExist(Ohota.AimHandle) and isCharOnScreen(Ohota.AimHandle) then
                    targetAtCoords(x, y, z)
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

        -- ������
        if not Menu.windowState.v then
            setCursorShown(false)
        else
            setCursorShown(true)
        end
        ::continue::
    end
end

-- ����
function imgui.OnDrawFrame()
    if not renderAllowed() then
        return
    end
    local sw, sh = getScreenResolution()
    if Menu.windowState.v then
        apply_custom_style()

        local mainWidth = 430
        local mainHeight = 690
        imgui.SetNextWindowSize(ImVec2(mainWidth, mainHeight), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, ImVec2(0.5, 0.5))

        imgui.Begin(u8'����� � ����', Menu.windowState, imgui.WindowFlags.NoResize)
            imgui.TextColored(imgui.ImVec4(0.30, 0.90, 0.35, 1.0), u8"Ohota By YaroRage")
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.60, 0.60, 0.60, 1.0))
            imgui.Text(u8"����� � ���� - ESP, ������, ���������� Y")
            imgui.PopStyleColor(1)
            imgui.Separator()

            -- ����� / ESP
            imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- ����� / ESP ---")
            if imgui.Checkbox(u8"WH ��������", Ohota.Wh) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ����� �������� � ����������� ����� (3-1 / 7-1)") end

            if imgui.Checkbox(u8"WH ���", Ohota.EspTush) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ��������� ��� (����� + ����� + ���������)") end

            if imgui.Checkbox(u8"WH �����", Ohota.EspCars) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ����� ������ (����� + ����� + ���������)") end

            if imgui.Checkbox(u8"WH �������", Ohota.WhPlayers) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"���������� ������� ����� ��� �������") end

            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"����� �� ����:")

            if imgui.Checkbox(u8"����� �� ��������", Ohota.LineAnimals) then end
            if imgui.Checkbox(u8"����� �� �����", Ohota.LineCars) then end
            if imgui.Checkbox(u8"����� �� �������", Ohota.LinePlayers) then end

            if imgui.Checkbox(u8"����� �� ������", Ohota.HeadDot) then end
            if imgui.Checkbox(u8"���������", Ohota.ShowDistance) then end
            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"��������� (0 = ����):")
            if imgui.SliderFloat(u8"��������, �", Ohota.DistAnimals, 0.0, 500.0, '%.0f') then Ohota.DistAnimals.v = math.floor(Ohota.DistAnimals.v + 0.5) end
            if imgui.SliderFloat(u8"������, �", Ohota.DistCars, 0.0, 500.0, '%.0f') then Ohota.DistCars.v = math.floor(Ohota.DistCars.v + 0.5) end
            if imgui.SliderFloat(u8"������, �", Ohota.DistPlayers, 0.0, 500.0, '%.0f') then Ohota.DistPlayers.v = math.floor(Ohota.DistPlayers.v + 0.5) end
            imgui.Separator()

            -- ������
            imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- ������ ---")
            if imgui.Checkbox(u8"��� �� ��������", Ohota.Aim) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ������ �� �������� (�����/�������)") end

            if imgui.Checkbox(u8"��� �� �������", Ohota.AimPlayers) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ������ �� �������") end
            imgui.Separator()

            -- ������
            imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- ������ ---")
            if imgui.Checkbox(u8"���������� Y", Ohota.AutoY) then
                if not Ohota.AutoY.v then
                    Ohota.AutoY_Clicker:Stop()
                end
            end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"�������������� ���� �� ������� Y (��� �����)") end

            if imgui.Checkbox(u8"������� ��������� ��� (20 �)", Ohota.Clear) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"������� ���� ��������, ������� 20 ������ �� ���������") end

            if imgui.Checkbox(u8"������� ������� ������", Ohota.ClearFol) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ������� �������/����� � ������� ������ ���������") end

            if imgui.Checkbox(u8"������� ������� ��������", Ohota.DbgObjs) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"���������� ������ �������� ������ �� ������ � ����� �� � les_dbg.txt (��� ������ ������ ID ��������)") end

            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.55, 1.0), u8"/les - ����, /lesr - ����������")
        imgui.End()
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
    r = r / 255
    g = g / 255
    b = b / 255
    return r, g, b, a
end

-- ������ ����� ������ ��������� �� �������� �����������
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

-- WH ���: ����� + ����� + ���������
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
                    renderFontDrawText(font_whGreen, '����', X, Y, 0xFFFF0000)
                    renderFontDrawText(font_whGreen, string.format("%.0f �", d), X, Y - 10, 0xFFFFAAAA)
                    -- ����� �� ����������� �� ����
                    local sw, sh = getScreenResolution()
                    local hx, hy, hz = GetBodyPartCoordinates(8, v)
                    local hX, hY = convert3DCoordsToScreen(hx, hy, hz)
                    if hX and hY then
                        renderDrawLine(sw/2, sh/2, hX, hY, 1.0, 0xFFFF0000)
                    end
                end
            end
        end
    end
end

-- WH ����� ����� ������ (getCarPointer + ������� �������)
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
            if x and y and z then
                return x, y, z
            end
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
                        renderFontDrawText(font_whGreen, '������', VX, VY, 0xFF00CCFF)
                        renderFontDrawText(font_whGreen, string.format("%.0f �", d), VX, VY - 10, 0xFFFFFFFF)
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

-- ��������� �������: ���� + ����� + ID �� ������ ������� � �������
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

-- �������/�����: � GTA �������������� �������� � ���� �������� (�� ������),
-- ������� RPC 43 �� �� �������. �� ������� ������� � �� ������������� ������
-- (���� �����) � ������ ������ ������, �������� ��� �� 500 � ���� �� ��� ��
-- ����� (�� �� ������ ���������, ������ �� ������). ���������� ����������,
-- ����� ������� ������� ��� ����������. ��������� ������� �� �������.
local TREE_MODELS = {}
for _i = 613, 820 do
    TREE_MODELS[#TREE_MODELS + 1] = _i
end
TREE_SET = {}
for _, m in ipairs(TREE_MODELS) do TREE_SET[m] = true end
local FOLIAGE_RADIUS = 120.0
local FOLIAGE_SINK = 500.0
local FOLIAGE_MAX_PER_PASS = 20
local FOLIAGE_MAX_RESTORE_PER_PASS = 25
local _folBldPosX, _folBldPosY, _folBldPosZ = nil, nil, nil
local _folBldStep = 0        -- ������ ������� ������ � ��������� ������� (0 = �� ���)
local FOLIAGE_RPC_PER_STEP = 5   -- ������� ������� �� ���� ����� (��� ����� � �����)

local _objHideOk = (type(getAllObjects) == "function" and type(setObjectCoordinates) == "function"
                    and type(getObjectModel) == "function" and type(getObjectCoordinates) == "function")

-- true = ������ ��������� (�� �������), false = ������� (����� �������).
-- ����� ���������� -1/0 ��� false ��� ������� ��������; -1 � Lua � ������,
-- ������� ��������� ����.
local function isServerObject(obj)
    if not sampGetObjectSampIdByHandle then return false end
    local ok, r1, r2 = pcall(sampGetObjectSampIdByHandle, obj)
    if not ok then return false end
    if r1 == false then return false end
    if r1 == true then return true end
    if type(r1) == 'number' then return r1 >= 0 end
    return false
end

_folHidden = {}   -- obj -> {x, y, z} (������������ ����������)
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
                            pcall(setObjectCoordinates, obj, cx, cy, cz - FOLIAGE_SINK)
                            done = done + 1
                        end
                    end
                end
            end
        end
    end
    -- ������ ������ ���������� ������� (������ �������������� = ������ �����)
    if (os.clock() - _folCheckAt) > 10 then
        _folCheckAt = os.clock()
        for h in pairs(_folHidden) do
            if not (doesObjectExist and doesObjectExist(h)) then
                _folHidden[h] = nil
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

-- ����������� �������/����� (building-�������� �����) � ������ ����� RemoveBuildingForPlayer.
-- RPC 43 ������ ������� �������� � �� ������� ������. ����� �� ����������� RPC ���
-- ������ ���/���� � �� �������� ������� � ���� ���� (samp.dll+0x12843):
--  - ������ ������ ����������� ������ ����� ����� ������ > 150 � �� ����� �������� �������;
--  - ������ �������� �� FOLIAGE_RPC_PER_STEP ����� �� ����� �� �������� ����� (5/���).
function sendRemoveBuildingRPCs()
    if type(raknetEmulRpcReceiveBitStream) ~= "function" then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    -- ����� ������ �������� ������ ���� ������ �� ������� ����� (�����-���/���� �� ����������)
    if _folBldStep == 0 then
        if _folBldPosX ~= nil then
            local dx = px - _folBldPosX
            local dy = py - _folBldPosY
            local dz = pz - _folBldPosZ
            if (dx*dx + dy*dy + dz*dz) <= (150.0 * 150.0) then return end
        end
        _folBldStep = 1
    end
    local stop = _folBldStep + FOLIAGE_RPC_PER_STEP - 1
    if stop > #TREE_MODELS then stop = #TREE_MODELS end
    repeat
        local model = TREE_MODELS[_folBldStep]
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt32(bs, model)
        raknetBitStreamWriteFloat(bs, px)
        raknetBitStreamWriteFloat(bs, py)
        raknetBitStreamWriteFloat(bs, pz)
        raknetBitStreamWriteFloat(bs, FOLIAGE_RADIUS)
        pcall(raknetEmulRpcReceiveBitStream, 43, bs)
        raknetDeleteBitStream(bs)
        _folBldStep = _folBldStep + 1
    until _folBldStep > stop
    if _folBldStep > #TREE_MODELS then
        _folBldStep = 0
        _folBldPosX, _folBldPosY, _folBldPosZ = px, py, pz
    end
end

-- �����: ������ ��������� � ��������� ������� ������ ������ (����� RPC 43).
function probeBuilding(id)
    if type(raknetEmulRpcReceiveBitStream) ~= "function" then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt32(bs, id)
    raknetBitStreamWriteFloat(bs, px)
    raknetBitStreamWriteFloat(bs, py)
    raknetBitStreamWriteFloat(bs, pz)
    raknetBitStreamWriteFloat(bs, FOLIAGE_RADIUS)
    pcall(raknetEmulRpcReceiveBitStream, 43, bs)
    raknetDeleteBitStream(bs)
    dbg('PROBE id=' .. id)
end

-- ���� ������ �� �����: ������� ��������� ������ ���� ������ ������ ������.
function sweepOne(id)
    if type(raknetEmulRpcReceiveBitStream) ~= "function" then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt32(bs, id)
    raknetBitStreamWriteFloat(bs, px)
    raknetBitStreamWriteFloat(bs, py)
    raknetBitStreamWriteFloat(bs, pz)
    raknetBitStreamWriteFloat(bs, FOLIAGE_RADIUS)
    pcall(raknetEmulRpcReceiveBitStream, 43, bs)
    raknetDeleteBitStream(bs)
    dbg('SWEEP id=' .. id)
end

-- �������: �������� ������ �������� ������ (� �������� �������)
function dbgObjectsScan()
    _dbgScreen = {}
    _dbgObjs = {}
    if not _objHideOk then
        _dbgScreen[1] = '��� API �������� (getAllObjects ����������)'
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
            if dist <= radius then
                counts[m].rad = counts[m].rad + 1
                withinRad = withinRad + 1
            end
            local isServer = isServerObject(obj)
            if isServer then counts[m].s = counts[m].s + 1 serverCnt = serverCnt + 1 end
            if _folHidden[obj] then counts[m].hid = counts[m].hid + 1 hiddenNow = hiddenNow + 1 end
            if TREE_SET[m] then treeById = treeById + 1 end
            if dist <= radius then
                _dbgObjs[#_dbgObjs + 1] = { m = m, x = cx, y = cy, z = cz, s = isServer }
                dbg(string.format('OBJ model=%d dist=%.0f server=%s hidden=%s pos=%.1f,%.1f,%.1f',
                    m, dist, tostring(isServer), tostring(_folHidden[obj] ~= nil), cx, cy, cz))
            end
        end
    end
    _dbgScreen[1] = string.format('�������� �����: %d | � �������: %d | �� ID ������: %d | ������: %d | ���������: %d',
        total, withinRad, treeById, hiddenNow, serverCnt)
    local sorted = {}
    for m, c in pairs(counts) do
        if c.n > 0 and (c.rad > 0 or c.s > 0) then
            sorted[#sorted + 1] = {
                n = c.n,
                r = c.rad,
                s = string.format('ID %d: x%d%s%s%s', m, c.n,
                    (c.rad > 0 and (' � ������=' .. c.rad) or ''),
                    (c.s > 0 and (' ����=' .. c.s) or ''),
                    (c.hid > 0 and (' ������=' .. c.hid) or ''))
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
        _dbgScreen[#_dbgScreen + 1] = '... ����� ������� ' .. #sorted .. ' (������ ������ � les_dbg.txt)'
    end
    if #_dbgScreen < 2 then
        _dbgScreen[#_dbgScreen + 1] = '����� �������� ���'
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

    local vect = {
        fX = cx - x,
        fY = cy - y,
        fZ = cz - z
    }

    local screenAspectRatio = representIntAsFloat(readMemory(0xC3EFA4, 4, false))
    local crosshairOffset = {
        representIntAsFloat(readMemory(0xB6EC10, 4, false)),
        representIntAsFloat(readMemory(0xB6EC14, 4, false))
    }

    local mult = math.tan(getCameraFov() * 0.5 * 0.017453292)
    fz = 3.14159265 - math.atan2(1.0, mult * ((0.5 - crosshairOffset[1]) * (2 / screenAspectRatio)))
    fx = 3.14159265 - math.atan2(1.0, mult * 2 * (crosshairOffset[2] - 0.5))

    local camMode = readMemory(0xB6F1A8, 1, false)

    if not (camMode == 53 or camMode == 55) then
        fx = 3.14159265 / 2
        fz = 3.14159265 / 2
    end

    local ax = math.atan2(vect.fY, -vect.fX) - 3.14159265 / 2
    local az = math.atan2(math.sqrt(vect.fX * vect.fX + vect.fY * vect.fY), vect.fZ)

    setCameraPositionUnfixed(az - fz, fx - ax)
end
