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
local json = require 'json'  -- ��� ���������� �������
ffi.cdef[[
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow(void);
    int IsIconic(void* hWnd);
    short GetAsyncKeyState(int vKey);
    int GetDpiForSystem(void);
    int GetSystemMetrics(int nIndex);
]]
local user32 = ffi.load("user32")

-- DPI-������� Windows (4K, 150-200% � �.�.): UI ������������� ��� ��� ����������.
-- ������� ������� ���� �� ���������� / 1080, � DPI-������ ��������� ������ ����
-- ������� ���� ������ ����������� ������ (����/��������������� �����).
local dpiUi = 1.0
do
    local ok, dpi = pcall(function()
        return user32.GetDpiForSystem()
    end)
    if ok and type(dpi) == "number" and dpi > 0 then dpiUi = dpi / 96 end
    -- Диапазон 100%..350% (0.5..3.5) с шагом 25%
    if dpiUi < 0.5 then dpiUi = 0.5 elseif dpiUi > 3.5 then dpiUi = 3.5 end
end

-- ���������� 1, ���� ���� �������������, ����� ��������� DPI-������
local function uiDpiFactor()
    local _resH = select(2, getScreenResolution())
    if not _resH or _resH <= 0 then _resH = 1080 end
    local ok, sysH = pcall(function() return user32.GetSystemMetrics(1) end)
    if ok and type(sysH) == "number" and sysH > 0 then
        if sysH * dpiUi > _resH * 1.05 then
            return dpiUi
        end
    end
    return 1
end

-- ������� ���������� ��� ���������� ������ (��������� 4K � ������ ��������)
local _espScale = 1.0

-- ���������� �����, ���������������� ��� ������� ���������� ������
local function uiScaled(v)
    return v * _espScale
end

-- ���������� ESP-������ ��� ��������� ������� ������ (��������, ����� � 4K)
local function ensureEspScale()
    local _sw, _sh = getScreenResolution()
    _sh = _sh or 1080
    local _s = (_sh / 1080.0) * uiDpiFactor()
    if math.abs(_s - _espScale) > 0.01 then
        _espScale = _s
        font_whGreen = renderCreateFont('Arial', math.floor(7 * _s + 0.5), 13)
        font_dbg = renderCreateFont('Arial', math.floor(7 * _s + 0.5), 13)
    end
end

-- === �������: ��������� ���������� � ����������� ������ ===
local function safeReadMemory(addr, size, signed)
    -- �������� ��������� �� ���������� ����� �������
    if not addr or addr < 0x10000 or addr > 0x7FFFFFFF then
        return nil
    end
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

local function safeCall(func, ...)
    -- ���������� ����� ������� � ������������ ������
    local ok, result = pcall(func, ...)
    if not ok then
        dbg("ERROR in " .. tostring(func) .. ": " .. tostring(result))
    end
    return ok, result
end

local function logError(context, err)
    dbg("[ERROR] " .. context .. ": " .. tostring(err))
end

-- ���� � ����� ������������
local CONFIG_FILE = thisScript().directory .. "\\les_config.json"

-- ��������� ������������
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
    CarShowHP = true,
    CarShowModel = true,
    CarShowDoor = true,
    CarShowDriver = true,
    EspPickups = false,
    Aim = false,
    AimPlayers = false,
    Aim_Smoothing = 5.0,    -- ����������� (1-20)
    Aim_FOV = 3.0,          -- FOV ���� (�������)
    Aim_VisibleCheck = false, -- �������� ���������
    -- Human-like ���������
    Aim_Humanize = false,
    Aim_Jitter = 0.0,
    Aim_RandomDelay = 0,
    Aim_OffsetX = 0.0,
    Aim_OffsetY = 0.0,
    AutoY = false,
    AutoY_Sleep = 600,      -- ����� ����� ������� (��)
    AutoY_DownTime = 300,   -- ������������ ������� (��)
    Clear = false,
    ClearFol = false,
    DbgObjs = false,
    -- Triggerbot
    Triggerbot = false,
    Triggerbot_Delay = 50,
    Triggerbot_FOV = 2.0,
    -- NoRecoil / NoSpread
    NoRecoil = false,
    NoSpread = false,
    -- ������� ������� (VK ����)
    Key_Menu = 0x4C,        -- L - ����
    Key_AimToggle = 0x00,   -- �� ���������
    Key_EspToggle = 0x00,   -- �� ���������
}

-- �������� �������
local function loadConfig()
    local f = io.open(CONFIG_FILE, "r")
    if f then
        local content = f:read("*a")
        f:close()
        local ok, data = pcall(json.decode, content)
        if ok and data then
            return data
        end
    end
    return defaultConfig
end

-- ���������� �������
local function saveConfig(cfg)
    local f = io.open(CONFIG_FILE, "w")
    if f then
        f:write(json.encode(cfg))
        f:close()
        return true
    end
    return false
end

-- ���������� ������������ ������� � ������� Les
local function applyConfig(cfg)
    Les.Wh.v = cfg.Wh or false
    Les.WhPlayers.v = cfg.WhPlayers or false
    Les.HeadDot.v = cfg.HeadDot or false
    Les.ShowDistance.v = cfg.ShowDistance or false
    Les.DistAnimals.v = cfg.DistAnimals or 250.0
    Les.DistCars.v = cfg.DistCars or 0.0
    Les.DistPlayers.v = cfg.DistPlayers or 0.0
    Les.DistPickups.v = cfg.DistPickups or 0.0
    Les.LineAnimals.v = cfg.LineAnimals or false
    Les.LineCars.v = cfg.LineCars or false
    Les.LinePlayers.v = cfg.LinePlayers or false
    Les.LineCorpses.v = cfg.LineCorpses or false
    Les.EspTush.v = cfg.EspTush or false
    Les.EspCars.v = cfg.EspCars or false
    local _chp = cfg.CarShowHP
    if _chp == nil then _chp = true end
    Les.CarShowHP.v = _chp
    local _chm = cfg.CarShowModel
    if _chm == nil then _chm = true end
    Les.CarShowModel.v = _chm
    local _chd = cfg.CarShowDoor
    if _chd == nil then _chd = true end
    Les.CarShowDoor.v = _chd
    local _chdr = cfg.CarShowDriver
    if _chdr == nil then _chdr = true end
    Les.CarShowDriver.v = _chdr
    Les.Triggerbot.v = cfg.Triggerbot or false
    Les.Triggerbot_Delay.v = cfg.Triggerbot_Delay or 50
    Les.Triggerbot_FOV.v = cfg.Triggerbot_FOV or 2.0
    Les.NoRecoil.v = cfg.NoRecoil or false
    Les.NoSpread.v = cfg.NoSpread or false
    Les.EspPickups.v = cfg.EspPickups or false
    Les.Aim.v = cfg.Aim or false
    Les.AimPlayers.v = cfg.AimPlayers or false
    Les.Aim_Smoothing.v = cfg.Aim_Smoothing or 5.0
    Les.Aim_FOV.v = cfg.Aim_FOV or 3.0
    Les.Aim_VisibleCheck.v = cfg.Aim_VisibleCheck or false
    Les.Aim_Humanize.v = cfg.Aim_Humanize or false
    Les.Aim_Jitter.v = cfg.Aim_Jitter or 0.0
    Les.Aim_RandomDelay.v = cfg.Aim_RandomDelay or 0
    Les.Aim_OffsetX.v = cfg.Aim_OffsetX or 0.0
    Les.Aim_OffsetY.v = cfg.Aim_OffsetY or 0.0
    Les.AutoY.v = cfg.AutoY or false
    -- ��������� AutoY ����������� ��� �������� ������� (��. ����)
    Les.Clear.v = cfg.Clear or false
    Les.ClearFol.v = cfg.ClearFol or false
    Les.DbgObjs.v = cfg.DbgObjs or false
    -- ������� ������� �� ����������� ������������� (������ ��� ����������)
end

