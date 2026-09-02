-- This file is part of mimgui project
-- Licensed under the MIT License
-- Copyright (c) 2018, FYP <https://github.com/THE-FYP>

assert(getMoonloaderVersion() >= 025)

local PKG = ... or 'mimgui'
local imgui = require(PKG .. '.imgui')
local DX9 = require(PKG .. '.dx9')
local ffi = require 'ffi'
local winmsg = require 'windows.message'
local memory = require 'memory'
local mimgui = {}

local renderer = nil
local subscriptionsInitialize = {}
local subscriptionsNewFrame = {}
local eventsRegistered = false
local active = false
local cursorActive = false
local playerLocked = false
local iniFilePath = nil
local defaultGlyphRanges = nil
local dpiScaling

local imgui_set_mouse_cursor = imgui.SetMouseCursor
local ImGuiMouseCursor_None = imgui.lib.ImGuiMouseCursor_None

local function ComputeSubscriptionsState()
    local activate = false
    local wantShowCursor = false
    local lockPlayer = false
    for _, sub in ipairs(subscriptionsNewFrame) do
        if type(sub.Condition) == 'function' then
            sub._render = sub.Condition()
        else
            sub._render = sub.Condition and true
        end
        if sub._render then
            if not sub.HideCursor then
                wantShowCursor = true
            end
            lockPlayer = lockPlayer or sub.LockPlayer
        end
        activate = activate or sub._render
    end
    return activate, wantShowCursor, lockPlayer
end

setmetatable(mimgui, {
    __index = imgui,
    __newindex = function(t, k, v)
        if imgui[k] and mimgui._debugMessages then
            print('[mimgui] Warning! Overwriting existing key "' .. k .. '"!')
        end
        rawset(t, k, v)
    end
})

mimgui._debugMessages = false
local _silentErrorCallback = ffi.cast('ImGuiErrorCallback', function() end)

-- background "Shift" triggering fix
memory.fill(0x00531155, 0x90, 5, true)

local function ScaleFontSize(size_pixels)
    return math.floor(mimgui.GetDpiScale() * size_pixels)
end

local function HookAddFont(f, size_pixels_argn, font_cfg_argn)
    return function(...)
        local args, argc = { ... }, select('#', ...)
        args[size_pixels_argn] = args[size_pixels_argn] and ScaleFontSize(args[size_pixels_argn])
        local font_cfg = args[font_cfg_argn]
        local size_backup
        if font_cfg then
            size_backup = font_cfg.SizePixels
            font_cfg.SizePixels = ScaleFontSize(size_backup)
        end
        local ret = f(unpack(args, 1, argc))
        if font_cfg then
            font_cfg.SizePixels = size_backup
        end
        return ret
    end
end

local function ShowCursor(show)
    if show then
        showCursor(true)
    elseif cursorActive then
        showCursor(false)
    end
    cursorActive = show
end

local function LockPlayer(lock)
    if lock then
        lockPlayerControl(true)
    elseif playerLocked then
        lockPlayerControl(false)
    end
    playerLocked = lock
end

-- MoonLoader v.027
if not isCursorActive then
    isCursorActive = function() return cursorActive end
end

