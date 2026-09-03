script_name("SAMPFUNCS Console")
script_version("2.1")
script_author("Custom")
script_description("Консоль SAMPFUNCS, адаптированная под любое разрешение экрана")
script_dependencies("SAMPFUNCS ^5.3")
script_properties("work-in-pause")

require "lib.sampfuncs"
require "lib.moonloader"

-- ==============================================
-- НАСТРОЙКИ
-- ==============================================
local SETTINGS = {
    maxMessages = 200,
    visibleLines = 12,
    holdTime = 0.3,            -- время удержания для активации (сек)
    fontSize = 10,
    fontName = "Tahoma",
    position = "bottom-left",
    backgroundAlpha = 0xAA,
    inputLineHeight = 18,
}

-- VK коды клавиш для активации: "+" и "="
-- На стандартной раскладке "+" = Shift + "=", "+" = 0xBB, "=" = 0x3D
-- Поддерживаем несколько вариантов
local VK_PLUS  = 0xBB  -- VK_OEM_PLUS ("+" / "=")
local VK_ADD   = 0x6B  -- VK_ADD (Numpad +)
local VK_SHIFT = 0x10  -- VK_SHIFT

-- ==============================================
-- ЦВЕТА
-- ==============================================
local COLORS = {
    border    = 0xFF555555,
    text      = 0xFFC0C0C0,
    input     = 0xFFFFFFFF,
    prompt    = 0xFF00FF00,
    scrollBar = 0xFF888888,
    info      = 0xFFA9EFF5,
    debug     = 0xFFAFA9F5,
    error     = 0xFFFF7070,
    warn      = 0xFFF5C28E,
    system    = 0xFFFA9746,
    fatal     = 0xFF040404,
    exception = 0xFFF5A9A9,
    script    = 0xFF7DD156,
}

-- ==============================================
-- СОСТОЯНИЕ
-- ==============================================
local messages = {}
local scrollOffset = 0
local isVisible = false
local consoleFont = nil
local consoleFontSmall = nil
local inputText = ""
local inputCursorPos = 0
local inputActive = false

-- Таймер удержания
local holdTimer = 0
local holdActive = false
local keyStates = {}
local lastSW = 0
local lastSH = 0

-- ==============================================
-- УТИЛИТЫ
-- ==============================================

local function getRes()
    return getScreenResolution()
end

local function scaleFont(baseSize)
    local w, h = getRes()
    local sc = math.max(w / 1280, h / 720)
    return math.max(8, math.floor(baseSize * sc))
end

local function scale(value)
    local w, h = getRes()
    local sc = math.max(w / 1280, h / 720)
    return math.floor(value * sc)
end

local function getConsolePosition(w, h, consoleW, consoleH)
    local margin = scale(10)
    local sx, sy
    if SETTINGS.position == "bottom-left" then
        sx = margin
        sy = h - consoleH - margin - SETTINGS.inputLineHeight
    elseif SETTINGS.position == "bottom-right" then
        sx = w - consoleW - margin
        sy = h - consoleH - margin - SETTINGS.inputLineHeight
    elseif SETTINGS.position == "top-left" then
        sx = margin
        sy = margin
    elseif SETTINGS.position == "top-right" then
        sx = w - consoleW - margin
        sy = margin
    else
        sx = margin
        sy = h - consoleH - margin - SETTINGS.inputLineHeight
    end
    return sx, sy
end

-- Проверка: нажата ли "+" (с Shift или Numpad +)
local function isPlusKeyDown()
    return isKeyDown(VK_ADD)
        or (isKeyDown(VK_PLUS) and isKeyDown(VK_SHIFT))
end

-- Проверка: нажата ли "=" (без Shift)
local function isEqualsKeyDown()
    return isKeyDown(VK_PLUS) and not isKeyDown(VK_SHIFT)
end

-- ==============================================
-- ДОБАВЛЕНИЕ СООБЩЕНИЙ
-- ==============================================