-- ���� �������� ��������� � ������� ��� ����������
local function gatherConfig()
    return {
        Wh = Les.Wh.v,
        WhPlayers = Les.WhPlayers.v,
        HeadDot = Les.HeadDot.v,
        ShowDistance = Les.ShowDistance.v,
        DistAnimals = Les.DistAnimals.v,
        DistCars = Les.DistCars.v,
        DistPlayers = Les.DistPlayers.v,
        DistPickups = Les.DistPickups.v,
        LineAnimals = Les.LineAnimals.v,
        LineCars = Les.LineCars.v,
        LinePlayers = Les.LinePlayers.v,
        LineCorpses = Les.LineCorpses.v,
        EspTush = Les.EspTush.v,
        EspCars = Les.EspCars.v,
        CarShowHP = Les.CarShowHP.v,
        CarShowModel = Les.CarShowModel.v,
        CarShowDoor = Les.CarShowDoor.v,
        CarShowDriver = Les.CarShowDriver.v,
        Triggerbot = Les.Triggerbot.v,
        Triggerbot_Delay = Les.Triggerbot_Delay.v,
        Triggerbot_FOV = Les.Triggerbot_FOV.v,
        NoRecoil = Les.NoRecoil.v,
        NoSpread = Les.NoSpread.v,
        EspPickups = Les.EspPickups.v,
        Aim = Les.Aim.v,
        AimPlayers = Les.AimPlayers.v,
        Aim_Smoothing = Les.Aim_Smoothing.v,
        Aim_FOV = Les.Aim_FOV.v,
        Aim_VisibleCheck = Les.Aim_VisibleCheck.v,
        Aim_Humanize = Les.Aim_Humanize.v,
        Aim_Jitter = Les.Aim_Jitter.v,
        Aim_RandomDelay = Les.Aim_RandomDelay.v,
        Aim_OffsetX = Les.Aim_OffsetX.v,
        Aim_OffsetY = Les.Aim_OffsetY.v,
        AutoY = Les.AutoY.v,
        AutoY_Sleep = waitWaitClickY.v,
        AutoY_DownTime = waitDownClickY.v,
        Clear = Les.Clear.v,
        ClearFol = Les.ClearFol.v,
        DbgObjs = Les.DbgObjs.v,
        Key_Menu = defaultConfig.Key_Menu,
        Key_AimToggle = defaultConfig.Key_AimToggle,
        Key_EspToggle = defaultConfig.Key_EspToggle,
    }
end

local function game_has_focus()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    return hwnd ~= nil and user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd
end


