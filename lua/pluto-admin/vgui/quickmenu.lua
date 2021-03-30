local PANEL = {}

function PANEL:Init()
    self:SetSize(480, 400)
    self:Center()
    self:MakePopup()
end

function PANEL:AddCommand(cmd, data, ply)
	local real_cat = vgui.Create "EditablePanel"
	real_cat:SetTall(310)
	real_cat:Dock(TOP)

    local get_args = {}

    real_cat.Args = real_cat:Add "ttt_settings_category"
    real_cat.Args:Dock(FILL)

    local run = real_cat.Args:AddLabelButton("Run " .. cmd .. " on " .. ply:Nick())
    run:DockMargin(16, 16, 16, 0)
    run:SetTall(run:GetTall() + 12)

    function run:DoClick()
        local args = {
            {
                Type = admin.args.cmd,
                Data = cmd
            },
            {
                Type = admin.args.userid,
                Data = ply:SteamID64()
            }
        }
        for i, arg in ipairs(get_args) do
            args[#args + 1] = {
                Type = arg.Type,
                Data = arg.Panel:GetValue()
            }
        end

        net.Start "pluto-admin-cmd"
        for _, arg in ipairs(args) do
            PrintTable(arg)
            if (arg.Type:NetworkWrite(arg.Data)) then
                error("error arg " .. i)
            end
        end
        net.SendToServer()
    end

    for i = 2, #data.args do
        local arg = data.args[i]

        local argtype = admin.args[arg.Type].CreateInputPanel and admin.args[arg.Type] or admin.args.string

        get_args[i - 1] = {
            Type = argtype,
            Panel = argtype:CreateInputPanel(arg, real_cat.Args)
        }
    end

	self:AddTab("Quick Menu: " .. cmd, real_cat)
end

vgui.Register("pluto_admin_quickmenu", PANEL, "tttrw_base")