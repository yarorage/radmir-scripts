local ultragui = require("ultrabot_res.ultragui")

local buffer = {
	window = ultragui.imgui.ImBool(true),
	active = ultragui.imgui.ImBool(true),
	tiph = ultragui.imgui.ImBool(true),
	tsm = ultragui.imgui.ImBool(true),
	zcrist = ultragui.imgui.ImBool(true),
	siph = ultragui.imgui.ImBool(true),
	tonok = ultragui.imgui.ImBool(true),
	svarka = ultragui.imgui.ImBool(true),
	scrist = ultragui.imgui.ImBool(true),
	zapiph = ultragui.imgui.ImBool(true),
	sothp = ultragui.imgui.ImBool(true),
	fcrist = ultragui.imgui.ImBool(true),
	nouappl = ultragui.imgui.ImBool(true),
	nout = ultragui.imgui.ImBool(true),
	rcrist = ultragui.imgui.ImBool(true),
	dvigalo = ultragui.imgui.ImBool(true),
	trapka = ultragui.imgui.ImBool(true),
	telek = ultragui.imgui.ImBool(true),
	gdrub = ultragui.imgui.ImBool(true),
	vazik = ultragui.imgui.ImBool(true),
	sysblock = ultragui.imgui.ImBool(true),
	lobglass = ultragui.imgui.ImBool(true),
	ximia = ultragui.imgui.ImBool(true),
	gdtworub = ultragui.imgui.ImBool(true),
	gitoskut = ultragui.imgui.ImBool(true),
	shpric 	= ultragui.imgui.ImBool(true),
	gdcherv = ultragui.imgui.ImBool(true),
	sputnik = ultragui.imgui.ImBool(true),
	diski = ultragui.imgui.ImBool(true),
	butalka = ultragui.imgui.ImBool(true),
	gdpatdes = ultragui.imgui.ImBool(true),
	sltelik = ultragui.imgui.ImBool(true),
	gonsiden = ultragui.imgui.ImBool(true),
	ahikspatr = ultragui.imgui.ImBool(true),
	zapcknoutu = ultragui.imgui.ImBool(true),
	oldsiden = ultragui.imgui.ImBool(true),
	otmach 	= ultragui.imgui.ImBool(true),
	modvolg = ultragui.imgui.ImBool(true),
	crackbank = ultragui.imgui.ImBool(true),
	oldrulamg = ultragui.imgui.ImBool(true),
	metall 	= ultragui.imgui.ImBool(true),
	modrafik = ultragui.imgui.ImBool(true),
	stanok 	= ultragui.imgui.ImBool(true),
	rulmersamg = ultragui.imgui.ImBool(true),
	glushak = ultragui.imgui.ImBool(true),
	ceif = ultragui.imgui.ImBool(true),
	key = ultragui.imgui.ImBool(true),
	rulnissgtr 	= ultragui.imgui.ImBool(true),
	blacksiden 	= ultragui.imgui.ImBool(true),
	akkum = ultragui.imgui.ImBool(true),
	inst = ultragui.imgui.ImBool(true),
	zapkrulamg 	= ultragui.imgui.ImBool(true)
}