-- ����� (��������� ���������)
imgui.GetIO().Fonts:Clear()
local _fontCands = {
    'C:\\Windows\\Fonts\\segoeui.ttf',   -- Segoe UI, ���� �����
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

-- ??????
local ImVec2 = imgui.ImVec2
local ImVec4 = imgui.ImVec4
local ImGuiStyle = imgui.GetStyle()
local ImGuiColors = ImGuiStyle.Colors
local ImGuiClr = imgui.Col

-- ��������� AutoY (imgui.ImInt ��� GUI)
waitDownClickY = imgui.ImInt(300)
waitWaitClickY = imgui.ImInt(600)

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
local animalLastState = {}  -- ��������� �������� ��� Clear (������� + ����� ���������� ��������)
local menuActiveTab = 1 -- �������� ������� ���� (������ ������ �������)

-- ������� �������� (������ �� ID �������)
local _dbgScanAt = 0
local _dbgScreen = {}
local _dbgObjs = {}   -- ������� � ������� �����: {m=, x=, y=, z=, s=}
local _probeId = 613  -- ������� ID ������ ��� ����� (F6/F7)

-- �������� �������� (F8 ���/����, F9 ����� ����).
-- �������� ����� RPC 43 (RemoveBuildingForPlayer, samp.dll+0x12843), ������� ����������.
local _sweepRun = false
local _sweepCursor = 1
local _sweepBandW = 5
local _sweepLast = 0
local _sweepTotal = 0
local _sweepMin = 1
local _sweepMax = 1024
local _sweepBudget = 500

-- ����� "������" (����������: �������� �������, ������ �� �����, ������������� ��������)
local Clicker = {}
function Clicker:new(Button, Sleep, DownTime)
    local obj = {}
    obj.Button = Button
    obj.Sleep = Sleep or 600
    obj.DownTime = DownTime or 300
    obj.Allow = false
    obj.thread = nil
    obj.lastClick = 0
    obj.minInterval = 50  -- ���. �������� ����� ������� (��)

    function obj:Start()
        self.Allow = true
        self.thread = lua_thread.create(function()
            while self.Allow do
                if game_has_focus() then
                    local now = os.clock() * 1000
                    -- ��������: �� ������ �� ��� ������� (������ �� �������� �������)
                    local keyState = user32.GetAsyncKeyState(self.Button)
                    if keyState >= 0 then  -- ������� �� ������
                        -- ������ �� �����: ���. ��������
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
-- ������ ��������
local MODEL_DEER = 15555
local MODEL_BEAR = 15556

Les = {
    -- WH / ESP
    Wh = imgui.ImBool(false),          -- WH ��������
    WhPlayers = imgui.ImBool(false),   -- WH ������� ( ESP)
    HeadDot = imgui.ImBool(false),     -- ����� �� ������
    ShowDistance = imgui.ImBool(false),-- ���������
    -- ��������� ��������� (0 = ����������)
    DistAnimals = imgui.ImFloat(250.0),-- ��������� �� ��������
    DistCars    = imgui.ImFloat(0.0),  -- ��������� �� ������� (���)
    DistPlayers = imgui.ImFloat(0.0),  -- ��������� �� ������� (���)
    DistPickups = imgui.ImFloat(0.0),  -- ��������� �� ������� (���)
    -- ����� � ����
    LineAnimals = imgui.ImBool(false), -- ����� � ��������
    LineCars = imgui.ImBool(false),    -- ����� � �������
    LinePlayers = imgui.ImBool(false), -- ����� � �������
    LineCorpses = imgui.ImBool(false),
    -- ESP
    EspTush = imgui.ImBool(false),     -- WH ������ (������� + ����� + ���������)
    EspCars = imgui.ImBool(false),     -- WH �����
    CarShowHP = imgui.ImBool(true),      -- HP � �����
    CarShowModel = imgui.ImBool(true),   -- ������ � �����
    CarShowDoor = imgui.ImBool(true),    -- ����� � �����
    CarShowDriver = imgui.ImBool(true),  -- �������� � �����
    EspPickups = imgui.ImBool(false),  -- ESP �������/���������
    -- ���
    Aim = imgui.ImBool(false),         -- ��� �� ��������
    AimPlayers = imgui.ImBool(false),  -- ��� �� �������
    Aim_silent = imgui.ImBool(false),
    AimHandle = nil,
    -- ��������� ����
    Aim_Smoothing = imgui.ImFloat(5.0),    -- ����������� (1-20, ������ = �������)
    Aim_FOV = imgui.ImFloat(3.0),          -- FOV ���� (�������)
    Aim_VisibleCheck = imgui.ImBool(false), -- �������� ��������� (LOS)
    -- Human-like ���������
    Aim_Humanize = imgui.ImBool(false),       -- ���������������� ���������
    Aim_Jitter = imgui.ImFloat(0.0),          -- �������� ������� (0-1.0)
    Aim_RandomDelay = imgui.ImInt(0),         -- ��������� �������� (��)
    Aim_OffsetX = imgui.ImFloat(0.0),         -- ��������� �������� X
    Aim_OffsetY = imgui.ImFloat(0.0),         -- ��������� �������� Y
    -- ����
    AutoY = imgui.ImBool(false),
    AutoY_Clicker = nil,  -- �������� � main() ����� �������� �������
    Clear = imgui.ImBool(false),       -- �������� ���������� �������� (20 ���)
    ClearFol = imgui.ImBool(false),    -- �������� ������/��������
    DbgObjs = imgui.ImBool(false),     -- ������� �������� ���������
    -- Triggerbot
    Triggerbot = imgui.ImBool(false),       -- ���������� (������������ ��� ���������)
    Triggerbot_Delay = imgui.ImInt(50),     -- �������� ����� ��������� (��)
    Triggerbot_FOV = imgui.ImFloat(2.0),    -- FOV ����������� (�������)
    -- NoRecoil / NoSpread
    NoRecoil = imgui.ImBool(false),         -- ��� ������
    NoSpread = imgui.ImBool(false),         -- ��� ��������
    FolApplied = false,
    FolBldTimer = 0,
    FolTimer = 0,                      -- ������ ��� ���������� ���������� ClearFol
    FirstApplied = false,
    LastTargetHandle = nil,
}

-- ����� �������� ��� ������ �������� ����
Les.Wh.v = false
Les.WhPlayers.v = false
Les.HeadDot.v = false
Les.ShowDistance.v = false
Les.LineAnimals.v = false
Les.LineCars.v = false
Les.LinePlayers.v = false
Les.EspTush.v = false
Les.EspCars.v = false
Les.CarShowHP.v = true
Les.CarShowModel.v = true
Les.CarShowDoor.v = true
Les.CarShowDriver.v = true
Les.Aim.v = false
Les.AimPlayers.v = false
Les.AutoY.v = false
Les.Clear.v = false
Les.ClearFol.v = false
Les.DbgObjs.v = false
Les.FirstApplied = false

function imgui_Menu_windowState(arg)
    Menu.windowState.v = not Menu.windowState.v
    imgui.ShowCursor = Menu.windowState.v
    if Menu.windowState.v and not Les.FirstApplied then
        Les.FirstApplied = true
        Les.Wh.v = true
        Les.EspTush.v = true
        Les.HeadDot.v = true
        Les.ShowDistance.v = true
        Les.Aim.v = true
        Les.AutoY.v = true
        Les.Clear.v = true
    end
end

-- ������� �������
function main()
    if not isSampLoaded() or not isSampfuncsLoaded then return end
    while not isSampAvailable() do wait(100) end

    -- �������� ������������
    local cfg = loadConfig()
    applyConfig(cfg)

    -- ������ ������ AutoY � ����������� �� �������
    Les.AutoY_Clicker = Clicker:new(vkeys.VK_Y, cfg.AutoY_Sleep or 600, cfg.AutoY_DownTime or 300)

    sampRegisterChatCommand("les", imgui_Menu_windowState)
    sampRegisterChatCommand("lesr", function()
        thisScript():reload()
    end)

    local okY, yw = pcall(require, "ywelcome")
    if okY and type(yw) == "function" then
        yw("Les", "����������� ������ L ���� /les")
    end

    -- ��������� ������� L: ������� ������� - �������/�������, ��������� 0.5 ��� - �������
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
                -- ������� �������
                if menuOpen then
                    -- ���� ������� -> ������� ����
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                    fired = true
                    hold_start = 0
                else
                    -- ���� ������� -> �������� ����� ���������
                    hold_start = os.clock()
                    fired = false
                end
            elseif down and prev_down then
                -- ��������� �������
                if not menuOpen and not fired and hold_start > 0 and (os.clock() - hold_start) >= 0.5 then
                    fired = true
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                end
            else
                -- ���������� �������
                hold_start = 0
                fired = false
            end
            prev_down = down
        end
    end)

    -- ������� ������� �������: F6/F7 - ����� ID, F8 - ������/������� �����, F9 - ����� ����.
    -- �������� �������� ����� RPC 43 (����������).
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
            if Les.DbgObjs.v and game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
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
            -- ��������: ������ 0.4 ��� ���������� RPC 43 ��� ����� ID
            if _sweepRun and Les.DbgObjs.v and (os.clock() - _sweepLast) >= 0.4 then
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

    -- ������ ��� �������
    font_whGreen = renderCreateFont('Arial', 7, 13)

    -- ����� ��� �������
    font_dbg = renderCreateFont('Arial', 7, 13)

    imgui.Process = true
    imgui.ShowCursor = false

    -- ��������� ������� ������ ��� ������, ���� ��������
    if Les.ClearFol.v then
        pcall(applyFoliageClear)
    end

    while true do
        wait(0)

        -- �������� ����� ������������ ������
        local sw, sh = getScreenResolution()
        ensureEspScale()
        local playerX, playerY, playerZ = getCharCoordinates(playerPed)
        local playerScreenX, playerScreenY = convert3DCoordsToScreen(playerX, playerY, playerZ)

        -- === ���� ������ �� ���� ���������� ===
        local animals = {}      -- ����� ��������
        local players = {}      -- ����� ������
        local deadAnimals = {}  -- ̸����� ��������
        local aimCandidates = {} -- ��������� ��� ����

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
                            nick = sampGetPlayerNickname(pid) or "�����"
                        })
                    end
                else
                    -- ̸�����
                    if isAnimal then
                        table.insert(deadAnimals, {
                            handle = value, modelid = modelid, posX = posX, posY = posY, posZ = posZ,
                            headX = hxx, headY = hyy, okHead = okHead
                        })
                    end
                end

                -- ��������� ��� ���� (���� �������������)
                if (Les.Aim.v and isAnimal) or (Les.AimPlayers.v and isPlayer) then
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

        -- ������ ESP (�����/������/������/������)
        if Les.EspTush.v and type(renderEspTush) == "function" then pcall(renderEspTush) end
        if Les.EspCars.v and type(renderEspCars) == "function" then pcall(renderEspCars) end
        if Les.WhPlayers.v and type(renderEspPlayers) == "function" then pcall(renderEspPlayers) end
        if Les.EspPickups.v and type(renderEspPickups) == "function" then pcall(renderEspPickups) end
        if Les.ClearFol.v then
            if not Les.FolApplied then
                Les.FolApplied = true
                Les.FolTimer = os.clock()
                Les.FolBldTimer = 0
                pcall(applyFoliageClear)
            elseif (os.clock() - (Les.FolTimer or 0)) > 2.0 then
                Les.FolTimer = os.clock()
                pcall(applyFoliageClear)
            end
            -- ������� ��������/������ ����� RPC 43 (������ 5 ���)
            if (os.clock() - (Les.FolBldTimer or 0)) > 5.0 then
                Les.FolBldTimer = os.clock()
                pcall(sendRemoveBuildingRPCs)
            end
        else
            if Les.FolApplied or next(_folHidden) ~= nil then
                Les.FolApplied = false
                pcall(restoreFoliage)
            end
        end

        -- ������� �������� (��� � 1.5 ���)
        if Les.DbgObjs.v then
            if (os.clock() - _dbgScanAt) > 1.5 then
                _dbgScanAt = os.clock()
                dbg('--- ���� ����� �������� ---')
                pcall(dbgObjectsScan)
            end
            pcall(dbgObjectsRender)
            renderFontDrawText(font_dbg, '������� ID: ' .. _probeId .. '  (F6 - / F7 +)', uiScaled(12), uiScaled(105), 0xFFFF66FF)
            if _sweepRun then
                local _bs = math.floor((_sweepCursor - 1) / _sweepBandW) * _sweepBandW + 1
                local _be = math.min(_bs + _sweepBandW - 1, _sweepMax)
                renderFontDrawText(font_dbg, string.format('��������: ID %d-%d (F8 ����, F9 ���=%d) ������=%d',
                    _bs, _be, _sweepBandW, _sweepCursor), uiScaled(12), uiScaled(118), 0xFF66FF00)
            else
                renderFontDrawText(font_dbg, string.format('�������� ���������� (F8 ������, ���=%d, F9 �����)', _sweepBandW), uiScaled(12), uiScaled(118), 0xFF66FF00)
            end
            local _sw, _sh = getScreenResolution()
            for _i, _line in ipairs(_dbgScreen) do
                renderFontDrawText(font_dbg, _line, uiScaled(12) + ((_i - 1) % 2) * uiScaled(330), uiScaled(130) + math.floor((_i - 1) / 2) * uiScaled(13), 0xFFFFFF00)
            end
        end

        -- WH �������� + ����� + ������ (���������� ������������� �������)
        local shouldRenderAimExtras = (doesCharExist(Les.AimHandle) and Les.AimHandle ~= nil)

        if Les.Wh.v or Les.LineAnimals.v or Les.WhPlayers.v or Les.LinePlayers.v or Les.HeadDot.v or Les.ShowDistance.v then
            -- ��������
            for _, a in ipairs(animals) do
                if a.okScreen and (Les.DistAnimals.v <= 0 or a.dist <= Les.DistAnimals.v) then
                    if Les.Wh.v then
                        if a.modelid == MODEL_DEER then
                            if a.health == 100 then
                                renderFontDrawText(font_whGreen, '�����(3)', a.screenX, a.screenY, 0xFF00FF00)
                            elseif a.health == 65 then
                                renderFontDrawText(font_whGreen, '�����(2)', a.screenX, a.screenY, 0xFFFF9D00)
                            elseif a.health == 30 then
                                renderFontDrawText(font_whGreen, '�����(1)', a.screenX, a.screenY, 0xFFFF0000)
                            end
                        elseif a.modelid == MODEL_BEAR then
                            if a.health == 100 then
                                renderFontDrawText(font_whGreen, '�������(7)', a.screenX, a.screenY, 0xFF00FF00)
                            elseif a.health == 85 then
                                renderFontDrawText(font_whGreen, '�������(6)', a.screenX, a.screenY, 0xFF55E100)
                            elseif a.health == 70 then
                                renderFontDrawText(font_whGreen, '�������(5)', a.screenX, a.screenY, 0xFFAAC300)
                            elseif a.health == 55 then
                                renderFontDrawText(font_whGreen, '�������(4)', a.screenX, a.screenY, 0xFFFFA500)
                            elseif a.health == 40 then
                                renderFontDrawText(font_whGreen, '�������(3)', a.screenX, a.screenY, 0xFFFF6E00)
                            elseif a.health == 25 then
                                renderFontDrawText(font_whGreen, '�������(2)', a.screenX, a.screenY, 0xFFFF3700)
                            elseif a.health == 10 then
                                renderFontDrawText(font_whGreen, '�������(1)', a.screenX, a.screenY, 0xFFFF0000)
                            end
                        end
                        -- ����� � ��������
                        if Les.LineAnimals.v and not shouldRenderAimExtras and a.okHead then
                            renderDrawLine(sw/2, sh/2, a.headX, a.headY, 1.0, 0xFFFFFF00)
                        end
                    end
                    -- ����� �� ������
                    if Les.HeadDot.v and a.okHead then
                        renderDrawBoxWithBorder(a.headX, a.headY, 3, 3, 0xFF00FF00, 1, 0xFF00FF00)
                    end
                    -- ���������
                    if Les.ShowDistance.v and Les.Wh.v then
                        renderFontDrawText(font_whGreen, string.format("%.0f �", a.dist), a.screenX, a.screenY - uiScaled(10), 0xFFFFFFFF)
                    end
                end
            end

            -- ������
            for _, p in ipairs(players) do
                if p.okScreen and (Les.DistPlayers.v <= 0 or p.dist <= Les.DistPlayers.v) then
                    if Les.WhPlayers.v then
                        renderFontDrawText(font_whGreen, p.nick or "�����", p.screenX, p.screenY, 0xFF00CCFF)
                    end
                    if Les.LinePlayers.v and not shouldRenderAimExtras and p.okHead then
                        renderDrawLine(sw/2, sh/2, p.headX, p.headY, 1.0, 0xFF00CCFF)
                    end
                    if Les.HeadDot.v and p.okHead then
                        renderDrawBoxWithBorder(p.headX, p.headY, 3, 3, 0xFF00FF00, 1, 0xFF00FF00)
                    end
                    if Les.ShowDistance.v and Les.WhPlayers.v then
                        renderFontDrawText(font_whGreen, string.format("%.0f �", p.dist), p.screenX, p.screenY - uiScaled(10), 0xFFFFFFFF)
                    end
                end
            end
        end

        -- ����� � ������ ��������
        if Les.LineCorpses.v then
            for _, d in ipairs(deadAnimals) do
                if d.okHead then
                    renderDrawLine(sw/2, sh/2, d.headX, d.headY, 2.0, 0xFF0000FF)
                    local _cdist = math.sqrt((d.posX-playerX)^2 + (d.posY-playerY)^2 + (d.posZ-playerZ)^2)
                    renderFontDrawText(font_whGreen, string.format("���� %.0f�", _cdist), d.headX + uiScaled(8), d.headY - uiScaled(8), 0xFF0000FF)
                end
            end
        end

        -- �������� ���������� �������� (20 ��� ��� ��������)
        if Les.Clear.v then
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

