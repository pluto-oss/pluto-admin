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

net.Receive("pluto-admin-afk", function(len, cl)
	GetConVar("tttrw_afk"):SetBool(net.ReadBool())
end)

hook.Add("PlutoGetChatCommand", "pluto_admin_command", function(text)
	local texts = string.Explode(" ", text)
	local cmd = table.remove(texts, 1)
	if (not cmd) then
		return
	end

	local cmdtype = admin.commands[cmd]
	if (not cmdtype) then
		return
	end

	local argnum = #cmdtype.args

	local args = {cmd}
	local current = ""
	for k, str in ipairs(texts) do
		if (current == "" and string.StartWith(str, "\"")) then
			if (string.EndsWith(str, "\"")) then
				table.insert(args, string.sub(str, 2, #str - 1))
			else
				current = string.sub(str, 2)
			end
			continue 
		end

		if (current ~= "") then
			if (string.EndsWith(str, "\"")) then
				table.insert(args, current .. " " .. string.sub(str, 1, #str - 1))
				current = ""
			else
				current = current .. " " .. str
			end
			if (k == #texts) then
				table.insert(args, current)
			end
			continue
		end

		if (#args == argnum and k ~= #texts) then
			current = str
			continue
		end

		table.insert(args, str)
	end

	RunConsoleCommand("admin", unpack(args))
	return true
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

timer.Simple(5, function()
	if (pluto and pluto.chat and pluto.chat.cl_commands) then
		for _, cmd in ipairs(pluto.chat.cl_commands) do
			if (not cmd.aliases or cmd.aliases[1] ~= "commands") then
				continue
			end

			if (not admin or not admin.commands) then
				return
			end

			local commands = {}

			for name, cmd in pairs(admin.commands) do
				table.insert(commands, ttt.roles.Traitor.Color)
				table.insert(commands, name)
				table.insert(commands, white_text)
				table.insert(commands, ", ")
			end

			table.remove(commands)

			local old = cmd.Run

			cmd.Run = function(channel)
				old(channel)

				chat.AddText("Here is a list of all ", ttt.roles.Traitor.Color, "admin ", white_text, "commands:")
				chat.AddText(unpack(commands))
			end
		end
	end
end)