-- Модуль Telegram AutoLoginByYaroRage
local AL = require("AutoLoginByYaroRage.state")
local M = {}

local https = require("ssl.https")
local ltn12 = require("ltn12")

function M.http_request(method, endpoint, body)
    local s = AL.state
    local url = "https://api.telegram.org/bot" .. s.tg_bot_token .. "/" .. endpoint
    local response_body = {}

    local params = {
        url = url,
        method = method,
        sink = ltn12.sink.table(response_body),
        verify = "none",
    }

    if body then
        local dkjson = require("dkjson")
        params.body = dkjson.encode(body)
        params.headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#params.body),
        }
    end

    local ok, code, headers, status = https.request(params)
    if ok and code == 200 then
        local dkjson = require("dkjson")
        return dkjson.decode(table.concat(response_body))
    end
    return nil
end

function M.send_message(text)
    local s = AL.state
    if not s.tg_enabled then return false end
    if os.clock() - s.tg_last_send_time < 1 then return false end

    local result = M.http_request("POST", "sendMessage", {
        chat_id = s.tg_chat_id,
        text = text,
        parse_mode = "HTML",
    })

    if result then
        s.tg_last_send_time = os.clock()
        return true
    end
    return false
end

function M.process_update(update)
    local s = AL.state
    if not update or not update.message then return end

    local msg = update.message
    local text = msg.text or ""
    local chat_id = tostring(msg.chat.id)

    if chat_id ~= s.tg_chat_id then return end

    if text:sub(1, 4) == "/say" then
        local args = text:sub(5):match("^%s*(.-)%s*$")
        if args and #args > 0 then
            sampSendChat(args)
            M.send_message("Выполнено в чате: " .. args)
        else
            M.send_message("Использование: /say <текст>")
        end
    elseif text == "/status" then
        local hp = 0
        local px, py, pz = 0, 0, 0
        if isSampAvailable() and doesCharExist(PLAYER_PED) then
            hp = getCharHealth(PLAYER_PED)
            px, py, pz = getCharCoordinates(PLAYER_PED)
        end
        local status = "Не в игре"
        if isSampAvailable() then
            status = string.format(
                "HP: %.0f\nX: %.1f Y: %.1f Z: %.1f\nAFK: %s\nSpawned: %s",
                hp, px, py, pz,
                s.mafk_active and "ВКЛ" or "ВЫКЛ",
                s.is_spawned and "Да" or "Нет"
            )
        end
        M.send_message(status)
    elseif text == "/afk" then
        s.mafk_active = not s.mafk_active
        local st = s.mafk_active and "включён" or "выключен"
        M.send_message("Anti-AFK: " .. st)
    elseif text == "/help" then
        M.send_message(
            "Команды бота:\n" ..
            "/say <текст> - отправить в чат игры\n" ..
            "/status - статус и позиция\n" ..
            "/afk - вкл/выкл anti-AFK\n" ..
            "/help - справка"
        )
    else
        M.send_message("Неизвестная команда: " .. text .. "\n/help - справка")
    end
end

function M.poll_thread()
    local s = AL.state
    AL.log("Telegram polling: старт (token=" .. (#s.tg_bot_token > 0 and "есть" or "пусто") .. ")")

    while true do
        wait(0)
        if s.tg_enabled and #s.tg_bot_token > 0 then
            local result = M.http_request("GET", "getUpdates?offset=" .. s.tg_last_update_id .. "&timeout=30")
            if result and result.ok then
                for _, update in ipairs(result.result) do
                    M.process_update(update)
                    s.tg_last_update_id = update.update_id + 1
                end
            else
                AL.log("Telegram: ошибка получения update: " .. tostring(result))
                wait(5000)
            end
        end
        wait(1000)
    end
end

function M.register_commands()
    sampRegisterChatCommand("tg", function(arg)
        local s = AL.state
        local token, chat_id = arg:match("^(%S+)%s+(%S+)$")
        if not token or not chat_id then
            AL.chat_msg("Использование: /tg <BOT_TOKEN> <CHAT_ID>")
            AL.chat_msg("Токен от @BotFather, chat_id от @userinfobot")
            return
        end
        s.tg_bot_token = token
        s.tg_chat_id = chat_id
        s.tg_enabled = true
        AL.chat_msg("{33FF33}Telegram подключён! Токен: " .. token:sub(1, 10) .. "...")
        M.send_message("Бот подключён к игре!")
    end)

    sampRegisterChatCommand("tgadmin", function(arg)
        local s = AL.state
        if not arg or #arg == 0 then
            if #s.admin_names == 0 then
                AL.chat_msg("Список пуст. Добавление: /tgadmin <ник>")
            else
                AL.chat_msg("Админы: " .. table.concat(s.admin_names, ", "))
            end
            return
        end
        local found = false
        for i, name in ipairs(s.admin_names) do
            if name:lower() == arg:lower() then
                table.remove(s.admin_names, i)
                AL.chat_msg("{FF3333}" .. arg .. "{FFFFFF} удалён из списка админов")
                found = true
                break
            end
        end
        if not found then
            table.insert(s.admin_names, arg)
            AL.chat_msg("{33FF33}" .. arg .. "{FFFFFF} добавлен в список админов")
        end
    end)

    sampRegisterChatCommand("tgstatus", function()
        local s = AL.state
        if s.tg_enabled and #s.tg_bot_token > 0 then
            AL.chat_msg("{33FF33}Telegram: подключён{FFFFFF} (токен: " .. s.tg_bot_token:sub(1, 10) .. ")")
            AL.chat_msg("Админы: " .. (#s.admin_names > 0 and table.concat(s.admin_names, ", ") or "нет"))
        else
            AL.chat_msg("{FF3333}Telegram: не подключён{FFFFFF}. Настройка /tg <token> <chat_id>")
        end
    end)

    sampRegisterChatCommand("tgtest", function()
        local s = AL.state
        if not s.tg_enabled or #s.tg_bot_token == 0 then
            AL.chat_msg("{FF3333}Telegram не подключён! /tg <token> <chat_id>")
            return
        end
        local ok = M.send_message("Тест от бота! Время: " .. os.date("%H:%M:%S"))
        if ok then
            AL.chat_msg("{33FF33}Тестовое сообщение отправлено в Telegram!")
        else
            AL.chat_msg("{FF3333}Ошибка отправки в Telegram. Проверьте токен и chat_id.")
        end
    end)
end

return M
