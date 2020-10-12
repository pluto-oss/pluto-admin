util.AddNetworkString "pluto-admin-cmd"

function admin.chatf(...)
	ttt.chat(...)
end

net.Receive("pluto-admin-cmd", function(len, cl)
	local cmd = admin.args.cmd:NetworkRead()

	local cmdtype = admin.commands[cmd]
	if (not cmdtype) then
		return
	end

	local args = {}

	for i, argtype in ipairs(cmdtype.args) do
		local arg = admin.args[argtype.Type]

		args[argtype.Name or argtype.Type] = arg:NetworkRead()
	end

	if (admin.hasperm(cl:GetUserGroup(), cmd)) then
		cl:PrintMessage(HUD_PRINTCONSOLE, cmdtype.Do(cl, args) and "Command successfully ran." or "Command failed.")
	else
		cl:PrintMessage(HUD_PRINTCONSOLE, "You do not have permission.")
	end
end)

hook.Add("PlayerSay", "pluto_admin_chat", function(ply, text, team)
	if (team or text:sub(1, 1) ~= "@") then
		return
	end

	text = text:sub(2)

	local msg

	if (admin.hasperm(ply:GetUserGroup(), "rdm")) then
		local usergroup = admin.ranks[ply:GetUserGroup()]
		msg = {
			Color(27, 171, 61),
			"[",
			usergroup.color,
			usergroup.PrintName,
			Color(27, 171, 61),
			"] ",
			ttt.roles.Innocent.Color,
			ply:Nick(),
			white_text,
			": " .. text
		}
	else
		msg = {
			Color(27, 171, 61),
			"[",
			Color(136, 21, 22),
			"REQUEST",
			Color(27, 171, 61),
			"] ",
			ttt.roles.Traitor.Color,
			ply:Nick(),
			white_text,
			": " .. text
		}
	end

	for _, oply in pairs(player.GetAll()) do
		if (oply == ply or admin.hasperm(oply:GetUserGroup(), "rdm")) then
			pluto.inv.message(oply)
				:write("chatmessage", pluto.chat.determineTypes(msg), "admin")
			:send()
		end
	end

	return ""
end)