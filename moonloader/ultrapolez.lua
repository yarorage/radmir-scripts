-- ============================================================
-- ultrapolez.lua (декомпилированный через luajiteditor.com)
-- Восстановлено из защищённого LuaJIT 2.1 байткода (69 МБ).
-- 6 под-деревьев уровня 2 (связаны через upvalues).
-- Отобрана лучшая (оригинальная) версия декомпиляции для каждого.
-- =============================================================

-- ===== l2_0 обёртка (return uv0(arg0,arg1),uv1) =====
return uv0(arg0, arg1), uv1

-- ===== l2_1 обёртка шифрования =====
return uv1(uv0(uv1(arg0)):cipher(uv1(arg1)))

-- ===== l2_2 bit-библиотека + bytecode-compiler =====
if not bit then
	local slot0_a1001 = nil

	pcall((function ()
		slot0_a1001 = require("bit")
	end))

	bit = slot0_a1001
end

local slot0_a1998 = bit
local slot0_a1999 = slot0_a1998 or bit32 or (function ()
	local slot0_a1010 = {
		_TYPE = "module",
		_VERSION = "0.3.1.20120131",
		_NAME = "bit.numberlua"
	}
	local slot1_a1012 = math.floor
	local slot2_a1013 = 4294967296.0
	local slot3_a1014 = slot2_a1013 - 1

	local function slot4_a1030(arg0)
		local slot1_a1016 = {}
		local slot2_a1020 = setmetatable({}, slot1_a1016)

		function slot1_a1016.__index(arg0, arg1)
			local slot2_a1026 = arg0(arg1)
			slot2_a1020[arg1] = slot2_a1026

			return slot2_a1026
		end

		return slot2_a1020
	end

	local function slot5_a1070(arg0, arg1)
		return (function (arg0, arg1)
			local slot2_a1052 = 0
			local slot3_a1050 = 1

			while arg0 ~= 0 and arg1 ~= 0 do
				local slot4_a1042 = arg0 % arg1
				local slot5_a1045 = arg1 % arg1
				slot2_a1052 = slot2_a1052 + arg0[slot4_a1042][slot5_a1045] * slot3_a1050
				arg0 = (arg0 - slot4_a1042) / arg1
				arg1 = (arg1 - slot5_a1045) / arg1
				slot3_a1050 = slot3_a1050 * arg1
			end

			return slot2_a1052 + (arg0 + arg1) * slot3_a1050
		end)
	end

	local function slot6_a1101(arg0)
		local slot1_a1076 = slot5_a1070(arg0, 2)
		local slot3_a1099 = slot5_a1070
		local slot5_a1100 = arg0.n or 1

		return slot3_a1099(slot4_a1030((function (arg0)
			return slot4_a1030((function (arg0)
				return slot1_a1076(arg0, arg0)
			end))
		end)), 2^slot5_a1100)
	end

	function slot0_a1010.tobit(arg0)
		return arg0 % 4294967296.0
	end

	local slot8_a1106 = {
		[0] = {
			[0] = 0,
			1
		},
		{
			[0] = 1,
			0
		},
		n = 4
	}
	slot0_a1010.bxor = slot6_a1101(slot8_a1106)
	local slot7_a1110 = slot0_a1010.bxor

	function slot0_a1010.bnot(arg0)
		return slot3_a1014 - arg0
	end

	local slot8_a1116 = slot0_a1010.bnot

	function slot0_a1010.band(arg0, arg1)
		return (arg0 + arg1 - slot7_a1110(arg0, arg1)) / 2
	end

	local slot9_a1128 = slot0_a1010.band

	function slot0_a1010.bor(arg0, arg1)
		return slot3_a1014 - slot9_a1128(slot3_a1014 - arg0, slot3_a1014 - arg1)
	end

	local slot10_a1142 = slot0_a1010.bor
	local slot11_a1143 = nil
	local slot12_a1144 = nil

	function slot0_a1010.rshift(arg0, arg1)
		if arg1 < 0 then
			return slot11_a1143(arg0, -arg1)
		end

		return slot1_a1012(arg0 % 4294967296.0 / 2^arg1)
	end

	local slot12_a1163 = slot0_a1010.rshift

	function slot0_a1010.lshift(arg0, arg1)
		if arg1 < 0 then
			return slot12_a1163(arg0, -arg1)
		end

		return arg0 * 2^arg1 % 4294967296.0
	end

	local slot11_a1180 = slot0_a1010.lshift

	function slot0_a1010.tohex(arg0, arg1)
		arg1 = arg1 or 8
		local slot2_a1204 = nil

		if arg1 <= 0 then
			if arg1 == 0 then
				return ""
			end

			slot2_a1204 = true
			arg1 = -arg1
		end

		local slot3_a1207 = "%0"
		local slot5_a1209 = slot2_a1204 and "X" or "x"

		return (slot3_a1207 .. arg1 .. slot5_a1209):format(slot9_a1128(arg0, 16^arg1 - 1))
	end

	local slot13_a1216 = slot0_a1010.tohex

	function slot0_a1010.extract(arg0, arg1, arg2)
		arg2 = arg2 or 1

		return slot9_a1128(slot12_a1163(arg0, arg1), 2^arg2 - 1)
	end

	local slot14_a1235 = slot0_a1010.extract

	function slot0_a1010.replace(arg0, arg1, arg2, arg3)
		arg3 = arg3 or 1
		local slot4_a1244 = 2^arg3 - 1

		return slot9_a1128(arg0, slot8_a1116(slot11_a1180(slot4_a1244, arg2))) + slot11_a1180(slot9_a1128(arg1, slot4_a1244), arg2)
	end

	local slot15_a1271 = slot0_a1010.replace

	function slot0_a1010.bswap(arg0)
		local slot1_a1277 = slot9_a1128(arg0, 255)
		local slot0_a1283 = slot12_a1163(arg0, 8)
		local slot0_a1292 = slot12_a1163(slot0_a1283, 8)

		return slot11_a1180(slot11_a1180(slot11_a1180(slot1_a1277, 8) + slot9_a1128(slot0_a1283, 255), 8) + slot9_a1128(slot0_a1292, 255), 8) + slot9_a1128(slot12_a1163(slot0_a1292, 8), 255)
	end

	local slot16_a1321 = slot0_a1010.bswap

	function slot0_a1010.rrotate(arg0, arg1)
		local slot1_a1324 = arg1 % 32
		local slot2_a1331 = slot9_a1128(arg0, 2^slot1_a1324 - 1)

		return slot12_a1163(arg0, slot1_a1324) + slot11_a1180(slot2_a1331, 32 - slot1_a1324)
	end

	local slot17_a1344 = slot0_a1010.rrotate

	function slot0_a1010.lrotate(arg0, arg1)
		return slot17_a1344(arg0, -arg1)
	end

	local slot18_a1352 = slot0_a1010.lrotate
	slot0_a1010.rol = slot0_a1010.lrotate
	slot0_a1010.ror = slot0_a1010.rrotate

	function slot0_a1010.arshift(arg0, arg1)
		local slot2_a1373 = slot12_a1163(arg0, arg1)

		if arg0 >= 2147483648.0 then
			slot2_a1373 = slot2_a1373 + slot11_a1180(2^arg1 - 1, 32 - arg1)
		end

		return slot2_a1373
	end

	local slot19_a1375 = slot0_a1010.arshift

	function slot0_a1010.btest(arg0, arg1)
		return slot9_a1128(arg0, arg1) ~= 0
	end

	slot0_a1010.bit32 = {}

	local function slot20_a1393(arg0)
		return (-1 - arg0) % slot2_a1013
	end

	local slot21_a1394 = slot0_a1010.bit32
	slot21_a1394.bnot = slot20_a1393

	local function slot21_a1427(arg0, arg1, arg2, ...)
		local slot3_a1398 = nil

		if arg1 then
			local slot3_a1415 = slot7_a1110(arg0 % slot2_a1013, arg1 % slot2_a1013)

			if arg2 then
				slot3_a1415 = slot21_a1394(slot3_a1415, arg2, ...)
			end

			return slot3_a1415
		elseif arg0 then
			return arg0 % slot2_a1013
		else
			return 0
		end
	end

	local slot22_a1428 = slot0_a1010.bit32
	slot22_a1428.bxor = slot21_a1427

	local function slot22_a1464(arg0, arg1, arg2, ...)
		local slot3_a1432 = nil

		if arg1 then
			local slot0_a1436 = arg0 % slot2_a1013
			local slot1_a1439 = arg1 % slot2_a1013
			local slot3_a1451 = (slot0_a1436 + slot1_a1439 - slot7_a1110(slot0_a1436, slot1_a1439)) / 2

			if arg2 then
				slot3_a1451 = slot22_a1428(slot3_a1451, arg2, ...)
			end

			return slot3_a1451
		elseif arg0 then
			return arg0 % slot2_a1013
		else
			return slot3_a1014
		end
	end

	local slot23_a1465 = slot0_a1010.bit32
	slot23_a1465.band = slot22_a1464

	function slot0_a1010.bit32.bor(arg0, arg1, arg2, ...)
		local slot3_a1469 = nil

		if arg1 then
			local slot3_a1490 = slot3_a1014 - slot9_a1128(slot3_a1014 - arg0 % slot2_a1013, slot3_a1014 - arg1 % slot2_a1013)

			if arg2 then
				slot3_a1490 = slot23_a1465(slot3_a1490, arg2, ...)
			end

			return slot3_a1490
		elseif arg0 then
			return arg0 % slot2_a1013
		else
			return 0
		end
	end

	function slot0_a1010.bit32.btest(...)
		return slot22_a1464(...) ~= 0
	end

	function slot0_a1010.bit32.lrotate(arg0, arg1)
		return slot18_a1352(arg0 % slot2_a1013, arg1)
	end

	function slot0_a1010.bit32.rrotate(arg0, arg1)
		return slot17_a1344(arg0 % slot2_a1013, arg1)
	end

	function slot0_a1010.bit32.lshift(arg0, arg1)
		if arg1 > 31 or arg1 < -31 then
			return 0
		end

		return slot11_a1180(arg0 % slot2_a1013, arg1)
	end

	function slot0_a1010.bit32.rshift(arg0, arg1)
		if arg1 > 31 or arg1 < -31 then
			return 0
		end

		return slot12_a1163(arg0 % slot2_a1013, arg1)
	end

	function slot0_a1010.bit32.arshift(arg0, arg1)
		local slot0_a1599 = arg0 % slot2_a1013

		if arg1 >= 0 then
			if arg1 > 31 then
				return slot0_a1599 >= 2147483648.0 and slot3_a1014 or 0
			else
				local slot2_a1597 = slot12_a1163(slot0_a1599, arg1)

				if slot0_a1599 >= 2147483648.0 then
					slot2_a1597 = slot2_a1597 + slot11_a1180(2^arg1 - 1, 32 - arg1)
				end

				return slot2_a1597
			end
		else
			return slot11_a1180(slot0_a1599, -arg1)
		end
	end

	function slot0_a1010.bit32.extract(arg0, arg1, ...)
		local slot2_a1629 = ... or 1

		if arg1 < 0 or arg1 > 31 or slot2_a1629 < 0 or arg1 + slot2_a1629 > 32 then
			error("out of range")
		end

		return slot14_a1235(arg0 % slot2_a1013, arg1, ...)
	end

	function slot0_a1010.bit32.replace(arg0, arg1, arg2, ...)
		local slot3_a1661 = ... or 1

		if arg2 < 0 or arg2 > 31 or slot3_a1661 < 0 or arg2 + slot3_a1661 > 32 then
			error("out of range")
		end

		return slot15_a1271(arg0 % slot2_a1013, arg1 % slot2_a1013, arg2, ...)
	end

	slot0_a1010.bit = {
		tobit = (function (arg0)
			local slot0_a1673 = arg0 % slot2_a1013

			if slot0_a1673 >= 2147483648.0 then
				slot0_a1673 = slot0_a1673 - slot2_a1013
			end

			return slot0_a1673
		end)
	}
	local slot24_a1676 = slot0_a1010.bit.tobit

	function slot0_a1010.bit.tohex(arg0, ...)
		return slot13_a1216(arg0 % slot2_a1013, ...)
	end

	local slot25_a1685 = slot0_a1010.bit

	function slot25_a1685.bnot(arg0)
		return slot24_a1676(slot8_a1116(arg0 % slot2_a1013))
	end

	local function slot25_a1723(arg0, arg1, arg2, ...)
		if arg2 then
			return slot25_a1685(slot25_a1685(arg0, arg1), arg2, ...)
		elseif arg1 then
			return slot24_a1676(slot10_a1142(arg0 % slot2_a1013, arg1 % slot2_a1013))
		else
			return slot24_a1676(arg0)
		end
	end

	local slot26_a1724 = slot0_a1010.bit
	slot26_a1724.bor = slot25_a1723

	local function slot26_a1753(arg0, arg1, arg2, ...)
		if arg2 then
			return slot26_a1724(slot26_a1724(arg0, arg1), arg2, ...)
		elseif arg1 then
			return slot24_a1676(slot9_a1128(arg0 % slot2_a1013, arg1 % slot2_a1013))
		else
			return slot24_a1676(arg0)
		end
	end

	local slot27_a1754 = slot0_a1010.bit
	slot27_a1754.band = slot26_a1753

	function slot0_a1010.bit.bxor(arg0, arg1, arg2, ...)
		if arg2 then
			return slot27_a1754(slot27_a1754(arg0, arg1), arg2, ...)
		elseif arg1 then
			return slot24_a1676(slot7_a1110(arg0 % slot2_a1013, arg1 % slot2_a1013))
		else
			return slot24_a1676(arg0)
		end
	end

	function slot0_a1010.bit.lshift(arg0, arg1)
		return slot24_a1676(slot11_a1180(arg0 % slot2_a1013, arg1 % 32))
	end

	function slot0_a1010.bit.rshift(arg0, arg1)
		return slot24_a1676(slot12_a1163(arg0 % slot2_a1013, arg1 % 32))
	end

	function slot0_a1010.bit.arshift(arg0, arg1)
		return slot24_a1676(slot19_a1375(arg0 % slot2_a1013, arg1 % 32))
	end

	function slot0_a1010.bit.rol(arg0, arg1)
		return slot24_a1676(slot18_a1352(arg0 % slot2_a1013, arg1 % 32))
	end

	function slot0_a1010.bit.ror(arg0, arg1)
		return slot24_a1676(slot17_a1344(arg0 % slot2_a1013, arg1 % 32))
	end

	function slot0_a1010.bit.bswap(arg0)
		return slot24_a1676(slot16_a1321(arg0 % slot2_a1013))
	end

	return slot0_a1010
end)()
local slot1_a3611 = table.unpack
local slot1_a3612 = slot1_a3611 or unpack
local slot2_a1860 = nil
local slot3_a1861 = nil
local slot4_a1862 = nil
local slot5_a1863 = 50
local slot6_a1864 = {
	[0] = 3,
	13,
	23,
	0,
	2,
	4,
	7,
	9,
	12,
	14,
	17,
	5,
	1,
	6,
	10,
	16,
	20,
	26,
	30,
	36,
	19,
	22,
	18,
	24,
	27,
	29,
	33,
	32,
	11,
	15,
	21,
	8,
	34,
	28,
	37,
	25,
	31,
	35
}
local slot7_a1865 = {
	[0] = "ABC",
	"ABx",
	"ABC",
	"ABC",
	"ABC",
	"ABx",
	"ABC",
	"ABx",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"AsBx",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"ABC",
	"AsBx",
	"AsBx",
	"ABC",
	"ABC",
	"ABC",
	"ABx",
	"ABC"
}
local slot8_a1866 = {
	[0] = {
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgN",
		b = "OpArgK"
	},
	{
		c = "OpArgU",
		b = "OpArgU"
	},
	{
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgN",
		b = "OpArgU"
	},
	{
		c = "OpArgN",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgR"
	},
	{
		c = "OpArgN",
		b = "OpArgK"
	},
	{
		c = "OpArgN",
		b = "OpArgU"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgU",
		b = "OpArgU"
	},
	{
		c = "OpArgK",
		b = "OpArgR"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgR",
		b = "OpArgR"
	},
	{
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgK",
		b = "OpArgK"
	},
	{
		c = "OpArgU",
		b = "OpArgR"
	},
	{
		c = "OpArgU",
		b = "OpArgR"
	},
	{
		c = "OpArgU",
		b = "OpArgU"
	},
	{
		c = "OpArgU",
		b = "OpArgU"
	},
	{
		c = "OpArgN",
		b = "OpArgU"
	},
	{
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgN",
		b = "OpArgR"
	},
	{
		c = "OpArgU",
		b = "OpArgN"
	},
	{
		c = "OpArgU",
		b = "OpArgU"
	},
	{
		c = "OpArgN",
		b = "OpArgN"
	},
	{
		c = "OpArgN",
		b = "OpArgU"
	},
	{
		c = "OpArgN",
		b = "OpArgU"
	}
}

