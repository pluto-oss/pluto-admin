admin.ranks = {
	developer = {
		inherits = "designer",
		color = Color(237, 34, 11),
		permissions = {
			setrank = "developer"
		},
	},
	designer = {
		inherits = "advisor",
		color = color_black,
		permissions = {
			setrank = false,
		},
	},
	advisor = {
		inherits = "leadadmin",
		color = Color(255, 114, 70),
		permissions = {
			setrank = "leadadmin",
			ban_custom = true,
			slay = true,
		},
	},
	leadadmin = {
		inherits = "mod",
		color = Color(255, 106, 214),
	},
	mod = {
		inherits = "supportstaff",
		color = Color(112, 166, 255),
	},
	supportstaff = {
		inherits = "user",
		permissions = {
			ban = true,
			map = true,
			rdm = true,
			slaynr = true,
		},
		color = Color(131, 231, 225),
	},
	donator = {
		inherits = "user",
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