-- ��� (������������): ����������� ������ ������������
        local camMode = safeReadMemory(0xB6F1A8, 1, false)
        local aiming = camMode and (camMode == 53 or camMode == 55 or camMode == 7 or camMode == 8)
        -- �������� �� spectator mode (������ 46 = spectator)
        local isSpectator = camMode and (camMode == 46 or camMode == 47)
        local aimAnimals = Les.Aim.v and not isSpectator
        local aimPlayers = Les.AimPlayers.v and not isSpectator
        local smoothing = Les.Aim_Smoothing.v
        local aimFOV = Les.Aim_FOV.v
        local visibleCheck = Les.Aim_VisibleCheck.v
        -- Human-like ���������
        local humanize = Les.Aim_Humanize.v
        local jitter = Les.Aim_Jitter.v
        local randomDelay = Les.Aim_RandomDelay.v
        local offsetX = Les.Aim_OffsetX.v
        local offsetY = Les.Aim_OffsetY.v
        -- ��� ������������ ��������
        if not Les._aimLastShot then Les._aimLastShot = 0 end

        if aiming and (aimAnimals or aimPlayers) then
            local width, heigth = getScreenResolution()
            local fov = getCameraFov() * 0.0174530
            local coeficent = width / fov
            -- FOV ����� �� ��������
            local distance = (aimFOV * 0.0174530) * coeficent
            local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)

            -- ������ FOV ����� �������
            renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)

            local candidates = {}
            local maxScreenDist = 0
            local max3DDist = 0

            -- ���������� ������������� ����������
            for _, c in ipairs(aimCandidates) do
                local isAn = c.isAnimal
                local isPl = c.isPlayer
                if (aimAnimals and isAn) or (aimPlayers and isPl) then
                    local wposX, wposY = c.headScreenX, c.headScreenY
                    local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)
                    if inBox then
                        -- �������� ��������� (Line of Sight)
                        local canSee = true
                        if visibleCheck then
                            local px, py, pz = getCharCoordinates(playerPed)
                            local tx, ty, tz = c.posX, c.posY, c.posZ
                            canSee = isLineOfSightClear(px, py, pz, tx, ty, tz, true, false, false, true, false, false, false)
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
                    Les.AimHandle = cand[1]
                end
            end
        elseif aiming and (Les.AimHandle ~= nil) then
            if aimAnimals or aimPlayers then
                local width, heigth = getScreenResolution()
                local fov = getCameraFov() * 0.0174530
                local coeficent = width / fov
                local distance = (aimFOV * 0.0174530) * coeficent
                local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)
                local x, y, z = GetBodyPartCoordinates(8, Les.AimHandle)
                local wposX, wposY = convert3DCoordsToScreen(x, y, z)

                renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)
                local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)
                
                -- �������� ��������� ��� ��������� ����
                local canSee = true
                if visibleCheck then
                    local px, py, pz = getCharCoordinates(playerPed)
                    local tx, ty, tz = getCharCoordinates(Les.AimHandle)
                    canSee = isLineOfSightClear(px, py, pz, tx, ty, tz, true, false, false, true, false, false, false)
                end
                
                if inBox and doesCharExist(Les.AimHandle) and isCharOnScreen(Les.AimHandle) and canSee then
                    -- ���������� ������������ (smoothing)
                    local cx, cy, cz = getActiveCameraCoordinates()
                    local targetX, targetY, targetZ = x, y, z
                    
                    -- ��������� ������ ���� ������
                    local vect = {fX = cx - targetX, fY = cy - targetY, fZ = cz - targetZ}
                    local screenAspectRatio = safeReadFloat(0xC3EFA4)
                    local crosshairOffset = {
                        safeReadFloat(0xB6EC10),
                        safeReadFloat(0xB6EC14)
                    }
                    -- Fallback �������� ���� ������ ������ �� �������
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
                    
                    -- �����������: ������������� ������� ���� � �������
                    local currentAz = safeReadFloat(0xB6F178) -- Z rotation ������
                    local currentFx = safeReadFloat(0xB6F17C) -- X rotation ������
                    if not currentAz then currentAz = finalAz end
                    if not currentFx then currentFx = finalFx end
                    
                    local smoothFactor = 1.0 / math.max(smoothing, 1.0)
                    finalAz = currentAz + (finalAz - currentAz) * smoothFactor
                    finalFx = currentFx + (finalFx - currentFx) * smoothFactor
                    
                    -- Human-like ������������
                    if humanize then
                        -- ��������� �������� (jitter)
                        if jitter > 0 then
                            finalAz = finalAz + (math.random() - 0.5) * jitter * 0.01
                            finalFx = finalFx + (math.random() - 0.5) * jitter * 0.01
                        end
                        -- ��������� �������� offset
                        if offsetX ~= 0 then
                            finalAz = finalAz + (math.random() - 0.5) * offsetX * 0.01
                        end
                        if offsetY ~= 0 then
                            finalFx = finalFx + (math.random() - 0.5) * offsetY * 0.01
                        end
                        -- ��������� �������� ����� ����������
                        if randomDelay > 0 then
                            local now = os.clock()
                            if now - Les._aimLastShot < (randomDelay / 1000) then
                                -- �� ��������, ���
                            else
                                Les._aimLastShot = now
                            end
                        end
                    end
                    
                    setCameraPositionUnfixed(finalAz, finalFx)
                end
                if not doesCharExist(Les.AimHandle) then
                    Les.AimHandle = nil
                end
            else
                Les.AimHandle = nil
            end
        else
            Les.AimHandle = nil
        end

        if Les.LastTargetHandle ~= Les.AimHandle then
            Les.LastTargetHandle = Les.AimHandle
        end

        -- Triggerbot: ������������ ��� ��������� �� ����
        if Les.Triggerbot.v and aiming then
            local target = Les.AimHandle
            if target and doesCharExist(target) and isCharOnScreen(target) then
                local hx, hy, hz = GetBodyPartCoordinates(8, target)
                local hxx, hyy = convert3DCoordsToScreen(hx, hy, hz)
                local width, height = getScreenResolution()
                local crosshairX, crosshairY = width / 2, height / 2
                local dist = math.sqrt((hxx - crosshairX)^2 + (hyy - crosshairY)^2)
                local fovRadius = (Les.Triggerbot_FOV.v * 0.0174530) * (width / (getCameraFov() * 0.0174530))
                if dist <= fovRadius then
                    -- �������� ����� ���������
                    if not Les._triggerbotTimer then Les._triggerbotTimer = 0 end
                    if os.clock() - Les._triggerbotTimer >= (Les.Triggerbot_Delay.v / 1000) then
                        setGameKeyState(16, -128) -- VK_LBUTTON down
                        wait(10)
                        setGameKeyState(16, 0) -- VK_LBUTTON up
                        Les._triggerbotTimer = os.clock()
                    end
                end
            end
        end

        -- NoRecoil / NoSpread
        if Les.NoRecoil.v or Les.NoSpread.v then
            -- NoRecoil: �������� �������� ������ ��� ��������
            if Les.NoRecoil.v then
                -- ����� ����������� ����� ������ � ������ ��� ��������� �������
            end
            -- NoSpread: ��������� ������� ����
            if Les.NoSpread.v then
                -- ����� ����������� ����� ��� �� �������
            end
        end

        -- ������
        if not Menu.windowState.v then
            imgui.ShowCursor = false
        else
            imgui.ShowCursor = true
        end
    end