local function slot9_a1930(arg0, arg1, arg2, arg3)
	local slot4_a1929 = 0

	for slot8_a1918 = arg1, arg2, arg3 do
		slot4_a1929 = slot4_a1929 + string.byte(arg0, slot8_a1918, slot8_a1918) * 256^(slot8_a1918 - arg1)
	end

	return slot4_a1929
end

function slot0_a1999(arg0, arg1, arg2, arg3)
	local slot4_a1992 = -1^slot0_a1998.rshift(arg3, 7)
	local slot5_a1988 = slot0_a1998.rshift(arg2, 7) + slot0_a1998.lshift(slot0_a1998.band(arg3, 127), 1)
	local slot6_a1981 = arg0 + slot0_a1998.lshift(arg1, 8) + slot0_a1998.lshift(slot0_a1998.band(arg2, 127), 16)
	local slot7_a1994 = 1

	if slot5_a1988 == 0 then
		if slot6_a1981 == 0 then
			return slot4_a1992 * 0
		else
			slot7_a1994 = 0
			slot5_a1988 = 1
		end
	elseif slot5_a1988 == 127 then
		if slot6_a1981 == 0 then
			return slot4_a1992 * 1 / 0
		else
			return slot4_a1992 * 0 / 0
		end
	end

	return slot4_a1992 * 2^(slot5_a1988 - 127) * (1 + slot7_a1994 / 8388608)
