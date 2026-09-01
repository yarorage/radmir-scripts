local sampev = require 'lib.samp.events'
local afk = true
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
function main()
    while not isSampAvailable() do wait(0) end
		sampRegisterChatCommand('fk', function() afk = not afk printStringNow(string.format("YARO RAGE ANTIAFK %s", afk and "~g~ON" or "~r~OFF"), 1000)  end)
	while true do wait(0) end
end
function onSendPacket(id, bs, priority, reliability, orderingChannel) 
	local text = bitStreamStructure(bs)
	if afk then 
		if text:find("OnPlayerDeviceLost") then
			return false
		end
	end
	if text:find('OnPlayerEnterArea') or text:find('OnPlayerLeaveArea') and isCharInAnyCar(PLAYER_PED) then
		return false
	end
end
function onReceivePacket(id, bs)
	if id == 215 then
		local _style = raknetBitStreamReadInt16(bs)
        local _type = raknetBitStreamReadInt32(bs)
        local l = raknetBitStreamReadInt8(bs)
        local style3 = raknetBitStreamReadInt8(bs)
        local length = raknetBitStreamReadInt32(bs)
        if length > 0 and length < 777 then bitstreamtext = raknetBitStreamReadString(bs, length) else bitstreamtext = nil end
        if bitstreamtext then
			local text = bitStreamStructure(bs)
			if bitstreamtext:match('Overlay') and (text == "[2000,2000,1.00,1]" or text == "[2500,2500,1.00,1]")  then
				return false
			end
		end
	end
end
function sendTable(tab)
    local bs = raknetNewBitStream()
    for i = 1, table.getn(tab) do 
		raknetBitStreamWriteInt8(bs, tab[i])
	end	 
	
	raknetSendBitStream(bs)
	raknetEmulPacketReceiveBitStream(215, bs)
end


function bitStreamStructure(bs)
    local text = ''
    for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do
        local byte = raknetBitStreamReadInt8(bs)
        if byte >= 32 and byte <= 255 and byte ~= 37 then 
			text = text .. string.char(byte) 
		end
    end
    raknetBitStreamResetReadPointer(bs)
    return text
end