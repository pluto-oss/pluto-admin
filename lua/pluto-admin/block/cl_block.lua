admin.cl_blocks = admin.cl_blocks or {Voice = {}, Chat = {}}

hook.Add("TTTRWPopulateScoreboardOptions", "pluto_block", function(menu, ply)
	if (ply == LocalPlayer()) then
		return
	end

	menu:AddOption((admin.cl_blocks.Chat[ply:SteamID64()] and "Unblock " or "Block ") .. ply:Nick().. "'s Chat", function()
		net.Start "pluto_block"
			net.WriteEntity(ply)
			net.WriteBool(false)
			net.WriteBool(not admin.cl_blocks.Chat[ply:SteamID64()])
		net.SendToServer()
	end)

	menu:AddOption((admin.cl_blocks.Voice[ply:SteamID64()] and "Unblock " or "Block ") .. ply:Nick().. "'s Voice", function()
		net.Start "pluto_block"
			net.WriteEntity(ply)
			net.WriteBool(true)
			net.WriteBool(not admin.cl_blocks.Voice[ply:SteamID64()])
		net.SendToServer()
	end)
end)

net.Receive("pluto_block", function()
	local who = net.ReadString()

	local what = net.ReadBool() and "Voice" or "Chat"
	admin.cl_blocks[what][who] = net.ReadBool() and true or nil
end)