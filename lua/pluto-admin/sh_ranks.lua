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
	cute = {
		PrintName = "Cute",
		inherits = "advisor",
		aliases = {
			"kat",
		},
		color = Color(27, 171, 61),
		permissions = {},
	},
	advisor = {
		PrintName = "Advisor",
		inherits = "admin",
		aliases = {
			"adv",
		},
		color = Color(27, 126, 28),
		permissions = {
			setrank = "leadadmin",
			tradeban = true,
		},
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
			ban_custom = true,
			["goto"] = true,
			unban = true,
			gold = true,
		},
		color = Color(99, 117, 36),
	},
	mod = {
		PrintName = "Moderator",
		inherits = "supportstaff",
		aliases = {
			"moderator",
			"m",
		},
		color = Color(0, 59, 153),
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
			warn = true,
			bypass_max = true,
		},
		color = Color(21, 126, 132),
	},
	donator = {
		PrintName = "Donator",
		inherits = "user",
		permissions = {
			votemap = true,
		},
		color = Color(0, 176, 18),
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
