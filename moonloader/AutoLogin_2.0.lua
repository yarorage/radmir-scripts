--[[
    AutoLogin 2.0 (fixed)
    MoonLoader 0.26-beta5 + SAMPFUNCS + SAMP.Lua
    RADMIR CRMP (CEF)
]]

local ffi = require('ffi')
local sampevents = require('lib.samp.events')

ffi.cdef[[
    void keybd_event(uint8_t bVk, uint8_t bScan, uint32_t dwFlags, uintptr_t dwExtraInfo);
    void mouse_event(uint32_t dwFlags, int32_t dx, int32_t dy, uint32_t dwData, uintptr_t dwExtraInfo);
    int SetCursorPos(int X, int Y);
    void* LoadKeyboardLayoutA(const char* pwszKLID, uint32_t Flags);
    void* ActivateKeyboardLayout(void* hkl, uint32_t Flags);
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow(void);
    uint32_t GetWindowThreadProcessId(void* hWnd, uint32_t* lpdwProcessId);
    int IsIconic(void* hWnd);
    short GetAsyncKeyState(int vKey);
    short GetKeyState(int nVirtKey);
    uint32_t GetKeyboardLayout(uint32_t idThread);
    int MessageBeep(uint32_t uType);
    int PlaySoundA(const char* pszSound, void* hmod, uint32_t fdwSound);
    uint32_t mciSendStringA(const char* lpszCommand, char* lpszReturnString, uint32_t cchReturn, void* hwndCallback);
    int OpenClipboard(void* hWnd);
    int EmptyClipboard(void);
    int CloseClipboard(void);
    void* GetClipboardData(uint32_t uFormat);
    void* SetClipboardData(uint32_t uFormat, void* hMem);
]]

ffi.cdef[[
    uintptr_t GlobalAlloc(uint32_t uFlags, uintptr_t dwBytes);
    uint8_t* GlobalLock(void* hMem);
    int GlobalUnlock(void* hMem);
    void* GlobalFree(void* hMem);
]]

local user32 = ffi.load("user32")
local winmm = ffi.load("winmm")
local kernel32 = ffi.load("kernel32")

local KEYEVENTF_KEYDOWN = 0x0
local KEYEVENTF_KEYUP   = 0x2
local MOUSEEVENTF_LEFTDOWN = 0x02
local MOUSEEVENTF_LEFTUP   = 0x04
local SND_ALIAS = 0x00010000
local SND_ASYNC = 0x0001
local CF_TEXT = 1
local GMEM_MOVEABLE = 0x0002
local GMEM_ZEROINIT = 0x0040

local script_name = "AutoLogin"
local config_folder = getWorkingDirectory() .. "\\config\\AutoLogin"
local config_file = config_folder .. "\\AutoLoginSettings.ini"

local password = ""
local spawn_choice = true
local script_active = true
local is_logging_in = false
local is_spawned = false
local player_in_world = false
local my_nick = ""
local reconnect_attempt_count = 0
local reconnect_pause_until = 0
local chatlog_path = nil

local waiting_for_spawn_choice = false
local current_dialog_id = -1
local spawn_timer_seconds = 0
local spawn_timer_running = false
local reconnect_cooldown_until = 0
local pending_autologin = false
local last_login_attempt = 0
local is_reconnecting = false

-- CloseMenuPause эмуляция при открытии OnPlayerOpenMenuPause:
-- окно для авторизации + ещё 5 секунд после входа
local CLOSE_MENU_EMUL_AFTER_SEC = 5
local close_menu_emul_until = 0
local last_close_menu_emul = 0
local login_submitted = false   -- пароль введён в CEF и пакет 215 ждём на вход

local force_password_form = false
local password_form_closed = false
local render_disabled = false
local render_disabled_until = 0
local reconnect_watch_active = false
local saw_loading_after_rec = false
local saw_queue_after_rec = false

-- ============ MODERN UI SYSTEM ============
local UI = {}

-- Color palette (ARGB)
UI.Colors = {
    -- Background layers
    bg_deep      = 0xFF0A0E17,  -- deepest background
    bg_card      = 0xFF111827,  -- card/panel background
    bg_card_hover= 0xFF171F33,  -- card hover
    bg_input     = 0xFF0B101A,  -- input field background
    bg_input_focus = 0xFF0F1522, -- input focus

    -- Borders
    border_subtle  = 0x332A3D6B,
    border_accent  = 0x884D7CFE,
    border_focus   = 0xFF4D7CFE,
    border_error   = 0xFFE04B5A,

    -- Text
    text_primary   = 0xFFF2F5FF,
    text_secondary = 0xFF9BA8D6,
    text_muted     = 0xFF5A6B96,
    text_accent    = 0xFF6FA0FF,
    text_error     = 0xFFFF7A90,
    text_success   = 0xFF4ADE80,

    -- Accent (blue)
    accent         = 0xFF4D7CFE,
    accent_hover   = 0xFF5B8DEF,
    accent_press   = 0xFF3D6FF2,
    accent_glow    = 0x444D7CFE,

    -- Button states
    btn_primary    = 0xFF3D6FF2,
    btn_primary_h  = 0xFF5B8DEF,
    btn_primary_p  = 0xFF2E5CD8,
    btn_secondary  = 0xFF1E2B52,
    btn_secondary_h= 0xFF2A3D8F,
    btn_danger     = 0xFFC83E4A,
    btn_danger_h   = 0xFFE04B5A,

    -- Overlay
    overlay        = 0xCC000000,
    shadow         = 0x40000000,
    shadow_strong  = 0x80000000,
}

-- Animation helpers
UI.Anim = {}
function UI.Anim.lerp(a, b, t) return a + (b - a) * t end
function UI.Anim.easeOut(t) return 1 - (1 - t)^3 end
function UI.Anim.easeInOut(t) return t < 0.5 and 4*t^3 or 1 - (-2*t + 2)^3 / 2 end

local anim_states = {}
function UI.Anim.get(id)
    if not anim_states[id] then anim_states[id] = {val = 0, target = 0, speed = 8} end
    return anim_states[id]
end
function UI.Anim.update(id, dt)
    local a = anim_states[id]
    if not a then return 0 end
    a.val = UI.Anim.lerp(a.val, a.target, 1 - math.exp(-a.speed * dt))
    return a.val
end
function UI.Anim.setTarget(id, target, speed)
    local a = UI.Anim.get(id)
    a.target = target
    a.speed = speed or a.speed
end

-- Scaling helper
local _cached_sw, _cached_sh, _cached_scale = 0, 0, 1
function UI.getScale()
    local sw, sh = getScreenResolution()
    if sw ~= _cached_sw or sh ~= _cached_sh then
        _cached_sw, _cached_sh = sw, sh
        _cached_scale = math.max(0.65, math.min(1.4, sh / 1080.0))
    end
    return _cached_scale, _cached_sw, _cached_sh
end
function UI.s(v) return math.floor(v * UI.getScale() + 0.5) end

-- Font cache
local font_cache = {}
function UI.font(name, size, flags)
    local key = name .. "_" .. size .. "_" .. (flags or 0)
    if not font_cache[key] then
        font_cache[key] = renderCreateFont(name, size, flags or 0)
    end
    return font_cache[key]
end

-- Rounded rectangle (9-slice simulation via layered boxes)
function UI.drawRoundedBox(x, y, w, h, radius, color)
    radius = math.min(radius, math.floor(math.min(w, h) / 2))
    local d = radius * 2
    -- Corners (4 small boxes for rounded effect)
    renderDrawBox(x, y, radius, radius, color)
    renderDrawBox(x + w - radius, y, radius, radius, color)
    renderDrawBox(x, y + h - radius, radius, radius, color)
    renderDrawBox(x + w - radius, y + h - radius, radius, radius, color)
    -- Edges
    renderDrawBox(x + radius, y, w - d, radius, color)
    renderDrawBox(x + radius, y + h - radius, w - d, radius, color)
    renderDrawBox(x, y + radius, radius, h - d, color)
    renderDrawBox(x + w - radius, y + radius, radius, h - d, color)
    -- Center
    renderDrawBox(x + radius, y + radius, w - d, h - d, color)
end

-- Draw shadow (multiple layers for depth)
function UI.drawShadow(x, y, w, h, radius, intensity)
    intensity = intensity or 1
    for i = 1, 4 do
        local alpha = math.floor(0x30 * intensity * (5 - i) / 4)
        local col = alpha * 0x1000000
        local offset = i * 2
        UI.drawRoundedBox(x - offset, y - offset, w + offset * 2, h + offset * 2, radius + offset, col)
    end
end

-- Glow effect
function UI.drawGlow(x, y, w, h, radius, color, intensity)
    intensity = intensity or 1
    for i = 1, 3 do
        local a = math.floor(0x20 * intensity * (4 - i) / 3)
        local col = a * 0x1000000 + (color % 0x1000000)
        local offset = i * 3
        UI.drawRoundedBox(x - offset, y - offset, w + offset * 2, h + offset * 2, radius + offset, col)
    end
end

-- Text with shadow
function UI.drawText(font, text, x, y, color, shadow)
    if shadow then
        renderFontDrawText(font, text, x + 1, y + 1, 0x80000000)
    end
    renderFontDrawText(font, text, x, y, color)
end

-- Centered text in rect
function UI.drawTextCentered(font, text, x, y, w, h, color, shadow)
    local tw = renderGetFontDrawTextLength(font, text)
    local th = renderGetFontDrawHeight(font)
    local tx = x + (w - tw) / 2
    local ty = y + (h - th) / 2
    UI.drawText(font, text, tx, ty, color, shadow)
end