local function InitializeRenderer()
    -- init renderer
    local hwnd = ffi.cast('HWND', readMemory(0x00C8CF88, 4, false))
    local d3ddevice = ffi.cast('LPDIRECT3DDEVICE9', getD3DDevicePtr())
    renderer = assert(DX9.new(d3ddevice, hwnd))
    renderer:SwitchContext()

    -- configure imgui
    imgui.GetIO().LogFilename = nil
    local confdir = getWorkingDirectory() .. [[\config\]] .. PKG .. [[\]]
    if not doesDirectoryExist(confdir) then
        createDirectory(confdir)
    end
    iniFilePath = ffi.new('char[260]', confdir .. script.this.filename .. '.ini')
    imgui.GetIO().IniFilename = iniFilePath

    local dsm = mimgui.GetDpiScalingMode()
    if dsm == 1 or dsm == 2 then
        imgui.GetIO().FontGlobalScale = mimgui.GetDpiScale()
    elseif dsm == 4 then
        local index = imgui.ImFontAtlas.__index
        index.AddFont = HookAddFont(index.AddFont, 0, 2)
        index.AddFontDefault = HookAddFont(index.AddFontDefault, 0, 2)
        index.AddFontFromFileTTF = HookAddFont(index.AddFontFromFileTTF, 3, 4)
        index.AddFontFromMemoryTTF = HookAddFont(index.AddFontFromMemoryTTF, 4, 5)
        index.AddFontFromMemoryCompressedTTF = HookAddFont(index.AddFontFromMemoryCompressedTTF, 4, 5)
        index.AddFontFromMemoryCompressedBase85TTF = HookAddFont(index.AddFontFromMemoryCompressedBase85TTF, 3, 4)
    end

    -- change font
    local fontFile = getFolderPath(0x14) .. '\\trebucbd.ttf'
    assert(doesFileExist(fontFile), '[mimgui] Font "' .. fontFile .. '" doesn\'t exist!')
    local builder = imgui.ImFontGlyphRangesBuilder()
    builder:AddRanges(imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    builder:AddText([[‚„…†‡€‰‹‘’“”•–—™›№]])
    defaultGlyphRanges = imgui.ImVector_ImWchar()
    builder:BuildRanges(defaultGlyphRanges)
    local fontSize = dsm == 3 and ScaleFontSize(14) or 14
    imgui.GetIO().Fonts:AddFontFromFileTTF(fontFile, fontSize, nil, defaultGlyphRanges[0].Data)

    for _, cb in ipairs(subscriptionsInitialize) do
        cb()
    end

    if mimgui.ApplyDebugMessages then
        mimgui.ApplyDebugMessages()
    end

    if dsm == 2 or dsm == 3 or dsm == 4 then
        imgui.GetStyle():ScaleAllSizes(mimgui.GetDpiScale())
    end
end

local function RegisterEvents()
    addEventHandler('onD3DPresent', function()
        if active then
            if not renderer then
                InitializeRenderer()
            end
            if renderer and not renderer.lost then
                renderer:SwitchContext()
                for _, sub in ipairs(subscriptionsNewFrame) do
                    if sub._render and sub._before then
                        sub:_before()
                    end
                end
                renderer:NewFrame()
                local wantShowCursor = false
                for _, sub in ipairs(subscriptionsNewFrame) do
                    if sub._render then
                        sub:_draw()
                        if not sub.HideCursor then
                            wantShowCursor = true
                        end
                    end
                end
                if not wantShowCursor then
                    imgui_set_mouse_cursor(ImGuiMouseCursor_None)
                end
                renderer:EndFrame(not wantShowCursor and not isCursorActive())
            end
        end
    end)

    local keyState = {}
    local WM_MOUSEHWHEEL = 0x020E
    local mouseMsgs = {
        [WM_MOUSEHWHEEL] = true,
        [winmsg.WM_MOUSEMOVE] = true,
        [winmsg.WM_LBUTTONDOWN] = true,
        [winmsg.WM_LBUTTONDBLCLK] = true,
        [winmsg.WM_RBUTTONDOWN] = true,
        [winmsg.WM_RBUTTONDBLCLK] = true,
        [winmsg.WM_MBUTTONDOWN] = true,
        [winmsg.WM_MBUTTONDBLCLK] = true,
        [winmsg.WM_LBUTTONUP] = true,
        [winmsg.WM_RBUTTONUP] = true,
        [winmsg.WM_MBUTTONUP] = true,
        [winmsg.WM_MOUSEWHEEL] = true
    }
    local keyboardMsgs = {
        [winmsg.WM_KEYDOWN] = true,
        [winmsg.WM_SYSKEYDOWN] = true,
        [winmsg.WM_KEYUP] = true,
        [winmsg.WM_SYSKEYUP] = true,
        [winmsg.WM_CHAR] = true
    }
    addEventHandler('onWindowMessage', function(msg, wparam, lparam)
        if not renderer then
            return
        end

        if not mimgui.DisableInput and active then
            local keyboard = keyboardMsgs[msg]
            local mouse = mouseMsgs[msg]
            local setcursor = msg == winmsg.WM_SETCURSOR
            if keyboard or mouse or setcursor then
                renderer:SwitchContext()
                local io = imgui.GetIO()
                local result = renderer:WindowMessage(msg, wparam, lparam)
                if setcursor then
                    if bit.band(lparam, 0xffff) == 1 then -- HTCLIENT
                        consumeWindowMessage(true, true)
                    end
                elseif (keyboard and io.WantCaptureKeyboard) or (mouse and io.WantCaptureMouse) then
                    if msg == winmsg.WM_KEYDOWN or msg == winmsg.WM_SYSKEYDOWN then
                        keyState[wparam] = false
                        consumeWindowMessage(true, true)
                    elseif msg == winmsg.WM_KEYUP or msg == winmsg.WM_SYSKEYUP then
                        if not keyState[wparam] then
                            consumeWindowMessage(true, true)
                        end
                    else
                        consumeWindowMessage(true, true)
                    end
                end
            end
        end

        -- save key states to prevent key sticking
        if msg == winmsg.WM_KILLFOCUS then
            keyState = {}
        elseif wparam < 256 then
            if msg == winmsg.WM_KEYDOWN or msg == winmsg.WM_SYSKEYDOWN then
                keyState[wparam] = true
            elseif msg == winmsg.WM_KEYUP or msg == winmsg.WM_SYSKEYUP then
                keyState[wparam] = false
            end
        end
    end)

    addEventHandler('onD3DDeviceLost', function()
        if renderer and not renderer.lost then
            renderer:InvalidateDeviceObjects()
            renderer.lost = true
        end
    end)

    addEventHandler('onD3DDeviceReset', function()
        if renderer then
            renderer.lost = false
            renderer:SwitchContext()
            renderer:CreateFontsTexture()
        end
    end)

    addEventHandler('onScriptTerminate', function(scr)
        if scr == script.this then
            ShowCursor(false)
            LockPlayer(false)
        end
    end)

    local updaterThread = lua_thread.create(function()
        while true do
            wait(0)
            local activate, wantShowCursor, lockPlayer = ComputeSubscriptionsState()
            active = activate
            ShowCursor(active and wantShowCursor)
            LockPlayer(active and lockPlayer)
        end
    end)
    updaterThread.work_in_pause = true
end

local function Unsubscribe(t, sub)
    for i, v in ipairs(t) do
        if v == sub then
            table.remove(t, i)
            return
        end
    end
end

local function ImGuiEnum(name)
    return setmetatable({ __name = name }, {
        __index = function(t, k)
            local key = t.__name .. k
            local value = imgui.lib[key]
            if value == nil then
                error('unknown imgui enum ' .. key, 2)
            end
            return value
        end
    })
end

local function ImGuiEnumOptional(name)
    return setmetatable({ __name = name }, {
        __index = function(t, k)
            return imgui.lib[t.__name .. k]
        end
    })
end

-- ImDrawCornerFlags_* removed in ImGui 1.82+; map old names to ImDrawFlags_RoundCorners*
local function ImGuiEnumRemap(prefix, remap)
    return setmetatable({ __prefix = prefix, __remap = remap }, {
        __index = function(t, k)
            local mapped = t.__remap[k] or k
            local value = imgui.lib[t.__prefix .. mapped]
            if value == nil then
                error('unknown imgui enum ' .. t.__prefix .. mapped, 2)
            end
            return value
        end
    })
end

--- API ---
mimgui._VERSION = '1.92.8'
mimgui.DisableInput = false

mimgui.ComboFlags = ImGuiEnum('ImGuiComboFlags_')
mimgui.Dir = ImGuiEnum('ImGuiDir_')
mimgui.ColorEditFlags = ImGuiEnumRemap('ImGuiColorEditFlags_', {
    AlphaPreview = 'AlphaPreviewHalf',
})
mimgui.Col = ImGuiEnumRemap('ImGuiCol_', {
    TabActive = 'TabSelected',
    TabUnfocused = 'TabDimmed',
    TabUnfocusedActive = 'TabDimmedSelected',
    NavHighlight = 'NavCursor',
})
mimgui.WindowFlags = ImGuiEnumRemap('ImGuiWindowFlags_', {
    AlwaysUseWindowPadding = 'None',
    NavFlattened = 'None',
})
mimgui.ChildFlags = ImGuiEnum('ImGuiChildFlags_')
mimgui.NavInput = ImGuiEnumOptional('ImGuiNavInput_')
mimgui.FocusedFlags = ImGuiEnum('ImGuiFocusedFlags_')
mimgui.Cond = ImGuiEnum('ImGuiCond_')
mimgui.BackendFlags = ImGuiEnum('ImGuiBackendFlags_')
mimgui.TreeNodeFlags = ImGuiEnumRemap('ImGuiTreeNodeFlags_', {
    AllowItemOverlap = 'AllowOverlap',
    NavLeftJumpsBackHere = 'None',
})
mimgui.StyleVar = ImGuiEnum('ImGuiStyleVar_')
mimgui.DrawCornerFlags = ImGuiEnumRemap('ImDrawFlags_', {
    None = 'RoundCornersNone',
    TopLeft = 'RoundCornersTopLeft',
    TopRight = 'RoundCornersTopRight',
    BotLeft = 'RoundCornersBottomLeft',
    BotRight = 'RoundCornersBottomRight',
    All = 'RoundCornersAll',
    Top = 'RoundCornersTop',
    Bot = 'RoundCornersBottom',
    Left = 'RoundCornersLeft',
    Right = 'RoundCornersRight',
})
mimgui.DrawFlags = ImGuiEnum('ImDrawFlags_')
mimgui.DragDropFlags = ImGuiEnum('ImGuiDragDropFlags_')
mimgui.SelectableFlags = ImGuiEnumRemap('ImGuiSelectableFlags_', {
    DontClosePopups = 'NoAutoClosePopups',
})
mimgui.InputTextFlags = ImGuiEnumRemap('ImGuiInputTextFlags_', {
    AlwaysInsertMode = 'None', -- removed
    NoMarkEdited = 'None',
})
mimgui.MouseCursor = ImGuiEnum('ImGuiMouseCursor_')
mimgui.FontAtlasFlags = ImGuiEnum('ImFontAtlasFlags_')
mimgui.HoveredFlags = ImGuiEnum('ImGuiHoveredFlags_')
mimgui.ConfigFlags = ImGuiEnumRemap('ImGuiConfigFlags_', {
    NavEnableSetMousePos = 'None',
    NavNoCaptureKeyboard = 'NoKeyboard',
})
mimgui.DrawListFlags = ImGuiEnum('ImDrawListFlags_')
mimgui.DataType = ImGuiEnum('ImGuiDataType_')
mimgui.Key = ImGuiEnumRemap('ImGuiKey_', {
    KeyPadEnter = 'KeypadEnter',
    COUNT = 'NamedKey_COUNT',
})
mimgui.ActivateFlags = ImGuiEnum('ImGuiActivateFlags_')
mimgui.Axis = ImGuiEnum('ImGuiAxis_')
mimgui.ButtonFlags = ImGuiEnum('ImGuiButtonFlags_')
mimgui.DebugLogFlags = ImGuiEnum('ImGuiDebugLogFlags_')

function mimgui.ApplyDebugMessages()
    local ctx = imgui.GetCurrentContext()
    if ctx == nil then
        return
    end
    local io = imgui.GetIO()
    local F = mimgui.DebugLogFlags
    local on = mimgui._debugMessages and true or false
    if on then
        ctx.DebugLogFlags = bit.bor(F.EventError or 1, F.OutputToTTY or bit.lshift(1, 20))
        ctx.ErrorCallback = nil
        io.ConfigErrorRecoveryEnableDebugLog = true
        io.ConfigErrorRecoveryEnableTooltip = true
        io.ConfigErrorRecoveryEnableAssert = false
        io.ConfigDebugHighlightIdConflicts = true
    else
        ctx.DebugLogFlags = F.None or 0
        ctx.ErrorCallback = _silentErrorCallback
        io.ConfigErrorRecoveryEnableDebugLog = false
        io.ConfigErrorRecoveryEnableTooltip = false
        io.ConfigErrorRecoveryEnableAssert = false
        io.ConfigDebugHighlightIdConflicts = false
    end
end

--- @param enabled boolean
function mimgui.SetDebugMessages(enabled)
    mimgui._debugMessages = not not enabled
    mimgui.ApplyDebugMessages()
end

--- @return boolean
function mimgui.GetDebugMessages()
    return mimgui._debugMessages and true or false
end

mimgui.DrawTextFlags = ImGuiEnum('ImDrawTextFlags_')
mimgui.FocusRequestFlags = ImGuiEnum('ImGuiFocusRequestFlags_')
mimgui.FontFlags = ImGuiEnum('ImFontFlags_')
mimgui.InputEventType = ImGuiEnum('ImGuiInputEventType_')
mimgui.InputFlags = ImGuiEnum('ImGuiInputFlags_')
mimgui.InputSource = ImGuiEnum('ImGuiInputSource_')
mimgui.ItemFlags = ImGuiEnum('ImGuiItemFlags_')
mimgui.ItemStatusFlags = ImGuiEnum('ImGuiItemStatusFlags_')
mimgui.LayoutType = ImGuiEnum('ImGuiLayoutType_')
mimgui.ListClipperFlags = ImGuiEnum('ImGuiListClipperFlags_')
mimgui.LocKey = ImGuiEnum('ImGuiLocKey_')
mimgui.LogFlags = ImGuiEnum('ImGuiLogFlags_')
mimgui.Mod = ImGuiEnum('ImGuiMod_')
mimgui.MouseButton = ImGuiEnum('ImGuiMouseButton_')
mimgui.MouseSource = ImGuiEnum('ImGuiMouseSource_')
mimgui.MultiSelectFlags = ImGuiEnum('ImGuiMultiSelectFlags_')
mimgui.NavLayer = ImGuiEnum('ImGuiNavLayer_')
mimgui.NavMoveFlags = ImGuiEnum('ImGuiNavMoveFlags_')
mimgui.NavRenderCursorFlags = ImGuiEnum('ImGuiNavRenderCursorFlags_')
mimgui.NextItemDataFlags = ImGuiEnum('ImGuiNextItemDataFlags_')
mimgui.NextWindowDataFlags = ImGuiEnum('ImGuiNextWindowDataFlags_')
mimgui.OldColumnFlags = ImGuiEnum('ImGuiOldColumnFlags_')
mimgui.PlotType = ImGuiEnum('ImGuiPlotType_')
mimgui.PopupFlags = ImGuiEnum('ImGuiPopupFlags_')
mimgui.PopupPositionPolicy = ImGuiEnum('ImGuiPopupPositionPolicy_')
mimgui.ScrollFlags = ImGuiEnum('ImGuiScrollFlags_')
mimgui.SelectionRequestType = ImGuiEnum('ImGuiSelectionRequestType_')
mimgui.SeparatorFlags = ImGuiEnum('ImGuiSeparatorFlags_')
mimgui.SliderFlags = ImGuiEnum('ImGuiSliderFlags_')
mimgui.SortDirection = ImGuiEnum('ImGuiSortDirection_')
mimgui.TabBarFlags = ImGuiEnum('ImGuiTabBarFlags_')
mimgui.TabItemFlags = ImGuiEnum('ImGuiTabItemFlags_')
mimgui.TableBgTarget = ImGuiEnum('ImGuiTableBgTarget_')
mimgui.TableColumnFlags = ImGuiEnum('ImGuiTableColumnFlags_')
mimgui.TableFlags = ImGuiEnum('ImGuiTableFlags_')
mimgui.TableRowFlags = ImGuiEnum('ImGuiTableRowFlags_')
mimgui.TextFlags = ImGuiEnum('ImGuiTextFlags_')
mimgui.TooltipFlags = ImGuiEnum('ImGuiTooltipFlags_')
mimgui.TypingSelectFlags = ImGuiEnum('ImGuiTypingSelectFlags_')
mimgui.ViewportFlags = ImGuiEnum('ImGuiViewportFlags_')
mimgui.WindowBgClickFlags = ImGuiEnum('ImGuiWindowBgClickFlags_')
mimgui.WindowRefreshFlags = ImGuiEnum('ImGuiWindowRefreshFlags_')

function mimgui.OnInitialize(cb)
    assert(type(cb) == 'function')
    table.insert(subscriptionsInitialize, cb)
    return { Unsubscribe = function() Unsubscribe(subscriptionsInitialize, cb) end }
end

function mimgui.OnFrame(cond, cbBeforeFrame, cbDraw)
    assert(type(cond) == 'function')
    assert(type(cbBeforeFrame) == 'function')
    if cbDraw then assert(type(cbDraw) == 'function') end
    if not eventsRegistered then
        RegisterEvents()
        eventsRegistered = true
    end
    local sub = {
        Condition = cond,
        LockPlayer = false,
        HideCursor = false,
        _before = cbDraw and cbBeforeFrame or nil,
        _draw = cbDraw or cbBeforeFrame,
        _render = false,
    }
    function sub:Unsubscribe()
        Unsubscribe(subscriptionsNewFrame, self)
    end

    function sub:IsActive()
        return self._render
    end

    table.insert(subscriptionsNewFrame, sub)
    return sub
end

function mimgui.SwitchContext()
    return renderer:SwitchContext()
end

function mimgui.CreateTextureFromFile(path)
    return renderer:CreateTextureFromFile(path)
end

function mimgui.CreateTextureFromFileInMemory(src, size)
    return renderer:CreateTextureFromFileInMemory(src, size)
end

function mimgui.ReleaseTexture(tex)
    return renderer:ReleaseTexture(tex)
end

function mimgui.CreateFontsTexture()
    return renderer:CreateFontsTexture()
end

function mimgui.InvalidateFontsTexture()
    return renderer:InvalidateFontsTexture()
end

function mimgui.GetRenderer()
    return renderer
end

function mimgui.IsInitialized()
    return renderer ~= nil
end

function mimgui.StrCopy(dst, src, len)
    if len or tostring(ffi.typeof(dst)):find('*', 1, true) then
        ffi.copy(dst, src, len)
    else
        len = math.min(ffi.sizeof(dst) - 1, #src)
        ffi.copy(dst, src, len)
        dst[len] = 0
    end
end

local defaultSettings = {
    display_settings = {
        dpi_scaling_mode = 3
    }
}

--  0: None
--  1: ImGuiIO::FontGlobalScale
--  2: ImGuiIO::FontGlobalScale + ImGuiStyle::ScaleAllSizes
--  3: Default ImFontAtlas::AddFont* + ImGuiStyle::ScaleAllSizes
--  4: All ImFontAtlas::AddFont* + ImGuiStyle::ScaleAllSizes
function mimgui.SetDpiScalingMode(v)
    dpiScaling = v
end

function mimgui.GetDpiScalingMode()
    if not dpiScaling then
        local inicfg = require('inicfg')
        local data = inicfg.load(defaultSettings, 'mimgui\\mimgui.user')
        data = inicfg.load(data, 'mimgui\\' .. script.this.filename .. '.user')
        dpiScaling = data.display_settings.dpi_scaling_mode
    end
    return dpiScaling
end

function mimgui.GetDpiScale()
    return renderer.dpiscale
end

local new = {}
setmetatable(new, {
    __index = function(self, key)
        local basetype = ffi.typeof(key)
        local mt = {
            __index = function(self, sz)
                return setmetatable({ type = ffi.typeof('$[$]', self.type, sz) }, getmetatable(self))
            end,
            __call = function(self, ...)
                return self.type(...)
            end
        }
        return setmetatable({ type = ffi.typeof('$[1]', basetype), basetype = basetype }, {
            __index = function(self, sz)
                return setmetatable({ type = ffi.typeof('$[$]', self.basetype, sz) }, mt)
            end,
            __call = mt.__call
        })
    end,
    __call = function(self, t, ...)
        return ffi.new(t, ...)
    end
})
mimgui.new = new

return mimgui
