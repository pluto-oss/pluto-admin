concommand.Add("admin", function(ply, cmd, args)
	local cmd = args[1]

	local cmdtype = admin.commands[cmd]
	if (not cmdtype) then
		return print("failed, no command!")
	end
	net.Start "pluto-admin-cmd"

	admin.args.cmd:NetworkWrite(args[1])

	for i, argtype in ipairs(cmdtype.args) do
		local arg = admin.args[argtype.Type]
		if (arg:NetworkWrite(args[i + 1])) then
			error("error arg " .. i)
		end
	end
		
	net.SendToServer()
end, function(cmd, str)
	local args = {}
	local nextarg = str:match "%s*()"
	local n
	if (str:len() >= nextarg) then
		repeat
			local pattern = "([^%s]*)%s*()"

			if (str:sub(nextarg, nextarg) == '"') then
				pattern = "\"([^\"]*)\"?%s*()"
			end

			args[#args + 1], n = str:sub(nextarg):match(pattern)

			nextarg = nextarg + n - 1
		until not nextarg or nextarg == str:len() + 1
	end

	local nextarg = str:find("%s", str:len()) ~= nil

	local ret = {}

	local command = admin.commands[args[1]]
	if (not nextarg and #args == 1 or not args[1]) then
		for _, opt in ipairs(admin.args.cmd:AutoComplete(args[1] or "")) do
			table.insert(ret, cmd .. " " .. opt)
		end
	elseif (command and command.args) then
		local argpos = (nextarg and 1 or 0) + #args - 1
		local curarg = command.args[argpos]
		if (curarg) then
			local argtype = admin.args[curarg.Type]

			if (argtype) then
				local real_args = {}
		
				for i = 1, argpos - 1 do
					real_args[i] = args[i + 1]
				end
		
				for i = argpos, #command.args do
					local cmdarg = command.args[i]

					local text = (cmdarg.Name or cmd.arg.Type):lower()

					if (cmdarg.optional) then
						text = "[" .. text .. "]"
					else
						text = "<" .. text .. ">"
					end
		
					real_args[i] = text
				end

				local complete = argtype:AutoComplete(args[argpos + 1] or "") or {}

				for _, text in ipairs(complete) do
					local next = {}
					for k, v in pairs(real_args) do
						next[k] = v
					end

					next[argpos] = text
					ret[#ret + 1] = cmd .. " " .. args[1] .. ' "' .. table.concat(next, '" "') .. '"'
				end

				if (#complete == 0) then
					ret[#ret + 1] = cmd .. " " .. args[1] .. ' "' .. table.concat(real_args, '" "') .. '"'
				end
			end
		end

	end


	if (#ret == 0) then
		ret[1] = cmd .. ' "' .. table.concat(args, '" "') .. '"'
	end

	return ret

end, "pluto-admin admin command")