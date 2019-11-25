local ARG = admin.args.userid or {}
admin.args.userid = ARG

function ARG:GetData(text)
	if (TypeID(text) == TYPE_ENTITY) then
		return {
			{
				Friendly = text:Nick(),
				SteamID = text:SteamID64()
			}
		}
	end

	if (text:StartWith "STEAM_") then
		return {
			{
				Friendly = text,
				SteamID = util.SteamIDTo64(text)
			}
		}
	end

	if (tonumber(text) and util.SteamIDFrom64(text) ~= "STEAM_0:0:0") then
		return {
			{
				Friendly = util.SteamIDFrom64(text),
				SteamID = text
			}
		}
	end

	local ret = {}
	for _, ply in pairs(player.GetAll()) do
		if (ply:Nick() == text) then
			return {
				{
					Friendly = text,
					SteamID = ply:SteamID64()
				}
			}
		end

		if (ply:Nick():lower():find(text:lower(), 1, true)) then
			ret[#ret + 1] = {
				Friendly = ply:Nick(),
				SteamID = ply:SteamID64()
			}
		end
	end

	return ret
end

function ARG:AutoComplete(text, cmd)
	local r = {}
	for _, item in pairs(self:GetData(text)) do
		r[#r + 1] = item.Friendly
	end
	return r
end

function ARG:NetworkWrite(text)
	local data = self:GetData(text)
	if (#data > 1) then
		return true
	end

	net.WriteString(data[1].SteamID)
end

function ARG:NetworkRead()
	local r = net.ReadString()
	if (not tonumber(r)) then
		return 0
	end
	return r
end

function ARG:CreateInputPanel(arginfo, prnt)
	return {
		Panel = prnt:AddTextEntry(arginfo.Name or arginfo.Type, true, ""),
		GetValue = function(s)
			return self:GetData(s.Panel:GetValue())[1].SteamID
		end
	}
end