end

-- GUI � ���������
function imgui.OnDrawFrame()
    local sw, sh = getScreenResolution()
    fsc = (sh / 1080) * uiDpiFactor()
    imgui.GetIO().FontGlobalScale = fsc
    if Menu.windowState.v then
        apply_custom_style()

        local mainWidth = 730 * fsc
        local mainHeight = 620 * fsc
        imgui.SetNextWindowSize(ImVec2(mainWidth, mainHeight), imgui.Cond.Always)
        imgui.SetNextWindowPos(ImVec2(sw / 2, sh / 2), imgui.Cond.Always, ImVec2(0.5, 0.5))

        imgui.Begin(u8'Les by YaroRage', Menu.windowState, imgui.WindowFlags.NoResize)
            imgui.TextColored(imgui.ImVec4(0.30, 0.90, 0.35, 1.0), u8"Les By YaroRage")
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.60, 0.60, 0.60, 1.0))
            imgui.Text(u8"Les - ESP, ���, ���� Y")
            imgui.PopStyleColor(1)
            imgui.Separator()

            -- �������: ���� ������, ���������� ������
            if imgui.Button(u8"WH / ESP", ImVec2(140 * fsc, 20 * fsc)) then menuActiveTab = 1 end
            imgui.SameLine()
            if imgui.Button(u8"���", ImVec2(140 * fsc, 20 * fsc)) then menuActiveTab = 2 end
            imgui.SameLine()
            if imgui.Button(u8"�������", ImVec2(140 * fsc, 20 * fsc)) then menuActiveTab = 3 end
            imgui.SameLine()
            if imgui.Button(u8"������� ������.", ImVec2(140 * fsc, 20 * fsc)) then menuActiveTab = 4 end
            imgui.SameLine()
            if imgui.Button(u8"�������", ImVec2(140 * fsc, 20 * fsc)) then menuActiveTab = 5 end
            imgui.Separator()
                -- ������� WH / ESP
                if menuActiveTab == 1 then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"��������� Wallhack / ESP")
                    imgui.Separator()

                    if imgui.Checkbox(u8"WH ��������", Les.Wh) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"���������� �������� �������� (����� 3-1, ������� 7-1)") end

                    if imgui.Checkbox(u8"WH �����", Les.EspTush) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"������� + ����� + ��������� �� ������� ��������") end

                    if imgui.Checkbox(u8"WH ������", Les.EspCars) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"�������� + �������� + ��������� ����������") end
                    if Les.EspCars.v then
                        imgui.SameLine()
                        imgui.Text(u8"�����:")
                        if imgui.Checkbox(u8"HP", Les.CarShowHP) then end
                        imgui.SameLine()
                        if imgui.Checkbox(u8"������", Les.CarShowModel) then end
                        imgui.SameLine()
                        if imgui.Checkbox(u8"�����", Les.CarShowDoor) then end
                        imgui.SameLine()
                        if imgui.Checkbox(u8"��������", Les.CarShowDriver) then end
                    end

                    if imgui.Checkbox(u8"WH ������", Les.WhPlayers) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"��� + �������� + ����� + ������ + ���������") end

                    if imgui.Checkbox(u8"ESP ������/��������", Les.EspPickups) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"����������� �������, ������, ��������, ����� �� �����") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"����� � ����:")

                    if imgui.Checkbox(u8"����� � ��������", Les.LineAnimals) then end
                    if imgui.Checkbox(u8"����� � �������", Les.LineCars) then end
                    if imgui.Checkbox(u8"����� � �������", Les.LinePlayers) then end
                    if imgui.Checkbox(u8"����� � ������", Les.LineCorpses) then end


                    imgui.Separator()
                    if imgui.Checkbox(u8"����� �� ������", Les.HeadDot) then end
                    if imgui.Checkbox(u8"���������", Les.ShowDistance) then end
                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"��������� (0 = ����������):")
                    if imgui.SliderFloat(u8"��������, �", Les.DistAnimals, 0.0, 500.0, '%.0f') then Les.DistAnimals.v = math.floor(Les.DistAnimals.v + 0.5) end
                    if imgui.SliderFloat(u8"������, �", Les.DistCars, 0.0, 500.0, '%.0f') then Les.DistCars.v = math.floor(Les.DistCars.v + 0.5) end
                    if imgui.SliderFloat(u8"������, �", Les.DistPlayers, 0.0, 500.0, '%.0f') then Les.DistPlayers.v = math.floor(Les.DistPlayers.v + 0.5) end
                    if imgui.SliderFloat(u8"������, �", Les.DistPickups, 0.0, 500.0, '%.0f') then Les.DistPickups.v = math.floor(Les.DistPickups.v + 0.5) end
                end

                -- ������� ���
                if menuActiveTab == 2 then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"��������� ����������������")
                    imgui.Separator()

                    if imgui.Checkbox(u8"��� �� ��������", Les.Aim) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"���������������� �� ������ �������� ��� ������������") end

                    if imgui.Checkbox(u8"��� �� �������", Les.AimPlayers) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"���������������� �� ������ ������� ��� ������������") end

                    if imgui.SliderFloat(u8"����������� (1-20)", Les.Aim_Smoothing, 1.0, 20.0, '%.1f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"��� ������ ��������, ��� ������� �������� �������") end

                    if imgui.SliderFloat(u8"FOV ���� (�������)", Les.Aim_FOV, 0.5, 10.0, '%.1f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"���� ������� ���� ������ �������") end

                    if imgui.Checkbox(u8"�������� ��������� (LOS)", Les.Aim_VisibleCheck) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"�� �������� ����� �����/�������") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- Human-like (�������) ---")
                    if imgui.Checkbox(u8"���������������� ���������", Les.Aim_Humanize) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"�������� ������������ ��� ������ ��������") end

                    if imgui.SliderFloat(u8"�������� (Jitter)", Les.Aim_Jitter, 0.0, 1.0, '%.2f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� �������� ������� (0-1.0)") end

                    if imgui.SliderInt(u8"��������� �������� (��)", Les.Aim_RandomDelay, 0, 500) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ����� ����� ��������������� �������") end

                    if imgui.SliderFloat(u8"�������� X", Les.Aim_OffsetX, -1.0, 1.0, '%.2f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� �������������� �������� �������") end

                    if imgui.SliderFloat(u8"�������� Y", Les.Aim_OffsetY, -1.0, 1.0, '%.2f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"��������� ������������ �������� �������") end

                end

                -- ������� ����
                if menuActiveTab == 3 then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"�������������� �������")
                    imgui.Separator()

                    if imgui.Checkbox(u8"���� Y", Les.AutoY) then
                        if not Les.AutoY.v then
                            Les.AutoY_Clicker:Stop()
                        end
                    end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"������������� �������� Y ��� ����-���� (����������)") end

                    if imgui.SliderInt(u8"����� ����� ������� (��)", waitWaitClickY, 100, 2000) then
                        if Les.AutoY_Clicker then Les.AutoY_Clicker.Sleep = waitWaitClickY.v end
                    end
                    if imgui.SliderInt(u8"������������ ������� (��)", waitDownClickY, 50, 1000) then
                        if Les.AutoY_Clicker then Les.AutoY_Clicker.DownTime = waitDownClickY.v end
                    end

                    if imgui.Checkbox(u8"������� ���������� ������ (20 �)", Les.Clear) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"������� ��������, �� ����������� 20 ������") end

                    if imgui.Checkbox(u8"������� ������/�������", Les.ClearFol) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"�������� �������/������ ������ ������ (���� ����!)") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- Triggerbot ---")
                    if imgui.Checkbox(u8"����������", Les.Triggerbot) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"�������������� ������� ��� ��������� ������� �� ����") end
                    if imgui.SliderInt(u8"�������� �������� (��)", Les.Triggerbot_Delay, 0, 500) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"����������� �������� ����� ����������") end
                    if imgui.SliderFloat(u8"FOV �����������", Les.Triggerbot_FOV, 0.5, 5.0, '%.1f') then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"���� ������� ���� ��� ������������") end

                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- NoRecoil / NoSpread ---")
                    if imgui.Checkbox(u8"��� ������ (NoRecoil)", Les.NoRecoil) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"������� ������ �� ������ (����������������)") end
                    if imgui.Checkbox(u8"��� �������� (NoSpread)", Les.NoSpread) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"������� ������� ���� (����������������)") end

                end

                -- ������� ������� �������
                if menuActiveTab == 4 then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"��������� ������� ������")
                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"������� �� ���� � �������� �������:")
                    imgui.Separator()

                    -- ��� �������� ���������� ������� VK ����
                    imgui.Text(u8"���� (�������/�������): L (0x4C)")
                    imgui.Text(u8"������� ��������: F6/F7 (ID), F8 (����), F9 (���)")
                    imgui.Text(u8"���: �������� ��� ������������ (���)")
                    
                    imgui.Separator()
                    imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"VK ���� ���������� ������:")
                    imgui.Text(u8"L = 0x4C  |  F1-F12 = 0x70-0x7B  |  Insert = 0x2D")
                    imgui.Text(u8"Home = 0x24  |  End = 0x23  |  PageUp = 0x21  |  PageDown = 0x22")
                    imgui.Text(u8"Numpad 0-9 = 0x60-0x69  |  NumLock = 0x90")
                    
                end

                -- ������� �������
                if menuActiveTab == 5 then
                    imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"����������� �������")
                    imgui.Separator()

                    if imgui.Checkbox(u8"������� ��������", Les.DbgObjs) then end
                    if imgui.IsItemHovered() then imgui.SetTooltip(u8"������ ID ������� ���������, ��� � les_dbg.txt (F6/F7 ID, F8 ����)") end

                    imgui.Separator()
                    if imgui.Button(u8"��������� ������", ImVec2(-1, 25)) then
                        saveConfig(gatherConfig())
                        print("[Les] ������ ��������")
                    end
                    imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.55, 1.0), u8"/les - ����, /lesr - ������������")
                end

        imgui.End()
    end
    -- �������������� ��� �������� ����
    if not Menu.windowState.v and Les.FirstApplied then
        saveConfig(gatherConfig())
        Les.FirstApplied = false
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

