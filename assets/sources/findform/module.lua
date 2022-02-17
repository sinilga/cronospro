local conditions = {}
local education = {}
local career = {}
local address = {}

function Форма_Load ( form, event )

--	Отчеркиваем область условий
	Line("edge",Me.btnFind.Y - 15)
	
--	Контроль ввода (стаж и возраст)
	local age_ctrl = {Me.txtAgeFrom, Me.txtAgeTo, Me.txtExperience }
	for _, ctrl in pairs(age_ctrl) do
		ctrl.ContentChange = AgeTypeCheck
		if ctrl.Name:match("^txtAge") then
			ctrl.TypeValidationCompleted = AgeValidation
		else	
			ctrl.TypeValidationCompleted = ExperienceValidation
		end	
	end
end

function Line(name, y)
--	Создание горизонтальной линии (панель высотой 1px)
	local line = Panel(name,"",0,y,Me.Width,1)
	line.Transparent = false
	line.BackColor = Color.ControlDark
	line.TabStop = false
	Me:AddControl(line)
end

function btnFind_Click( control, event )
--	Выполнение отбора записей
	local req, err = MakeRequest()
	if req then
		local rs = GetBank():StringRequest(req)
		if not rs then 
			MsgBox("При выполнении запроса произошла ошибка\r\n"..req)
		elseif rs.Count == 0 then
			MsgBox("Подходящих записей не найдено")
		else
		--	отображение найденных записей
			if conditions.experience then
				rs = FilterByExperience(rs)
			end	
			GetBank():GetBase("ЛЦ"):OpenReview(rs)
			Me.WindowState = Form.Minimized
		end
	else
		MsgBox(err)
	end
end

function makedate(val,mode)
--	пустое значение: дата отсутствует
	if val == "" then
		return DateTime.Now
	end
	local date = DateTime(val)
	if date.IsValid and date <= DateTime.Now then
		return date
	elseif date.IsValid then	
		return DateTime.Now
	end
	
--	обработка неполных дат
	if not mode or mode == "min" then
		val = val:gsub("^00%.","01.")
		val = val:gsub("%.00%.",".01.")
		return DateTime(val)
	else
		local day, month, year = unpack(val:split(".",0,true,tonumber))
		if month == 0 then
			month = 12
		end
		if day == 0 then
			local last = {31,28,31,30,31,30,31,31,30,31,30,31}
			day = last[month]
		end		
		date = DateTime()
		date.Year, date.Month, date.Day  = year, month, day
		return date
	end	
end

function FilterByExperience(rs)
--	фильтрация по стажу
	for rec in rs.Records do
		local td_rs = rec:GetValue(90,"ТД")
		if conditions.career then
			td_rs:StringRequest("ОТ "..conditions.career)
		end	
		local exp = DateTimeSpan()
		for td in td_rs.Records do
			if td:GetValue(1) ~= "" then
				local start = makedate(td:GetValue(1))
				local finish = makedate(td:GetValue(2),"max")
				exp = exp + (finish - start)
			end	
		end
		if exp.Days/365 < conditions.experience then
			rs:Remove(rec.SN)
		end
	end	
	return rs
end

function MakeRequest()
--	Формирование строчной записи запроса
	local req = "ОТ ЛЦ01"
	
	conditions = {}
	
--	возраст	
	if Me.txtAgeFrom.Text ~= "" then
		local cur_year = DateTime.Now.Year
		local val = tonumber(Me.txtAgeFrom.Text)
		table.insert(conditions,"9 МР 31.12."..(cur_year - val))
	end

	if Me.txtAgeTo.Text ~= "" then
		local cur_year = DateTime.Now.Year
		local val = tonumber(Me.txtAgeTo.Text)
		table.insert(conditions,"9 БР 00.00."..(cur_year - val))
	end
	
--	стаж
	AgeValidation({Control = Me.txtExperience})
	if Me.txtExperience.Text ~= "" then
		conditions.experience = tonumber(Me.txtExperience.Text)
	end
	