end

local function slot11_a2073(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	local slot8_a2066 = -1^slot0_a1998.rshift(arg7, 7)
	local slot9_a2062 = slot0_a1998.lshift(slot0_a1998.band(arg7, 127), 4) + slot0_a1998.rshift(arg6, 4)
	local slot11_a2070 = 1
	local slot10_a2055 = slot0_a1998.band(arg6, 15) * 281474976710656.0 + arg5 * 1099511627776.0 + arg4 * 4294967296.0 + arg3 * 16777216 + arg2 * 65536 + arg1 * 256 + arg0

	if slot9_a2062 == 0 then
		if slot10_a2055 == 0 then
			return slot8_a2066 * 0
		else
			slot11_a2070 = 0
			slot9_a2062 = 1
		end
	elseif slot9_a2062 == 2047 then
		if slot10_a2055 == 0 then
			return slot8_a2066 * 1 / 0
		else
			return slot8_a2066 * 0 / 0
		end
	end

	return slot8_a2066 * 2^(slot9_a2062 - 1023) * (slot11_a2070 + slot10_a2055 / 4503599627370496.0)
end

local function slot12_a2083(arg0, arg1, arg2)
	return slot9_a1930(arg0, arg1, arg2 - 1, 1)
end

local function slot13_a2093(arg0, arg1, arg2)
	return slot9_a1930(arg0, arg2 - 1, arg1, -1)
end

local function slot15_a2121(arg0, arg1)
	local slot2_a2111, slot3_a2112, slot4_a2113, slot5_a2114 = string.byte(arg0, arg1, arg1 + 3)

	return slot0_a1999(slot5_a2114, slot4_a2113, slot3_a2112, slot2_a2111)
end

local function slot16_a2131(arg0, arg1)
	return slot11_a2073(string.byte(arg0, arg1, arg1 + 7))
end

local function slot17_a2157(arg0, arg1)
	local slot2_a2139, slot3_a2140, slot4_a2141, slot5_a2142, slot6_a2143, slot7_a2144, slot8_a2145, slot9_a2146 = string.byte(arg0, arg1, arg1 + 7)

	return slot11_a2073(slot9_a2146, slot8_a2145, slot7_a2144, slot6_a2143, slot5_a2142, slot4_a2141, slot3_a2140, slot2_a2139)
end

local slot18_a2158 = {}
local slot19_a2159 = {}

function slot19_a2159.little(arg0, arg1)
	return slot0_a1999(string.byte(arg0, arg1, arg1 + 3))
end

slot19_a2159.big = slot15_a2121
slot18_a2158[4] = slot19_a2159
local slot19_a2160 = {
	little = slot16_a2131,
	big = slot17_a2157
}
slot18_a2158[8] = slot19_a2160

local function slot19_a2170(arg0)
	local slot1_a2162 = arg0.index
	local slot2_a2168 = string.byte(arg0.source, slot1_a2162, slot1_a2162)
	arg0.index = slot1_a2162 + 1

	return slot2_a2168
end

local function slot20_a2181(arg0, arg1)
	local slot2_a2174 = arg0.index + arg1
	local slot3_a2180 = string.sub(arg0.source, arg0.index, slot2_a2174 - 1)
	arg0.index = slot2_a2174

	return slot3_a2180
end

local function slot21_a2201(arg0)
	local slot1_a2193 = arg0:s_szt()
	local slot2_a2200 = nil

	if slot1_a2193 ~= 0 then
		slot2_a2200 = string.sub(slot20_a2181(arg0, slot1_a2193), 1, -2)
	end

	return slot2_a2200
end

local function slot22_a2216(arg0, arg1)
	return (function (arg0)
		local slot1_a2208 = arg0.index + arg0
		local slot2_a2214 = arg1(arg0.source, arg0.index, slot1_a2208)
		arg0.index = slot1_a2208

		return slot2_a2214
	end)
end

local function slot23_a2230(arg0, arg1)
	return (function (arg0)
		local slot1_a2224 = arg1(arg0.source, arg0.index)
		arg0.index = arg0.index + arg0

		return slot1_a2224
	end)
end

local function slot24_a2342(arg0)
	local slot2_a2339 = {}

	for slot6_a2340 = 1, arg0:s_int() do
		local slot7_a2330 = arg0:s_ins()
		local slot8_a2249 = slot0_a1998.band(slot7_a2330, 63)
		local slot9_a2325 = slot7_a1865[slot8_a2249]
		local slot10_a2298 = slot8_a1866[slot8_a2249]
		local slot11_a2338 = {
			value = slot7_a2330,
			op = slot6_a1864[slot8_a2249],
			A = slot0_a1998.band(slot0_a1998.rshift(slot7_a2330, 6), 255)
		}

		if slot9_a2325 == "ABC" then
			slot11_a2338.B = slot0_a1998.band(slot0_a1998.rshift(slot7_a2330, 23), 511)
			slot11_a2338.C = slot0_a1998.band(slot0_a1998.rshift(slot7_a2330, 14), 511)
			slot11_a2338.is_KB = slot10_a2298.b == "OpArgK" and slot11_a2338.B > 255
			slot11_a2338.is_KC = slot10_a2298.c == "OpArgK" and slot11_a2338.C > 255
		elseif slot9_a2325 == "ABx" then
			slot11_a2338.Bx = slot0_a1998.band(slot0_a1998.rshift(slot7_a2330, 14), 262143)
			slot11_a2338.is_K = slot10_a2298.b == "OpArgK"
		elseif slot9_a2325 == "AsBx" then
			slot11_a2338.sBx = slot0_a1998.band(slot0_a1998.rshift(slot7_a2330, 14), 262143) - 131071
		end

		slot2_a2339[slot6_a2340] = slot11_a2338
	end

	return slot2_a2339
end

local function slot25_a2381(arg0)
	local slot2_a2378 = {}

	for slot6_a2379 = 1, arg0:s_int() do
		local slot7_a2370 = slot19_a2170(arg0)
		local slot8_a2377 = nil

		if slot7_a2370 == 1 then
			slot8_a2377 = slot19_a2170(arg0) ~= 0
		elseif slot7_a2370 == 3 then
			slot8_a2377 = arg0:s_num()
		elseif slot7_a2370 == 4 then
			slot8_a2377 = slot21_a2201(arg0)
		end

		slot2_a2378[slot6_a2379] = slot8_a2377
	end

	return slot2_a2378
end

local function slot26_a2402(arg0, arg1)
	local slot3_a2401 = {}

	for slot7_a2400 = 1, arg0:s_int() do
		slot3_a2401[slot7_a2400] = slot4_a1862(arg0, arg1)
	end

	return slot3_a2401
end

local function slot27_a2419(arg0)
	local slot2_a2418 = {}

	for slot6_a2417 = 1, arg0:s_int() do
		slot2_a2418[slot6_a2417] = arg0:s_int()
	end

	return slot2_a2418
end

local function slot28_a2444(arg0)
	local slot2_a2443 = {}

	for slot6_a2442 = 1, arg0:s_int() do
		local slot7_a2429 = {
			varname = slot21_a2201(arg0),
			startpc = arg0:s_int(),
			endpc = arg0:s_int()
		}
		slot2_a2443[slot6_a2442] = slot7_a2429
	end

	return slot2_a2443
end

local function slot29_a2462(arg0)
	local slot2_a2461 = {}

	for slot6_a2460 = 1, arg0:s_int() do
		slot2_a2461[slot6_a2460] = slot21_a2201(arg0)
	end

	return slot2_a2461
end

local function slot4_a2545(arg0, arg1)
	local slot2_a2538 = {}
	local slot3_a2539 = slot21_a2201(arg0) or arg1
	slot2_a2538.source = slot3_a2539

	arg0:s_int()
	arg0:s_int()

	slot2_a2538.numupvals = slot19_a2170(arg0)
	slot2_a2538.numparams = slot19_a2170(arg0)

	slot19_a2170(arg0)
	slot19_a2170(arg0)

	slot2_a2538.code = slot24_a2342(arg0)
	slot2_a2538.const = slot25_a2381(arg0)
	slot2_a2538.subs = slot26_a2402(arg0, slot3_a2539)
	slot2_a2538.lines = slot27_a2419(arg0)

	slot28_a2444(arg0)
	slot29_a2462(arg0)

	for slot7_a2518, slot8_a2540 in ipairs(slot2_a2538.code) do
		if slot8_a2540.is_K then
			slot8_a2540.const = slot2_a2538.const[slot8_a2540.Bx + 1]
		else
			if slot8_a2540.is_KB then
				slot8_a2540.const_B = slot2_a2538.const[slot8_a2540.B - 255]
			end

			if slot8_a2540.is_KC then
				slot8_a2540.const_C = slot2_a2538.const[slot8_a2540.C - 255]
			end
		end
	end

	return slot2_a2538
end

local function slot2_a2675(arg0)
	local slot1_a2547 = nil
	local slot2_a2548 = nil
	local slot3_a2549 = nil
	local slot4_a2550 = nil
	local slot5_a2551 = nil
	local slot6_a2552 = nil
	local slot7_a2553 = nil
	local slot8_a2672 = {
		index = 1,
		source = arg0
	}

	assert(slot20_a2181(slot8_a2672, 4) == "Lua", "invalid Lua signature")
	assert(slot19_a2170(slot8_a2672) == 81, "invalid Lua version")
	assert(slot19_a2170(slot8_a2672) == 0, "invalid Lua format")

	local slot2_a2658 = slot19_a2170(slot8_a2672) ~= 0
	local slot6_a2654 = slot19_a2170(slot8_a2672)
	local slot7_a2640 = slot19_a2170(slot8_a2672) ~= 0
	local slot1_a2644 = slot2_a2658 and slot12_a2083 or slot13_a2093
	slot8_a2672.s_int = slot22_a2216(slot19_a2170(slot8_a2672), slot1_a2644)
	slot8_a2672.s_szt = slot22_a2216(slot19_a2170(slot8_a2672), slot1_a2644)
	slot8_a2672.s_ins = slot22_a2216(slot19_a2170(slot8_a2672), slot1_a2644)

	if slot7_a2640 then
		slot8_a2672.s_num = slot22_a2216(slot6_a2654, slot1_a2644)
	elseif slot18_a2158[slot6_a2654] then
		slot8_a2672.s_num = slot23_a2230(slot6_a2654, slot18_a2158[slot6_a2654][slot2_a2658 and "little" or "big"])
	else
		error("unsupported float size")
	end

	return slot4_a2545(slot8_a2672, "@virtual")
end

local function slot30_a2696(arg0, arg1)
	for slot5_a2695, slot6_a2688 in pairs(arg0) do
		if arg1 <= slot6_a2688.index then
			slot6_a2688.value = slot6_a2688.store[slot6_a2688.index]
			slot6_a2688.store = slot6_a2688
			slot6_a2688.index = "value"
			arg0[slot5_a2695] = nil
		end
	end
end

local function slot31_a2707(arg0, arg1, arg2)
	local slot3_a2706 = arg0[arg1]

	if not slot3_a2706 then
		local slot4_a2701 = {
			index = arg1,
			store = arg2
		}
		slot3_a2706 = slot4_a2701
		arg0[arg1] = slot3_a2706
	end

	return slot3_a2706
end

local function slot32_a2712(...)
	local slot0_a2710 = select("#", ...)
	local slot1_a2711 = {
		...
	}

	return slot0_a2710, slot1_a2711
end

local function slot33_a2753(arg0, arg1)
	local slot2_a2741 = arg0.source
	local slot3_a2743 = arg0.lines[arg0.pc - 1]
	local slot4_a2745, slot5_a2747, slot6_a2749 = string.match(arg1, "^(.-):(%d+):%s+(.+)")
	local slot7_a2739 = "%s:%i: [%s:%i] %s"
	local slot3_a2744 = slot3_a2743 or "0"
	slot4_a2745 = slot4_a2745 or "?"
	slot5_a2747 = slot5_a2747 or "0"
	slot6_a2749 = slot6_a2749 or arg1

	error(string.format(slot7_a2739, slot2_a2741, slot3_a2744, slot4_a2745, slot5_a2747, slot6_a2749), 0)
end

function slot1_a3612(arg0)
	local slot1_a2764 = arg0.code
	local slot2_a3370 = arg0.subs
	local slot3_a2847 = arg0.env
	local slot4_a2961 = arg0.upvals
	local slot5_a3474 = arg0.varargs
	local slot6_a3522 = -1
	local slot7_a3394 = {}
	local slot8_a3105 = arg0.stack
	local slot9_a3284 = arg0.pc

	while true do
		local slot10_a3102 = slot1_a2764[slot9_a3284]
		local slot11_a3514 = slot10_a3102.op
		slot9_a3284 = slot9_a3284 + 1

		if slot11_a3514 < 18 then
			if slot11_a3514 < 8 then
				if slot11_a3514 < 3 then
					if slot11_a3514 < 1 then
						for slot15_a2783 = slot10_a3102.A, slot10_a3102.B do
							slot8_a3105[slot15_a2783] = nil
						end
					elseif slot11_a3514 > 1 then
						local slot12_a2789 = slot4_a2961[slot10_a3102.B]
						slot8_a3105[slot10_a3102.A] = slot12_a2789.store[slot12_a2789.index]
					else
						local slot12_a2795 = nil
						local slot13_a2796 = nil
						slot8_a3105[slot10_a3102.A] = ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) + ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C])
					end
				elseif slot11_a3514 > 3 then
					if slot11_a3514 < 6 then
						if slot11_a3514 > 4 then
							local slot12_a2836 = slot10_a3102.A
							local slot13_a2839 = slot10_a3102.B
							local slot14_a2828 = nil
							local slot14_a2842 = (not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C]
							slot8_a3105[slot12_a2836 + 1] = slot8_a3105[slot13_a2839]
							slot8_a3105[slot12_a2836] = slot8_a3105[slot13_a2839][slot14_a2842]
						else
							slot8_a3105[slot10_a3102.A] = slot3_a2847[slot10_a3102.const]
						end
					elseif slot11_a3514 > 6 then
						local slot12_a2852 = nil
						local slot12_a2866 = (not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C]
						slot8_a3105[slot10_a3102.A] = slot8_a3105[slot10_a3102.B][slot12_a2866]
					else
						local slot12_a2868 = nil
						local slot13_a2869 = nil
						slot8_a3105[slot10_a3102.A] = ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) - ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C])
					end
				else
					slot8_a3105[slot10_a3102.A] = slot8_a3105[slot10_a3102.B]
				end
			elseif slot11_a3514 > 8 then
				if slot11_a3514 < 13 then
					if slot11_a3514 < 10 then
						slot3_a2847[slot10_a3102.const] = slot8_a3105[slot10_a3102.A]
					elseif slot11_a3514 > 10 then
						if slot11_a3514 < 12 then
							local slot12_a2952 = slot10_a3102.A
							local slot13_a2923 = slot10_a3102.B
							local slot14_a2945 = slot10_a3102.C
							local slot15_a2917 = nil
							local slot16_a2918 = nil
							local slot17_a2919 = nil
							local slot15_a2934 = slot13_a2923 == 0 and slot6_a3522 - slot12_a2952 or slot13_a2923 - 1
							local slot16_a2948, slot19_a2937 = slot32_a2712(slot8_a3105[slot12_a2952](slot1_a3611(slot8_a3105, slot12_a2952 + 1, slot12_a2952 + slot15_a2934)))

							if slot14_a2945 == 0 then
								slot6_a3522 = slot12_a2952 + slot16_a2948 - 1
							else
								slot16_a2948 = slot14_a2945 - 1
							end

							for slot21_a2953 = 1, slot16_a2948 do
								slot8_a3105[slot12_a2952 + slot21_a2953 - 1] = slot19_a2937[slot21_a2953]
							end
						else
							local slot12_a2962 = slot4_a2961[slot10_a3102.B]
							slot12_a2962.store[slot12_a2962.index] = slot8_a3105[slot10_a3102.A]
						end
					else
						local slot12_a2968 = nil
						local slot13_a2969 = nil
						slot8_a3105[slot10_a3102.A] = ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) * ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C])
					end
				elseif slot11_a3514 > 13 then
					if slot11_a3514 < 16 then
						if slot11_a3514 > 14 then
							local slot12_a3014 = slot10_a3102.A
							local slot13_a3005 = slot10_a3102.B
							local slot14_a3001 = nil
							local slot14_a3019 = slot13_a3005 == 0 and slot6_a3522 - slot12_a3014 or slot13_a3005 - 1

							slot30_a2696(slot7_a3394, 0)

							return slot32_a2712(slot8_a3105[slot12_a3014](slot1_a3611(slot8_a3105, slot12_a3014 + 1, slot12_a3014 + slot14_a3019)))
						else
							local slot12_a3021 = nil
							local slot13_a3022 = nil
							local slot12_a3044 = (not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]
							slot8_a3105[slot10_a3102.A][slot12_a3044] = (not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C]
						end
					elseif slot11_a3514 > 16 then
						slot8_a3105[slot10_a3102.A] = {}
					else
						local slot12_a3051 = nil
						local slot13_a3052 = nil
						slot8_a3105[slot10_a3102.A] = ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) / ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C])
					end
				else
					slot8_a3105[slot10_a3102.A] = slot10_a3102.const
				end
			else
				local slot12_a3080 = slot10_a3102.A
				local slot13_a3083 = slot8_a3105[slot12_a3080 + 2]
				local slot14_a3104 = slot8_a3105[slot12_a3080] + slot13_a3083
				local slot15_a3097 = slot8_a3105[slot12_a3080 + 1]
				local slot16_a3088 = nil

				if slot13_a3083 == math.abs(slot13_a3083) and slot14_a3104 <= slot15_a3097 or slot15_a3097 <= slot14_a3104 then
					slot8_a3105[slot10_a3102.A] = slot14_a3104
					slot8_a3105[slot10_a3102.A + 3] = slot14_a3104
					slot9_a3284 = slot9_a3284 + slot10_a3102.sBx
				end
			end
		elseif slot11_a3514 > 18 then
			if slot11_a3514 < 28 then
				if slot11_a3514 < 23 then
					if slot11_a3514 < 20 then
						slot8_a3105[slot10_a3102.A] = #slot8_a3105[slot10_a3102.B]
					elseif slot11_a3514 > 20 then
						if slot11_a3514 < 22 then
							local slot12_a3145 = slot10_a3102.A
							local slot13_a3138 = slot10_a3102.B
							local slot14_a3158 = {}
							local slot15_a3133 = nil
							local slot15_a3156 = slot13_a3138 == 0 and slot6_a3522 - slot12_a3145 + 1 or slot13_a3138 - 1

							for slot19_a3146 = 1, slot15_a3156 do
								slot14_a3158[slot19_a3146] = slot8_a3105[slot12_a3145 + slot19_a3146 - 1]
							end

							slot30_a2696(slot7_a3394, 0)

							return slot15_a3156, slot14_a3158
						else
							local slot12_a3177 = slot8_a3105[slot10_a3102.B]

							for slot16_a3172 = slot10_a3102.B + 1, slot10_a3102.C do
								slot12_a3177 = slot12_a3177 .. slot8_a3105[slot16_a3172]
							end

							slot8_a3105[slot10_a3102.A] = slot12_a3177
						end
					else
						local slot12_a3179 = nil
						local slot13_a3180 = nil
						slot8_a3105[slot10_a3102.A] = ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) % ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C])
					end
				elseif slot11_a3514 > 23 then
					if slot11_a3514 < 26 then
						if slot11_a3514 > 24 then
							slot30_a2696(slot7_a3394, slot10_a3102.A)
						else
							local slot12_a3214 = nil
							local slot13_a3215 = nil

							if ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) == ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C]) == (slot10_a3102.A ~= 0) then
								slot9_a3284 = slot9_a3284 + slot1_a2764[slot9_a3284].sBx
							end

							slot9_a3284 = slot9_a3284 + 1
						end
					elseif slot11_a3514 > 26 then
						local slot12_a3251 = nil
						local slot13_a3252 = nil

						if ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) < ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C]) == (slot10_a3102.A ~= 0) then
							slot9_a3284 = slot9_a3284 + slot1_a2764[slot9_a3284].sBx
						end

						slot9_a3284 = slot9_a3284 + 1
					else
						local slot12_a3286 = nil
						local slot13_a3287 = nil
						slot8_a3105[slot10_a3102.A] = ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B])^((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C])
					end
				else
					slot8_a3105[slot10_a3102.A] = slot10_a3102.B ~= 0

					if slot10_a3102.C ~= 0 then
						slot9_a3284 = slot9_a3284 + 1
					end
				end
			elseif slot11_a3514 > 28 then
				if slot11_a3514 < 33 then
					if slot11_a3514 < 30 then
						local slot12_a3328 = nil
						local slot13_a3329 = nil

						if ((not slot10_a3102.is_KB or slot10_a3102.const_B) and slot8_a3105[slot10_a3102.B]) <= ((not slot10_a3102.is_KC or slot10_a3102.const_C) and slot8_a3105[slot10_a3102.C]) == (slot10_a3102.A ~= 0) then
							slot9_a3284 = slot9_a3284 + slot1_a2764[slot9_a3284].sBx
						end

						slot9_a3284 = slot9_a3284 + 1
					elseif slot11_a3514 > 30 then
						if slot11_a3514 < 32 then
							local slot12_a3420 = slot2_a3370[slot10_a3102.Bx + 1]
							local slot13_a3414 = slot12_a3420.numupvals
							local slot14_a3424 = nil

							if slot13_a3414 ~= 0 then
								slot14_a3424 = {}

								for slot18_a3390 = 1, slot13_a3414 do
									local slot19_a3408 = slot1_a2764[slot9_a3284 + slot18_a3390 - 1]

									if slot19_a3408.op == slot6_a1864[0] then
										slot14_a3424[slot18_a3390 - 1] = slot31_a2707(slot7_a3394, slot19_a3408.B, slot8_a3105)
									elseif slot19_a3408.op == slot6_a1864[4] then
										slot14_a3424[slot18_a3390 - 1] = slot4_a2961[slot19_a3408.B]
									end
								end

								slot9_a3284 = slot9_a3284 + slot13_a3414
							end

							slot8_a3105[slot10_a3102.A] = slot3_a1861(slot12_a3420, slot3_a2847, slot14_a3424)
						else
							local slot12_a3444 = slot10_a3102.A
							local slot13_a3442 = slot10_a3102.B

							if not slot8_a3105[slot13_a3442] == (slot10_a3102.C ~= 0) then
								slot9_a3284 = slot9_a3284 + 1
							else
								slot8_a3105[slot12_a3444] = slot8_a3105[slot13_a3442]
							end
						end
					else
						slot8_a3105[slot10_a3102.A] = -slot8_a3105[slot10_a3102.B]
					end
				elseif slot11_a3514 > 33 then
					if slot11_a3514 < 36 then
						if slot11_a3514 > 34 then
							local slot12_a3470 = slot10_a3102.A
							local slot13_a3466 = slot10_a3102.B

							if slot13_a3466 == 0 then
								slot13_a3466 = slot5_a3474.size
								slot6_a3522 = slot12_a3470 + slot13_a3466 - 1
							end

							for slot17_a3471 = 1, slot13_a3466 do
								slot8_a3105[slot12_a3470 + slot17_a3471 - 1] = slot5_a3474.list[slot17_a3471]
							end
						else
							local slot12_a3479 = slot10_a3102.A
							local slot13_a3480 = nil
							local slot14_a3481 = nil
							local slot15_a3482 = nil
							local slot15_a3506 = assert(tonumber(slot8_a3105[slot12_a3479 + 2]), "`for` step must be a number")
							slot8_a3105[slot12_a3479] = assert(tonumber(slot8_a3105[slot12_a3479]), "`for` initial value must be a number") - slot15_a3506
							slot8_a3105[slot12_a3479 + 1] = assert(tonumber(slot8_a3105[slot12_a3479 + 1]), "`for` limit must be a number")
							slot8_a3105[slot12_a3479 + 2] = slot15_a3506
							slot9_a3284 = slot9_a3284 + slot10_a3102.sBx
						end
					elseif slot11_a3514 > 36 then
						local slot12_a3544 = slot10_a3102.A
						local slot13_a3531 = slot10_a3102.C
						local slot14_a3537 = slot10_a3102.B
						local slot15_a3548 = slot8_a3105[slot12_a3544]
						local slot16_a3521 = nil

						if slot14_a3537 == 0 then
							slot14_a3537 = slot6_a3522 - slot12_a3544
						end

						if slot13_a3531 == 0 then
							slot13_a3531 = slot10_a3102[slot9_a3284].value
							slot9_a3284 = slot9_a3284 + 1
						end

						local slot16_a3542 = (slot13_a3531 - 1) * slot5_a1863

						for slot20_a3541 = 1, slot14_a3537 do
							slot15_a3548[slot20_a3541 + slot16_a3542] = slot8_a3105[slot12_a3544 + slot20_a3541]
						end
					else
						slot8_a3105[slot10_a3102.A] = not slot8_a3105[slot10_a3102.B]
					end
				elseif not slot8_a3105[slot10_a3102.A] == (slot10_a3102.C ~= 0) then
					slot9_a3284 = slot9_a3284 + 1
				end
			else
				local slot12_a3598 = slot10_a3102.A
				local slot13_a3570 = slot8_a3105[slot12_a3598]
				local slot14_a3572 = slot8_a3105[slot12_a3598 + 1]
				local slot15_a3574 = slot8_a3105[slot12_a3598 + 2]
				local slot16_a3601 = slot12_a3598 + 3
				local slot17_a3576 = nil
				slot8_a3105[slot16_a3601 + 2] = slot15_a3574
				slot8_a3105[slot16_a3601 + 1] = slot14_a3572
				slot8_a3105[slot16_a3601] = slot13_a3570
				local slot18_a3579 = {
					slot13_a3570(slot14_a3572, slot15_a3574)
				}

				for slot21_a3589 = 1, slot10_a3102.C do
					slot8_a3105[slot16_a3601 + slot21_a3589 - 1] = slot18_a3579[slot21_a3589]
				end

				if slot8_a3105[slot16_a3601] ~= nil then
					slot8_a3105[slot12_a3598 + 2] = slot8_a3105[slot16_a3601]
				else
					slot9_a3284 = slot9_a3284 + 1
				end
			end
		else
			slot9_a3284 = slot9_a3284 + slot10_a3102.sBx
		end

		arg0.pc = slot9_a3284
	end
