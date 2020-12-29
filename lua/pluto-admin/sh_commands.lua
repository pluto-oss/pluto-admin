color_name = Color(255, 0, 0)
color_text = Color(230, 230, 230, 255)
color_important = Color(0, 255, 0)

local function name(x)
	local ply = player.GetBySteamID64(x)
	if (IsValid(ply)) then
		return ply:Nick()
	end

	ply = player.GetBySteamID(x)
	if (IsValid(ply)) then
		return ply:Nick()
	end

	return x
end

local timewords = {}
local function registertimeword(word, abbrev, duration)
	timewords[word] = duration
	timewords[word .. "s"] = duration
	timewords[abbrev] = duration
	table.insert(timewords, {
		Word = word,
		Abbrev = abbrev,
		Duration = duration
	})

	table.sort(timewords, function(a, b)
		return a.Duration > b.Duration
	end)
end

registertimeword("second", "s", 1)
registertimeword("minute", "m", 60)
registertimeword("hour",   "h", 60 * 60)
registertimeword("day",    "d", 60 * 60 * 24)
registertimeword("week",   "w", 60 * 60 * 24 * 7)
registertimeword("month",  "M", 60 * 60 * 24 * 28)

function admin.nicetime(playtime)
	local nicetime = {}

	for _, data in ipairs(timewords) do
		if (playtime >= data.Duration) then
			local amount = math.floor(playtime / data.Duration)
			playtime = playtime - amount * data.Duration
			table.insert(nicetime, amount .. " " .. data.Word .. (amount == 1 and "" or "s"))
		end
	end

	return table.concat(nicetime, " ")
end

function admin.fromnicetime(nicetime)
	local seconds = 0

	for number, timeword in nicetime:gmatch "([%d%.]+)%s*([^%s]+)" do
		number = tonumber(number)
		timeword = timeword:lower()

		if (not number or not timewords[timeword]) then
			return false
		end

		seconds = seconds + timewords[timeword] * number
	end

	return seconds
end

