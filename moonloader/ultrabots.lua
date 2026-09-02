return (function()
	local function var_1_0(arg_2_0)
		local var_2_0 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

		arg_2_0 = string.gsub(arg_2_0, "[^" .. var_2_0 .. "=]", "")

		return arg_2_0:gsub(".", function(arg_3_0)
			if arg_3_0 == "=" then
				return ""
			end

			local var_3_0 = ""
			local var_3_1 = var_2_0:find(arg_3_0) - 1

			for iter_3_0 = 6, 1, -1 do
				var_3_0 = var_3_0 .. (var_3_1 % 2^iter_3_0 - var_3_1 % 2^(iter_3_0 - 1) > 0 and "1" or "0")
			end

			return var_3_0
		end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(arg_3_0)
			if #arg_3_0 ~= 8 then
				return ""
			end

			local var_3_0 = 0

			for iter_3_0 = 1, 8 do
				var_3_0 = var_3_0 + (arg_3_0:sub(iter_3_0, iter_3_0) == "1" and 2^(8 - iter_3_0) or 0)
			end

			return string.char(var_3_0)
		end)
	end

	local var_1_1 = (function()
		local var_2_0 = (function(arg_3_0)
			local var_3_0 = {}

			for iter_3_0 = 0, 255 do
				var_3_0[iter_3_0] = {}
			end

			var_3_0[0][0] = arg_3_0[1] * 255

			local var_3_1 = 1

			for iter_3_1 = 0, 7 do
				for iter_3_2 = 0, var_3_1 - 1 do
					for iter_3_3 = 0, var_3_1 - 1 do
						local var_3_2 = var_3_0[iter_3_2][iter_3_3] - arg_3_0[1] * var_3_1

						var_3_0[iter_3_2][iter_3_3 + var_3_1] = var_3_2 + arg_3_0[2] * var_3_1
						var_3_0[iter_3_2 + var_3_1][iter_3_3] = var_3_2 + arg_3_0[3] * var_3_1
						var_3_0[iter_3_2 + var_3_1][iter_3_3 + var_3_1] = var_3_2 + arg_3_0[4] * var_3_1
					end
				end

				var_3_1 = var_3_1 * 2
			end

			return var_3_0
		end)({
			0,
			1,
			1,
			0,
		})

		local function var_2_1(arg_3_0, arg_3_1)
			local var_3_0 = arg_3_0.S
			local var_3_1 = arg_3_0.i
			local var_3_2 = arg_3_0.j
			local var_3_3 = {}
			local var_3_4 = string.char

			for iter_3_0 = 1, arg_3_1 do
				var_3_1 = (var_3_1 + 1) % 256
				var_3_2 = (var_3_2 + var_3_0[var_3_1]) % 256
				var_3_0[var_3_1], var_3_0[var_3_2] = var_3_0[var_3_2], var_3_0[var_3_1]
				var_3_3[iter_3_0] = var_3_4(var_3_0[(var_3_0[var_3_1] + var_3_0[var_3_2]) % 256])
			end

			arg_3_0.i, arg_3_0.j = var_3_1, var_3_2

			return table.concat(var_3_3)
		end

		local function var_2_2(arg_3_0, arg_3_1)
			local var_3_0 = var_2_1(arg_3_0, #arg_3_1)
			local var_3_1 = {}
			local var_3_2 = string.byte
			local var_3_3 = string.char

			for iter_3_0 = 1, #arg_3_1 do
				var_3_1[iter_3_0] = var_3_3(var_2_0[var_3_2(arg_3_1, iter_3_0)][var_3_2(var_3_0, iter_3_0)])
			end

			return table.concat(var_3_1)
		end

		local function var_2_3(arg_3_0, arg_3_1)
			local var_3_0 = arg_3_0.S
			local var_3_1 = 0
			local var_3_2 = #arg_3_1
			local var_3_3 = string.byte

			for iter_3_0 = 0, 255 do
				var_3_1 = (var_3_1 + var_3_0[iter_3_0] + var_3_3(arg_3_1, iter_3_0 % var_3_2 + 1)) % 256
				var_3_0[iter_3_0], var_3_0[var_3_1] = var_3_0[var_3_1], var_3_0[iter_3_0]
			end
		end

		function new(arg_3_0)
			local var_3_0 = {}
			local var_3_1 = {
				i = 0,
				j = 0,
				S = var_3_0,
				generate = var_2_1,
				cipher = var_2_2,
				schedule = var_2_3,
			}

			for iter_3_0 = 0, 255 do
				var_3_0[iter_3_0] = iter_3_0
			end

			if arg_3_0 then
				var_3_1:schedule(arg_3_0)
			end

			return var_3_1
		end

		return new
	end)()
	local var_1_2 = getfenv or function()
		return _ENV
	end
	local var_1_3 = (function()
		if not bit then
			local var_2_0

			pcall(function()
				var_2_0 = require("bit")
			end)

			bit = var_2_0
		end

		local var_2_1 = bit or bit32 or (function()
			local var_3_0 = {
				_NAME = "bit.numberlua",
				_TYPE = "module",
				_VERSION = "0.3.1.20120131",
			}
			local var_3_1 = math.floor
			local var_3_2 = 4294967296
			local var_3_3 = var_3_2 - 1

			local function var_3_4(arg_4_0)
				local var_4_0 = {}
				local var_4_1 = setmetatable({}, var_4_0)

				function var_4_0.__index(arg_5_0, arg_5_1)
					local var_5_0 = arg_4_0(arg_5_1)

					var_4_1[arg_5_1] = var_5_0

					return var_5_0
				end

				return var_4_1
			end

			local function var_3_5(arg_4_0, arg_4_1)
				return function(arg_5_0, arg_5_1)
					local var_5_0 = 0
					local var_5_1 = 1

					while arg_5_0 ~= 0 and arg_5_1 ~= 0 do
						local var_5_2 = arg_5_0 % arg_4_1
						local var_5_3 = arg_5_1 % arg_4_1

						var_5_0 = var_5_0 + arg_4_0[var_5_2][var_5_3] * var_5_1
						arg_5_0 = (arg_5_0 - var_5_2) / arg_4_1
						arg_5_1 = (arg_5_1 - var_5_3) / arg_4_1
						var_5_1 = var_5_1 * arg_4_1
					end

					return var_5_0 + (arg_5_0 + arg_5_1) * var_5_1
				end
			end

			local function var_3_6(arg_4_0)
				local var_4_0 = var_3_5(arg_4_0, 2)
				local var_4_1 = var_3_4(function(arg_5_0)
					return var_3_4(function(arg_6_0)
						return var_4_0(arg_5_0, arg_6_0)
					end)
				end)

				return var_3_5(var_4_1, 2^(arg_4_0.n or 1))
			end

			function var_3_0.tobit(arg_4_0)
				return arg_4_0 % 4294967296
			end

			var_3_0.bxor = var_3_6({
				[0] = {
					[0] = 0,
					1,
				},
				{
					[0] = 1,
					0,
				},
				n = 4,
			})

			local var_3_7 = var_3_0.bxor

			function var_3_0.bnot(arg_4_0)
				return var_3_3 - arg_4_0
			end

			local var_3_8 = var_3_0.bnot

			function var_3_0.band(arg_4_0, arg_4_1)
				return (arg_4_0 + arg_4_1 - var_3_7(arg_4_0, arg_4_1)) / 2
			end

			local var_3_9 = var_3_0.band

			function var_3_0.bor(arg_4_0, arg_4_1)
				return var_3_3 - var_3_9(var_3_3 - arg_4_0, var_3_3 - arg_4_1)
			end

			local var_3_10 = var_3_0.bor
			local var_3_11
			local var_3_12

			function var_3_0.rshift(arg_4_0, arg_4_1)
				if arg_4_1 < 0 then
					return var_3_11(arg_4_0, -arg_4_1)
				end

				return var_3_1(arg_4_0 % 4294967296 / 2^arg_4_1)
			end

			local var_3_13 = var_3_0.rshift

			function var_3_0.lshift(arg_4_0, arg_4_1)
				if arg_4_1 < 0 then
					return var_3_13(arg_4_0, -arg_4_1)
				end

				return arg_4_0 * 2^arg_4_1 % 4294967296
			end

			var_3_11 = var_3_0.lshift

			function var_3_0.tohex(arg_4_0, arg_4_1)
				arg_4_1 = arg_4_1 or 8

				local var_4_0

				if arg_4_1 <= 0 then
					if arg_4_1 == 0 then
						return ""
					end

					var_4_0 = true
					arg_4_1 = -arg_4_1
				end

				arg_4_0 = var_3_9(arg_4_0, 16^arg_4_1 - 1)

				return ("%0" .. arg_4_1 .. (var_4_0 and "X" or "x")):format(arg_4_0)
			end

			local var_3_14 = var_3_0.tohex

			function var_3_0.extract(arg_4_0, arg_4_1, arg_4_2)
				arg_4_2 = arg_4_2 or 1

				return var_3_9(var_3_13(arg_4_0, arg_4_1), 2^arg_4_2 - 1)
			end

			local var_3_15 = var_3_0.extract

			function var_3_0.replace(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
				arg_4_3 = arg_4_3 or 1

				local var_4_0 = 2^arg_4_3 - 1

				arg_4_1 = var_3_9(arg_4_1, var_4_0)

				local var_4_1 = var_3_8(var_3_11(var_4_0, arg_4_2))

				return var_3_9(arg_4_0, var_4_1) + var_3_11(arg_4_1, arg_4_2)
			end

			local var_3_16 = var_3_0.replace

			function var_3_0.bswap(arg_4_0)
				local var_4_0 = var_3_9(arg_4_0, 255)

				arg_4_0 = var_3_13(arg_4_0, 8)

				local var_4_1 = var_3_9(arg_4_0, 255)

				arg_4_0 = var_3_13(arg_4_0, 8)

				local var_4_2 = var_3_9(arg_4_0, 255)

				arg_4_0 = var_3_13(arg_4_0, 8)

				local var_4_3 = var_3_9(arg_4_0, 255)

				return var_3_11(var_3_11(var_3_11(var_4_0, 8) + var_4_1, 8) + var_4_2, 8) + var_4_3
			end

			local var_3_17 = var_3_0.bswap

			function var_3_0.rrotate(arg_4_0, arg_4_1)
				arg_4_1 = arg_4_1 % 32

				local var_4_0 = var_3_9(arg_4_0, 2^arg_4_1 - 1)

				return var_3_13(arg_4_0, arg_4_1) + var_3_11(var_4_0, 32 - arg_4_1)
			end

			local var_3_18 = var_3_0.rrotate

			function var_3_0.lrotate(arg_4_0, arg_4_1)
				return var_3_18(arg_4_0, -arg_4_1)
			end

			local var_3_19 = var_3_0.lrotate

			var_3_0.rol = var_3_0.lrotate
			var_3_0.ror = var_3_0.rrotate

			function var_3_0.arshift(arg_4_0, arg_4_1)
				local var_4_0 = var_3_13(arg_4_0, arg_4_1)

				if arg_4_0 >= 2147483648 then
					var_4_0 = var_4_0 + var_3_11(2^arg_4_1 - 1, 32 - arg_4_1)
				end

				return var_4_0
			end

			local var_3_20 = var_3_0.arshift

			function var_3_0.btest(arg_4_0, arg_4_1)
				return var_3_9(arg_4_0, arg_4_1) ~= 0
			end

			var_3_0.bit32 = {}

			local function var_3_21(arg_4_0)
				return (-1 - arg_4_0) % var_3_2
			end

			var_3_0.bit32.bnot = var_3_21

			local function var_3_22(arg_4_0, arg_4_1, arg_4_2, ...)
				local var_4_0

				if arg_4_1 then
					arg_4_0 = arg_4_0 % var_3_2
					arg_4_1 = arg_4_1 % var_3_2

					local var_4_1 = var_3_7(arg_4_0, arg_4_1)

					if arg_4_2 then
						var_4_1 = var_3_22(var_4_1, arg_4_2, ...)
					end

					return var_4_1
				elseif arg_4_0 then
					return arg_4_0 % var_3_2
				else
					return 0
				end
			end

			var_3_0.bit32.bxor = var_3_22

			local function var_3_23(arg_4_0, arg_4_1, arg_4_2, ...)
				local var_4_0

				if arg_4_1 then
					arg_4_0 = arg_4_0 % var_3_2
					arg_4_1 = arg_4_1 % var_3_2

					local var_4_1 = (arg_4_0 + arg_4_1 - var_3_7(arg_4_0, arg_4_1)) / 2

					if arg_4_2 then
						var_4_1 = var_3_23(var_4_1, arg_4_2, ...)
					end

					return var_4_1
				elseif arg_4_0 then
					return arg_4_0 % var_3_2
				else
					return var_3_3
				end
			end

			var_3_0.bit32.band = var_3_23

			local function var_3_24(arg_4_0, arg_4_1, arg_4_2, ...)
				local var_4_0

				if arg_4_1 then
					arg_4_0 = arg_4_0 % var_3_2
					arg_4_1 = arg_4_1 % var_3_2

					local var_4_1 = var_3_3 - var_3_9(var_3_3 - arg_4_0, var_3_3 - arg_4_1)

					if arg_4_2 then
						var_4_1 = var_3_24(var_4_1, arg_4_2, ...)
					end

					return var_4_1
				elseif arg_4_0 then
					return arg_4_0 % var_3_2
				else
					return 0
				end
			end

			var_3_0.bit32.bor = var_3_24

			function var_3_0.bit32.btest(...)
				return var_3_23(...) ~= 0
			end

			function var_3_0.bit32.lrotate(arg_4_0, arg_4_1)
				return var_3_19(arg_4_0 % var_3_2, arg_4_1)
			end

			function var_3_0.bit32.rrotate(arg_4_0, arg_4_1)
				return var_3_18(arg_4_0 % var_3_2, arg_4_1)
			end

			function var_3_0.bit32.lshift(arg_4_0, arg_4_1)
				if arg_4_1 > 31 or arg_4_1 < -31 then
					return 0
				end

				return var_3_11(arg_4_0 % var_3_2, arg_4_1)
			end

			function var_3_0.bit32.rshift(arg_4_0, arg_4_1)
				if arg_4_1 > 31 or arg_4_1 < -31 then
					return 0
				end

				return var_3_13(arg_4_0 % var_3_2, arg_4_1)
			end

			function var_3_0.bit32.arshift(arg_4_0, arg_4_1)
				arg_4_0 = arg_4_0 % var_3_2

				if arg_4_1 >= 0 then
					if arg_4_1 > 31 then
						return arg_4_0 >= 2147483648 and var_3_3 or 0
					else
						local var_4_0 = var_3_13(arg_4_0, arg_4_1)

						if arg_4_0 >= 2147483648 then
							var_4_0 = var_4_0 + var_3_11(2^arg_4_1 - 1, 32 - arg_4_1)
						end

						return var_4_0
					end
				else
					return var_3_11(arg_4_0, -arg_4_1)
				end
			end

			function var_3_0.bit32.extract(arg_4_0, arg_4_1, ...)
				local var_4_0 = ... or 1

				if arg_4_1 < 0 or arg_4_1 > 31 or var_4_0 < 0 or arg_4_1 + var_4_0 > 32 then
					error("out of range")
				end

				arg_4_0 = arg_4_0 % var_3_2

				return var_3_15(arg_4_0, arg_4_1, ...)
			end

			function var_3_0.bit32.replace(arg_4_0, arg_4_1, arg_4_2, ...)
				local var_4_0 = ... or 1

				if arg_4_2 < 0 or arg_4_2 > 31 or var_4_0 < 0 or arg_4_2 + var_4_0 > 32 then
					error("out of range")
				end

				arg_4_0 = arg_4_0 % var_3_2
				arg_4_1 = arg_4_1 % var_3_2

				return var_3_16(arg_4_0, arg_4_1, arg_4_2, ...)
			end

			var_3_0.bit = {}

			function var_3_0.bit.tobit(arg_4_0)
				arg_4_0 = arg_4_0 % var_3_2

				if arg_4_0 >= 2147483648 then
					arg_4_0 = arg_4_0 - var_3_2
				end

				return arg_4_0
			end

			local var_3_25 = var_3_0.bit.tobit

			function var_3_0.bit.tohex(arg_4_0, ...)
				return var_3_14(arg_4_0 % var_3_2, ...)
			end

			function var_3_0.bit.bnot(arg_4_0)
				return var_3_25(var_3_8(arg_4_0 % var_3_2))
			end

			local function var_3_26(arg_4_0, arg_4_1, arg_4_2, ...)
				if arg_4_2 then
					return var_3_26(var_3_26(arg_4_0, arg_4_1), arg_4_2, ...)
				elseif arg_4_1 then
					return var_3_25(var_3_10(arg_4_0 % var_3_2, arg_4_1 % var_3_2))
				else
					return var_3_25(arg_4_0)
				end
			end

			var_3_0.bit.bor = var_3_26

			local function var_3_27(arg_4_0, arg_4_1, arg_4_2, ...)
				if arg_4_2 then
					return var_3_27(var_3_27(arg_4_0, arg_4_1), arg_4_2, ...)
				elseif arg_4_1 then
					return var_3_25(var_3_9(arg_4_0 % var_3_2, arg_4_1 % var_3_2))
				else
					return var_3_25(arg_4_0)
				end
			end

			var_3_0.bit.band = var_3_27

			local function var_3_28(arg_4_0, arg_4_1, arg_4_2, ...)
				if arg_4_2 then
					return var_3_28(var_3_28(arg_4_0, arg_4_1), arg_4_2, ...)
				elseif arg_4_1 then
					return var_3_25(var_3_7(arg_4_0 % var_3_2, arg_4_1 % var_3_2))
				else
					return var_3_25(arg_4_0)
				end
			end

			var_3_0.bit.bxor = var_3_28

			function var_3_0.bit.lshift(arg_4_0, arg_4_1)
				return var_3_25(var_3_11(arg_4_0 % var_3_2, arg_4_1 % 32))
			end

			function var_3_0.bit.rshift(arg_4_0, arg_4_1)
				return var_3_25(var_3_13(arg_4_0 % var_3_2, arg_4_1 % 32))
			end

			function var_3_0.bit.arshift(arg_4_0, arg_4_1)
				return var_3_25(var_3_20(arg_4_0 % var_3_2, arg_4_1 % 32))
			end

			function var_3_0.bit.rol(arg_4_0, arg_4_1)
				return var_3_25(var_3_19(arg_4_0 % var_3_2, arg_4_1 % 32))
			end

			function var_3_0.bit.ror(arg_4_0, arg_4_1)
				return var_3_25(var_3_18(arg_4_0 % var_3_2, arg_4_1 % 32))
			end

			function var_3_0.bit.bswap(arg_4_0)
				return var_3_25(var_3_17(arg_4_0 % var_3_2))
			end

			return var_3_0
		end)()
		local var_2_2 = table.unpack or unpack
		local var_2_3
		local var_2_4
		local var_2_5
		local var_2_6 = 50
		local var_2_7 = {
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
			35,
		}
		local var_2_8 = {
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
			"ABC",
		}
		local var_2_9 = {
			[0] = {
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgK",
				c = "OpArgN",
			},
			{
				b = "OpArgU",
				c = "OpArgU",
			},
			{
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgU",
				c = "OpArgN",
			},
			{
				b = "OpArgK",
				c = "OpArgN",
			},
			{
				b = "OpArgR",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgN",
			},
			{
				b = "OpArgU",
				c = "OpArgN",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgU",
				c = "OpArgU",
			},
			{
				b = "OpArgR",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgR",
				c = "OpArgR",
			},
			{
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgK",
				c = "OpArgK",
			},
			{
				b = "OpArgR",
				c = "OpArgU",
			},
			{
				b = "OpArgR",
				c = "OpArgU",
			},
			{
				b = "OpArgU",
				c = "OpArgU",
			},
			{
				b = "OpArgU",
				c = "OpArgU",
			},
			{
				b = "OpArgU",
				c = "OpArgN",
			},
			{
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgR",
				c = "OpArgN",
			},
			{
				b = "OpArgN",
				c = "OpArgU",
			},
			{
				b = "OpArgU",
				c = "OpArgU",
			},
			{
				b = "OpArgN",
				c = "OpArgN",
			},
			{
				b = "OpArgU",
				c = "OpArgN",
			},
			{
				b = "OpArgU",
				c = "OpArgN",
			},
		}

		local function var_2_10(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
			local var_3_0 = 0

			for iter_3_0 = arg_3_1, arg_3_2, arg_3_3 do
				var_3_0 = var_3_0 + string.byte(arg_3_0, iter_3_0, iter_3_0) * 256^(iter_3_0 - arg_3_1)
			end

			return var_3_0
		end

		local function var_2_11(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
			local var_3_0 = (-1)^var_2_1.rshift(arg_3_3, 7)
			local var_3_1 = var_2_1.rshift(arg_3_2, 7) + var_2_1.lshift(var_2_1.band(arg_3_3, 127), 1)
			local var_3_2 = arg_3_0 + var_2_1.lshift(arg_3_1, 8) + var_2_1.lshift(var_2_1.band(arg_3_2, 127), 16)
			local var_3_3 = 1

			if var_3_1 == 0 then
				if var_3_2 == 0 then
					return var_3_0 * 0
				else
					var_3_3 = 0
					var_3_1 = 1
				end
			elseif var_3_1 == 127 then
				if var_3_2 == 0 then
					return var_3_0 * 1 / 0
				else
					return var_3_0 * 0 / 0
				end
			end

			return var_3_0 * 2^(var_3_1 - 127) * (1 + var_3_3 / 8388608)
		end

		local function var_2_12(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
			local var_3_0 = (-1)^var_2_1.rshift(arg_3_7, 7)
			local var_3_1 = var_2_1.lshift(var_2_1.band(arg_3_7, 127), 4) + var_2_1.rshift(arg_3_6, 4)
			local var_3_2 = var_2_1.band(arg_3_6, 15) * 281474976710656
			local var_3_3 = 1
			local var_3_4 = var_3_2 + arg_3_5 * 1099511627776 + arg_3_4 * 4294967296 + arg_3_3 * 16777216 + arg_3_2 * 65536 + arg_3_1 * 256 + arg_3_0

			if var_3_1 == 0 then
				if var_3_4 == 0 then
					return var_3_0 * 0
				else
					var_3_3 = 0
					var_3_1 = 1
				end
			elseif var_3_1 == 2047 then
				if var_3_4 == 0 then
					return var_3_0 * 1 / 0
				else
					return var_3_0 * 0 / 0
				end
			end

			return var_3_0 * 2^(var_3_1 - 1023) * (var_3_3 + var_3_4 / 4503599627370496)
		end

		local function var_2_13(arg_3_0, arg_3_1, arg_3_2)
			return var_2_10(arg_3_0, arg_3_1, arg_3_2 - 1, 1)
		end

		local function var_2_14(arg_3_0, arg_3_1, arg_3_2)
			return var_2_10(arg_3_0, arg_3_2 - 1, arg_3_1, -1)
		end

		local function var_2_15(arg_3_0, arg_3_1)
			return var_2_11(string.byte(arg_3_0, arg_3_1, arg_3_1 + 3))
		end

		local function var_2_16(arg_3_0, arg_3_1)
			local var_3_0, var_3_1, var_3_2, var_3_3 = string.byte(arg_3_0, arg_3_1, arg_3_1 + 3)

			return var_2_11(var_3_3, var_3_2, var_3_1, var_3_0)
		end

		local function var_2_17(arg_3_0, arg_3_1)
			return var_2_12(string.byte(arg_3_0, arg_3_1, arg_3_1 + 7))
		end

		local function var_2_18(arg_3_0, arg_3_1)
			local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5, var_3_6, var_3_7 = string.byte(arg_3_0, arg_3_1, arg_3_1 + 7)

			return var_2_12(var_3_7, var_3_6, var_3_5, var_3_4, var_3_3, var_3_2, var_3_1, var_3_0)
		end

		local var_2_19 = {
			[4] = {
				little = var_2_15,
				big = var_2_16,
			},
			[8] = {
				little = var_2_17,
				big = var_2_18,
			},
		}

		local function var_2_20(arg_3_0)
			local var_3_0 = arg_3_0.index
			local var_3_1 = string.byte(arg_3_0.source, var_3_0, var_3_0)

			arg_3_0.index = var_3_0 + 1

			return var_3_1
		end

		local function var_2_21(arg_3_0, arg_3_1)
			local var_3_0 = arg_3_0.index + arg_3_1
			local var_3_1 = string.sub(arg_3_0.source, arg_3_0.index, var_3_0 - 1)

			arg_3_0.index = var_3_0

			return var_3_1
		end

		local function var_2_22(arg_3_0)
			local var_3_0 = arg_3_0:s_szt()
			local var_3_1

			if var_3_0 ~= 0 then
				var_3_1 = string.sub(var_2_21(arg_3_0, var_3_0), 1, -2)
			end

			return var_3_1
		end

		local function var_2_23(arg_3_0, arg_3_1)
			return function(arg_4_0)
				local var_4_0 = arg_4_0.index + arg_3_0
				local var_4_1 = arg_3_1(arg_4_0.source, arg_4_0.index, var_4_0)

				arg_4_0.index = var_4_0

				return var_4_1
			end
		end

		local function var_2_24(arg_3_0, arg_3_1)
			return function(arg_4_0)
				local var_4_0 = arg_3_1(arg_4_0.source, arg_4_0.index)

				arg_4_0.index = arg_4_0.index + arg_3_0

				return var_4_0
			end
		end

		local function var_2_25(arg_3_0)
			local var_3_0 = arg_3_0:s_int()
			local var_3_1 = {}

			for iter_3_0 = 1, var_3_0 do
				local var_3_2 = arg_3_0:s_ins()
				local var_3_3 = var_2_1.band(var_3_2, 63)
				local var_3_4 = var_2_8[var_3_3]
				local var_3_5 = var_2_9[var_3_3]
				local var_3_6 = {
					value = var_3_2,
					op = var_2_7[var_3_3],
					A = var_2_1.band(var_2_1.rshift(var_3_2, 6), 255),
				}

				if var_3_4 == "ABC" then
					var_3_6.B = var_2_1.band(var_2_1.rshift(var_3_2, 23), 511)
					var_3_6.C = var_2_1.band(var_2_1.rshift(var_3_2, 14), 511)
					var_3_6.is_KB = var_3_5.b == "OpArgK" and var_3_6.B > 255
					var_3_6.is_KC = var_3_5.c == "OpArgK" and var_3_6.C > 255
				elseif var_3_4 == "ABx" then
					var_3_6.Bx = var_2_1.band(var_2_1.rshift(var_3_2, 14), 262143)
					var_3_6.is_K = var_3_5.b == "OpArgK"
				elseif var_3_4 == "AsBx" then
					var_3_6.sBx = var_2_1.band(var_2_1.rshift(var_3_2, 14), 262143) - 131071
				end

				var_3_1[iter_3_0] = var_3_6
			end

			return var_3_1
		end

		local function var_2_26(arg_3_0)
			local var_3_0 = arg_3_0:s_int()
			local var_3_1 = {}

			for iter_3_0 = 1, var_3_0 do
				local var_3_2 = var_2_20(arg_3_0)
				local var_3_3

				if var_3_2 == 1 then
					var_3_3 = var_2_20(arg_3_0) ~= 0
				elseif var_3_2 == 3 then
					var_3_3 = arg_3_0:s_num()
				elseif var_3_2 == 4 then
					var_3_3 = var_2_22(arg_3_0)
				end

				var_3_1[iter_3_0] = var_3_3
			end

			return var_3_1
		end

		local function var_2_27(arg_3_0, arg_3_1)
			local var_3_0 = arg_3_0:s_int()
			local var_3_1 = {}

			for iter_3_0 = 1, var_3_0 do
				var_3_1[iter_3_0] = var_2_5(arg_3_0, arg_3_1)
			end

			return var_3_1
		end

		local function var_2_28(arg_3_0)
			local var_3_0 = arg_3_0:s_int()
			local var_3_1 = {}

			for iter_3_0 = 1, var_3_0 do
				var_3_1[iter_3_0] = arg_3_0:s_int()
			end

			return var_3_1
		end

		local function var_2_29(arg_3_0)
			local var_3_0 = arg_3_0:s_int()
			local var_3_1 = {}

			for iter_3_0 = 1, var_3_0 do
				var_3_1[iter_3_0] = {
					varname = var_2_22(arg_3_0),
					startpc = arg_3_0:s_int(),
					endpc = arg_3_0:s_int(),
				}
			end

			return var_3_1
		end

		local function var_2_30(arg_3_0)
			local var_3_0 = arg_3_0:s_int()
			local var_3_1 = {}

			for iter_3_0 = 1, var_3_0 do
				var_3_1[iter_3_0] = var_2_22(arg_3_0)
			end

			return var_3_1
		end

		function var_2_5(arg_3_0, arg_3_1)
			local var_3_0 = {}
			local var_3_1 = var_2_22(arg_3_0) or arg_3_1

			var_3_0.source = var_3_1

			arg_3_0:s_int()
			arg_3_0:s_int()

			var_3_0.numupvals = var_2_20(arg_3_0)
			var_3_0.numparams = var_2_20(arg_3_0)

			var_2_20(arg_3_0)
			var_2_20(arg_3_0)

			var_3_0.code = var_2_25(arg_3_0)
			var_3_0.const = var_2_26(arg_3_0)
			var_3_0.subs = var_2_27(arg_3_0, var_3_1)
			var_3_0.lines = var_2_28(arg_3_0)

			var_2_29(arg_3_0)
			var_2_30(arg_3_0)

			for iter_3_0, iter_3_1 in ipairs(var_3_0.code) do
				if iter_3_1.is_K then
					iter_3_1.const = var_3_0.const[iter_3_1.Bx + 1]
				else
					if iter_3_1.is_KB then
						iter_3_1.const_B = var_3_0.const[iter_3_1.B - 255]
					end

					if iter_3_1.is_KC then
						iter_3_1.const_C = var_3_0.const[iter_3_1.C - 255]
					end
				end
			end

			return var_3_0
		end

		local function var_2_31(arg_3_0)
			local var_3_0
			local var_3_1
			local var_3_2
			local var_3_3
			local var_3_4
			local var_3_5
			local var_3_6
			local var_3_7 = {
				index = 1,
				source = arg_3_0,
			}

			assert(var_2_21(var_3_7, 4) == "\x1BLua", "X\x02\fЂa9V\x18Ua‰BB\x16F\x17Tp\x10X`\x10\x10\x01u\x10рА\x00\x01\x00\x02\x00А\x00Р\x00\x01\x00Д\x00\x01\x00\x02\x00\x01\x00\x00\x02\x00\x00\x00")
			assert(var_2_20(var_3_7) == 81, "X\x02\fЂa9V\x18Ua‰BB\x16F\x17Tp\x10X`\x10\x10\x01u\x10рА\x00\x01\x00\x02\x00А\x00Р\x00\x01\x00Д\x00\x01\x00\x02\x00\x01\x00\x00\x02\x00\x00\x00")
			assert(var_2_20(var_3_7) == 0, "X\x02\fЂa9V\x18Ua‰BB\x16F\x17Tp\x10X`\x10\x10\x01u\x10рА\x00\x01\x00\x02\x00А\x00Р\x00\x01\x00Д\x00\x01\x00\x02\x00\x01\x00\x00\x02\x00\x00\x00")

			local var_3_8 = var_2_20(var_3_7) ~= 0
			local var_3_9 = var_2_20(var_3_7)
			local var_3_10 = var_2_20(var_3_7)
			local var_3_11 = var_2_20(var_3_7)
			local var_3_12 = var_2_20(var_3_7)
			local var_3_13 = var_2_20(var_3_7) ~= 0
			local var_3_14 = var_3_8 and var_2_13 or var_2_14

			var_3_7.s_int = var_2_23(var_3_9, var_3_14)
			var_3_7.s_szt = var_2_23(var_3_10, var_3_14)
			var_3_7.s_ins = var_2_23(var_3_11, var_3_14)

			if var_3_13 then
				var_3_7.s_num = var_2_23(var_3_12, var_3_14)
			elseif var_2_19[var_3_12] then
				var_3_7.s_num = var_2_24(var_3_12, var_2_19[var_3_12][var_3_8 and "little" or "big"])
			else
				error("X\x02\fЂa9V\x18Ua‰BB\x16F\x17Tp\x10X`\x10\x10\x01u\x10рА\x00\x01\x00\x02\x00А\x00Р\x00\x01\x00Д\x00\x01\x00\x02\x00\x01\x00\x00\x02\x00\x00\x00")
			end

			return var_2_5(var_3_7, "@virtual")
		end

		local function var_2_32(arg_3_0, arg_3_1)
			for iter_3_0, iter_3_1 in pairs(arg_3_0) do
				if arg_3_1 <= iter_3_1.index then
					iter_3_1.value = iter_3_1.store[iter_3_1.index]
					iter_3_1.store = iter_3_1
					iter_3_1.index = "value"
					arg_3_0[iter_3_0] = nil
				end
			end
		end

		local function var_2_33(arg_3_0, arg_3_1, arg_3_2)
			local var_3_0 = arg_3_0[arg_3_1]

			if not var_3_0 then
				var_3_0 = {
					index = arg_3_1,
					store = arg_3_2,
				}
				arg_3_0[arg_3_1] = var_3_0
			end

			return var_3_0
		end

		local function var_2_34(...)
			return select("#", ...), {
				...,
			}
		end

		local function var_2_35(arg_3_0, arg_3_1)
			local var_3_0 = arg_3_0.source
			local var_3_1 = arg_3_0.lines[arg_3_0.pc - 1]
			local var_3_2, var_3_3, var_3_4 = string.match(arg_3_1, "^(.-):(%d+):%s+(.+)")
			local var_3_5 = "%s:%i: [%s:%i] %s"

			var_3_1 = var_3_1 or "0"
			var_3_2 = var_3_2 or "?"
			var_3_3 = var_3_3 or "0"
			var_3_4 = var_3_4 or arg_3_1

			error(string.format(var_3_5, var_3_0, var_3_1, var_3_2, var_3_3, var_3_4), 0)
		end

		local function var_2_36(arg_3_0)
			local var_3_0 = arg_3_0.code
			local var_3_1 = arg_3_0.subs
			local var_3_2 = arg_3_0.env
			local var_3_3 = arg_3_0.upvals
			local var_3_4 = arg_3_0.varargs
			local var_3_5 = -1
			local var_3_6 = {}
			local var_3_7 = arg_3_0.stack
			local var_3_8 = arg_3_0.pc

			while true do
				local var_3_9 = var_3_0[var_3_8]
				local var_3_10 = var_3_9.op

				var_3_8 = var_3_8 + 1

				if var_3_10 < 18 then
					if var_3_10 < 8 then
						if var_3_10 < 3 then
							if var_3_10 < 1 then
								for iter_3_0 = var_3_9.A, var_3_9.B do
									var_3_7[iter_3_0] = nil
								end
							elseif var_3_10 > 1 then
								local var_3_11 = var_3_3[var_3_9.B]

								var_3_7[var_3_9.A] = var_3_11.store[var_3_11.index]
							else
								local var_3_12
								local var_3_13

								if var_3_9.is_KB then
									var_3_12 = var_3_9.const_B
								else
									var_3_12 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_13 = var_3_9.const_C
								else
									var_3_13 = var_3_7[var_3_9.C]
								end

								var_3_7[var_3_9.A] = var_3_12 + var_3_13
							end
						elseif var_3_10 > 3 then
							if var_3_10 < 6 then
								if var_3_10 > 4 then
									local var_3_14 = var_3_9.A
									local var_3_15 = var_3_9.B
									local var_3_16

									if var_3_9.is_KC then
										var_3_16 = var_3_9.const_C
									else
										var_3_16 = var_3_7[var_3_9.C]
									end

									var_3_7[var_3_14 + 1] = var_3_7[var_3_15]
									var_3_7[var_3_14] = var_3_7[var_3_15][var_3_16]
								else
									var_3_7[var_3_9.A] = var_3_2[var_3_9.const]
								end
							elseif var_3_10 > 6 then
								local var_3_17

								if var_3_9.is_KC then
									var_3_17 = var_3_9.const_C
								else
									var_3_17 = var_3_7[var_3_9.C]
								end

								var_3_7[var_3_9.A] = var_3_7[var_3_9.B][var_3_17]
							else
								local var_3_18
								local var_3_19

								if var_3_9.is_KB then
									var_3_18 = var_3_9.const_B
								else
									var_3_18 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_19 = var_3_9.const_C
								else
									var_3_19 = var_3_7[var_3_9.C]
								end

								var_3_7[var_3_9.A] = var_3_18 - var_3_19
							end
						else
							var_3_7[var_3_9.A] = var_3_7[var_3_9.B]
						end
					elseif var_3_10 > 8 then
						if var_3_10 < 13 then
							if var_3_10 < 10 then
								var_3_2[var_3_9.const] = var_3_7[var_3_9.A]
							elseif var_3_10 > 10 then
								if var_3_10 < 12 then
									local var_3_20 = var_3_9.A
									local var_3_21 = var_3_9.B
									local var_3_22 = var_3_9.C
									local var_3_23
									local var_3_24
									local var_3_25

									if var_3_21 == 0 then
										var_3_23 = var_3_5 - var_3_20
									else
										var_3_23 = var_3_21 - 1
									end

									local var_3_26, var_3_27 = var_2_34(var_3_7[var_3_20](var_2_2(var_3_7, var_3_20 + 1, var_3_20 + var_3_23)))

									if var_3_22 == 0 then
										var_3_5 = var_3_20 + var_3_26 - 1
									else
										var_3_26 = var_3_22 - 1
									end

									for iter_3_1 = 1, var_3_26 do
										var_3_7[var_3_20 + iter_3_1 - 1] = var_3_27[iter_3_1]
									end
								else
									local var_3_28 = var_3_3[var_3_9.B]

									var_3_28.store[var_3_28.index] = var_3_7[var_3_9.A]
								end
							else
								local var_3_29
								local var_3_30

								if var_3_9.is_KB then
									var_3_29 = var_3_9.const_B
								else
									var_3_29 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_30 = var_3_9.const_C
								else
									var_3_30 = var_3_7[var_3_9.C]
								end

								var_3_7[var_3_9.A] = var_3_29 * var_3_30
							end
						elseif var_3_10 > 13 then
							if var_3_10 < 16 then
								if var_3_10 > 14 then
									local var_3_31 = var_3_9.A
									local var_3_32 = var_3_9.B
									local var_3_33

									if var_3_32 == 0 then
										var_3_33 = var_3_5 - var_3_31
									else
										var_3_33 = var_3_32 - 1
									end

									var_2_32(var_3_6, 0)

									return var_2_34(var_3_7[var_3_31](var_2_2(var_3_7, var_3_31 + 1, var_3_31 + var_3_33)))
								else
									local var_3_34
									local var_3_35

									if var_3_9.is_KB then
										var_3_34 = var_3_9.const_B
									else
										var_3_34 = var_3_7[var_3_9.B]
									end

									if var_3_9.is_KC then
										var_3_35 = var_3_9.const_C
									else
										var_3_35 = var_3_7[var_3_9.C]
									end

									var_3_7[var_3_9.A][var_3_34] = var_3_35
								end
							elseif var_3_10 > 16 then
								var_3_7[var_3_9.A] = {}
							else
								local var_3_36
								local var_3_37

								if var_3_9.is_KB then
									var_3_36 = var_3_9.const_B
								else
									var_3_36 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_37 = var_3_9.const_C
								else
									var_3_37 = var_3_7[var_3_9.C]
								end

								var_3_7[var_3_9.A] = var_3_36 / var_3_37
							end
						else
							var_3_7[var_3_9.A] = var_3_9.const
						end
					else
						local var_3_38 = var_3_9.A
						local var_3_39 = var_3_7[var_3_38 + 2]
						local var_3_40 = var_3_7[var_3_38] + var_3_39
						local var_3_41 = var_3_7[var_3_38 + 1]
						local var_3_42

						if var_3_39 == math.abs(var_3_39) then
							var_3_42 = var_3_40 <= var_3_41
						else
							var_3_42 = var_3_41 <= var_3_40
						end

						if var_3_42 then
							var_3_7[var_3_9.A] = var_3_40
							var_3_7[var_3_9.A + 3] = var_3_40
							var_3_8 = var_3_8 + var_3_9.sBx
						end
					end
				elseif var_3_10 > 18 then
					if var_3_10 < 28 then
						if var_3_10 < 23 then
							if var_3_10 < 20 then
								var_3_7[var_3_9.A] = #var_3_7[var_3_9.B]
							elseif var_3_10 > 20 then
								if var_3_10 < 22 then
									local var_3_43 = var_3_9.A
									local var_3_44 = var_3_9.B
									local var_3_45 = {}
									local var_3_46

									if var_3_44 == 0 then
										var_3_46 = var_3_5 - var_3_43 + 1
									else
										var_3_46 = var_3_44 - 1
									end

									for iter_3_2 = 1, var_3_46 do
										var_3_45[iter_3_2] = var_3_7[var_3_43 + iter_3_2 - 1]
									end

									var_2_32(var_3_6, 0)

									return var_3_46, var_3_45
								else
									local var_3_47 = var_3_7[var_3_9.B]

									for iter_3_3 = var_3_9.B + 1, var_3_9.C do
										var_3_47 = var_3_47 .. var_3_7[iter_3_3]
									end

									var_3_7[var_3_9.A] = var_3_47
								end
							else
								local var_3_48
								local var_3_49

								if var_3_9.is_KB then
									var_3_48 = var_3_9.const_B
								else
									var_3_48 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_49 = var_3_9.const_C
								else
									var_3_49 = var_3_7[var_3_9.C]
								end

								var_3_7[var_3_9.A] = var_3_48 % var_3_49
							end
						elseif var_3_10 > 23 then
							if var_3_10 < 26 then
								if var_3_10 > 24 then
									var_2_32(var_3_6, var_3_9.A)
								else
									local var_3_50
									local var_3_51

									if var_3_9.is_KB then
										var_3_50 = var_3_9.const_B
									else
										var_3_50 = var_3_7[var_3_9.B]
									end

									if var_3_9.is_KC then
										var_3_51 = var_3_9.const_C
									else
										var_3_51 = var_3_7[var_3_9.C]
									end

									if var_3_50 == var_3_51 == (var_3_9.A ~= 0) then
										var_3_8 = var_3_8 + var_3_0[var_3_8].sBx
									end

									var_3_8 = var_3_8 + 1
								end
							elseif var_3_10 > 26 then
								local var_3_52
								local var_3_53

								if var_3_9.is_KB then
									var_3_52 = var_3_9.const_B
								else
									var_3_52 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_53 = var_3_9.const_C
								else
									var_3_53 = var_3_7[var_3_9.C]
								end

								if var_3_52 < var_3_53 == (var_3_9.A ~= 0) then
									var_3_8 = var_3_8 + var_3_0[var_3_8].sBx
								end

								var_3_8 = var_3_8 + 1
							else
								local var_3_54
								local var_3_55

								if var_3_9.is_KB then
									var_3_54 = var_3_9.const_B
								else
									var_3_54 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_55 = var_3_9.const_C
								else
									var_3_55 = var_3_7[var_3_9.C]
								end

								var_3_7[var_3_9.A] = var_3_54^var_3_55
							end
						else
							var_3_7[var_3_9.A] = var_3_9.B ~= 0

							if var_3_9.C ~= 0 then
								var_3_8 = var_3_8 + 1
							end
						end
					elseif var_3_10 > 28 then
						if var_3_10 < 33 then
							if var_3_10 < 30 then
								local var_3_56
								local var_3_57

								if var_3_9.is_KB then
									var_3_56 = var_3_9.const_B
								else
									var_3_56 = var_3_7[var_3_9.B]
								end

								if var_3_9.is_KC then
									var_3_57 = var_3_9.const_C
								else
									var_3_57 = var_3_7[var_3_9.C]
								end

								if var_3_56 <= var_3_57 == (var_3_9.A ~= 0) then
									var_3_8 = var_3_8 + var_3_0[var_3_8].sBx
								end

								var_3_8 = var_3_8 + 1
							elseif var_3_10 > 30 then
								if var_3_10 < 32 then
									local var_3_58 = var_3_1[var_3_9.Bx + 1]
									local var_3_59 = var_3_58.numupvals
									local var_3_60

									if var_3_59 ~= 0 then
										var_3_60 = {}

										for iter_3_4 = 1, var_3_59 do
											local var_3_61 = var_3_0[var_3_8 + iter_3_4 - 1]

											if var_3_61.op == var_2_7[0] then
												var_3_60[iter_3_4 - 1] = var_2_33(var_3_6, var_3_61.B, var_3_7)
											elseif var_3_61.op == var_2_7[4] then
												var_3_60[iter_3_4 - 1] = var_3_3[var_3_61.B]
											end
										end

										var_3_8 = var_3_8 + var_3_59
									end

									var_3_7[var_3_9.A] = var_2_4(var_3_58, var_3_2, var_3_60)
								else
									local var_3_62 = var_3_9.A
									local var_3_63 = var_3_9.B

									if not var_3_7[var_3_63] == (var_3_9.C ~= 0) then
										var_3_8 = var_3_8 + 1
									else
										var_3_7[var_3_62] = var_3_7[var_3_63]
									end
								end
							else
								var_3_7[var_3_9.A] = -var_3_7[var_3_9.B]
							end
						elseif var_3_10 > 33 then
							if var_3_10 < 36 then
								if var_3_10 > 34 then
									local var_3_64 = var_3_9.A
									local var_3_65 = var_3_9.B

									if var_3_65 == 0 then
										var_3_65 = var_3_4.size
										var_3_5 = var_3_64 + var_3_65 - 1
									end

									for iter_3_5 = 1, var_3_65 do
										var_3_7[var_3_64 + iter_3_5 - 1] = var_3_4.list[iter_3_5]
									end
								else
									local var_3_66 = var_3_9.A
									local var_3_67
									local var_3_68
									local var_3_69
									local var_3_70 = assert(tonumber(var_3_7[var_3_66]), "X\x02\fЂa9V\x18Ua‰BB\x16F\x17Tp\x10X`\x10\x10\x01u\x10рА\x00\x01\x00\x02\x00А\x00Р\x00\x01\x00Д\x00\x01\x00\x02\x00\x01\x00\x00\x02\x00\x00\x00")
									local var_3_71 = assert(tonumber(var_3_7[var_3_66 + 1]), "X\x02\fЂa9V\x18Ua‰BB\x16F\x17Tp\x10X`\x10\x10\x01u\x10рА\x00\x01\x00\x02\x00А\x00Р\x00\x01\x00Д\x00\x01\x00\x02\x00\x01\x00\x00\x02\x00\x00\x00")
									local var_3_72 = assert(tonumber(var_3_7[var_3_66 + 2]), "X\x02\fЂa9V\x18Ua‰BB\x16F\x17Tp\x10X`\x10\x10\x01u\x10рА\x00\x01\x00\x02\x00А\x00Р\x00\x01\x00Д\x00\x01\x00\x02\x00\x01\x00\x00\x02\x00\x00\x00")

									var_3_7[var_3_66] = var_3_70 - var_3_72
									var_3_7[var_3_66 + 1] = var_3_71
									var_3_7[var_3_66 + 2] = var_3_72
									var_3_8 = var_3_8 + var_3_9.sBx
								end
							elseif var_3_10 > 36 then
								local var_3_73 = var_3_9.A
								local var_3_74 = var_3_9.C
								local var_3_75 = var_3_9.B
								local var_3_76 = var_3_7[var_3_73]
								local var_3_77

								if var_3_75 == 0 then
									var_3_75 = var_3_5 - var_3_73
								end

								if var_3_74 == 0 then
									var_3_74 = var_3_9[var_3_8].value
									var_3_8 = var_3_8 + 1
								end

								local var_3_78 = (var_3_74 - 1) * var_2_6

								for iter_3_6 = 1, var_3_75 do
									var_3_76[iter_3_6 + var_3_78] = var_3_7[var_3_73 + iter_3_6]
								end
							else
								var_3_7[var_3_9.A] = not var_3_7[var_3_9.B]
							end
						elseif not var_3_7[var_3_9.A] == (var_3_9.C ~= 0) then
							var_3_8 = var_3_8 + 1
						end
					else
						local var_3_79 = var_3_9.A
						local var_3_80 = var_3_7[var_3_79]
						local var_3_81 = var_3_7[var_3_79 + 1]
						local var_3_82 = var_3_7[var_3_79 + 2]
						local var_3_83 = var_3_79 + 3
						local var_3_84

						var_3_7[var_3_83 + 2] = var_3_82
						var_3_7[var_3_83 + 1] = var_3_81
						var_3_7[var_3_83] = var_3_80

						local var_3_85 = {
							var_3_80(var_3_81, var_3_82),
						}

						for iter_3_7 = 1, var_3_9.C do
							var_3_7[var_3_83 + iter_3_7 - 1] = var_3_85[iter_3_7]
						end

						if var_3_7[var_3_83] ~= nil then
							var_3_7[var_3_79 + 2] = var_3_7[var_3_83]
						else
							var_3_8 = var_3_8 + 1
						end
					end
				else
					var_3_8 = var_3_8 + var_3_9.sBx
				end

				arg_3_0.pc = var_3_8
			end
		end

		function var_2_4(arg_3_0, arg_3_1, arg_3_2)
			local var_3_0 = arg_3_0.code
			local var_3_1 = arg_3_0.subs
			local var_3_2 = arg_3_0.lines
			local var_3_3 = arg_3_0.source
			local var_3_4 = arg_3_0.numparams

			return function(...)
				local var_4_0 = {}
				local var_4_1 = {}
				local var_4_2 = 0
				local var_4_3, var_4_4 = var_2_34(...)
				local var_4_5
				local var_4_6
				local var_4_7
				local var_4_8

				for iter_4_0 = 1, var_3_4 do
					var_4_0[iter_4_0 - 1] = var_4_4[iter_4_0]
				end

				if var_4_3 > var_3_4 then
					var_4_2 = var_4_3 - var_3_4

					for iter_4_1 = 1, var_4_2 do
						var_4_1[iter_4_1] = var_4_4[var_3_4 + iter_4_1]
					end
				end

				local var_4_9 = {
					pc = 1,
					varargs = {
						list = var_4_1,
						size = var_4_2,
					},
					code = var_3_0,
					subs = var_3_1,
					lines = var_3_2,
					source = var_3_3,
					env = arg_3_1,
					upvals = arg_3_2,
					stack = var_4_0,
				}
				local var_4_10, var_4_11, var_4_12 = pcall(var_2_36, var_4_9, ...)
				local var_4_13 = var_4_12
				local var_4_14 = var_4_11

				if var_4_10 then
					return var_2_2(var_4_13, 1, var_4_14)
				else
					var_2_35(var_4_9, var_4_14)
				end
			end
		end

		return function(arg_3_0, arg_3_1)
			return var_2_4(var_2_31(arg_3_0), arg_3_1 or var_1_2(0))
		end
	end)()
	local var_1_4 = "QHZiQkloTlA+cEtBQWl3MDMzUA=="
	local var_1_5 = "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"

	local function var_1_6(arg_2_0, arg_2_1)
		local var_2_0 = var_1_1(var_1_0(arg_2_0))
		local var_2_1 = var_2_0.cipher(var_2_0, var_1_0(arg_2_1))

		return var_1_0(var_2_1)
	end

	local var_1_7 = 100
	local var_1_8 = 0
	local var_1_9 = {}
	local var_1_10 = "obfuscated."
	local var_1_11 = "by"
	local var_1_12 = "Mintha"
	local var_1_13 = "version"
	local var_1_14 = ".."
	local var_1_15 = "v1.2"
	local var_1_16 = var_1_13.lookupify
	local var_1_17 = var_1_10.AstKind
	local var_1_18 = unpack or table.unpack

	function var_1_9.new(arg_2_0)
		local var_2_0 = {
			maxUsedRegister = 0,
			usedRegisters = 0,
			blocks = {},
			registers = {},
			registersForVar = {},
			registerVars = {},
			VAR_REGISTER = newproxy(false),
			RETURN_ALL = newproxy(false),
			POS_REGISTER = newproxy(false),
			RETURN_REGISTER = newproxy(false),
			UPVALUE = newproxy(false),
			BIN_OPS = var_1_16({
				var_1_17.LessThanExpression,
				var_1_17.GreaterThanExpression,
				var_1_17.LessThanOrEqualsExpression,
				var_1_17.GreaterThanOrEqualsExpression,
				var_1_17.NotEqualsExpression,
				var_1_17.EqualsExpression,
				var_1_17.StrCatExpression,
				var_1_17.AddExpression,
				var_1_17.SubExpression,
				var_1_17.MulExpression,
				var_1_17.DivExpression,
				var_1_17.ModExpression,
				var_1_17.PowExpression,
			}),
		}

		setmetatable(var_2_0, arg_2_0)

		arg_2_0.__index = arg_2_0

		return var_2_0
	end

	function var_1_9.createBlock(arg_2_0)
		local var_2_0

		repeat
			var_2_0 = math.random(0, 16777216)
		until not arg_2_0.usedBlockIds[var_2_0]

		local var_2_1 = var_1_11:new(arg_2_0.containerFuncScope)
		local var_2_2 = {
			advanceToNextBlock = true,
			id = var_2_0,
			statements = {},
			scope = var_2_1,
		}

		table.insert(arg_2_0.blocks, var_2_2)

		return var_2_2
	end

	function var_1_9.setActiveBlock(arg_2_0, arg_2_1)
		arg_2_0.activeBlock = arg_2_1
	end

	function var_1_9.addStatement(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
		if arg_2_0.activeBlock.advanceToNextBlock then
			table.insert(arg_2_0.activeBlock.statements, {
				statement = arg_2_1,
				writes = var_1_16(arg_2_2),
				reads = var_1_16(arg_2_3),
				usesUpvals = arg_2_4 or false,
			})
		end
	end

	function var_1_9.compile(arg_2_0, arg_2_1)
		arg_2_0.blocks = {}
		arg_2_0.registers = {}
		arg_2_0.activeBlock = nil
		arg_2_0.registersForVar = {}
		arg_2_0.scopeFunctionDepths = {}
		arg_2_0.maxUsedRegister = 0
		arg_2_0.usedRegisters = 0
		arg_2_0.registerVars = {}
		arg_2_0.usedBlockIds = {}
		arg_2_0.upvalVars = {}
		arg_2_0.registerUsageStack = {}
		arg_2_0.upvalsProxyLenReturn = math.random(-4194304, 4194304)

		local var_2_0 = var_1_11:newGlobal()
		local var_2_1 = var_1_11:new(var_2_0, nil)
		local var_2_2, var_2_3 = var_2_0:resolve("getfenv")
		local var_2_4, var_2_5 = var_2_0:resolve("table")
		local var_2_6, var_2_7 = var_2_0:resolve("unpack")
		local var_2_8, var_2_9 = var_2_0:resolve("_ENV")
		local var_2_10, var_2_11 = var_2_0:resolve("newproxy")
		local var_2_12, var_2_13 = var_2_0:resolve("setmetatable")
		local var_2_14, var_2_15 = var_2_0:resolve("getmetatable")
		local var_2_16, var_2_17 = var_2_0:resolve("select")

		var_2_1:addReferenceToHigherScope(var_2_0, var_2_3, 2)
		var_2_1:addReferenceToHigherScope(var_2_0, var_2_5)
		var_2_1:addReferenceToHigherScope(var_2_0, var_2_7)
		var_2_1:addReferenceToHigherScope(var_2_0, var_2_9)
		var_2_1:addReferenceToHigherScope(var_2_0, var_2_11)
		var_2_1:addReferenceToHigherScope(var_2_0, var_2_13)
		var_2_1:addReferenceToHigherScope(var_2_0, var_2_15)

		arg_2_0.scope = var_2_17:new(var_2_1)
		arg_2_0.envVar = arg_2_0.scope:addVariable()
		arg_2_0.containerFuncVar = arg_2_0.scope:addVariable()
		arg_2_0.unpackVar = arg_2_0.scope:addVariable()
		arg_2_0.newproxyVar = arg_2_0.scope:addVariable()
		arg_2_0.setmetatableVar = arg_2_0.scope:addVariable()
		arg_2_0.getmetatableVar = arg_2_0.scope:addVariable()
		arg_2_0.selectVar = arg_2_0.scope:addVariable()

		local var_2_18 = arg_2_0.scope:addVariable()

		arg_2_0.containerFuncScope = var_2_17:new(arg_2_0.scope)
		arg_2_0.whileScope = var_2_17:new(arg_2_0.containerFuncScope)
		arg_2_0.posVar = arg_2_0.containerFuncScope:addVariable()
		arg_2_0.argsVar = arg_2_0.containerFuncScope:addVariable()
		arg_2_0.currentUpvaluesVar = arg_2_0.containerFuncScope:addVariable()
		arg_2_0.detectGcCollectVar = arg_2_0.containerFuncScope:addVariable()
		arg_2_0.returnVar = arg_2_0.containerFuncScope:addVariable()
		arg_2_0.upvaluesTable = arg_2_0.scope:addVariable()
		arg_2_0.upvaluesReferenceCountsTable = arg_2_0.scope:addVariable()
		arg_2_0.allocUpvalFunction = arg_2_0.scope:addVariable()
		arg_2_0.currentUpvalId = arg_2_0.scope:addVariable()
		arg_2_0.upvaluesProxyFunctionVar = arg_2_0.scope:addVariable()
		arg_2_0.upvaluesGcFunctionVar = arg_2_0.scope:addVariable()
		arg_2_0.freeUpvalueFunc = arg_2_0.scope:addVariable()
		arg_2_0.createClosureVars = {}
		arg_2_0.createVarargClosureVar = arg_2_0.scope:addVariable()

		local var_2_19 = var_2_17:new(arg_2_0.scope)
		local var_2_20 = var_2_19:addVariable()
		local var_2_21 = var_2_19:addVariable()
		local var_2_22 = var_2_19:addVariable()
		local var_2_23 = var_2_19:addVariable()
		local var_2_24 = var_2_17:new(var_2_19)
		local var_2_25 = {}
		local var_2_26 = {}

		function arg_2_0.getUpvalueId(arg_3_0, arg_3_1, arg_3_2)
			local var_3_0

			if arg_3_0.scopeFunctionDepths[arg_3_1] == 0 then
				if var_2_26[arg_3_2] then
					return var_2_26[arg_3_2]
				end

				var_3_0 = var_2_15.FunctionCallExpression(var_2_15.VariableExpression(arg_3_0.scope, arg_3_0.allocUpvalFunction), {})
			else
				var_2_18:error("Unresolved Upvalue, this error should not occur!")
			end

			table.insert(var_2_25, var_2_15.TableEntry(var_3_0))

			local var_3_1 = #var_2_25

			var_2_26[arg_3_2] = var_3_1

			return var_3_1
		end

		var_2_24:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.containerFuncVar)
		var_2_24:addReferenceToHigherScope(var_2_19, var_2_20)
		var_2_24:addReferenceToHigherScope(var_2_19, var_2_21, 1)
		var_2_19:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesProxyFunctionVar)
		var_2_24:addReferenceToHigherScope(var_2_19, var_2_22)
		arg_2_0:compileTopNode(arg_2_1)

		local var_2_27 = {
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.containerFuncVar),
				val = var_2_15.FunctionLiteralExpression({
					var_2_15.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.posVar),
					var_2_15.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.argsVar),
					var_2_15.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar),
					var_2_15.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.detectGcCollectVar),
				}, arg_2_0:emitContainerFuncBody()),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.createVarargClosureVar),
				val = var_2_15.FunctionLiteralExpression({
					var_2_15.VariableExpression(var_2_19, var_2_20),
					var_2_15.VariableExpression(var_2_19, var_2_21),
				}, var_2_15.Block({
					var_2_15.LocalVariableDeclaration(var_2_19, {
						var_2_22,
					}, {
						var_2_15.FunctionCallExpression(var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesProxyFunctionVar), {
							var_2_15.VariableExpression(var_2_19, var_2_21),
						}),
					}),
					var_2_15.LocalVariableDeclaration(var_2_19, {
						var_2_23,
					}, {
						var_2_15.FunctionLiteralExpression({
							var_2_15.VarargExpression(),
						}, var_2_15.Block({
							var_2_15.ReturnStatement({
								var_2_15.FunctionCallExpression(var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.containerFuncVar), {
									var_2_15.VariableExpression(var_2_19, var_2_20),
									var_2_15.TableConstructorExpression({
										var_2_15.TableEntry(var_2_15.VarargExpression()),
									}),
									var_2_15.VariableExpression(var_2_19, var_2_21),
									var_2_15.VariableExpression(var_2_19, var_2_22),
								}),
							}),
						}, var_2_24)),
					}),
					var_2_15.ReturnStatement({
						var_2_15.VariableExpression(var_2_19, var_2_23),
					}),
				}, var_2_19)),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.upvaluesTable),
				val = var_2_15.TableConstructorExpression({}),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable),
				val = var_2_15.TableConstructorExpression({}),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.allocUpvalFunction),
				val = arg_2_0:createAllocUpvalFunction(),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.currentUpvalId),
				val = var_2_15.NumberExpression(0),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.upvaluesProxyFunctionVar),
				val = arg_2_0:createUpvaluesProxyFunc(),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.upvaluesGcFunctionVar),
				val = arg_2_0:createUpvaluesGcFunc(),
			},
			{
				var = var_2_15.AssignmentVariable(arg_2_0.scope, arg_2_0.freeUpvalueFunc),
				val = arg_2_0:createFreeUpvalueFunc(),
			},
		}
		local var_2_28 = {
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.containerFuncVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.createVarargClosureVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesTable),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.allocUpvalFunction),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.currentUpvalId),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesProxyFunctionVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesGcFunctionVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.freeUpvalueFunc),
		}

		for iter_2_0, iter_2_1 in pairs(arg_2_0.createClosureVars) do
			table.insert(var_2_27, iter_2_1)
			table.insert(var_2_28, var_2_15.VariableExpression(iter_2_1.var.scope, iter_2_1.var.id))
		end

		var_2_19.shuffle(var_2_27)

		local var_2_29 = {}
		local var_2_30 = {}

		for iter_2_2, iter_2_3 in ipairs(var_2_27) do
			var_2_29[iter_2_2] = iter_2_3.var
			var_2_30[iter_2_2] = iter_2_3.val
		end

		local var_2_31 = var_2_15.FunctionLiteralExpression({
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.envVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.unpackVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.newproxyVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.setmetatableVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.getmetatableVar),
			var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.selectVar),
			var_2_15.VariableExpression(arg_2_0.scope, var_2_18),
			var_1_18(var_2_19.shuffle(var_2_28)),
		}, var_2_15.Block({
			var_2_15.AssignmentStatement(var_2_29, var_2_30),
			var_2_15.ReturnStatement({
				var_2_15.FunctionCallExpression(var_2_15.FunctionCallExpression(var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.createVarargClosureVar), {
					var_2_15.NumberExpression(arg_2_0.startBlockId),
					var_2_15.TableConstructorExpression(var_2_25),
				}), {
					var_2_15.FunctionCallExpression(var_2_15.VariableExpression(arg_2_0.scope, arg_2_0.unpackVar), {
						var_2_15.VariableExpression(arg_2_0.scope, var_2_18),
					}),
				}),
			}),
		}, arg_2_0.scope))

		return var_2_15.TopNode(var_2_15.Block({
			var_2_15.ReturnStatement({
				var_2_15.FunctionCallExpression(var_2_31, {
					var_2_15.OrExpression(var_2_15.AndExpression(var_2_15.VariableExpression(var_2_0, var_2_3), var_2_15.FunctionCallExpression(var_2_15.VariableExpression(var_2_0, var_2_3), {})), var_2_15.VariableExpression(var_2_0, var_2_9)),
					var_2_15.OrExpression(var_2_15.VariableExpression(var_2_0, var_2_7), var_2_15.IndexExpression(var_2_15.VariableExpression(var_2_0, var_2_5), var_2_15.StringExpression("unpack"))),
					var_2_15.VariableExpression(var_2_0, var_2_11),
					var_2_15.VariableExpression(var_2_0, var_2_13),
					var_2_15.VariableExpression(var_2_0, var_2_15),
					var_2_15.VariableExpression(var_2_0, var_2_17),
					var_2_15.TableConstructorExpression({
						var_2_15.TableEntry(var_2_15.VarargExpression()),
					}),
				}),
			}),
		}, var_2_1), var_2_0)
	end

	function var_1_9.getCreateClosureVar(arg_2_0, arg_2_1)
		if not arg_2_0.createClosureVars[arg_2_1] then
			local var_2_0 = var_1_10.AssignmentVariable(arg_2_0.scope, arg_2_0.scope:addVariable())
			local var_2_1 = var_1_11:new(arg_2_0.scope)
			local var_2_2 = var_1_11:new(var_2_1)
			local var_2_3 = var_2_1:addVariable()
			local var_2_4 = var_2_1:addVariable()
			local var_2_5 = var_2_1:addVariable()
			local var_2_6 = var_2_1:addVariable()

			var_2_2:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.containerFuncVar)
			var_2_2:addReferenceToHigherScope(var_2_1, var_2_3)
			var_2_2:addReferenceToHigherScope(var_2_1, var_2_4, 1)
			var_2_1:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesProxyFunctionVar)
			var_2_2:addReferenceToHigherScope(var_2_1, var_2_5)

			local var_2_7 = {}
			local var_2_8 = {}

			for iter_2_0 = 1, arg_2_1 do
				local var_2_9 = var_2_2:addVariable()

				var_2_7[iter_2_0] = var_1_10.VariableExpression(var_2_2, var_2_9)
				var_2_8[iter_2_0] = var_1_10.TableEntry(var_1_10.VariableExpression(var_2_2, var_2_9))
			end

			local var_2_10 = var_1_10.FunctionLiteralExpression({
				var_1_10.VariableExpression(var_2_1, var_2_3),
				var_1_10.VariableExpression(var_2_1, var_2_4),
			}, var_1_10.Block({
				var_1_10.LocalVariableDeclaration(var_2_1, {
					var_2_5,
				}, {
					var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesProxyFunctionVar), {
						var_1_10.VariableExpression(var_2_1, var_2_4),
					}),
				}),
				var_1_10.LocalVariableDeclaration(var_2_1, {
					var_2_6,
				}, {
					var_1_10.FunctionLiteralExpression(var_2_7, var_1_10.Block({
						var_1_10.ReturnStatement({
							var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.containerFuncVar), {
								var_1_10.VariableExpression(var_2_1, var_2_3),
								var_1_10.TableConstructorExpression(var_2_8),
								var_1_10.VariableExpression(var_2_1, var_2_4),
								var_1_10.VariableExpression(var_2_1, var_2_5),
							}),
						}),
					}, var_2_2)),
				}),
				var_1_10.ReturnStatement({
					var_1_10.VariableExpression(var_2_1, var_2_6),
				}),
			}, var_2_1))

			arg_2_0.createClosureVars[arg_2_1] = {
				var = var_2_0,
				val = var_2_10,
			}
		end

		local var_2_11 = arg_2_0.createClosureVars[arg_2_1].var

		return var_2_11.scope, var_2_11.id
	end

	function var_1_9.pushRegisterUsageInfo(arg_2_0)
		table.insert(arg_2_0.registerUsageStack, {
			usedRegisters = arg_2_0.usedRegisters,
			registers = arg_2_0.registers,
		})

		arg_2_0.usedRegisters = 0
		arg_2_0.registers = {}
	end

	function var_1_9.popRegisterUsageInfo(arg_2_0)
		local var_2_0 = table.remove(arg_2_0.registerUsageStack)

		arg_2_0.usedRegisters = var_2_0.usedRegisters
		arg_2_0.registers = var_2_0.registers
	end

	function var_1_9.createUpvaluesGcFunc(arg_2_0)
		local var_2_0 = var_1_11:new(arg_2_0.scope)
		local var_2_1 = var_2_0:addVariable()
		local var_2_2 = var_2_0:addVariable()
		local var_2_3 = var_2_0:addVariable()
		local var_2_4 = var_1_11:new(var_2_0)

		var_2_4:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable, 3)
		var_2_4:addReferenceToHigherScope(var_2_0, var_2_3, 3)
		var_2_4:addReferenceToHigherScope(var_2_0, var_2_2, 3)
		a9:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable, 1)
		a9:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesTable, 1)

		return var_1_10.FunctionLiteralExpression({
			var_1_10.VariableExpression(var_2_0, var_2_1),
		}, var_1_10.Block({
			var_1_10.LocalVariableDeclaration(var_2_0, {
				var_2_2,
				var_2_3,
			}, {
				var_1_10.NumberExpression(1),
				var_1_10.IndexExpression(var_1_10.VariableExpression(var_2_0, var_2_1), var_1_10.NumberExpression(1)),
			}),
			var_1_10.WhileStatement(var_1_10.Block({
				var_1_10.AssignmentStatement({
					var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_3)),
					var_1_10.AssignmentVariable(var_2_0, var_2_2),
				}, {
					var_1_10.SubExpression(var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_3)), var_1_10.NumberExpression(1)),
					var_1_10.AddExpression(var_1_18(var_1_13.shuffle({
						var_1_10.VariableExpression(var_2_0, var_2_2),
						var_1_10.NumberExpression(1),
					}))),
				}),
				var_1_10.IfStatement(var_1_10.EqualsExpression(var_1_18(var_1_13.shuffle({
					var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_3)),
					var_1_10.NumberExpression(0),
				}))), var_1_10.Block({
					var_1_10.AssignmentStatement({
						var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_3)),
						var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesTable), var_1_10.VariableExpression(var_2_0, var_2_3)),
					}, {
						var_1_10.NilExpression(),
						var_1_10.NilExpression(),
					}),
				}, a9), {}, nil),
				var_1_10.AssignmentStatement({
					var_1_10.AssignmentVariable(var_2_0, var_2_3),
				}, {
					var_1_10.IndexExpression(var_1_10.VariableExpression(var_2_0, var_2_1), var_1_10.VariableExpression(var_2_0, var_2_2)),
				}),
			}, var_2_4), var_1_10.VariableExpression(var_2_0, var_2_3), var_2_0),
		}, var_2_0))
	end

	function var_1_9.createFreeUpvalueFunc(arg_2_0)
		local var_2_0 = var_1_11:new(arg_2_0.scope)
		local var_2_1 = var_2_0:addVariable()
		local var_2_2 = var_1_11:new(var_2_0)

		var_2_2:addReferenceToHigherScope(var_2_0, var_2_1, 3)
		var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable, 2)

		return var_1_10.FunctionLiteralExpression({
			var_1_10.VariableExpression(var_2_0, var_2_1),
		}, var_1_10.Block({
			var_1_10.AssignmentStatement({
				var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_1)),
			}, {
				var_1_10.SubExpression(var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_1)), var_1_10.NumberExpression(1)),
			}),
			var_1_10.IfStatement(var_1_10.EqualsExpression(var_1_18(var_1_13.shuffle({
				var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_1)),
				var_1_10.NumberExpression(0),
			}))), var_1_10.Block({
				var_1_10.AssignmentStatement({
					var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(var_2_0, var_2_1)),
					var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesTable), var_1_10.VariableExpression(var_2_0, var_2_1)),
				}, {
					var_1_10.NilExpression(),
					var_1_10.NilExpression(),
				}),
			}, var_2_2), {}, nil),
		}, var_2_0))
	end

	function var_1_9.createUpvaluesProxyFunc(arg_2_0)
		local var_2_0 = var_1_11:new(arg_2_0.scope)

		var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.newproxyVar)

		local var_2_1 = var_2_0:addVariable()
		local var_2_2 = var_1_11:new(var_2_0)
		local var_2_3 = var_2_2:addVariable()
		local var_2_4 = var_2_2:addVariable()
		local var_2_5 = var_1_11:new(var_2_0)

		var_2_2:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.newproxyVar)
		var_2_2:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.getmetatableVar)
		var_2_2:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesGcFunctionVar)
		var_2_2:addReferenceToHigherScope(var_2_0, var_2_1)
		var_2_5:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.setmetatableVar)
		var_2_5:addReferenceToHigherScope(var_2_0, var_2_1)
		var_2_5:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesGcFunctionVar)

		local var_2_6 = var_1_11:new(var_2_0)
		local var_2_7 = var_2_6:addVariable()

		var_2_6:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable, 2)
		var_2_6:addReferenceToHigherScope(var_2_0, var_2_1, 2)

		return var_1_10.FunctionLiteralExpression({
			var_1_10.VariableExpression(var_2_0, var_2_1),
		}, var_1_10.Block({
			var_1_10.ForStatement(var_2_6, var_2_7, var_1_10.NumberExpression(1), var_1_10.LenExpression(var_1_10.VariableExpression(var_2_0, var_2_1)), var_1_10.NumberExpression(1), var_1_10.Block({
				var_1_10.AssignmentStatement({
					var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.IndexExpression(var_1_10.VariableExpression(var_2_0, var_2_1), var_1_10.VariableExpression(var_2_6, var_2_7))),
				}, {
					var_1_10.AddExpression(var_1_18(var_1_13.shuffle({
						var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.IndexExpression(var_1_10.VariableExpression(var_2_0, var_2_1), var_1_10.VariableExpression(var_2_6, var_2_7))),
						var_1_10.NumberExpression(1),
					}))),
				}),
			}, var_2_6), var_2_0),
			var_1_10.IfStatement(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.newproxyVar), var_1_10.Block({
				var_1_10.LocalVariableDeclaration(var_2_2, {
					var_2_3,
				}, {
					var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.newproxyVar), {
						var_1_10.BooleanExpression(true),
					}),
				}),
				var_1_10.LocalVariableDeclaration(var_2_2, {
					var_2_4,
				}, {
					var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.getmetatableVar), {
						var_1_10.VariableExpression(var_2_2, var_2_3),
					}),
				}),
				var_1_10.AssignmentStatement({
					var_1_10.AssignmentIndexing(var_1_10.VariableExpression(var_2_2, var_2_4), var_1_10.StringExpression("__index")),
					var_1_10.AssignmentIndexing(var_1_10.VariableExpression(var_2_2, var_2_4), var_1_10.StringExpression("__gc")),
					var_1_10.AssignmentIndexing(var_1_10.VariableExpression(var_2_2, var_2_4), var_1_10.StringExpression("__len")),
				}, {
					var_1_10.VariableExpression(var_2_0, var_2_1),
					var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesGcFunctionVar),
					var_1_10.FunctionLiteralExpression({}, var_1_10.Block({
						var_1_10.ReturnStatement({
							var_1_10.NumberExpression(arg_2_0.upvalsProxyLenReturn),
						}),
					}, var_1_11:new(var_2_2))),
				}),
				var_1_10.ReturnStatement({
					var_1_10.VariableExpression(var_2_2, var_2_3),
				}),
			}, var_2_2), {}, var_1_10.Block({
				var_1_10.ReturnStatement({
					var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.setmetatableVar), {
						var_1_10.TableConstructorExpression({}),
						var_1_10.TableConstructorExpression({
							var_1_10.KeyedTableEntry(var_1_10.StringExpression("__gc"), var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesGcFunctionVar)),
							var_1_10.KeyedTableEntry(var_1_10.StringExpression("__index"), var_1_10.VariableExpression(var_2_0, var_2_1)),
							var_1_10.KeyedTableEntry(var_1_10.StringExpression("__len"), var_1_10.FunctionLiteralExpression({}, var_1_10.Block({
								var_1_10.ReturnStatement({
									var_1_10.NumberExpression(arg_2_0.upvalsProxyLenReturn),
								}),
							}, var_1_11:new(var_2_2)))),
						}),
					}),
				}),
			}, var_2_5)),
		}, var_2_0))
	end

	function var_1_9.createAllocUpvalFunction(arg_2_0)
		local var_2_0 = var_1_11:new(arg_2_0.scope)

		var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.currentUpvalId, 4)
		var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable, 1)

		return var_1_10.FunctionLiteralExpression({}, var_1_10.Block({
			var_1_10.AssignmentStatement({
				var_1_10.AssignmentVariable(arg_2_0.scope, arg_2_0.currentUpvalId),
			}, {
				var_1_10.AddExpression(var_1_18(var_1_13.shuffle({
					var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.currentUpvalId),
					var_1_10.NumberExpression(1),
				}))),
			}),
			var_1_10.AssignmentStatement({
				var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesReferenceCountsTable), var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.currentUpvalId)),
			}, {
				var_1_10.NumberExpression(1),
			}),
			var_1_10.ReturnStatement({
				var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.currentUpvalId),
			}),
		}, var_2_0))
	end

	function var_1_9.emitContainerFuncBody(arg_2_0)
		local var_2_0 = {}

		var_1_13.shuffle(arg_2_0.blocks)

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.blocks) do
			local var_2_1 = iter_2_1.id
			local var_2_2 = iter_2_1.statements

			for iter_2_2 = 2, #var_2_2 do
				local var_2_3 = var_2_2[iter_2_2]
				local var_2_4 = var_2_3.reads
				local var_2_5 = var_2_3.writes
				local var_2_6 = 0
				local var_2_7 = var_2_3.usesUpvals

				for iter_2_3 = 1, iter_2_2 - 1 do
					local var_2_8 = var_2_2[iter_2_2 - iter_2_3]

					if var_2_8.usesUpvals and var_2_7 then
						break
					end

					local var_2_9 = var_2_8.reads
					local var_2_10 = var_2_8.writes
					local var_2_11 = true

					for iter_2_4, iter_2_5 in pairs(var_2_9) do
						if var_2_5[iter_2_4] then
							var_2_11 = false

							break
						end
					end

					if var_2_11 then
						for iter_2_6, iter_2_7 in pairs(var_2_10) do
							if var_2_5[iter_2_6] then
								var_2_11 = false

								break
							end

							if var_2_4[iter_2_6] then
								var_2_11 = false

								break
							end
						end
					end

					if not var_2_11 then
						break
					end

					var_2_6 = iter_2_3
				end

				local var_2_12 = math.random(0, var_2_6)

				for iter_2_8 = 1, var_2_12 do
					var_2_2[iter_2_2 - iter_2_8], var_2_2[iter_2_2 - iter_2_8 + 1] = var_2_2[iter_2_2 - iter_2_8 + 1], var_2_2[iter_2_2 - iter_2_8]
				end
			end

			local var_2_13 = {}

			for iter_2_9, iter_2_10 in ipairs(iter_2_1.statements) do
				table.insert(var_2_13, iter_2_10.statement)
			end

			table.insert(var_2_0, {
				id = var_2_1,
				block = var_1_10.Block(var_2_13, iter_2_1.scope),
			})
		end

		table.sort(var_2_0, function(arg_3_0, arg_3_1)
			return arg_3_0.id < arg_3_1.id
		end)

		local function var_2_14(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
			return var_1_10.Block({
				var_1_10.IfStatement(var_1_10.LessThanExpression(arg_2_0:pos(arg_3_0), var_1_10.NumberExpression(arg_3_1)), arg_3_2, {}, arg_3_3),
			}, arg_3_0)
		end

		local function var_2_15(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
			local var_3_0 = arg_3_2 - arg_3_1 + 1

			if var_3_0 == 1 then
				arg_3_0[arg_3_2].block.scope:setParent(arg_3_3)

				return arg_3_0[arg_3_2].block
			elseif var_3_0 == 0 then
				return nil
			end

			local var_3_1 = arg_3_1 + math.ceil(var_3_0 / 2)
			local var_3_2 = math.random(arg_3_0[var_3_1 - 1].id, arg_3_0[var_3_1].id)
			local var_3_3 = arg_3_4 or var_1_11:new(arg_3_3)
			local var_3_4 = var_2_15(arg_3_0, arg_3_1, var_3_1 - 1, var_3_3)
			local var_3_5 = var_2_15(arg_3_0, var_3_1, arg_3_2, var_3_3)

			return var_2_14(var_3_3, var_3_2, var_3_4, var_3_5)
		end

		local var_2_16 = var_2_15(var_2_0, 1, #var_2_0, arg_2_0.containerFuncScope, arg_2_0.whileScope)

		arg_2_0.whileScope:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.returnVar, 1)
		arg_2_0.whileScope:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.posVar)
		arg_2_0.containerFuncScope:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.unpackVar)

		local var_2_17 = {
			arg_2_0.returnVar,
		}

		for iter_2_11, iter_2_12 in pairs(arg_2_0.registerVars) do
			if iter_2_11 ~= var_1_7 then
				table.insert(var_2_17, iter_2_12)
			end
		end

		local var_2_18 = {
			var_1_10.LocalVariableDeclaration(arg_2_0.containerFuncScope, var_1_13.shuffle(var_2_17), {}),
			var_1_10.WhileStatement(var_2_16, var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.posVar)),
			var_1_10.AssignmentStatement({
				var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, arg_2_0.posVar),
			}, {
				var_1_10.LenExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.detectGcCollectVar)),
			}),
			var_1_10.ReturnStatement({
				var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.unpackVar), {
					var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.returnVar),
				}),
			}),
		}

		if arg_2_0.maxUsedRegister >= var_1_7 then
			table.insert(var_2_18, 1, var_1_10.LocalVariableDeclaration(arg_2_0.containerFuncScope, {
				arg_2_0.registerVars[var_1_7],
			}, {
				var_1_10.TableConstructorExpression({}),
			}))
		end

		return var_1_10.Block(var_2_18, arg_2_0.containerFuncScope)
	end

	function var_1_9.freeRegister(arg_2_0, arg_2_1, arg_2_2)
		if arg_2_2 or arg_2_0.registers[arg_2_1] ~= arg_2_0.VAR_REGISTER then
			arg_2_0.usedRegisters = arg_2_0.usedRegisters - 1
			arg_2_0.registers[arg_2_1] = false
		end
	end

	function var_1_9.isVarRegister(arg_2_0, arg_2_1)
		return arg_2_0.registers[arg_2_1] == arg_2_0.VAR_REGISTER
	end

	function var_1_9.allocRegister(arg_2_0, arg_2_1)
		arg_2_0.usedRegisters = arg_2_0.usedRegisters + 1

		if not arg_2_1 then
			if not arg_2_0.registers[arg_2_0.POS_REGISTER] then
				arg_2_0.registers[arg_2_0.POS_REGISTER] = true

				return arg_2_0.POS_REGISTER
			end

			if not arg_2_0.registers[arg_2_0.RETURN_REGISTER] then
				arg_2_0.registers[arg_2_0.RETURN_REGISTER] = true

				return arg_2_0.RETURN_REGISTER
			end
		end

		local var_2_0 = 0

		if arg_2_0.usedRegisters < var_1_7 * var_1_8 then
			repeat
				var_2_0 = math.random(1, var_1_7 - 1)
			until not arg_2_0.registers[var_2_0]
		else
			repeat
				var_2_0 = var_2_0 + 1
			until not arg_2_0.registers[var_2_0]
		end

		if var_2_0 > arg_2_0.maxUsedRegister then
			arg_2_0.maxUsedRegister = var_2_0
		end

		if arg_2_1 then
			arg_2_0.registers[var_2_0] = arg_2_0.VAR_REGISTER
		else
			arg_2_0.registers[var_2_0] = true
		end

		return var_2_0
	end

	function var_1_9.isUpvalue(arg_2_0, arg_2_1, arg_2_2)
		return arg_2_0.upvalVars[arg_2_1] and arg_2_0.upvalVars[arg_2_1][arg_2_2]
	end

	function var_1_9.makeUpvalue(arg_2_0, arg_2_1, arg_2_2)
		if not arg_2_0.upvalVars[arg_2_1] then
			arg_2_0.upvalVars[arg_2_1] = {}
		end

		arg_2_0.upvalVars[arg_2_1][arg_2_2] = true
	end

	function var_1_9.getVarRegister(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
		if not arg_2_0.registersForVar[arg_2_1] then
			arg_2_0.registersForVar[arg_2_1] = {}
			arg_2_0.scopeFunctionDepths[arg_2_1] = arg_2_3
		end

		local var_2_0 = arg_2_0.registersForVar[arg_2_1][arg_2_2]

		if not var_2_0 then
			if arg_2_4 and arg_2_0.registers[arg_2_4] ~= arg_2_0.VAR_REGISTER and arg_2_4 ~= arg_2_0.POS_REGISTER and arg_2_4 ~= arg_2_0.RETURN_REGISTER then
				arg_2_0.registers[arg_2_4] = arg_2_0.VAR_REGISTER
				var_2_0 = arg_2_4
			else
				var_2_0 = arg_2_0:allocRegister(true)
			end

			arg_2_0.registersForVar[arg_2_1][arg_2_2] = var_2_0
		end

		return var_2_0
	end

	function var_1_9.getRegisterVarId(arg_2_0, arg_2_1)
		local var_2_0 = arg_2_0.registerVars[arg_2_1]

		if not var_2_0 then
			var_2_0 = arg_2_0.containerFuncScope:addVariable()
			arg_2_0.registerVars[arg_2_1] = var_2_0
		end

		return var_2_0
	end

	function var_1_9.register(arg_2_0, arg_2_1, arg_2_2)
		if arg_2_2 == arg_2_0.POS_REGISTER then
			return arg_2_0:pos(arg_2_1)
		end

		if arg_2_2 == arg_2_0.RETURN_REGISTER then
			return arg_2_0:getReturn(arg_2_1)
		end

		if arg_2_2 < var_1_7 then
			local var_2_0 = arg_2_0:getRegisterVarId(arg_2_2)

			arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, var_2_0)

			return var_1_10.VariableExpression(arg_2_0.containerFuncScope, var_2_0)
		end

		local var_2_1 = arg_2_0:getRegisterVarId(var_1_7)

		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, var_2_1)

		return var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, var_2_1), var_1_10.NumberExpression(arg_2_2 - var_1_7 + 1))
	end

	function var_1_9.registerList(arg_2_0, arg_2_1, arg_2_2)
		local var_2_0 = {}

		for iter_2_0, iter_2_1 in ipairs(arg_2_2) do
			table.insert(var_2_0, arg_2_0:register(arg_2_1, iter_2_1))
		end

		return var_2_0
	end

	function var_1_9.registerAssignment(arg_2_0, arg_2_1, arg_2_2)
		if arg_2_2 == arg_2_0.POS_REGISTER then
			return arg_2_0:posAssignment(arg_2_1)
		end

		if arg_2_2 == arg_2_0.RETURN_REGISTER then
			return arg_2_0:returnAssignment(arg_2_1)
		end

		if arg_2_2 < var_1_7 then
			local var_2_0 = arg_2_0:getRegisterVarId(arg_2_2)

			arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, var_2_0)

			return var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, var_2_0)
		end

		local var_2_1 = arg_2_0:getRegisterVarId(var_1_7)

		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, var_2_1)

		return var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.containerFuncScope, var_2_1), var_1_10.NumberExpression(arg_2_2 - var_1_7 + 1))
	end

	function var_1_9.setRegister(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
		if arg_2_4 then
			return arg_2_4(arg_2_0:registerAssignment(arg_2_1, arg_2_2), arg_2_3)
		end

		return var_1_10.AssignmentStatement({
			arg_2_0:registerAssignment(arg_2_1, arg_2_2),
		}, {
			arg_2_3,
		})
	end

	function var_1_9.setRegisters(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
		local var_2_0 = {}

		for iter_2_0, iter_2_1 in ipairs(arg_2_2) do
			table.insert(var_2_0, arg_2_0:registerAssignment(arg_2_1, iter_2_1))
		end

		return var_1_10.AssignmentStatement(var_2_0, arg_2_3)
	end

	function var_1_9.copyRegisters(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
		local var_2_0 = {}
		local var_2_1 = {}

		for iter_2_0, iter_2_1 in ipairs(arg_2_2) do
			local var_2_2 = arg_2_3[iter_2_0]

			if var_2_2 ~= iter_2_1 then
				table.insert(var_2_0, arg_2_0:registerAssignment(arg_2_1, iter_2_1))
				table.insert(var_2_1, arg_2_0:register(arg_2_1, var_2_2))
			end
		end

		if #var_2_0 > 0 and #var_2_1 > 0 then
			return var_1_10.AssignmentStatement(var_2_0, var_2_1)
		end
	end

	function var_1_9.resetRegisters(arg_2_0)
		arg_2_0.registers = {}
	end

	function var_1_9.pos(arg_2_0, arg_2_1)
		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.posVar)

		return var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.posVar)
	end

	function var_1_9.posAssignment(arg_2_0, arg_2_1)
		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.posVar)

		return var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, arg_2_0.posVar)
	end

	function var_1_9.args(arg_2_0, arg_2_1)
		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.argsVar)

		return var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.argsVar)
	end

	function var_1_9.unpack(arg_2_0, arg_2_1)
		arg_2_1:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.unpackVar)

		return var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.unpackVar)
	end

	function var_1_9.env(arg_2_0, arg_2_1)
		arg_2_1:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.envVar)

		return var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.envVar)
	end

	function var_1_9.jmp(arg_2_0, arg_2_1, arg_2_2)
		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.posVar)

		return var_1_10.AssignmentStatement({
			var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, arg_2_0.posVar),
		}, {
			arg_2_2,
		})
	end

	function var_1_9.setPos(arg_2_0, arg_2_1, arg_2_2)
		if not arg_2_2 then
			local var_2_0 = var_1_10.IndexExpression(arg_2_0:env(arg_2_1), var_1_15.randomStringNode(math.random(12, 14)))

			arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.posVar)

			return var_1_10.AssignmentStatement({
				var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, arg_2_0.posVar),
			}, {
				var_2_0,
			})
		end

		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.posVar)

		return var_1_10.AssignmentStatement({
			var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, arg_2_0.posVar),
		}, {
			var_1_10.NumberExpression(arg_2_2) or var_1_10.NilExpression(),
		})
	end

	function var_1_9.setReturn(arg_2_0, arg_2_1, arg_2_2)
		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.returnVar)

		return var_1_10.AssignmentStatement({
			var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, arg_2_0.returnVar),
		}, {
			arg_2_2,
		})
	end

	function var_1_9.getReturn(arg_2_0, arg_2_1)
		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.returnVar)

		return var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.returnVar)
	end

	function var_1_9.returnAssignment(arg_2_0, arg_2_1)
		arg_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.returnVar)

		return var_1_10.AssignmentVariable(arg_2_0.containerFuncScope, arg_2_0.returnVar)
	end

	function var_1_9.setUpvalueMember(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
		arg_2_1:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesTable)

		if arg_2_4 then
			return arg_2_4(var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesTable), arg_2_2), arg_2_3)
		end

		return var_1_10.AssignmentStatement({
			var_1_10.AssignmentIndexing(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesTable), arg_2_2),
		}, {
			arg_2_3,
		})
	end

	function var_1_9.getUpvalueMember(arg_2_0, arg_2_1, arg_2_2)
		arg_2_1:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.upvaluesTable)

		return var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.upvaluesTable), arg_2_2)
	end

	function var_1_9.compileTopNode(arg_2_0, arg_2_1)
		local var_2_0 = arg_2_0:createBlock()
		local var_2_1 = var_2_0.scope

		arg_2_0.startBlockId = var_2_0.id

		arg_2_0:setActiveBlock(var_2_0)

		local var_2_2 = var_1_16({
			var_1_17.AssignmentVariable,
			var_1_17.VariableExpression,
			var_1_17.FunctionDeclaration,
			var_1_17.LocalFunctionDeclaration,
		})
		local var_2_3 = var_1_16({
			var_1_17.FunctionDeclaration,
			var_1_17.LocalFunctionDeclaration,
			var_1_17.FunctionLiteralExpression,
			var_1_17.TopNode,
		})

		var_1_14(arg_2_1, function(arg_3_0, arg_3_1)
			if arg_3_0.kind == var_1_17.Block then
				arg_3_0.scope.__depth = arg_3_1.functionData.depth
			end

			if var_2_2[arg_3_0.kind] and not arg_3_0.scope.isGlobal and arg_3_0.scope.__depth < arg_3_1.functionData.depth and not arg_2_0:isUpvalue(arg_3_0.scope, arg_3_0.id) then
				arg_2_0:makeUpvalue(arg_3_0.scope, arg_3_0.id)
			end
		end, nil, nil)

		arg_2_0.varargReg = arg_2_0:allocRegister(true)

		var_2_1:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.argsVar)
		var_2_1:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.selectVar)
		var_2_1:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.unpackVar)
		arg_2_0:addStatement(arg_2_0:setRegister(var_2_1, arg_2_0.varargReg, var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.argsVar)), {
			arg_2_0.varargReg,
		}, {}, false)
		arg_2_0:compileBlock(arg_2_1.body, 0)

		if arg_2_0.activeBlock.advanceToNextBlock then
			arg_2_0:addStatement(arg_2_0:setPos(arg_2_0.activeBlock.scope, nil), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:addStatement(arg_2_0:setReturn(arg_2_0.activeBlock.scope, var_1_10.TableConstructorExpression({})), {
				arg_2_0.RETURN_REGISTER,
			}, {}, false)

			arg_2_0.activeBlock.advanceToNextBlock = false
		end

		arg_2_0:resetRegisters()
	end

	function var_1_9.compileFunction(arg_2_0, arg_2_1, arg_2_2)
		arg_2_2 = arg_2_2 + 1

		local var_2_0 = arg_2_0.activeBlock
		local var_2_1 = arg_2_0.varargReg

		arg_2_0.varargReg = nil

		local var_2_2 = {}
		local var_2_3 = {}
		local var_2_4 = {}
		local var_2_5 = arg_2_0.getUpvalueId

		function arg_2_0.getUpvalueId(arg_3_0, arg_3_1, arg_3_2)
			if not var_2_3[arg_3_1] then
				var_2_3[arg_3_1] = {}
			end

			if var_2_3[arg_3_1][arg_3_2] then
				return var_2_3[arg_3_1][arg_3_2]
			end

			local var_3_0 = arg_3_0.scopeFunctionDepths[arg_3_1]
			local var_3_1

			if var_3_0 == arg_2_2 then
				var_2_0.scope:addReferenceToHigherScope(arg_3_0.scope, arg_3_0.allocUpvalFunction)

				var_3_1 = var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_3_0.scope, arg_3_0.allocUpvalFunction), {})
			elseif var_3_0 == arg_2_2 - 1 then
				local var_3_2 = arg_3_0:getVarRegister(arg_3_1, arg_3_2, var_3_0, nil)

				var_3_1 = arg_3_0:register(var_2_0.scope, var_3_2)

				table.insert(var_2_4, var_3_2)
			else
				local var_3_3 = var_2_5(arg_3_0, arg_3_1, arg_3_2)

				var_2_0.scope:addReferenceToHigherScope(arg_3_0.containerFuncScope, arg_3_0.currentUpvaluesVar)

				var_3_1 = var_1_10.IndexExpression(var_1_10.VariableExpression(arg_3_0.containerFuncScope, arg_3_0.currentUpvaluesVar), var_1_10.NumberExpression(var_3_3))
			end

			table.insert(var_2_2, var_1_10.TableEntry(var_3_1))

			local var_3_4 = #var_2_2

			var_2_3[arg_3_1][arg_3_2] = var_3_4

			return var_3_4
		end

		local var_2_6 = arg_2_0:createBlock()

		arg_2_0:setActiveBlock(var_2_6)

		local var_2_7 = arg_2_0.activeBlock.scope

		arg_2_0:pushRegisterUsageInfo()

		for iter_2_0, iter_2_1 in ipairs(arg_2_1.args) do
			if iter_2_1.kind == var_1_17.VariableExpression then
				if arg_2_0:isUpvalue(iter_2_1.scope, iter_2_1.id) then
					var_2_7:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.allocUpvalFunction)

					local var_2_8 = arg_2_0:getVarRegister(iter_2_1.scope, iter_2_1.id, arg_2_2, nil)

					arg_2_0:addStatement(arg_2_0:setRegister(var_2_7, var_2_8, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.allocUpvalFunction), {})), {
						var_2_8,
					}, {}, false)
					arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_7, arg_2_0:register(var_2_7, var_2_8), var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.argsVar), var_1_10.NumberExpression(iter_2_0))), {}, {
						var_2_8,
					}, true)
				else
					local var_2_9 = arg_2_0:getVarRegister(iter_2_1.scope, iter_2_1.id, arg_2_2, nil)

					var_2_7:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.argsVar)
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_7, var_2_9, var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.argsVar), var_1_10.NumberExpression(iter_2_0))), {
						var_2_9,
					}, {}, false)
				end
			else
				arg_2_0.varargReg = arg_2_0:allocRegister(true)

				var_2_7:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.argsVar)
				var_2_7:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.selectVar)
				var_2_7:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.unpackVar)
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_7, arg_2_0.varargReg, var_1_10.TableConstructorExpression({
					var_1_10.TableEntry(var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.selectVar), {
						var_1_10.NumberExpression(iter_2_0),
						var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.unpackVar), {
							var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.argsVar),
						}),
					})),
				})), {
					arg_2_0.varargReg,
				}, {}, false)
			end
		end

		arg_2_0:compileBlock(arg_2_1.body, arg_2_2)

		if arg_2_0.activeBlock.advanceToNextBlock then
			arg_2_0:addStatement(arg_2_0:setPos(arg_2_0.activeBlock.scope, nil), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:addStatement(arg_2_0:setReturn(arg_2_0.activeBlock.scope, var_1_10.TableConstructorExpression({})), {
				arg_2_0.RETURN_REGISTER,
			}, {}, false)

			arg_2_0.activeBlock.advanceToNextBlock = false
		end

		if arg_2_0.varargReg then
			arg_2_0:freeRegister(arg_2_0.varargReg, true)
		end

		arg_2_0.varargReg = var_2_1
		arg_2_0.getUpvalueId = var_2_5

		arg_2_0:popRegisterUsageInfo()
		arg_2_0:setActiveBlock(var_2_0)

		local var_2_10 = arg_2_0.activeBlock.scope
		local var_2_11 = arg_2_0:allocRegister(false)
		local var_2_12 = #arg_2_1.args > 0 and arg_2_1.args[#arg_2_1.args].kind == var_1_17.VarargExpression
		local var_2_13

		if var_2_12 then
			var_2_10:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.createVarargClosureVar)

			var_2_13 = var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.createVarargClosureVar), {
				var_1_10.NumberExpression(var_2_6.id),
				var_1_10.TableConstructorExpression(var_2_2),
			})
		else
			local var_2_14, var_2_15 = arg_2_0:getCreateClosureVar(#arg_2_1.args + math.random(0, 5))

			var_2_10:addReferenceToHigherScope(var_2_14, var_2_15)

			var_2_13 = var_1_10.FunctionCallExpression(var_1_10.VariableExpression(var_2_14, var_2_15), {
				var_1_10.NumberExpression(var_2_6.id),
				var_1_10.TableConstructorExpression(var_2_2),
			})
		end

		arg_2_0:addStatement(arg_2_0:setRegister(var_2_10, var_2_11, var_2_13), {
			var_2_11,
		}, var_2_4, false)

		return var_2_11
	end

	function var_1_9.compileBlock(arg_2_0, arg_2_1, arg_2_2)
		for iter_2_0, iter_2_1 in ipairs(arg_2_1.statements) do
			arg_2_0:compileStatement(iter_2_1, arg_2_2)
		end

		local var_2_0 = arg_2_0.activeBlock.scope

		for iter_2_2, iter_2_3 in ipairs(arg_2_1.scope.variables) do
			local var_2_1 = arg_2_0:getVarRegister(arg_2_1.scope, iter_2_2, arg_2_2, nil)

			if arg_2_0:isUpvalue(arg_2_1.scope, iter_2_2) then
				var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.freeUpvalueFunc)
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_1, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.freeUpvalueFunc), {
					arg_2_0:register(var_2_0, var_2_1),
				})), {
					var_2_1,
				}, {
					var_2_1,
				}, false)
			else
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_1, var_1_10.NilExpression()), {
					var_2_1,
				}, {}, false)
			end

			arg_2_0:freeRegister(var_2_1, true)
		end
	end

	function var_1_9.compileStatement(arg_2_0, arg_2_1, arg_2_2)
		local var_2_0 = arg_2_0.activeBlock.scope

		if arg_2_1.kind == var_1_17.ReturnStatement then
			local var_2_1 = {}
			local var_2_2 = {}

			for iter_2_0, iter_2_1 in ipairs(arg_2_1.args) do
				if iter_2_0 == #arg_2_1.args and (iter_2_1.kind == var_1_17.FunctionCallExpression or iter_2_1.kind == var_1_17.PassSelfFunctionCallExpression or iter_2_1.kind == var_1_17.VarargExpression) then
					local var_2_3 = arg_2_0:compileExpression(iter_2_1, arg_2_2, arg_2_0.RETURN_ALL)[1]

					table.insert(var_2_1, var_1_10.TableEntry(var_1_10.FunctionCallExpression(arg_2_0:unpack(var_2_0), {
						arg_2_0:register(var_2_0, var_2_3),
					})))
					table.insert(var_2_2, var_2_3)
				else
					local var_2_4 = arg_2_0:compileExpression(iter_2_1, arg_2_2, 1)[1]

					table.insert(var_2_1, var_1_10.TableEntry(arg_2_0:register(var_2_0, var_2_4)))
					table.insert(var_2_2, var_2_4)
				end
			end

			for iter_2_2, iter_2_3 in ipairs(var_2_2) do
				arg_2_0:freeRegister(iter_2_3, false)
			end

			arg_2_0:addStatement(arg_2_0:setReturn(var_2_0, var_1_10.TableConstructorExpression(var_2_1)), {
				arg_2_0.RETURN_REGISTER,
			}, var_2_2, false)
			arg_2_0:addStatement(arg_2_0:setPos(arg_2_0.activeBlock.scope, nil), {
				arg_2_0.POS_REGISTER,
			}, {}, false)

			arg_2_0.activeBlock.advanceToNextBlock = false

			return
		end

		if arg_2_1.kind == var_1_17.LocalVariableDeclaration then
			local var_2_5 = {}

			for iter_2_4, iter_2_5 in ipairs(arg_2_1.expressions) do
				if iter_2_4 == #arg_2_1.expressions and #arg_2_1.ids > #arg_2_1.expressions then
					local var_2_6 = arg_2_0:compileExpression(iter_2_5, arg_2_2, #arg_2_1.ids - #arg_2_1.expressions + 1)

					for iter_2_6, iter_2_7 in ipairs(var_2_6) do
						table.insert(var_2_5, iter_2_7)
					end
				elseif arg_2_1.ids[iter_2_4] or iter_2_5.kind == var_1_17.FunctionCallExpression or iter_2_5.kind == var_1_17.PassSelfFunctionCallExpression then
					local var_2_7 = arg_2_0:compileExpression(iter_2_5, arg_2_2, 1)[1]

					table.insert(var_2_5, var_2_7)
				end
			end

			if #var_2_5 == 0 then
				for iter_2_8 = 1, #arg_2_1.ids do
					table.insert(var_2_5, arg_2_0:compileExpression(var_1_10.NilExpression(), arg_2_2, 1)[1])
				end
			end

			for iter_2_9, iter_2_10 in ipairs(arg_2_1.ids) do
				if var_2_5[iter_2_9] then
					if arg_2_0:isUpvalue(arg_2_1.scope, iter_2_10) then
						local var_2_8 = arg_2_0:getVarRegister(arg_2_1.scope, iter_2_10, arg_2_2)
						local var_2_9 = arg_2_0:getVarRegister(arg_2_1.scope, iter_2_10, arg_2_2, nil)

						var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.allocUpvalFunction)
						arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_9, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.allocUpvalFunction), {})), {
							var_2_9,
						}, {}, false)
						arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, arg_2_0:register(var_2_0, var_2_9), arg_2_0:register(var_2_0, var_2_5[iter_2_9])), {}, {
							var_2_9,
							var_2_5[iter_2_9],
						}, true)
						arg_2_0:freeRegister(var_2_5[iter_2_9], false)
					else
						local var_2_10 = arg_2_0:getVarRegister(arg_2_1.scope, iter_2_10, arg_2_2, var_2_5[iter_2_9])

						arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_0, {
							var_2_10,
						}, {
							var_2_5[iter_2_9],
						}), {
							var_2_10,
						}, {
							var_2_5[iter_2_9],
						}, false)
						arg_2_0:freeRegister(var_2_5[iter_2_9], false)
					end
				end
			end

			if not arg_2_0.scopeFunctionDepths[arg_2_1.scope] then
				arg_2_0.scopeFunctionDepths[arg_2_1.scope] = arg_2_2
			end

			return
		end

		if arg_2_1.kind == var_1_17.FunctionCallStatement then
			local var_2_11 = arg_2_0:compileExpression(arg_2_1.base, arg_2_2, 1)[1]
			local var_2_12 = arg_2_0:allocRegister(false)
			local var_2_13 = {}
			local var_2_14 = {}

			for iter_2_11, iter_2_12 in ipairs(arg_2_1.args) do
				if iter_2_11 == #arg_2_1.args and (iter_2_12.kind == var_1_17.FunctionCallExpression or iter_2_12.kind == var_1_17.PassSelfFunctionCallExpression or iter_2_12.kind == var_1_17.VarargExpression) then
					local var_2_15 = arg_2_0:compileExpression(iter_2_12, arg_2_2, arg_2_0.RETURN_ALL)[1]

					table.insert(var_2_14, var_1_10.FunctionCallExpression(arg_2_0:unpack(var_2_0), {
						arg_2_0:register(var_2_0, var_2_15),
					}))
					table.insert(var_2_13, var_2_15)
				else
					local var_2_16 = arg_2_0:compileExpression(iter_2_12, arg_2_2, 1)[1]

					table.insert(var_2_14, arg_2_0:register(var_2_0, var_2_16))
					table.insert(var_2_13, var_2_16)
				end
			end

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_12, var_1_10.FunctionCallExpression(arg_2_0:register(var_2_0, var_2_11), var_2_14)), {
				var_2_12,
			}, {
				var_2_11,
				var_1_18(var_2_13),
			}, true)
			arg_2_0:freeRegister(var_2_11, false)
			arg_2_0:freeRegister(var_2_12, false)

			for iter_2_13, iter_2_14 in ipairs(var_2_13) do
				arg_2_0:freeRegister(iter_2_14, false)
			end

			return
		end

		if arg_2_1.kind == var_1_17.PassSelfFunctionCallStatement then
			local var_2_17 = arg_2_0:compileExpression(arg_2_1.base, arg_2_2, 1)[1]
			local var_2_18 = arg_2_0:allocRegister(false)
			local var_2_19 = {
				arg_2_0:register(var_2_0, var_2_17),
			}
			local var_2_20 = {
				var_2_17,
			}

			for iter_2_15, iter_2_16 in ipairs(arg_2_1.args) do
				if iter_2_15 == #arg_2_1.args and (iter_2_16.kind == var_1_17.FunctionCallExpression or iter_2_16.kind == var_1_17.PassSelfFunctionCallExpression or iter_2_16.kind == var_1_17.VarargExpression) then
					local var_2_21 = arg_2_0:compileExpression(iter_2_16, arg_2_2, arg_2_0.RETURN_ALL)[1]

					table.insert(var_2_19, var_1_10.FunctionCallExpression(arg_2_0:unpack(var_2_0), {
						arg_2_0:register(var_2_0, var_2_21),
					}))
					table.insert(var_2_20, var_2_21)
				else
					local var_2_22 = arg_2_0:compileExpression(iter_2_16, arg_2_2, 1)[1]

					table.insert(var_2_19, arg_2_0:register(var_2_0, var_2_22))
					table.insert(var_2_20, var_2_22)
				end
			end

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_18, var_1_10.StringExpression(arg_2_1.passSelfFunctionName)), {
				var_2_18,
			}, {}, false)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_18, var_1_10.IndexExpression(arg_2_0:register(var_2_0, var_2_17), arg_2_0:register(var_2_0, var_2_18))), {
				var_2_18,
			}, {
				var_2_18,
				var_2_17,
			}, false)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_18, var_1_10.FunctionCallExpression(arg_2_0:register(var_2_0, var_2_18), var_2_19)), {
				var_2_18,
			}, {
				var_2_18,
				var_1_18(var_2_20),
			}, true)
			arg_2_0:freeRegister(var_2_18, false)

			for iter_2_17, iter_2_18 in ipairs(var_2_20) do
				arg_2_0:freeRegister(iter_2_18, false)
			end

			return
		end

		if arg_2_1.kind == var_1_17.LocalFunctionDeclaration then
			if arg_2_0:isUpvalue(arg_2_1.scope, arg_2_1.id) then
				local var_2_23 = arg_2_0:getVarRegister(arg_2_1.scope, arg_2_1.id, arg_2_2, nil)

				var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.allocUpvalFunction)
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_23, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.allocUpvalFunction), {})), {
					var_2_23,
				}, {}, false)

				local var_2_24 = arg_2_0:compileFunction(arg_2_1, arg_2_2)

				arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, arg_2_0:register(var_2_0, var_2_23), arg_2_0:register(var_2_0, var_2_24)), {}, {
					var_2_23,
					var_2_24,
				}, true)
				arg_2_0:freeRegister(var_2_24, false)
			else
				local var_2_25 = arg_2_0:compileFunction(arg_2_1, arg_2_2)
				local var_2_26 = arg_2_0:getVarRegister(arg_2_1.scope, arg_2_1.id, arg_2_2, var_2_25)

				arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_0, {
					var_2_26,
				}, {
					var_2_25,
				}), {
					var_2_26,
				}, {
					var_2_25,
				}, false)
				arg_2_0:freeRegister(var_2_25, false)
			end

			return
		end

		if arg_2_1.kind == var_1_17.FunctionDeclaration then
			local var_2_27 = arg_2_0:compileFunction(arg_2_1, arg_2_2)

			if #arg_2_1.indices > 0 then
				local var_2_28

				if arg_2_1.scope.isGlobal then
					var_2_28 = arg_2_0:allocRegister(false)

					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_28, var_1_10.StringExpression(arg_2_1.scope:getVariableName(arg_2_1.id))), {
						var_2_28,
					}, {}, false)
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_28, var_1_10.IndexExpression(arg_2_0:env(var_2_0), arg_2_0:register(var_2_0, var_2_28))), {
						var_2_28,
					}, {
						var_2_28,
					}, true)
				elseif arg_2_0.scopeFunctionDepths[arg_2_1.scope] == arg_2_2 then
					if arg_2_0:isUpvalue(arg_2_1.scope, arg_2_1.id) then
						var_2_28 = arg_2_0:allocRegister(false)

						local var_2_29 = arg_2_0:getVarRegister(arg_2_1.scope, arg_2_1.id, arg_2_2)

						arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_28, arg_2_0:getUpvalueMember(var_2_0, arg_2_0:register(var_2_0, var_2_29))), {
							var_2_28,
						}, {
							var_2_29,
						}, true)
					else
						var_2_28 = arg_2_0:getVarRegister(arg_2_1.scope, arg_2_1.id, arg_2_2, var_2_27)
					end
				else
					var_2_28 = arg_2_0:allocRegister(false)

					local var_2_30 = arg_2_0:getUpvalueId(arg_2_1.scope, arg_2_1.id)

					var_2_0:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar)
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_28, arg_2_0:getUpvalueMember(var_2_0, var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar), var_1_10.NumberExpression(var_2_30)))), {
						var_2_28,
					}, {}, true)
				end

				for iter_2_19 = 1, #arg_2_1.indices - 1 do
					local var_2_31 = arg_2_1.indices[iter_2_19]
					local var_2_32 = arg_2_0:compileExpression(var_1_10.StringExpression(var_2_31), arg_2_2, 1)[1]
					local var_2_33 = var_2_28

					var_2_28 = arg_2_0:allocRegister(false)

					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_28, var_1_10.IndexExpression(arg_2_0:register(var_2_0, var_2_33), arg_2_0:register(var_2_0, var_2_32))), {
						var_2_28,
					}, {
						var_2_28,
						var_2_32,
					}, false)
					arg_2_0:freeRegister(var_2_33, false)
					arg_2_0:freeRegister(var_2_32, false)
				end

				local var_2_34 = arg_2_1.indices[#arg_2_1.indices]
				local var_2_35 = arg_2_0:compileExpression(var_1_10.StringExpression(var_2_34), arg_2_2, 1)[1]

				arg_2_0:addStatement(var_1_10.AssignmentStatement({
					var_1_10.AssignmentIndexing(arg_2_0:register(var_2_0, var_2_28), arg_2_0:register(var_2_0, var_2_35)),
				}, {
					arg_2_0:register(var_2_0, var_2_27),
				}), {}, {
					var_2_28,
					var_2_35,
					var_2_27,
				}, true)
				arg_2_0:freeRegister(var_2_35, false)
				arg_2_0:freeRegister(var_2_28, false)
				arg_2_0:freeRegister(var_2_27, false)

				return
			end

			if arg_2_1.scope.isGlobal then
				local var_2_36 = arg_2_0:allocRegister(false)

				arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_36, var_1_10.StringExpression(arg_2_1.scope:getVariableName(arg_2_1.id))), {
					var_2_36,
				}, {}, false)
				arg_2_0:addStatement(var_1_10.AssignmentStatement({
					var_1_10.AssignmentIndexing(arg_2_0:env(var_2_0), arg_2_0:register(var_2_0, var_2_36)),
				}, {
					arg_2_0:register(var_2_0, var_2_27),
				}), {}, {
					var_2_36,
					var_2_27,
				}, true)
				arg_2_0:freeRegister(var_2_36, false)
			elseif arg_2_0.scopeFunctionDepths[arg_2_1.scope] == arg_2_2 then
				if arg_2_0:isUpvalue(arg_2_1.scope, arg_2_1.id) then
					local var_2_37 = arg_2_0:getVarRegister(arg_2_1.scope, arg_2_1.id, arg_2_2)

					arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, arg_2_0:register(var_2_0, var_2_37), arg_2_0:register(var_2_0, var_2_27)), {}, {
						var_2_37,
						var_2_27,
					}, true)
				else
					local var_2_38 = arg_2_0:getVarRegister(arg_2_1.scope, arg_2_1.id, arg_2_2, var_2_27)

					if var_2_38 ~= var_2_27 then
						arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_38, arg_2_0:register(var_2_0, var_2_27)), {
							var_2_38,
						}, {
							var_2_27,
						}, false)
					end
				end
			else
				local var_2_39 = arg_2_0:getUpvalueId(arg_2_1.scope, arg_2_1.id)

				var_2_0:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar)
				arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar), var_1_10.NumberExpression(var_2_39)), arg_2_0:register(var_2_0, var_2_27)), {}, {
					var_2_27,
				}, true)
			end

			arg_2_0:freeRegister(var_2_27, false)

			return
		end

		if arg_2_1.kind == var_1_17.AssignmentStatement then
			local var_2_40 = {}
			local var_2_41 = {}

			for iter_2_20, iter_2_21 in ipairs(arg_2_1.lhs) do
				if iter_2_21.kind == var_1_17.AssignmentIndexing then
					var_2_41[iter_2_20] = {
						base = arg_2_0:compileExpression(iter_2_21.base, arg_2_2, 1)[1],
						index = arg_2_0:compileExpression(iter_2_21.index, arg_2_2, 1)[1],
					}
				end
			end

			for iter_2_22, iter_2_23 in ipairs(arg_2_1.rhs) do
				if iter_2_22 == #arg_2_1.rhs and #arg_2_1.lhs > #arg_2_1.rhs then
					local var_2_42 = arg_2_0:compileExpression(iter_2_23, arg_2_2, #arg_2_1.lhs - #arg_2_1.rhs + 1)

					for iter_2_24, iter_2_25 in ipairs(var_2_42) do
						if arg_2_0:isVarRegister(iter_2_25) then
							local var_2_43 = iter_2_25

							iter_2_25 = arg_2_0:allocRegister(false)

							arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_0, {
								iter_2_25,
							}, {
								var_2_43,
							}), {
								iter_2_25,
							}, {
								var_2_43,
							}, false)
						end

						table.insert(var_2_40, iter_2_25)
					end
				elseif arg_2_1.lhs[iter_2_22] or iter_2_23.kind == var_1_17.FunctionCallExpression or iter_2_23.kind == var_1_17.PassSelfFunctionCallExpression then
					local var_2_44 = arg_2_0:compileExpression(iter_2_23, arg_2_2, 1)[1]

					if arg_2_0:isVarRegister(var_2_44) then
						local var_2_45 = var_2_44

						var_2_44 = arg_2_0:allocRegister(false)

						arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_0, {
							var_2_44,
						}, {
							var_2_45,
						}), {
							var_2_44,
						}, {
							var_2_45,
						}, false)
					end

					table.insert(var_2_40, var_2_44)
				end
			end

			for iter_2_26, iter_2_27 in ipairs(arg_2_1.lhs) do
				if iter_2_27.kind == var_1_17.AssignmentVariable then
					if iter_2_27.scope.isGlobal then
						local var_2_46 = arg_2_0:allocRegister(false)

						arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_46, var_1_10.StringExpression(iter_2_27.scope:getVariableName(iter_2_27.id))), {
							var_2_46,
						}, {}, false)
						arg_2_0:addStatement(var_1_10.AssignmentStatement({
							var_1_10.AssignmentIndexing(arg_2_0:env(var_2_0), arg_2_0:register(var_2_0, var_2_46)),
						}, {
							arg_2_0:register(var_2_0, var_2_40[iter_2_26]),
						}), {}, {
							var_2_46,
							var_2_40[iter_2_26],
						}, true)
						arg_2_0:freeRegister(var_2_46, false)
					elseif arg_2_0.scopeFunctionDepths[iter_2_27.scope] == arg_2_2 then
						if arg_2_0:isUpvalue(iter_2_27.scope, iter_2_27.id) then
							local var_2_47 = arg_2_0:getVarRegister(iter_2_27.scope, iter_2_27.id, arg_2_2)

							arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, arg_2_0:register(var_2_0, var_2_47), arg_2_0:register(var_2_0, var_2_40[iter_2_26])), {}, {
								var_2_47,
								var_2_40[iter_2_26],
							}, true)
						else
							local var_2_48 = arg_2_0:getVarRegister(iter_2_27.scope, iter_2_27.id, arg_2_2, var_2_40[iter_2_26])

							if var_2_48 ~= var_2_40[iter_2_26] then
								arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_48, arg_2_0:register(var_2_0, var_2_40[iter_2_26])), {
									var_2_48,
								}, {
									var_2_40[iter_2_26],
								}, false)
							end
						end
					else
						local var_2_49 = arg_2_0:getUpvalueId(iter_2_27.scope, iter_2_27.id)

						var_2_0:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar)
						arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar), var_1_10.NumberExpression(var_2_49)), arg_2_0:register(var_2_0, var_2_40[iter_2_26])), {}, {
							var_2_40[iter_2_26],
						}, true)
					end
				elseif iter_2_27.kind == var_1_17.AssignmentIndexing then
					local var_2_50 = var_2_41[iter_2_26].base
					local var_2_51 = var_2_41[iter_2_26].index

					arg_2_0:addStatement(var_1_10.AssignmentStatement({
						var_1_10.AssignmentIndexing(arg_2_0:register(var_2_0, var_2_50), arg_2_0:register(var_2_0, var_2_51)),
					}, {
						arg_2_0:register(var_2_0, var_2_40[iter_2_26]),
					}), {}, {
						var_2_40[iter_2_26],
						var_2_50,
						var_2_51,
					}, true)
					arg_2_0:freeRegister(var_2_40[iter_2_26], false)
					arg_2_0:freeRegister(var_2_50, false)
					arg_2_0:freeRegister(var_2_51, false)
				else
					error(string.format("Invalid Assignment lhs: %s", arg_2_1.lhs))
				end
			end

			return
		end

		if arg_2_1.kind == var_1_17.IfStatement then
			local var_2_52 = arg_2_0:compileExpression(arg_2_1.condition, arg_2_2, 1)[1]
			local var_2_53 = arg_2_0:createBlock()
			local var_2_54

			if arg_2_1.elsebody or #arg_2_1.elseifs > 0 then
				var_2_54 = arg_2_0:createBlock()
			else
				var_2_54 = var_2_53
			end

			local var_2_55 = arg_2_0:createBlock()

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, arg_2_0.POS_REGISTER, var_1_10.OrExpression(var_1_10.AndExpression(arg_2_0:register(var_2_0, var_2_52), var_1_10.NumberExpression(var_2_55.id)), var_1_10.NumberExpression(var_2_54.id))), {
				arg_2_0.POS_REGISTER,
			}, {
				var_2_52,
			}, false)
			arg_2_0:freeRegister(var_2_52, false)
			arg_2_0:setActiveBlock(var_2_55)

			var_2_0 = var_2_55.scope

			arg_2_0:compileBlock(arg_2_1.body, arg_2_2)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, arg_2_0.POS_REGISTER, var_1_10.NumberExpression(var_2_53.id)), {
				arg_2_0.POS_REGISTER,
			}, {}, false)

			for iter_2_28, iter_2_29 in ipairs(arg_2_1.elseifs) do
				arg_2_0:setActiveBlock(var_2_54)

				local var_2_56 = arg_2_0:compileExpression(iter_2_29.condition, arg_2_2, 1)[1]
				local var_2_57 = arg_2_0:createBlock()

				if arg_2_1.elsebody or iter_2_28 < #arg_2_1.elseifs then
					var_2_54 = arg_2_0:createBlock()
				else
					var_2_54 = var_2_53
				end

				local var_2_58 = arg_2_0.activeBlock.scope

				arg_2_0:addStatement(arg_2_0:setRegister(var_2_58, arg_2_0.POS_REGISTER, var_1_10.OrExpression(var_1_10.AndExpression(arg_2_0:register(var_2_58, var_2_56), var_1_10.NumberExpression(var_2_57.id)), var_1_10.NumberExpression(var_2_54.id))), {
					arg_2_0.POS_REGISTER,
				}, {
					var_2_56,
				}, false)
				arg_2_0:freeRegister(var_2_56, false)
				arg_2_0:setActiveBlock(var_2_57)

				local var_2_59 = var_2_57.scope

				arg_2_0:compileBlock(iter_2_29.body, arg_2_2)
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_59, arg_2_0.POS_REGISTER, var_1_10.NumberExpression(var_2_53.id)), {
					arg_2_0.POS_REGISTER,
				}, {}, false)
			end

			if arg_2_1.elsebody then
				arg_2_0:setActiveBlock(var_2_54)
				arg_2_0:compileBlock(arg_2_1.elsebody, arg_2_2)
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, arg_2_0.POS_REGISTER, var_1_10.NumberExpression(var_2_53.id)), {
					arg_2_0.POS_REGISTER,
				}, {}, false)
			end

			arg_2_0:setActiveBlock(var_2_53)

			return
		end

		if arg_2_1.kind == var_1_17.DoStatement then
			arg_2_0:compileBlock(arg_2_1.body, arg_2_2)

			return
		end

		if arg_2_1.kind == var_1_17.WhileStatement then
			local var_2_60 = arg_2_0:createBlock()
			local var_2_61 = arg_2_0:createBlock()
			local var_2_62 = arg_2_0:createBlock()

			arg_2_1.__start_block = var_2_62
			arg_2_1.__final_block = var_2_61

			arg_2_0:addStatement(arg_2_0:setPos(var_2_0, var_2_62.id), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:setActiveBlock(var_2_62)

			local var_2_63 = arg_2_0.activeBlock.scope
			local var_2_64 = arg_2_0:compileExpression(arg_2_1.condition, arg_2_2, 1)[1]

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_63, arg_2_0.POS_REGISTER, var_1_10.OrExpression(var_1_10.AndExpression(arg_2_0:register(var_2_63, var_2_64), var_1_10.NumberExpression(var_2_60.id)), var_1_10.NumberExpression(var_2_61.id))), {
				arg_2_0.POS_REGISTER,
			}, {
				var_2_64,
			}, false)
			arg_2_0:freeRegister(var_2_64, false)
			arg_2_0:setActiveBlock(var_2_60)

			local var_2_65 = arg_2_0.activeBlock.scope

			arg_2_0:compileBlock(arg_2_1.body, arg_2_2)
			arg_2_0:addStatement(arg_2_0:setPos(var_2_65, var_2_62.id), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:setActiveBlock(var_2_61)

			return
		end

		if arg_2_1.kind == var_1_17.RepeatStatement then
			local var_2_66 = arg_2_0:createBlock()
			local var_2_67 = arg_2_0:createBlock()
			local var_2_68 = arg_2_0:createBlock()

			arg_2_1.__start_block = var_2_68
			arg_2_1.__final_block = var_2_67

			local var_2_69 = arg_2_0:compileExpression(arg_2_1.condition, arg_2_2, 1)[1]

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, arg_2_0.POS_REGISTER, var_1_10.NumberExpression(var_2_66.id)), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:freeRegister(var_2_69, false)
			arg_2_0:setActiveBlock(var_2_66)
			arg_2_0:compileBlock(arg_2_1.body, arg_2_2)

			local var_2_70 = arg_2_0.activeBlock.scope

			arg_2_0:addStatement(arg_2_0:setPos(var_2_70, var_2_68.id), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:setActiveBlock(var_2_68)

			local var_2_71 = arg_2_0.activeBlock.scope
			local var_2_72 = arg_2_0:compileExpression(arg_2_1.condition, arg_2_2, 1)[1]

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_71, arg_2_0.POS_REGISTER, var_1_10.OrExpression(var_1_10.AndExpression(arg_2_0:register(var_2_71, var_2_72), var_1_10.NumberExpression(var_2_67.id)), var_1_10.NumberExpression(var_2_66.id))), {
				arg_2_0.POS_REGISTER,
			}, {
				var_2_72,
			}, false)
			arg_2_0:freeRegister(var_2_72, false)
			arg_2_0:setActiveBlock(var_2_67)

			return
		end

		if arg_2_1.kind == var_1_17.ForStatement then
			local var_2_73 = arg_2_0:createBlock()
			local var_2_74 = arg_2_0:createBlock()
			local var_2_75 = arg_2_0:createBlock()

			arg_2_1.__start_block = var_2_73
			arg_2_1.__final_block = var_2_75

			local var_2_76 = arg_2_0.registers[arg_2_0.POS_REGISTER]

			arg_2_0.registers[arg_2_0.POS_REGISTER] = arg_2_0.VAR_REGISTER

			local var_2_77 = arg_2_0:compileExpression(arg_2_1.initialValue, arg_2_2, 1)[1]
			local var_2_78 = arg_2_0:compileExpression(arg_2_1.finalValue, arg_2_2, 1)[1]
			local var_2_79 = arg_2_0:allocRegister(false)

			arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_0, {
				var_2_79,
			}, {
				var_2_78,
			}), {
				var_2_79,
			}, {
				var_2_78,
			}, false)
			arg_2_0:freeRegister(var_2_78)

			local var_2_80 = arg_2_0:compileExpression(arg_2_1.incrementBy, arg_2_2, 1)[1]
			local var_2_81 = arg_2_0:allocRegister(false)

			arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_0, {
				var_2_81,
			}, {
				var_2_80,
			}), {
				var_2_81,
			}, {
				var_2_80,
			}, false)
			arg_2_0:freeRegister(var_2_80)

			local var_2_82 = arg_2_0:allocRegister(false)

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_82, var_1_10.NumberExpression(0)), {
				var_2_82,
			}, {}, false)

			local var_2_83 = arg_2_0:allocRegister(false)

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_83, var_1_10.LessThanExpression(arg_2_0:register(var_2_0, var_2_81), arg_2_0:register(var_2_0, var_2_82))), {
				var_2_83,
			}, {
				var_2_81,
				var_2_82,
			}, false)
			arg_2_0:freeRegister(var_2_82)

			local var_2_84 = arg_2_0:allocRegister(true)

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_84, var_1_10.SubExpression(arg_2_0:register(var_2_0, var_2_77), arg_2_0:register(var_2_0, var_2_81))), {
				var_2_84,
			}, {
				var_2_77,
				var_2_81,
			}, false)
			arg_2_0:freeRegister(var_2_77)
			arg_2_0:addStatement(arg_2_0:jmp(var_2_0, var_1_10.NumberExpression(var_2_73.id)), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:setActiveBlock(var_2_73)

			var_2_0 = var_2_73.scope

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_84, var_1_10.AddExpression(arg_2_0:register(var_2_0, var_2_84), arg_2_0:register(var_2_0, var_2_81))), {
				var_2_84,
			}, {
				var_2_84,
				var_2_81,
			}, false)

			local var_2_85 = arg_2_0:allocRegister(false)
			local var_2_86 = arg_2_0:allocRegister(false)

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_86, var_1_10.NotExpression(arg_2_0:register(var_2_0, var_2_83))), {
				var_2_86,
			}, {
				var_2_83,
			}, false)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_85, var_1_10.LessThanOrEqualsExpression(arg_2_0:register(var_2_0, var_2_84), arg_2_0:register(var_2_0, var_2_79))), {
				var_2_85,
			}, {
				var_2_84,
				var_2_79,
			}, false)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_85, var_1_10.AndExpression(arg_2_0:register(var_2_0, var_2_86), arg_2_0:register(var_2_0, var_2_85))), {
				var_2_85,
			}, {
				var_2_85,
				var_2_86,
			}, false)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_86, var_1_10.GreaterThanOrEqualsExpression(arg_2_0:register(var_2_0, var_2_84), arg_2_0:register(var_2_0, var_2_79))), {
				var_2_86,
			}, {
				var_2_84,
				var_2_79,
			}, false)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_86, var_1_10.AndExpression(arg_2_0:register(var_2_0, var_2_83), arg_2_0:register(var_2_0, var_2_86))), {
				var_2_86,
			}, {
				var_2_86,
				var_2_83,
			}, false)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_85, var_1_10.OrExpression(arg_2_0:register(var_2_0, var_2_86), arg_2_0:register(var_2_0, var_2_85))), {
				var_2_85,
			}, {
				var_2_85,
				var_2_86,
			}, false)
			arg_2_0:freeRegister(var_2_86)

			local var_2_87 = arg_2_0:compileExpression(var_1_10.NumberExpression(var_2_74.id), arg_2_2, 1)[1]

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, arg_2_0.POS_REGISTER, var_1_10.AndExpression(arg_2_0:register(var_2_0, var_2_85), arg_2_0:register(var_2_0, var_2_87))), {
				arg_2_0.POS_REGISTER,
			}, {
				var_2_85,
				var_2_87,
			}, false)
			arg_2_0:freeRegister(var_2_87)
			arg_2_0:freeRegister(var_2_85)

			local var_2_88 = arg_2_0:compileExpression(var_1_10.NumberExpression(var_2_75.id), arg_2_2, 1)[1]

			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, arg_2_0.POS_REGISTER, var_1_10.OrExpression(arg_2_0:register(var_2_0, arg_2_0.POS_REGISTER), arg_2_0:register(var_2_0, var_2_88))), {
				arg_2_0.POS_REGISTER,
			}, {
				arg_2_0.POS_REGISTER,
				var_2_88,
			}, false)
			arg_2_0:freeRegister(var_2_88)
			arg_2_0:setActiveBlock(var_2_74)

			var_2_0 = var_2_74.scope
			arg_2_0.registers[arg_2_0.POS_REGISTER] = var_2_76

			local var_2_89 = arg_2_0:getVarRegister(arg_2_1.scope, arg_2_1.id, arg_2_2, nil)

			if arg_2_0:isUpvalue(arg_2_1.scope, arg_2_1.id) then
				var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.allocUpvalFunction)
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_89, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.allocUpvalFunction), {})), {
					var_2_89,
				}, {}, false)
				arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, arg_2_0:register(var_2_0, var_2_89), arg_2_0:register(var_2_0, var_2_84)), {}, {
					var_2_89,
					var_2_84,
				}, true)
			else
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_89, arg_2_0:register(var_2_0, var_2_84)), {
					var_2_89,
				}, {
					var_2_84,
				}, false)
			end

			arg_2_0:compileBlock(arg_2_1.body, arg_2_2)
			arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, arg_2_0.POS_REGISTER, var_1_10.NumberExpression(var_2_73.id)), {
				arg_2_0.POS_REGISTER,
			}, {}, false)

			arg_2_0.registers[arg_2_0.POS_REGISTER] = arg_2_0.VAR_REGISTER

			arg_2_0:freeRegister(var_2_79)
			arg_2_0:freeRegister(var_2_83)
			arg_2_0:freeRegister(var_2_81)
			arg_2_0:freeRegister(var_2_84, true)

			arg_2_0.registers[arg_2_0.POS_REGISTER] = var_2_76

			arg_2_0:setActiveBlock(var_2_75)

			return
		end

		if arg_2_1.kind == var_1_17.ForInStatement then
			local var_2_90 = #arg_2_1.expressions
			local var_2_91 = {}

			for iter_2_30, iter_2_31 in ipairs(arg_2_1.expressions) do
				if iter_2_30 == var_2_90 and var_2_90 < 3 then
					local var_2_92 = arg_2_0:compileExpression(iter_2_31, arg_2_2, 4 - var_2_90)

					for iter_2_32 = 1, 4 - var_2_90 do
						table.insert(var_2_91, var_2_92[iter_2_32])
					end
				elseif iter_2_30 <= 3 then
					table.insert(var_2_91, arg_2_0:compileExpression(iter_2_31, arg_2_2, 1)[1])
				else
					arg_2_0:freeRegister(arg_2_0:compileExpression(iter_2_31, arg_2_2, 1)[1], false)
				end
			end

			for iter_2_33, iter_2_34 in ipairs(var_2_91) do
				if iter_2_34 and arg_2_0.registers[iter_2_34] ~= arg_2_0.VAR_REGISTER and iter_2_34 ~= arg_2_0.POS_REGISTER and iter_2_34 ~= arg_2_0.RETURN_REGISTER then
					arg_2_0.registers[iter_2_34] = arg_2_0.VAR_REGISTER
				else
					var_2_91[iter_2_33] = arg_2_0:allocRegister(true)

					arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_0, {
						var_2_91[iter_2_33],
					}, {
						iter_2_34,
					}), {
						var_2_91[iter_2_33],
					}, {
						iter_2_34,
					}, false)
				end
			end

			local var_2_93 = arg_2_0:createBlock()
			local var_2_94 = arg_2_0:createBlock()
			local var_2_95 = arg_2_0:createBlock()

			arg_2_1.__start_block = var_2_93
			arg_2_1.__final_block = var_2_95

			arg_2_0:addStatement(arg_2_0:setPos(var_2_0, var_2_93.id), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:setActiveBlock(var_2_93)

			local var_2_96 = arg_2_0.activeBlock.scope
			local var_2_97 = {}

			for iter_2_35, iter_2_36 in ipairs(arg_2_1.ids) do
				var_2_97[iter_2_35] = arg_2_0:getVarRegister(arg_2_1.scope, iter_2_36, arg_2_2)
			end

			arg_2_0:addStatement(var_1_10.AssignmentStatement({
				arg_2_0:registerAssignment(var_2_96, var_2_91[3]),
				var_2_97[2] and arg_2_0:registerAssignment(var_2_96, var_2_97[2]),
			}, {
				var_1_10.FunctionCallExpression(arg_2_0:register(var_2_96, var_2_91[1]), {
					arg_2_0:register(var_2_96, var_2_91[2]),
					arg_2_0:register(var_2_96, var_2_91[3]),
				}),
			}), {
				var_2_91[3],
				var_2_97[2],
			}, {
				var_2_91[1],
				var_2_91[2],
				var_2_91[3],
			}, true)
			arg_2_0:addStatement(var_1_10.AssignmentStatement({
				arg_2_0:posAssignment(var_2_96),
			}, {
				var_1_10.OrExpression(var_1_10.AndExpression(arg_2_0:register(var_2_96, var_2_91[3]), var_1_10.NumberExpression(var_2_94.id)), var_1_10.NumberExpression(var_2_95.id)),
			}), {
				arg_2_0.POS_REGISTER,
			}, {
				var_2_91[3],
			}, false)
			arg_2_0:setActiveBlock(var_2_94)

			local var_2_98 = arg_2_0.activeBlock.scope

			arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_98, {
				var_2_97[1],
			}, {
				var_2_91[3],
			}), {
				var_2_97[1],
			}, {
				var_2_91[3],
			}, false)

			for iter_2_37 = 3, #var_2_97 do
				arg_2_0:addStatement(arg_2_0:setRegister(var_2_98, var_2_97[iter_2_37], var_1_10.NilExpression()), {
					var_2_97[iter_2_37],
				}, {}, false)
			end

			for iter_2_38, iter_2_39 in ipairs(arg_2_1.ids) do
				if arg_2_0:isUpvalue(arg_2_1.scope, iter_2_39) then
					local var_2_99 = var_2_97[iter_2_38]
					local var_2_100 = arg_2_0:allocRegister(false)

					var_2_98:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.allocUpvalFunction)
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_98, var_2_100, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.allocUpvalFunction), {})), {
						var_2_100,
					}, {}, false)
					arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_98, arg_2_0:register(var_2_98, var_2_100), arg_2_0:register(var_2_98, var_2_99)), {}, {
						var_2_100,
						var_2_99,
					}, true)
					arg_2_0:addStatement(arg_2_0:copyRegisters(var_2_98, {
						var_2_99,
					}, {
						var_2_100,
					}), {
						var_2_99,
					}, {
						var_2_100,
					}, false)
					arg_2_0:freeRegister(var_2_100, false)
				end
			end

			arg_2_0:compileBlock(arg_2_1.body, arg_2_2)
			arg_2_0:addStatement(arg_2_0:setPos(var_2_98, var_2_93.id), {
				arg_2_0.POS_REGISTER,
			}, {}, false)
			arg_2_0:setActiveBlock(var_2_95)

			for iter_2_40, iter_2_41 in ipairs(var_2_91) do
				arg_2_0:freeRegister(var_2_91[iter_2_40], true)
			end

			return
		end

		if arg_2_1.kind == var_1_17.DoStatement then
			arg_2_0:compileBlock(arg_2_1.body, arg_2_2)

			return
		end

		if arg_2_1.kind == var_1_17.BreakStatement then
			local var_2_101 = {}
			local var_2_102

			repeat
				var_2_102 = var_2_102 and var_2_102.parentScope or arg_2_1.scope

				for iter_2_42, iter_2_43 in ipairs(var_2_102.variables) do
					table.insert(var_2_101, {
						scope = var_2_102,
						id = iter_2_42,
					})
				end
			until var_2_102 == arg_2_1.loop.body.scope

			for iter_2_44, iter_2_45 in pairs(var_2_101) do
				local var_2_103 = iter_2_45.scope
				local var_2_104 = iter_2_45.id
				local var_2_105 = arg_2_0:getVarRegister(var_2_103, var_2_104, nil, nil)

				if arg_2_0:isUpvalue(var_2_103, var_2_104) then
					var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.freeUpvalueFunc)
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_105, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.freeUpvalueFunc), {
						arg_2_0:register(var_2_0, var_2_105),
					})), {
						var_2_105,
					}, {
						var_2_105,
					}, false)
				else
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_105, var_1_10.NilExpression()), {
						var_2_105,
					}, {}, false)
				end
			end

			arg_2_0:addStatement(arg_2_0:setPos(var_2_0, arg_2_1.loop.__final_block.id), {
				arg_2_0.POS_REGISTER,
			}, {}, false)

			arg_2_0.activeBlock.advanceToNextBlock = false

			return
		end

		if arg_2_1.kind == var_1_17.ContinueStatement then
			local var_2_106 = {}
			local var_2_107

			repeat
				var_2_107 = var_2_107 and var_2_107.parentScope or arg_2_1.scope

				for iter_2_46, iter_2_47 in pairs(var_2_107.variables) do
					table.insert(var_2_106, {
						scope = var_2_107,
						id = iter_2_46,
					})
				end
			until var_2_107 == arg_2_1.loop.body.scope

			for iter_2_48, iter_2_49 in ipairs(var_2_106) do
				local var_2_108 = iter_2_49.scope
				local var_2_109 = iter_2_49.id
				local var_2_110 = arg_2_0:getVarRegister(var_2_108, var_2_109, nil, nil)

				if arg_2_0:isUpvalue(var_2_108, var_2_109) then
					var_2_0:addReferenceToHigherScope(arg_2_0.scope, arg_2_0.freeUpvalueFunc)
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_110, var_1_10.FunctionCallExpression(var_1_10.VariableExpression(arg_2_0.scope, arg_2_0.freeUpvalueFunc), {
						arg_2_0:register(var_2_0, var_2_110),
					})), {
						var_2_110,
					}, {
						var_2_110,
					}, false)
				else
					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_110, var_1_10.NilExpression()), {
						var_2_110,
					}, {}, false)
				end
			end

			arg_2_0:addStatement(arg_2_0:setPos(var_2_0, arg_2_1.loop.__start_block.id), {
				arg_2_0.POS_REGISTER,
			}, {}, false)

			arg_2_0.activeBlock.advanceToNextBlock = false

			return
		end

		local var_2_111 = {
			[var_1_17.CompoundAddStatement] = var_1_10.CompoundAddStatement,
			[var_1_17.CompoundSubStatement] = var_1_10.CompoundSubStatement,
			[var_1_17.CompoundMulStatement] = var_1_10.CompoundMulStatement,
			[var_1_17.CompoundDivStatement] = var_1_10.CompoundDivStatement,
			[var_1_17.CompoundModStatement] = var_1_10.CompoundModStatement,
			[var_1_17.CompoundPowStatement] = var_1_10.CompoundPowStatement,
			[var_1_17.CompoundConcatStatement] = var_1_10.CompoundConcatStatement,
		}

		if var_2_111[arg_2_1.kind] then
			local var_2_112 = var_2_111[arg_2_1.kind]

			if arg_2_1.lhs.kind == var_1_17.AssignmentIndexing then
				local var_2_113 = arg_2_1.lhs
				local var_2_114 = arg_2_0:compileExpression(var_2_113.base, arg_2_2, 1)[1]
				local var_2_115 = arg_2_0:compileExpression(var_2_113.index, arg_2_2, 1)[1]
				local var_2_116 = arg_2_0:compileExpression(arg_2_1.rhs, arg_2_2, 1)[1]

				arg_2_0:addStatement(var_2_112(var_1_10.AssignmentIndexing(arg_2_0:register(var_2_0, var_2_114), arg_2_0:register(var_2_0, var_2_115)), arg_2_0:register(var_2_0, var_2_116)), {}, {
					var_2_114,
					var_2_115,
					var_2_116,
				}, true)
			else
				local var_2_117 = arg_2_0:compileExpression(arg_2_1.rhs, arg_2_2, 1)[1]
				local var_2_118 = arg_2_1.lhs

				if var_2_118.scope.isGlobal then
					local var_2_119 = arg_2_0:allocRegister(false)

					arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_119, var_1_10.StringExpression(var_2_118.scope:getVariableName(var_2_118.id))), {
						var_2_119,
					}, {}, false)
					arg_2_0:addStatement(var_1_10.AssignmentStatement({
						var_1_10.AssignmentIndexing(arg_2_0:env(var_2_0), arg_2_0:register(var_2_0, var_2_119)),
					}, {
						arg_2_0:register(var_2_0, var_2_117),
					}), {}, {
						var_2_119,
						var_2_117,
					}, true)
					arg_2_0:freeRegister(var_2_119, false)
				elseif arg_2_0.scopeFunctionDepths[var_2_118.scope] == arg_2_2 then
					if arg_2_0:isUpvalue(var_2_118.scope, var_2_118.id) then
						local var_2_120 = arg_2_0:getVarRegister(var_2_118.scope, var_2_118.id, arg_2_2)

						arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, arg_2_0:register(var_2_0, var_2_120), arg_2_0:register(var_2_0, var_2_117), var_2_112), {}, {
							var_2_120,
							var_2_117,
						}, true)
					else
						local var_2_121 = arg_2_0:getVarRegister(var_2_118.scope, var_2_118.id, arg_2_2, var_2_117)

						if var_2_121 ~= var_2_117 then
							arg_2_0:addStatement(arg_2_0:setRegister(var_2_0, var_2_121, arg_2_0:register(var_2_0, var_2_117), var_2_112), {
								var_2_121,
							}, {
								var_2_117,
							}, false)
						end
					end
				else
					local var_2_122 = arg_2_0:getUpvalueId(var_2_118.scope, var_2_118.id)

					var_2_0:addReferenceToHigherScope(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar)
					arg_2_0:addStatement(arg_2_0:setUpvalueMember(var_2_0, var_1_10.IndexExpression(var_1_10.VariableExpression(arg_2_0.containerFuncScope, arg_2_0.currentUpvaluesVar), var_1_10.NumberExpression(var_2_122)), arg_2_0:register(var_2_0, var_2_117), var_2_112), {}, {
						var_2_117,
					}, true)
				end
			end

			return
		end

		var_1_12:error(string.format("%s is not _a compileable statement!", arg_2_1.kind))
	end

	local var_1_19 = "elI9MXNnL1slUQ=="
	local var_1_20 = "Oz8/NGtZYjtDaUkrRkErWloyOyNzUyVycTolSjNqJDQwaE4=bi12PyZmUDh0RiF1"

	function __obfuscatelIIlIlll(arg_2_0, arg_2_1)
		local var_2_0 = var_1_0(arg_2_0, arg_2_1)
		local var_2_1 = var_1_4

		return var_2_0, var_2_1
	end

	return var_1_3(var_1_6(var_1_19, var_1_5), getfenv(0))()
end)()
