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
			{
				Name = "Reason",
				Type = "string",
			},
		},
		-- TODO(meep): NOT HERE IN FUTURE!!
		Do = function(user, info)
			admin.ban(info.Player, info.Reason, info.Time, user)
		end
	},
	slay = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (not IsValid(ply) or not ply:Alive()) then
				return
			end

			ply:Kill()
		end,
	},
	map = {
		args = {
			{
				Name = "MapName",
				Type = "string",
			}
		},
		Do = function(user, info)
			RunConsoleCommand("changelevel", info.MapName)
		end,
	},
}