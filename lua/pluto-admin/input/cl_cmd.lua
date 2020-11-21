concommand.Add("admin", function(ply, cmd, args)
	local cmd = args[1]

	local cmdtype = admin.commands[cmd]
	if (not cmdtype) then
		return print("failed, no command!")
	end

	for i, argtype in ipairs(cmdtype.args) do
		local arg = admin.args[argtype.Type]
		if (not args[i + 1] and not argtype.Optional) then
			print("failed, no " .. argtype.Name:lower())
			return
		end
	end

	net.Start "pluto-admin-cmd"
	admin.args.cmd:NetworkWrite(args[1])

	for i, argtype in ipairs(cmdtype.args) do
		local arg = admin.args[argtype.Type]
		if (arg:NetworkWrite(args[i + 1] or argtype.Optional and "No reason given")) then
			error("error arg " .. i)
		end
	end

	net.SendToServer()
end, admin.autocomplete, "pluto-admin admin command")