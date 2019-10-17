admin.ranks = {
	developer = {
		inherits = "advisor",
		color = Color(237, 34, 11),
	},
	advisor = {
		inherits = "leadadmin",
		color = Color(255, 114, 70),
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
			slay = true,
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
		if (mygroup and mygroup.permissions and mygroup.permissions[perm]) then
			return true
		end

		last = usergroup
		usergroup = CAMI.GetUsergroup(usergroup.Inherits)
	end

	return false
end

admin.users = {
	["STEAM_0:0:44950009"] = "developer", -- meepen
	["STEAM_0:1:27537959"] = "mod",
	["STEAM_0:0:113902473"] = "developer",
	["STEAM_0:0:35214868"] = "mod",
	["STEAM_0:0:58378410"] = "mod", --loveyy
	["STEAM_0:1:27119610"] = "advisor", -- zero
	["STEAM_0:0:69089132"] = "mod", -- agent
	["STEAM_0:0:76071854"] = "developer", -- squibble
	["STEAM_0:0:35214868"] = "mod", -- ekksdee
	["STEAM_0:1:41818825"] = "mod", -- rusty
	["STEAM_0:0:28467572"] = "mod", -- francoise
	["STEAM_0:0:30028117"] = "mod", -- hound
	["STEAM_0:0:61790383"] = "advisor", -- kat
	["STEAM_0:0:120144587"] = "mod", -- mae
	["STEAM_0:1:71412544"] = "mod", -- shootr
	["STEAM_0:0:142848003"] = "advisor", -- leo
	["STEAM_0:1:49799454"] = "advisor", -- suess
}

admin.hardcoded = {}

for usergroup, info in pairs(admin.ranks) do
	CAMI.RegisterUsergroup({
		Name = usergroup,
		Inherits = info.inherits
	}, "pluto-admin")
end

for group in pairs(admin.ranks) do
	if (admin.hasperm(group, "rdm")) then
		Damagelog:AddUser(group, 4, true)
	end
end

hook.Add("PlayerAuthed", "pluto_admin", function(ply)
	local usergroup = admin.users[ply:SteamID()] or "user"

	ply:SetUserGroup(usergroup)
end)