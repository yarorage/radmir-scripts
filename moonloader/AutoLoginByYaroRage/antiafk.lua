-- Модуль Anti-AFK AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local config = require("AutoLoginByYaroRage.config")
local M = {}

-- Оффсеты контрол-блока GTA:SA (прямая эмуляция ввода, как в CLEO char_goto):
-- 0xB73458 + 0x03 = движение вперёд (byte 255/0)
-- 0xB73458 + 0x20 = спринт
-- 0xB73458 + 0x04 = движение назад
-- Поворот педа: getCharPointer(PLAYER_PED) + 0x558 пишется heading (setCharHeading)
local CONTROL_BASE = 0xB73458
local OFF_FORWARD = 0x03
local OFF_BACKWARD = 0x04
local OFF_SPRINT = 0x20

-- ffi для принудительной записи heading в память педа (struct + 0x558), как в CLEO char_goto
local ffi_h = require("ffi")

local function set_forced_heading(heading_deg)
    if not doesCharExist(PLAYER_PED) then return false end
    local ped_ok, ped_addr = pcall(function()
        return tonumber(ffi_h.cast("unsigned int", getCharPointer(PLAYER_PED)))
    end)
    if not ped_ok or not ped_addr then return false end
    local f = ffi_h.new("float[1]", math.rad(heading_deg))
    local i = ffi_h.new("int[1]")
    ffi_h.copy(i, f, 4)
    return pcall(writeMemory, ped_addr + 0x558, 4, i[0], true)
end

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

local function direction_to_heading(dx, dy)
    local rad = math.atan2(-dx, dy)
    local deg = math.deg(rad) % 360
    if deg < 0 then deg = deg + 360 end
    return deg
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

local function is_path_clear(px, py, pz, heading, distance)
    local s = AL.state
    local dx, dy = heading_to_direction(heading)
    local end_x = px + dx * distance
    local end_y = py + dy * distance
    local ok, result = pcall(processLineOfSight,
        px, py, pz + 0.5,
        end_x, end_y, pz + 0.5,
        true, true, false, true, false, false, false, false
    )
    if not ok then return true end
    return not result
end

local function find_clear_direction(px, py, pz, heading)
    local s = AL.state
    -- Смещения в градусах (heading в градусах)
    local offsets = {0, s.RAYCAST_ANGLE_OFFSET, -s.RAYCAST_ANGLE_OFFSET, 90, -90, 180}
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

-- Плавный поворот персонажа к целевому углу через setCharHeading
-- Плавный поворот как мышкой: интерполяция с ease-in-out.
-- Персонаж разгоняется в начале, плавно замедляется у цели, без рывков.
-- Перед каждым поворотом стоит на месте 1-5 секунд, как живой человек.
local function turn_towards(target)
    local s = AL.state
    -- Небольшая пауза перед поворотом (1-5 секунд)
    local pause_ms = math.random(1000, 5000)
    local waited = 0
    while waited < pause_ms do
        if not s.mafk_active then return end
        if not doesCharExist(PLAYER_PED) then return end
        wait(250)
        waited = waited + 250
    end
    local tolerance = s.AFK_TURN_TOLERANCE or 6
    local heading = getCharHeading(PLAYER_PED)
    if not heading then return end
    local dd = angle_diff(heading, target)
    if math.abs(dd) <= tolerance then
        set_forced_heading(target)
        return
    end
    -- Число кадров пропорционально углу, чтобы скорость была похожа на мышь
    local total = math.abs(dd)
    local steps = math.max(30, math.min(200, math.floor(total * 1.2)))
    local start_heading = heading
    for i = 1, steps do
        if not s.mafk_active then return end
        if not doesCharExist(PLAYER_PED) then return end
        -- smoothstep: медленный старт, плавное ускорение и замедление в конце
        local p = i / steps
        local eased = p * p * (3 - 2 * p)
        local next_heading = normalize_angle(start_heading + dd * eased)
        pcall(setCharHeading, PLAYER_PED, next_heading)
        set_forced_heading(next_heading)
        wait(0)
    end
    set_forced_heading(target)
end

