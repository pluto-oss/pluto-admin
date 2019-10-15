local ARG = admin.args.string or {}
admin.args.string = ARG

function ARG:AutoComplete(text)
	return {text}
end

function ARG:NetworkWrite(text)
	net.WriteString(text)
end

function ARG:NetworkRead()
	return net.ReadString()
end