-- Ìîäóëü Anti-AFK AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local config = require("AutoLoginByYaroRage.config")
local M = {}

local ffi = require("ffi")
local user32 = ffi.load("user32")

local afk_templates = {
    {dx = 1.0, dy = 0.0, dur = 2000},
    {dx = -1.0, dy = 0.0, dur = 2000},
    {dx = 0.0, dy = 1.0, dur = 2000},
    {dx = 0.0, dy = -1.0, dur = 2000},
    {dx = 1.0, dy = 1.0, dur = 1500},
    {dx = -1.0, dy = -1.0, dur = 1500},
    {dx = 1.0, dy = -1.0, dur = 1500},
    {dx = -1.0, dy = 1.0, dur = 1500},
    {dx = 0.5, dy = 0.0, dur = 3000},
    {dx = -0.5, dy = 0.0, dur = 3000},
    {dx = 0.0, dy = 0.5, dur = 3000},
}

local function heading_to_direction(heading)
    local rad = math.rad(heading)
    return -math.sin(rad), math.cos(rad)
end

local function is_path_clear(px, py, pz, heading, distance)
    local s = AL.state
    local dx, dy = heading_to_direction(heading)
    local end_x = px + dx * distance
    local end_y = py + dy * distance
    local result, _ = processLineOfSight(
        px, py, pz + 0.5,
        end_x, end_y, pz + 0.5,
        true, true, false, true, false, false, false, false
    )
    return not result
end

local function find_clear_direction(px, py, pz, heading)
    local s = AL.state
    local offsets = {0, s.RAYCAST_ANGLE_OFFSET, -s.RAYCAST_ANGLE_OFFSET, math.pi/2, -math.pi/2, math.pi}
    for _, offset in ipairs(offsets) do
        if is_path_clear(px, py, pz, heading + offset, s.RAYCAST_DISTANCE) then
            return heading + offset
        end
    end
    return nil
end

local function generate_afk_route(template)
    local route = {}
    local tmpl = afk_templates[template]
    if tmpl then
        local duration = tmpl.dur + math.random(-500, 500)
        table.insert(route, {dx = tmpl.dx, dy = tmpl.dy, dur = math.max(500, duration)})
    else
        local count = math.random(3, 6)
        for i = 1, count do
            local t = afk_templates[math.random(1, #afk_templates)]
            local duration = t.dur + math.random(-500, 500)
            table.insert(route, {dx = t.dx, dy = t.dy, dur = math.max(500, duration)})
        end
    end
    return route
end

local function press_key(vk, duration)
    user32.keybd_event(vk, 0, 0, 0)
    wait(duration)
    user32.keybd_event(vk, 0, 2, 0)
end

function M.anti_afk_thread()
    local s = AL.state
    local VK_W = 0x57
    local VK_A = 0x41
    local VK_S = 0x53
    local VK_D = 0x44
    local VK_C = 0x43

    while true do
        wait(100)
        if s.mafk_active and isSampAvailable() then
            local route = generate_afk_route(s.afk_mode)
            for _, step in ipairs(route) do
                if not s.mafk_active then break end
                local px, py, pz = getCharCoordinates(PLAYER_PED)
                local heading = getCharHeading(PLAYER_PED)
                local clear_heading = find_clear_direction(px, py, pz, heading)
                if clear_heading then
                    local dx, dy = heading_to_direction(clear_heading)
                    if math.abs(dx) > math.abs(dy) then
                        press_key(dx > 0 and VK_W or VK_S, step.dur)
                    else
                        press_key(dy > 0 and VK_D or VK_A, step.dur)
                    end
                else
                    if step.dx > 0 then press_key(VK_W, step.dur)
                    elseif step.dx < 0 then press_key(VK_S, step.dur)
                    elseif step.dy > 0 then press_key(VK_D, step.dur)
                    elseif step.dy < 0 then press_key(VK_A, step.dur)
                    end
                end
                if math.random(1, 10) <= 2 then press_key(VK_C, 100) end
                wait(100)
            end
        end
    end
end

function M.mafk_hotkey_thread()
    local s = AL.state
    local VK_RCONTROL = 0xA3
    while true do
        wait(0)
        if bit.band(user32.GetAsyncKeyState(VK_RCONTROL), 0x8000) ~= 0 then
            if s.mafk_hold_start == 0 then
                s.mafk_hold_start = os.clock()
            end
            if os.clock() - s.mafk_hold_start >= 1.5 then
                s.mafk_active = not s.mafk_active
                config.update_mafk_config()
                local status = s.mafk_active and "{33FF33}ÂÊË" or "{FF3333}ÂÛÊË"
                AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Ñòàòóñ: " .. status)
                s.mafk_notify_until = os.clock() + 3
                s.mafk_hold_start = 0
                wait(500)
            end
        else
            s.mafk_hold_start = 0
        end
    end
end

function M.on_send_packet(id, bs)
    local s = AL.state
    if not s.anti_ticket_enabled then return end
    local text = M.bitStreamStructure(bs)
    if text:find("OnPlayerDeviceLost") then
        return false
    end
    if (text:find('OnPlayerEnterArea') or text:find('OnPlayerLeaveArea')) and isCharInAnyCar(PLAYER_PED) then
        return false
    end
end

function M.on_receive_packet(id, bs)
    local s = AL.state
    if not s.anti_ticket_enabled then return end
    if id == 215 then
        local _style = raknetBitStreamReadInt16(bs)
        local _type = raknetBitStreamReadInt32(bs)
        local l = raknetBitStreamReadInt8(bs)
        local style3 = raknetBitStreamReadInt8(bs)
        local length = raknetBitStreamReadInt32(bs)
        if length > 0 and length < 777 then
            local bitstreamtext = raknetBitStreamReadString(bs, length)
            if bitstreamtext then
                local text = M.bitStreamStructure(bs)
                if bitstreamtext:match('Overlay') and (text == "[2000,2000,1.00,1]" or text == "[2500,2500,1.00,1]") then
                    return false
                end
            end
        end
    end
end

function M.bitStreamStructure(bs)
    local text = ''
    for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do
        local byte = raknetBitStreamReadInt8(bs)
        if byte >= 32 and byte <= 255 and byte ~= 37 then
            text = text .. string.char(byte)
        end
    end
    raknetBitStreamResetReadPointer(bs)
    return text
end

function M.register_commands()
    sampRegisterChatCommand("mafk", function()
        local s = AL.state
        s.mafk_active = not s.mafk_active
        config.update_mafk_config()
        local status = s.mafk_active and "{33FF33}ÂÊË" or "{FF3333}ÂÛÊË"
        AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Ñòàòóñ: " .. status)
    end)

    sampRegisterChatCommand("afk", function(arg)
        local s = AL.state
        local mode = arg:lower()
        if mode == "mix" or mode == "" then
            s.afk_mode = 0
            AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Ğåæèì: random mix")
        else
            local num = tonumber(mode)
            if num and num >= 1 and num <= 11 then
                s.afk_mode = num
                AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Ğåæèì: " .. num)
            else
                AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Íåâåğíûé ââîä: /afk [mix/1-11]")
            end
        end
    end)

    sampRegisterChatCommand("fk", function()
        local s = AL.state
        s.anti_ticket_enabled = not s.anti_ticket_enabled
        printStringNow(string.format("YARO RAGE ANTIAFK %s", s.anti_ticket_enabled and "~g~ON" or "~r~OFF"), 1000)
    end)
end

return M
