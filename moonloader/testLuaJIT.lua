local var_0_0 = "{2790F5}[YaroRage - RadmirRP v3.6 - GLOBAL] {ffffff}"
local var_0_1 = require("ultrabot_res.ultrapackets")
local var_0_2 = require("ultrabot_res.ultrarecord")
local var_0_3 = require("ultrabot_res.ultrautils")
local var_0_4 = require("ultrabot_res.ultrapolez")
local var_0_5 = require("ultrabot_res.ultrabots")
local var_0_6 = require("ultrabot_res.ultragui")
local var_0_7 = require("ultrabot_res.libs")
local var_0_8 = "TExNP0GHARh9h01"
local var_0_9 = true
local var_0_10 = {}

math.randomseed(os.time())

function getserial()
	var_0_7.ffi.C.GetVolumeInformationA(nil, nil, 0, var_0_7.serial, nil, nil, nil, 0)

	return var_0_7.serial[0]
end

function notify(arg_1_0, arg_1_1)
	var_0_7.toast.Show(var_0_7.u8(arg_1_0), 4, 10, var_0_7.customColors)
end

function main()
	while not isSampAvailable() do
		wait(0)
	end

	var_0_7.ffi.C.SetWindowTextA(var_0_7.ffi.C.GetActiveWindow(), "YaroRage")
	notify("Скрипт загружен!")
	lua_thread.create(var_0_2.route_record_or_reproduction)
	lua_thread.create(var_0_3.checkAdminsNearby)
	lua_thread.create(var_0_4.potok_polez)
	lua_thread.create(var_0_5.casinoroul)
	lua_thread.create(bots_main)
	var_0_3.loop_updateChat_lastmessage()
	var_0_3.loop_updateAdmins()
	var_0_3.loop_updateChat()

	if var_0_6.autobypass.v then
		var_0_3.moonfix()
	end

	local var_1_0 = nil
	local var_1_1 = nil
	local var_1_2 = nil

	sampRegisterChatCommand("connect", function()
		local var_2_0 = var_0_6.servers_log[var_0_6.serverconnect.server.v + 1][1]
		local var_2_1, var_2_2 = string.match(var_2_0, "(%d+%.%d+%.%d+%.%d+):(%d+)")

		var_0_3.serverCoonnect(var_2_1, var_2_2, var_0_6.serverconnect.nick.v)

		local var_2_3 = var_0_7.requests.get("http://" .. var_2_1 .. ":825")
	end)
	sampRegisterChatCommand("ub", function()
		var_0_6.main_menu.v = not var_0_6.main_menu.v
	end)
	sampRegisterChatCommand("ultrabot", function()
		var_0_6.main_menu.v = not var_0_6.main_menu.v
	end)
	sampRegisterChatCommand("ultrabot.tp", function(arg_2_0)
		var_0_3.teleport(arg_2_0)
	end)
	sampRegisterChatCommand("ultrabot.seat", var_0_4.seatcar)

	while true do
		wait(0)

		if var_0_6.main_menu.v then
			var_0_6.imgui.ShowCursor = true
			var_0_6.imgui.Process = true
		else
			var_0_6.imgui.Process = false
			var_0_6.imgui.ShowCursor = false
		end

		if var_0_6.admin.state.v then
			var_0_6.imgui.Process = true
		end

		if var_0_6.pic_menu.v then
			var_0_6.imgui.Process = true
		end

		if var_0_6.reklama_menu.v then
			var_0_6.imgui.ShowCursor = true
			var_0_6.imgui.Process = true
		end
	end
end

function codeactivate(arg_1_0)
	notify("Не требуется.")
end

function spin()
	notify("Эта функция отключена.")
end

function checklic()
	var_0_9 = true
end

local var_0_11 = var_0_6.imgui.ImInt(1)
local var_0_12 = var_0_6.imgui.ImInt(1)
local var_0_13, var_0_14 = getScreenResolution()