-- ������ ������� ��������� (��� ESP ������)
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

-- WH �����: ������� + ����� + ��������� + ����
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
                    local animalName = (m == MODEL_DEER) and "�����" or "�������"
                    renderFontDrawText(font_whGreen, animalName .. " (����)", X, Y, 0xFFFF0000)
                    renderFontDrawText(font_whGreen, string.format("%.0f �", d), X, Y - uiScaled(10), 0xFFFFAAAA)
                    -- ����� � ������ �����
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

-- WH ������: ��� + �������� + ����� + ������ + ���������
function renderEspPlayers()
    if not Les.WhPlayers.v or type(getAllChars) ~= "function" then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, v in pairs(getAllChars()) do
        if doesCharExist(v) and v ~= PLAYER_PED and isCharOnScreen(v) then
            local isPlayer = false
            local resPid, pid = sampGetPlayerIdByCharHandle(v)
            if not resPid then goto continue end
            isPlayer = true
            
            local posX, posY, posZ = getCharCoordinates(v)
            local _X, _Y = convert3DCoordsToScreen(posX, posY, posZ)
            local dist = math.sqrt((posX - px)^2 + (posY - py)^2 + (posZ - pz)^2)
            
            if Les.DistPlayers.v > 0 and dist > Les.DistPlayers.v then goto continue end
            
            if _X and _Y and _X > -50 and _X < 8050 and _Y > -50 and _Y < 6050 then
                local health = getCharHealth(v)
                local armor = getCharArmour(v)
                local weapon = getCurrentCharWeapon(v)
                local weaponName = getWeaponName(weapon)
                local nick = sampGetPlayerNickname(pid) or "Unknown"
                
                local healthColor = 0xFF00FF00
                if health < 50 then healthColor = 0xFFFF0000 end
                if health < 20 then healthColor = 0xFFFF0000 end
                
                local yOffset = 0
                renderFontDrawText(font_whGreen, nick, _X, _Y + yOffset, 0xFF00CCFF); yOffset = yOffset + uiScaled(12)
                renderFontDrawText(font_whGreen, "HP: " .. health, _X, _Y + yOffset, healthColor); yOffset = yOffset + uiScaled(12)
                if armor > 0 then
                    renderFontDrawText(font_whGreen, "AP: " .. armor, _X, _Y + yOffset, 0xFF00AAFF); yOffset = yOffset + uiScaled(12)
                end
                renderFontDrawText(font_whGreen, weaponName, _X, _Y + yOffset, 0xFFFFFFFF); yOffset = yOffset + uiScaled(12)
                renderFontDrawText(font_whGreen, string.format("%.0f �", dist), _X, _Y + yOffset, 0xFFFFAAAA)
                
                -- ����� � ������
                if Les.LinePlayers.v then
                    local hx, hy, hz = GetBodyPartCoordinates(8, v)
                    local hX, hY = convert3DCoordsToScreen(hx, hy, hz)
                    local sw, sh = getScreenResolution()
                    if hX and hY then
                        renderDrawLine(sw/2, sh/2, hX, hY, 1.0, 0xFF00CCFF)
                    end
                end
            end
            ::continue::
        end
    end
end

-- ���������������: �������� ������ �� ID
function getWeaponName(id)
    local names = {
        [0] = "������", [1] = "�������", [2] = "�����", [3] = "���", [4] = "������", [5] = "���������",
        [6] = "��������", [7] = "�������� � ����.", [8] = "������ ���", [9] = "��������", [10] = "�����",
        [11] = "����-12", [12] = "���", [13] = "��5", [14] = "��-47", [15] = "�4", [16] = "���-9",
        [17] = "�����", [18] = "���������", [19] = "���", [20] = "���������", [21] = "������",
        [22] = "�������", [23] = "�������", [24] = "���", [25] = "������", [26] = "�������� (������)",
        [27] = "�������� (������)", [28] = "��������� (������)", [29] = "����", [30] = "������",
        [31] = "�������", [32] = "�����������", [33] = "�������", [34] = "�����", [35] = "�������",
        [36] = "�����", [37] = "����", [38] = "�����", [39] = "����", [40] = "����������",
        [41] = "�������", [42] = "���������", [43] = "����", [44] = "����", [45] = "���������",
        [46] = "������", [47] = "������"
    }
    return names[id] or ("������ " .. id)
end

-- ESP ������/�������� �� �����
function renderEspPickups()
    if not Les.EspPickups.v or type(getAllPickups) ~= "function" then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    for _, pickup in pairs(getAllPickups()) do
        if doesPickupExist(pickup) then
            local model = getPickupModel(pickup)
            local modelName = getPickupModelName(model) or ("ID:" .. model)
            local px2, py2, pz2 = getPickupCoordinates(pickup)
            local X, Y = convert3DCoordsToScreen(px2, py2, pz2)
            if X and Y and X > -50 and X < 8050 and Y > -50 and Y < 6050 then
                local dist = math.sqrt((px2 - px)^2 + (py2 - py)^2 + (pz2 - pz)^2)
                if Les.DistPickups.v > 0 and dist > Les.DistPickups.v then goto continue end
                
                local pickupType = getPickupType(pickup) or 0
                local typeName = ""
                if pickupType == 1 then typeName = "������"
                elseif pickupType == 2 then typeName = "��������"
                elseif pickupType == 3 then typeName = "�����"
                elseif pickupType == 4 then typeName = "����"
                elseif pickupType == 5 then typeName = "������"
                else typeName = "����� " .. pickupType end
                
                local color = 0xFFFFFF00
                if pickupType == 1 then color = 0xFF00CCFF end
                if pickupType == 2 then color = 0xFF00FF00 end
                if pickupType == 3 then color = 0xFF00AAFF end
                
                renderFontDrawText(font_whGreen, typeName .. ": " .. modelName, X, Y, color)
                renderFontDrawText(font_whGreen, string.format("%.0f �", dist), X, Y - uiScaled(10), 0xFFFFAAAA)
                ::continue::
            end
        end
    end
