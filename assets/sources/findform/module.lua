function Форма_Load ( form, event )
--	Отчеркиваем область условий
	Line("edge",Me.btnFind.Y - 15)
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
	return req
end
