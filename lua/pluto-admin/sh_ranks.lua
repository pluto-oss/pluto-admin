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
		}
	},
	donator = {
		inherits = "user",
	},
}

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
}

admin.hardcoded = {}

for usergroup, info in pairs(admin.ranks) do
	CAMI.RegisterUsergroup({
		Name = usergroup,
		Inherits = info.inherits
	}, "pluto-admin")
end

hook.Add("PlayerAuthed", "pluto_admin", function(ply)
	local usergroup = admin.users[ply:SteamID()] or "user"
	local u = admin.ranks[usergroup]

	ply:SetUserGroup(usergroup)
end)