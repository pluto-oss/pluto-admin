util.AddNetworkString "pluto-admin-cmd"

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

	local usergroup = admin.users[cl:SteamID()] or "user"

	if (admin.hasperm(cl:GetUserGroup(), cmd)) then
		cmdtype.Do(cl, args)
	end
end)
