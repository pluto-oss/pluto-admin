admin.ranks = {
	developer = {
		PrintName = "Developer",
		inherits = "advisor",
		aliases = {
			"dev",
		},
		color = Color(237, 34, 11),
		permissions = {
			setrank = "developer",
			ac = true
		},
	},
	designer = {
		PrintName = "Designer",
		inherits = "donator",
		aliases = {
			"squibble",
		},
		color = color_black,
		permissions = {},
	},
	advisor = {
		PrintName = "Advisor",
		inherits = "leadadmin",
		aliases = {
			"adv",
		},
		color = Color(52, 212, 55),
		permissions = {
			setrank = "leadadmin",
			tradeban = true,
		},
	},
	leadadmin = {
		PrintName = "Lead Admin",
		inherits = "admin",
		aliases = {
			"lead",
			"la",
			"ladmin",
			"leada",
		},
		permissions = {
			ban_custom = true,
			kick = true,
			["goto"] = true,
			unban = true,
		},
		color = Color(255, 106, 214),
	},
	admin = {
		PrintName = "Administrator",
		inherits = "mod",
		aliases = {
			"administrator",
			"ad",
		},
		permissions = {
			bring = true,
			unmute = true,
		},
		color = color_black,
	},
	mod = {
		PrintName = "Moderator",
		inherits = "supportstaff",
		aliases = {
			"moderator",
			"m",
		},
		color = Color(112, 166, 255),
	},
	supportstaff = {
		PrintName = "Support Staff",
		inherits = "user",
		aliases = {
			"ss",
			"sstaff",
			"support staff",
			"support",
		},
		permissions = {
			rdm = true,

			ban = true,
			map = true, -- only for now, need to fix bugs preventing round end
			mute = true,
			gag = true,
			ungag = true,
			afk = true,
			slaynr = true,
			slay = true,
		},
		color = Color(131, 231, 225),
	},
	donator = {
		PrintName = "Donator",
		inherits = "user",
		permissions = {
			votemap = true,
		}
	},
	user = {
		PrintName = "User",
		permissions = {
			po = true,
		}
	},
}

hook.Add("TTTGetPlayerColor", "pluto_admin", function(ply)
	local rank = admin.ranks[ply:GetUserGroup()]
	if (rank and rank.color) then
		return rank.color
	end
end)

function admin.hasperm(usergroup, perm)
	usergroup = CAMI.GetUsergroup(usergroup)
	local last
	while (usergroup and usergroup ~= last) do
		local mygroup = admin.ranks[usergroup.Name]
		if (mygroup and mygroup.permissions and mygroup.permissions[perm] ~= nil) then
			return mygroup.permissions[perm]
		end

		last = usergroup
		usergroup = CAMI.GetUsergroup(usergroup.Inherits)
	end

	return false
end

admin.hardcoded = {}

for usergroup, info in pairs(admin.ranks) do
	CAMI.RegisterUsergroup({
		Name = usergroup,
		Inherits = info.inherits
	}, "pluto-admin")
end

for group in pairs(admin.ranks) do
	if (admin.hasperm(group, "rdm") and Damagelog) then
		Damagelog:AddUser(group, 4, true)
	end
end