end

local function slot3_a3703(arg0, arg1, arg2)
	local slot3_a3616 = arg0.code
	local slot4_a3617 = arg0.subs
	local slot5_a3618 = arg0.lines
	local slot6_a3619 = arg0.source
	local slot7_a3620 = arg0.numparams

	return (function (...)
		local slot0_a3673 = {}
		local slot1_a3659 = {}
		local slot2_a3660 = 0
		local slot3_a3645, slot4_a3654 = slot32_a2712(...)
		local slot5_a3628 = nil
		local slot6_a3629 = nil
		local slot7_a3630 = nil
		local slot8_a3631 = nil

		for slot12_a3637 = 1, slot7_a3620 do
			slot0_a3673[slot12_a3637 - 1] = slot4_a3654[slot12_a3637]
		end

		if slot7_a3620 < slot3_a3645 then
			slot2_a3660 = slot3_a3645 - slot7_a3620

			for slot12_a3652 = 1, slot2_a3660 do
				slot1_a3659[slot12_a3652] = slot4_a3654[slot7_a3620 + slot12_a3652]
			end
		end

		local slot9_a3657 = {
			pc = 1
		}
		local slot10_a3658 = {
			list = slot1_a3659,
			size = slot2_a3660
		}
		slot9_a3657.varargs = slot10_a3658
		slot9_a3657.code = slot3_a3616
		slot9_a3657.subs = slot4_a3617
		slot9_a3657.lines = slot5_a3618
		slot9_a3657.source = slot6_a3619
		slot9_a3657.env = arg1
		slot9_a3657.upvals = arg2
		slot9_a3657.stack = slot0_a3673
		local slot5_a3694 = slot9_a3657
		local slot9_a3679, slot7_a3696, slot11_a3681 = pcall(slot1_a3612, slot5_a3694, ...)

		if slot9_a3679 then
			return slot1_a3611(slot11_a3681, 1, slot7_a3696)
		else
			slot33_a2753(slot5_a3694, slot7_a3696)
		end
	end)