-- ============ PASSWORD FORM STATE ============
local PF = {
    -- Animation states
    anim = { enter = 0, shake = 0, shake_dir = 1 },
    -- Layout (calculated each frame)
    layout = {},
    -- Input state
    input_active = false,
    temp_password = "",
    show_chars = true,
    error = "",
    error_timer = 0,
    -- Drag
    dragging = false,
    drag_offset_x = 0,
    drag_offset_y = 0,
    -- Persistent window position offset from center (top-left)
    pos = { dx = 0, dy = 0 },
}

function PF.reset()
    PF.input_active = false
    PF.temp_password = ""
    PF.show_chars = true
    PF.error = ""
    PF.error_timer = 0
    PF.anim.enter = 0
    PF.anim.shake = 0
    UI.Anim.setTarget("pf_enter", 1, 12)
end

function PF.setError(msg)
    PF.error = msg
    PF.error_timer = os.clock() + 3
    PF.anim.shake = 10
    UI.Anim.setTarget("pf_shake", 1, 20)
end

function PF.updateAnim(dt)
    PF.anim.enter = UI.Anim.update("pf_enter", dt)
    local shake_val = UI.Anim.update("pf_shake", dt)
    if PF.error_timer > 0 and os.clock() > PF.error_timer then
        PF.error = ""
        PF.error_timer = 0
        UI.Anim.setTarget("pf_shake", 0, 8)
    end
    -- Shake oscillation
    if shake_val > 0.01 then
        PF.anim.shake = math.sin(os.clock() * 40) * shake_val * 4
    else
        PF.anim.shake = 0
    end
end

