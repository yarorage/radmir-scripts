local memory = require 'memory'
local font_flag = require('moonloader').font_flag
local font = renderCreateFont('Calibri', 12) -- стандартный шрифт и стандартный размер
local notify_timeopen = {}
local notify_timeclose = {}
local notify_text = {}

local notify_x_size
local notify_x_pos
local notify_y_pos

function main()
  if not isSampLoaded() or not isSampfuncsLoaded() then return end
	local radar_x_left = memory.getfloat(memory.getuint32(0x58A79B, true), true)
	local radar_y = memory.getfloat(memory.getuint32(0x58A7C7, true), true)
	radar_x_left, radar_y = convertGameScreenCoordsToWindowScreenCoords(radar_x_left, radar_y)
	radar_y = select(2, getScreenResolution()) - radar_y
	local radar_x_right = memory.getfloat(memory.getuint32(0x58A79B, true), true) + memory.getfloat(memory.getuint32(0x5834C2, true), true)
	radar_x_right, _ = convertGameScreenCoordsToWindowScreenCoords(radar_x_right, radar_y)
	notify_x_size = radar_x_right - radar_x_left
	notify_x_pos = radar_x_left
	notify_y_pos = radar_y + 20 - 30 -- 20 – расстояние между соседними уведомлениями; 30 – высота уведомления над радаром
  while not isSampAvailable() do wait(0) end
	while true do
		wait(0)
		DrawRender()
	end
end

