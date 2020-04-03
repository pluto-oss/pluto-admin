admin.ranks = {
	developer = {
		PrintName = "Developer",
		inherits = "advisor",
		aliases = {
			"dev",
		},
		color = Color(136, 21, 22),
		permissions = {
			setrank = "developer",
			ac = true,
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
		color = Color(17, 79, 18),
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

			kick = true,
			ban = true,
			map = true, -- only for now, need to fix bugs preventing round end
			mute = true,
			unmute = true,
			gag = true,
			ungag = true,
			afk = true,
			slaynr = true,
			rslaynr = true,
			slay = true,
			pa = true,
		},
		color = Color(13, 77, 80),
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
			playtime = true,
			--gold = true,
		}
	},
}

hook.Add("TTTGetPlayerColor", "pluto_admin", function(ply)
	local rank = admin.ranks[ply:GetUserGroup()]
	if (rank and rank.color and ply:GetUserGroup() ~= "user") then
		return rank.color
	end

	return Color(0, 0, 0, 0)
end)

hook.Add("TTTGetRankPrintName", "pluto_admin", function(rank)
	local rank = admin.ranks[rank]
	if (rank and rank.PrintName) then
		return rank.PrintName
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
