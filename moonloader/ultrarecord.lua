local var_0_0 = require("ultrabot_res.ultragui")
local var_0_1 = {
	setting = {
		recordingDelay = 80,
		recordingKey = 76,
	},
}
local var_0_2 = {
	radius,
}
local var_0_3 = {
	reload,
	pause,
	stop,
}
local var_0_4 = {
	workType,
	location,
	colorMain = "a60880",
	loop = false,
	tick = 0,
}

function route_record_or_reproduction()
	while true do
		wait(0)

		if var_0_4.workType ~= "reproduction" and var_0_4.workType == "record" then
			if isKeyJustPressed(var_0_1.setting.recordingKey) then
				local var_1_0 = open_file("w")

				if var_1_0 then
					notify("Начали записывать новый маршрут")

					repeat
						wait(0)

						local var_1_1 = os.clock() * 1000

						if var_1_1 - var_0_4.tick > tonumber(var_0_1.setting.recordingDelay) then
							if var_0_4.location == "incar" then
								if isCharInAnyCar(PLAYER_PED) then
									local var_1_2 = storeCarCharIsInNoSave(PLAYER_PED)
									local var_1_3, var_1_4, var_1_5 = getCarCoordinates(var_1_2)
									local var_1_6 = getCarSpeed(var_1_2)

									var_1_0:write("{" .. var_1_3 .. "}:{" .. var_1_4 .. "}:{" .. var_1_6 .. "}:{nil}\n")
									printStringNow("[UltraRec] ~g~X: " .. math.floor(var_1_3) .. " Y: " .. math.floor(var_1_4) .. " SPEED: " .. math.floor(var_1_6) .. "", 1000)
								else
									break
								end
							else
								local var_1_7, var_1_8, var_1_9 = getCharCoordinates(PLAYER_PED)

								if isButtonPressed(PLAYER_HANDLE, 14) then
									var_1_0:write("{" .. var_1_7 .. "}:{" .. var_1_8 .. "}:{nil}:{jump}\n")

									while isButtonPressed(PLAYER_HANDLE, 14) do
										wait(0)
									end

									wait(600)
								end

								if var_1_1 - var_0_4.tick > tonumber(var_0_1.setting.recordingDelay) then
									if isButtonPressed(PLAYER_HANDLE, 16) then
										var_1_0:write("{" .. var_1_7 .. "}:{" .. var_1_8 .. "}:{sprint}:{nil}\n")
									else
										var_1_0:write("{" .. var_1_7 .. "}:{" .. var_1_8 .. "}:{nil}:{nil}\n")
									end

									printStringNow("[UltraRec] ~g~X: " .. math.floor(var_1_7) .. " Y: " .. math.floor(var_1_8) .. "", 1000)
								end
							end

							var_0_4.tick = os.clock() * 1000
						end
					until isKeyJustPressed(var_0_1.setting.recordingKey)

					notify("Запись маршрута завершена!")
					var_1_0:close()

					var_0_4.location = ""
				end
			end
		elseif var_0_4.workType == "reproduction" and not var_0_4.loop then
			local var_1_10 = read_route_information()

			if var_1_10 then
				for iter_1_0, iter_1_1 in pairs(var_1_10) do
					local var_1_11, var_1_12, var_1_13, var_1_14 = iter_1_1:match("{(.*)}:{(.*)}:{(.*)}:{(.*)}")

					if var_1_11 and var_1_12 and var_1_13 and var_1_14 then
						repeat
							wait(0)
							draw_line(tonumber(var_1_11), tonumber(var_1_12))

							if var_0_4.location == "incar" then
								local var_1_15 = storeCarCharIsInNoSave(PLAYER_PED)

								if iter_1_0 % 2 > 0 then
									local var_1_16, var_1_17, var_1_18 = getCarCoordinates(var_1_15)

									turning_mechanism(tonumber(var_1_11), tonumber(var_1_12), var_1_16, var_1_17, var_1_15)

									if getCarSpeed(var_1_15) < var_1_13 + 0.2 then
										press_gas()
									else
										press_brake()
									end
								else
									break
								end
							else
								setGameKeyState(1, -128)
								set_camera_pos_unfix(tonumber(var_1_11), tonumber(var_1_12))

								if var_1_13 == "sprint" then
									setGameKeyState(16, 255)
								elseif var_1_14 == "jump" then
									setGameKeyState(16, 0)
									setGameKeyState(14, 255)
								end
							end

							if var_0_3.pause then
								repeat
									wait(0)
								until not var_0_3.pause or var_0_3.stop

								var_0_3.pause = false
							end

							if var_0_3.stop or var_0_4.location == "incar" and not isCharInAnyCar(PLAYER_PED) then
								var_0_3.stop = true

								break
							end
						until locateCharOnFoot2d(PLAYER_PED, tonumber(var_1_11), tonumber(var_1_12), var_0_2.radius, var_0_2.radius, false) or locateCharInCar2d(PLAYER_PED, tonumber(var_1_11), tonumber(var_1_12), var_0_2.radius, var_0_2.radius, false)

						if var_0_3.stop then
							var_0_3.stop = false

							break
						end
					end
				end

				var_0_4.location = ""
				var_0_4.workType = ""
			else
				notify("Маршрут не найден!")

				var_0_4.workType = ""
			end
		elseif var_0_4.workType == "reproduction" and var_0_4.loop then
			while var_0_4.loop do
				wait(0)

				local var_1_19 = read_route_information()

				if var_1_19 then
					for iter_1_2, iter_1_3 in pairs(var_1_19) do
						local var_1_20, var_1_21, var_1_22, var_1_23 = iter_1_3:match("{(.*)}:{(.*)}:{(.*)}:{(.*)}")

						if var_1_20 and var_1_21 and var_1_22 and var_1_23 then
							repeat
								wait(0)
								draw_line(tonumber(var_1_20), tonumber(var_1_21))

								if var_0_4.location == "incar" then
									local var_1_24 = storeCarCharIsInNoSave(PLAYER_PED)

									if iter_1_2 % 2 > 0 then
										local var_1_25, var_1_26, var_1_27 = getCarCoordinates(var_1_24)

										turning_mechanism(tonumber(var_1_20), tonumber(var_1_21), var_1_25, var_1_26, var_1_24)

										if getCarSpeed(var_1_24) < var_1_22 + 0.2 then
											press_gas()
										else
											press_brake()
										end
									else
										break
									end
								else
									setGameKeyState(1, -128)
									set_camera_pos_unfix(tonumber(var_1_20), tonumber(var_1_21))

									if var_1_22 == "sprint" then
										setGameKeyState(16, 255)
									elseif var_1_23 == "jump" then
										setGameKeyState(16, 0)
										setGameKeyState(14, 255)
									end
								end

								if var_0_3.pause then
									repeat
										wait(0)
									until not var_0_3.pause or var_0_3.stop

									var_0_3.pause = false
								end

								if var_0_3.stop or var_0_4.location == "incar" and not isCharInAnyCar(PLAYER_PED) then
									var_0_3.stop = true

									break
								end
							until locateCharOnFoot2d(PLAYER_PED, tonumber(var_1_20), tonumber(var_1_21), var_0_2.radius, var_0_2.radius, false) or locateCharInCar2d(PLAYER_PED, tonumber(var_1_20), tonumber(var_1_21), var_0_2.radius, var_0_2.radius, false)

							if var_0_3.stop then
								var_0_3.stop = false

								break
							end
						end
					end

					var_0_4.location = ""
					var_0_4.workType = ""
				else
					notify("Маршрут не найден!")

					var_0_4.workType = ""
				end
			end
		end
	end
