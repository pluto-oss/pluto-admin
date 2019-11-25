local color_name = Color(255, 0, 0)
local color_text = Color(230, 230, 230, 255)
local color_important = Color(0, 255, 0)

local function name(x)
	local ply = player.GetBySteamID64(x)
	print(x, ply)
	if (IsValid(ply)) then
		return ply:Nick()
	end

	ply = player.GetBySteamID(x)
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
			admin.chatf(color_name, user:Nick(), color_text, " has banned ", color_name, name(info.Player))
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

			admin.chatf(color_name, user:Nick(), color_text, " has slain ", color_name, name(info.Player))
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
				admin.chatf(color_name, user:Nick(), color_text, " ran slaynr on ", color_name, name(info.Player))
				return true
			end
		end,
	},
	po = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			}
		},
		Do = function(user, info)
			local function printf(...)
				if (IsValid(user)) then
					user:PrintMessage(HUD_PRINTCONSOLE, string.format(...))
				else
					pprintf(...)
				end
			end

			pluto.db.query("SELECT CAST(banned_user as CHAR) as banned_user, CAST(banner as CHAR) as banner, bantime, endtime, reason,\
				IF(endtime IS NOT NULL, TIMESTAMPDIFF(SECOND, bantime, endtime), 0) as ban_diff,\
				(endtime < CURRENT_TIMESTAMP) as expired,\
				_banned.displayname as banned_name, _updater.displayname as updater_name, _banner.displayname as banner_name,\
				unban_reason, unbanned, CAST(unbanned_by as CHAR) as unbanned_by,\
				CAST(updated_by AS CHAR) as updated_by, updatetime FROM pluto_bans\
\
				LEFT OUTER JOIN pluto_player_info _banned ON _banned.steamid = pluto_bans.banned_user\
				LEFT OUTER JOIN pluto_player_info _banner ON _banner.steamid = pluto_bans.banner\
				LEFT OUTER JOIN pluto_player_info _updater ON _updater.steamid = pluto_bans.updated_by\
				WHERE banned_user = ?", {info.Player}, function(err, q, d)

				printf("Bans for %s:", info.Player)
				for i, ban in pairs(d) do
					printf("%i: %s\n\t%s [%s] was banned at %s by %s [%s]\n\t\tLength: %s\n\t\tReason: %s", i, ban.unbanned == 1 and "(UNBANNED)" or ban.expired == 1 and "(EXPIRED)" or "",
						ban.banned_name, ban.banned_user, ban.bantime, ban.banner_name or "???", ban.banner, ban.ban_diff == 0 and "Permanent" or ban.ban_diff .. " minutes", ban.reason)

					if (ban.unbanned == 1) then
						printf("\n\t\tUnbanned by %s [%s]: %s", ban.updater_name or "CONSOLE", ban.updated_by, ban.unban_reason)
					end

					if (ban.updated_by) then
						printf("\n\t\tLast updated at %s by %s [%s]", ban.updatetime, ban.updater_name or "", ban.updated_by)
					end

					printf "\n"
				end
			end)

			return true
		end,
	},

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