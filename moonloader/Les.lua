require "lib.moonloader"
require "lib.sampfuncs"

-- Include
local sampEvents = require 'lib.samp.events'
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = "CP1251"
u8 = encoding.UTF8
local vkeys = require 'vkeys'
local gkeys = require 'game.keys'
local vector3d = require 'vector3d'
local memory = require 'memory'
local ffi = require 'ffi'
ffi.cdef[[
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetForegroundWindow(void);
    int IsIconic(void* hWnd);
    short GetAsyncKeyState(int vKey);
]]
local user32 = ffi.load("user32")

local function game_has_focus()
    local hwnd = user32.FindWindowA("Grand theft auto San Andreas", nil)
    return hwnd ~= nil and user32.IsIconic(hwnd) == 0 and user32.GetForegroundWindow() == hwnd
end


-- Шрифт (гарантированная кириллица)
imgui.GetIO().Fonts:Clear()
local _fontCands = {
    'C:\\Windows\\Fonts\\segoeui.ttf',   -- системный, всегда есть
    'C:\\Windows\\Fonts\\arial.ttf',
    getFolderPath(0x14) .. '\\Arial.ttf',
}
local _fontLoaded = false
for _, _fp in ipairs(_fontCands) do
    local _ok = pcall(function()
        imgui.GetIO().Fonts:AddFontFromFileTTF(_fp, 16, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end)
    if _ok then _fontLoaded = true break end
end
if _fontLoaded then
    pcall(function() imgui.GetIO().Fonts:Build() end)
else
    imgui.GetIO().Fonts:AddFontDefault()
end

-- Алиасы
local ImVec2 = imgui.ImVec2
local ImVec4 = imgui.ImVec4
local ImGuiStyle = imgui.GetStyle()
local ImGuiColors = ImGuiStyle.Colors
local ImGuiClr = imgui.Col

-- Параметры
local waitDownClickY = 300
local waitWaitClickY = 600

local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
function GetBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end
local dbgLog = thisScript().directory .. "\\les_dbg.txt"
local function dbg(msg)
    local fh = io.open(dbgLog, 'a')
    if fh then fh:write(os.date('%H:%M:%S') .. ' | ' .. msg .. '\n') fh:close() end
end
local AutoYLastSetFill = 0
local AutoYPresses = 0

-- Класс "Кликер"
local Clicker = {}
function Clicker:new(Button, Sleep)
    local obj = {}
    obj.Button = Button
    obj.Sleep = Sleep
    obj.Allow = false
    obj.thread = nil

    function obj:Start()
        self.Allow = true
        self.thread = lua_thread.create(function()
            while self.Allow do
                if game_has_focus() then
                    setVirtualKeyDown(self.Button, true)
                    wait(waitDownClickY)
                    setVirtualKeyDown(self.Button, false)
                end
                wait(self.Sleep)
            end
            self.thread = nil
        end)
    end

    function obj:Stop()
        self.Allow = false
    end

    setmetatable(obj, self)
    self.__index = self; return obj
end

local Menu = {
    windowState = imgui.ImBool(false);
}
-- Модели животных
local MODEL_DEER = 15555
local MODEL_BEAR = 15556

local Ohota = {
    -- Охота / WH
    Wh = imgui.ImBool(false),          -- WH живых животных
    WhPlayers = imgui.ImBool(false),   -- WH игроков (надпись)
    HeadDot = imgui.ImBool(false),     -- точка на голове
    ShowDistance = imgui.ImBool(false),-- дистанция
    -- дальности отображения (0 = выключено)
    DistAnimals = imgui.ImFloat(250.0),-- дальность по животным
    DistCars    = imgui.ImFloat(0.0),  -- дальность по машинам (выкл)
    DistPlayers = imgui.ImFloat(0.0),  -- дальность по игрокам (выкл)
    -- линии отдельно
    LineAnimals = imgui.ImBool(false), -- линии до живых животных
    LineCars = imgui.ImBool(false),    -- линии до машин
    LinePlayers = imgui.ImBool(false), -- линии до игроков
    -- ESP
    EspTush = imgui.ImBool(false),     -- WH туш (мертвых животных)
    EspCars = imgui.ImBool(false),     -- WH машин
    -- Прицел
    Aim = imgui.ImBool(false),         -- аим по животным
    AimPlayers = imgui.ImBool(false),  -- аим по игрокам
    Aim_silent = imgui.ImBool(false),
    AimHandle = nil,
    -- Уборка
    AutoY = imgui.ImBool(false),
    AutoY_Clicker = Clicker:new(vkeys.VK_Y, waitWaitClickY),
    Clear = imgui.ImBool(false),       -- убирать призраков туш (20 с)
    ClearFol = imgui.ImBool(false),    -- убирать деревья/листву вокруг
    FolApplied = false,
    FirstApplied = false,
    LastTargetHandle = nil,
}

-- все пункты выключены до первого открытия меню
Ohota.Wh.v = false
Ohota.WhPlayers.v = false
Ohota.HeadDot.v = false
Ohota.ShowDistance.v = false
Ohota.LineAnimals.v = false
Ohota.LineCars.v = false
Ohota.LinePlayers.v = false
Ohota.EspTush.v = false
Ohota.EspCars.v = false
Ohota.Aim.v = false
Ohota.AimPlayers.v = false
Ohota.AutoY.v = false
Ohota.Clear.v = false
Ohota.ClearFol.v = false
Ohota.FirstApplied = false

function imgui_Menu_windowState(arg)
    Menu.windowState.v = not Menu.windowState.v
    imgui.ShowCursor = Menu.windowState.v
    if Menu.windowState.v and not Ohota.FirstApplied then
        Ohota.FirstApplied = true
        Ohota.Wh.v = true
        Ohota.EspTush.v = true
        Ohota.HeadDot.v = true
        Ohota.ShowDistance.v = true
        Ohota.Aim.v = true
        Ohota.AutoY.v = true
        Ohota.Clear.v = true
    end
end

-- Главный цикл
function main()
    if not isSampLoaded() or not isSampfuncsLoaded then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("les", imgui_Menu_windowState)
    sampRegisterChatCommand("lesr", function()
        thisScript():reload()
    end)

    local okY, yw = pcall(require, "ywelcome")
    if okY and type(yw) == "function" then
        yw("Les", "Охота в лесу. Меню: удерживай L 1 сек, закрыть - нажатие L / /les")
    end

    -- Управление меню по L: открытие - удержание 1 сек, закрытие - нажатие
    local VK_L = 0x4C
    lua_thread.create(function()
        local prev_down = false
        local hold_start = 0
        local fired = false
        while true do
            wait(20)
            local down = (user32.GetAsyncKeyState(VK_L) < 0)
            local menuOpen = Menu.windowState.v

            if down and not prev_down then
                -- свежее нажатие
                if menuOpen then
                    -- меню открыто -> закрыть сразу по нажатию
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                    fired = true
                    hold_start = 0
                else
                    -- меню закрыто -> начали удержание для открытия
                    hold_start = os.clock()
                    fired = false
                end
            elseif down and prev_down then
                -- удержание кнопки
                if not menuOpen and not fired and hold_start > 0 and (os.clock() - hold_start) >= 0.5 then
                    fired = true
                    if game_has_focus() and not sampIsChatInputActive() and not sampIsDialogActive() then
                        imgui_Menu_windowState()
                    end
                end
            else
                -- кнопка отпущена
                hold_start = 0
                fired = false
            end
            prev_down = down
        end
    end)

    -- Шрифт для живых животных
    font_whGreen = renderCreateFont('Arial', 7, 13)

    imgui.Process = true
    imgui.ShowCursor = false

    -- автоочистка деревьев при старте, если включено
    if Ohota.ClearFol.v then
        pcall(applyFoliageClear)
    end

    while true do
        wait(0)

        -- охранные вызовы ESP (безопасно)
        if Ohota.EspTush.v and type(renderEspTush) == "function" then pcall(renderEspTush) end
        if Ohota.EspCars.v and type(renderEspCars) == "function" then pcall(renderEspCars) end
        if Ohota.ClearFol.v then
            if not Ohota.FolApplied then
                Ohota.FolApplied = true
                Ohota.FolTimer = os.clock()
                pcall(applyFoliageClear)
            elseif (os.clock() - (Ohota.FolTimer or 0)) > 2.0 then
                Ohota.FolTimer = os.clock()
                pcall(applyFoliageClear)
            end
        else
            if Ohota.FolApplied then
                Ohota.FolApplied = false
                pcall(restoreFoliage)
            end
        end

        -- WH живых животных + подписи + линии
        if Ohota.Wh.v or Ohota.LineAnimals.v or Ohota.WhPlayers.v or Ohota.LinePlayers.v or Ohota.HeadDot.v or Ohota.ShowDistance.v then
            for pairsId, value in pairs(getAllChars()) do
                if doesCharExist(value) and value ~= PLAYER_PED and isCharOnScreen(value) and getCharHealth(value) > 0 then
                    local modelid = getCharModel(value)
                    local posX, posY, posZ = getCharCoordinates(value)
                    local _X, _Y = convert3DCoordsToScreen(posX, posY, posZ)

                    local playerX, playerY, playerZ = getCharCoordinates(playerPed)
                    local X, Y = convert3DCoordsToScreen(playerX, playerY, playerZ)

                    local dist = math.sqrt((posX - playerX)^2 + (posY - playerY)^2 + (posZ - playerZ)^2)

                    local health = getCharHealth(value)
                    local hx, hy, hz = GetBodyPartCoordinates(8, value)
                    local hxx, hyy = convert3DCoordsToScreen(hx, hy, hz)

                    local isAnimal = (modelid == MODEL_DEER or modelid == MODEL_BEAR)
                    local shouldRenderAimExtras = (doesCharExist(Ohota.AimHandle) and Ohota.AimHandle == value)

                    -- защита от NaN/мусорных координат (иначе краш рендера)
                    local okScreen = (_X ~= nil and _Y ~= nil and _X == _X and _Y == _Y
                                      and _X > -50 and _X < 8050 and _Y > -50 and _Y < 6050)
                    local okHead = (hxx ~= nil and hyy ~= nil and hxx == hxx and hyy == hyy
                                    and hxx > -50 and hxx < 8050 and hyy > -50 and hyy < 6050)

                    -- WH животин
                    if Ohota.Wh.v and isAnimal and okScreen and (Ohota.DistAnimals.v > 0 and dist <= Ohota.DistAnimals.v) then
                        if modelid == MODEL_DEER then
                            if health == 100 then
                                renderFontDrawText(font_whGreen, 'Олень(3)', _X, _Y, 0xFF00FF00)
                            elseif health == 65 then
                                renderFontDrawText(font_whGreen, 'Олень(2)', _X, _Y, 0xFFFF9D00)
                            elseif health == 30 then
                                renderFontDrawText(font_whGreen, 'Олень(1)', _X, _Y, 0xFFFF0000)
                            end
                        elseif modelid == MODEL_BEAR then
                            if health == 100 then
                                renderFontDrawText(font_whGreen, 'Медведь(7)', _X, _Y, 0xFF00FF00)
                            elseif health == 85 then
                                renderFontDrawText(font_whGreen, 'Медведь(6)', _X, _Y, 0xFF55E100)
                            elseif health == 70 then
                                renderFontDrawText(font_whGreen, 'Медведь(5)', _X, _Y, 0xFFAAC300)
                            elseif health == 55 then
                                renderFontDrawText(font_whGreen, 'Медведь(4)', _X, _Y, 0xFFFFA500)
                            elseif health == 40 then
                                renderFontDrawText(font_whGreen, 'Медведь(3)', _X, _Y, 0xFFFF6E00)
                            elseif health == 25 then
                                renderFontDrawText(font_whGreen, 'Медведь(2)', _X, _Y, 0xFFFF3700)
                            elseif health == 10 then
                                renderFontDrawText(font_whGreen, 'Медведь(1)', _X, _Y, 0xFFFF0000)
                            end
                        end
                        -- линия до животин
                        if Ohota.LineAnimals.v and not shouldRenderAimExtras and okHead then
                            local sw, sh = getScreenResolution()
                            renderDrawLine(sw/2, sh/2, hxx, hyy, 1.0, 0xFFFFFF00)
                        end
                    end

                    -- линия до игроков
                    local isPlayer = false
                    local resPid, pid = sampGetPlayerIdByCharHandle(value)
                    if resPid then isPlayer = true end
                    if okScreen and isPlayer and (Ohota.DistPlayers.v > 0 and dist <= Ohota.DistPlayers.v) then
                        if Ohota.WhPlayers.v then
                            renderFontDrawText(font_whGreen, "Игрок", _X, _Y, 0xFF00CCFF)
                        end
                        if Ohota.LinePlayers.v and not shouldRenderAimExtras and okHead then
                            local sw, sh = getScreenResolution()
                            renderDrawLine(sw/2, sh/2, hxx, hyy, 1.0, 0xFF00CCFF)
                        end
                    end

                    -- точка на голове
                    if Ohota.HeadDot.v and okHead then
                        renderDrawBoxWithBorder(hxx, hyy, 3, 3, 0xFF00FF00, 1, 0xFF00FF00)
                    end

                    -- дистанция (только для активных категорий)
                    if Ohota.ShowDistance.v then
                        local _showDist = false
                        if isAnimal and Ohota.Wh.v and (Ohota.DistAnimals.v > 0 and dist <= Ohota.DistAnimals.v) then
                            _showDist = true
                        elseif isPlayer and Ohota.WhPlayers.v and (Ohota.DistPlayers.v > 0 and dist <= Ohota.DistPlayers.v) then
                            _showDist = true
                        end
                        if _showDist and okScreen then
                            renderFontDrawText(font_whGreen, string.format("%.0f м", dist), _X, _Y - 10, 0xFFFFFFFF)
                        end
                    end
                end
            end
        end

        -- Уборка призраков туш (20 с без движения)
        if Ohota.Clear.v then
            if not animalLastState then animalLastState = {} end
            for _, value in pairs(getAllChars()) do
                if value ~= PLAYER_PED and doesCharExist(value) then
                    local modelid = getCharModel(value)
                    if (modelid == MODEL_DEER or modelid == MODEL_BEAR) then
                        local curX, curY, curZ = getCharCoordinates(value)
                        local state = animalLastState[value]
                        local now = os.time()
                        if not state then
                            animalLastState[value] = {x = curX, y = curY, z = curZ, lastMoveTime = now}
                        else
                            local moved = (math.abs(curX - state.x) > 0.01 or
                                           math.abs(curY - state.y) > 0.01 or
                                           math.abs(curZ - state.z) > 0.01)
                            if moved then
                                state.x = curX; state.y = curY; state.z = curZ
                                state.lastMoveTime = now
                            else
                                if now - state.lastMoveTime >= 20 then
                                    deleteChar(value)
                                    animalLastState[value] = nil
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Прицел (аим): раздельно животные / игроки
        local camMode = readMemory(0xB6F1A8, 1, false)
        local aiming = (camMode == 53 or camMode == 55 or camMode == 7 or camMode == 8)
        local aimAnimals = Ohota.Aim.v
        local aimPlayers = Ohota.AimPlayers.v

        if aiming and (Ohota.AimHandle == nil) and (aimAnimals or aimPlayers) then
            local width, heigth = getScreenResolution()
            local fov = getCameraFov() * 0.0174530
            local coeficent = width / fov
            local distance = 0.025 * coeficent
            local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)

            -- квадратик зоны прицела
            renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)

            local candidates = {}
            local maxScreenDist = 0
            local max3DDist = 0

            for _, v in pairs(getAllChars()) do
                if doesCharExist(v) and isCharOnScreen(v) then
                    local modelid = getCharModel(v)
                    local isAn = (modelid == MODEL_DEER or modelid == MODEL_BEAR)
                    local isPl = false
                    if not isAn then
                        local r, p = sampGetPlayerIdByCharHandle(v)
                        if r then isPl = true end
                    end
                    -- фильтр по типу цели
                    if (aimAnimals and isAn) or (aimPlayers and isPl) then
                        local x, y, z = GetBodyPartCoordinates(8, v)
                        local wposX, wposY = convert3DCoordsToScreen(x, y, z)
                        local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)
                        if inBox then
                            local screenDist = math.sqrt((wposX - width_crosshair)^2 + (wposY - heigth_crosshair)^2)
                            local cX, cY, cZ = getCharCoordinates(v)
                            local pX, pY, pZ = getCharCoordinates(playerPed)
                            local dist3D = math.sqrt((cX-pX)^2 + (cY-pY)^2 + (cZ-pZ)^2)
                            table.insert(candidates, {v, screenDist, dist3D, x, y, z})
                            if screenDist > maxScreenDist then maxScreenDist = screenDist end
                            if dist3D > max3DDist then max3DDist = dist3D end
                        end
                    end
                end
            end

            local bestScore = math.huge
            for _, cand in ipairs(candidates) do
                local scrNorm = (maxScreenDist > 0) and (cand[2] / maxScreenDist) or 0
                local distNorm = (max3DDist > 0) and (cand[3] / max3DDist) or 0
                local score = scrNorm + distNorm
                if score < bestScore then
                    bestScore = score
                    Ohota.AimHandle = cand[1]
                end
            end
        elseif aiming and (Ohota.AimHandle ~= nil) then
            if aimAnimals or aimPlayers then
                local width, heigth = getScreenResolution()
                local fov = getCameraFov() * 0.0174530
                local coeficent = width / fov
                local distance = 0.025 * coeficent
                local width_crosshair, heigth_crosshair = convertGameScreenCoordsToWindowScreenCoords(339.1, 179.1)
                local x, y, z = GetBodyPartCoordinates(8, Ohota.AimHandle)
                local wposX, wposY = convert3DCoordsToScreen(x, y, z)

                renderDrawBoxWithBorder(width_crosshair-(distance/2), heigth_crosshair-(distance/2), distance, distance, nil, 2, 0xFF5AE053)
                local inBox = (wposX > width_crosshair - distance/2 and wposX < width_crosshair + distance/2 and wposY > heigth_crosshair - distance/2 and wposY < heigth_crosshair + distance/2)
                if inBox and doesCharExist(Ohota.AimHandle) and isCharOnScreen(Ohota.AimHandle) then
                    targetAtCoords(x, y, z)
                end
                if not doesCharExist(Ohota.AimHandle) then
                    Ohota.AimHandle = nil
                end
            else
                Ohota.AimHandle = nil
            end
        else
            Ohota.AimHandle = nil
        end

        if Ohota.LastTargetHandle ~= Ohota.AimHandle then
            Ohota.LastTargetHandle = Ohota.AimHandle
        end

        -- курсор
        if not Menu.windowState.v then
            imgui.ShowCursor = false
        else
            imgui.ShowCursor = true
        end
    end
