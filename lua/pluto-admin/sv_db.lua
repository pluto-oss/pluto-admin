hook.Add("PlutoDatabaseInitialize", "pluto_admin_init", function(db)
	pluto.db.transact {
		{
			[[CREATE TABLE IF NOT EXISTS pluto_bans (
				idx INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
				banned_user BIGINT UNSIGNED NOT NULL,
				reason VARCHAR(255) NOT NULL,
				banner BIGINT UNSIGNED NOT NULL,
				endtime TIMESTAMP NULL,
				bantime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

				updated_by BIGINT UNSIGNED,
				updatetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

				unbanned BOOLEAN NOT NULL DEFAULT FALSE,
				unbanned_by BIGINT UNSIGNED,
				unban_reason VARCHAR(255),

				INDEX USING HASH(banned_user)
			)]]
		},
		{
			[[CREATE PROCEDURE IF NOT EXISTS pluto_ban(user BIGINT UNSIGNED,
				banner BIGINT UNSIGNED,
				_reason VARCHAR(255),
				seconds INT UNSIGNED
			) BEGIN
				DECLARE i INT UNSIGNED DEFAULT 0;
				DECLARE _endtime TIMESTAMP DEFAULT NULL;

				SELECT idx INTO i FROM pluto_bans WHERE banned_user = user AND NOT (unbanned = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP);

				IF seconds != 0 THEN
					SET _endtime = TIMESTAMPADD(SECOND, seconds, CURRENT_TIMESTAMP);
				END IF;

				IF i = 0 THEN
					INSERT INTO pluto_bans (banned_user, reason, banner, endtime) VALUES (user, _reason, banner, _endtime);
				ELSE
					UPDATE pluto_bans SET updated_by = banner, reason = _reason, endtime = _endtime WHERE idx = i;
				END IF;
			END]]
		},
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
		}
	}:wait(true)
end)

function admin.formatban(reason, banner, length)
	return string.format(
[[YOU ARE BANNED
Reason: %s
Banner: %s
Time remaining: %s]], reason, banner == "0" and "CONSOLE" or banner or "n/a", length == 0 and "forever" or length .. " seconds")
end

function admin.getrank(ply, cb)
	local nick = ply
	if (TypeID(ply) == TYPE_ENTITY and IsValid(ply)) then
		ply.AdminJoin = os.time()
		nick = ply:Nick()
	end

	pluto.db.transact({
		{ "INSERT INTO pluto_player_info (steamid, displayname, last_server) VALUES (?, ?, INET_ATON(?)) ON DUPLICATE KEY UPDATE displayname = VALUE(displayname), last_server = VALUE(last_server), last_join = CURRENT_TIMESTAMP", {pluto.db.steamid64(ply), nick, game.GetIPAddress():match"^[^:]+"} },
		{ "SELECT rank FROM pluto_player_info WHERE steamid = ?", {pluto.db.steamid64(ply)}, function(err, q)
			return cb(not err and q:getData()[1].rank or "user")
		end }
	})
end

function admin.updatetime(ply)
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


function admin.ban(ply, reason, minutes, banner)
	local steamid = pluto.db.steamid64(ply)
	banner = banner and pluto.db.steamid64(banner) or 0

	pluto.db.query("CALL pluto_ban(?, ?, ?, ?)", {steamid, banner, reason, math.floor(minutes * 60)}, print)

	local ply = player.GetBySteamID64(steamid)
	if (IsValid(ply)) then
		ply:Kick(reason)
	end
end

function admin.unban(ply, reason, unbanner)
	unbanner = unbanner and pluto.db.steamid64(unbanner) or 0
	ply = ply and pluto.db.steamid64(ply) or 0

	pluto.db.query("UPDATE pluto_bans SET unbanned = TRUE, unbanned_by = ?, unban_reason = ? WHERE banned_user = ? AND NOT (unbanned = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP)", {unbanner, reason or "", ply}, function(err, q)
		if (err) then
			return
		end
	end)
end

hook.Add("CheckPassword", "pluto_bans", function(sid)
	pluto.db.query("SELECT reason, CAST(banner AS CHAR) as banner, IF(endtime IS NULL, 0, TIMESTAMPDIFF(SECOND, CURRENT_TIMESTAMP, endtime)) as seconds_remaining FROM pluto_bans WHERE banned_user = ? AND NOT (unbanned = TRUE OR endtime IS NOT NULL AND endtime <= CURRENT_TIMESTAMP)", {sid}, function(err, q)
		if (err) then
			return
		end

		local data = q:getData()[1]

		if (data) then
			game.KickID(util.SteamIDFrom64(sid), admin.formatban(data.reason, data.banner, data.seconds_remaining))
		end
	end)
end)