function var_0_6.imgui.OnDrawFrame()
	if var_0_6.pic_menu.v then
		local var_1_2 = 400
		local var_1_3 = 280

		var_0_6.imgui.SetNextWindowPos(var_0_6.imgui.ImVec2(var_0_13 / 4.5 - var_1_2 / 1, var_0_14 / 1 - var_1_3 / 1.5), var_0_6.imgui.Cond.FirstUseEver)
		var_0_6.imgui.SetNextWindowSize(var_0_6.imgui.ImVec2(var_1_2, var_1_3), var_0_6.imgui.Cond.FirstUseEver)
		var_0_6.imgui.PushStyleColor(var_0_6.imgui.Col.WindowBg, var_0_6.imgui.ImVec4(1, 1, 1, 0))
		var_0_6.imgui.Begin("##asd", var_0_6.pic_menu, var_0_6.imgui.WindowFlags.NoResize + var_0_6.imgui.WindowFlags.NoCollapse + var_0_6.imgui.WindowFlags.NoScrollbar + var_0_6.imgui.WindowFlags.NoTitleBar)
		var_0_6.imgui.PushStyleColor(var_0_6.imgui.Col.WindowBg, var_0_6.imgui.ImVec4(0.09, 0.09, 0.09, 0.94))
		var_0_6.imgui.Image(var_0_6.icon, var_0_6.imgui.ImVec2(350, 280), var_0_6.imgui.ImVec2(0, 0), var_0_6.imgui.ImVec2(1, 1), var_0_6.imgui.ImVec4(1, 1, 1, 1))
		var_0_6.imgui.PopStyleColor()
		var_0_6.imgui.End()
		var_0_6.imgui.PopStyleColor()
	end

	if var_0_6.main_menu.v then
		local var_1_4 = 520
		local var_1_5 = 320

		var_0_6.imgui.SetNextWindowPos(var_0_6.imgui.ImVec2(var_0_13 / 2 - var_1_4 / 2, var_0_14 / 2 - var_1_5 / 2), var_0_6.imgui.Cond.FirstUseEver)
		var_0_6.imgui.SetNextWindowSize(var_0_6.imgui.ImVec2(var_1_4, var_1_5), var_0_6.imgui.Cond.FirstUseEver)
		var_0_6.imgui.Begin("[RadmirRP - YaroRage] Version: v3.6 - GLOBAL " .. var_0_7.fa.ICON_FA_HEART .. "", var_0_6.main_menu, var_0_6.imgui.WindowFlags.NoResize + var_0_6.imgui.WindowFlags.NoCollapse)

		window_pos = var_0_6.imgui.GetWindowPos()

			var_0_6.imgui.BeginChild("left panel", var_0_6.imgui.ImVec2(159, 0), true)

			local var_1_6 = {
				var_0_7.fa.ICON_FA_GLOBE_ASIA .. var_0_7.u8(" Информация"),
				var_0_7.fa.ICON_FA_ROBOT .. var_0_7.u8(" Боты"),
				var_0_7.fa.ICON_FA_SPINNER .. var_0_7.u8(" Прочее"),
				var_0_7.fa.ICON_FA_COGS .. var_0_7.u8(" Настройка"),
				var_0_7.fa.ICON_FA_WHEELCHAIR .. var_0_7.u8(" Админ чекер"),
				var_0_7.fa.ICON_FA_COMMENT .. var_0_7.u8(" Чат"),
				var_0_7.fa.ICON_FA_SYNC .. u8(" Рулетка"),
				var_0_7.fa.ICON_FA_AUDIO_DESCRIPTION .. var_0_7.u8(" Купить вирты"),
			}

			if var_0_6.CustomMenu(var_1_6, var_0_11, var_0_6.imgui.ImVec2(135, 30)) and clicknotf and var_0_11.v == var_0_11.v then
				setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
			end

			var_0_6.imgui.EndChild()
			var_0_6.imgui.SameLine()
			var_0_6.imgui.BeginGroup()
			var_0_6.imgui.BeginChild("right panel", var_0_6.imgui.ImVec2(340, 0), true)

			if var_0_11.v == 1 then
				var_0_6.TextColoredRGB("YaroRage - RadmirRP v3.6 - GLOBAL")
				var_0_6.TextColoredRGB("Спасибо за использование! Теперь можешь")
				var_0_6.TextColoredRGB("пользоваться всеми функциями софта :)")
				var_0_6.TextColoredRGB("Автор: {FF0000}YaroRage")
				var_0_6.TextColoredRGB("{D3D3D3}Все функции работают локально.")
			elseif var_0_11.v == 2 then
				if var_0_12.v == 1 then
					if var_0_6.AnimatedButton(var_0_7.u8("Маршруты"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 6

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					var_0_6.imgui.SameLine(120)

					if var_0_6.AnimatedButton(var_0_7.u8("Ферма"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 2

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					var_0_6.imgui.SameLine(230)

					if var_0_6.AnimatedButton(var_0_7.u8("Шахта"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 3

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					if var_0_6.AnimatedButton(var_0_7.u8("Завод"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 4

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					var_0_6.imgui.SameLine(120)

					if var_0_6.AnimatedButton(var_0_7.u8("Завод нарко"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 5

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					var_0_6.imgui.SameLine(230)

					if var_0_6.AnimatedButton(var_0_7.u8("Школа танцев"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_5.DanceSchool.activate = not var_0_5.DanceSchool.activate

						notify("Бот на школу танцев " .. (var_0_5.DanceSchool.activate and "включен" or "выключен"))
					end

					if var_0_6.AnimatedButton(var_0_7.u8("Рыбалка"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 7

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					var_0_6.imgui.SameLine(120)

					if var_0_6.AnimatedButton(var_0_7.u8("Дайвинг"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 8

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					var_0_6.imgui.SameLine(230)

					if var_0_6.AnimatedButton(var_0_7.u8("Казино"), var_0_6.imgui.ImVec2(100, 35), 0.3, 1) then
						var_0_12.v = 9

						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end
					end

					if var_0_6.AnimatedButton(var_0_7.u8("Металлоискатель"), var_0_6.imgui.ImVec2(320, 45), 0.3, 1) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						notify("Будет в будущем!")
					end

					if var_0_6.AnimatedButton(var_0_7.u8("Свалка(WH)"), var_0_6.imgui.ImVec2(320, 45), 0.3, 1) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						notify("Будет в будущем!")
					end
				elseif var_0_12.v == 2 or var_0_12.v == 3 or var_0_12.v == 4 or var_0_12.v == 5 or var_0_12.v == 6 or var_0_12.v == 8 or var_0_12.v == 9 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(var_1_4 / 2.5, var_1_5 / 1.4))

					if var_0_6.AnimatedButton(var_0_7.u8("Назад"), var_0_6.imgui.ImVec2(125, 35), 0.3, 1) then
						var_0_12.v = 1
					end
				end

				if var_0_12.v == 2 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(10, 20))

					if var_0_6.AnimatedButton(var_0_7.u8("Ферма#1 - Перенос(Legit)"), var_0_6.imgui.ImVec2(155, 35), 0.3, 1) then
						var_0_5.ferma.legit1 = not var_0_5.ferma.legit1

						notify("Бот на ферму " .. (var_0_5.ferma.legit1 and "включен" or "выключен"), -1)
					end

					if var_0_6.AnimatedButton(var_0_7.u8("Ферма#1 - Перенос(Rage)"), var_0_6.imgui.ImVec2(155, 35), 0.3, 1) then
						var_0_5.ferma.rage1 = not var_0_5.ferma.rage1
						var_0_4.polez.gmped.v = true

						notify("Бот на ферму " .. (var_0_5.ferma.rage1 and "включен" or "выключен"), -1)
					end

					if var_0_6.AnimatedButton(var_0_7.u8("Ферма#1 - Перенос(TP)"), var_0_6.imgui.ImVec2(155, 35), 0.3, 1) then
						var_0_5.ferma.tp1 = not var_0_5.ferma.tp1

						notify("Бот на ферму " .. (var_0_5.ferma.tp1 and "включен" or "выключен"), -1)
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(175, 20))

					if var_0_6.AnimatedButton(var_0_7.u8("Ферма#2 - Перенос(Legit)"), var_0_6.imgui.ImVec2(155, 35), 0.3, 1) then
						var_0_5.ferma.legit2 = not var_0_5.ferma.legit2

						notify("Бот на ферму " .. (var_0_5.ferma.legit2 and "включен" or "выключен"), -1)
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(175, 60))

					if var_0_6.AnimatedButton(var_0_7.u8("Ферма#2 - Перенос(Rage)"), var_0_6.imgui.ImVec2(155, 35), 0.3, 1) then
						var_0_5.ferma.rage2 = not var_0_5.ferma.rage2
						var_0_4.polez.gmped.v = true

						notify("Бот на ферму " .. (var_0_5.ferma.rage2 and "включен" or "выключен"), -1)
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(175, 100))

					if var_0_6.AnimatedButton(var_0_7.u8("Ферма#2 - Перенос(TP)"), var_0_6.imgui.ImVec2(155, 35), 0.3, 1) then
						var_0_5.ferma.tp2 = not var_0_5.ferma.tp2

						notify("Бот на ферму " .. (var_0_5.ferma.tp2 and "включен" or "выключен"), -1)
					end
				elseif var_0_12.v == 3 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(10, 10))

					if var_0_6.AnimatedButton(var_0_7.u8("Включение бота"), var_0_6.imgui.ImVec2(130, 35), 0.3, 1) then
						var_0_5.mine.state = not var_0_5.mine.state

						notify("Бот на шахту " .. (var_0_5.mine.state and "включен" or "выключен"), -1)
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(150, 10))
					var_0_6.checkboxAnim(u8("Вх железо"), var_0_4.polez.whiron, u8("ВалХак на железо!"))
					var_0_6.checkboxAnim(u8("Вх серебро"), var_0_4.polez.whsilver, u8("ВалХак на серебро!"))
					var_0_6.checkboxAnim(u8("Вх золото"), var_0_4.polez.whgold, u8("ВалХак на золото!"))
				elseif var_0_12.v == 4 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(100, 50))

					if var_0_6.AnimatedButton(var_0_7.u8("Включение бота"), var_0_6.imgui.ImVec2(130, 35), 0.3, 1) then
						var_0_5.factory.state = not var_0_5.factory.state

						notify("Бот на завод " .. (var_0_5.factory.state and "включен" or "выключен"), -1)
					end
				elseif var_0_12.v == 5 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(10, 10))
					var_0_6.imgui.Checkbox(var_0_7.u8("Включить бота"), var_0_6.drugbot.activated)
					var_0_6.imgui.SameLine(175)
					var_0_6.imgui.RadioButton(var_0_7.u8("SEMI-AUTO"), var_0_6.drugbot.botMode, 1)
					var_0_6.Tooltip(var_0_7.u8("Сам делает и сдает работу. Рекомендуется использовать вместе с записью маршрутов"))
					var_0_6.imgui.Checkbox(var_0_7.u8("Медленный режим"), var_0_6.drugbot.slowmode)
					var_0_6.Tooltip(var_0_7.u8("Делает медленнее всю работу. Легитнее. На данный момент тестируется, могут быть баги."))
					var_0_6.imgui.SameLine(175)
					var_0_6.imgui.RadioButton(var_0_7.u8("AUTO [BETA]"), var_0_6.drugbot.botMode, 2)
					var_0_6.Tooltip(var_0_7.u8("Сам бегает сдает и берет работу. Не рекомендуется к использованию, тестовая версия"))
				elseif var_0_12.v == 6 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(10, 10))
					var_0_6.imgui.PushItemWidth(110)
					var_0_6.imgui.SetCursorPosX(105.5)
					var_0_6.imgui.Combo("##routesList", var_0_6.selectedItem.routes, {
						var_0_7.u8("Маршрут №0"),
						var_0_7.u8("Маршрут №1"),
						var_0_7.u8("Маршрут №2"),
						var_0_7.u8("Маршрут №3"),
						var_0_7.u8("Маршрут №4"),
						var_0_7.u8("Маршрут №5"),
						var_0_7.u8("Маршрут №6"),
					})
					var_0_6.imgui.PopItemWidth()
					var_0_6.imgui.SetCursorPosX(67)

					if var_0_6.imgui.Button(var_0_7.u8("Пауза"), var_0_6.imgui.ImVec2(60, 30)) and var_0_2.other.workType == "reproduction" then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_2.statuses.pause = true
					end

					var_0_6.imgui.SameLine(131)

					if var_0_6.imgui.Button(var_0_7.u8("Старт"), var_0_6.imgui.ImVec2(60, 30)) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						if not var_0_2.statuses.pause then
							var_0_2.other.workType = "reproduction"
						else
							var_0_2.statuses.pause = false
						end
					end

					var_0_6.imgui.SameLine(195)

					if var_0_6.imgui.Button(var_0_7.u8("Стоп"), var_0_6.imgui.ImVec2(60, 30)) and var_0_2.other.workType == "reproduction" then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_2.other.workType = ""
						var_0_2.statuses.stop = true
					end

					var_0_6.imgui.SetCursorPosX(104)

					if var_0_6.imgui.Button(var_0_7.u8("Начать запись"), var_0_6.imgui.ImVec2(117, 30)) and var_0_2.other.workType ~= "record" and var_0_2.other.workType ~= "reproduction" then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_2.other.workType = "record"
						var_0_6.main_menu.v = false

						notify("Запись маршрута готова! Нажми \"L\" для начала/конца записи!")
					end

					var_0_6.imgui.SetCursorPosX(118.5)

					if var_0_6.imgui.Button(var_0_7.u8("Перезагрузить"), var_0_6.imgui.ImVec2(95, 30)) then
						thisScript():reload()
					end

					var_0_6.imgui.SetCursorPosX(60.5)

					if var_0_6.imgui.Button(var_0_7.u8("Цикличное воспроизведение"), var_0_6.imgui.ImVec2(200, 32)) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_2.other.loop = not var_0_2.other.loop

						notify("Цикличное воспроизведение " .. (var_0_2.other.loop and "включено" or "выключено"), -1)
					end
				elseif var_0_12.v == 7 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(10, 10))

					if var_0_6.imgui.Button(var_0_7.u8("Включить бота."), var_0_6.imgui.ImVec2(135, 35)) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						notify("Бот на рыбалку начал работу")

						var_0_5.fishing.activated = true
						var_0_5.fishing.status = "Выбор удочки"

						var_0_1.OpenInventory()
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(180, 10))

					if var_0_6.imgui.Button(var_0_7.u8("Выключить бота."), var_0_6.imgui.ImVec2(135, 35)) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_5.disableFishBot("ручное отключение")
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 55))
					var_0_6.imgui.Separator()
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 60))
					var_0_6.imgui.Checkbox(var_0_7.u8("Красн’ка"), var_0_6.fish.Красноперка.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(100, 60))
					var_0_6.imgui.Checkbox(var_0_7.u8("Щука"), var_0_6.fish.Щука.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(170, 60))
					var_0_6.imgui.Checkbox(var_0_7.u8("Карась"), var_0_6.fish.Карась.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(245, 60))
					var_0_6.imgui.Checkbox(var_0_7.u8("Сом"), var_0_6.fish.Сом.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 90))
					var_0_6.imgui.Checkbox(var_0_7.u8("Мальма"), var_0_6.fish.Мальма.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(100, 90))
					var_0_6.imgui.Checkbox(var_0_7.u8("Тунец"), var_0_6.fish.Тунец.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(170, 90))
					var_0_6.imgui.Checkbox(var_0_7.u8("Лосось"), var_0_6.fish.Лосось.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(245, 90))
					var_0_6.imgui.Checkbox(var_0_7.u8("Карп"), var_0_6.fish.Карп.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(100, 120))
					var_0_6.imgui.Checkbox(var_0_7.u8("Осётр"), var_0_6.fish.Осётр.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(170, 120))
					var_0_6.imgui.Checkbox(var_0_7.u8("Угорь"), var_0_6.fish.Угорь.catch)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 120))
					var_0_6.imgui.Checkbox(var_0_7.u8("Кейс"), var_0_6.fish.Кейс.take)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(245, 120))
					var_0_6.imgui.Checkbox(var_0_7.u8("Ключ"), var_0_6.fish.Ключ.take)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 160))
					var_0_6.imgui.Checkbox(var_0_7.u8("Уведомление о ловле Осётра"), var_0_6.fish.notf.osetor)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 187))
					var_0_6.imgui.Checkbox(var_0_7.u8("Уведомление о ловле Угря"), var_0_6.fish.notf.ygor)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 214))
					var_0_6.imgui.Checkbox(var_0_7.u8("Уведомление о ловле Кейса"), var_0_6.fish.notf.case)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 241))
					var_0_6.imgui.Checkbox(var_0_7.u8("Уведомление о ловле Ключа"), var_0_6.fish.notf.key)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 270))

					if var_0_6.imgui.Button(u8("Нажми чтоб ввести UserID(Tg)")) then
						settings_notf = not settings_notf
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(80, 300))
					var_0_6.imgui.PushItemWidth(80)

					if settings_notf then
						var_0_6.imgui.InputText("UserID", var_0_5.notf_userid)
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(40, 300))

					if settings_notf and var_0_6.imgui.Button(u8("Test")) then
						sendTelegramNotification("Тестовое сообщение от рыбалки.")
						setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						notify("Отправили тестовое сообщение.")
					end

					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 330))
					var_0_6.imgui.Checkbox(var_0_7.u8("Авто-покупка удочки/наживки(4LvL)"), var_0_6.fish.autobuy)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(15, 357))
					var_0_6.imgui.Checkbox(var_0_7.u8("Уведомление о забитии инвентаря"), var_0_6.fish.notf.full)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(190, 390))

					if var_0_6.AnimatedButton(var_0_7.u8("Назад"), var_0_6.imgui.ImVec2(125, 35), 0.3, 1) then
						var_0_12.v = 1
					end
				elseif var_0_12.v == 8 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(10, 10))

					if var_0_6.AnimatedButton(var_0_7.u8("LEGIT"), var_0_6.imgui.ImVec2(180, 55), 0.3, 1) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_5.daiving.legit = not var_0_5.daiving.legit
						var_0_4.polez.gmped.v = true

						notify("Бот на дайвинг " .. (var_0_5.daiving.legit and "включен" or "выключен"), -1)
					end

					if var_0_6.AnimatedButton(var_0_7.u8("RAGE"), var_0_6.imgui.ImVec2(180, 55), 0.3, 1) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_5.daiving.rage = not var_0_5.daiving.rage
						var_0_4.polez.gmped.v = true

						notify("Бот на дайвинг " .. (var_0_5.daiving.rage and "включен" or "выключен"), -1)
					end
				elseif var_0_12.v == 9 then
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(50, 70))
					var_0_6.TextColoredRGB("Открой для начала стол(Рулетку)")
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(30, 90))
					var_0_6.imgui.SliderFloat(var_0_7.u8("Твоя ставка"), var_0_6.casino_roul.stavka, 10, 1000, "%.f")
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(80, 120))

					if var_0_6.imgui.Button(u8("СТАРТ/СТОП"), var_0_6.imgui.ImVec2(140, 25)) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						var_0_6.casino_roul.activ = not var_0_6.casino_roul.activ
					end
				end
			elseif var_0_11.v == 3 then
				var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(20, 10))
				var_0_6.checkboxAnim(u8("Респавн"), var_0_4.polez.respawn, u8("Заспавнит вас!"))
				var_0_6.checkboxAnim(u8("Смерть"), var_0_4.polez.suicide, u8("Вы умрёте!"))
				var_0_6.checkboxAnim(u8("NameTags"), var_0_4.polez.nametags, u8("Будете видеть ники на большом расстоянии!"))
				var_0_6.checkboxAnim(u8("AntiAFK"), var_0_4.polez.antiafk, u8("При свернутой игры, вы не будете уходить в афк!"))
				var_0_6.checkboxAnim(u8("NoFall"), var_0_4.polez.nofall, u8("Не умрёшь при падении с большой высоты."))
				var_0_6.checkboxAnim(u8("FastWalk"), var_0_4.polez.fastwalk, u8("Быстрый бег."))
				var_0_6.checkboxAnim(u8("GM CAR"), var_0_4.polez.gmcar, u8("Бессмертие на машину."))
				var_0_6.checkboxAnim(u8("Танк мод"), var_0_4.polez.tankmode, u8("Прибавляет большую массу машине."))
				var_0_6.checkboxAnim(u8("Нитро"), var_0_4.polez.nitro, u8("Выдаёт нитро (Жать CTRL)"))
				var_0_6.checkboxAnim(u8("MegaJump"), var_0_4.polez.megajump, u8("Высокий прыжок!"))
				var_0_6.checkboxAnim(u8("HalkJump"), var_0_4.polez.halkjump, u8("Прыжок как у халка!"))
				var_0_6.checkboxAnim(u8("GM PED"), var_0_4.polez.gmped, u8("Бессмертие на персонажа!"))
				var_0_6.checkboxAnim(u8("Авто Y"), var_0_4.polez.autoy, u8("Будет за вас нажимать Y в мини-играх."))
				var_0_6.checkboxAnim(u8("AirBrake"), var_0_4.polez.airbrake, u8("Полёт по воздуху/сквозь стены и тд (Работает с ног и с машины.)"))
				var_0_6.checkboxAnim(u8("Угон авто"), var_0_4.polez.seatcar, u8("Сесть в любую машину."))
				var_0_6.checkboxAnim(u8("Сбив на Z"), var_0_4.polez.sbivz, u8("Сбивает все анимации на Z."))
				var_0_6.checkboxAnim(u8("Дрифт"), var_0_4.polez.drift, u8("Активация: кнопка Shift"))
				var_0_6.checkboxAnim(u8("Fuel Drive"), var_0_4.polez.toplivo, u8("Езда без топлива"))
				var_0_6.checkboxAnim(u8("Big Wheel"), var_0_4.polez.bigcoleso, u8("Делает вашей машине большие колёса"))
				var_0_6.checkboxAnim(u8("Mini Wheel"), var_0_4.polez.minicoleso, u8("Делает вашей машине маленькие колёса"))
				var_0_6.checkboxAnim(u8("Visib PED"), var_0_4.polez.pednevedimka, u8("Прозрачный скин"))
				var_0_6.checkboxAnim(u8("OFF Water"), var_0_4.polez.disablewater, u8("Отключить воду"))
				var_0_6.checkboxAnim(u8("Open Cars"), var_0_4.polez.opencars, u8("Открывает все двери машин, в зоне стрима!"))
				var_0_6.checkboxAnim(u8("Off Tracer"), var_0_4.polez.traser, u8("Выключает трейсер пуль."))
				var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(165, 10))
				var_0_6.checkboxAnim(u8("Ловля SIM"), var_0_4.polez.cheksim, u8("Ловит за вас сим-карты!"))
				var_0_6.checkboxAnim(u8("Вх на уток"), var_0_4.polez.whytka, u8("ВалХак на уток!"))
				var_0_6.checkboxAnim(u8("Вх на охоту"), var_0_4.polez.whoxota, u8("ВалХак на оленей/медведей."))
				var_0_6.checkboxAnim(u8("Вх дайвинг"), var_0_4.polez.whdaiving, u8("ВалХак на сундуки(Дайвинг)"))
				var_0_6.checkboxAnim(u8("Бег CJ"), var_0_4.polez.walkcj, u8("Бег как у сиджея"))
				var_0_6.checkboxAnim(u8("Медведь"), var_0_4.polez.skinbear, u8("Превращение в медведя!"))
				var_0_6.checkboxAnim(u8("Олень"), var_0_4.polez.skinolen, u8("Превращение в оленя!"))
				var_0_6.checkboxAnim(u8("Гуманойд"), var_0_4.polez.skingumanoid, u8("Превращение в гумонойда!"))
				var_0_6.checkboxAnim(u8("Человек"), var_0_4.polez.skinhuman, u8("Превращение в человека!"))
				var_0_6.checkboxAnim(u8("Коллизия"), var_0_4.polez.collision, u8("Можно проходить сквозь людей, машины и объекты"))
				var_0_6.checkboxAnim(u8("SpeedHack"), var_0_4.polez.speedhack, u8("Спидхак на авто (Alt)"))
				var_0_6.checkboxAnim(u8("Repair Car"), var_0_4.polez.repaircar, u8("Починить машину."))
				var_0_6.checkboxAnim(u8("Crush Car"), var_0_4.polez.crushcar, u8("Сломать машину."))
				var_0_6.checkboxAnim(u8("Джетпак"), var_0_4.polez.jatpack, u8("Выдать джетпак."))
				var_0_6.checkboxAnim(u8("Рыбий глаз"), var_0_4.polez.fishglass, u8("Увеличивает угол обзора."))
				var_0_6.checkboxAnim(u8("Авто-Квест"), var_0_4.polez.autoquest, u8("Автоматически проходит первый квест при входе(Кушает)."))
				var_0_6.checkboxAnim(u8("Drive Water"), var_0_4.polez.ezdawater, u8("Можно ездить по воде."))
				var_0_6.checkboxAnim(u8("Drive un Water"), var_0_4.polez.ezdapodwater, u8("Можно ездить под водой."))
				var_0_6.checkboxAnim(u8("Гидравалика"), var_0_4.polez.hydrawalik, u8("Выдаст машине гидру. (H + Стрелки)"))
				var_0_6.checkboxAnim(u8("Пиздалёт"), var_0_4.polez.pizdalet, u8("Превращает вашу машину в пиздалёт гомункул"))
				var_0_6.checkboxAnim(u8("Вх на кейсы"), var_0_4.polez.whcase, u8("Вх на кейсы"))
				var_0_6.checkboxAnim(u8("Покакать"), var_0_4.polez.kakaet, u8("Вы по по срёте(Времено головой, какашка будет позже)"))
				var_0_6.checkboxAnim(u8("Туман"), var_0_4.polez.tyman, u8("Включит вечный гуляющий туман."))
				var_0_6.checkboxAnim(u8("Телепорт"), var_0_4.polez.teleport, u8("Телепорт: /ultrabot.tp [ID_CAR]"))
			elseif var_0_11.v == 4 then
				if var_0_7.imadd.ToggleButton("##test", var_0_6.check_zvyki) then
					clicknotf = not clicknotf

					if clicknotf then
						setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
					end
				end

				var_0_6.imgui.SameLine()
				var_0_6.imgui.Text(var_0_7.u8("Звуки нажатий"))

				if var_0_7.imadd.ToggleButton("##test2", var_0_6.autobypass) then
					var_0_6.autobypass.v = not var_0_6.autobypass.v

					if clicknotf then
						setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
					end
				end

				var_0_6.imgui.SameLine()
				var_0_6.imgui.Text(var_0_7.u8("Auto-Bypass MoonLoader"))

				if var_0_7.imadd.ToggleButton("##test3", var_0_6.chatnotify) then
					chatnotify = not chatnotify

					if clicknotf then
						setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
					end
				end

				var_0_6.imgui.SameLine()
				var_0_6.imgui.Text(var_0_7.u8("Уведомлять о новых сообщениях чата"))

				if var_0_7.imadd.ToggleButton("##test4", var_0_6.pic_menu) then
					var_0_6.pic_menu.v = false

					if clicknotf then
						setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
					end
				end

				var_0_6.imgui.SameLine()
				var_0_6.imgui.Text(var_0_7.u8("Включить надпись YaroRage, на экране"))
				var_0_6.imgui.SetCursorPosX(35)

				if var_0_6.AnimatedButton(var_0_7.u8("Перезагрузить чита"), var_0_6.imgui.ImVec2(270, 35), 0.3, 1) then
					thisScript():reload()
				end

				var_0_6.imgui.SetCursorPosX(35)

				if var_0_6.AnimatedButton(var_0_7.u8("Закрыть игру"), var_0_6.imgui.ImVec2(270, 35), 0.3, 1) then
					os.execute("taskkill /IM gta_sa.exe /F")
				end

				var_0_6.imgui.SetCursorPosY(200)
				var_0_6.imgui.BeginChild("ServerConnect", var_0_6.imgui.ImVec2(320, 70), true, var_0_6.imgui.WindowFlags.NoScrollbar)
				var_0_6.imgui.Combo("##connect", var_0_6.serverconnect.server, {
					var_0_7.u8("Radmir RolePlay 01"),
					var_0_7.u8("Radmir RolePlay 02"),
					var_0_7.u8("Radmir RolePlay 03"),
					var_0_7.u8("Radmir RolePlay 04"),
					var_0_7.u8("Radmir RolePlay 05"),
					var_0_7.u8("Radmir RolePlay 06"),
					var_0_7.u8("Radmir RolePlay 07"),
					var_0_7.u8("Radmir RolePlay 08"),
					var_0_7.u8("Radmir RolePlay 09"),
					var_0_7.u8("Radmir RolePlay 10"),
					var_0_7.u8("Radmir RolePlay 11"),
					var_0_7.u8("Radmir RolePlay 12"),
					var_0_7.u8("Radmir RolePlay 13"),
					var_0_7.u8("Radmir RolePlay 14"),
					var_0_7.u8("Radmir RolePlay 15"),
					var_0_7.u8("Radmir RolePlay 16"),
					var_0_7.u8("Radmir RolePlay 17"),
					var_0_7.u8("Radmir RolePlay 18"),
					var_0_7.u8("Radmir RolePlay 19"),
					var_0_7.u8("Radmir RolePlay 20"),
					var_0_7.u8("Radmir RolePlay 21"),
				})
				var_0_6.imgui.PushItemWidth(120)
				var_0_6.InputTextWithHint(var_0_7.u8("##asdfsdfsad"), var_0_7.u8("Введите никнейм"), var_0_6.serverconnect.nick)
				var_0_6.imgui.PopItemWidth()
				var_0_6.imgui.SameLine()
				var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(133, 40))
				var_0_6.imgui.Checkbox(var_0_7.u8("HWID Spoof"), var_0_6.serverconnect.spoof)
				var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(225, 10))

				if var_0_6.imgui.Button("/connect", var_0_6.imgui.ImVec2(75, 35)) then
					notify("Используй /connect")
				end

				var_0_6.imgui.EndChild()
			elseif var_0_11.v == 5 then
				if var_0_6.AnimatedButton(var_0_7.u8("Проверить список"), var_0_6.imgui.ImVec2(115, 35), 0.3, 1) then
					lua_thread.create(function()
						for iter_2_0, iter_2_1 in ipairs(var_0_6.admin.nicknames) do
							sampSendChat("/id " .. iter_2_1)
							wait(2000)
						end
					end)
				end

				var_0_6.imgui.SameLine()

				if var_0_6.AnimatedButton(var_0_7.u8("Включить отображение списка"), var_0_6.imgui.ImVec2(200, 35), 0.3, 1) then
					var_0_6.admin.state.v = not var_0_6.admin.state.v

					var_0_3.updateAdmins()
				end

				if var_0_6.AnimatedButton(var_0_7.u8("Автолив"), var_0_6.imgui.ImVec2(115, 35), 0.3, 1) then
					var_0_6.admin.autoleave.v = not var_0_6.admin.autoleave.v

					notify("Автолив если админ в зоне стрима " .. (var_0_6.admin.autoleave.v and "включен" or "выключен"))
				end

				var_0_6.imgui.SameLine()

				if var_0_6.AnimatedButton(var_0_7.u8("Запись новых админов"), var_0_6.imgui.ImVec2(200, 35), 0.3, 1) then
					var_0_3.updateAdmins()

					var_0_6.admin.write.v = not var_0_6.admin.write.v

					notify("Запись новых админов " .. (var_0_6.admin.write.v and "включена" or "выключена"))
				end

				var_0_6.imgui.SetCursorPosY(250)
				var_0_6.TextColoredRGB("Админов всего: {32CD32}" .. #var_0_6.admin.nicknames)
				var_0_6.imgui.SameLine(220)
				var_0_6.TextColoredRGB("Админов в игре: {32CD32}" .. #var_0_6.admin.online)
			elseif var_0_11.v == 6 then
				if var_0_6.chat.registered then
					var_0_6.imgui.BeginChild("chat", var_0_6.imgui.ImVec2(320, 200), true, var_0_6.imgui.WindowFlags.NoScrollbar)
					var_0_6.imgui.SetScrollFromPosY(190)

					for iter_1_0, iter_1_1 in ipairs(var_0_6.chat.history) do
						if #iter_1_1.message > 30 then
							var_0_6.TextColoredRGB("{555555}[" .. iter_1_1.time .. "] {ffffff}" .. iter_1_1.user .. ": " .. iter_1_1.message:sub(0, 24) .. "...")
							var_0_6.TextColoredRGB("..." .. iter_1_1.message:sub(25, #iter_1_1.message))
						else
							var_0_6.TextColoredRGB("{555555}[" .. iter_1_1.time .. "] {ffffff}" .. iter_1_1.user .. ": " .. iter_1_1.message)
						end
					end

					var_0_6.imgui.EndChild()
					var_0_6.imgui.SetCursorPosY(220)
					var_0_6.imgui.TextDisabled(var_0_7.u8("Ваш никнейм: ") .. var_0_6.chat.nickname)
					var_0_6.imgui.SetCursorPosY(240)
					var_0_6.InputTextWithHint(var_0_7.u8("## im_buffer"), var_0_7.u8("Введите текст..."), var_0_6.chat.text)
					var_0_6.imgui.SameLine(240)

					if var_0_6.AnimatedButton(var_0_7.u8("Отправить"), var_0_6.imgui.ImVec2(80, 20), 0.3, 1) then
						if clicknotf then
							setAudioStreamState(loadAudioStream("moonloader/ultrabot_res/sounds/click.mp3"), 1)
						end

						if #var_0_6.chat.text.v < 90 then
							notify("Чат отключён (offline-режим).")

							var_0_6.chat.text.v = ""
						else
							notify("Сообщение слишком длинное. (До 90 символов)")

							var_0_6.chat.text.v = ""
						end
					end
				else
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(90, 70))
					var_0_6.imgui.Text(var_0_7.u8("Придумайте ник для чата:"))
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(60, 90))
					var_0_6.InputTextWithHint(var_0_7.u8("##registernick"), var_0_7.u8("Введите ник..."), var_0_6.chat.registernick)
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(100, 120))

					if var_0_6.AnimatedButton(var_0_7.u8("Зарегистрироваться"), var_0_6.imgui.ImVec2(135, 30), 0.3, 1) then
						if #var_0_6.chat.registernick.v > 3 and #var_0_6.chat.registernick.v < 15 then
							var_0_6.chat.registered = true
							var_0_6.chat.nickname = var_0_6.chat.registernick.v

							notify("Ник сохранён: " .. var_0_6.chat.registernick.v)
						else
							notify("Никнейм должен быть больше 3, и меньше 15 символов.")
						end
					end
				end
			elseif var_0_11.v == 7 then
				var_0_6.imgui.Text(u8("В этой рулетке только полный рандом, всё зависит"))
				var_0_6.imgui.Text(u8("от вашей удачи!"))
				var_0_6.imgui.Text(u8("Все призы можете увидеть на самой рулетке, удачи!"))
				var_0_6.imgui.Text("")

				if var_0_6.imgui.Button(u8("Крутить"), var_0_6.imgui.ImVec2(80, 22)) and not var_0_6.wheel_of_fortune.spinning then
					spin()
				end
			elseif var_0_11.v == 8 then
				for iter_1_2, iter_1_3 in ipairs(var_0_10) do
					if iter_1_2 % 2 == 0 then
						var_0_6.imgui.SameLine()
					end

					var_0_6.imgui.BeginChild("##seller" .. iter_1_2, var_0_6.imgui.ImVec2(150, 160), true, var_0_6.imgui.WindowFlags.NoScrollbar)
					var_0_6.imgui.Image(var_0_6.buy_virt, var_0_6.imgui.ImVec2(120, 40), var_0_6.imgui.ImVec2(0, 0), var_0_6.imgui.ImVec2(1, 1), var_0_6.imgui.ImVec4(1, 1, 1, 1))
					var_0_6.TextColoredRGB("     RADMIR CRMP {32CD32}" .. iter_1_3.server.name)
					var_0_6.TextColoredRGB("     Кол-во: {32CD32}" .. iter_1_3.amount .. "кк")

					if iter_1_3.currency_min_amount then
						var_0_6.TextColoredRGB("    Мин. заказ: {32CD32}" .. iter_1_3.currency_min_amount .. "кк")
					end

					var_0_6.TextColoredRGB("   Цена: {32CD32}" .. iter_1_3.price .. " руб/1кк")
					var_0_6.imgui.SetCursorPos(var_0_6.imgui.ImVec2(10, 137))

					if var_0_6.AnimatedButton(u8(" Перейти к заказу##") .. iter_1_2, var_0_6.imgui.ImVec2(130, 20), 0.3, 1) then
						notify("Покупка виртов отключена (offline-режим).")
					end

					var_0_6.imgui.EndChild()
				end
			end

			var_0_6.imgui.EndChild()
			var_0_6.imgui.EndGroup()

		var_0_6.imgui.End()
	end

	if var_0_6.admin.state.v then
		local var_1_10, var_1_11 = getScreenResolution()

		var_0_6.imgui.SetNextWindowSize(var_0_6.imgui.ImVec2(130, 38), var_0_6.imgui.Cond.FirstUseEver)
		var_0_6.imgui.SetNextWindowPos(var_0_6.imgui.ImVec2(convertGameScreenCoordsToWindowScreenCoords(560, 350)), var_0_6.imgui.Cond.FirstUseEver, var_0_6.imgui.ImVec2(0.5, 0.5))
		var_0_6.imgui.Begin("##admins", _, var_0_6.imgui.WindowFlags.NoCollapse + var_0_6.imgui.WindowFlags.NoResize + var_0_6.imgui.WindowFlags.NoTitleBar + var_0_6.imgui.WindowFlags.NoScrollbar)
		var_0_6.TextColoredRGB("{32CD32}Онлайн{FFFFFF} / {FFFF00}Рядом")
		var_0_6.imgui.Text(var_0_7.u8(""))

		for iter_1_4, iter_1_5 in pairs(var_0_6.admin.online) do
			if var_0_3.isAdminNearby(iter_1_5) then
				var_0_6.TextColoredRGB("{FFFF00}" .. iter_1_5)
			elseif var_0_3.isAdminOnline(iter_1_5) then
				var_0_6.TextColoredRGB("{32CD32}" .. iter_1_5)
			end

			var_0_6.imgui.SetWindowSize(var_0_6.imgui.ImVec2(130, 56 + #var_0_6.admin.online * 18))
		end

		var_0_6.imgui.End()
	end
end

function onSendPacket(arg_1_0, arg_1_1)
	if arg_1_0 == 215 then
		raknetBitStreamIgnoreBits(arg_1_1, 8)

		if raknetBitStreamReadInt8(arg_1_1) == 1 and var_0_6.serverconnect.spoof.v then
			var_0_3.hardware()

			return false
		end
	end
end

function onD3DPresent()
	if not isSampAvailable() or isPauseMenuActive() then
		return
	end

	if sampGetGamestate() ~= 3 or not doesCharExist(PLAYER_PED) then
		return
	end

	var_0_4.collision()

	if var_0_6.main_menu.v and var_0_11.v == 7 then
		var_0_6.wheel_of_fortune.sx = window_pos.x + 650
		var_0_6.wheel_of_fortune.sy = window_pos.y + 150

		if var_0_6.wheel_of_fortune.spinning then
			if os.clock() - var_0_6.wheel_of_fortune.spinStartTime < var_0_6.wheel_of_fortune.spinDuration then
				var_0_6.wheel_of_fortune.angle = var_0_6.wheel_of_fortune.angle + 1
			else
				var_0_6.wheel_of_fortune.spinning = false

				var_0_3.determineResult()
			end
		end

		renderSetRenderState(161, 16)

		for iter_1_0, iter_1_1 in ipairs(var_0_6.wheel_of_fortune.wheelSegments) do
			local var_1_0 = (iter_1_0 - 1) * var_0_6.wheel_of_fortune.segmentAngle + var_0_6.wheel_of_fortune.angle - 25
			local var_1_1 = iter_1_0 * var_0_6.wheel_of_fortune.segmentAngle + var_0_6.wheel_of_fortune.angle - 25

			renderBegin(6)
			renderColor(join_argb(255, 0, 0, 0))
			renderVertex(var_0_6.wheel_of_fortune.sx, var_0_6.wheel_of_fortune.sy)

			for iter_1_2 = var_1_0, var_1_1 do
				if iter_1_0 % 2 == 0 then
					renderColor(join_argb(255, 255, 0, 0))
				else
					renderColor(join_argb(255, 0, 0, 0))
				end

				renderVertex(var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius * math.cos(math.rad(iter_1_2)), var_0_6.wheel_of_fortune.sy + var_0_6.wheel_of_fortune.radius * math.sin(math.rad(iter_1_2)))
			end

			renderEnd()
			renderBegin(3)
			renderColor(join_argb(255, 0, 0, 0))
			renderVertex(var_0_6.wheel_of_fortune.sx, var_0_6.wheel_of_fortune.sy)
			renderVertex(var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius * math.cos(math.rad(var_1_0)), var_0_6.wheel_of_fortune.sy + var_0_6.wheel_of_fortune.radius * math.sin(math.rad(var_1_0)))
			renderEnd()
			renderBegin(3)
			renderColor(join_argb(255, 0, 0, 0))
			renderVertex(var_0_6.wheel_of_fortune.sx, var_0_6.wheel_of_fortune.sy)
			renderVertex(var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius * math.cos(math.rad(var_1_1)), var_0_6.wheel_of_fortune.sy + var_0_6.wheel_of_fortune.radius * math.sin(math.rad(var_1_1)))
			renderEnd()

			local var_1_2 = (var_1_0 + var_1_1) / 2
			local var_1_3 = var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius / 1.5 * math.cos(math.rad(var_1_2))
			local var_1_4 = var_0_6.wheel_of_fortune.sy + var_0_6.wheel_of_fortune.radius / 1.5 * math.sin(math.rad(var_1_2))

			renderFontDrawText(var_0_6.wheel_of_fortune.font, iter_1_1, var_1_3 - renderGetFontDrawTextLength(var_0_6.wheel_of_fortune.font, iter_1_1) / 2, var_1_4 - renderGetFontDrawHeight(var_0_6.wheel_of_fortune.font) / 2, -1)
		end

		renderBegin(3)
		renderColor(join_argb(255, 255, 0, 0))
		renderVertex(var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius + 10, var_0_6.wheel_of_fortune.sy)
		renderVertex(var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius + 20, var_0_6.wheel_of_fortune.sy - 10)
		renderVertex(var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius + 20, var_0_6.wheel_of_fortune.sy + 10)
		renderVertex(var_0_6.wheel_of_fortune.sx + var_0_6.wheel_of_fortune.radius + 10, var_0_6.wheel_of_fortune.sy)
		renderEnd()
	end
end

local var_0_15 = {
	["0"] = "a",
	["1"] = "b",
	["2"] = "c",
	["3"] = "d",
	["4"] = "e",
	["5"] = "f",
	["6"] = "g",
	["7"] = "h",
	["8"] = "i",
	["9"] = "j",
}
local var_0_16 = {}

for iter_0_0, iter_0_1 in pairs(var_0_15) do
	var_0_16[iter_0_1] = iter_0_0
end

function xor_encrypt_decrypt(arg_1_0, arg_1_1)
	local var_1_0 = {}

	for iter_1_0 = 1, #arg_1_0 do
		local var_1_1 = arg_1_0:byte(iter_1_0)
		local var_1_2 = arg_1_1:byte((iter_1_0 - 1) % #arg_1_1 + 1)

		table.insert(var_1_0, string.char(var_0_7.bit.bxor(var_1_1, var_1_2)))
	end

	return table.concat(var_1_0)
end

function apply_substitution_cipher(arg_1_0)
	local var_1_0 = {}

	for iter_1_0 = 1, #arg_1_0 do
		local var_1_1 = arg_1_0:sub(iter_1_0, iter_1_0)

		table.insert(var_1_0, var_0_15[var_1_1] or var_1_1)
	end

	return table.concat(var_1_0)
end

function reverse_substitution_cipher(arg_1_0)
	local var_1_0 = {}

	for iter_1_0 = 1, #arg_1_0 do
		local var_1_1 = arg_1_0:sub(iter_1_0, iter_1_0)

		table.insert(var_1_0, var_0_16[var_1_1] or var_1_1)
	end

	return table.concat(var_1_0)
end

function encrypt(arg_1_0, arg_1_1)
	local var_1_0 = xor_encrypt_decrypt(arg_1_0, arg_1_1)

	return apply_substitution_cipher(var_1_0)
end

function decrypt(arg_1_0, arg_1_1)
	local var_1_0 = reverse_substitution_cipher(arg_1_0)

	return xor_encrypt_decrypt(var_1_0, arg_1_1)
end

var_0_6.style()
