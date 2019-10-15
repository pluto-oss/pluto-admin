admin = admin or {}

if (not file.Exists("cfg/admin-db.json", "GAME")) then
	error "no db config"
end

admin.db = util.JSONToTable(file.Read("cfg/admin-db.json", "GAME"))

if (admin.db.type == "mysql") then
else
	error("does not support database type: " .. admin.cfg.database.type)
end
