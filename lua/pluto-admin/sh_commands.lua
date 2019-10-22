local color_name = Color(255, 0, 0)
local color_text = Color(230, 230, 230, 255)
local color_important = Color(0, 255, 0)

local function name(x)
	local ply = player.GetBySteamID64(x)
	if (IsValid(ply)) then
		return ply:Nick()
	end

	return x
end

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
			admin.chatf(color_name, user:Nick(), color_text, " has banned ", color_name, info.Player)
			return true
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

			admin.chatf(color_name, user:Nick(), color_text, " has slain ", color_name, info.Player)
			return true
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
			timer.Simple(2, function()
				RunConsoleCommand("changelevel", info.MapName)
			end)
			admin.chatf(color_name, user:Nick(), color_text, " changed the map to ", color_important, info.MapName)
			return true
		end,
	},
	setrank = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Rank",
				Type = "string"
			}
		},
		Do = function(user, info)
			local usergroup, last = CAMI.GetUsergroup(admin.hasperm(user:GetUserGroup(), "setrank"))

			while (usergroup and usergroup ~= last) do
				if (usergroup.Name == info.Rank) then
					break
				end

				last = usergroup
				usergroup = CAMI.GetUsergroup(usergroup.Inherits)
			end

			if (usergroup.Name == info.Rank) then
				admin.setrank(info.Player, info.Rank)
				admin.chatf(color_name, user:Nick(), color_text, " set the rank of ", color_name, name(info.Player), color_text, " to ", color_important, info.Rank)
				return true
			end
		end,
	},
}