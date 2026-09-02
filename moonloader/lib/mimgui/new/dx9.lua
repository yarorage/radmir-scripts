-- This file is part of mimgui project
-- Licensed under the MIT License
-- Copyright (c) 2018, FYP <https://github.com/THE-FYP>

local PKG = (... or 'mimgui.dx9'):match('^(.+)%.[^%.]+$') or 'mimgui'
local imgui = require(PKG .. '.imgui')
local win32 = require(PKG .. '.win32')
local lib = imgui.lib
local ffi = require 'ffi'

ffi.cdef [[
typedef struct IDirect3DDevice9 *LPDIRECT3DDEVICE9, *PDIRECT3DDEVICE9;
typedef struct IDirect3DTexture9 *LPDIRECT3DTEXTURE9, *PDIRECT3DTEXTURE9;
typedef const char *LPCTSTR;
typedef const void *LPCVOID;
typedef unsigned int UINT;
typedef void *HWND;
typedef unsigned int UINT_PTR, *PUINT_PTR;
typedef long LONG_PTR, *PLONG_PTR;
typedef UINT_PTR WPARAM;
typedef LONG_PTR LPARAM;
typedef LONG_PTR LRESULT;

bool ImGui_ImplWin32_Init(void* hwnd);
void ImGui_ImplWin32_Shutdown();
void ImGui_ImplWin32_NewFrame();
void ImGui_ImplWin32_UpdateMouseCursorFrameEnd();
LRESULT ImGui_ImplWin32_WndProcHandler(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

bool ImGui_ImplDX9_Init(LPDIRECT3DDEVICE9 device);
void ImGui_ImplDX9_Shutdown();
void ImGui_ImplDX9_NewFrame();
void ImGui_ImplDX9_RenderDrawData(ImDrawData* draw_data);
void ImGui_ImplDX9_InvalidateDeviceObjects();
bool ImGui_ImplDX9_CreateDeviceObjects();

LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFile(LPDIRECT3DDEVICE9 device, LPCTSTR path);
LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFileInMemory(LPDIRECT3DDEVICE9 device, LPCVOID src, UINT size);
void ImGui_ImplDX9_ReleaseTexture(LPDIRECT3DTEXTURE9 tex);

typedef unsigned short wchar_t;
int __stdcall MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags, const char* lpMultiByteStr, int cbMultiByte, wchar_t* lpWideCharStr, int cchWideChar);
]]

local ImplDX9 = {}
function ImplDX9.new(device, hwnd)
    local obj = {}
    local context = imgui.CreateContext()
    obj.ticksPerSecond = ffi.new('INT64[1]', 0)
    obj.time = ffi.new('INT64[1]', 0)
    imgui.SetCurrentContext(context)
    local imio = imgui.GetIO()
    imio.BackendRendererName = 'imgui_impl_dx9_lua'
    if not lib.ImGui_ImplWin32_Init(hwnd) then
        imgui.DestroyContext(context)
        return nil
    end
    if not lib.ImGui_ImplDX9_Init(device) then
        lib.ImGui_ImplWin32_Shutdown()
        imgui.DestroyContext(context)
        return nil
    end
    obj.context = context
    obj.d3ddevice = device
    obj.hwnd = hwnd
    obj.dpiscale = win32.GetDpiScaleForWindow(hwnd)
    local shutdown_marker = ffi.new('char[1]')
    ffi.gc(shutdown_marker, function()
        imgui.SetCurrentContext(context)
        lib.ImGui_ImplDX9_Shutdown()
        lib.ImGui_ImplWin32_Shutdown()
        imgui.DestroyContext(context)
    end)
    obj._shutdown_marker = shutdown_marker
    return setmetatable(obj, {__index = ImplDX9})
end

function ImplDX9:SwitchContext()
    imgui.SetCurrentContext(self.context)
end

function ImplDX9:NewFrame()
    self:SwitchContext()
    lib.ImGui_ImplWin32_NewFrame()
    lib.ImGui_ImplDX9_NewFrame()
    imgui.NewFrame()
end

function ImplDX9:EndFrame(hideOsCursor)
    self:SwitchContext()
    imgui.Render()
    if hideOsCursor then
        imgui.SetMouseCursor(imgui.lib.ImGuiMouseCursor_None)
    end
    lib.ImGui_ImplDX9_RenderDrawData(imgui.GetDrawData())
    lib.ImGui_ImplWin32_UpdateMouseCursorFrameEnd()
end

jit.off(ImplDX9.EndFrame)

function ImplDX9:WindowMessage(msg, wparam, lparam)
    self:SwitchContext()
    -- GTA:SA uses ANSI WM_CHAR; convert system code page to UTF-16 before ImGui backend.
    if msg == 0x0102 then -- WM_CHAR
        if wparam < 256 then
            local char = ffi.new('char[1]', wparam)
            local wchar = ffi.new('wchar_t[1]', 0)
            if ffi.C.MultiByteToWideChar(0, 0, char, 1, wchar, 1) > 0 then
                wparam = wchar[0]
            end
        end
    end
    return lib.ImGui_ImplWin32_WndProcHandler(self.hwnd, msg, wparam, lparam)
end

function ImplDX9:InvalidateDeviceObjects()
    self:SwitchContext()
    lib.ImGui_ImplDX9_InvalidateDeviceObjects()
end

function ImplDX9:CreateTextureFromFile(path)
    local tex = lib.ImGui_ImplDX9_CreateTextureFromFile(self.d3ddevice, path)
    if tex == nil then
        return nil
    end
    return ffi.gc(tex, lib.ImGui_ImplDX9_ReleaseTexture)
end

function ImplDX9:CreateTextureFromFileInMemory(src, size)
    if type(src) == 'number' then
        src = ffi.cast('LPCVOID', src)
    end
    local tex = lib.ImGui_ImplDX9_CreateTextureFromFileInMemory(self.d3ddevice, src, size)
    if tex == nil then
        return nil
    end
    return ffi.gc(tex, lib.ImGui_ImplDX9_ReleaseTexture)
end

function ImplDX9:ReleaseTexture(tex)
    ffi.gc(tex, nil)
    lib.ImGui_ImplDX9_ReleaseTexture(tex)
end

function ImplDX9:CreateFontsTexture()
    self:SwitchContext()
    return lib.ImGui_ImplDX9_CreateDeviceObjects()
end

function ImplDX9:InvalidateFontsTexture()
    self:SwitchContext()
end

return ImplDX9
