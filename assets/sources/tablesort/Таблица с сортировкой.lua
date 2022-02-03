function Форма_Load( form, event )
	Me.table1.NumberRows = 1
	Me.table1.NumberCols = 4
	Me.table1.SideHdrWidth = 0
	
	Me.table1:SetCellText(0,-1,"Фамилия")
	Me.table1:SetCellText(1,-1,"Имя")
	Me.table1:SetCellText(2,-1,"Отчество")
	Me.table1:SetCellText(3,-1,"Дата рождения")

	Me.table1.TopHdrRows = 2
	Me.table1.TopHdrHeight = 30
	Me.table1:SetRowHeight(-2,0)
	Me.table1:SetRowHeight(-1,30)
	
	Me.table1.SortEvaluate = OnSortEvaluate
	filltable()
end

function filltable()
	local base = GetBank():GetBase("ЛЦ")
	local rs = base.RecordSet
	Me.table1.NumberRows = rs.Count
	local row = 0
	for rec in rs.Records do
		Me.table1:SetCellText(0,row,rec:GetValue(2))
		Me.table1:SetCellText(1,row,rec:GetValue(3))
		Me.table1:SetCellText(2,row,rec:GetValue(4))
		Me.table1:SetCellText(3,row,rec:GetValue(9))
		row = row + 1
	end
	Me.table1:BestFit(0,3)
end

function table1_CellClick( event )
	if event.RowIndex == -1 then
		if Me.table1:GetCellText(event.ColumnIndex,-2) == "a" then
			for i=1,4 do
				Me.table1:SetCellText(i-1,-2,"")
			end
			Me.table1:SetCellText(event.ColumnIndex,-2,"d")
			Me.table1:Sort(event.ColumnIndex,TableControl.SortDescending)
			Me.Text = "Таблица с сортировкой: "..Me.table1:GetCellText(event.ColumnIndex,-1).." [-]"
		else	
			for i=1,4 do
				Me.table1:SetCellText(i-1,-2,"")
			end
			Me.table1:SetCellText(event.ColumnIndex,-2,"a")
			Me.table1:Sort(event.ColumnIndex,TableControl.SortAscending)
			Me.Text = "Таблица с сортировкой: "..Me.table1:GetCellText(event.ColumnIndex,-1).." [+]"
		end
		
	end
end

function OnSortEvaluate( event )
	local a,b
	if event.ColumnIndex == 3 then
		a, b = event.Data1, event.Data2
		a = a:gsub("^(%d%d)%.(%d%d)%.(%d+)","%2-%1-%3")
		b = b:gsub("^(%d%d)%.(%d%d)%.(%d+)","%2-%1-%3")
		event.Handled = true
		if a > b then 
			return 1	
		elseif a < b then
			return -1
		else
			return 0
		end	
	elseif event.ColumnIndex >= 0 and event.ColumnIndex < 3 then
		a, b = event.Data1, event.Data2
		event.Handled = true
		if #a > #b then 
			return 1	
		elseif #a < #b then
			return -1
		else
			return 0
		end	
	else 
		return 0
	end
end