end

function turning_mechanism(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4)
	local var_1_0 = math.rad(getHeadingFromVector2d(arg_1_0 - arg_1_2, arg_1_1 - arg_1_3) + math.abs(getCarHeading(arg_1_4) - 360))
	local var_1_1 = getHeadingFromVector2d(math.deg(math.sin(var_1_0)), math.deg(math.cos(var_1_0)))

	if var_1_1 > 180 and var_1_1 < 355 then
		setGameKeyState(0, -128)
	elseif var_1_1 > 5 and var_1_1 <= 180 then
		setGameKeyState(0, 128)
	else
		setGameKeyState(0, 0)
	end
end

function press_gas()
	writeMemory(12006520, 1, 255, false)
end

function press_brake()
	writeMemory(12006500, 1, 255, false)
end

function set_camera_pos_unfix(arg_1_0, arg_1_1)
	local var_1_0, var_1_1, var_1_2 = getActiveCameraCoordinates()

	setCameraPositionUnfixed(0, (getHeadingFromVector2d(arg_1_0 - var_1_0, arg_1_1 - var_1_1) - 90) / 57.2957795)
end

function draw_line(arg_1_0, arg_1_1)
	local var_1_0, var_1_1, var_1_2 = getCharCoordinates(PLAYER_PED)

	if isPointOnScreen(arg_1_0, arg_1_1, var_1_2, 0) then
		local var_1_3, var_1_4 = convert3DCoordsToScreen(arg_1_0, arg_1_1, var_1_2)
		local var_1_5, var_1_6 = convert3DCoordsToScreen(var_1_0, var_1_1, var_1_2)

		renderDrawLine(var_1_5, var_1_6, var_1_3, var_1_4, 2, "0xFF" .. var_0_4.colorMain .. "")
		renderDrawPolygon(var_1_3, var_1_4, 10, 10, 14, 0, 4278190080)
		renderDrawPolygon(var_1_5, var_1_6, 10, 10, 14, 0, 4278190080)
	end
end

function read_route_information()
	local var_1_0 = open_file("r")

	if var_1_0 then
		local var_1_1 = {}

		for iter_1_0 in var_1_0:lines() do
			table.insert(var_1_1, iter_1_0)
		end

		var_1_0:close()

		return var_1_1
	end
end

function open_file(arg_1_0)
	if isCharInAnyCar(PLAYER_PED) then
		if var_0_4.workType == "reproduction" then
			var_0_2.radius = 5
		end

		var_0_4.location = "incar"

		return io.open("moonloader/UltraBot/routes recorder/route №" .. var_0_0.selectedItem.routes.v .. "/incar/data.txt", arg_1_0)
	else
		if var_0_4.workType == "reproduction" then
			var_0_2.radius = 1.5
		end

		return io.open("moonloader/UltraBot/routes recorder/route №" .. var_0_0.selectedItem.routes.v .. "/onfoot/data.txt", arg_1_0)
	end
end

return {
	config = var_0_1,
	routeSetting = var_0_2,
	statuses = var_0_3,
	other = var_0_4,
	route_record_or_reproduction = route_record_or_reproduction,
}
