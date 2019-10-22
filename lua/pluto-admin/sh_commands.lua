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
	slaynr = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			}
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (IsValid(ply)) then
				ply.Slays = (ply.Slays or 0) + 1
				return true
			end
		end,
	}
}

hook.Add("TTTRemoveIneligiblePlayers", "admin_slaynr", function(plys)
	local remove = {}

	for i = #plys, 1, -1 do
		if (plys[i].Slays and plys[i].Slays > 0) then
			remove[#remove + 1] = i
		end
	end

	if (#plys - #remove < GetConVar "ttt_minimum_players":GetInt()) then
		return
	end

	for _, idx in ipairs(remove) do
		local ply = plys[idx]
		table.remove(plys, idx)
	end
end)

hook.Add("TTTBeginRound", "admin_slaynr", function()
	for k, v in pairs(player.GetAll()) do
		if (v.Slays) then
			v.Slays = math.max(v.Slays - 1, 0)
		end
	end
end)