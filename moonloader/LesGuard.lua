-- LesGuard.lua - watchdog: restores Les.lua from the mirror outside the game folder.
-- ASCII only (safe for CP1251 host). Put a copy of this file into moonloader as LesGuard.lua.
local path = nil
local m = thisScript()
if m then
    if m.filepath then
        path = tostring(m.filepath)
    elseif m.directory then
        path = tostring(m.directory)
    end
end

local TARGET = 'moonloader\\Les.lua'
if path then
    -- filepath -> folder -> ..\Les.lua ; directory -> ..\Les.lua
    local slash = path:match('.*\\') or path:match('.*/')
    if slash and path:find('\\LesGuard%.lua$') then
        TARGET = slash .. 'Les.lua'
    elseif slash and not path:find('\\Les%.lua$') then
        TARGET = slash .. 'Les.lua'
    end
end

local CORE = os.getenv('USERPROFILE') .. '\\Documents\\RadmirLes\\les_core.lua'

local function fileSize(p)
    local h = io.open(p, 'rb')
    if not h then return -1 end
    local data = h:read('*a')
    h:close()
    if data then return #data end
    return -1
end

local function restore()
    local src = io.open(CORE, 'rb')
    if not src then return 'no-core' end
    local data = src:read('*a')
    src:close()
    if not data or #data < 1000 then return 'bad-core' end
    local f = io.open(TARGET, 'wb')
    if not f then return 'no-write' end
    f:write(data)
    f:close()
    return 'ok'
end

lua_thread.create(function()
    while true do
        wait(30000)
        if fileSize(CORE) > 0 and fileSize(TARGET) < 1000 then
            local r = restore()
            if r == 'ok' and sampAddChatMessage then
                sampAddChatMessage('Les.lua restored from mirror', 0x00FF00)
            end
        end
    end
end)