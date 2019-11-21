local ARG = admin.args.time or {}
admin.args.time = ARG

local function GetData(text)
	if (tonumber(text)) then
		return {
			{
				Friendly = tonumber(text),
				Time = text,
			}
		}
	end

	return {}
end

function ARG:AutoComplete(text)
	local r = {}
	for _, item in pairs(GetData(text)) do
		r[#r + 1] = item.Friendly
	end
	return r
end

function ARG:NetworkWrite(text)
	net.WriteUInt(GetData(text)[1].Time, 32)
end

function ARG:NetworkRead()
	return net.ReadUInt(32)
end

function ARG:CreateInputPanel(arginfo, prnt)
	return {
		Panel = prnt:AddTextEntry(arginfo.Name or arginfo.Type, true, ""),
		GetValue = function(s)
			return GetData(s.Panel:GetValue())[1].Time
		end
	}
end