local obj = {
	[10711] = { name = "Золотой рубль", arg = buffer.gdrub },
	[10716] = { name = "Отмычка", arg = buffer.otmach },
	[10715] = { name = "Системный блок", arg = buffer.sysblock },
	[10707] = { name = "Телефон Nokia 3310", arg = buffer.tonok },
	[10505] = { name = "Ноутбук", arg = buffer.nout },
	[10825] = { name = "Глушитель", arg = buffer.glushak },
	[13923] = { name = "Красный кристалл", arg = buffer.rcrist },
	[10828] = { name = "Запчасти к ноутбуку", arg = buffer.zapcknoutu },
	[10818] = { name = "Бутылка", arg = buffer.butalka },
	[13952] = { name = "Лобовое стекло", arg = buffer.lobglass },
	[1044] 	= { name = "Металл", arg = buffer.metall },
	[10816] = { name = "Тряпка", arg = buffer.trapka },
	[10708] = { name = "Телефон Nokia", arg = buffer.sothp },
	[10826] = { name = "Сломанный iPhone", arg = buffer.siph },
	[13948] = { name = "Химия", arg = buffer.ximia },
	[10833] = { name = "Колесо", arg = buffer.diski },
	[13922] = { name = "Спутник", arg = buffer.sputnik },
	[13929] = { name = "Модель РАФ-2203", arg = buffer.modrafik },
	[10819] = { name = "Шприц", arg = buffer.shpric },
	[10706] = { name = "Гоночное сиденье", arg = buffer.gonsiden },
	[10709] = { name = "Телефон Samsung", arg = buffer.tsm },
	[10702] = { name = "Ящик с патронами", arg = buffer.ahikspatr },
	[10704] = { name = "Старое сиденье", arg = buffer.oldsiden },
	[13928] = { name = "Модель ВАЗ-2109", arg = buffer.vazik },
	[13925] = { name = "Зеленый кристалл", arg = buffer.zcrist },
	[10710] = { name = "Телефон iPhone", arg = buffer.tiph },
	[10509] = { name = "Сломанный телевизор", arg = buffer.sltelik },
	[13926] = { name = "Синий кристалл", arg = buffer.scrist },
	[13950] = { name = "Старый руль AMG", arg = buffer.oldrulamg },
	[10719] = { name = "Руль Nissan GTR", arg = buffer.rulnissgtr },
	[10827] = { name = "Запчасти к iPhone", arg = buffer.zapiph },
	[10713] = { name = "Золотой червонец", arg = buffer.gdcherv },
	[13930] = { name = "Гироскутер", arg = buffer.gitoskut },
	[13927] = { name = "Модель \"Волга\"", arg = buffer.modvolg },
	[10712] = { name = "Золотые два рубля", arg = buffer.gdtworub },
	[10723] = { name = "Ноутбук Apple", arg = buffer.nouappl },
	[10703] = { name = "Сломанный", arg = buffer.crackbank },
	[13924] = { name = "Фиолетовый кристалл", arg = buffer.fcrist },
	[10720] = { name = "Старый сейф", arg = buffer.ceif },
	[15411] = { name = "КЛЮЧИ", arg = buffer.key },
	[10508] = { name = "Телевизор", arg = buffer.telek },
	[10718] = { name = "Руль Mercedes AMG", arg = buffer.rulmersamg },
	[10832] = { name = "Сварка", arg = buffer.svarka },
	[13949] = { name = "Двигатель", arg = buffer.dvigalo },
	[10714] = { name = "Золотые пятьдесят", arg = buffer.gdpatdes },
	[10721] = { name = "Станок", arg = buffer.stanok },
	[13951] = { name = "Запчасти к рулю AMG", arg = buffer.zapkrulamg },
	[10831] = { name = "Инструменты", arg = buffer.inst },
	[10834] = { name = "Инструменты", arg = buffer.akkum },
	[634] 	= { name = "Инструменты", arg = buffer.blacksiden }
}

function svalka()
    for k, v in pairs(svalkaobj.obj) do
        if v.arg.v then 
            renderobj(k, v.name) 
        end
    end 	
end

function renderobj(model, name)
	for _, v in pairs(getAllObjects()) do
        if isObjectOnScreen(v) then
            local result, oX, oY, oZ = getObjectCoordinates(v)
            local x1, y1 = convert3DCoordsToScreen(oX,oY,oZ)
            local objmodel = getObjectModel(v)
            local x2,y2,z2 = getCharCoordinates(PLAYER_PED)
            local x10, y10 = convert3DCoordsToScreen(x2,y2,z2)
            distance = string.format("%.0f", getDistanceBetweenCoords3d(oX,oY,oZ, x2, y2, z2))
            if objmodel == model then 
                renderFontDrawText(renderCreateFont('Discovery Font', 10), name.."\n{AFEEEE}Дистанция: "..distance, x1, y1, -1) 
            end
        end
	end
end


return {obj = obj, buffer = buffer} 