end

-- ���������������: �������� ������ ������
function getPickupModelName(model)
    local names = {
        [330] = "�������", [331] = "����������", [332] = "������", [333] = "������",
        [334] = "������ ������", [335] = "�������", [336] = "������", [337] = "����",
        [338] = "����", [339] = "��������", [340] = "��������", [341] = "������",
        [342] = "��������", [343] = "���-���", [344] = "�����", [345] = "�����",
        [346] = "���-�?", [347] = "�������", [348] = "���������", [349] = "�������",
        [350] = "����", [351] = "���� �� ������", [352] = "�������", [353] = "�����",
        [354] = "���������", [355] = "���������", [356] = "������", [357] = "���������",
        [358] = "�����", [359] = "����", [360] = "����", [361] = "���� �� �����",
    }
    return names[model] or ("������ " .. model)
end

-- WH ������ (getCarPointer + ������ �������)
-- �������� ������� ���������� �� ID
local VEHICLE_NAMES = {}
-- �������� �������� ������� �� ���������� ����� LesByYaroRage\LesCarNames.txt
-- ������: ������ ID � ����� ������ "ID=��������"; ��������� CP1251
local _ncDir = thisScript().directory
local _ncDbg = _ncDir .. "les_dbg.txt"
local _ncDbgH = io.open(_ncDbg, "a")
if _ncDbgH then
    _ncDbgH:write(os.date("%H:%M:%S") .. " | [������] �������� dir=" .. _ncDir .. "\n")
    _ncDbgH:close()
end
local _ncFile = _ncDir .. "\\LesByYaroRage\\LesCarNames.txt"
local _nc = io.open(_ncFile, "r")
if not _nc then
    _ncDbgH = io.open(_ncDbg, "a")
    if _ncDbgH then _ncDbgH:write("\t�� ������ ����1: " .. _ncFile .. "\n") _ncDbgH:close() end
    _ncFile = _ncDir .. "\\LesCarNames.txt"
    _nc = io.open(_ncFile, "r")
end
if _nc then
    for _ln in _nc:lines() do
        local _eq = string.find(_ln, "=", 1, true)
        if _eq then
            local _id = tonumber(string.sub(_ln, 1, _eq - 1))
            local _nm = string.sub(_ln, _eq + 1)
            if _id then
                VEHICLE_NAMES[_id] = _nm
            end
        end
    end
    _nc:close()
    local _cnt = 0
    for _ in pairs(VEHICLE_NAMES) do _cnt = _cnt + 1 end
    _ncDbgH = io.open(_ncDbg, "a")
    if _ncDbgH then
        _ncDbgH:write("\tOK ����: " .. _ncFile .. " �������=" .. _cnt .. "\n")
        _ncDbgH:close()
    end
else
    _ncDbgH = io.open(_ncDbg, "a")
    if _ncDbgH then _ncDbgH:write("\t��� ���� �� �������\n") _ncDbgH:close() end
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
            if x and y and z then
                return x, y, z
            end
        end
    end
    return nil
end

-- ������ ���������� ������ (nDoorLock = 0x4F8 �� ��������� ������)
function getVehicleDoorLock(veh)
    if not _vehPosOk then return 0 end
    local ptr = getCarPointer(veh)
    if not ptr or ptr < 0x100000 or ptr > 0x40000000 then return 0 end
    local lock = readMemory(ptr + 0x4F8, 4, false)
    if not lock then return 0 end
    return lock
end

function renderEspCars()
    if type(getAllVehicles) ~= "function" then return end
    if not _vehPosOk then return end
    local camX, camY, camZ = getActiveCameraCoordinates()
    local lookX, lookY, lookZ = getActiveCameraPointAt()
    local dirX, dirY, dirZ = lookX - camX, lookY - camY, lookZ - camZ
    for _, v in pairs(getAllVehicles()) do
        if doesVehicleExist(v) then
            local okC, vvx, vvy, vvz = pcall(getVehiclePosByMemory, v)
            if okC and vvx and vvy and vvz then
                if (vvx - camX) * dirX + (vvy - camY) * dirY + (vvz - camZ) * dirZ > 0 then
                local VX, VY = convert3DCoordsToScreen(vvx, vvy, vvz)
                if VX and VY and VX > 0 and VX < 8000 and VY > 0 and VY < 6000 then
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local d = math.sqrt((vvx-px)^2 + (vvy-py)^2 + (vvz-pz)^2)
                    if Les.DistCars.v > 0 and d <= Les.DistCars.v then
                        -- �������� ���������� � ����������
                        local model = getCarModel(v)
                        local modelName = VEHICLE_NAMES[model] or getNameOfVehicleModel(model) or ("ID:" .. model)
                        local health = getCarHealth(v)
                        local doorLock = getVehicleDoorLock(v)
                        local driver = getDriverOfCar(v)
                        local driverName = ""
                        if driver and driver ~= 0 then
                            local isPlayer, pid = sampGetPlayerIdByCharHandle(driver)
                            if isPlayer then
                                driverName = sampGetPlayerNickname(pid) or ""
                            else
                                driverName = "���"
                            end
                        end
                        
                        -- ���� �� ��������
                        local doorStatus = "�����: �������"
                        if doorLock == 0 or doorLock == 1 then doorStatus = "�����: �������" end
                        
                        local healthColor = 0xFF00FF00
                        if health < 500 then healthColor = 0xFFFFFF00 end
                        if health < 250 then healthColor = 0xFFFF0000 end
                        
                        local yOff = 0
                        renderFontDrawText(font_whGreen, string.format("%.0f �", d), VX, VY + yOff - uiScaled(10), 0xFFFFFFFF)
                        if Les.CarShowModel.v then
                            renderFontDrawText(font_whGreen, modelName, VX, VY + yOff, 0xFF00CCFF)
                            yOff = yOff + uiScaled(12)
                        end
                        if Les.CarShowHP.v then
                            renderFontDrawText(font_whGreen, string.format("HP: %.0f", health/10), VX, VY + yOff, healthColor)
                            yOff = yOff + uiScaled(12)
                        end
                        if Les.CarShowDriver.v and driverName ~= "" then
                            renderFontDrawText(font_whGreen, "��������: " .. driverName, VX, VY + yOff, 0xFFFFFFFF)
                            yOff = yOff + uiScaled(12)
                        end
                        if Les.CarShowDoor.v then
                            renderFontDrawText(font_whGreen, doorStatus, VX, VY + yOff, 0xFFFFAAAA)
                        end
                        if Les.LineCars.v then
                            local sw, sh = getScreenResolution()
                            renderDrawLine(sw/2, sh/2, VX, VY, 1.0, 0xFF00CCFF)
                        end
                    end
                end
                end
            end
        end
    end
end

-- ������� ��������: ������� + ����� + ID ������
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
            renderFontDrawText(font_dbg, tostring(o.m) .. (o.s and 'S' or ''), X, y0 - uiScaled(14), color)
        end
    end
end

-- ������� ������/��������: GTA ������ ������� ��������, �� �� ������� ��� �����.
-- ����� ���������� RPC 43 (RemoveBuildingForPlayer) ��� ������.
-- RPC 43 ���������� � ������� ����� ���������. ����������� �� ���� �����.
-- ������ ������ ������� ������/������ (GTA SA + SA:MP)
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
    -- �������������� ������ ������ SA:MP
    821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,837,838,839,840,
    841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,
    861,862,863,864,865,866,867,868,869,870,871,872,873,874,875,876,877,878,879,880,
    881,882,883,884,885,886,887,888,889,890,891,892,893,894,895,896,897,898,899,900
}
local TREE_SET = {}
for _, m in ipairs(TREE_MODEL_IDS) do TREE_SET[m] = true end
local FOLIAGE_RADIUS = 120.0
local FOLIAGE_SINK = 500.0
local FOLIAGE_MAX_PER_PASS = 50  -- ��������� ��� ������� �������
local FOLIAGE_MAX_RESTORE_PER_PASS = 50
local BUILDING_MAX_PER_PASS = 30  -- ��� ������
local _folBldPosX, _folBldPosY, _folBldPosZ = nil, nil, nil
local _folBldStep = 0        -- ��� �������� RPC ��� ������ (0 = �� ������)
local FOLIAGE_RPC_PER_STEP = 5   -- ������� RPC �� ���� (���� �� �������)

local _objHideOk = (type(getAllObjects) == "function" and type(setObjectCoordinates) == "function"
                    and type(getObjectModel) == "function" and type(getObjectCoordinates) == "function")

