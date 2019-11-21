net.Receive("pluto-admin-cmd", function(len, cl)
	local stuff = {}
	for i = 1, net.ReadUInt(8) do
		if (net.ReadBool()) then
			stuff[i] = net.ReadString()
		else
			stuff[i] = net.ReadColor()
		end
	end

	chat.AddText(unpack(stuff))
end)


hook.Add("TTTPopulateSettingsMenu", "admin_settings", function()
	local real_cat = vgui.Create "EditablePanel"
	real_cat:SetTall(310)
	real_cat:Dock(TOP)
	local cat = real_cat:Add "EditablePanel"
	cat:Dock(FILL)

	cat.Commands = cat:Add "tttrw_dropdown"
	cat.Commands:Dock(LEFT)
	cat.Commands:SetWide(150)
	cat.Commands:DockMargin(0, 0, 8, 0)

	cat.Args = cat:Add "EditablePanel"
	cat.Args:Dock(FILL)

	local done = false
	for cmd, data in SortedPairs(admin.commands) do
		local btn = cat.Commands:AddButton(cmd, function()

			if (IsValid(cat.Args)) then
				cat.Args:Remove()
			end

			local get_args = {}

			cat.Args = cat:Add "ttt_settings_category"
			cat.Args:Dock(FILL)

			local run = cat.Args:AddLabelButton("Run " .. cmd)
			run:DockMargin(0, 0, 0, 0)

			function run:DoClick()
				local args = {
					{
						Type = admin.args.cmd,
						Data = cmd
					}
				}
				for i, arg in ipairs(get_args) do
					args[#args + 1] = {
						Type = arg.Type,
						Data = arg.Panel:GetValue()
					}
				end

				net.Start "pluto-admin-cmd"
				for _, arg in ipairs(args) do
					if (arg.Type:NetworkWrite(arg.Data)) then
						error("error arg " .. i)
					end
				end
				net.SendToServer()
			end

			for i, arg in ipairs(data.args) do
				local argtype = admin.args[arg.Type].CreateInputPanel and admin.args[arg.Type] or admin.args.string

				get_args[i] = {
					Type = argtype,
					Panel = argtype:CreateInputPanel(arg, cat.Args)
				}
			end

			return true
		end)

		if (not done) then
			done = true
			btn:DoClick()
		end
	end

	ttt.settings:AddTab("Admin", real_cat)
end)