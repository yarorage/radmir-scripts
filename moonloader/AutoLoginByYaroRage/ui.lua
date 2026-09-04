-- UI (пароль) — AutoLoginByYaroRage
-- Стиль сайта yarorage.github.io + логотип лаунчера
local AL = require("AutoLoginByYaroRage.state")
local utils = require("AutoLoginByYaroRage.utils")
local config = require("AutoLoginByYaroRage.config")
local auth = require("AutoLoginByYaroRage.auth")
local M = {}

local ffi = require("ffi")
local user32 = ffi.load("user32")

ffi.cdef[[
    unsigned long GetKeyboardLayout(int idThread);
    int GetKeyState(int nVirtKey);
    int GetWindowThreadProcessId(void* hWnd, unsigned long* lpdwProcessId);
    void* GetForegroundWindow();
    short GetAsyncKeyState(int vKey);
]]

local function get_current_lang()
    local hwnd = user32.GetForegroundWindow()
    if hwnd == nil then return "EN" end
    local pid = ffi.new("unsigned long[1]")
    local tid = user32.GetWindowThreadProcessId(hwnd, pid)
    local kl = user32.GetKeyboardLayout(tid)
    local lang_id = bit.band(tonumber(kl), 0xFFFF)
    if lang_id == 0x419 then return "RU" end
    return "EN"
end

local function is_caps_lock()
    return bit.band(tonumber(user32.GetKeyState(0x14)), 1) ~= 0
end

local function is_shift_down()
    return user32.GetAsyncKeyState(0x10) < 0
end

local function is_lmb_down()
    return user32.GetAsyncKeyState(0x01) < 0
end

-- ЦВЕТА САЙТА
local C = {
    bg       = 0x05080F,
    bg2      = 0x0A0E1A,
    bg3      = 0x0D1225,
    blue     = 0x0066FF,
    blue2    = 0x0088FF,
    blue3    = 0x00AAFF,
    cyan     = 0x00D4FF,
    text     = 0xE0E8F0,
    muted    = 0x5A6A80,
    accent   = 0x00CCFF,
    gold     = 0xFFD700,
    gold2    = 0xE8C050,
    error    = 0xEF5050,
    warn     = 0xFFC759,
    input_bg = 0x080C18,
    white    = 0xFFFFFF,
}

-- МАСШТАБ
local function get_scale()
    local sw, sh = getScreenResolution()
    return math.max(0.75, math.min(1.25, sh / 1080.0)), sw, sh
end
local function sc(v)
    return math.floor(v * get_scale() + 0.5)
end

-- ШРИФТЫ
local font_cache = {}
local function get_font(name, size, flags)
    local key = name .. "_" .. size .. "_" .. (flags or 0)
    if not font_cache[key] then
        font_cache[key] = renderCreateFont(name, size, flags or 0)
    end
    return font_cache[key]
end

-- РИСОВАНИЕ
local function rr(x, y, w, h, r, color)
    r = math.min(r, math.floor(math.min(w, h) / 2))
    local d = r * 2
    renderDrawBox(x, y, r, r, color)
    renderDrawBox(x + w - r, y, r, r, color)
    renderDrawBox(x, y + h - r, r, r, color)
    renderDrawBox(x + w - r, y + h - r, r, r, color)
    renderDrawBox(x + r, y, w - d, r, color)
    renderDrawBox(x + r, y + h - r, w - d, r, color)
    renderDrawBox(x, y + r, r, h - d, color)
    renderDrawBox(x + w - r, y + r, r, h - d, color)
    renderDrawBox(x + r, y + r, w - d, h - d, color)
end

local function tw(f, t) return renderGetFontDrawTextLength(f, t) end
local function th(f) return renderGetFontDrawHeight(f) end
local function tcx(cx, fw, f, t) return cx + math.floor((fw - tw(f, t)) / 2) end

-- СОСТОЯНИЕ
local PF = {
    visible = false,
    anim = 0,
    password = "",
    temp_password = "",
    show_chars = true,
    error_msg = "",
    error_time = 0,
    shake_x = 0,
    shake_time = 0,
    input_active = false,
    last_lmb = false,
    layout = {},
}

function PF.reset()
    PF.password = ""
    PF.temp_password = ""
    PF.show_chars = true
    PF.error_msg = ""
    PF.input_active = false
end

function PF.setError(msg)
    PF.error_msg = msg
    PF.error_time = os.clock() + 4
    PF.shake_time = os.clock() + 0.3
