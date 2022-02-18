local pre_checked = {}

function Форма_Load( form, event )
	if not Arg then
		Arg = {}
	end
	if type(Arg.selection) ~= "table" then
		Arg.selection = {}
	end
	
--[[
	selection = {
		["801"] = {Name = "Россия", "Москва", "Серпухов", ...},
		["286"] = {Name = "Италия"},
	}	
]]	

	fill_list(Arg.selection or {})
	
	Me.ApplyControl = Me.btnOk
	Me.CancelControl = Me.btnCancel
end

function fill_list(selection)
	Me.tree1.ShowCheckBoxes = true
	Me.tree1.SmartCheck = true
	Me.tree1:DeleteAll()
	
	local rs = GetBank():StringRequest("ОТ АД01 1 УЗ 3")
	local tree_items = {}
	if not rs or rs.Count == 0 then
		return
	end
	local index = {}
	for rec in rs.Records do
		local code = rec:GetValue(1,1,false)
		local area = sl(3,code)
		if not tree_items[code] then
			tree_items[code] = {["Name"] = area}
			table.insert(index,{code,area})
		end
		local val = rec:GetValue(3)
		if val ~= "" then
			table.insert(tree_items[code],val)
		end	
	end
	table.sort(index, function(a,b) return a[2] < b[2] end)
	for k = 1,#index do
		code, cities = index[k][1], tree_items[index[k][1]]
		local node = Me.tree1:InsertItem(cities.Name)
		node.ItemData = code
		for i=1,#cities do
			table.sort(cities)
			local sub_node = Me.tree1:InsertItem(cities[i], node)
			if selection[code] and (#(selection[code]) == 0 or
				table.getkey(selection[code],cities[i])) then
				sub_node.Checked = true
				table.insert(pre_checked,sub_node.Id)
			end
		end
	end	
	
	Me.labInfo.Text = "Выбрано: "..Me.tree1.CheckedCount
	if #Me.tree1.RootItems > 0 then
		Me.tree1.RootItems[1].Selected = true
		Me.tree1.RootItems[1]:Expand()
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
		SaveSelections()
	end
	Me:CloseForm()
end

function SaveSelections()
	Arg.selection = {}
	local codes = Me.tree1.RootItems
	for i=1,#codes do
		local node = codes[i]
		if node.Checked then
			Arg.selection[node.ItemData] = {["Name"] = node.Text}
		else
			local cities = node.Children
			for j=1,#cities do
				if cities[j].Checked then
					if not Arg.selection[node.ItemData] then
						Arg.selection[node.ItemData] = {["Name"] = node.Text}
					end	
					table.insert(Arg.selection[node.ItemData],cities[j].Text)
				end	
			end	
		end	
	end	
end

function tree1_CheckStateChanged( event )
	Me.labInfo.Text = "Выбрано: "..Me.tree1.CheckedCount
end


function Форма_UnloadForm( form, mode, event )
	if mode == Form.UECloseScript then
		return true 
	end

	if not Arg or type(Arg.selection) ~= "table" then
		return true 
	end

	if SelectionChanged() then
		local answ = MsgBox("Сохранить изменения?",BtnYesNoCancel+IconQuestion)
		if answ == IdCancel then
			return false
		end	
		if answ == IdYes then
			Arg.ModalResult = 1
			SaveSelections()
		elseif answ == IdNo then
			Arg.ModalResult = 0
		end
	end	
	return true
end

function SelectionChanged()
	local t = Me.tree1:GetAllItems()
	for i=1,#t do
		local item = t[i].Text
		if t[i].ParentItem then
			if t[i].Checked and not table.getkey(pre_checked,t[i].Id) or
			   not t[i].Checked and table.getkey(pre_checked,t[i].Id) then
				return true
			end 
		end	
	end
	return false
end