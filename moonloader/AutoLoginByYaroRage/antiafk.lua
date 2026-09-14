-- Модуль Anti-AFK AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local config = require("AutoLoginByYaroRage.config")
local M = {}

-- Оффсеты контрол-блока GTA:SA (для прямой эмуляции ввода в фоне):
-- 0xB73458 + 0x03 = движение вперёд (byte 255/0)
-- 0xB73458 + 0x20 = спринт
-- Поворот педа: setCharHeading напрямую (struct + 0x558)
local CONTROL_BASE = 0xB73458

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

local function normalize_angle(deg)
    deg = deg % 360
    if deg < 0 then deg = deg + 360 end
    return deg
end

local function angle_diff(from, to)
    local d = normalize_angle(to) - normalize_angle(from)
    if d > 180 then d = d - 360 elseif d <= -180 then d = d + 360 end
    return d
end

local function heading_to_direction(heading)
    local rad = math.rad(heading)
    return -math.sin(rad), math.cos(rad)
end

local function direction_to_heading(dx, dy)
    local rad = math.atan2(-dx, dy)
    return normalize_angle(math.deg(rad))
end

-- Вращение персонажа к целевому углу напрямую через setCharHeading
local function turn_towards(target)
    local s = AL.state
    local tolerance = s.AFK_TURN_TOLERANCE or 6
    local max_steps = 200
    for _ = 1, max_steps do
        if not s.mafk_active then return end
        if not doesCharExist(PLAYER_PED) then return end
        local heading = getCharHeading(PLAYER_PED)
        if not heading then return end
        local dist = math.abs(angle_diff(heading, target))
        if dist <= tolerance then return end
        local step = math.min(dist, 3)
        local dir = angle_diff(heading, target) > 0 and 1 or -1
        pcall(setCharHeading, PLAYER_PED, normalize_angle(heading + dir * step))
        wait(30)
    end
end

-- Удержание движения вперёд: записываем 255 в контрол-блок каждые 30мс
-- (GTA:SA перезаписывает 0xB73458 каждый кадр из реального ввода).
local function hold_forward(duration)
    local s = AL.state
    local elapsed = 0
    local STEP = 30
    while elapsed < duration do
        if not s.mafk_active then break end
        if not doesCharExist(PLAYER_PED) then break end
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        if not px then break end
        writeMemory(CONTROL_BASE + 0x03, 1, 255, true)
        writeMemory(CONTROL_BASE + 0x20, 1, 255, true)
        wait(STEP)
        elapsed = elapsed + STEP
    end
    -- Сброс контрол-блока
    pcall(function()
        writeMemory(CONTROL_BASE + 0x03, 1, 0, true)
        writeMemory(CONTROL_BASE + 0x20, 1, 0, true)
    end)
end

-- Проверка застревания: если координаты не изменились за 1.5 сек - разворачиваемся
local function check_stuck(px, py, pz)
    local s = AL.state
    local elapsed = 0
    while elapsed < 1500 do
        if not s.mafk_active then return false end
        wait(200)
        elapsed = elapsed + 200
        local cx, cy, cz = getCharCoordinates(PLAYER_PED)
        if cx and math.abs(cx - px) + math.abs(cy - py) > 0.15 then
            return false
        end
    end
    return true
end

function M.anti_afk_thread()
    local s = AL.state

    while true do
        wait(100)
        if not s.mafk_active then goto continue end
        if not isSampAvailable() then goto continue end
        if not s.player_in_world then goto continue end
        if not doesCharExist(PLAYER_PED) then goto continue end

        local ok, err = pcall(function()
            local route = generate_afk_route(s.afk_mode)
            for _, step in ipairs(route) do
                if not s.mafk_active then break end
                if not doesCharExist(PLAYER_PED) then break end

                local target = direction_to_heading(step.dx, step.dy)
                turn_towards(target)

                local px, py, pz = getCharCoordinates(PLAYER_PED)
                if px then
                    hold_forward(step.dur)
                    if check_stuck(px, py, pz) then
                        local h = getCharHeading(PLAYER_PED)
                        if h then
                            local jitter = 60 + math.random(0, 60)
                            pcall(setCharHeading, PLAYER_PED, normalize_angle(h + jitter))
                            wait(100)
                        end
                    end
                end
            end
        end)

        if not ok and err then
            AL.chat_msg("{FF6600}[Anti-AFK]{FFFFFF} Ошибка потока: " .. tostring(err))
            wait(5000)
        end

        ::continue::
    end
end

function M.mafk_hotkey_thread()
    local s = AL.state
    local ffi = require("ffi")
    local user32 = ffi.load("user32")
    local VK_RCONTROL = 0xA3
    while true do
        wait(150)
        if bit.band(user32.GetAsyncKeyState(VK_RCONTROL), 0x8000) ~= 0 then
            if s.mafk_hold_start == 0 then
                s.mafk_hold_start = os.clock()
            end
            if os.clock() - s.mafk_hold_start >= 1.5 then
                s.mafk_active = not s.mafk_active
                config.update_mafk_config()
                local status = s.mafk_active and "{33FF33}Вкл" or "{FF3333}Выкл"
                AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Режим: " .. status)
                s.mafk_notify_until = os.clock() + 3
                s.mafk_hold_start = 0
                wait(500)
            end
        else
            s.mafk_hold_start = 0
        end
    end
end

function M.register_commands()
    sampRegisterChatCommand("mafk", function()
        local s = AL.state
        s.mafk_active = not s.mafk_active
        config.update_mafk_config()
        local status = s.mafk_active and "{33FF33}Вкл" or "{FF3333}Выкл"
        AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Режим: " .. status)
    end)

    sampRegisterChatCommand("marsh", function(arg)
        local s = AL.state
        local mode = arg:lower()
        if mode == "mix" or mode == "" then
            s.afk_mode = 0
            AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} АФК: random mix")
        else
            local num = tonumber(mode)
            if num and num >= 1 and num <= 11 then
                s.afk_mode = num
                AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} АФК: " .. num)
            else
                AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Неверный режим. Использование: /afk [mix/1-11]")
            end
        end
    end)
end

return M
