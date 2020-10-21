hook.Add("PlutoDatabaseInitialize", "pluto_admin_init", function()
	pluto.db.instance(function(db)
		mysql_query(db, [[
			CREATE TABLE IF NOT EXISTS pluto_player_info (
				steamid BIGINT UNSIGNED NOT NULL PRIMARY KEY,
				rank VARCHAR(16) NOT NULL DEFAULT "user",
				first_join TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
				last_join TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
				time_played INT UNSIGNED NOT NULL DEFAULT 0,
				last_server INT UNSIGNED NOT NULL,
				displayname VARCHAR(64) NOT NULL,
				experience INT UNSIGNED NOT NULL DEFAULT 0,
				tokens INT UNSIGNED NOT NULL DEFAULT 0
			)
		]])
		mysql_query(db, [[
			CREATE TABLE IF NOT EXISTS pluto_punishments (
				idx INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,

				punishment VARCHAR(16) NOT NULL,

				effected_user BIGINT UNSIGNED NOT NULL,
				reason VARCHAR(255) NOT NULL,
				acting_user BIGINT UNSIGNED NOT NULL,
				endtime TIMESTAMP NULL,
				starttime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

				updating_user BIGINT UNSIGNED,
				updatetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

				revoked BOOLEAN NOT NULL DEFAULT FALSE,
				revoking_user BIGINT UNSIGNED,
				revoke_reason VARCHAR(255),

				INDEX USING HASH(effected_user)
			)
		]])
		mysql_query(db, [[
			CREATE PROCEDURE IF NOT EXISTS pluto_punish (
				_punishment VARCHAR(16),
				user BIGINT UNSIGNED,
				actor BIGINT UNSIGNED,
				_reason VARCHAR(255),
				seconds INT UNSIGNED
			) BEGIN
				DECLARE i INT UNSIGNED DEFAULT 0;
				DECLARE _endtime TIMESTAMP DEFAULT NULL;

				SELECT idx INTO i FROM pluto_punishments WHERE effected_user = user AND punishment =  _punishment AND NOT (revoked = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP);

				IF seconds != 0 THEN
					SET _endtime = TIMESTAMPADD(SECOND, seconds, CURRENT_TIMESTAMP);
				END IF;

				IF i = 0 THEN
					INSERT INTO pluto_punishments (effected_user, reason, acting_user, endtime, punishment) VALUES (user, _reason, actor, _endtime, _punishment);
				ELSE
					UPDATE pluto_punishments SET updating_user = user, reason = _reason, endtime = _endtime WHERE idx = i;
				END IF;
			END
		]])
		mysql_query(db, [[
			CREATE PROCEDURE IF NOT EXISTS pluto_punish_revoke (
				_punishment VARCHAR(16),
				user BIGINT UNSIGNED,
				revoker BIGINT UNSIGNED,
				_reason VARCHAR(255)
			) BEGIN
				DECLARE i INT UNSIGNED DEFAULT 0;

				SELECT idx INTO i FROM pluto_punishments WHERE effected_user = user AND punishment = _punishment AND NOT (revoked = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP);

				IF i != 0 THEN
					UPDATE pluto_punishments SET revoking_user = revoker, revoke_reason = _reason, revoked = TRUE WHERE idx = i;
				END IF;
			END
		]])
		mysql_query(db, [[
			CREATE PROCEDURE IF NOT EXISTS pluto_ban (
				user BIGINT UNSIGNED,
				actor BIGINT UNSIGNED,
				_reason VARCHAR(255),
				seconds INT UNSIGNED
			) BEGIN
				CALL pluto_punish('ban', user, actor, _reason, seconds);
			END
		]])
		mysql_query(db, [[
			CREATE TABLE IF NOT EXISTS pluto_blocks (blocker BIGINT UNSIGNED NOT NULL, blockee BIGINT UNSIGNED NOT NULL, type INT UNSIGNED NOT NULL, PRIMARY KEY (blocker, blockee, type), INDEX(blocker))
		]])
		mysql_query(db, [[
			CREATE PROCEDURE IF NOT EXISTS pluto_warn (
				user BIGINT UNSIGNED,
				actor BIGINT UNSIGNED,
				_reason VARCHAR(255)
			) BEGIN
				CALL pluto_punish('warn', user, actor, _reason, 0);
			END
		]])
	end)
end)

function admin.formatban(reason, banner_name, banner, length)
	return string.format(
[[YOU ARE BANNED
Reason: %s
Banner: %s [%s]
Time remaining: %s]], reason, banner_name, banner == "0" and "CONSOLE" or banner or "n/a", length == 0 and "forever" or length .. " seconds")
end

function admin.getrank(ply, cb)
	local nick = ply
	ply = pluto.db.steamid64(ply)

	local p = player.GetBySteamID64(ply)
	if (IsValid(p)) then
		p.AdminJoin = os.time()
		nick = p:Nick()
	end

	pluto.db.simplequery([[
			INSERT INTO pluto_player_info (steamid, displayname, last_server) VALUES 
				(?, ?, INET_ATON(?)) 
				ON DUPLICATE KEY UPDATE displayname = VALUE(displayname), 
					last_server = VALUE(last_server),
					last_join = CURRENT_TIMESTAMP
		]], {ply, nick, game.GetIPAddress():match"^[^:]+"}
	)

	pluto.db.simplequery("SELECT rank FROM pluto_player_info WHERE steamid = ?", {ply}, function(dat, err)
		cb(dat and dat[1] and dat[1].rank or "user")
	end)
end

