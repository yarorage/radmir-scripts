-- Модуль Anti-AFK AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local config = require("AutoLoginByYaroRage.config")
local M = {}

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

local function direction_to_heading(dx, dy)
    local rad = math.atan2(-dx, dy)
    return normalize_angle(math.deg(rad))
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

local function hold_forward(duration)
    if not isSampfuncsLoaded() then return end
    local s = AL.state
    local VK_W = 0x57
    local elapsed = 0
    local chunk = s.AFK_RUN_CHUNK or 250
    while elapsed < duration do
        if not s.mafk_active then break end
        if not doesCharExist(PLAYER_PED) then break end
        s.mafk_thread_alive = os.clock()
        local step_ms = math.min(chunk, duration - elapsed)
        setVirtualKeyDown(VK_W, true)
        wait(step_ms)
        setVirtualKeyDown(VK_W, false)
        elapsed = elapsed + step_ms
    end
end

local function human_pause()
    local s = AL.state
    local ms = math.random(1000, 20000)
    local waited = 0
    while waited < ms do
        if not s.mafk_active then return end
        if not doesCharExist(PLAYER_PED) then return end
        wait(500)
        waited = waited + 500
        s.mafk_thread_alive = os.clock()
    end
end

function M.anti_afk_thread()
    local s = AL.state
    s.mafk_thread_alive = os.clock()

    while true do
        wait(100)
        s.mafk_thread_alive = os.clock()
        if not s.mafk_active then goto continue end
        if not isSampAvailable() then goto continue end
        if not doesCharExist(PLAYER_PED) then goto continue end

        local ok_route, route = pcall(generate_afk_route, s.afk_mode)
        if not ok_route or not route then
            wait(3000)
            goto continue
        end

        for _, step in ipairs(route) do
            if not s.mafk_active then break end
            if not doesCharExist(PLAYER_PED) then break end
            local target = direction_to_heading(step.dx, step.dy)
            pcall(setCharHeading, PLAYER_PED, target)
            hold_forward(step.dur)
            wait(200)
        end

        if math.random(1, 100) <= 40 then
            human_pause()
        end

        ::continue::
    end
end

function M.mafk_watchdog_thread()
    local s = AL.state
    while true do
        wait(1000)
        if s.mafk_active and (os.clock() - s.mafk_thread_alive) > 5 then
            s.mafk_thread_alive = os.clock()
            lua_thread.create(M.anti_afk_thread)
            AL.chat_msg("{FF6600}[Anti-AFK]{FFFFFF} Поток anti-AFK перезапущен воронкой")
        end
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
                -- Блокируем повторное срабатывание, пока RCtrl не отпущена
                while bit.band(user32.GetAsyncKeyState(VK_RCONTROL), 0x8000) ~= 0 do
                    wait(100)
                end
                wait(150)
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
                AL.chat_msg("{FFCC00}[Anti-AFK]{FFFFFF} Неверный режим. Использование: /marsh [mix/1-11]")
            end
        end
    end)
end

return M
