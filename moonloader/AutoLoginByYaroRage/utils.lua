-- Модуль утилит AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local ffi = require("ffi")
local M = {}

local KEYEVENTF_KEYDOWN = 0x0
local KEYEVENTF_KEYUP = 0x2
local MOUSEEVENTF_LEFTDOWN = 0x02
local MOUSEEVENTF_LEFTUP = 0x04

function M.get_current_keyboard_layout_name()
    local foreground_window = user32.GetForegroundWindow()
    local foreground_thread = user32.GetWindowThreadProcessId(foreground_window, nil)
    local keyboard_layout = user32.GetKeyboardLayout(foreground_thread)
    local layout_id = tonumber(ffi.cast("unsigned int", keyboard_layout)) % 0x10000

    if layout_id == 0x0419 then
        return "RU"
    elseif layout_id == 0x0409 then
        return "EN"
    else
        return "UNKNOWN_" .. string.format("%04X", layout_id)
    end
end

function M.is_shift_pressed()
    return bit.band(user32.GetKeyState(0x10), 0x8000) ~= 0
end

function M.play_gta_confirm_sound()
    winmm.PlaySoundA("SystemAsterisk", nil, bit.bor(0x00010000, 0x0001))
end

function M.set_clipboard_text(str)
    user32.OpenClipboard(0)
    user32.EmptyClipboard()

    local hMem = kernel32.GlobalAlloc(0x0042, #str + 1)
    if hMem ~= 0 then
        local pMem = kernel32.GlobalLock(hMem)
        if pMem ~= 0 then
            ffi.copy(pMem, str)
            kernel32.GlobalUnlock(hMem)
            user32.SetClipboardData(1, hMem)
        end
    end

    user32.CloseClipboard()
end

function M.get_clipboard_text()
    if not user32.IsClipboardFormatAvailable(1) then return nil end
    if not user32.OpenClipboard(0) then return nil end

    local hData = user32.GetClipboardData(1)
    if hData == 0 then
        user32.CloseClipboard()
        return nil
    end

    local pData = kernel32.GlobalLock(hData)
    if pData == 0 then
        user32.CloseClipboard()
        return nil
    end

    local text = ffi.string(pData)
    kernel32.GlobalUnlock(hData)
    user32.CloseClipboard()
    return text
end

function M.click_password_field()
    local sw, sh = getScreenResolution()
    local x = math.floor(sw * 0.20)
    local y = math.floor(sh * 0.76)

    user32.SetCursorPos(x, y)
    wait(50)
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
end

function M.game_window_active()
    local hwnd = user32.FindWindowA("CDisplaya", nil)
    if hwnd == 0 then return false end
    return user32.GetForegroundWindow() == hwnd and not user32.IsIconic(hwnd)
end

function M.wait_for_game_focus()
    while not M.game_window_active() do
        wait(100)
    end
end

function M.when_game_active()
    M.wait_for_game_focus()
end

function M.is_scoreboard_or_dialog_open()
    if isSampAvailable and isSampAvailable() then
        if sampIsDialogActive() then return true end
    end
    return false
end

function M.try_close_dialog_fast()
    if isSampAvailable and isSampAvailable() and sampIsDialogActive() then
        sampCloseCurrentDialogWithButton(0)
        return true
    end
    return false
end

function M.send_paste_command()
    user32.keybd_event(0x11, 0, 0, 0)
    user32.keybd_event(0x56, 0, 0, 0)
    user32.keybd_event(0x56, 0, 2, 0)
    user32.keybd_event(0x11, 0, 2, 0)
end

return M