local function addMessage(text, color)
    table.insert(messages, {
        text = text or "",
        color = color or COLORS.text,
        time = os.clock()
    })
    if #messages > SETTINGS.maxMessages then
        table.remove(messages, 1)
    end
    -- Отправляем в нативную консоль SAMPFUNCS
    if isSampfuncsLoaded() and isOpcodesAvailable() then
        local cleanText = text:gsub("{%x%x%x%x%x%x}", "")
        sampfuncsLog(cleanText)
    end
end

local function clearConsole()
    messages = {}
    scrollOffset = 0
    addMessage("Консоль очищена.", COLORS.system)
end

-- ==============================================
-- ПАРСИНГ ЦВЕТОВ {RRGGBB}
-- ==============================================

local function parseColorSegments(text)
    local segments = {}
    local currentColor = nil
    local remaining = text
    while true do
        local startIdx, endIdx, hexColor = remaining:find("{(%x%x%x%x%x%x)}")
        if not startIdx then
            if #remaining > 0 then
                table.insert(segments, { text = remaining, color = currentColor })
            end
            break
        end
        if startIdx > 1 then
            table.insert(segments, { text = remaining:sub(1, startIdx - 1), color = currentColor })
        end
        currentColor = tonumber(hexColor, 16)
        remaining = remaining:sub(endIdx + 1)
    end
    return segments
end

-- ==============================================
-- ИНИЦИАЛИЗАЦИЯ ШРИФТОВ
-- ==============================================

local function initFonts()
    local fsize = scaleFont(SETTINGS.fontSize)
    local fsizeSmall = scaleFont(SETTINGS.fontSize - 2)
    consoleFont = renderCreateFont(SETTINGS.fontName, fsize, FCR_BOLD + FCR_BORDER)
    consoleFontSmall = renderCreateFont(SETTINGS.fontName, fsizeSmall, FCR_BORDER)
end

-- ==============================================
-- ОТРИСОВКА КОНСОЛИ
-- ==============================================

