script_name('CEF Monitoring')
script_properties('work-in-pause')
script_author('Rice.')
script_version('1.0')

local imgui = require 'mimgui'
local ffi = require 'ffi'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local renderWindow = imgui.new.bool(false)
local renderScreen = imgui.new.bool(false)
local cursorScreen = imgui.new.bool(true)

local resX, resY = getScreenResolution()

local packetList, arrayFind = {}, {}
local menuDisplay, lastHintCopy = 0, 0
local search = imgui.new.char[512]()

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.DarkTheme()
    
    local defGlyph = imgui.GetIO().Fonts.ConfigData.Data[0].GlyphRanges
	imgui.GetIO().Fonts:Clear()
	local font_config = imgui.ImFontConfig()
	font_config.SizePixels = 14.0;
	font_config.GlyphExtraSpacing.x = 0.1
	imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arialbd.ttf', font_config.SizePixels, font_config, defGlyph)
end)

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
    function(player)
        player.HideCursor = imgui.IsMouseDown(1)
        local sizeX, sizeY = 700, 420
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.Begin('CEF Monitoring', renderWindow, imgui.WindowFlags.NoCollapse)
            if menuDisplay == 0 then
                imgui.CenterText(u8('Всего пакетов: ' .. #packetList))

                imgui.PushItemWidth(-1)
                imgui.InputTextWithHint('##search', u8('Поиск пакетов'), search, ffi.sizeof(search))
                imgui.PopItemWidth()

                if imgui.Button(u8('Найти'), imgui.ImVec2(-1)) then
                    arrayFind = {}
                    if #u8:decode(ffi.string(search)) > 0 then
                        for k, v in pairs(packetList) do
                            if string.find(string.nlower(('[%s] %s | %s'):format((v.status == 2 and 'GET' or 'SEND'), v.text, table.concat(v.packets, ', '))), string.nlower(u8:decode(ffi.string(search))), nil, true) then
                                table.insert(arrayFind, v)
                            end
                        end
                        if #arrayFind == 0 then sms('Ничего не найдено!') end
                    else
                        sms('Отсутствует текст для поиска!')
                    end
                end

                if imgui.Button(u8('Отображение на экране'), imgui.ImVec2(-1)) then renderScreen[0] = not renderScreen[0] end

                if imgui.Button(u8('Очистить лог'), imgui.ImVec2(-1)) then packetList = {} end

                imgui.BeginChild('packets', imgui.ImVec2(-1, -1), true, imgui.WindowFlags.HorizontalScrollbar)
                    local obj = (#arrayFind > 0) and arrayFind or packetList
                    local clipper = imgui.ImGuiListClipper(#obj)
                    while clipper:Step() do
                        for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
                            local text = obj[i].text
                            local packets = table.concat(obj[i].packets, ', ')
                            local time = obj[i].time
                            local status = obj[i].status
                            local key = obj[i].key

                            imgui.BeginGroup()
                                imgui.Text(('[%s] [%s]'):format(time, key))
                                imgui.SameLine()
                                imgui.TextColored( (status == 2 and imgui.ImVec4(1, 0, 0, 1) or imgui.ImVec4(0, 1, 0, 1)), ('[%s] %s | %s'):format((status == 2 and 'GET' or 'SEND'), u8(text), packets))
                            imgui.EndGroup()
                            if imgui.IsItemClicked(0) then
                                imgui.SetClipboardText(('%s | %s'):format(u8(text), packets))
                            elseif imgui.IsItemClicked(1) then
                                menuDisplay = key
                            end
                            imgui.Hint('packet' .. key, u8(('Пакет №%s:\nЛКМ - Скопировать пакет\nПКМ - Детальная информация'):format(key)))
                        end
                    end
                imgui.EndChild()
            else
                imgui.CenterText(u8('Просмотр пакета №' .. menuDisplay))

                imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 2)
                if imgui.Button(u8('Воспроизвести пакет'), imgui.ImVec2(200)) then
                    local bs = raknetNewBitStream()

                    for i = (packetList[menuDisplay].status == 2 and 2 or 1), #packetList[menuDisplay].packets do
                        raknetBitStreamWriteInt8(bs, packetList[menuDisplay].packets[i])
                    end

                    if packetList[menuDisplay].status == 2 then
                        raknetEmulPacketReceiveBitStream(packetList[menuDisplay].packets[1], bs)
                    else
                        raknetSendBitStream(bs)
                    end

                    raknetDeleteBitStream(bs)
                end

                imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 2)
                imgui.BeginChild('packets1', imgui.ImVec2(200, imgui.GetWindowHeight() - 115), true)
                    for k, v in pairs(packetList[menuDisplay].packets) do
                        imgui.CenterText(tostring(v), 100)
                        imgui.SameLine(100)
                        imgui.CenterText(((v >= 33 and v <= 255) and u8(string.char(v)) or '?'), 300)
                        if k ~= #packetList[menuDisplay].packets then imgui.Separator() end
                    end
                imgui.EndChild()

                imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 2)
                if imgui.Button(u8('Вернуться к списку'), imgui.ImVec2(200)) then menuDisplay = 0 end

                imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2, 78))
                local p = imgui.GetCursorScreenPos()
                imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x, p.y + imgui.GetWindowHeight() - 117), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Separator]))
            end
        imgui.End()
    end
)

