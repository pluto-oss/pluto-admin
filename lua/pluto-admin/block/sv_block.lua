util.AddNetworkString "pluto_block"

admin.blocks = admin.blocks or setmetatable({}, {__mode = "k"})
admin.block_cache = {}

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
		pluto.db.query("INSERT INTO pluto_blocks (blocker, blockee, type) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE type = type", {scl, sply, type}, function() end)
	else
		pluto.db.query("DELETE FROM pluto_blocks WHERE blocker = ? AND blockee = ? AND type = ?", {scl, sply, type}, function() end)
	end

	net.Start "pluto_block"
		net.WriteString(ply:SteamID64())
		net.WriteBool(is_voice)
		net.WriteBool(block)
	net.Send(cl)
end)

hook.Add("TTTRWUpdateVoiceState", "pluto_block", function(ply, cache)
	if (not admin.blocks[ply]) then
		return
	end

	for oply, blocked in pairs(admin.blocks[ply].Voice) do
		if (admin.block_cache[oply]) then
			cache[admin.block_cache[oply]] = false
		end
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

	admin.block_cache[stmd] = p

	admin.blocks[p] = admin.blocks[p] or {Voice = {}, Chat = {}}
	pluto.db.query("SELECT CAST(blockee AS CHAR) as blockee, type FROM pluto_blocks WHERE blocker = ?", {stmd}, function(_, _, data)
		if (not IsValid(p)) then
			return
		end

		for _, d in pairs(data) do
			admin.blocks[p][db_modes[d.type]][d.blockee] = true
			net.Start "pluto_block"
				net.WriteString(d.blockee)
				net.WriteBool(d.type == 0)
				net.WriteBool(true)
			net.Send(p)
		end
	end)
end)