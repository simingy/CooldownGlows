local addonName, addon = ...

function addon.ShowItemHelper(activeProfileFrame)
    if not addon.ItemHelperFrame then
        local h = CreateFrame("Frame", "CooldownGlowsItemHelper", UIParent, "BasicFrameTemplateWithInset")
        h:SetSize(450, 400)
        h:SetMovable(true)
        h:EnableMouse(true)
        h:RegisterForDrag("LeftButton")
        h:SetScript("OnDragStart", h.StartMoving)
        h:SetScript("OnDragStop", h.StopMovingOrSizing)
        h:SetFrameStrata("DIALOG")
        
        if SettingsPanel and SettingsPanel:IsShown() then
            h:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0)
        elseif addon.OptionsFrame and addon.OptionsFrame:IsShown() then
            h:SetPoint("TOPLEFT", addon.OptionsFrame, "TOPRIGHT", 10, 0)
        else
            h:SetPoint("CENTER")
        end

        h.title = h:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        h.title:SetPoint("TOP", h, "TOP", 0, -5)
        h.title:SetText("Items on Action Bars")
        
        h.headerName = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.headerName:SetPoint("TOPLEFT", h, "TOPLEFT", 15, -30)
        h.headerName:SetText("Item Name")
        
        h.headerID = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.headerID:SetPoint("TOPRIGHT", h, "TOPRIGHT", -55, -30)
        h.headerID:SetText("Item ID")

        h.scroll = CreateFrame("ScrollFrame", nil, h, "UIPanelScrollFrameTemplate")
        h.scroll:SetPoint("TOPLEFT", 10, -50)
        h.scroll:SetPoint("BOTTOMRIGHT", -30, 10)
        h.content = CreateFrame("Frame", nil, h.scroll)
        h.content:SetSize(350, 10)
        h.scroll:SetScrollChild(h.content)

        addon.ItemHelperFrame = h
    end
    
    -- Re-anchor if opened again
    if addon.ItemHelperFrame:IsVisible() then
        if SettingsPanel and SettingsPanel:IsShown() then
            addon.ItemHelperFrame:ClearAllPoints()
            addon.ItemHelperFrame:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0)
        end
    end
    
    local content = addon.ItemHelperFrame.content
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Scan action bars for items
    addon.ScanActionBarItems()
    local items = addon.GetActionBarItems and addon.GetActionBarItems() or {}
    
    local yOffset = -5
    
    if #items == 0 then
        local noItems = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noItems:SetPoint("TOP", 0, yOffset)
        noItems:SetText("|cff888888No items found on your action bars.|r")
        content:SetHeight(30)
        addon.ItemHelperFrame:Show()
        return
    end
    
    for _, item in ipairs(items) do
        local row = CreateFrame("Button", nil, content)
        row:SetSize(350, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 0.6, 0.15)
        
        row:SetScript("OnClick", function()
            if activeProfileFrame and activeProfileFrame.itemInput then
                activeProfileFrame.itemInput:SetText(tostring(item.itemID))
                activeProfileFrame.itemDurationInput:SetText("3")
            end
            addon.ItemHelperFrame:Hide()
        end)
        
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", 5, 0)
        nameText:SetWidth(240)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(string.format("|T%s:16|t |cffccaa00%s|r", item.icon, item.name))
        
        local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        idText:SetPoint("RIGHT", -5, 0)
        idText:SetWidth(60)
        idText:SetJustifyH("RIGHT")
        idText:SetText("|cffccaa00" .. tostring(item.itemID) .. "|r")
        
        yOffset = yOffset - 22
    end
    content:SetHeight(math.abs(yOffset))
    addon.ItemHelperFrame:Show()
end
