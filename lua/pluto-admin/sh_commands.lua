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

			pluto.db.query("SELECT CAST(effected_user as CHAR) as banned_user, CAST(acting_user as CHAR) as banner, starttime as bantime, endtime, reason,\
				IF(endtime IS NOT NULL, TIMESTAMPDIFF(SECOND, starttime, endtime), 0) as ban_diff,\
				(endtime < CURRENT_TIMESTAMP) as expired,\
				_banned.displayname as banned_name, _updater.displayname as updater_name, _banner.displayname as banner_name, _unbanner.displayname as unbanner_name,\
				revoke_reason as unban_reason, revoked as unbanned, CAST(revoking_user as CHAR) as unbanned_by,\
				CAST(updating_user AS CHAR) as updated_by, updatetime, punishment FROM pluto_punishments\
\
				LEFT OUTER JOIN pluto_player_info _banned ON _banned.steamid = pluto_punishments.effected_user\
				LEFT OUTER JOIN pluto_player_info _banner ON _banner.steamid = pluto_punishments.acting_user\
				LEFT OUTER JOIN pluto_player_info _unbanner ON _unbanner.steamid = pluto_punishments.revoking_user\
				LEFT OUTER JOIN pluto_player_info _updater ON _updater.steamid = pluto_punishments.updating_user\
				WHERE effected_user = ?", {info.Player}, function(err, q, d)

				printf("Past offences for %s:", info.Player)
				for i, ban in pairs(d) do
					printf("%i: %s %s\n\t%s [%s] was banned at %s by %s [%s]\n\t\tLength: %s\n\t\tReason: %s", i, ban.punishment, ban.unbanned == 1 and "(REVOKED)" or ban.expired == 1 and "(EXPIRED)" or "",
						ban.banned_name, ban.banned_user, ban.bantime, ban.banner_name or "???", ban.banner, ban.ban_diff == 0 and "Permanent" or ban.ban_diff .. " seconds", ban.reason)

					if (ban.unbanned == 1) then
						printf("\n\t\tUnbanned by %s [%s]: %s", ban.unbanner_name or "CONSOLE", ban.unbanned_by, ban.unban_reason)
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

local function punishment(n, _do, _undo)
	admin.commands[n] = {
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
		Do = function(user, info)
			if (_do) then
				_do(info.Player, info.Reason, info.Time, user)
			else
				admin.punish(n, info.Player, info.Reason, info.Time, user)
			end
			admin.chatf(color_name, user:Nick(), color_text, " has ran " .. n .. " on ", color_name, name(info.Player))

			return true
		end
	}

	admin.commands["un" .. n] = {
		args = {
			{
				Name = "SteamID",
				Type = "userid"
			},
			{
				Name = "Reason",
				Type = "string"
			}
		},
		Do = function(user, info)
			if (_undo) then
				_undo(info.Player, info.Reason, user)
			else
				admin.punish_revoke(n, info.Player, info.Reason, info.Time, user)
			end

			admin.chatf(color_name, user:Nick(), color_text, " has ran un" .. n .. " on ", color_name, name(info.Player))
			return true
		end
	}
end

punishment("ban", admin.ban, admin.unban)

punishment("mute")

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