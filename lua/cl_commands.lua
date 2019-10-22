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
	-- MsgC(unpack(stuff))
end)
