local ARG = admin.args.int or {}
admin.args.int = ARG

function ARG:AutoComplete(int)
	return {tostring(int)}
end

function ARG:NetworkWrite(int)
	net.WriteUInt(int, 32)
end

function ARG:NetworkRead()
	return net.ReadUInt(32)
end

function ARG:CreateInputPanel(arginfo, prnt)
	return prnt:AddTextEntry(arginfo.Name or arginfo.Type, true, "")
end