local listFrame = imgui.OnFrame(
    function() return renderScreen[0] and cursorScreen[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
    function(player)
        player.HideCursor = true
        local sizeX, sizeY = 700, 200
        imgui.SetNextWindowPos(imgui.ImVec2((resX - sizeX) / 2, resY - sizeY - 5), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.07, 0.07, 0.07, 0.8))
            imgui.Begin('ListFrame', renderScreen, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove)
                for i = #packetList, (#packetList >= 10 and #packetList - 9 or 1), -1 do
                    local text = packetList[i].text
                    local packets = table.concat(packetList[i].packets, ', ')
                    local time = packetList[i].time
                    local status = packetList[i].status
                    local key = packetList[i].key

                    imgui.Text(('[%s] [%s]'):format(time, key))
                    imgui.SameLine()
                    imgui.TextColored( (status == 2 and imgui.ImVec4(1, 0, 0, 1) or imgui.ImVec4(0, 1, 0, 1)), ('[%s] %s | %s'):format((status == 2 and 'GET' or 'SEND'), u8(text), packets))
                end
            imgui.End()
        imgui.PopStyleColor(1)
    end
)

function main()
    while not isSampAvailable() do wait(0) end
    sms('Активация: /cef')
    sampRegisterChatCommand('cef', function() renderWindow[0] = not renderWindow[0] end)
    while true do wait(0)
        cursorScreen[0] = cursorHoveredWindow()
    end
end

function cursorHoveredWindow()
    local px, py = getCursorPos()
    local size = imgui.ImVec2(700, 200)
    local wp = imgui.ImVec2((resX - size.x) / 2, resY - size.y - 5)
    return not(px >= wp.x and px <= (wp.x + size.x) and py >= wp.y and py <= (wp.y + size.y))
end

function onSendPacket(id, bs, priority, reliability, orderingChannel) 
    if not raknetGetPacketName(id) then
        local text, packets = bitStreamStructure(bs)
        table.insert(packetList, {status = 3, text = text, packets = packets, time = os.date('%H:%M:%S'), key = #packetList + 1})
    end
end

function onReceivePacket(id, bs) 
    if not raknetGetPacketName(id) then
        local text, packets = bitStreamStructure(bs)
        table.insert(packetList, {status = 2, text = text, packets = packets, time = os.date('%H:%M:%S'), key = #packetList + 1})
    end
end

function bitStreamStructure(bs)
    local text, array = '', {}
    for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do
        local byte = raknetBitStreamReadInt8(bs)
        if byte >= 32 and byte <= 255 and byte ~= 37 then text = text .. string.char(byte) end
        table.insert(array, byte)
    end
    raknetBitStreamResetReadPointer(bs)
    return text, array
end

function imgui.CenterText(text, size)
    imgui.SetCursorPosX((size or imgui.GetWindowSize().x) / 2 - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function string.nlower(s)
	local line_lower = string.lower(s)
	for line in s:gmatch('.') do
		if (string.byte(line) >= 192 and string.byte(line) <= 223) or string.byte(line) == 168 then
			line_lower = string.gsub(line_lower, line, string.char(string.byte(line) == 168 and string.byte(line) + 16 or string.byte(line) + 32), 1)
		end
	end
	return line_lower
end

function imgui.Hint(str_id, hint, delay)
    local hovered = imgui.IsItemHovered()
    local animTime = 0.2
    local delay = delay or 0.00
    local show = true

    if not allHints then allHints = {} end
    if not allHints[str_id] then
        allHints[str_id] = {
            status = false,
            timer = 0
        }
    end

    if hovered then
        for k, v in pairs(allHints) do
            if k ~= str_id and os.clock() - v.timer <= animTime  then
                show = false
            end
        end
    end

    if show and allHints[str_id].status ~= hovered then
        allHints[str_id].status = hovered
        allHints[str_id].timer = os.clock() + delay
    end

    if show then
        local between = os.clock() - allHints[str_id].timer
        if between <= animTime then
            local s = function(f)
                return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
            end
            local alpha = hovered and s(between / animTime) or s(1.00 - between / animTime)
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
            imgui.SetTooltip(hint)
            imgui.PopStyleVar()
        elseif hovered then
            imgui.SetTooltip(hint)
        end
    end
end

function sms(text)
    sampAddChatMessage('[CEF Monitoring] {FFFFFF}' .. text, 0x404040)
end

function imgui.DarkTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    -->> Sizez
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(5, 5)

    imgui.GetStyle().IndentSpacing = 21
    imgui.GetStyle().ScrollbarSize = 14
    imgui.GetStyle().GrabMinSize = 10

    imgui.GetStyle().WindowBorderSize = 0
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 0

    imgui.GetStyle().WindowRounding = 5
    imgui.GetStyle().ChildRounding = 5
    imgui.GetStyle().PopupRounding = 5
    imgui.GetStyle().FrameRounding = 5
    imgui.GetStyle().ScrollbarRounding = 2.5
    imgui.GetStyle().GrabRounding = 5
    imgui.GetStyle().TabRounding = 5

    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.50, 0.50)
    
    -->> Colors
    imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.2, 0.2, 0.2, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.25, 0.25, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(0.5, 0.5, 0.5, 0.35)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end