end

return (function (arg0, arg1)
	return slot3_a3703(slot2_a2675(arg0), arg1 or uv2(0))
end)

-- ===== l2_3 return _ENV =====
return _ENV

-- ===== l2_4 RC4 =====
local slot1_a1061 = (function (arg0)
	local slot1_a1029 = {}

	for slot5_a1008 = 0, 255 do
		slot1_a1029[slot5_a1008] = {}
	end

	slot1_a1029[0][0] = arg0[1] * 255
	local slot2_a1036 = 1

	for slot6_a1018 = 0, 7 do
		for slot10_a1030 = 0, slot2_a1036 - 1 do
			for slot14_a1032 = 0, slot2_a1036 - 1 do
				local slot15_a1038 = slot1_a1029[slot10_a1030][slot14_a1032] - arg0[1] * slot2_a1036
				slot1_a1029[slot10_a1030][slot14_a1032 + slot2_a1036] = slot15_a1038 + arg0[2] * slot2_a1036
				slot1_a1029[slot10_a1030 + slot2_a1036][slot14_a1032] = slot15_a1038 + arg0[3] * slot2_a1036
				slot1_a1029[slot10_a1030 + slot2_a1036][slot14_a1032 + slot2_a1036] = slot15_a1038 + arg0[4] * slot2_a1036
			end
		end

		slot2_a1036 = slot2_a1036 * 2
	end

	return slot1_a1029
end)({
	0,
	1,
	1,
	0
})