--	образование
	if #education > 0 then
		local tmp = {}
		table.foreach(education, function(k,item) tmp[k] = "4 РВ "..item:quote([["]]) end)
		conditions.edu = "ОБ02 "..table.concat(tmp, " ИЛИ ")
		table.insert(conditions,"201 ОБ02")
	end
	
--	опыт работы	
	if #career > 0 then
		local tmp = {}
		table.foreach(career, function(k,item) tmp[k] = "3 РВ "..item:quote([["]]) end)
		conditions.career = "ТД03 "..table.concat(tmp, " ИЛИ ")
		table.insert(conditions,"90 ТД03")
	end

--	место проживания	
	if table.count(address) > 0 then
		local tmpAreas = {}
		for area,cities in pairs(address) do
			local s = "1 РВ "..area
			if #cities > 0 then
				local tmp = {}
				table.foreach(cities, function(k,item) tmp[k] = "3 РВ "..item:quote([["]]) end)
				s = s.." И "..table.concat(tmp," ИЛИ ")
			end
			table.insert(tmpAreas,"("..s..")")
		end
		conditions.address = "АД04 "..table.concat(tmpAreas, " ИЛИ ")
		table.insert(conditions,"80 АД04")
	end

	if #conditions > 0 then
		req = req.." "..table.concat(conditions," И ")
		if conditions.edu then
			req = req.." "..conditions.edu
		end
		if conditions.career then 
			req = req.." "..conditions.career
		end
		if conditions.address then
			req = req.." "..conditions.address
		end
	end
		
	return req
end

function AgeTypeCheck(event)
--	контроль ввода в полях возраста и стажа
	local control = event.Control
	if control.Text:match("%D") then
		control.ForeColor = Color.Red
	else	
		control.ForeColor = Color.DimGray
	end
end

function AgeValidation( event )
	local min, max = 14, 65
	local control = event.Control
	local val = control.Text:trim()
	
-- 	очистка от нецифровых символов в начале и в конце строки
	val = val:gsub("^%D+","")
	val = val:gsub("%D+$","")
	if not val:match("%D") then
		control.Text = tonumber(val)
		return
	end

--	проверка на диапазон (напр., 20-50 )	
	val = val:gsub("%s+%-","-")
	val = val:gsub("%-%s+","-")
	if val:match("%d+%-%d+") then
		local st, ed = val:match("(%d+)%-(%d+)")
		local st_ed = st..ed
		st = tonumber(st)
		ed = tonumber(ed)
		st_ed = tonumber(st_ed)
		if ed > st and st >= min and st <= max and ed <= max then
			Me.txtAgeFrom.Text = st
			Me.txtAgeTo.Text = ed
			return
		end
	end
	
--	проверка на случайно набранный нецифровой символ (2r5)
	if val:match("%d+%D%d+") then
		local st_ed = val:match("%d+%D%d+"):gsub("%D","")
		st_ed = tonumber(st_ed)
		if st_ed <= max then
			control.Text = st_ed
			return
		end
	end
	
--	последний рубеж
	control.Text = val:match("%d+")
end

function ExperienceValidation( event )
	local min, max = 0, 20
	local control = event.Control
	local val = control.Text:trim()
	
-- 	очистка от нецифровых символов в начале и в конце строки
	val = val:gsub("^%D+","")
	val = val:gsub("%D+$","")
	if not val:match("%D") then
		control.Text = tonumber(val)
		return
	end

--	проверка на случайно набранный нецифровой символ (2r5)
	if val:match("%d+%D%d+") then
		local st_ed = val:match("%d+%D%d+"):gsub("%D","")
		st_ed = tonumber(st_ed)
		if st_ed <= max then
			control.Text = st_ed
			return
		end
	end
	
--	последний рубеж
	control.Text = val:match("%d+")
end

function btnEducation_Click( control, event )
	args = {field = "ОБ4", title="Направления подготовки",selection = education}
	GetBank():OpenForm("словарик",0,Me,args)
	if args.ModalResult == 1 then
		education = args.selection
		Me.txtEducation.Text = table.concat(education,"; ")
	end
end

function btnCareer_Click( control, event )
	args = {field = "ТД3", title="Опыт работы",selection = career}
	GetBank():OpenForm("словарик",0,Me,args)
	if args.ModalResult == 1 then
		career = args.selection
		Me.txtCareer.Text = table.concat(career,"; ")
	end
end

function btnAddress_Click( control, event )
	args = {selection = address}
	GetBank():OpenForm("Города",0,Me,args)
	if args.ModalResult == 1 then
		address = args.selection
		local tmpAreas = {}
		for area, cities in pairs(address) do
			if #cities > 0 then
				table.insert(tmpAreas,cities.Name..": "..table.concat(cities,","))
			else	
				table.insert(tmpAreas,cities.Name) 
			end	
		end
		Me.txtAddress.Text = table.concat(tmpAreas,"; ")
	end
end
