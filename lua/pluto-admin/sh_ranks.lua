admin.ranks = {
	developer = {
		inherits = "advisor",
	},
	advisor = {
		inherits = "leadadmin",
	},
	leadadmin = {
		inherits = "mod",
	},
	mod = {
		inherits = "supportstaff",
	},
	supportstaff = {
		inherits = "user",
		permissions = {
			ban = true,
			map = true,
			rdm = true,
		}
	},
	donator = {
		inherits = "user",
	},
}

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
	["STEAM_0:0:58378410"] = "advisor", --zero
	["STEAM_0:1:27119610"] = "mod", -- loveyy
	["STEAM_0:0:69089132"] = "mod", -- agent
	["STEAM_0:0:76071854"] = "developer", -- squibble
	["STEAM_0:0:35214868"] = "mod", -- ekksdee
	["STEAM_0:1:41818825"] = "mod", -- rusty
	["STEAM_0:0:28467572"] = "mod", -- francoise
	["STEAM_0:0:30028117"] = "mod", -- hound
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