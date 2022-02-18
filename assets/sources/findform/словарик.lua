function Форма_Load ( form, event )
	
	if Arg and type(Arg.field) == "string" and Arg.field:match("%u%u%d+") then
		if type(Arg.selection) ~= "table" then
			Arg.selection = {}
		end
		fill_list(Arg.field, Arg.selection)
	end
	
	if Arg and Arg.title then
		Me.Text = Arg.title
	end
	
	Me.labInfo.Text = "Выбрано: "..Me.listbox1.CheckedCount
	Me.Height = 600
	
	Me.ApplyControl = Me.btnOk
	Me.CancelControl = Me.btnCancel
end

function fill_list(field,selection)
	Me.listbox1:Clear()
	local code, fnum = field:match("(%u%u)(%d+)")
	local req = "ОТ "..code.."01 "..fnum.." УЗ"
	local rs = GetBank():StringRequest(req)
	local strings = {}
	if rs and rs.Count > 0 then
		for rec in rs.Records do
			val = rec:GetValue(tonumber(fnum)):trim()
			if val ~= "" then
				table.insert(strings,vals[i])
			end	
		end
		table.sort(strings)
		for i=1,#strings do
			Me.listbox1:Add(strings[i])
			if table.getkey(selection,strings[i]) then
				Me.listbox1:SetItemChecked(Me.listbox1.ItemsCount)
			end
		end
	end
	if Me.listbox1.ItemsCount > 0 then
		Me.listbox1.SelectedIndex = 1
	end	
end

function btnCancel_Click( control, event )
	if Arg then
		Arg.ModalResult = 0
	end
	Me:CloseForm()
end

function btnOk_Click( control, event )
	if Arg then
		Arg.ModalResult = 1
		Arg.selection = Me.listbox1.CheckedItems
	end
	Me:CloseForm()
end

function listbox1_CheckStateChanged( event )
	Me.labInfo.Text = "Выбрано: "..Me.listbox1.CheckedCount
end

function Форма_UnloadForm( form, mode, event )
	if mode == Form.UECloseScript then
		return true 
	end

	if not Arg or type(Arg.selection) ~= "table" then
		return true 
	end
	
	if #Arg.selection ~= Me.listbox1.CheckedCount or SelectionChanged() then
		local answ = MsgBox("Сохранить изменения?",BtnYesNoCancel+IconQuestion)
		if answ == IdCancel then
			return false
		end	
		if answ == IdYes then
			Arg.ModalResult = 1
			Arg.selection = Me.listbox1.CheckedItems
		elseif answ == IdNo then
			Arg.ModalResult = 0
		end
	end	
	return true
end

function SelectionChanged()
	local items = Me.listbox1.CheckedItems
	local n = Me.listbox1.CheckedCount
	for i=1,n do
		if not table.getkey(Arg.selection,items[i]) then
			return true
		end
	end
	return false
end
