local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() / 1.5, ScrH() / 1.5)
    self:SetPos((ScrW() / 2) - (self:GetWide() / 2), (ScrH() / 2) - (self:GetTall() / 2))
    self:MakePopup()

    local close_btn = vgui.Create("DButton", self)
    local close_btn_color = HORDE.color_config_btn
    close_btn:SetFont("marlett")
    close_btn:SetText("r")
    close_btn.Paint = function() draw.RoundedBox(10, 0, 0, 40, 32, close_btn_color) end
    close_btn:SetColor(Color(255, 255, 255))
    close_btn:SetSize(40, 32)
    close_btn:SetPos(self:GetWide() - 45, 4)
    close_btn.OnCursorEntered = function ()
        close_btn_color = HORDE.color_crimson
    end
    close_btn.OnCursorExited = function ()
        close_btn_color = HORDE.color_config_btn
    end
    close_btn.DoClick = function() HORDE:ToggleClassConfig() end

    local q_btn = vgui.Create("DButton", self)
    local q_btn_color = HORDE.color_config_btn
    q_btn:SetFont("Trebuchet24")
    q_btn:SetText("?")
    q_btn.Paint = function() draw.RoundedBox(10, 0, 0, 40, 32, q_btn_color) end
    q_btn:SetColor(Color(255, 255, 255))
    q_btn:SetSize(40, 32)
    q_btn:SetPos(self:GetWide() - 45 - 45, 4)
    q_btn.OnCursorEntered = function ()
        q_btn_color = HORDE.color_crimson
    end
    q_btn.OnCursorExited = function ()
        q_btn_color = HORDE.color_config_btn
    end
    q_btn.DoClick = function() gui.OpenURL("https://github.com/tpan496/Horde/wiki/Class-Config") end

    local modify_tab = vgui.Create("DPanel", self)
    modify_tab:SetBackgroundColor(HORDE.color_config_content_bg)
    modify_tab:SetSize(self:GetWide() / 2 - 200, self:GetTall() - 40 - 12 - 10)
    modify_tab:SetPos(self:GetWide() / 2, 50)

    local function create_property_editor(name, height)
        local panel = vgui.Create("DPanel", modify_tab)
        panel:DockPadding(10, 10, 10, 10)
        panel:SetSize(modify_tab:GetWide(), height)
        panel:Dock(TOP)
        panel:SetBackgroundColor(HORDE.color_none)

        local label = vgui.Create("DLabel", panel)
        label:SetText(name)
        label:SetTextColor(Color(0,0,0))
        label:DockPadding(10, 10, 10, 10)
        label:SetWide(100)
        label:Dock(LEFT)

        local editor = vgui.Create("DTextEntry", panel)
        editor:SetSize(200, height)
        editor:DockPadding(10, 10, 10, 10)
        editor:Dock(LEFT)
        return editor
    end

    local name_editor = create_property_editor("name", 50)
    local description_editor = create_property_editor("extra description", 300)

    name_editor:SetEditable(false)
    description_editor:SetMultiline(true)

    if GetConVarNumber("horde_default_class_config") == 1 then
        local warning_label = vgui.Create("DLabel", modify_tab)
        warning_label:DockMargin(10, 10, 10, 10)
        warning_label:Dock(TOP)
        warning_label:SetSize(modify_tab:GetWide(), 50)
        warning_label:SetTextColor(Color(255,0,0))
        warning_label:SetText("You are using default config!\nYour data won't be saved!")
        warning_label:SetFont("Heading")
    end  

    local btn_panel = vgui.Create("DPanel", self)
    btn_panel:SetPos(self:GetWide() - 200, 50)
    btn_panel:SetSize(200, self:GetTall() - 58)
    btn_panel:SetBackgroundColor(HORDE.color_none)

    local save_btn = vgui.Create("DButton", btn_panel)
    save_btn:Dock(TOP)
    save_btn:SetText("Save")
    save_btn:SetTall(30)
    save_btn:DockMargin(10, 5, 10, 5)
    save_btn.DoClick = function ()
        if GetConVarNumber("horde_default_class_config") == 1 then return end
        local name = name_editor:GetValue()
        local extra_description = description_editor:GetValue()
        if name and HORDE.classes[name] and extra_description then
            HORDE.classes[name].extra_description = extra_description

            net.Start("Horde_SetClassData")
            net.WriteTable(HORDE.classes)
            net.SendToServer()
            notification.AddLegacy("Your changes have been saved.", NOTIFY_GENERIC, 5)
        end
    end

    local reset_btn = vgui.Create("DButton", btn_panel)
    reset_btn:Dock(BOTTOM)
    reset_btn:SetText("Reset Everything")
    reset_btn:SetTall(30)
    reset_btn:DockMargin(10, 5, 10, 5)
    reset_btn.DoClick = function ()
        if GetConVarNumber("horde_default_class_config") == 1 then return end
        HORDE.CreateClasses()

        net.Start("Horde_SetClassData")
        net.WriteTable(HORDE.classes)
        net.SendToServer()
        notification.AddLegacy("Your changes have been saved.", NOTIFY_GENERIC, 5)
    end

    local settings_tab = vgui.Create("DPanel", self)
    settings_tab:SetPos(0, 40)
    settings_tab:SetSize(self:GetWide() / 2, self:GetTall() - 40 - 3)
    settings_tab:SetBackgroundColor(HORDE.color_none)

    local class_list = vgui.Create("DListView", settings_tab)
    class_list:DockMargin(10, 10, 10, 10)
    class_list:Dock(FILL)

    class_list:SetMultiSelect(false)
    class_list:AddColumn("Name")
    class_list:AddColumn("Description")

    class_list:SetDataHeight(40)

    class_list.OnClickLine = function(parent, line, selected)
        local class = line.class

        local menu = DermaMenu()

        menu:AddOption("Modify", function()
            name_editor:SetValue(class.name)
            description_editor:SetValue(class.extra_description)
        end)

        menu:AddSpacer()

        menu:Open()
    end

    self.class_list = class_list
end

function PANEL:Think()
    local lines = self.class_list:GetLines()

    for _, class in pairs(HORDE.classes) do
        local found = false
        for _, line in pairs(lines) do
            if line.class == class then
                found = true
            end
        end
        if not found then
            self.class_list:AddLine(class.name, class.description).class = class
        end
    end

    for i, line in pairs(lines) do
        if table.HasValue(HORDE.classes, line.class) then
            local class = line.class

            line:SetValue(1, class.name)
            line:SetValue(2, class.extra_description)
        else
            self.class_list:RemoveLine(i)
        end
    end
end

function PANEL:Paint(w, h)
    -- Entire Panel
    draw.RoundedBox(10, 0, 0, w, h, HORDE.color_config_bg)

    -- Background
    draw.RoundedBox(10, 0, 0, w, 40, HORDE.color_config_bar)

    draw.SimpleText("Horde Class Configuration", "Trebuchet24", 10, 22, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("HordeClassConfig", PANEL, "EditablePanel")