local function renderConsole()
    if not consoleFont or not consoleFontSmall then return end
    if not isVisible then return end

    local sw, sh = getRes()
    local lineH = renderGetFontDrawHeight(consoleFont) + 2
    local inputH = SETTINGS.inputLineHeight
    local consoleH = SETTINGS.visibleLines * lineH
    local consoleW = scale(500)

    local maxW = math.floor(sw * 0.6)
    if consoleW > maxW then consoleW = maxW end

    local cx, cy = getConsolePosition(sw, sh, consoleW, consoleH)
    local bgAlpha = SETTINGS.backgroundAlpha

    -- Рамка и фон
    renderDrawBox(cx - 1, cy - 1, consoleW + 2, consoleH + inputH + 2, COLORS.border)
    renderDrawBox(cx, cy, consoleW, consoleH, bit.bor(bit.lshift(bgAlpha, 24), 0x000000))
    renderDrawBox(cx, cy + consoleH, consoleW, inputH, bit.bor(bit.lshift(bgAlpha, 24), 0x000000))

    -- Видимые сообщения
    local visibleStart = #messages - SETTINGS.visibleLines - scrollOffset + 1
    if visibleStart < 1 then visibleStart = 1 end
    local visibleEnd = visibleStart + SETTINGS.visibleLines - 1
    if visibleEnd > #messages then visibleEnd = #messages end

    local textMargin = scale(4)
    local drawY = cy + textMargin
    for i = visibleStart, visibleEnd do
        local msg = messages[i]
        if msg then
            local segments = parseColorSegments(msg.text)
            local drawX = cx + textMargin
            for _, seg in ipairs(segments) do
                local color = seg.color or msg.color or COLORS.text
                local fullColor = bit.bor(bit.lshift(bgAlpha, 24), bit.band(color, 0x00FFFFFF))
                renderFontDrawText(consoleFont, seg.text, drawX, drawY, fullColor)
                drawX = drawX + renderGetFontDrawTextLength(consoleFont, seg.text)
            end
            drawY = drawY + lineH
        end
    end

    -- Полоса прокрутки
    if #messages > SETTINGS.visibleLines then
        local scrollBarW = scale(3)
        local scrollBarX = cx + consoleW - scrollBarW - 2
        local scrollBarH = consoleH
        local scrollBarY = cy
        renderDrawBox(scrollBarX, scrollBarY, scrollBarW, scrollBarH, 0x40000000)

        local totalLines = #messages
        local thumbH = math.max(10, math.floor((SETTINGS.visibleLines / totalLines) * scrollBarH))
        local thumbMax = scrollBarH - thumbH
        local scrollMax = totalLines - SETTINGS.visibleLines
        local thumbY = scrollBarY
        if scrollMax > 0 then
            thumbY = scrollBarY + math.floor((scrollOffset / scrollMax) * thumbMax)
        end
        renderDrawBox(scrollBarX, thumbY, scrollBarW, thumbH, COLORS.scrollBar)
    end

    -- Строка ввода
    local inputY = cy + consoleH + 2
    local prompt = "> "
    local promptW = renderGetFontDrawTextLength(consoleFontSmall, prompt)
    renderFontDrawText(consoleFontSmall, prompt, cx + textMargin, inputY + 3, COLORS.prompt)

    if inputActive then
        local beforeCursor = inputText:sub(1, inputCursorPos)
        local afterCursor = inputText:sub(inputCursorPos + 1)
        local beforeW = renderGetFontDrawTextLength(consoleFontSmall, beforeCursor)
        local afterW = renderGetFontDrawTextLength(consoleFontSmall, afterCursor)
        renderFontDrawText(consoleFontSmall, beforeCursor, cx + textMargin + promptW, inputY + 3, COLORS.input)

        -- Курсор
        if os.clock() % 1 > 0.5 then
            local cursorH = renderGetFontDrawHeight(consoleFontSmall)
            renderDrawBox(cx + textMargin + promptW + beforeW, inputY + 3, 2, cursorH, COLORS.input)
        end

        renderFontDrawText(consoleFontSmall, afterCursor, cx + textMargin + promptW + beforeW, inputY + 3, COLORS.input)
    else
        renderFontDrawText(consoleFontSmall, inputText, cx + textMargin + promptW, inputY + 3, COLORS.input)
    end

    -- Подсказка
    local holdHint = "Удерж. + = 0.3с — открыть"
    if isVisible then holdHint = "Удерж. + = 0.3с — закрыть" end
    local hint = string.format("%s | Стрелки — прокрутка | Сообщений: %d", holdHint, #messages)
    local hintW = renderGetFontDrawTextLength(consoleFontSmall, hint)
    renderFontDrawText(consoleFontSmall, hint, cx + consoleW - hintW - textMargin, inputY + 3, 0x80FFFFFF)
end

-- ==============================================
-- ОБРАБОТКА ВВОДА
-- ==============================================

local function processInput()
    if #inputText > 0 then
        local orig = inputText
        local cmd = orig:lower()
        if cmd == "/clear" or cmd == "/cls" then
            clearConsole()
        elseif cmd:sub(1, 3) == "/t " then
            local num = tonumber(cmd:sub(4))
            if num and num >= 6 and num <= 30 then
                SETTINGS.fontSize = num
                initFonts()
                addMessage(string.format("Размер шрифта изменён на %d", SETTINGS.fontSize), COLORS.system)
            else
                addMessage("Использование: /t <6-30> (текущий: " .. SETTINGS.fontSize .. ")", COLORS.warn)
            end
        elseif cmd:sub(1, 1) == "=" then
            local code = "print(" .. orig:sub(2) .. ")"
            local func, err = load(code)
            if func then
                local ok, result = pcall(func)
                if ok and result ~= nil then
                    addMessage(tostring(result), COLORS.info)
                elseif not ok then
                    addMessage("Ошибка: " .. tostring(result), COLORS.error)
                end
            else
                addMessage("Ошибка парсинга: " .. tostring(err), COLORS.error)
            end
        else
            local func, err = load(orig)
            if func then
                local ok, err2 = pcall(func)
                if not ok then
                    addMessage("Ошибка: " .. tostring(err2), COLORS.error)
                end
            else
                addMessage("Ошибка парсинга: " .. tostring(err), COLORS.error)
            end
        end
    end
    inputText = ""
    inputCursorPos = 0
end

local function processKeyPress(vk)
    if vk == 0x26 then
        if scrollOffset < #messages - SETTINGS.visibleLines then
            scrollOffset = scrollOffset + 1
        end
        return true
    end
    if vk == 0x28 then
        if scrollOffset > 0 then
            scrollOffset = scrollOffset - 1
        end
        return true
    end
    if vk == 0x21 then
        scrollOffset = scrollOffset + SETTINGS.visibleLines
        local maxScroll = #messages - SETTINGS.visibleLines
        if maxScroll < 0 then maxScroll = 0 end
        if scrollOffset > maxScroll then scrollOffset = maxScroll end
        return true
    end
    if vk == 0x22 then
        scrollOffset = scrollOffset - SETTINGS.visibleLines
        if scrollOffset < 0 then scrollOffset = 0 end
        return true
    end
    if vk == 0x24 then
        local maxScroll = #messages - SETTINGS.visibleLines
        if maxScroll < 0 then maxScroll = 0 end
        scrollOffset = maxScroll
        return true
    end
    if vk == 0x23 then
        scrollOffset = 0
        return true
    end
    return false
end

-- ==============================================
-- КОМАНДЫ SAMPFUNCS
-- ==============================================

local function cmd_lua(code)
    if code:sub(1, 1) == "=" then
        code = "print(" .. code:sub(2, -1) .. ")"
    end
    local func, err = load(code)
    if func then
        local ok, result = pcall(func)
        if ok and result ~= nil then
            addMessage(tostring(result), COLORS.info)
        elseif not ok then
            addMessage("Ошибка: " .. tostring(result), COLORS.error)
        end
    else
        addMessage("Ошибка парсинга: " .. tostring(err), COLORS.error)
    end
end

local function cmd_gtp(code)
    cmd_lua(code)
end

local function cmd_t(sizeStr)
    local num = tonumber(sizeStr)
    if num and num >= 6 and num <= 30 then
        SETTINGS.fontSize = num
        initFonts()
        addMessage(string.format("Размер шрифта изменён на %d", SETTINGS.fontSize), COLORS.system)
    else
        addMessage("Использование: /t <6-30> (текущий: " .. SETTINGS.fontSize .. ")", COLORS.warn)
    end
end

-- ==============================================
-- ПЕРЕХВАТ СООБЩЕНИЙ
-- ==============================================

function onSystemMessage(msg, type, sender)
    if not isSampfuncsLoaded() or not isOpcodesAvailable() then return end
    if msg == nil or msg == "" then return end
    if type == TAG.TYPE_DEBUG then return end

    local tagColors = {
        [TAG.TYPE_INFO]      = COLORS.info,
        [TAG.TYPE_ERROR]     = COLORS.error,
        [TAG.TYPE_WARN]      = COLORS.warn,
        [TAG.TYPE_SYSTEM]    = COLORS.system,
        [TAG.TYPE_FATAL]     = COLORS.fatal,
        [TAG.TYPE_EXCEPTION] = COLORS.exception,
    }
    local tagNames = {
        [TAG.TYPE_INFO]      = "INFO",
        [TAG.TYPE_ERROR]     = "ERROR",
        [TAG.TYPE_WARN]      = "WARN",
        [TAG.TYPE_SYSTEM]    = "SYSTEM",
        [TAG.TYPE_FATAL]     = "FATAL",
        [TAG.TYPE_EXCEPTION] = "EXCEPTION",
    }

    local color = tagColors[type] or COLORS.text
    local tag = tagNames[type]
    local prefix = ""
    if tag then
        prefix = string.format("{%s}[%s] ", bit.tohex(color, 6), tag)
    end
    if sender and sender.name then
        prefix = prefix .. string.format("{E0E0E0}(%s) ", sender.name)
    end

    -- Пишем в нативную консоль SAMPFUNCS
    local cleanMsg = msg:gsub("{%x%x%x%x%x%x}", "")
    local tagtxt = get_tag_text(type)
    local logStr = string.format("[ML] %s %s", tagtxt and ("(" .. tagtxt .. ")") or "", cleanMsg)
    sampfuncsLog(logStr)

    addMessage(prefix .. msg, color)
end

function onScriptMessage(msg, sender)
    if not isSampfuncsLoaded() or not isOpcodesAvailable() then return end
    if msg == nil or msg == "" then return end
    local prefix = ""
    if sender and sender.name then
        prefix = string.format("{7DD156}(%s) ", sender.name)
    end
    addMessage(prefix .. msg, COLORS.script)
end

-- ==============================================
-- ГЛАВНЫЙ ЦИКЛ
-- ==============================================

function main()
    if not isSampfuncsLoaded() then
        print("SAMPFUNCS Console: SAMPFUNCS не загружен!")
        return
    end

    while not isSampAvailable() do wait(100) end

    initFonts()

    -- Регистрируем команды в SAMPFUNCS (как в SF Integration)
    sampfuncsRegisterConsoleCommand("lua", cmd_lua)
    sampfuncsRegisterConsoleCommand(">>", cmd_lua)
    sampfuncsRegisterConsoleCommand("gtp", cmd_gtp)
    sampfuncsRegisterConsoleCommand("t", cmd_t)

    addMessage("Консоль SAMPFUNCS загружена.", COLORS.system)
    addMessage("Удерживайте + и = одновременно 0.3 сек для открытия/закрытия.", COLORS.info)
    addMessage("Команды: /clear, /cls | /t <6-30> — размер шрифта | =выражение | Lua-код", COLORS.info)

    while true do
        wait(0)

        -- Пересоздание шрифтов при смене разрешения
        local sw, sh = getScreenResolution()
        if sw ~= lastSW or sh ~= lastSH then
            initFonts()
            lastSW = sw
            lastSH = sh
        end

        -- ==========================================
        -- ДЕТЕКТОР УДЕРЖАНИЯ "+ =" НА 0.3 СЕКУНДЫ
        -- ==========================================
        local bothPressed = isPlusKeyDown() or isEqualsKeyDown()

        if bothPressed then
            if not holdActive then
                holdActive = true
                holdTimer = os.clock()
            else
                local elapsed = os.clock() - holdTimer
                if elapsed >= SETTINGS.holdTime then
                    isVisible = not isVisible
                    holdActive = false
                    holdTimer = 0
                    -- Ждём отпускания клавиш
                    while isPlusKeyDown() or isEqualsKeyDown() do wait(20) end
                end
            end
        else
            holdActive = false
            holdTimer = 0
        end

        -- ==========================================
        -- ОТРИСОВКА
        -- ==========================================
        if isVisible then
            renderConsole()

            local scrollKeys = {
                { vk = 0x26, id = "scrollUp" },
                { vk = 0x28, id = "scrollDown" },
                { vk = 0x21, id = "pageUp" },
                { vk = 0x22, id = "pageDown" },
                { vk = 0x24, id = "home" },
                { vk = 0x23, id = "end" },
            }
            for _, k in ipairs(scrollKeys) do
                if isKeyDown(k.vk) and not keyStates[k.id] then
                    processKeyPress(k.vk)
                    keyStates[k.id] = true
                elseif not isKeyDown(k.vk) then
                    keyStates[k.id] = false
                end
            end
        end
    end
end

-- ==============================================
-- ТЕГИ (для совместимости с SF Integration)
-- ==============================================

local tags = {
    [TAG.TYPE_INFO]      = {"info", 0xA9EFF5},
    [TAG.TYPE_DEBUG]     = {"debug", 0xAFA9F5},
    [TAG.TYPE_ERROR]     = {"error", 0xFF7070},
    [TAG.TYPE_WARN]      = {"warn", 0xF5C28E},
    [TAG.TYPE_SYSTEM]    = {"system", 0xFA9746},
    [TAG.TYPE_FATAL]     = {"fatal", 0x040404},
    [TAG.TYPE_EXCEPTION] = {"exception", 0xF5A9A9},
}

function get_tag_text(n)
    local tag = tags[n]
    return tag ~= nil and tag[1] or nil
end

function get_tag_color(n)
    local tag = tags[n]
    return tag ~= nil and tag[2] or nil
end