function EXPORTS.addNotification(text, time)
	notify_timeopen[#notify_timeopen + 1] = os.clock()
	notify_timeclose[#notify_timeclose + 1] = os.clock() + time
	notify_text[#notify_text + 1] = text
end

function DrawRender()
	local y_pos = notify_y_pos -- начальная вертикальная координата
	local i = 1
	while i <= #notify_text do
		local show_notify = true -- надо ли рисовать уведомление?
		local x_pos = notify_x_pos -- координата по горизонатали
		local str = 0 -- количество строк в уведомлении
		local last_symb = 0
		local prelast_symb = 1
		local text_len = {} -- массив длины текста в пикселях
		while last_symb ~= nil do
			last_symb = notify_text[i]:find('\n', last_symb + 1)
			local ourstr = ''
			if last_symb ~= nil then -- создаем строку до ближайшего переноса строки
				ourstr = notify_text[i]:sub(prelast_symb, last_symb - 1)
				prelast_symb = last_symb + 1
			else
				ourstr = notify_text[i]:sub(prelast_symb, notify_text[i]:len())
			end
			text_len[#text_len + 1] = renderGetFontDrawTextLength(font, ourstr) -- считаем длину текста
			str = str + 1
		end
		local y_size = 20 + str * renderGetFontDrawHeight(font) + 3 * (str - 1) -- 20 – высота "бортиков" (до текста + после текста), 3 – доп. высота (отступ между строками)
		local timerdur = os.clock() - notify_timeopen[i] -- время с момента добавления уведомления
		if timerdur < 0.3 then -- 0.3 – время "раскрывания" (анимация движения вправо)
			x_pos = timerdur / 0.3 * (notify_x_pos + notify_x_size) - notify_x_size
		else
			timerdur = notify_timeclose[i] - os.clock() -- время до закрывания
			if timerdur > 0 and timerdur < 0.3 then -- 0.3 – время "скрывания" (анимация влево)
				x_pos = timerdur / 0.3 * (notify_x_pos + notify_x_size) - notify_x_size
			elseif timerdur > -0.2 and timerdur <= 0 then -- верхние уведомления съезжают вниз. 0.2 – время съезжания
				local new_y_pos = y_pos - y_size - 20 -- 20 – расстояние между соседними уведомлениями
				y_pos = new_y_pos - timerdur / 0.2 * (y_pos - new_y_pos)
				show_notify = false -- говорим, что уведомление показывать уже не надо
			elseif timerdur <= -0.2 then -- уведомление окончено. удаляем. 0.2 – время съезжания
				show_notify = false -- говорим, что уведомление показывать уже не надо
				table.remove(notify_timeopen, i)
				table.remove(notify_timeclose, i)
				table.remove(notify_text, i)
				i = i - 1
			end
		end
		if show_notify then
			y_pos = y_pos - y_size - 20 -- 20 – расстояние между соседними уведомлениями
			renderDrawCircleBox(notify_x_size, y_size, x_pos, y_pos, 8, 0x0D0000000) -- 8 – радиус закругления
			local text_y = y_pos + 10 -- 10 – высота "бортика" до текста
			last_symb = 1
			local tcolor = 0xFFFFFF -- текущий цвет
			local u = 1
			local text_x = x_pos + (notify_x_size - text_len[u]) / 2 -- позиция текста по X координате
			local current_str_st = 1 -- начало текущей строки (до переноса / до следующего цвета)
			while last_symb <= notify_text[i]:len() do
				if last_symb == notify_text[i]:len() then -- если последний символ
					local current_str = notify_text[i]:sub(current_str_st, last_symb)
					renderFontDrawText(font, current_str, text_x, text_y, 0xFF000000 + tcolor, true) -- рисуем строку текста уведомления
				elseif notify_text[i]:sub(last_symb, last_symb) == '\n' then
					u = u + 1
					local current_str = notify_text[i]:sub(current_str_st, last_symb - 1)
					renderFontDrawText(font, current_str, text_x, text_y, 0xFF000000 + tcolor, true) -- рисуем строку текста уведомления
					current_str_st = last_symb + 1
					text_x = x_pos + (notify_x_size - text_len[u]) / 2
					text_y = text_y + (renderGetFontDrawHeight(font) + 3) -- 3 – отступ между строками
				else -- если обычный символ (не перенос и не последний)
					local hex_color = true
					local hex_number = 0 -- сам новый цвет
					if last_symb <= notify_text[i]:len() - 7 and notify_text[i]:sub(last_symb, last_symb) == '{' and notify_text[i]:sub(last_symb + 7, last_symb + 7) == '}' then -- если формат: {......}
						local symbs = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' }
						local symbs2 = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' }
						for k = last_symb + 1, last_symb + 6 do -- обходим все 6 внутренних (между скобочками) символов
							local correct_symb = false
							for numb, hex_symb in pairs(symbs) do -- обходим все числа HEX системы
								if notify_text[i]:sub(k, k) == hex_symb or notify_text[i]:sub(k, k) == symbs2[numb] then
									correct_symb = true
									hex_number = hex_number * 0x10 + (numb - 1)
									break
								end
							end
							if not correct_symb then -- если некорретный символ, то выкидываем из цикла и не обращаем внимание
								hex_color = false
								break
							end
						end
					else
						hex_color = false -- говорим, что нету изменения цвета
					end
					if hex_color then
						local current_str = notify_text[i]:sub(current_str_st, last_symb - 1) -- записываем "текущую" строку
						renderFontDrawText(font, current_str, text_x, text_y, 0xFF000000 + tcolor, true) -- рисуем строку текста уведомления
						text_x = text_x + renderGetFontDrawTextLength(font, current_str)
						last_symb = last_symb + 7 -- все элементи {......} скипаем
						current_str_st = last_symb + 1
						tcolor = hex_number
					end
				end
				last_symb = last_symb + 1
			end
		end
		i = i + 1
  end
end

function renderDrawCircleBox(sizex, sizey, posx, posy, radius, color)
	sizex = sizex - 2 * radius
	sizey = sizey - 2 * radius
	posx = posx + radius
	posy = posy + radius
	renderDrawBox(posx - radius, posy, radius, sizey, color)
	renderDrawBox(posx + sizex, posy, radius, sizey, color)
	renderDrawBox(posx, posy - radius, sizex, sizey + 2 * radius, color)
	for i = posx + sizex, posx + sizex + radius - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx + sizex)) * (i - (posx + sizex)))
		renderDrawBox(i, posy - dist, 1, dist, color)
	end
	for i = posx - radius, posx - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx - 1)) * (i - (posx - 1)))
		renderDrawBox(i, posy - dist, 1, dist, color)
	end
	for i = posx + sizex, posx + sizex + radius - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx + sizex)) * (i - (posx + sizex)))
		renderDrawBox(i, posy + sizey, 1, dist, color)
	end
	for i = posx - radius, posx - 1 do
		local dist = math.sqrt(radius * radius - (i - (posx - 1)) * (i - (posx - 1)))
		renderDrawBox(i, posy + sizey, 1, dist, color)
	end
end