-- true = ��������� ������ (�� �������), false = ���������� (����� ��������).
-- sampGetObjectSampIdByHandle ���������� -1/0 ��� ����������, >=0 ��� ���������.
local function isServerObject(obj)
    if not sampGetObjectSampIdByHandle then return false end
    local ok, r1, r2 = pcall(sampGetObjectSampIdByHandle, obj)
    if not ok then return false end
    if r1 == false then return false end
    if r1 == true then return true end
    if type(r1) == 'number' then return r1 >= 0 end
    return false
end

_folHidden = {}   -- obj -> {x, y, z} (�������� ����������)
local _folCheckAt = 0

function applyFoliageClear()
    if not _objHideOk then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local done = 0
    local checked = 0
    local skippedServer = 0
    local skippedModel = 0
    local skippedDist = 0
    for _, obj in pairs(getAllObjects()) do
        checked = checked + 1
        if done >= FOLIAGE_MAX_PER_PASS then break end
        if doesObjectExist and doesObjectExist(obj) and not _folHidden[obj] then
            local isServer = isServerObject(obj)
            if isServer then
                skippedServer = skippedServer + 1
            else
                local om, m = pcall(getObjectModel, obj)
                if om and m and TREE_SET[m] then
                    local oc, _, cx, cy, cz = pcall(getObjectCoordinates, obj)
                    if oc then
                        local dx = cx - px; local dy = cy - py; local dz = cz - pz
                        if (dx*dx + dy*dy + dz*dz) <= (FOLIAGE_RADIUS * FOLIAGE_RADIUS) then
                            _folHidden[obj] = {cx, cy, cz}
                            local ok = pcall(setObjectCoordinates, obj, cx, cy, cz - FOLIAGE_SINK)
                            if ok then
                                done = done + 1
                            else
                                dbg("FOLIAGE: setObjectCoordinates failed for model " .. m)
                            end
                        else
                            skippedDist = skippedDist + 1
                        end
                    end
                else
                    skippedModel = skippedModel + 1
                end
            end
        end
    end
    -- Debug log
    if done > 0 then
        dbg(string.format("FOLIAGE: hidden=%d checked=%d server=%d model=%d dist=%d", done, checked, skippedServer, skippedModel, skippedDist))
    end
    -- ������� ������ ������ � _folHidden (��� � 10 ���) + ������ �� ������ ������
    if (os.clock() - _folCheckAt) > 10 then
        _folCheckAt = os.clock()
        local count = 0
        for h in pairs(_folHidden) do
            count = count + 1
            if not (doesObjectExist and doesObjectExist(h)) then
                _folHidden[h] = nil
            end
        end
        -- Ƹ����� �����: ���� ������� > 500, ������ ������
        if count > 500 then
            local removed = 0
            for h in pairs(_folHidden) do
                if removed >= count - 400 then break end
                _folHidden[h] = nil
                removed = removed + 1
            end
            dbg("_folHidden cleanup: removed " .. removed .. " old entries")
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

-- ������� ������ ����� RPC 43 (RemoveBuildingForPlayer).
-- ��������� ��������, ���� �� �������:
--  - �������� ��������� > 150 � �� ������� ������� ����� ����� ������;
--  - �������� �� FOLIAGE_RPC_PER_STEP �� ����.
local FOLIAGE_RPC_PER_STEP = 5
local _folBldStep = 0
local _folBldPosX, _folBldPosY, _folBldPosZ = nil, nil, nil

function sendRemoveBuildingRPCs()
    -- ���������� ������������ RPC 43: ���������� setObjectCoordinates ��� ������
    -- ��� �� ���������� ������� ������, ������� �� ������������� ���������
    if not _objHideOk then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local done = 0
    local checked = 0
    local skippedServer = 0
    local skippedModel = 0
    local skippedDist = 0
    -- ���������� ���������� ��������� BUILDING_MAX_PER_PASS
    local BUILDING_SINK = 500.0
    local BUILDING_RADIUS = 150.0

    for _, obj in pairs(getAllObjects()) do
        checked = checked + 1
        if done >= BUILDING_MAX_PER_PASS then break end
        if doesObjectExist and doesObjectExist(obj) and not _folHidden[obj] then
            local isServer = isServerObject(obj)
            if isServer then
                skippedServer = skippedServer + 1
            else
                local om, m = pcall(getObjectModel, obj)
                if om and m and TREE_SET[m] then
                    local oc, _, cx, cy, cz = pcall(getObjectCoordinates, obj)
                    if oc then
                        local dx = cx - px; local dy = cy - py; local dz = cz - pz
                        if (dx*dx + dy*dy + dz*dz) <= (BUILDING_RADIUS * BUILDING_RADIUS) then
                            _folHidden[obj] = {cx, cy, cz}
                            local ok = pcall(setObjectCoordinates, obj, cx, cy, cz - BUILDING_SINK)
                            if ok then
                                done = done + 1
                            else
                                dbg("BUILDING: setObjectCoordinates failed for model " .. m)
                            end
                        else
                            skippedDist = skippedDist + 1
                        end
                    end
                else
                    skippedModel = skippedModel + 1
                end
            end
        end
    end
    -- Debug log
    if done > 0 then
        dbg(string.format("BUILDING: hidden=%d checked=%d server=%d model=%d dist=%d", done, checked, skippedServer, skippedModel, skippedDist))
    end
end

-- �����: ������� ������ ������� ������ (���������, ��� RPC)
function probeBuilding(id)
    if not _objHideOk then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local done = 0
    for _, obj in pairs(getAllObjects()) do
        if done >= 1 then break end
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
                            done = done + 1
                            dbg('PROBE id=' .. id .. ' �����')
                        end
                    end
                end
            end
        end
    end
end

-- ��� ���������: ������� �������� �� ID (���������, ��� RPC)
function sweepOne(id)
    probeBuilding(id)
end

-- ������ ��������: �������� ���������� �� ������� � �������
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
    _dbgScreen[1] = string.format('����� ��������: %d | � �������: %d | �� ID ��������: %d | ������: %d | ���������: %d',
        total, withinRad, treeById, hiddenNow, serverCnt)
    local sorted = {}
    for m, c in pairs(counts) do
        if c.n > 0 and (c.rad > 0 or c.s > 0) then
            sorted[#sorted + 1] = {
                n = c.n,
                r = c.rad,
                s = string.format('ID %d: x%d%s%s%s', m, c.n,
                    (c.rad > 0 and (' � �������=' .. c.rad) or ''),
                    (c.s > 0 and (' ������=' .. c.s) or ''),
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
        _dbgScreen[#_dbgScreen + 1] = '... ����� ������� ' .. #sorted .. ' (����������� � les_dbg.txt)'
    end
    if #_dbgScreen < 2 then
        _dbgScreen[#_dbgScreen + 1] = '�������� ����� ���'
    end
end

function onReceivePacket(id, bs)
    if type(_cefLogReceive) == 'function' then pcall(_cefLogReceive, id, bs) end
    if id ~= 215 then return end
    local pk = ''
    for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do pk = pk .. string.char(raknetBitStreamReadInt8(bs)) end
    if Les.AutoY.v then
        if pk:find("setFill(0, 100)", 1, true) then
            Les.AutoY_Clicker:Stop()
            dbg("AUTOY stop-100")
        elseif pk:find("setFill(0, ", 1, true) then
            Les.AutoY_Clicker:Start()
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

    local screenAspectRatio = safeReadFloat(0xC3EFA4)
    local crosshairOffset = {
        safeReadFloat(0xB6EC10),
        safeReadFloat(0xB6EC14)
    }
    
    -- Fallback �������� ���� ������ ������ �� �������
    if not screenAspectRatio then screenAspectRatio = 1.3333 end
    if not crosshairOffset[1] then crosshairOffset[1] = 0.5 end
    if not crosshairOffset[2] then crosshairOffset[2] = 0.5 end

    local mult = math.tan(getCameraFov() * 0.5 * 0.017453292)
    fz = 3.14159265 - math.atan2(1.0, mult * ((0.5 - crosshairOffset[1]) * (2 / screenAspectRatio)))
    fx = 3.14159265 - math.atan2(1.0, mult * 2 * (crosshairOffset[2] - 0.5))

    local camMode = safeReadMemory(0xB6F1A8, 1, false)

    if not camMode or not (camMode == 53 or camMode == 55) then
        fx = 3.14159265 / 2
        fz = 3.14159265 / 2
    end

    local ax = math.atan2(vect.fY, -vect.fX) - 3.14159265 / 2
    local az = math.atan2(math.sqrt(vect.fX * vect.fX + vect.fY * vect.fY), vect.fZ)

    setCameraPositionUnfixed(az - fz, fx - ax)
end
