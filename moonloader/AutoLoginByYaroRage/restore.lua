-- Ìîäóëü «Âîññòàíîâëåíèå ïîçèöèè» AutoLoginByYaroRage
-- Àâòîâûáîğ îòâåòà íà CEF-äèàëîã «Âîññòàíîâëåíèå ïîçèöèè» (id=215).
-- Ïğè ïîÿâëåíèè äèàëîãà çàïóñêàåòñÿ òàéìåğ (15 ñåê) ñ êíîïêîé «Èçìåíèòü»,
-- ïî èñòå÷åíèè òàéìåğà àâòîìàòè÷åñêè îòïğàâëÿåòñÿ îòâåò OnDialogResponse
-- ñîãëàñíî íàñòğîéêå àâòîñïàâíà (s.spawn_choice).
local AL = require("AutoLoginByYaroRage.state")
local config = require("AutoLoginByYaroRage.config")
local M = {}

local RESTORE_TITLE = "Âîññòàíîâëåíèå ïîçèöèè"
local RESTORE_TIMER_SECONDS = 15

local function reset_state()
    local s = AL.state
    s.restore_active = false
    s.restore_deadline = 0
    s.restore_answered = false
    s.restore_btn_rect = nil
    s.restore_last_lmb = false
end

-- Ñáîğêà ïîëíîãî ïàêåòà îòâåòà CEF: ïåğâûì áàéòîì èä¸ò id 215 (D7),
-- òåëî ñîîòâåòñòâóåò ïåğåõâà÷åííîìó ôîğìàòó OnDialogResponse.
-- button: 1 = «Äà», 0 = «Íåò».
local function build_response_bytes(button)
    local name = "OnDialogResponse"
    local p = {}
    local function push(x) p[#p + 1] = x end
    local function push_int32(v)
        v = v % 4294967296
        push(v % 256)
        push(math.floor(v / 256) % 256)
        push(math.floor(v / 65536) % 256)
        push(math.floor(v / 16777216) % 256)
    end
    push(215)          -- D7
    push_int32(2)      -- ïğåôèêñ
    push(0); push(0)   -- ïğåôèêñ
    push_int32(#name)  -- äëèíà èìåíè
    for i = 1, #name do push(string.byte(name, i)) end
    push_int32(8)      -- ñ÷¸ò÷èê ïàğàìåòğîâ
    push(0x64); push_int32(0)     -- dialogId = 0
    push(0x64); push_int32(button) -- response (1 = «Äà», 0 = «Íåò»)
    push(0x64); push_int32(-1)    -- listboxId = -1
    push(0x73); push_int32(0)     -- input = ""
    return p
end

-- Îòïğàâêà îòâåòà â CEF ÷åğåç raknetSendBitStream (êàê â auth.lua)
function M.send_response(button)
    local bytes = build_response_bytes(button)
    local ok_bs, bs = pcall(raknetNewBitStream)
    if not ok_bs or not bs then
        AL.log("Âîññòàíîâëåíèå ïîçèöèè: raknetNewBitStream íåäîñòóïåí")
        return false
    end
    local ok_w = pcall(function()
        for i = 1, #bytes do
            raknetBitStreamWriteInt8(bs, bytes[i])
        end
    end)
    local ok_s = false
    if ok_w then
        local res
        ok_s, res = pcall(raknetSendBitStream, bs)
        AL.log(string.format("Âîññòàíîâëåíèå ïîçèöèè: îòâåò îòïğàâëåí (button=%d, %d áàéò, ok=%s, res=%s)",
            button, #bytes, tostring(ok_s), tostring(res)))
    end
    raknetDeleteBitStream(bs)
    return ok_s
end

-- Äåòåêò CEF-äèàëîãà «Âîññòàíîâëåíèå ïîçèöèè» (RX id=215)
function M.handle_received(id, text, is_real)
    local s = AL.state
    if id ~= 215 then return end
    local is_restore = text:find(RESTORE_TITLE, 1, true) and text:find("addDialogInQueue", 1, true)
    if not is_restore then
        -- Ïîëüçîâàòåëü ñàì çàêğûë äèàëîã è ïğèøëî äğóãîå îêíî — ñáğîñ òàéìåğà
        if s.restore_active and text:find("addDialogInQueue", 1, true) then
            reset_state()
            AL.log("Âîññòàíîâëåíèå ïîçèöèè: äèàëîã çàêğûò âğó÷íóş, òàéìåğ ñáğîøåí")
        end
        return
    end
    if not is_real then return end
    if not s.script_active then return end
    s.restore_active = true
    s.restore_deadline = os.clock() + RESTORE_TIMER_SECONDS
    s.restore_answered = false
    AL.log("Âîññòàíîâëåíèå ïîçèöèè: äèàëîã îáíàğóæåí, òàéìåğ " .. RESTORE_TIMER_SECONDS .. " ñåê (âûáîğ: "
        .. (s.spawn_choice and "Äà" or "Íåò") .. ")")
end

-- Îáğàáîòêà èñõîäÿùåãî ïàêåòà: ïîëüçîâàòåëü ñàì îòâåòèë â CEF
local function pcall_get_len(bs)
    local ok, len = pcall(raknetBitStreamGetNumberOfBytesUsed, bs)
    if not ok or not len then return 0 end
    return len
end

function M.handle_send(id, bs)
    local s = AL.state
    if id ~= 215 or not s.restore_active then return end
    local txt = ""
    local len = pcall_get_len(bs)
    local max_len = math.min(len or 0, 4096)
    for i = 1, max_len do
        local ok_b, b = pcall(raknetBitStreamReadInt8, bs)
        if not ok_b then break end
        if b >= 32 and b <= 255 then
            txt = txt .. string.char(b)
        end
    end
    pcall(raknetBitStreamResetReadPointer, bs)
    if txt:find("OnDialogResponse", 1, true) then
        reset_state()
        AL.log("Âîññòàíîâëåíèå ïîçèöèè: ïîëüçîâàòåëü îòâåòèë âğó÷íóş, òàéìåğ ñáğîøåí")
    end
end

-- Îòêëèê ïîëüçîâàòåëÿ ïî êíîïêå «Èçìåíèòü»
function M.handle_click(x, y)
    local s = AL.state
    if not s.restore_active then return end
    local r = s.restore_btn_rect
    if not r then return end
    if x >= r[1] and x <= r[1] + r[3] and y >= r[2] and y <= r[2] + r[4] then
        s.spawn_choice = not s.spawn_choice
        config.save()
        AL.log("Âîññòàíîâëåíèå ïîçèöèè: âûáîğ èçìåí¸í íà " .. (s.spawn_choice and "Äà" or "Íåò"))
        -- Ïğîäëåâàåì, ÷òîáû ïîëüçîâàòåëü óñïåë óâèäåòü íîâîå çíà÷åíèå 1 ñåê
        s.restore_deadline = os.clock() + 1
    end
end

-- Ğåíäåğ òàéìåğà è êíîïêè (âûçûâàåòñÿ èç timer_render_thread)
function M.render(r_font, k)
    local s = AL.state
    if not s.restore_active then
        s.restore_btn_rect = nil
        return
    end
    local now = os.clock()
    local remaining = s.restore_deadline - now
    local sec = math.ceil(remaining)
    if sec <= 0 and not s.restore_answered then
        s.restore_answered = true
        s.restore_btn_rect = nil
        AL.log("Âîññòàíîâëåíèå ïîçèöèè: òàéìåğ èñò¸ê, àâòîîòâåò "
            .. (s.spawn_choice and "Äà" or "Íåò"))
        M.send_response(s.spawn_choice and 1 or 0)
        reset_state()
        return
    end
    if sec <= 0 then
        reset_state()
        return
    end

    local sw, sh = getScreenResolution()
    local choice_str = s.spawn_choice and "Äà" or "Íåò"
    local text_str = string.format("Âîññòàíîâëåíèå ïîçèöèè: %s | %d ñåê", choice_str, sec)
    local btn_text = "Èçìåíèòü"
    local text_w = renderGetFontDrawTextLength(r_font, text_str)
    local btn_w = renderGetFontDrawTextLength(r_font, btn_text) + math.floor(24 * k)
    local pad = math.floor(12 * k)
    local gap = math.floor(8 * k)
    local box_w = text_w + btn_w + pad * 2 + gap
    local box_h = math.floor(28 * k)
    local posX = math.floor((sw - box_w) / 2)
    local posY = math.floor(sh * 0.08)

    -- ôîí
    renderDrawBox(posX, posY, box_w, box_h, 0xCC000000)
    -- òåêñò
    renderFontDrawText(r_font, text_str, posX + pad, posY + math.floor(5 * k), 0xFFFFFF00)
    -- êíîïêà «Èçìåíèòü»
    local btnX = posX + pad + text_w + gap
    local btnY = posY + math.floor((box_h - math.floor(20 * k)) / 2)
    renderDrawBox(btnX, btnY, btn_w, math.floor(20 * k), 0x330066FF)
    renderFontDrawText(r_font, btn_text, btnX + math.floor(12 * k), btnY + math.floor(3 * k), 0xFFFFFFFF)
    s.restore_btn_rect = { btnX, btnY, btn_w, math.floor(20 * k) }
end

-- Ïîëíûé ñáğîñ (ïğè ğåêîííåêòå/âûõîäå èç ìèğà)
function M.reset()
    reset_state()
end

return M