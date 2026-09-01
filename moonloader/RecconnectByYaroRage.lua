-- ?? Настройка среды (загружаем только то, что нужно)
require 'lib.moonloader'
require 'lib.sampfuncs' -- Для работы с памятью и функциями SAMP
local inicfg = require('inicfg') -- Для сохранения настроек FastConnect
local ywelcome = require('ywelcome')    -- Наша библиотека для красивых сообщений
local vkeys = require('vkeys')  -- Библиотека для работы с виртуальными клавишами

-----------------------------------
--- Логическая часть ---
-----------------------------------

-- Проверка того, что игрок действительно находится в игре
local function isActuallyInGame()
    local ped_ptr = getCharPointer(PLAYER_PED) or 0
    return readMemory(ped_ptr + 0x46C, 1, false) == 1 -- Флаг спавна
        or readMemory(ped_ptr + 0x72C, 1, false) > 0 -- Наличие оружия
end

-- Точная логика реконнекта из предоставленного образца
function doRec(arg)
    lua_thread.create(function()
        if sampIsDialogActive() then
            sampCloseCurrentDialogWithButton(0)
        end

        printStringNow("Reconnect in ~r~"..arg.."  ~w~sec.", 1600)

        if sampGetGamestate() ~= GAMESTATE_RESTARTING then
            sampSetGamestate(GAMESTATE_DISCONNECTED)
            sampDisconnectWithReason(0)
        end

        wait(arg * 1000)
        sampSetGamestate(GAMESTATE_WAIT_CONNECT)
    end)
end

-- Точная логика патча фаст коннекта из образца
function applyPatch()
    if fastrecoonnect_enabled then
        writeMemory(sampGetBase() + 2964549, 2, 0, true)
    else
        writeMemory(sampGetBase() + 2964549, 2, 0x01F4, true)
    end
end

-----------------------------------
--- Сохранение настроек ---
-----------------------------------

-- Создаёт директорию config\RecconnectByYaroRage, если её нет
local function createConfigDir()
    local dirPath = getWorkingDirectory() .. '\\config'
    local subDirPath = dirPath .. '\\RecconnectByYaroRage'
    
    if not doesDirectoryExist(dirPath) then
        createDirectory(dirPath)
    end
    if not doesDirectoryExist(subDirPath) then
        createDirectory(subDirPath)
    end
end

-- Загрузка настроек при старте
function loadSettings()
    createConfigDir()
    
    local loadedCfg = inicfg.load(nil, 'config\\RecconnectByYaroRage\\RecconnectByYaroRage.ini')
    if loadedCfg and loadedCfg.Settings and loadedCfg.Settings.AutoEnableFast ~= nil then
        fastrecoonnect_enabled = loadedCfg.Settings.AutoEnableFast
    end
end

-- Сохранение настроек при изменении
function saveSettings()
    createConfigDir()
    
    local cfg = {
        Settings = { AutoEnableFast = fastrecoonnect_enabled }
    }
    inicfg.save(cfg, 'config\\RecconnectByYaroRage\\RecconnectByYaroRage.ini')
end

-----------------------------------
--- Точка входа ---
-----------------------------------

-- ?? Глобальные настройки
local ini_path = getWorkingDirectory() .. '\\config\\RecconnectByYaroRage\\RecconnectByYaroRage.ini'
local fastrecoonnect_enabled = true -- Включено по умолчанию
local sampAvailable = false

function main()
    repeat wait(0) until isSampAvailable()
    sampAvailable = true

    -- ?? Инициализация
    loadSettings()
    applyPatch() -- Сразу применяем состояние из конфига

    -- Регистрация команд (используем /mrec как в образце, а также /rec для совместимости)
    sampRegisterChatCommand('mrec', function(arg)
        if tonumber(arg) then
            doRec(tonumber(arg))
        else
            printStringNow("Wrong ~r~[~w~value~r~]", 1600)
        end
    end)

    sampRegisterChatCommand('rec', function(arg)
        local seconds = tonumber(arg) or 5
        doRec(seconds)
    end)

    sampRegisterChatCommand('fastrec', function()
        fastrecoonnect_enabled = not fastrecoonnect_enabled
        saveSettings()
        applyPatch()

        ywelcome(
            "Recconnect",
            string.format('Фаст коннект сейчас: %s',
                fastrecoonnect_enabled and 'Вкл' or 'Выкл')
        )
    end)

    -- Приветствие
    ywelcome(
        "Recconnect",
        'Активируйте реконнект кнопкой F11 | Команды: /rec <сек>, /fastrec.'
    )

    -- Основной цикл обработки нажатия F11
    while true do
        wait(0)

        if wasKeyPressed(vkeys.VK_F11) and not sampIsChatInputActive() and not sampIsDialogActive() then
            if isSampAvailable() and isActuallyInGame() then
                doRec(5)
            end
        end

        -- Периодическая проверка патча фаст коннекта (как в UltraHack)
        if fastrecoonnect_enabled then
            writeMemory(sampGetBase() + 2964549, 2, 0, true)
        end
    end
end