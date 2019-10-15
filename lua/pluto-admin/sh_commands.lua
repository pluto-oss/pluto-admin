admin.commands = {
	ban = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Time",
				Type = "time",
			},
			--[[{
				Name = "Reason",
				Type = "string",
			}]]
		},
		-- TODO(meep): NOT HERE IN FUTURE!!
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (not IsValid(ply)) then
				return
			end

			ply:Ban(info.Time, true)
		end
	}
}