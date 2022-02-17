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
			GetBank():GetBase("ЛЦ"):OpenReview(rs)
			Me.WindowState = Form.Minimized
		end
	else
		MsgBox(err)
	end
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
	if Me.txtExperience.Text ~= "" then
		conditions.experience = tonumber(Me.txtExperience.Text)
	end
	
	if #conditions > 0 then
		req = req.." "..table.concat(conditions," И ")
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
