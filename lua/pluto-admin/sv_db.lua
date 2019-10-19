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
    }:wait(true)
end)

function admin.formatban(reason, banner, length)
    return string.format(
[[YOU ARE BANNED
Reason: %s
Banner: %s
Time remaining: %s]], reason, banner == "0" and "CONSOLE" or banner or "n/a", length == 0 and "forever" or length .. " seconds")
end

function admin.ban(ply, reason, minutes, banner)
    local steamid = pluto.db.steamid64(ply)
    banner = banner and pluto.db.steamid64(banner) or 0

    pluto.db.query("CALL pluto_ban(?, ?, ?, ?)", {steamid, banner, reason, math.floor(minutes * 60)}, print)

    local ply = player.GetBySteamID64(steamid)
    if (IsValid(ply)) then
        ply:Kick(admin.formatban(reason, banner, minutes * 60))
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