function admin.updatetime(ply)
	if (not ply.AdminJoin) then
		ply.AdminJoin = os.time()
		return
	end

	local add = os.time() - ply.AdminJoin
	ply.AdminJoin = os.time()

	pluto.db.simplequery("UPDATE pluto_player_info SET time_played = time_played + ? WHERE steamid = ?", {add, pluto.db.steamid64(ply)}, function() end)
end

function admin.setrank(ply, rank)
	pluto.db.simplequery("UPDATE pluto_player_info SET rank = ? WHERE steamid = ?", {rank, pluto.db.steamid64(ply)}, function(d)
		if (not d) then
			return
		end

		if (type(ply) == "string") then
			ply = player.GetBySteamID64(pluto.db.steamid64(ply))
		end

		if (TypeID(ply) == TYPE_ENTITY and IsValid(ply)) then
			ply:SetUserGroup(rank)
		end
	end)
end

hook.Add("PlayerDisconnected", "pluto_time", admin.updatetime)
hook.Add("ShutDown", "pluto_time", function()
	for _, ply in pairs(player.GetAll()) do
		admin.updatetime(ply)
	end
end)

hook.Add("PlayerAuthed", "pluto_admin", function(ply)
	admin.getrank(ply, function(rank)
		ply:SetUserGroup(rank)
	end)

	ply.Punishments = {}
	
	pluto.db.simplequery("SELECT reason, punishment, IF(endtime IS NULL, 0, TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP, endtime)) as seconds_remaining\
	FROM pluto_punishments \
	WHERE effected_user = ? AND NOT (revoked = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP)", {pluto.db.steamid64(ply)}, function(d)
		if (not d or not IsValid(ply)) then
			return
		end

		for _, data in ipairs(d) do
			local prev = ply.Punishments[data.punishment]
			if (not prev) then
				prev = {}
				ply.Punishments[data.punishment] = prev
			end

			prev.Reason = data.reason
			prev.Ending = math.max(prev.Ending or 0, data.seconds_remaining == 0 and math.huge or os.time() + data.seconds_remaining)

			if (prev.Ending > os.time() and admin["run" .. data.punishment]) then
				admin["run" .. data.punishment](ply, prev)
			end
		end
	end)
end)

function admin.punish(type, ply, reason, minutes, actor, cb)
	local steamid = pluto.db.steamid64(ply)
	actor = actor ~= 0 and actor and pluto.db.steamid64(actor) or 0

	pluto.db.simplequery("CALL pluto_punish(?, ?, ?, ?, ?)", {type, steamid, actor, reason, math.floor(minutes * 60)}, cb or function() end)

	local p = player.GetBySteamID64(steamid)

	if (not IsValid(p)) then
		return
	end

	local prev = p.Punishments[type]
	if (not prev) then
		prev = {}
		p.Punishments[type] = prev
	end

	prev.Reason = reason
	prev.Ending = math.max(prev.Ending or 0, minutes == 0 and math.huge or os.time() + minutes * 60)
end

function admin.punish_revoke(type, ply, reason, revoker)
	revoker = revoker and pluto.db.steamid64(revoker) or 0
	ply = ply and pluto.db.steamid64(ply) or 0

	pluto.db.simplequery("CALL pluto_punish_revoke(?, ?, ?, ?)", {type, ply, revoker, reason or ""}, function(d) end)

	local p = player.GetBySteamID64(ply)

	if (not IsValid(p)) then
		return
	end

	p.Punishments[type] = nil
end

function admin.ban(ply, reason, minutes, banner)
	local steamid = pluto.db.steamid64(ply)
	admin.punish("ban", steamid, reason, minutes, banner)
	local ply = player.GetBySteamID64(steamid)
	if (IsValid(ply)) then
		ply:Kick(reason)
	end
end

function admin.unban(ply, reason, unbanner)
	return admin.punish_revoke("ban", ply, reason, unbanner)
end

hook.Add("CheckPassword", "pluto_bans", function(sid)
	pluto.db.simplequery("SELECT reason, CAST(acting_user AS CHAR) as banner, IF(endtime IS NULL, 0, TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP, endtime)) as seconds_remaining,\
		actor.displayname as acting_name \
		FROM pluto_punishments \
		LEFT OUTER JOIN pluto_player_info actor ON actor.steamid = pluto_punishments.acting_user\
		WHERE effected_user = ? AND punishment = 'ban' AND NOT (revoked = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP)", {sid}, function(data)

		if (not data or not data[1]) then
			return
		end

		data = data[1]

		game.KickID(util.SteamIDFrom64(sid), admin.formatban(data.reason, data.acting_name, data.banner, data.seconds_remaining))
	end)
end)

hook.Add("PlayerSay", "pluto_mutes", function(s)
	local mute = s.Punishments and s.Punishments.mute

	if (mute and mute.Ending > os.time()) then
		s:ChatPrint(color_text, "You are ", color_important, "muted ", color_text, "for ", color_name, mute.Ending - os.time(), color_text, " more seconds because: ", color_important, mute.Reason)
		return false
	end
end)

hook.Add("PlayerCanHearPlayersVoice", "pluto_gags", function(_, s)
	local mute = s.Punishments and s.Punishments.gag

	if (mute and mute.Ending > os.time()) then
		if (not mute.NextNotif or mute.NextNotif < CurTime()) then
			s:ChatPrint(color_text, "You are ", color_important, "gagged ", color_text, "for ", color_name, mute.Ending - os.time(), color_text, " more seconds because: ", color_important, mute.Reason)
			mute.NextNotif = CurTime() + 20
		end
		return false
	end
end)