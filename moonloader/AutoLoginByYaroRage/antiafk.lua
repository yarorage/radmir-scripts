-- Модуль Anti-AFK AutoLoginByYaroRage
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

local function is_path_clear(px, py, pz, heading, distance)
    local dx, dy = heading_to_direction(heading)
    local end_x = px + dx * distance
    local end_y = py + dy * distance
    local result, _ = processLineOfSight(
        px, py, pz + 0.8,
        end_x, end_y, pz + 0.8,
        true, true, true, true, false, false, false, false
    )
    return not result
end

-- Поиск ближайшего свободного направления методом сканирования веера
local function find_clear_direction(px, py, pz, heading)
    local s = AL.state
    local scan = {
        {delta = 0}, {delta = 25}, {delta = -25},
        {delta = 50}, {delta = -50},
        {delta = 90}, {delta = -90},
        {delta = 130}, {delta = -130},
        {delta = 180},
    }
    for _, cand in ipairs(scan) do
        local target = normalize_angle(heading + cand.delta)
        if is_path_clear(px, py, pz, target, s.RAYCAST_DISTANCE) then
            return target
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

-- Контрол-блок гта:SA (0xB73458) работает даже при свёрнутом окне, в отличие от
-- user32.keybd_event и CEF OnPlayerClientSideKey. Оффсеты подтверждены CLEO-скриптом
-- char_goto: +0x03 = движение вперёд, +0x20 = спринт. 255 = зажато, 0 = отпущено.
local CONTROL_BASE = 0xB73458
local CONTROL_FORWARD = 0x03
local CONTROL_SPRINT = 0x20

-- Зажимает и держит контрол указанное количество миллисекунд, затем отпускает
local function control_press(offset, duration)
    writeMemory(CONTROL_BASE + offset, 1, 255)
    local waited = 0
    while waited < duration do
        local step = math.min(50, duration - waited)
        wait(step)
        waited = waited + step
        writeMemory(CONTROL_BASE + offset, 1, 255)
    end
    writeMemory(CONTROL_BASE + offset, 1, 0)
end

-- Ходьба вперёд (аналог удержания W)
local function press_forward(duration)
    control_press(CONTROL_FORWARD, duration)
end

-- Кратковременный спринт для «живости» персонажа
local function press_sprint(duration)
    control_press(CONTROL_SPRINT, duration)
end

-- Плавный поворот в направлении цели через heading (без эмуляции клавиш A/D)
local function turn_towards(target)
    local s = AL.state
    local tolerance = s.AFK_TURN_TOLERANCE or 6
    local deadline = os.clock() + (s.AFK_MAX_TURN_TIME or 4000) / 1000
    local dir = nil
    local last_dist = nil
    while true do
        if not s.mafk_active then return end
        if not doesCharExist(PLAYER_PED) then return end
        local heading = getCharHeading(PLAYER_PED)
        if not heading then return end
        local dist = math.abs(angle_diff(heading, target))
        if dist <= tolerance then return end
        -- Не успели за отведённое время - ставим поворот напрямую
        if os.clock() > deadline then
            pcall(setCharHeading, PLAYER_PED, target)
            return
        end
        if dir == nil then
            dir = angle_diff(heading, target) > 0 and 1 or -1
            last_dist = dist
        elseif last_dist and last_dist < dist then
            dir = -dir
        end
        last_dist = dist
        local step = 3 * dir
        pcall(setCharHeading, PLAYER_PED, normalize_angle(heading + step))
        wait(50)
    end
end

local function run_forward(duration)
    local s = AL.state
    local elapsed = 0
    local chunk = s.AFK_RUN_CHUNK or 250
    while elapsed < duration do
        if not s.mafk_active then return end
        if not doesCharExist(PLAYER_PED) then return end
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        local heading = getCharHeading(PLAYER_PED)
        if not px or not heading then return end
        if not is_path_clear(px, py, pz, heading, s.AFK_STOP_DISTANCE or 3.0) then
            return
        end
        local step_ms = math.min(chunk, duration - elapsed)
        press_forward(step_ms)
        elapsed = elapsed + step_ms
    end
end

function M.anti_afk_thread()
    local s = AL.state

    while true do
        wait(100)
        if s.mafk_active and isSampAvailable() and s.player_in_world then
            if doesCharExist(PLAYER_PED) then
                local route = generate_afk_route(s.afk_mode)
                for _, step in ipairs(route) do
                    if not s.mafk_active then break end
                    if not doesCharExist(PLAYER_PED) then break end
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local heading = getCharHeading(PLAYER_PED)
                    if not px or not py or not pz or not heading then break end
                    -- Выбираем направление: если путь в сторону маршрута занят - ищем свободный угол
                    local preff_heading = direction_to_heading(step.dx, step.dy)
                    local target = preff_heading
                    if not is_path_clear(px, py, pz, target, s.RAYCAST_DISTANCE) then
                        target = find_clear_direction(px, py, pz, heading)
                    end
                    if target then
                        turn_towards(target)
                        run_forward(step.dur)
                    else
                        -- Вокруг всё занято - разворачиваемся в противоположную сторону
                        turn_towards(normalize_angle(heading + 180))
                        wait(200)
                    end
                    if math.random(1, 10) <= 2 then press_sprint(150) end
                    wait(100)
                end
            end
        end
    end
end

function M.mafk_hotkey_thread()
    local s = AL.state
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