end

-- РЕНДЕР
function PF.render()
    local should_show = auth.is_password_form_visible()
    if should_show then PF.visible = true end
    if not PF.visible then return end

    if should_show and PF.anim < 1 then
        PF.anim = math.min(1, PF.anim + 0.1)
    elseif not should_show and PF.anim > 0 then
        PF.anim = math.max(0, PF.anim - 0.1)
    end
    if PF.anim <= 0 then PF.visible = false; return end

    if PF.shake_time > 0 and os.clock() < PF.shake_time then
        PF.shake_x = math.sin(os.clock() * 60) * 4
    else
        PF.shake_x = 0
    end
    if PF.error_time > 0 and os.clock() > PF.error_time then
        PF.error_msg = ""
    end

    local _, sw, sh = get_scale()
    local al = PF.anim

    local fw = sc(360)
    local fh = sc(330)
    local cx = math.floor((sw - fw) / 2) + math.floor(PF.shake_x)
    local cy = math.floor((sh - fh) / 2 - sh * 0.03)

    local mx, my = getCursorPos()
    local lmb = is_lmb_down()
    local clicked = lmb and not PF.last_lmb

    PF.layout = {x = cx, y = cy, w = fw, h = fh}

    -- Фон
    renderDrawBox(0, 0, sw, sh, math.floor(200 * al) * 0x1000000 + C.bg)

    -- Карточка
    rr(cx, cy, fw, fh, sc(16), math.floor(255 * al) * 0x1000000 + C.bg3)

    -- Верхняя полоса
    rr(cx, cy, fw, sc(3), sc(2), math.floor(255 * al) * 0x1000000 + C.cyan)

    -- Контур
    rr(cx - 1, cy - 1, fw + 2, fh + 2, sc(17), math.floor(60 * al) * 0x1000000 + C.blue)

    -- Неоновое свечение
    for i = 3, 1, -1 do
        local o = i * sc(3)
        local sa = math.floor(8 * (4 - i) * al)
        rr(cx - o, cy - o, fw + o * 2, fh + o * 2, sc(18) + o, sa * 0x1000000 + C.blue)
    end

    local pad = sc(22)
    local y = cy + pad

    -- ЛОГОТИП
    local logo_w = sc(80)
    local logo_h = sc(50)
    local logo_x = cx + math.floor((fw - logo_w) / 2)
    local logo_y = y

    rr(logo_x, logo_y, logo_w, logo_h, sc(8), math.floor(255 * al) * 0x1000000 + C.bg2)
    rr(logo_x - 2, logo_y - 2, logo_w + 4, logo_h + 4, sc(9), math.floor(200 * al) * 0x1000000 + C.blue)
    rr(logo_x - 1, logo_y - 1, logo_w + 2, logo_h + 2, sc(8), math.floor(255 * al) * 0x1000000 + C.bg2)

    local logo_f = get_font("Arial", sc(24), 1)
    local logo_txt = "YR"
    local ltw = tw(logo_f, logo_txt)
    local lth = th(logo_f)
    renderFontDrawText(logo_f, logo_txt,
        logo_x + math.floor((logo_w - ltw) / 2),
        logo_y + math.floor((logo_h - lth) / 2) - sc(2),
        math.floor(255 * al) * 0x1000000 + C.gold)

    local scripts_f = get_font("Arial", sc(7), 0)
    local scripts_txt = "SCRIPTS"
    local stw = tw(scripts_f, scripts_txt)
    renderFontDrawText(scripts_f, scripts_txt,
        logo_x + math.floor((logo_w - stw) / 2),
        logo_y + logo_h - sc(12),
        math.floor(200 * al) * 0x1000000 + C.gold2)

    y = y + logo_h + sc(14)

    -- ЗАГОЛОВОК
    local title_f = get_font("Arial", sc(16), 1)
    local title = "AutoLogin"
    renderFontDrawText(title_f, title, tcx(cx, fw, title_f, title), y, math.floor(255 * al) * 0x1000000 + C.text)
    y = y + th(title_f) + sc(4)

    local sub_f = get_font("Arial", sc(9), 0)
    local sub = "Введите пароль для входа на сервер"
    renderFontDrawText(sub_f, sub, tcx(cx, fw, sub_f, sub), y, math.floor(180 * al) * 0x1000000 + C.muted)
    y = y + th(sub_f) + sc(14)

    -- ПОЛЕ ВВОДА
    local field_h = sc(34)
    local field_x = cx + pad
    local field_w = fw - pad * 2
    local field_hov = mx >= field_x and mx <= field_x + field_w and my >= y and my <= y + field_h
    local focused = PF.input_active or field_hov

    rr(field_x, y, field_w, field_h, sc(8), math.floor(255 * al) * 0x1000000 + C.input_bg)

    local bdr = C.muted
    if focused then bdr = C.blue end
    if PF.error_msg ~= "" and os.clock() < PF.error_time then bdr = C.error end
    rr(field_x - 1, y - 1, field_w + 2, field_h + 2, sc(9), math.floor(180 * al) * 0x1000000 + bdr)

    if focused then
        for i = 2, 1, -1 do
            local o = i * sc(2)
            local sa = math.floor(15 * (3 - i) * al)
            rr(field_x - o, y - o, field_w + o * 2, field_h + o * 2, sc(10) + o, sa * 0x1000000 + C.blue)
        end
    end

    local mono = get_font("Consolas", sc(12), 0)
    local display = ""
    if #PF.password > 0 then
        display = PF.show_chars and PF.password or string.rep("*", #PF.password)
    end
    local tx = field_x + sc(10)
    local ty = y + math.floor((field_h - th(mono)) / 2)

    if #PF.password > 0 then
        renderFontDrawText(mono, display, tx, ty, math.floor(255 * al) * 0x1000000 + C.text)
    else
        renderFontDrawText(mono, "Пароль...", tx, ty, math.floor(150 * al) * 0x1000000 + C.muted)
    end

    -- Курсор
    if focused then
        local cursor_x
        if #PF.password > 0 then
            cursor_x = tx + tw(mono, display) + sc(2)
        else
            cursor_x = tx
        end
        local cursor_h = th(mono) + sc(4)
        local cursor_y = y + math.floor((field_h - cursor_h) / 2)
        if (os.clock() % 1.0) < 0.5 then
            renderDrawBox(cursor_x, cursor_y, sc(1), cursor_h, math.floor(255 * al) * 0x1000000 + C.accent)
        end
    end

    -- Кнопка глаз
    local eye_w = field_h
    local eye_x = field_x + field_w - eye_w
    local eye_hov = mx >= eye_x and mx <= eye_x + eye_w and my >= y and my <= y + field_h
    if eye_hov then
        rr(eye_x, y, eye_w, field_h, sc(8), math.floor(60 * al) * 0x1000000 + C.blue)
    end
    local eye_f = get_font("Arial", sc(12), 0)
    local eye_sym = PF.show_chars and "?" or "*"
    local ets = tw(eye_f, eye_sym)
    renderFontDrawText(eye_f, eye_sym, eye_x + math.floor((eye_w - ets) / 2), ty,
        math.floor((eye_hov and 255 or 130) * al) * 0x1000000 + C.cyan)

    if clicked and eye_hov then
        PF.show_chars = not PF.show_chars
    end

    if clicked and field_hov then
        PF.input_active = true
    end

    -- ИНДИКАТОРЫ
    local ind_y = y + field_h + sc(6)
    local ind_f = get_font("Arial", sc(9), 1)
    local ind_pad = sc(4)
    local ind_h = th(ind_f) + sc(6)

    local lang = get_current_lang()
    local lang_bg = lang == "RU" and 0x182030 or C.bg2
    local lang_w = tw(ind_f, lang) + sc(14)
    rr(field_x, ind_y, lang_w, ind_h, sc(4), math.floor(255 * al) * 0x1000000 + lang_bg)
    renderFontDrawText(ind_f, lang, field_x + sc(7), ind_y + sc(3),
        math.floor(255 * al) * 0x1000000 + C.white)

    local caps_on = is_caps_lock()
    local caps_text = "CAPS"
    local caps_bg = caps_on and C.blue or C.bg2
    local caps_x = field_x + lang_w + ind_pad
    local caps_w = tw(ind_f, caps_text) + sc(14)
    rr(caps_x, ind_y, caps_w, ind_h, sc(4), math.floor(255 * al) * 0x1000000 + caps_bg)
    renderFontDrawText(ind_f, caps_text, caps_x + sc(7), ind_y + sc(3),
        math.floor(255 * al) * 0x1000000 + (caps_on and C.white or C.muted))

    local shift_on = is_shift_down()
    local shift_text = "SHIFT"
    local shift_bg = shift_on and C.blue or C.bg2
    local shift_x = caps_x + caps_w + ind_pad
    local shift_w = tw(ind_f, shift_text) + sc(14)
    rr(shift_x, ind_y, shift_w, ind_h, sc(4), math.floor(255 * al) * 0x1000000 + shift_bg)
    renderFontDrawText(ind_f, shift_text, shift_x + sc(7), ind_y + sc(3),
        math.floor(255 * al) * 0x1000000 + (shift_on and C.white or C.muted))

    y = y + field_h + sc(24)

    -- ОШИБКА
    if PF.error_msg ~= "" and os.clock() < PF.error_time then
        local err_f = get_font("Arial", sc(9), 0)
        renderFontDrawText(err_f, PF.error_msg, tcx(cx, fw, err_f, PF.error_msg), y,
            math.floor(255 * al) * 0x1000000 + C.error)
        y = y + th(err_f) + sc(8)
    end

    -- КНОПКА
    local btn_h = sc(36)
    local btn_x = cx + pad
    local btn_w = fw - pad * 2
    local btn_hov = mx >= btn_x and mx <= btn_x + btn_w and my >= y and my <= y + btn_h
    local btn_pressed = btn_hov and lmb

    local btn_color = C.blue
    if btn_pressed then btn_color = C.blue2
    elseif btn_hov then btn_color = C.blue2 end

    rr(btn_x, y, btn_w, btn_h, sc(8), math.floor(255 * al) * 0x1000000 + btn_color)

    if btn_hov then
        for i = 2, 1, -1 do
            local o = i * sc(3)
            local sa = math.floor(12 * (3 - i) * al)
            rr(btn_x - o, y - o, btn_w + o * 2, btn_h + o * 2, sc(9) + o, sa * 0x1000000 + C.blue)
        end
    end

    local btn_f = get_font("Arial", sc(11), 1)
    local btn_text = "Ввести пароль"
    renderFontDrawText(btn_f, btn_text, tcx(cx, fw, btn_f, btn_text), y + math.floor((btn_h - th(btn_f)) / 2),
        math.floor(255 * al) * 0x1000000 + C.white)

    if clicked and btn_hov and #PF.password > 0 then
        AL.state.password = PF.password
        config.save()
        utils.play_gta_confirm_sound()
        AL.chat_msg("{33FF33}Пароль сохранён!")
        auth.on_password_saved()
    end

    y = y + btn_h + sc(12)

    -- ПОДСКАЗКА
    local hint_f = get_font("Arial", sc(8), 0)
    local hint = "Enter — ввод  |  Ctrl+V — вставка"
    renderFontDrawText(hint_f, hint, tcx(cx, fw, hint_f, hint), y,
        math.floor(120 * al) * 0x1000000 + C.muted)

    -- КРЕСТИК
    local close_size = sc(22)
    local close_x = cx + fw - pad - close_size + sc(5)
    local close_y = cy + sc(8)
    local close_hov = mx >= close_x and mx <= close_x + close_size and my >= close_y and my <= close_y + close_size

    local close_color = close_hov and C.error or C.muted
    local close_f = get_font("Arial", sc(14), 1)
    local close_sym = "x"
    local csx = tw(close_f, close_sym)
    local csy = th(close_f)
    renderFontDrawText(close_f, close_sym, close_x + math.floor((close_size - csx) / 2), close_y + math.floor((close_size - csy) / 2),
        math.floor((close_hov and 255 or 140) * al) * 0x1000000 + close_color)

    if clicked and close_hov then
        auth.close_password_form()
    end

    PF.last_lmb = lmb
end

-- API
M.PF = PF
M.render = function() PF.render() end
M.reset = function() PF.reset() end
M.setError = function(msg) PF.setError(msg) end

M.handle_char_input = function(char)
    if PF.input_active then
        PF.password = PF.password .. char
        PF.temp_password = PF.password
    end
end

M.handle_backspace = function()
    if PF.input_active and #PF.password > 0 then
        PF.password = PF.password:sub(1, -2)
        PF.temp_password = PF.password
    end
end

M.handle_paste = function(text)
    if PF.input_active and text then
        PF.password = PF.password .. text
        PF.temp_password = PF.password
    end
end

M.handle_copy = function()
    if #PF.password > 0 then
        utils.set_clipboard_text(PF.password)
    end
end

M.handle_enter = function()
    if #PF.password > 0 then
        AL.state.password = PF.password
        config.save()
        utils.play_gta_confirm_sound()
        AL.chat_msg("{33FF33}Пароль сохранён!")
        auth.on_password_saved()
    end
end

return M
