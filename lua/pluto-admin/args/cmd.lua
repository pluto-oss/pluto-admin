local ARG = admin.args.cmd or {}
admin.args.cmd = ARG

function ARG:AutoComplete(text)
	local r = {}
	for name in pairs(admin.commands) do
		if (name == text) then
			table.insert(r, 1, text)
		elseif (text == "" or name:find(text, 1, true)) then
			r[#r + 1] = name
		end
	end
	return r
end

function ARG:NetworkWrite(text)
	net.WriteString(text)
end

function ARG:NetworkRead()
	return net.ReadString()
end