-- Движение вперёд: записываем 255 в контрол-блок НА КАЖДОМ КАДРЕ (wait 0),
-- как в CLEO char_goto. GTA:SA перезаписывает CPad каждый кадр из реального
-- ввода, поэтому редкая запись (~30мс) не работает. Прямая запись в память
-- не зависит от фокуса окна - нажатия идут только в игру.
local function hold_run(duration, backwards, heading_deg)
    local s = AL.state
    local off = backwards and OFF_BACKWARD or OFF_FORWARD
    local tolerance = s.AFK_TURN_TOLERANCE or 6
    local turn_speed = s.AFK_TURN_SPEED or 1.0
    local blocked = false
    local last_px, last_py = getCharCoordinates(PLAYER_PED)
    local move_counter = 0
    local still_windows = 0
    local elapsed = 0
    while elapsed < duration do
        if not s.mafk_active then break end
        if not doesCharExist(PLAYER_PED) then break end
        -- Плавный доворот к цели во время движения
        if heading_deg then
            local cur = getCharHeading(PLAYER_PED)
            if cur then
                local dd = angle_diff(cur, heading_deg)
                if math.abs(dd) > tolerance then
                    local sp = math.min(math.abs(dd), turn_speed)
                    local next_h = normalize_angle(cur + (dd > 0 and 1 or -1) * sp)
                    pcall(setCharHeading, PLAYER_PED, next_h)
                    set_forced_heading(next_h)
                else
                    set_forced_heading(heading_deg)
                end
            end
            pcall(setCameraBehindPlayer)
        end
        -- Спринт не используем, только медленная ходьба без остановок
        writeMemory(CONTROL_BASE + off, 1, s.AFK_MOVE_AMOUNT or 128, true)
        move_counter = move_counter + 1
        -- Надёжный детектор упора: лишь два окна подряд без продвижения
        -- (~1 секунда полной остановки) считаются препятствием
        if move_counter >= 25 then
            move_counter = 0
            local cx, cy = getCharCoordinates(PLAYER_PED)
            local still = not cx or math.abs(cx - last_px) + math.abs(cy - last_py) < 0.08
            last_px, last_py = cx, cy
            if still then
                still_windows = still_windows + 1
            else
                still_windows = 0
            end
            if still_windows >= 2 then
                blocked = true
                break
            end
        end
        writeMemory(CONTROL_BASE + OFF_SPRINT, 1, 0, true)
        wait(0)
        elapsed = elapsed + 1
    end
    -- Сброс записей после остановки
    pcall(function()
        writeMemory(CONTROL_BASE + OFF_FORWARD, 1, 0, true)
        writeMemory(CONTROL_BASE + OFF_BACKWARD, 1, 0, true)
        writeMemory(CONTROL_BASE + OFF_SPRINT, 1, 0, true)
    end)
    return not blocked
end

-- Длинная естественная пауза: стоим на месте от 1 до 20 секунд
local function human_pause()
    local s = AL.state
    local ms = math.random(1000, 20000)
    local waited = 0
    while waited < ms do
        if not s.mafk_active then return end
        if not doesCharExist(PLAYER_PED) then return end
        wait(500)
        waited = waited + 500
    end
end

function M.anti_afk_thread()
    local s = AL.state

    while true do
        wait(100)
        if not s.mafk_active then goto continue end
        if not isSampAvailable() then goto continue end
        if not doesCharExist(PLAYER_PED) then goto continue end

        -- pcall только для расчётов без wait (нельзя вызывать wait внутри pcall)
        local ok_route, route = pcall(generate_afk_route, s.afk_mode)
        if not ok_route or not route then
            AL.chat_msg("{FF6600}[Anti-AFK]{FFFFFF} Ошибка маршрута: " .. tostring(route))
            wait(3000)
            goto continue
        end

        for _, step in ipairs(route) do
            if not s.mafk_active then break end
            if not doesCharExist(PLAYER_PED) then break end

            local px, py, pz = getCharCoordinates(PLAYER_PED)
            if not px then break end

            -- Выбор целевого направления (расчёт без wait)
            local target_heading = direction_to_heading(step.dx, step.dy)
            local move_heading = target_heading
            local clear_ok, target_clear = pcall(is_path_clear, px, py, pz, target_heading, s.RAYCAST_DISTANCE)
            if clear_ok and target_clear then
                turn_towards(target_heading)
            else
                local ok_dir, clear_heading = pcall(find_clear_direction, px, py, pz, target_heading)
                if ok_dir and clear_heading then
                    move_heading = clear_heading
                    turn_towards(clear_heading)
                else
                    local jitter_heading = normalize_angle(target_heading + 60 + math.random(0, 120))
                    move_heading = jitter_heading
                    turn_towards(jitter_heading)
                    wait(100)
                end
            end

            local completed = hold_run(step.dur, false, move_heading)

            if not completed then
                -- Упёрлись в препятствие, отходим в сторону по перпендикуляру
                local h = getCharHeading(PLAYER_PED)
                if h then
                    local side = math.random(1, 2) == 1 and 90 or -90
                    local escape_heading = normalize_angle(h + side)
                    turn_towards(escape_heading)
                    hold_run(450, false, escape_heading)
                    wait(150)
                end
            end

            if math.random(1, 10) <= 2 then
                writeMemory(CONTROL_BASE + 0x19, 1, 255, true)
                wait(80)
                writeMemory(CONTROL_BASE + 0x19, 1, 0, true)
            end
        end

        -- Длинная пауза: стоит на месте 1-20 сек, затем снова забег
        if math.random(1, 100) <= 40 then
            human_pause()
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