end

-- Меню
function imgui.OnDrawFrame()
    local sw, sh = getScreenResolution()
    if Menu.windowState.v then
        apply_custom_style()

        local mainWidth = 430
        local mainHeight = 690
        imgui.SetNextWindowSize(ImVec2(mainWidth, mainHeight), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, ImVec2(0.5, 0.5))

        imgui.Begin(u8'Охота в лесу', Menu.windowState, imgui.WindowFlags.NoResize)
            imgui.TextColored(imgui.ImVec4(0.30, 0.90, 0.35, 1.0), u8"Ohota By YaroRage")
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.60, 0.60, 0.60, 1.0))
            imgui.Text(u8"Охота в лесу - ESP, прицел, автокликер Y")
            imgui.PopStyleColor(1)
            imgui.Separator()

            -- Охота / ESP
            imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- Охота / ESP ---")
            if imgui.Checkbox(u8"WH животных", Ohota.Wh) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Подсветка живых животных с количеством хитов (3-1 / 7-1)") end

            if imgui.Checkbox(u8"WH туш", Ohota.EspTush) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Подсветка призраков туш (рамка + линия + дистанция)") end

            if imgui.Checkbox(u8"WH машин", Ohota.EspCars) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Подсветка машин вокруг (рамка + линия + дистанция)") end

            if imgui.Checkbox(u8"WH игроков", Ohota.WhPlayers) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Показывает надпись Игрок над игроком") end

            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"Линии до цели:")

            if imgui.Checkbox(u8"Линии до животных", Ohota.LineAnimals) then end
            if imgui.Checkbox(u8"Линии до машин", Ohota.LineCars) then end
            if imgui.Checkbox(u8"Линии до игроков", Ohota.LinePlayers) then end

            if imgui.Checkbox(u8"Точка на голове", Ohota.HeadDot) then end
            if imgui.Checkbox(u8"Дистанция", Ohota.ShowDistance) then end
            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(0.80, 0.80, 0.80, 1.0), u8"Дальность (0 = выкл):")
            if imgui.SliderFloat(u8"Животные, м", Ohota.DistAnimals, 0.0, 500.0, '%.0f') then Ohota.DistAnimals.v = math.floor(Ohota.DistAnimals.v + 0.5) end
            if imgui.SliderFloat(u8"Машины, м", Ohota.DistCars, 0.0, 500.0, '%.0f') then Ohota.DistCars.v = math.floor(Ohota.DistCars.v + 0.5) end
            if imgui.SliderFloat(u8"Игроки, м", Ohota.DistPlayers, 0.0, 500.0, '%.0f') then Ohota.DistPlayers.v = math.floor(Ohota.DistPlayers.v + 0.5) end
            imgui.Separator()

            -- Прицел
            imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- Прицел ---")
            if imgui.Checkbox(u8"Аим по животным", Ohota.Aim) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Наводится только на животных (олень/медведь)") end

            if imgui.Checkbox(u8"Аим по игрокам", Ohota.AimPlayers) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Наводится только на игроков") end
            imgui.Separator()

            -- Уборка
            imgui.TextColored(imgui.ImVec4(1.0, 0.80, 0.20, 1.0), u8"--- Уборка ---")
            if imgui.Checkbox(u8"Автокликер Y", Ohota.AutoY) then
                if not Ohota.AutoY.v then
                    Ohota.AutoY_Clicker:Stop()
                end
            end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Автоматический клик по клавише Y (для охоты)") end

            if imgui.Checkbox(u8"Убирать призраков туш (20 с)", Ohota.Clear) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Удаляет туши животных, которые 20 секунд не двигаются") end

            if imgui.Checkbox(u8"Убирать деревья вокруг", Ohota.ClearFol) then end
            if imgui.IsItemHovered() then imgui.SetTooltip(u8"Визуально убирает деревья/кусты в радиусе вокруг персонажа") end

            imgui.Separator()
            imgui.TextColored(imgui.ImVec4(0.55, 0.55, 0.55, 1.0), u8"/les - меню, /lesr - перезапуск")
        imgui.End()
    end