-- ============ PASSWORD FORM RENDER ============
function PF.render()
    if not is_password_form_visible() then
        UI.Anim.setTarget("pf_enter", 0, 10)
        PF.anim.enter = UI.Anim.update("pf_enter", 0.016)
        if PF.anim.enter < 0.01 then return end
    end

    local dt = 1/60
    PF.updateAnim(dt)

    local sc, sw, sh = UI.getScale()
    local scf = function(v) return math.floor(v * sc + 0.5) end

    -- Form dimensions
    local fw, fh = scf(420), scf(300)
    local base_x = math.floor((sw - fw) / 2)
    local base_y = math.floor((sh - fh) / 2)
    local fx = base_x + PF.pos.dx + math.floor(PF.anim.shake)
    local fy = base_y + PF.pos.dy

    -- Store layout for hit testing
    PF.layout = {x = fx, y = fy, w = fw, h = fh}

    -- Fonts
    local font_title = UI.font("Arial", scf(20), 1)
    local font_body  = UI.font("Arial", scf(14), 0)
    local font_small = UI.font("Arial", scf(12), 0)
    local font_mono  = UI.font("Consolas", scf(15), 0)

    local alpha = math.floor(255 * PF.anim.enter)
    local function a(col) return math.floor((col % 0x1000000) + alpha * 0x1000000) end

    -- Background overlay
    renderDrawBox(0, 0, sw, sh, a(UI.Colors.overlay))

    -- Shadow
    UI.drawShadow(fx, fy, fw, fh, scf(16), 1.2)

    -- Glow
    UI.drawGlow(fx, fy, fw, fh, scf(16), UI.Colors.accent, 0.3 * PF.anim.enter)

    -- Card background
    UI.drawRoundedBox(fx, fy, fw, fh, scf(16), a(UI.Colors.bg_card))

    -- Top accent bar
    UI.drawRoundedBox(fx, fy, fw, scf(4), scf(4), a(UI.Colors.accent))

    -- Header
    local head_h = scf(64)
    local pad = scf(24)

    -- Logo circle
    local logo_size = scf(36)
    local logo_x = fx + pad
    local logo_y = fy + (head_h - logo_size) / 2
    UI.drawRoundedBox(logo_x, logo_y, logo_size, logo_size, scf(10), a(UI.Colors.accent))
    UI.drawTextCentered(font_title, "AL", logo_x, logo_y + scf(6), logo_size, logo_size, a(0xFFFFFFFF), true)

    -- Title
    UI.drawText(font_title, "AutoLogin", logo_x + logo_size + scf(14), logo_y + scf(2), a(UI.Colors.text_primary), true)
    UI.drawText(font_small, "������� ������ ��������", logo_x + logo_size + scf(14), logo_y + scf(26), a(UI.Colors.text_secondary))

    -- Close button (top right)
    local close_size = scf(32)
    local close_x = fx + fw - pad - close_size
    local close_y = fy + (head_h - close_size) / 2
    local cx, cy = getCursorPos()
    local close_hov = (cx >= close_x and cx <= close_x + close_size and cy >= close_y and cy <= close_y + close_size)
    UI.drawRoundedBox(close_x, close_y, close_size, close_size, scf(8), a(close_hov and UI.Colors.btn_danger_h or UI.Colors.bg_card_hover))
    -- X icon
    local cx1, cy1 = close_x + scf(8), close_y + scf(8)
    local cx2, cy2 = close_x + close_size - scf(8), close_y + close_size - scf(8)
    renderDrawBox(cx1, cy1 + 1, scf(14), 2, a(close_hov and 0xFFFFFFFF or UI.Colors.text_muted))
    renderDrawBox(cx1 + 1, cy1, 2, scf(14), a(close_hov and 0xFFFFFFFF or UI.Colors.text_muted))
    -- Store for click
    PF.layout.close = {x = close_x, y = close_y, w = close_size, h = close_size}

    -- Layout indicator
    local layout_name = get_current_keyboard_layout_name()
    local lay_w = scf(52)
    local lay_h = scf(28)
    local lay_x = fx + pad
    local lay_y = fy + head_h + scf(16)
    UI.drawRoundedBox(lay_x, lay_y, lay_w, lay_h, scf(6), a(UI.Colors.bg_input))
    UI.drawTextCentered(font_small, layout_name, lay_x, lay_y, lay_w, lay_h, a(UI.Colors.text_accent))

    -- Password field
    local field_x = lay_x + lay_w + scf(12)
    local field_y = lay_y
    local field_w = fw - (field_x - fx) - pad - scf(100)
    local field_h = scf(44)

    local field_hov = (cx >= field_x and cx <= field_x + field_w and cy >= field_y and cy <= field_y + field_h)
    local field_active = PF.input_active or field_hov
    local field_color = PF.input_active and UI.Colors.bg_input_focus or (field_hov and UI.Colors.bg_card_hover or UI.Colors.bg_input)
    local border_color = PF.input_active and UI.Colors.border_focus or (PF.error ~= "" and UI.Colors.border_error or (field_hov and UI.Colors.border_accent or UI.Colors.border_subtle))

    -- Field background
    UI.drawRoundedBox(field_x, field_y, field_w, field_h, scf(8), a(field_color))
    -- Border (draw slightly larger box behind)
    UI.drawRoundedBox(field_x - 1, field_y - 1, field_w + 2, field_h + 2, scf(9), a(border_color))
    UI.drawRoundedBox(field_x, field_y, field_w, field_h, scf(8), a(field_color))

    -- Placeholder / password text
    local display_text = (#PF.temp_password > 0) and (PF.show_chars and PF.temp_password or string.rep("�", #PF.temp_password)) or "������� ������..."
    local text_color = #PF.temp_password > 0 and UI.Colors.text_primary or UI.Colors.text_muted
    UI.drawText(font_mono, display_text, field_x + scf(16), field_y + (field_h - renderGetFontDrawHeight(font_mono)) / 2, a(text_color))

    -- Blinking cursor
    if PF.input_active and (os.clock() % 1.0) < 0.5 and #PF.temp_password > 0 then
        local tw = renderGetFontDrawTextLength(font_mono, display_text)
        local cur_x = field_x + scf(16) + tw + 2
        local cur_y = field_y + scf(10)
        renderDrawBox(cur_x, cur_y, 2, field_h - scf(20), a(UI.Colors.accent))
    end

    PF.layout.field = {x = field_x, y = field_y, w = field_w, h = field_h}

    -- Eye button (show/hide)
    local eye_size = field_h
    local eye_x = field_x + field_w - eye_size
    local eye_y = field_y
    local eye_hov = (cx >= eye_x and cx <= eye_x + eye_size and cy >= eye_y and cy <= eye_y + eye_size)
    UI.drawRoundedBox(eye_x, eye_y, eye_size, eye_size, scf(8), a(eye_hov and UI.Colors.btn_secondary_h or UI.Colors.bg_input))
    local eye_text = PF.show_chars and "*" or "�"
    UI.drawTextCentered(font_body, eye_text, eye_x, eye_y, eye_size, eye_size, a(eye_hov and UI.Colors.text_primary or UI.Colors.text_secondary))
    PF.layout.eye = {x = eye_x, y = eye_y, w = eye_size, h = eye_size}

    -- Submit button
    local btn_w = scf(100)
    local btn_h = field_h
    local btn_x = eye_x + eye_size + scf(10)
    local btn_y = field_y
    local btn_hov = (cx >= btn_x and cx <= btn_x + btn_w and cy >= btn_y and cy <= btn_y + btn_h)
    local btn_press = btn_hov and (user32.GetAsyncKeyState(0x01) < 0)
    local btn_color = btn_press and UI.Colors.btn_primary_p or (btn_hov and UI.Colors.btn_primary_h or UI.Colors.btn_primary)
    UI.drawRoundedBox(btn_x, btn_y, btn_w, btn_h, scf(8), a(btn_color))
    -- Highlight top
    renderDrawBox(btn_x + scf(2), btn_y + scf(2), btn_w - scf(4), 2, a(0x33FFFFFF))
    UI.drawTextCentered(font_body, "�����", btn_x, btn_y, btn_w, btn_h, a(0xFFFFFFFF), true)
    PF.layout.submit = {x = btn_x, y = btn_y, w = btn_w, h = btn_h}

    -- Error message
    if PF.error ~= "" then
        local err_y = field_y + field_h + scf(10)
        local err_w = renderGetFontDrawTextLength(font_small, PF.error)
        UI.drawText(font_small, PF.error, fx + (fw - err_w) / 2, err_y, a(UI.Colors.text_error), true)
    end

    -- Hint row
    local hint_y = fy + fh - scf(50)
    local hint1 = "Enter � ����� � Esc � ������� � Ctrl+V"
    UI.drawText(font_small, hint1, fx + pad, hint_y, a(UI.Colors.text_muted))
    local hint2 = "������: config/AutoLogin"
    UI.drawText(font_small, hint2, fx + pad, hint_y + scf(18), a(0xFF4A5A8C))

    -- Version badge
    local ver_text = "v2.0"
    local ver_w = renderGetFontDrawTextLength(font_small, ver_text)
    UI.drawText(font_small, ver_text, fx + fw - pad - ver_w, hint_y + scf(18), a(UI.Colors.text_muted))

    -- Handle input/events
    PF.handleEvents(cx, cy, close_hov, field_hov, eye_hov, btn_hov, btn_press)
end

function PF.handleEvents(cx, cy, close_hov, field_hov, eye_hov, btn_hov, btn_press)
    local lclick = user32.GetAsyncKeyState(0x01) < 0

    -- Click detection (on release)
    if PF.last_click and not lclick then
        if close_hov then
            if password == "" then
                chat_msg("{FF3333}������� ������� ������ � ��� ���� �������� �� ��������!")
            else
                close_password_form()
            end
        elseif field_hov then
            PF.input_active = true
        elseif eye_hov then
            PF.show_chars = not PF.show_chars
        elseif btn_hov and #PF.temp_password > 0 then
            password = PF.temp_password
            save_config()
            play_gta_confirm_sound()
            chat_msg("������ ������� ���������� ����� ����������� �����!")
            on_password_saved()
        elseif not (cx >= PF.layout.x and cx <= PF.layout.x + PF.layout.w and cy >= PF.layout.y and cy <= PF.layout.y + PF.layout.h) then
            PF.input_active = false
        end
    end
    PF.last_click = lclick

    -- Drag to move (hold on header)
    if PF.dragging then
        if lclick then
            local nx = cx - PF.drag_offset_x
            local ny = cy - PF.drag_offset_y
            local sc, sw, sh = UI.getScale()
            local scf = function(v) return math.floor(v * sc + 0.5) end
            local max_dx = math.floor((sw - PF.layout.w) / 2) + scf(420) - scf(80)
            local max_dy = math.floor((sh - PF.layout.h) / 2) + scf(300) - scf(80)
            PF.pos.dx = math.max(-max_dx, math.min(max_dx, nx - math.floor((sw - PF.layout.w) / 2)))
            PF.pos.dy = math.max(-max_dy, math.min(max_dy, ny - math.floor((sh - PF.layout.h) / 2)))
        else
            PF.dragging = false
        end
    elseif lclick and not btn_press and not close_hov and not eye_hov and not field_hov
        and cx >= PF.layout.x and cx <= PF.layout.x + PF.layout.w
        and cy >= PF.layout.y and cy <= PF.layout.y + scf(64) then
        PF.dragging = true
        PF.drag_offset_x = cx - PF.layout.x
        PF.drag_offset_y = cy - PF.layout.y
        PF.last_click = false
    end

    -- Keyboard input when active
    -- Character input and Backspace handled via onWindowMessage/onChar
end

-- Key press helper
local key_state = {}
function wasKeyPressed(vk)
    local down = user32.GetAsyncKeyState(vk) < 0
    local pressed = down and not (key_state[vk] or false)
    key_state[vk] = down
    return pressed
end

-- ============ END UI SYSTEM ============

local mafk_active = false
local mafk_hold_start = 0
local mafk_notify_until = 0
local afk_mode = 0
local auto_restart = true

local afk_templates = {
    { {'x',1}, {'y',1}, {'x',-1}, {'y',-1} },
    { {'x',1}, {'y',1}, {'x',1}, {'y',-1}, {'x',-1}, {'y',-1}, {'x',-1}, {'y',1} },
    { {'x',1}, {'y',1}, {'x',-1}, {'y',1}, {'x',-1}, {'y',-1}, {'x',1}, {'y',-1} },
    { {'x',1}, {'y',1}, {'x',-1}, {'y',1}, {'x',1}, {'y',-1}, {'x',-1}, {'y',-1} },
    { {'x',1}, {'y',1}, {'x',-1}, {'y',-1}, {'x',-1}, {'y',1}, {'x',1}, {'y',-1} },
    { {'x',1}, {'y',1}, {'x',-1}, {'y',-1}, {'x',1}, {'y',1}, {'x',-1}, {'y',-1} },
    { {'x',1}, {'y',1}, {'x',1}, {'y',-1}, {'x',-1}, {'y',1}, {'x',-1}, {'y',-1} },
    { {'x',1}, {'y',1}, {'x',-1}, {'y',-1}, {'x',1}, {'y',-1}, {'x',-1}, {'y',1} },
    { {'x',1}, {'y',1}, {'x',1}, {'y',-1}, {'x',-1}, {'y',-1}, {'x',-1}, {'y',1} },
    { {'x',1}, {'y',-1}, {'x',-1}, {'y',1}, {'x',1}, {'y',1}, {'x',-1}, {'y',-1} },
    { {'x',1}, {'y',1}, {'x',-1}, {'y',-1}, {'x',1}, {'y',-1}, {'x',-1}, {'y',1} },
}

local function generate_afk_route(template)
    local result = {}
    local x_fwd, x_bwd, y_fwd, y_bwd = {}, {}, {}, {}
    for _, t in ipairs(template) do
        local entry = {axis=t[1], dir=t[2], time=2.0}
        table.insert(result, entry)
        if t[1] == 'x' then
            if t[2] == 1 then table.insert(x_fwd, entry) else table.insert(x_bwd, entry) end
        else
            if t[2] == 1 then table.insert(y_fwd, entry) else table.insert(y_bwd, entry) end
        end
    end
    local cx = math.min(#x_fwd, #x_bwd)
    for i = 1, cx do
        local t = math.random(1000, 3000) / 1000.0
        x_fwd[i].time = t
        x_bwd[i].time = t
    end
    local cy = math.min(#y_fwd, #y_bwd)
    for i = 1, cy do
        local t = math.random(1000, 3000) / 1000.0
        y_fwd[i].time = t
        y_bwd[i].time = t
    end
    return result
end
local function mafk_flag_path()
    local folder = (thisScript and thisScript().folder) or getWorkingDirectory()
    return folder .. "\\..\\mafk_on.flag"
end

local function update_mafk_config()
    if not doesDirectoryExist(config_folder) then createDirectory(config_folder) end
    local content = ""
    if doesFileExist(config_file) then
        local fr = io.open(config_file, "r")
        if fr then content = fr:read("*all") fr:close() end
    end
    local newval = 'MafkEnabled = ' .. tostring(mafk_active)
    if content:find('MafkEnabled%s*=') then
        content = content:gsub('MafkEnabled%s*=%s*%a+', newval)
    else
        content = content .. '\n' .. newval
    end
    local fw = io.open(config_file, "w")
    if fw then fw:write(content) fw:close() end
end

local function sync_mafk_flag()
    if auto_restart and mafk_active then
        local f = io.open(mafk_flag_path(), "w")
        if f then
            f:write("1")
            f:close()
        end
    else
        if doesFileExist(mafk_flag_path()) then
            os.remove(mafk_flag_path())
        end
    end
    update_mafk_config()
end

-- forward declarations
local wait_for_game_focus
local schedule_autologin_after_reconnect
local perform_login
local on_password_saved
local close_password_form
local is_password_form_visible
local mark_queue_seen
local start_reconnect_watch
local mark_manual_reconnect
local emulate_loading_close_auth
local post_loading_login_watch
local emulate_close_menu_pause
local emulate_reconnect_ui_cleanup
local finish_reconnect
local in_close_menu_emul_window

local ywelcome_status, ywelcome = pcall(require, "ywelcome")
if not ywelcome_status then
    ywelcome_status, ywelcome = pcall(require, "ywelcom")
end

local encoding = require 'encoding'
encoding.default = 'CP1251'

local debug_step = 0
local function log(msg)
    print(string.format("[%s] %s", script_name, msg))
end
local function dlog(msg)
    debug_step = debug_step + 1
    log(string.format("STEP#%03d (%.2fs) %s", debug_step, os.clock(), msg))
end

in_close_menu_emul_window = function()
    if is_reconnecting then
        return true
    end
    return close_menu_emul_until > 0 and os.clock() < close_menu_emul_until
end

finish_reconnect = function(reason)
    if is_reconnecting then
        close_menu_emul_until = os.clock() + CLOSE_MENU_EMUL_AFTER_SEC
        log("reconnect end (" .. tostring(reason) .. ") — CloseMenu window 5s")
    end
    is_reconnecting = false
end

local function chat_msg(msg)
    sampAddChatMessage(string.format("{FFCC00}[%s] {FFFFFF}%s", script_name, msg), -1)
end

local function get_current_keyboard_layout_name()
    local hwnd = user32.GetForegroundWindow()
    local threadId = user32.GetWindowThreadProcessId(hwnd, nil)
    local hkl = user32.GetKeyboardLayout(threadId)
    local langID = bit.band(tonumber(ffi.cast("uint32_t", hkl)), 0xFFFF)
    if langID == 0x0419 then return "RU"
    elseif langID == 0x0409 then return "EN"
    else return string.format("%04X", langID) end
end

local function is_shift_pressed()
    return (user32.GetAsyncKeyState(0x10) < 0)
end

local function play_gta_confirm_sound()
    winmm.PlaySoundA("SystemAsterisk", nil, bit.bor(SND_ALIAS, SND_ASYNC))
end

local AUTH_SOUND_PATH = getWorkingDirectory() .. "\\resource\\authSound.mp3"

-- Уведомление, когда надо ввести пароль, а игра свёрнута (mp3 через MCI)
local function play_auth_sound()
    pcall(function()
        if not doesFileExist(AUTH_SOUND_PATH) then
            log("authSound.mp3 не найден: " .. AUTH_SOUND_PATH)
            return
        end
        winmm.mciSendStringA('close autologin_snd', nil, 0, nil)
        winmm.mciSendStringA('open "' .. AUTH_SOUND_PATH .. '" type mpegvideo alias autologin_snd', nil, 0, nil)
        winmm.mciSendStringA('play autologin_snd from 0', nil, 0, nil)
    end)
end

local function set_clipboard_text(str)
    str = str or ""
    local hmem = kernel32.GlobalAlloc(bit.bor(GMEM_MOVEABLE, GMEM_ZEROINIT), #str + 1)
    if hmem == nil then return false end
    local ptr = kernel32.GlobalLock(hmem)
    if ptr == nil then
        kernel32.GlobalFree(hmem)
        return false
    end
    if #str > 0 then ffi.copy(ptr, str, #str) end
    kernel32.GlobalUnlock(hmem)
    local ok = false
    if user32.OpenClipboard(nil) ~= 0 then
        user32.EmptyClipboard()
        if user32.SetClipboardData(CF_TEXT, hmem) ~= nil then
            ok = true
            hmem = nil
        end
        user32.CloseClipboard()
    end
    if hmem ~= nil then
        kernel32.GlobalFree(hmem)
    end
    return ok
end

local function get_clipboard_text()
    local text = ""
    if user32.OpenClipboard(nil) == 0 then
        return text
    end
    local hmem = user32.GetClipboardData(CF_TEXT)
    if hmem ~= nil then
        local ptr = kernel32.GlobalLock(hmem)
        if ptr ~= nil then
            text = ffi.string(ptr)
            kernel32.GlobalUnlock(hmem)
        end
    end
    user32.CloseClipboard()
    return text
end

is_password_form_visible = function()
    return (password == "" or force_password_form) and not password_form_closed
end

mark_queue_seen = function(source)
    if saw_queue_after_rec then
        return
    end
    saw_queue_after_rec = true
    reconnect_watch_active = false
    log("Очередь на сервер (" .. tostring(source) .. ") — watchdog снят")
end

local function find_chatlog_path()
    local userprofile = os.getenv("USERPROFILE")
    local possible_folders = {"Documents", "Документы"}
    if userprofile then
        for _, folder in ipairs(possible_folders) do
            local path = userprofile .. "\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
            if doesFileExist(path) then return path end
        end
    end
    local drives = {"C", "D", "E", "F", "G", "H"}
    for _, drive in ipairs(drives) do
        for _, folder in ipairs(possible_folders) do
            local path = drive .. ":\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
            if doesFileExist(path) then return path end
        end
    end
    if userprofile then
        for _, folder in ipairs(possible_folders) do
            local default_path = userprofile .. "\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
            if doesDirectoryExist(userprofile .. "\\" .. folder .. "\\RADMIR CRMP User Files\\SAMP") then
                return default_path
            end
        end
    end
    return "D:\\Documents\\RADMIR CRMP User Files\\SAMP\\chatlog.txt"
end

local function save_config()
    if not doesDirectoryExist(config_folder) then createDirectory(config_folder) end
    local file = io.open(config_file, "w")
    if file then
        file:write(string.format('Password = "%s"\nSpawnChoice = %s\nScriptActive = %s\nAutoRestart = %s\nMafkEnabled = %s\n', password, tostring(spawn_choice), tostring(script_active), tostring(auto_restart), tostring(mafk_active)))
        file:close()
        log("Конфигурация сохранена.")
    else
        log("Ошибка записи конфига!")
    end
end

local function ensure_config_exists()
    if not doesDirectoryExist(config_folder) then createDirectory(config_folder) end
    local file = io.open(config_file, "w")
    if file then
        file:write('Password = ""\nSpawnChoice = true\nScriptActive = true\nAutoRestart = true\nMafkEnabled = false\n')
        file:close()
    end
end

local function load_config()
    if doesFileExist(config_file) then
        local f = io.open(config_file, "r")
        if f then
            local content = f:read("*all")
            f:close()
            local pass_match = content:match('Password%s*=%s*"(.-)"')
            if pass_match and #pass_match > 0 then
                password = pass_match
                if ywelcome_status and type(ywelcome) == "function" then
                    ywelcome(script_name, "Скрипт запущен. Файл конфигурации с паролем {33FF33}найден{FFFFFF}. Используйте /alhelp для справки.")
                end
            else
                if ywelcome_status and type(ywelcome) == "function" then
                    ywelcome(script_name, "Скрипт запущен. Файл конфигурации с паролем {FF3333}не найден{FFFFFF}. Введите пароль в форме на экране.")
                end
            end
            local spawn_match = content:match('SpawnChoice%s*=%s*(%a+)')
            spawn_choice = (spawn_match ~= "false")
            local active_match = content:match('ScriptActive%s*=%s*(%a+)')
            script_active = (active_match ~= "false")
            local restart_match = content:match('AutoRestart%s*=%s*(%a+)')
            auto_restart = (restart_match ~= "false")
            local mafk_match = content:match('MafkEnabled%s*=%s*(%a+)')
            mafk_active = (mafk_match == "true")
        end
    else
        ensure_config_exists()
        if ywelcome_status and type(ywelcome) == "function" then
            ywelcome(script_name, "Скрипт запущен. Файл конфигурации с паролем {FF3333}не найден{FFFFFF}. Введите пароль в форме на экране.")
        end
    end
end

local function trigger_reconnect()
    local now = os.clock()
    if is_reconnecting then
        log("Реконнект уже идёт — пропуск")
        return
    end
    if now < reconnect_cooldown_until then
        log("Реконнект пропущен (cooldown)")
        return
    end
    if now < reconnect_pause_until then
        log("Реконнект пропущен (пауза после безуспешных попыток)")
        return
    end
    reconnect_attempt_count = reconnect_attempt_count + 1
    if reconnect_attempt_count >= 3 then
        reconnect_attempt_count = 0
        reconnect_pause_until = now + 300
        log("Реконнект: 3 безуспешные попытки подряд — пауза 5 минут")
    end
    reconnect_cooldown_until = now + 25
is_reconnecting = true
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    login_submitted = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    spawn_timer_running = false
    pending_autologin = true
    chat_msg("{FF3333}������� ��������! ��������� ���������...")
    log("trigger_reconnect()")
    start_reconnect_watch()

    lua_thread.create(function()
        wait(600)
        pcall(wait_for_game_focus)
        wait(300)

        local ip, port = sampGetCurrentServerAddress()
        local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
        if hwnd ~= nil and user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd then
            user32.keybd_event(0x7A, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x7A, 0, KEYEVENTF_KEYUP, 0)
            log("Реконнект: F11 (один раз). Ждём AuthorizationT, пароль не вводим вслепую.")
            wait(800)
            emulate_reconnect_ui_cleanup()
        elseif ip and port then
            pcall(function() sampDisconnectWithReason(false) end)
            wait(1000)
            sampConnectToServer(ip, port)
            log("Реконнект: sampConnectToServer")
            wait(800)
            emulate_reconnect_ui_cleanup()
        else
            sampSendChat("/rec 3")
            log("Реконнект: /rec 3")
            wait(800)
            emulate_reconnect_ui_cleanup()
        end

        -- ожидание окна авторизации до 60 сек активного времени (при свёрнутой игре — пауза)
        local timeout_remaining = 60.0
        local last2 = os.clock()
        while timeout_remaining > 0 do
            wait(200)
            if game_window_active() then
                local now2 = os.clock()
                timeout_remaining = timeout_remaining - (now2 - last2)
            end
            last2 = os.clock()
            if not is_reconnecting then break end
        end
        if is_reconnecting then
            finish_reconnect("timeout 60s")
        end
    end)
end

local function register_commands()
    sampRegisterChatCommand("setpass", function(arg)
        if arg:len() == 0 then
            chat_msg("Использование: /setpass <пароль>")
            return
        end
        password = arg
        save_config()
        chat_msg("Пароль успешно установлен.")
        on_password_saved()
    end)

    sampRegisterChatCommand("mspawn", function()
        spawn_choice = not spawn_choice
        save_config()
        local status = spawn_choice and "{33FF33}Да (Enter)" or "{FF3333}Нет (Esc)"
        chat_msg("Переключить спавн на точке выхода: " .. status)
    end)

    sampRegisterChatCommand("alogin", function()
        script_active = not script_active
        save_config()
        local status = script_active and "{33FF33}Включен" or "{FF3333}Выключен"
        chat_msg("Автологин: " .. status)
    end)

    sampRegisterChatCommand("mafk", function()
        mafk_active = not mafk_active
        mafk_notify_until = os.clock() + 4
        play_gta_confirm_sound()
        if mafk_active then
            player_in_world = true
        end
        local status = mafk_active and "{33FF33}Включен" or "{FF3333}Выключен"
        chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} режим: " .. status)
        sync_mafk_flag()
    end)

    sampRegisterChatCommand("afk", function(arg)
        local n = tonumber(arg)
        if arg == "" or arg == "mix" then
            afk_mode = 0
            chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Маршрут: random mix")
        elseif n and n >= 1 and n <= 11 then
            afk_mode = math.floor(n)
            chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Маршрут: " .. afk_mode)
        else
            chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Использование: /afk [mix/1-11]")
        end
    end)

    sampRegisterChatCommand("autostart", function()
        auto_restart = not auto_restart
        save_config()
        local status = auto_restart and "{33FF33}Включен" or "{FF3333}Выключен"
        chat_msg("Автозапуск игры при mafk: " .. status)
        sync_mafk_flag()
    end)

    sampRegisterChatCommand("alhelp", function()
        chat_msg("Список команд скрипта:")
        chat_msg("/setpass <пароль> — установить пароль для входа")
        chat_msg("/alogin — включить или выключить автологин")
        chat_msg("/mspawn — переключить спавн на точке выхода")
        chat_msg("/mafk — включить/выключить анти-AFK (или удержание прав. Ctrl 1.5с)")
        chat_msg("/afk [mix/1-11] — выбрать маршрут анти-AFK (mix=random)")
        chat_msg("/autostart — включить/выключить автозапуск игры при активном mafk")
        chat_msg("/alhelp — показать эту справку")
    end)
end

local function click_password_field()
    local screen_w, screen_h = getScreenResolution()
    local target_x = math.floor(screen_w * 0.20)
    local target_y = math.floor(screen_h * 0.76)

    user32.SetCursorPos(target_x, target_y)
    wait(50)
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    wait(50)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
    wait(50)
end

wait_for_game_focus = function()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    if hwnd ~= nil then
        while true do
            if user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd then
                break
            end
            wait(500)
        end
    end
end

-- Активна ли игра: окно не свёрнуто и находится в фокусе (развёрнуто)
local function game_window_active()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    return hwnd ~= nil and user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd
end

-- Пауза: блокирует текущий поток, пока игра находится не в фокусе (свёрнута).
-- При развёртывании окна поток продолжает работу с того же места.
local function when_game_active()
    while not game_window_active() do
        wait(200)
    end
end

local function clear_input_field()
    dlog("clear_input_field: клик по полю пароля")
    click_password_field()
    wait(200)
    dlog("clear_input_field: Ctrl+A")
    user32.keybd_event(0x11, 0, KEYEVENTF_KEYDOWN, 0)
    wait(50)
    user32.keybd_event(0x41, 0, KEYEVENTF_KEYDOWN, 0)
    wait(50)
    user32.keybd_event(0x41, 0, KEYEVENTF_KEYUP, 0)
    user32.keybd_event(0x11, 0, KEYEVENTF_KEYUP, 0)
    wait(100)
    dlog("clear_input_field: Backspace")
    user32.keybd_event(0x08, 0, KEYEVENTF_KEYDOWN, 0)
    wait(50)
    user32.keybd_event(0x08, 0, KEYEVENTF_KEYUP, 0)
    wait(200)
    dlog("clear_input_field: готово")
end

local function type_password()
    local caps_was_on = bit.band(user32.GetKeyState(0x14), 1) == 1
    dlog("type_password: начало, caps=" .. tostring(caps_was_on) .. ", len=" .. #password)
    if caps_was_on then
        user32.keybd_event(0x14, 0, KEYEVENTF_KEYDOWN, 0)
        wait(50)
        user32.keybd_event(0x14, 0, KEYEVENTF_KEYUP, 0)
        wait(100)
    end
    local shift_map = {
        ['!'] = 0x31, ['@'] = 0x32, ['#'] = 0x33, ['$'] = 0x34, ['%'] = 0x35,
        ['^'] = 0x36, ['&'] = 0x37, ['*'] = 0x38, ['('] = 0x39, [')'] = 0x30,
        ['_'] = 0xBD, ['+'] = 0xBB, ['{'] = 0xDB, ['}'] = 0xDD, ['|'] = 0xDC,
        [':'] = 0xBA, ['"'] = 0xDE, ['<'] = 0xBC, ['>'] = 0xBE, ['?'] = 0xBF,
        ['~'] = 0xC0,
    }
    local normal_map = {
        ['-'] = 0xBD, ['='] = 0xBB, ['['] = 0xDB, [']'] = 0xDD, ['\\'] = 0xDC,
        [';'] = 0xBA, ["'"] = 0xDE, [','] = 0xBC, ['.'] = 0xBE, ['/'] = 0xBF,
        ['`'] = 0xC0, [' '] = 0x20,
    }
    local dropped = {}
    for i = 1, #password do
        local ch = password:sub(i, i)
        local vkey = 0
        local needs_shift = false
        if ch >= 'a' and ch <= 'z' then
            vkey = string.byte(ch) - 32
        elseif ch >= 'A' and ch <= 'Z' then
            vkey = string.byte(ch)
            needs_shift = true
        elseif ch >= '0' and ch <= '9' then
            vkey = string.byte(ch)
        elseif shift_map[ch] then
            vkey = shift_map[ch]
            needs_shift = true
        elseif normal_map[ch] then
            vkey = normal_map[ch]
        end
        if vkey ~= 0 then
            if needs_shift then
                user32.keybd_event(0x10, 0, KEYEVENTF_KEYDOWN, 0)
                wait(25)
            end
            user32.keybd_event(vkey, 0, KEYEVENTF_KEYDOWN, 0)
            wait(30)
            user32.keybd_event(vkey, 0, KEYEVENTF_KEYUP, 0)
            wait(30)
            if needs_shift then
                user32.keybd_event(0x10, 0, KEYEVENTF_KEYUP, 0)
                wait(25)
            end
        else
            dropped[#dropped + 1] = ch
        end
        wait(40)
    end
    if caps_was_on then
        user32.keybd_event(0x14, 0, KEYEVENTF_KEYDOWN, 0)
        wait(50)
        user32.keybd_event(0x14, 0, KEYEVENTF_KEYUP, 0)
        wait(100)
    end
    dlog("type_password: ввод завершён (caps был " .. tostring(caps_was_on) .. ")")
    if #dropped > 0 then
        log("type_password: предупреждение — не мог точно ввести " .. #dropped ..
            " символов пароля (не поддерживаются эмуляцией): " .. table.concat(dropped, ""))
    end
end

emulate_loading_close_auth = function()
    if is_spawned or login_submitted or is_logging_in then
        log("Loading[3000] пропуск (уже вход/выход)")
        return
    end
    local ok, err = pcall(function()
        local bs = raknetNewBitStream()
        local bytes = {
            2, 0, 4, 0, 0, 0, 2,
            7, 0, 0, 0, 76, 111, 97, 100, 105, 110, 103,
            6, 0, 0, 0, 91, 51, 48, 48, 48, 93
        }
        for i = 1, #bytes do
            raknetBitStreamWriteInt8(bs, bytes[i])
        end
        raknetEmulPacketReceiveBitStream(215, bs)
        raknetDeleteBitStream(bs)
    end)
    if ok then
        log("Эмуляция Loading[3000] x1 (reconnect)")
    else
        log("Эмуляция Loading[3000] ошибка: " .. tostring(err))
    end
end

emulate_close_menu_pause = function(times)
    if is_spawned or login_submitted then
        log("CloseMenuPause пропуск (уже вход/выход)")
        return
    end
    times = times or 1
    local ok, err = pcall(function()
        for n = 1, times do
            local bs = raknetNewBitStream()
            local bytes = {
                2, 0, 0, 0, 0, 0,
                22, 0, 0, 0,
                79, 110, 80, 108, 97, 121, 101, 114, 67, 108, 111, 115, 101, 77, 101, 110, 117, 80, 97, 117, 115, 101,
                0, 0, 0, 0
            }
            for i = 1, #bytes do
                raknetBitStreamWriteInt8(bs, bytes[i])
            end
            raknetEmulPacketReceiveBitStream(215, bs)
            raknetDeleteBitStream(bs)
            if n < times then
                wait(80)
            end
        end
    end)
    if ok then
        log("Эмуляция OnPlayerCloseMenuPause x" .. tostring(times))
    else
        log("Эмуляция OnPlayerCloseMenuPause ошибка: " .. tostring(err))
    end
end

emulate_reconnect_ui_cleanup = function()
    emulate_loading_close_auth()
end

start_reconnect_watch = function()
    reconnect_watch_active = true
    saw_loading_after_rec = false
    saw_queue_after_rec = false
    log("Watchdog реконнекта: 20 сек (ждём Загрузка / очередь; отсчёт только при развёрнутой игре)")
    lua_thread.create(function()
        local remaining = 20.0
        local last_t = os.clock()
        while reconnect_watch_active and remaining > 0 do
            wait(200)
            if game_window_active() then
                local now = os.clock()
                remaining = remaining - (now - last_t)
            end
            last_t = os.clock()
            if saw_loading_after_rec or saw_queue_after_rec or is_spawned or login_submitted then
                reconnect_watch_active = false
                log("Watchdog: ок (загрузка/очередь/спавн/вход) — F11 не нужен")
                return
            end
        end
        if reconnect_watch_active
            and not saw_loading_after_rec
            and not saw_queue_after_rec
            and not is_spawned
            and not login_submitted
            and not is_logging_in then
            reconnect_watch_active = false
            log("Watchdog: 20с без загрузки и без очереди — принудительный F11")
            is_spawned = false
            is_logging_in = false
            lua_thread.create(function()
                if login_submitted or is_spawned then return end
                local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
                if hwnd ~= nil then
                    if not (user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd) then
                        log("Watchdog: жду фокуса GTA, затем F11")
                    end
                    wait_for_game_focus()
                    wait(200)
                    user32.keybd_event(0x7A, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(50)
                    user32.keybd_event(0x7A, 0, KEYEVENTF_KEYUP, 0)
                    log("Watchdog: F11 отправлен")
                    wait(800)
                    if login_submitted or is_spawned then return end
                    emulate_reconnect_ui_cleanup()
                else
                    log("Watchdog: окно GTA не найдено — F11 пропущен")
                end
                is_spawned = false
                pending_autologin = true
                start_reconnect_watch()
            end)
        else
            reconnect_watch_active = false
        end
    end)
end

mark_manual_reconnect = function(reason)
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    login_submitted = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    spawn_timer_running = false
    pending_autologin = true
    last_login_attempt = 0
    close_menu_emul_until = os.clock() + CLOSE_MENU_EMUL_AFTER_SEC
    log("������ ��������� (" .. tostring(reason) .. ") � is_spawned=false")
    start_reconnect_watch()
    lua_thread.create(function()
        wait(800)
        emulate_reconnect_ui_cleanup()
    end)
end

post_loading_login_watch = function()
    if reconnect_watch_active then return end
    if is_spawned or login_submitted then return end
    log("Watchdog: Загрузка поймана — контроль входа 30 сек (отсчёт только при развёрнутой игре)")
    lua_thread.create(function()
        local remaining = 30.0
        local last_t = os.clock()
        while remaining > 0 do
            wait(200)
            if game_window_active() then
                local now = os.clock()
                remaining = remaining - (now - last_t)
            end
            last_t = os.clock()
            if is_spawned or login_submitted then
                log("Watchdog: вход/спавн за 30с — контроль отменён")
                return
            end
        end
        if is_spawned or login_submitted or not script_active then return end
        log("Watchdog: 30с после Загрузки без входа — следим заново")
        start_reconnect_watch()
    end)
end

admin_kicked_our_player = function(source_text)
    local nick = my_nick
    if #nick == 0 then return false end
    if not source_text:find('кикнул игрока') then return false end
    return source_text:find(nick, 1, true) ~= nil
end

handle_admin_kick = function(source_text, where)
    if is_reconnecting then
        log(where .. ": кик замечен, но реконнект уже идёт — пропуск")
        return
    end
    if not admin_kicked_our_player(source_text) then return end
    log(where .. ": Администратор кикнул нас — реконнект")
    trigger_reconnect()
end

on_password_saved = function()
    is_spawned = false
    is_logging_in = false
    pending_autologin = true
    last_login_attempt = 0
    force_password_form = false
    PF.error = ""
    password_form_closed = true
    render_disabled = true
    dlog("on_password_saved: ������ ���������� (len=" .. #password .. ")")
    log("������ �������� � ������� �������� � �������� CEF-�����")
    lua_thread.create(function()
        local wait_remaining = 0.3
        local last_t = os.clock()
        while wait_remaining > 0 do
            wait(200)
            if game_window_active() then
                local now = os.clock()
                wait_remaining = wait_remaining - (now - last_t)
            end
            last_t = os.clock()
        end
        dlog("on_password_saved-thread: +300ms, �������� perform_login")
        if not is_spawned and password ~= "" and script_active then
            perform_login()
        end
        for i = 1, 2 do
            wait_remaining = 2.0
            last_t = os.clock()
            while wait_remaining > 0 do
                wait(200)
                if game_window_active() then
                    local now = os.clock()
                    wait_remaining = wait_remaining - (now - last_t)
                end
                last_t = os.clock()
            end
            if is_spawned or password == "" or not script_active then return end
            if not is_logging_in then
                dlog("on_password_saved-thread: ������ ��������� #" .. i)
                perform_login()
            end
        end
    end)
end

close_password_form = function()
    local retry_old_password = (force_password_form or PF.error ~= "") and password ~= ""
    password_form_closed = true
    force_password_form = false
    PF.error = ""
    PF.input_active = false
    PF.temp_password = ""
    PF.show_chars = true
    log("��������� ����� ����� ������")
    if retry_old_password and script_active then
        log("������� ����� ������ �������, ���� �� ��� ��� ��������")
        last_login_attempt = 0
        is_logging_in = false
        login_submitted = false
        is_spawned = false
        pending_autologin = true
        lua_thread.create(function()
            local wait_remaining = 0.4
            local last_t = os.clock()
            while wait_remaining > 0 do
                wait(200)
                if game_window_active() then
                    local now = os.clock()
                    wait_remaining = wait_remaining - (now - last_t)
                end
                last_t = os.clock()
            end
            if not is_spawned and password ~= "" and script_active then
                perform_login()
            end
        end)
    end
end

perform_login = function()
    if not script_active then return end
    if password == "" then
        log("perform_login: ������ ������")
        return
    end
    if is_logging_in then
        log("perform_login: ��� ��� ����")
        return
    end
    if is_spawned then
        log("perform_login: is_spawned=true, �����")
        return
    end
    is_logging_in = true
    local now = os.clock()
    if now - last_login_attempt < 2.5 then
        log("perform_login: ��������")
        is_logging_in = false
        return
    end
    last_login_attempt = now
    pending_autologin = false
    close_menu_emul_until = 0
    reconnect_watch_active = false
    render_disabled = true
    dlog("perform_login: ����� ����� ������ (len=" .. #password .. ")")

    lua_thread.create(function()
        dlog("perform_login-thread: начало, ждём фокус")
        -- Ограниченное ожидание фокуса: не блокируем is_logging_in вчистую
        local deadline = os.clock() + 300
        while os.clock() < deadline and not game_window_active() do
            wait(500)
        end
        if not game_window_active() then
            is_logging_in = false
            dlog("perform_login-thread: фокус не получен за 5 мин, выход")
            return
        end
        wait(1200)
        if is_spawned then
            is_logging_in = false
            dlog("perform_login-thread: is_spawned уже true, выход")
            return
        end
        dlog("perform_login-thread: переключение раскладки EN")
        local hkl = user32.LoadKeyboardLayoutA("00000409", 1)
        if hkl ~= nil then
            user32.ActivateKeyboardLayout(hkl, 0)
        end
        wait(300)
        dlog("perform_login-thread: clear_input_field")
        clear_input_field()
        wait(200)
        dlog("perform_login-thread: type_password")
        type_password()
        wait(200)
        dlog("perform_login-thread: отправка Enter (0x0D)")
        user32.keybd_event(0x0D, 0, KEYEVENTF_KEYDOWN, 0)
        wait(30)
        user32.keybd_event(0x0D, 0, KEYEVENTF_KEYUP, 0)
        login_submitted = true
        close_menu_emul_until = 0
        reconnect_watch_active = false
        dlog("perform_login-thread: Enter отправлен, ждём CEF-пакет 215")
        wait(600)
        is_logging_in = false
        dlog("perform_login-thread: завершено")
    end)
end

schedule_autologin_after_reconnect = function()
    pending_autologin = true
    is_spawned = false
    is_logging_in = false
    log("schedule: ��� ����� AuthorizationT[auth] (��� ������� �����; ������ ������ ��� ���������� ����)")
    lua_thread.create(function()
        local remaining = 40.0
        local last_t = os.clock()
        while remaining > 0 do
            wait(200)
            if game_window_active() then
                local now = os.clock()
                remaining = remaining - (now - last_t)
            end
            last_t = os.clock()
            if is_spawned or not script_active then
                pending_autologin = false
                return
            end
        end
        pending_autologin = false
        log("schedule: timeout �������� �����")
    end)
end

function sampevents.onServerMessage(color, text)
    local lower_text = text:lower()
    if (not saw_queue_after_rec) and (
        lower_text:find("нет свободных мест")
        or (lower_text:find("очеред") and lower_text:find("сервер"))
        or lower_text:find("в очереди")
    ) then
        mark_queue_seen("chat")
    end
    if lower_text:find("the server is restarting")
        or lower_text:find("����������� �")
        or lower_text:find("�������������� �")
        or lower_text:find("������������")
        or lower_text:find("connecting to") then
        is_spawned = false
        is_logging_in = false
        waiting_for_spawn_choice = false
        spawn_timer_seconds = 0
        spawn_timer_running = false
        pending_autologin = true
    end
    handle_admin_kick(text, "чат")
    if is_reconnecting then return end
if lower_text:find("вы отключены от сервера")
        or lower_text:find("соединение потеряно")
        or lower_text:find("соединение разорвано")
        or lower_text:find("connection lost")
        or lower_text:find("server closed the connection")
        or lower_text:find("lost connection to the server") then
        is_spawned = false
        player_in_world = false
        is_logging_in = false
        waiting_for_spawn_choice = false
        spawn_timer_seconds = 0
        spawn_timer_running = false
        log("���������� �� ��������� ����: " .. text:sub(1, 80))
        trigger_reconnect()
        return
    end
    -- connection reject / отказ в подключении: реконнект не запускаем,
    -- просто приводим состояние в готовность к автовходу (ждём окно авторизации)
    if lower_text:find("connection reject")
        or lower_text:find("отказ в подключении")
        or lower_text:find("отклонено подключение")
        or lower_text:find("отклонено соединение") then
        is_spawned = false
        player_in_world = false
        is_logging_in = false
        login_submitted = false
        waiting_for_spawn_choice = false
        spawn_timer_seconds = 0
        spawn_timer_running = false
        pending_autologin = true
        saw_queue_after_rec = true
        reconnect_watch_active = false
        log("connection reject / ����� � ����������� � ������� �������� (" .. text:sub(1, 80) .. ")")
        schedule_autologin_after_reconnect()
    end
end

function sampevents.onSendDialogResponse(dialogId, button, listboxId, input)
    if waiting_for_spawn_choice and dialogId == current_dialog_id then
        if button == 0 or button == 1 then
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            spawn_timer_running = false
            is_spawned = true
            player_in_world = true
        end
    end
end

function onReceivePacket(id, bs)
    if id == 32 or id == 33 then
        log(string.format("����������-����� id=%d", id))
        if is_reconnecting then
            log("����� ������ ����������� � ��� ���������")
            return
        end
        is_spawned = false
        player_in_world = false
        is_logging_in = false
        waiting_for_spawn_choice = false
        spawn_timer_seconds = 0
        spawn_timer_running = false
        trigger_reconnect()
        return
    end

    local text = ""
    local len = raknetBitStreamGetNumberOfBytesUsed(bs)
    for i = 1, len do
        local byte = raknetBitStreamReadInt8(bs)
        if byte >= 32 and byte <= 255 then
            text = text .. string.char(byte)
        end
    end
    raknetBitStreamResetReadPointer(bs)

    if #my_nick == 0 and text:find('Authorization') and text:find('"auth"') then
        local parsed = text:match('"auth"%s*,"%s*"([^"]+)')
        if parsed then
            my_nick = parsed
            log("Ник персонажа из AuthorizationT: " .. my_nick)
        end
    end

    handle_admin_kick(text, "пакет")

    if text:find('OnPlayerOpenMenuPause', 1, true) then
        if login_submitted or is_spawned or is_logging_in then
            log("OnPlayerOpenMenuPause ignored (login in progress/done)")
        elseif in_close_menu_emul_window() then
            local now = os.clock()
            if (now - last_close_menu_emul) >= 0.15 then
                last_close_menu_emul = now
                log("OnPlayerOpenMenuPause -> emulate CloseMenuPause")
                lua_thread.create(function()
                    wait(50)
                    if login_submitted or is_spawned or is_logging_in then return end
                    emulate_close_menu_pause(1)
                end)
            else
                log("OnPlayerOpenMenuPause ignored (debounce)")
            end
        end
    end

    if text:find('GameText') and (text:find('Загрузка') or text:find('~y~')) then
        if text:find('Загрузка') or text:find('Loading') then
            saw_loading_after_rec = true
            reconnect_watch_active = false
            log("Пакет Загрузка/GameText — watchdog снят")
            post_loading_login_watch()
        end
    end
    if text:find('~y~Загрузка') or (text:find('Загрузка') and text:find('10000')) then
        saw_loading_after_rec = true
        reconnect_watch_active = false
        log("Пакет Загрузка — watchdog снят")
        post_loading_login_watch()
    end

    if text:find('Loading') and text:find('3000') then
        saw_loading_after_rec = true
        reconnect_watch_active = false
        is_logging_in = false
        dlog("Loading[3000] (UI/загрузка) — переход в мир")
        post_loading_login_watch()
    end

    if not script_active or password == "" then return end

    if text:find('setPlayerNickName')
        or text:find('Добро пожаловать')
        or text:find('setPlayerConnectedStatus') then
        is_logging_in = false
        pending_autologin = false
        if not waiting_for_spawn_choice then
            is_spawned = true
            player_in_world = true
            finish_reconnect("login ok")
            reconnect_attempt_count = 0
            reconnect_pause_until = 0
            render_disabled = true
            render_disabled_until = os.clock() + 8
            dlog("АВТОРИЗАЦИЯ ПРОЙДЕНА: is_spawned=true (рендер ещё 8с выключен)")
            log("Авторизация пройдена (успешный вход в мир)")
            return
        end
    end

    if not is_reconnecting then
        local low = text:lower()
        if low:find("вы отключены от сервера") then
            is_spawned = false
            player_in_world = false
            is_logging_in = false
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            spawn_timer_running = false
            log("���������� �� ������ ������")
            trigger_reconnect()
            return
        end
    end

    local lower_err = text:lower()
    local is_kick_dialog =
        text:find("Вы ввели неправильный пароль")
        or text:find("Вы ввели неправильный пароль 3 раза")
        or text:find("заблокирован")
        or (lower_err:find("подозрительн") and lower_err:find("программ"))
        or lower_err:find("сторонняя программа")
        or (lower_err:find("заблокир") and (lower_err:find("античит") or lower_err:find("чит")))
        or (lower_err:find("подозрительн") and lower_err:find("действи"))
        or lower_err:find("you have been kicked")

    if lower_err:find("the server is restarting")
        or lower_err:find("подключение к")
        or lower_err:find("connecting to") then
        is_kick_dialog = false
    end

    if is_kick_dialog and not is_reconnecting then
        lua_thread.create(function()
            is_spawned = false
            player_in_world = false
            is_logging_in = false
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            wait_for_game_focus()
            wait(200)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYUP, 0)
            wait(400)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x1B, 0, KEYEVENTF_KEYUP, 0)
            wait(800)
            reconnect_cooldown_until = os.clock() + 5
            trigger_reconnect()
        end)
        return
    end

    if waiting_for_spawn_choice then
        local low = text:lower()
        if low:find("вы появились на")
            or low:find("вернулись на место")
            or low:find("позиция восстановлена") then
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            spawn_timer_running = false
            is_spawned = true
            player_in_world = true
            log("����� ������ ������� � ������ ������")
        end
    end

    if text:find("Диалог точки спавна")
        or text:find("Восстановление позиции")
        or text:find("хотите вернуться на место последнего выхода") then
        if spawn_timer_running then
            log("Spawn timer ��� �������, ������� �����")
            return
        end
        spawn_timer_running = true
        lua_thread.create(function()
            wait(150)
            current_dialog_id = sampGetCurrentDialogId and sampGetCurrentDialogId() or -1
            is_spawned = false
            waiting_for_spawn_choice = true
            spawn_timer_seconds = 15
            log("������ ����� ������ � ������ 15 ��� (������ ������ ��� ���������� ����)")
            local remaining = 15.0
            local last_t = os.clock()
            while waiting_for_spawn_choice and remaining > 0 do
                wait(200)
                if game_window_active() then
                    local now = os.clock()
                    remaining = remaining - (now - last_t)
                    spawn_timer_seconds = math.ceil(remaining)
                end
                last_t = os.clock()
            end
            if waiting_for_spawn_choice then
                waiting_for_spawn_choice = false
                spawn_timer_seconds = 0
                is_spawned = true
                player_in_world = true
                wait_for_game_focus()
                wait(200)
                if spawn_choice then
                    user32.keybd_event(0x0D, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(50)
                    user32.keybd_event(0x0D, 0, KEYEVENTF_KEYUP, 0)
                else
                    user32.keybd_event(0x1B, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(50)
                    user32.keybd_event(0x1B, 0, KEYEVENTF_KEYUP, 0)
                end
            end
            spawn_timer_running = false
        end)
        return
    end

    if text:find('SelectSpawn') and (text:find('Автовокзал г. Южный') or text:find('Южный')) then
        log("SelectSpawn: выбираем «Автовокзал г. Южный»")
        lua_thread.create(function()
            wait(400)
            pcall(wait_for_game_focus)
            wait(200)
            local sw, sh = getScreenResolution()
            local points = {
                {0.28, 0.58},
                {0.30, 0.55},
                {0.26, 0.60},
                {0.32, 0.56},
            }
            for _, p in ipairs(points) do
                local x = math.floor(sw * p[1])
                local y = math.floor(sh * p[2])
                user32.SetCursorPos(x, y)
                wait(40)
                user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
                wait(40)
                user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
                wait(80)
            end
            wait(250)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYUP, 0)
            wait(200)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYDOWN, 0)
            wait(50)
            user32.keybd_event(0x20, 0, KEYEVENTF_KEYUP, 0)
            log("SelectSpawn: ���� + Space �� ����������� �. �����")
            is_spawned = true
            player_in_world = true
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            spawn_timer_running = false
        end)
        return
    end

    if is_spawned then return end

    if text:find('setError') and (text:find('password') or text:find('"password"') or text:find('Password')) then
        local low = text:lower()
        local is_wrong = text:find('неправильный пароль')
            or text:find('неверный пароль')
            or low:find('wrong password')
            or low:find('invalid password')
            or low:find('incorrect password')
            or text:find('setError')
        if is_wrong then
            log("CEF: неверный пароль — открываем форму ввода")
            is_spawned = false
            player_in_world = false
            is_logging_in = false
            login_submitted = false
            finish_reconnect("wrong password")
            pending_autologin = false
            force_password_form = true
            password_form_closed = false
            PF.error = "������ ��������, ������� ������"
            PF.temp_password = ""
            PF.input_active = true
            return
        end
    end

    local is_auth_form =
        (text:find('Authorization') and text:find('"auth"'))
        or text:find('OnAuthorizationStart')
        or text:find('OnAuthorizationStarts')
        or text:find('recovery-password')

    local looks_like_password_form =
        text:find('Введите пароль')
        or text:find('Поле пароля')
        or text:find('форма авторизации')
        or text:find('ожидания формы')

    if is_auth_form or looks_like_password_form then
        finish_reconnect("auth form")
        is_spawned = false
        player_in_world = false
        is_logging_in = false
        waiting_for_spawn_choice = false
        spawn_timer_running = false
        pending_autologin = false
        last_login_attempt = 0
        if password == "" or force_password_form then
            log("CEF-����� �����������, ������ ��� � ��� ���� � GUI")
            force_password_form = true
            password_form_closed = false
            PF.input_active = true
        else
            log("CEF-форма авторизации — ввод пароля")
            -- уведомление, если игра свёрнута и надо ввести пароль
            if not game_window_active() then
                play_auth_sound()
            end
            perform_login()
        end
    end
end

function sampevents.onServerJoin()
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    spawn_timer_running = false
    pending_autologin = true
    last_login_attempt = 0
    log("onServerJoin � ��� CEF AuthorizationT / ��������")
    schedule_autologin_after_reconnect()
    if password ~= "" and not force_password_form then
        lua_thread.create(function()
            for attempt = 1, 6 do
                local wait_remaining = 2.0
                local last_t = os.clock()
                while wait_remaining > 0 do
                    wait(200)
                    if game_window_active() then
                        local now = os.clock()
                        wait_remaining = wait_remaining - (now - last_t)
                    end
                    last_t = os.clock()
                    if is_spawned or not script_active or password == "" then return end
                end
                if is_spawned or not script_active or password == "" then return end
                if not is_logging_in then
                    log(string.format("onServerJoin: ���������� �������� #%d", attempt))
                    last_login_attempt = 0
                    perform_login()
                end
            end
        end)
    end
end

function sampevents.onConnectionClosed()
    log("sampevents.onConnectionClosed (packet 32)")
    if is_reconnecting then return end
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    trigger_reconnect()
end

function sampevents.onConnectionLost()
    log("sampevents.onConnectionLost (packet 33)")
    if is_reconnecting then return end
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    trigger_reconnect()
end

function onConnectionClosed()
    log("onConnectionClosed (global)")
    if is_reconnecting then return end
    is_spawned = false
    player_in_world = false
    is_logging_in = false
    waiting_for_spawn_choice = false
    spawn_timer_seconds = 0
    trigger_reconnect()
end

function onWindowMessage(msg, wparam, lparam)
    if (msg == 0x0100 or msg == 0x0104) and wparam == 0x7A then
        mark_manual_reconnect("F11")
    end

    if is_password_form_visible() and (msg == 0x0100 or msg == 0x0104) and wparam == 0x1B then
        if password == "" then
            chat_msg("{FF3333}Сначала введите пароль — без него автовход не работает!")
        else
            close_password_form()
        end
        return
    end

    if waiting_for_spawn_choice then
        if msg == 0x0100 or msg == 0x0104 then
            if wparam == 0x0D or wparam == 0x1B then
                waiting_for_spawn_choice = false
                spawn_timer_seconds = 0
                is_spawned = true
                player_in_world = true
                log("Таймер спавна закрыт (клавиша)")
            end
        elseif msg == 0x0201 then
            waiting_for_spawn_choice = false
            spawn_timer_seconds = 0
            is_spawned = true
            player_in_world = true
            log("Таймер спавна закрыт (ЛКМ)")
        end
    end

    if is_password_form_visible() and PF.input_active then
        local ctrl_down = (user32.GetAsyncKeyState(0x11) < 0)
        if msg == 0x0100 then
            if wparam == 0x08 then
                if #PF.temp_password > 0 then
                    PF.temp_password = PF.temp_password:sub(1, #PF.temp_password - 1)
                end
            elseif wparam == 0x0D then
                if #PF.temp_password > 0 then
                    password = PF.temp_password
                    save_config()
                    play_gta_confirm_sound()
                    chat_msg("������ ������� ���������� ����� ����������� �����!")
                    on_password_saved()
                else
                    chat_msg("{FF3333}������ �� ����� ���� ������!")
                end
            elseif wparam == 0x56 and ctrl_down then
                local ok_cb, cb = pcall(get_clipboard_text)
                if not ok_cb then cb = "" end
                if #cb > 0 then
                    if #PF.temp_password + #cb > 32 then
                        cb = cb:sub(1, 32 - #PF.temp_password)
                    end
                    PF.temp_password = PF.temp_password .. cb
                    log("������� �� ������ ������: " .. tostring(#cb) .. " ����.")
                end
            elseif wparam == 0x43 and ctrl_down then
                pcall(set_clipboard_text, PF.temp_password)
                log("����������� � ����� ������: " .. tostring(#PF.temp_password) .. " ����.")
            end
        elseif msg == 0x0102 then
            local is_cv = (wparam == 0x56 or wparam == 0x76 or wparam == 0x43 or wparam == 0x63)
            if not (ctrl_down and is_cv) then
                if wparam >= 32 and wparam <= 126 and #PF.temp_password < 32 then
                    PF.temp_password = PF.temp_password .. string.char(wparam)
                elseif wparam > 126 and #PF.temp_password < 32 then
                    PF.temp_password = PF.temp_password .. string.char(wparam)
                end
            end
        end
    end
end

local function timer_render_thread()
    local r_font = renderCreateFont("Arial", 14, 13)
    while true do
        wait(0)
        if (render_disabled or os.clock() < render_disabled_until) and not is_password_form_visible() then
            if os.clock() >= render_disabled_until then render_disabled = false end
            if is_password_form_visible() then render_disabled = false end
        else
        if os.clock() < mafk_notify_until then
            local sw, sh = getScreenResolution()
            local status_str = mafk_active and "{33FF33}Включен" or "{FF3333}Выключен"
            local msg_str = string.format("Anti-AFK режим: %s (правый Ctrl 1.5с /mafk)", status_str)
            local m_w = renderGetFontDrawTextLength(r_font, msg_str)
            local m_box_w = m_w + 24
            local m_x = math.floor((sw - m_box_w) / 2)
            local m_y = math.floor(sh * 0.70)
            renderDrawBox(m_x - 12, m_y - 6, m_box_w, 26, 0xB0000000)
            renderFontDrawText(r_font, msg_str, m_x + (m_box_w - 24 - m_w) / 2, m_y, 0xFFFFFFFF)
        end

        if waiting_for_spawn_choice and spawn_timer_seconds > 0 then
            local sw, sh = getScreenResolution()
            local text_str = string.format("����� ������: ���������� ����� ����� %d ���.", spawn_timer_seconds)
            local text_w = renderGetFontDrawTextLength(r_font, text_str)
            local box_w = text_w + 24
            local posX = math.floor((sw - box_w) / 2)
            local posY = 20
            renderDrawBox(posX - 12, posY - 6, box_w, 28, 0xCC000000)
            renderFontDrawText(r_font, text_str, posX + (box_w - 24 - text_w) / 2, posY, 0xFFFFFF00)
        end

        if is_password_form_visible() then
            PF.render()
        end
    end
end
end

local function chatlog_parser_thread()
    local last_size = 0
    local initialized = false
    while true do
        wait(2000)
        if not game_window_active() then
            -- игра свёрнута: пауза, не читаем/не реконнектим по chatlog
            if initialized then
                local f = io.open(chatlog_path, "r")
                if f then
                    last_size = #(f:read("*all") or "")
                    f:close()
                end
            end
        elseif script_active and chatlog_path and doesFileExist(chatlog_path) then
            local ok_read, content = pcall(function()
                local f = io.open(chatlog_path, "r")
                if not f then return nil end
                local c = f:read("*all") or ""
                f:close()
                return c
            end)
            if ok_read and content then
                local size = #content
                if not initialized then
                    last_size = size
                    initialized = true
                    log("chatlog: пропускаем историю (size=" .. tostring(size) .. ")")
                else
                    if size < last_size then
                        last_size = size
                    elseif size > last_size then
                        local ok_sub, new_part = pcall(function() return content:sub(last_size + 1) end)
                        if ok_sub and new_part then
                            last_size = size
                            local low = new_part:lower()
                            if low:find("кикнул игрока") then
                                handle_admin_kick(new_part, "chatlog")
                            end
                            if not is_reconnecting
                                and low:find("вы отключены от сервера")
                                and not low:find("восстановление позиции")
                                and not low:find("Дисконнект по НОВОЙ строке chatlog.txt") then
                                log("Дисконнект по НОВОЙ строке chatlog.txt")
                                is_spawned = false
                                player_in_world = false
                                is_logging_in = false
                                waiting_for_spawn_choice = false
                                spawn_timer_seconds = 0
                                trigger_reconnect()
                            end
                        else
                            last_size = size
                        end
                    end
                end
            end
        end
    end
end

function onSendCommand(command)
    if not command then return end
    local c = command:lower()
    if c:match("^rec%s+") or c == "rec" or c:match("^reconnect") then
        mark_manual_reconnect("/" .. command)
    end
end

function sampevents.onSendCommand(command)
    onSendCommand(command)
end

local function anti_afk_thread()
    while true do
        wait(100)
        if not mafk_active then
            -- inactive: просто ждём
        elseif not is_spawned then
            player_in_world = false
        elseif player_in_world and game_window_active() then
            local template
            if afk_mode == 0 then
                template = afk_templates[math.random(#afk_templates)]
            else
                template = afk_templates[afk_mode]
            end
            local route = generate_afk_route(template)
            for _, step in ipairs(route) do
                if not mafk_active or not player_in_world or not game_window_active() then break end
                local key
                if step.axis == 'x' and step.dir == 1 then key = 0x57
                elseif step.axis == 'x' and step.dir == -1 then key = 0x53
                elseif step.axis == 'y' and step.dir == 1 then key = 0x44
                elseif step.axis == 'y' and step.dir == -1 then key = 0x41 end
                if key then
                    user32.keybd_event(key, 0, KEYEVENTF_KEYDOWN, 0)
                    wait(step.time * 1000)
                    user32.keybd_event(key, 0, KEYEVENTF_KEYUP, 0)
                    if math.random() < 0.2 then
                        user32.keybd_event(0x43, 0, KEYEVENTF_KEYDOWN, 0)
                        wait(math.random(500, 1500))
                        user32.keybd_event(0x43, 0, KEYEVENTF_KEYUP, 0)
                    end
                    wait(50)
                end
            end
            wait(math.random(1000, 2000))
        end
    end
end

local function mafk_hotkey_thread()
    local prev_down = (user32.GetAsyncKeyState(0xA3) < 0)
    local hold_until = 0
    while true do
        wait(25)
        if not game_window_active() then
            prev_down = (user32.GetAsyncKeyState(0xA3) < 0)
        else
            local down = (user32.GetAsyncKeyState(0xA3) < 0)
            if down and not prev_down then
                hold_until = os.clock() + 1.5
            elseif not down and prev_down then
                if hold_until > 0 and os.clock() >= hold_until then
                    mafk_active = not mafk_active
                    mafk_notify_until = os.clock() + 4
                    play_gta_confirm_sound()
                    local status = mafk_active and "{33FF33}Включен" or "{FF3333}Выключен"
                    chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} режим: " .. status)
                    if mafk_active then
                        player_in_world = is_spawned
                        local spawn_state = is_spawned and "{33FF33}true" or "{FF3333}false"
                        local world_state = player_in_world and "{33FF33}true" or "{FF3333}false"
                        chat_msg(string.format("{FFCC00}[Anti-AFK]{FFFFFF} is_spawned=%s player_in_world=%s", spawn_state, world_state))
                    end
                    sync_mafk_flag()
                end
                hold_until = 0
            end
            prev_down = down
        end
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    load_config()
    register_commands()
    chatlog_path = find_chatlog_path()
    log("Путь к chatlog.txt определен: " .. tostring(chatlog_path))
    sync_mafk_flag()
    lua_thread.create(chatlog_parser_thread)
    lua_thread.create(timer_render_thread)
    lua_thread.create(anti_afk_thread)
    lua_thread.create(mafk_hotkey_thread)
    while true do wait(10000) end
end