admin.commands = {
	mapvote = {
		args = {},
		Do = function(user)
			hook.Add("TTTEndRound", "mapvote_start", pluto.mapvote.start)
			admin.chatf(color_name, user:Nick(), color_text, " has forced a mapvote at the end of the round")
			return true
		end
	},
	slay = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Reason",
				Type = "string",
				Optional = true,
			}
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (not IsValid(ply) or not ply:Alive()) then
				return
			end

			ply:Kill()

			admin.chatf(color_name, user:Nick(), color_text, " has slain ", color_name, name(info.Player), color_text, " for: ", color_important, info.Reason)
			return true
		end,
	},
	gold = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			}
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (not IsValid(ply) or not ply:Alive()) then
				return
			end

			local rag = ttt.CreatePlayerRagdoll(ply, ply, DamageInfo())
			if (IsValid(rag)) then
				MakeGold(rag)
			end
			return true
		end
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
			local notallowed = admin.hasperm(user:GetUserGroup(), "setrank")
			local usergroup, last = CAMI.GetUsergroup(info.Rank)

			if (not admin.ranks[info.Rank]) then
				return false
			end

			while (usergroup and usergroup ~= last) do
				last = usergroup

				usergroup = CAMI.GetUsergroup(usergroup.Inherits)

				if (usergroup and usergroup.Name == notallowed) then
					return false
				end
			end

			admin.setrank(info.Player, info.Rank)
			usergroup = admin.ranks[info.Rank]
			admin.chatf(color_name, user:Nick(), color_text, " set the rank of ", color_name, name(info.Player), color_text, " to ", usergroup.color, usergroup.PrintName)
			return true
		end,
	},
	slaynr = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Reason",
				Type = "string",
				Optional = true,
			}
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (IsValid(ply)) then
				ply.Slays = (ply.Slays or 0) + 1
				admin.chatf(color_name, user:Nick(), color_text, " ran slaynr on ", color_name, name(info.Player), color_text, " for: ", color_important, info.Reason)
				return true
			end
		end,
	},
	boostmap = {
		args = {
			{
				Name = "Map",
				Type = "string",
			}
		},
		Do = function(user, info)
			if (pluto.mapvote.blacklisted[info.Map]) then
				user:ChatPrint "That map was played too recently."
				return
			end
			if (not table.HasValue(pluto.GetValidMaps(), info.Map)) then
				user:ChatPrint "That map cannot be played."
				return
			end

			if (not pluto.mapvote.boost(info.Map, user)) then
				user:ChatPrint "You cannot boost that map."
				return
			end

			admin.chatf(color_name, user:Nick(), color_text, " boosted ", color_important, info.Map)

			return true
		end,
	},
	rslaynr = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Reason",
				Type = "string",
				Optional = true,
			}
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (IsValid(ply) and ply.Slays and ply.Slays > 0) then
				ply.Slays = ply.Slays - 1
				admin.chatf(color_name, user:Nick(), color_text, " ran rslaynr on ", color_name, name(info.Player), color_text, " for: ", color_important, info.Reason)
				return true
			end
		end,
	},
	kick = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Reason",
				Type = "string",
			}
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (IsValid(ply)) then
				ply:Kick(info.Reason)
				admin.chatf(color_name, user:Nick(), color_text, " kicked ", color_name, name(info.Player), color_text, " for: ", color_important, info.Reason)
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

			pluto.db.simplequery("SELECT CAST(effected_user as CHAR) as banned_user, CAST(acting_user as CHAR) as banner, starttime as bantime, endtime, reason,\
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
				WHERE effected_user = ?", {info.Player}, function(d)

				if (not d) then
					return
				end

				printf("Past offences for %s:", info.Player)
				local offenses = {}
				for i, offense in ipairs(d) do
					if (not offenses[offense.punishment]) then
						offenses[offense.punishment] = {}
					end
					table.insert(offenses[offense.punishment], offense)
				end

				print "a"

				for type, punishments in pairs(offenses) do

					printf("---------------------- " .. type .. " ----------------------")
					for i, log in ipairs(punishments) do
						printf("%i: %s %s\n\t%s [%s] was affected at %s by %s [%s]\n\t\tLength: %s\n\t\tReason: %s", i, log.punishment, log.unbanned == 1 and "(REVOKED)" or log.expired == 1 and "(EXPIRED)" or "",
						log.banned_name, log.banned_user, log.bantime, log.banner_name or "???", log.banner, log.ban_diff == 0 and "Permanent" or log.ban_diff .. " seconds", log.reason)

						if (log.unbanned == 1) then
							printf("\n\t\tUndone by %s [%s]: %s", log.unbanner_name or "CONSOLE", log.unbanned_by, log.unban_reason)
						end

						printf "\n"
					end
				end

			end)

			return true
		end,
	},
	pa = {
		args = {
			{
				Name = "Message",
				Type = "string",
			}
		},
		Do = function(user, info)
			local rank = admin.ranks[user:GetUserGroup()]
			if (rank and info.Message and info.Message ~= "") then
				admin.chatf(white_text, "[", rank.color, rank.PrintName, white_text, "]: ", ttt.roles.Innocent.Color, info.Message, white_text, "\n- ", user:Nick())
			end
		end,
	},
	playtime = {
		args = {},
		Do = function(user, info)
			pluto.db.simplequery("SELECT time_played FROM pluto_player_info WHERE steamid = ?", {user:SteamID64()}, function(d)
				playtime = d[1].time_played

				local length = admin.nicetime(playtime)

				user:ChatPrint("You have played " .. length)
			end)

			return true
		end
	},
	warn = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Reason",
				Type = "string",
			}
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (IsValid(ply)) then
				pluto.db.simplequery("CALL pluto_warn(?, ?, ?)", {ply:SteamID64(), user:SteamID64(), info.Reason}, function(d, err)
					if (not d) then
						pwarnf("pluto_warn err: %s", err)
					end
				end)

				admin.chatf(color_name, user:Nick(), color_text, " warned ", color_name, name(info.Player), color_text, " for ", color_important, info.Reason)
				return true
			end
		end,
	},
	afk = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (IsValid(ply)) then
				net.Start("pluto-admin-afk")
				net.WriteBool(true)
				net.Send(ply)

				admin.chatf(color_name, user:Nick(), color_text, " has forced ", color_name, name(info.Player), color_text, " into spectator mode")
			end
		end,
	},
	unafk = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (IsValid(ply)) then
				net.Start("pluto-admin-afk")
				net.WriteBool(false)
				net.Send(ply)

				admin.chatf(color_name, user:Nick(), color_text, " has forced ", color_name, name(info.Player), color_text, " out of spectator mode")
			end
		end,
	},
	pm = {
		args = {
			{
				Name = "Player",
				Type = "userid",
			},
			{
				Name = "Message",
				Type = "string",
			},
		},
		Do = function(user, info)
			local ply = player.GetBySteamID64(info.Player)

			if (not info.Message or info.Message == "") then
				return
			end

			if (IsValid(ply) and IsValid(user)) then
				ply:ChatPrint(ttt.roles.Detective.Color, user:Nick(), white_text, " to ", ttt.roles.Detective.Color, "You", white_text, ": ", ttt.roles.Innocent.Color, info.Message)
				user:ChatPrint(ttt.roles.Detective.Color, "You", white_text, " to ", ttt.roles.Detective.Color, ply:Nick(), white_text, ": ", ttt.roles.Innocent.Color, info.Message)
			end

			for _, _ply in ipairs(player.GetAll()) do
				if (admin.hasperm(_ply:GetUserGroup(), "seepm") and ply ~= _ply and ply ~= user) then
					_ply:ChatPrint(ttt.roles.Detective.Color, user:Nick(), white_text, " sent to ", ttt.roles.Detective.Color, ply:Nick(), white_text, ": ",ttt.roles.Innocent.Color, info.Message)
				end
			end
		end,
	}
}

local function punishment(n)
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
			if (admin[n]) then
				admin[n](info.Player, info.Reason, info.Time, user)
			else
				admin.punish(n, info.Player, info.Reason, info.Time, user)
			end
			admin.chatf(color_name, user:Nick(), color_text, " used ", color_important, n, color_text, " on ", color_name, name(info.Player), color_text, "\nIt was ", color_important, "super effective", color_text, " for ", admin.nicetime(info.Time * 60), ": ", color_important, info.Reason)

			return true
		end
	}

	admin.commands["un" .. n] = {
		args = {
			{
				Name = "Player",
				Type = "userid"
			},
			{
				Name = "Reason",
				Type = "string"
			}
		},
		Do = function(user, info)
			if (admin["un" .. n]) then
				admin["un" .. n](info.Player, info.Reason, user)
			else
				admin.punish_revoke(n, info.Player, info.Reason, user)
			end

			admin.chatf(color_name, user:Nick(), color_text, " used un" .. n .. " on ", color_name, name(info.Player), color_text, ": ", color_important, info.Reason)
			return true
		end
	}
end

punishment "ban"

punishment "mute"
punishment "gag"
punishment "questban"

function admin.questban(ply, reason, time, user)
	admin.punish("questban", ply, reason, time, user)
	ply = player.GetBySteamID64(ply)
	if (IsValid(ply)) then
		ply:SetNWString("pluto_questban", reason)
	end
end

function admin.runquestban(ply, prev)
	if (IsValid(ply)) then
		ply:SetNWString("pluto_questban", prev.Reason)
	end
end

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