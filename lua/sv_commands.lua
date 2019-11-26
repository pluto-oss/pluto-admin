util.AddNetworkString "pluto-admin-cmd"

function admin.chatf(...)
	net.Start "pluto-admin-cmd"
		net.WriteUInt(select("#", ...), 8)
		for i = 1, select("#", ...) do
			local arg = select(i, ...)
			if (IsColor(arg)) then
				net.WriteBool(false)
				net.WriteColor(arg)
			else
				net.WriteBool(true)
				net.WriteString(tostring(arg))
			end
		end
	net.Broadcast()
end

local PLAYER = FindMetaTable "Player"

function PLAYER:AdminChat(...)
	net.Start "pluto-admin-cmd"
		net.WriteUInt(select("#", ...), 8)
		for i = 1, select("#", ...) do
			local arg = select(i, ...)
			if (IsColor(arg)) then
				net.WriteBool(false)
				net.WriteColor(arg)
			else
				net.WriteBool(true)
				net.WriteString(tostring(arg))
			end
		end
	net.Send(self)
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