end

function apply_custom_style()
    ImGuiStyle.WindowPadding = imgui.ImVec2(5.0, 5.0)
    ImGuiStyle.WindowRounding = 10.0
    ImGuiStyle.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    ImGuiStyle.ChildWindowRounding = 2.0
    ImGuiStyle.FrameRounding = 10.0
    ImGuiStyle.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    ImGuiStyle.ScrollbarSize = 13.0
    ImGuiStyle.ScrollbarRounding = 0
    ImGuiStyle.GrabMinSize = 8.0
    ImGuiStyle.GrabRounding = 1.0

    ImGuiColors[ImGuiClr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    ImGuiColors[ImGuiClr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    ImGuiColors[ImGuiClr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    ImGuiColors[ImGuiClr.TitleBg]                = ImVec4(RGBA(90, 224, 83, 1))
    ImGuiColors[ImGuiClr.TitleBgActive]          = ImVec4(RGBA(90, 224, 83, 1))
    ImGuiColors[ImGuiClr.TitleBgCollapsed]       = ImVec4(RGBA(90, 224, 83, 0.51))
    ImGuiColors[ImGuiClr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    ImGuiColors[ImGuiClr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
    ImGuiColors[ImGuiClr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
    ImGuiColors[ImGuiClr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    ImGuiColors[ImGuiClr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    ImGuiColors[ImGuiClr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.Separator]              = ImGuiColors[ImGuiClr.Border]
    ImGuiColors[ImGuiClr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    ImGuiColors[ImGuiClr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    ImGuiColors[ImGuiClr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    ImGuiColors[ImGuiClr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    ImGuiColors[ImGuiClr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    ImGuiColors[ImGuiClr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    ImGuiColors[ImGuiClr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    ImGuiColors[ImGuiClr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    ImGuiColors[ImGuiClr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    ImGuiColors[ImGuiClr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    ImGuiColors[ImGuiClr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    ImGuiColors[ImGuiClr.ComboBg]                = ImGuiColors[ImGuiClr.PopupBg]
    ImGuiColors[ImGuiClr.Border]                 = ImVec4(RGBA(4, 212, 28, 1))
    ImGuiColors[ImGuiClr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    ImGuiColors[ImGuiClr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    ImGuiColors[ImGuiClr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    ImGuiColors[ImGuiClr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    ImGuiColors[ImGuiClr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    ImGuiColors[ImGuiClr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    ImGuiColors[ImGuiClr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    ImGuiColors[ImGuiClr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    ImGuiColors[ImGuiClr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    ImGuiColors[ImGuiClr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    ImGuiColors[ImGuiClr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    ImGuiColors[ImGuiClr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    ImGuiColors[ImGuiClr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    ImGuiColors[ImGuiClr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function RGBA(r, g, b, a)
    r = r / 255
    g = g / 255
    b = b / 255
    return r, g, b, a
end

-- Рисует рамку вокруг персонажа по экранным координатам
function drawCharBox(handle, color)
    if not doesCharExist(handle) then return end
    local hx, hy, hz = GetBodyPartCoordinates(8, handle)
    local hxx, hyy = convert3DCoordsToScreen(hx, hy, hz)
    if not hxx or not hyy or hxx <= 0 or hyy <= 0 then return end
    local fx, fy, fz = getCharCoordinates(handle)
    local fxx, fyy = convert3DCoordsToScreen(fx, fy, fz)
    if not fxx or not fyy then return end
    local h = math.max(math.abs(fyy - hyy), 12)
    h = math.min(h, 80)
    local w = h * 0.62
    local x0 = fxx - w / 2
    local y0 = hyy - h * 0.1
    renderDrawBoxWithBorder(x0, y0, w, h, color, 1, color)
end

-- WH туш: рамка + линия + дистанция
function renderEspTush()
    if type(getAllChars) ~= "function" then return end
    for _, v in pairs(getAllChars()) do
        if doesCharExist(v) and v ~= PLAYER_PED then
            local m = getCharModel(v)
            if (m == MODEL_DEER or m == MODEL_BEAR) and getCharHealth(v) <= 0 then
                local lx, ly, lz = getCharCoordinates(v)
                local X, Y = convert3DCoordsToScreen(lx, ly, lz)
                if X and Y and X > 0 and X < 8000 and Y > 0 and Y < 6000 then
                    drawCharBox(v, 0xFFFF0000)
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local d = math.sqrt((lx-px)^2 + (ly-py)^2 + (lz-pz)^2)
                    renderFontDrawText(font_whGreen, 'Туша', X, Y, 0xFFFF0000)
                    renderFontDrawText(font_whGreen, string.format("%.0f м", d), X, Y - 10, 0xFFFFAAAA)
                    -- линия от перекрестья до туши
                    local sw, sh = getScreenResolution()
                    local hx, hy, hz = GetBodyPartCoordinates(8, v)
                    local hX, hY = convert3DCoordsToScreen(hx, hy, hz)
                    if hX and hY then
                        renderDrawLine(sw/2, sh/2, hX, hY, 1.0, 0xFFFF0000)
                    end
                end
            end
        end
    end
end

-- WH машин через память (getCarPointer + матрица позиции)
local _vehPosOk = (type(getCarPointer) == "function")
function getVehiclePosByMemory(veh)
    if not _vehPosOk then return nil end
    local ptr = getCarPointer(veh)
    if ptr and ptr > 0x100000 and ptr < 0x40000000 then
        local matrixPtr = readMemory(ptr + 0x14, 4, false)
        if matrixPtr and matrixPtr > 0x100000 and matrixPtr < 0x40000000 then
            local posPtr = matrixPtr + 0x30
            local x = representIntAsFloat(readMemory(posPtr + 0, 4, false))
            local y = representIntAsFloat(readMemory(posPtr + 4, 4, false))
            local z = representIntAsFloat(readMemory(posPtr + 8, 4, false))
            if x and y and z then
                return x, y, z
            end
        end
    end
    return nil
end

function renderEspCars()
    if type(getAllVehicles) ~= "function" then return end
    if not _vehPosOk then return end
    for _, v in pairs(getAllVehicles()) do
        if doesVehicleExist(v) then
            local okC, vvx, vvy, vvz = pcall(getVehiclePosByMemory, v)
            if okC and vvx and vvy and vvz then
                local VX, VY = convert3DCoordsToScreen(vvx, vvy, vvz)
                if VX and VY and VX > 0 and VX < 8000 and VY > 0 and VY < 6000 then
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local d = math.sqrt((vvx-px)^2 + (vvy-py)^2 + (vvz-pz)^2)
                    if Ohota.DistCars.v > 0 and d <= Ohota.DistCars.v then
                        renderFontDrawText(font_whGreen, 'Машина', VX, VY, 0xFF00CCFF)
                        renderFontDrawText(font_whGreen, string.format("%.0f м", d), VX, VY - 10, 0xFFFFFFFF)
                        if Ohota.LineCars.v then
                            local sw, sh = getScreenResolution()
                            renderDrawLine(sw/2, sh/2, VX, VY, 1.0, 0xFF00CCFF)
                        end
                    end
                end
            end
        end
    end
end

-- Деревья/кусты: в GTA растительность хранится в пуле ОБЪЕКТОВ (не зданий),
-- поэтому RPC 43 их не удаляет. НЕ удаляем объекты и НЕ телепортируем далеко
-- (риск краша) — прячем каждое дерево, погружая его на 500 м вниз НА ТОМ ЖЕ
-- МЕСТЕ (та же ячейка стриминга, ничего не ломаем). Координаты запоминаем,
-- чтобы вернуть деревья при выключении. Серверные объекты не трогаем.
local TREE_MODELS = {}
for _i = 613, 820 do
    TREE_MODELS[#TREE_MODELS + 1] = _i
end
local TREE_SET = {}
for _, m in ipairs(TREE_MODELS) do TREE_SET[m] = true end
local FOLIAGE_RADIUS = 120.0
local FOLIAGE_SINK = 500.0
local FOLIAGE_MAX_PER_PASS = 20

local _objHideOk = (type(getAllObjects) == "function" and type(setObjectCoordinates) == "function"
                    and type(getObjectModel) == "function" and type(getObjectCoordinates) == "function")

local _folHidden = {}   -- obj -> {x, y, z} (оригинальные координаты)
local _folCheckAt = 0

function applyFoliageClear()
    if not _objHideOk then return end
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local done = 0
    for _, obj in pairs(getAllObjects()) do
        if done >= FOLIAGE_MAX_PER_PASS then break end
        if doesObjectExist and doesObjectExist(obj) and not _folHidden[obj] then
            local isServer = sampGetObjectSampIdByHandle and sampGetObjectSampIdByHandle(obj)
            if not isServer then
                local om, m = pcall(getObjectModel, obj)
                if om and m and TREE_SET[m] then
                    local oc, _, cx, cy, cz = pcall(getObjectCoordinates, obj)
                    if oc then
                        local dx = cx - px; local dy = cy - py; local dz = cz - pz
                        if (dx*dx + dy*dy + dz*dz) <= (FOLIAGE_RADIUS * FOLIAGE_RADIUS) then
                            _folHidden[obj] = {cx, cy, cz}
                            pcall(setObjectCoordinates, obj, cx, cy, cz - FOLIAGE_SINK)
                            done = done + 1
                        end
                    end
                end
            end
        end
    end
    -- редкая чистка устаревших записей (дерево перестримилось = старый хэндл)
    if (os.clock() - _folCheckAt) > 10 then
        _folCheckAt = os.clock()
        for h in pairs(_folHidden) do
            if not (doesObjectExist and doesObjectExist(h)) then
                _folHidden[h] = nil
            end
        end
    end
end

function restoreFoliage()
    if not _objHideOk then return end
    for h, coords in pairs(_folHidden) do
        if doesObjectExist and doesObjectExist(h) then
            pcall(setObjectCoordinates, h, coords[1], coords[2], coords[3])
        end
        _folHidden[h] = nil
    end
    _folHidden = {}
end

function onReceivePacket(id, bs)
    if type(_cefLogReceive) == 'function' then pcall(_cefLogReceive, id, bs) end
    if id ~= 215 then return end
    local pk = ''
    for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do pk = pk .. string.char(raknetBitStreamReadInt8(bs)) end
    if Ohota.AutoY.v then
        if pk:find("setFill(0, 100)", 1, true) then
            Ohota.AutoY_Clicker:Stop()
            dbg("AUTOY stop-100")
        elseif pk:find("setFill(0, ", 1, true) then
            Ohota.AutoY_Clicker:Start()
            dbg("AUTOY start triggered")
            AutoYLastSetFill = os.clock()
        end
    end
end

function targetAtCoords(x, y, z)
    local cx, cy, cz = getActiveCameraCoordinates()

    local vect = {
        fX = cx - x,
        fY = cy - y,
        fZ = cz - z
    }

    local screenAspectRatio = representIntAsFloat(readMemory(0xC3EFA4, 4, false))
    local crosshairOffset = {
        representIntAsFloat(readMemory(0xB6EC10, 4, false)),
        representIntAsFloat(readMemory(0xB6EC14, 4, false))
    }

    local mult = math.tan(getCameraFov() * 0.5 * 0.017453292)
    fz = 3.14159265 - math.atan2(1.0, mult * ((0.5 - crosshairOffset[1]) * (2 / screenAspectRatio)))
    fx = 3.14159265 - math.atan2(1.0, mult * 2 * (crosshairOffset[2] - 0.5))

    local camMode = readMemory(0xB6F1A8, 1, false)

    if not (camMode == 53 or camMode == 55) then
        fx = 3.14159265 / 2
        fz = 3.14159265 / 2
    end

    local ax = math.atan2(vect.fY, -vect.fX) - 3.14159265 / 2
    local az = math.atan2(math.sqrt(vect.fX * vect.fX + vect.fY * vect.fY), vect.fZ)

    setCameraPositionUnfixed(az - fz, fx - ax)
end
