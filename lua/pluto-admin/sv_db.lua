hook.Add("PlutoDatabaseInitialize", "pluto_admin_init", function(db)
	pluto.db.transact {
		{
			[[CREATE TABLE IF NOT EXISTS pluto_player_info (
				steamid BIGINT UNSIGNED NOT NULL PRIMARY KEY,
				rank VARCHAR(16) NOT NULL DEFAULT "user",
				first_join TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
				last_join TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
				time_played INT UNSIGNED NOT NULL DEFAULT 0,
				last_server INT UNSIGNED NOT NULL,
				displayname VARCHAR(64) NOT NULL
			)]]
		},
		{
			[[CREATE TABLE IF NOT EXISTS pluto_punishments (
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
			)]]
		},
		{
			[[CREATE PROCEDURE IF NOT EXISTS pluto_punish (
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
					UPDATE pluto_punishments SET updating_user = banner, reason = _reason, endtime = _endtime WHERE idx = i;
				END IF;
			END]]
		},
		{
			[[CREATE PROCEDURE IF NOT EXISTS pluto_punish_revoke (
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
			END]]
		},
		{
			[[CREATE PROCEDURE IF NOT EXISTS pluto_ban (
				user BIGINT UNSIGNED,
				actor BIGINT UNSIGNED,
				_reason VARCHAR(255),
				seconds INT UNSIGNED
			) BEGIN
				CALL pluto_punish('ban', user, actor, _reason, seconds);
			END]]
		},
	}:wait(true)
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

	pluto.db.transact({
		{ "INSERT INTO pluto_player_info (steamid, displayname, last_server) VALUES (?, ?, INET_ATON(?)) ON DUPLICATE KEY UPDATE displayname = VALUE(displayname), last_server = VALUE(last_server), last_join = CURRENT_TIMESTAMP", {ply, nick, game.GetIPAddress():match"^[^:]+"} },
		{ "SELECT rank FROM pluto_player_info WHERE steamid = ?", {ply}, function(err, q)
			return cb(not err and q:getData()[1].rank or "user")
		end }
	})
end

function admin.updatetime(ply)
	if (not ply.AdminJoin) then
		ply.AdminJoin = os.time()
		return
	end

	local add = os.time() - ply.AdminJoin
	ply.AdminJoin = os.time()

	pluto.db.query("UPDATE pluto_player_info SET time_played = time_played + ? WHERE steamid = ?", {add, pluto.db.steamid64(ply)}, function() end)
end

function admin.setrank(ply, rank)
	pluto.db.query("UPDATE pluto_player_info SET rank = ? WHERE steamid = ?", {rank, pluto.db.steamid64(ply)}, function(err, q)
		if (err) then
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
end)

function admin.punish(type, ply, reason, minutes, actor, cb)
	local steamid = pluto.db.steamid64(ply)
	banner = banner ~= 0 and banner and pluto.db.steamid64(actor) or 0

	pluto.db.query("CALL pluto_punish(?, ?, ?, ?, ?)", {type, steamid, banner, reason, math.floor(minutes * 60)}, cb or function() end)
end

function admin.punish_revoke(type, ply, reason, revoker)
	unbanner = unbanner and pluto.db.steamid64(unbanner) or 0
	ply = ply and pluto.db.steamid64(ply) or 0

	pluto.db.query("CALL pluto_punish_revoke(?, ?, ?, ?)", {type, ply, unbanner, reason or ""}, function(err, q)
		if (err) then
			return
		end
	end)
end

function admin.ban(ply, reason, minutes, banner)
	local steamid = pluto.db.steamid64(ply)
	admin.punish("ban", ply, reason, minutes, banner, function()
		local ply = player.GetBySteamID64(steamid)
		if (IsValid(ply)) then
			ply:Kick(reason)
		end
	end)
end

function admin.unban(ply, reason, unbanner)
	return admin.punish_revoke("ban", ply, reason, unbanner)
end

hook.Add("CheckPassword", "pluto_bans", function(sid)
	pluto.db.query("SELECT reason, CAST(acting_user AS CHAR) as banner, IF(endtime IS NULL, 0, TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP, endtime)) as seconds_remaining,\
		actor.displayname as acting_name \
		FROM pluto_punishments \
		LEFT OUTER JOIN pluto_player_info actor ON actor.steamid = pluto_punishments.acting_user\
		WHERE effected_user = ? AND punishment = 'ban' AND NOT (revoked = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP)", {sid}, function(err, q)
		if (err) then
			return
		end

		local data = q:getData()[1]

		if (data) then
			game.KickID(util.SteamIDFrom64(sid), admin.formatban(data.reason, data.acting_name, data.banner, data.seconds_remaining))
		end
	end)
end)