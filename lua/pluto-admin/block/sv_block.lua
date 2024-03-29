util.AddNetworkString "pluto_block"

admin.blocks = admin.blocks or setmetatable({}, {__mode = "k"})
admin.steamid_cache = admin.steamid_cache or setmetatable({}, {__mode="v"})

local modes = {
	[true] = "Voice",
	[false] = "Chat",
}

net.Receive("pluto_block", function(len, cl)
	local ply = net.ReadEntity()
	local is_voice = net.ReadBool()
	local block = net.ReadBool()
	if (not IsValid(ply) or not ply:IsPlayer()) then
		return
	end


	admin.blocks[cl] = admin.blocks[cl] or {Voice = {}, Chat = {}}
	admin.blocks[cl][modes[is_voice]][ply:SteamID64()] = block and true or nil

	local sply, scl, type = pluto.db.steamid64(ply), pluto.db.steamid64(cl), is_voice and 0 or 1


	if (block) then
		pluto.db.simplequery("INSERT INTO pluto_blocks (blocker, blockee, type) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE type = type", {scl, sply, type}, function() end)
	else
		pluto.db.simplequery("DELETE FROM pluto_blocks WHERE blocker = ? AND blockee = ? AND type = ?", {scl, sply, type}, function() end)
	end

	net.Start "pluto_block"
		net.WriteString(ply:SteamID64())
		net.WriteBool(is_voice)
		net.WriteBool(block)
	net.Send(cl)
end)

hook.Add("PlayerCanHearPlayersVoice", "pluto_block", function(listener, speaker)
	if (not admin.blocks[listener]) then
		return
	end
	
	if (admin.blocks[listener].Voice[speaker:SteamID64()]) then
		return false
	end
end)

hook.Add("PlayerCanSeePlayersChat", "pluto_block", function(text, _, listener, speaker)
	if (not IsValid(speaker)) then
		return
	end

	if (not admin.blocks[listener]) then
		return
	end

	if (speaker.Formatted) then
		return
	end

	if (admin.blocks[listener].Chat[speaker:SteamID64()]) then
		return false
	end
end)

local db_modes = {
	[0] = "Voice",
	"Chat"
}
hook.Add("PlayerAuthed", "pluto_block", function(p, stmd)
	stmd = util.SteamIDTo64(stmd)

	admin.steamid_cache[stmd] = p

	admin.blocks[p] = admin.blocks[p] or {Voice = {}, Chat = {}}
	pluto.db.simplequery("SELECT CAST(blockee AS CHAR) as blockee, type FROM pluto_blocks WHERE blocker = ?", {stmd}, function(data)
		if (not IsValid(p)) then
			return
		end

		for _, d in ipairs(data) do
			admin.blocks[p][db_modes[d.type]][d.blockee] = true
			net.Start "pluto_block"
				net.WriteString(d.blockee)
				net.WriteBool(d.type == 0)
				net.WriteBool(true)
			net.Send(p)
		end
	end)
end)