local function slot2_a1102(arg0, arg1)
	local slot2_a1077 = arg0.S
	local slot3_a1094 = arg0.i
	local slot4_a1096 = arg0.j
	local slot5_a1100 = {}
	local slot6_a1084 = string.char

	for slot10_a1093 = 1, arg1 do
		slot3_a1094 = (slot3_a1094 + 1) % 256
		slot4_a1096 = (slot4_a1096 + slot2_a1077[slot3_a1094]) % 256
		local slot11_a1082 = slot2_a1077[slot4_a1096]
		slot2_a1077[slot4_a1096] = slot2_a1077[slot3_a1094]
		slot2_a1077[slot3_a1094] = slot11_a1082
		slot5_a1100[slot10_a1093] = slot6_a1084(slot2_a1077[(slot2_a1077[slot3_a1094] + slot2_a1077[slot4_a1096]) % 256])
	end

	arg0.j = slot4_a1096
	arg0.i = slot3_a1094

	return table.concat(slot5_a1100)
end

local function slot3_a1143(arg0, arg1)
	local slot2_a1132 = slot2_a1102(arg0, #arg1)
	local slot3_a1138 = {}
	local slot4_a1123 = string.byte
	local slot5_a1119 = string.char

	for slot9_a1127 = 1, #arg1 do
		slot3_a1138[slot9_a1127] = slot5_a1119(slot1_a1061[slot4_a1123(arg1, slot9_a1127)][slot4_a1123(slot2_a1132, slot9_a1127)])
	end

	return table.concat(slot3_a1138)
end

local function slot4_a1172(arg0, arg1)
	local slot2_a1155 = arg0.S
	local slot3_a1158 = 0
	local slot4_a1164 = #arg1
	local slot5_a1160 = string.byte

	for slot9_a1156 = 0, 255 do
		slot3_a1158 = (slot3_a1158 + slot2_a1155[slot9_a1156] + slot5_a1160(arg1, slot9_a1156 % slot4_a1164 + 1)) % 256
		local slot10_a1170 = slot2_a1155[slot3_a1158]
		slot2_a1155[slot3_a1158] = slot2_a1155[slot9_a1156]
		slot2_a1155[slot9_a1156] = slot10_a1170
	end
end

function new(arg0)
	local slot1_a1187 = {}
	local slot2_a1194 = {
		j = 0,
		i = 0,
		S = slot1_a1187,
		generate = slot2_a1102,
		cipher = slot3_a1143,
		schedule = slot4_a1172
	}

	for slot6_a1186 = 0, 255 do
		slot1_a1187[slot6_a1186] = slot6_a1186
	end

	if arg0 then
		slot2_a1194:schedule(arg0)
	end

	return slot2_a1194
end

return new

-- ===== l2_5 base64 =====
local slot1_a1001 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

return string.gsub(arg0, "[^" .. slot1_a1001 .. "=]", ""):gsub(".", (function (arg0)
	if arg0 == "=" then
		return ""
	end

	local slot1_a1048 = ""
	local slot2_a1035 = slot1_a1001:find(arg0) - 1

	for slot6_a1033 = 6, 1, -1 do
		slot1_a1048 = slot1_a1048 .. (slot2_a1035 % 2^slot6_a1033 - slot2_a1035 % 2^(slot6_a1033 - 1) > 0 and "1" or "0")
	end

	return slot1_a1048
end)):gsub("%d%d%d?%d?%d?%d?%d?%d?", (function (arg0)
	if #arg0 ~= 8 then
		return ""
	end

	local slot1_a1074 = 0

	for slot5_a1069 = 1, 8 do
		slot1_a1074 = slot1_a1074 + (arg0:sub(slot5_a1069, slot5_a1069) == "1" and 2^(8 - slot5_a1069) or 0)
	end

	return string.char(slot1_a1074)
end))
