local addonName, addon = ...

function addon.ShowItemHelper(activeProfileFrame, profileKey, isEditMode)
    if not addon.ItemHelperFrame then
        local h = CreateFrame("Frame", "CooldownGlowsItemHelper", UIParent, "BasicFrameTemplateWithInset")
        h:SetSize(600, 500)
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
        h.title:SetText("Add Item")
        
        -- == LEFT PANE (Item List) ==
        h.headerName = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.headerName:SetPoint("TOPLEFT", h, "TOPLEFT", 15, -30)
        h.headerName:SetText("Item Name (ID)")

        h.scroll = CreateFrame("ScrollFrame", nil, h, "UIPanelScrollFrameTemplate")
        h.scroll:SetPoint("TOPLEFT", 10, -50)
        h.scroll:SetPoint("BOTTOMRIGHT", h, "BOTTOMLEFT", 320, 10)
        
        -- Divider
        h.divider = h:CreateTexture(nil, "ARTWORK")
        h.divider:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        h.divider:SetWidth(1)
        h.divider:SetPoint("TOPLEFT", h.scroll, "TOPRIGHT", 20, 0)
        h.divider:SetPoint("BOTTOMLEFT", h.scroll, "BOTTOMRIGHT", 20, 0)

        h.content = CreateFrame("Frame", nil, h.scroll)
        h.content:SetSize(280, 10)
        h.scroll:SetScrollChild(h.content)

        -- == RIGHT PANE (Inputs) ==
        local rightBaseX = 360
        
        h.itemPreviewIcon = h:CreateTexture(nil, "ARTWORK")
        h.itemPreviewIcon:SetSize(40, 40)
        h.itemPreviewIcon:SetPoint("TOPLEFT", h, "TOPLEFT", rightBaseX, -50)
        h.itemPreviewIcon:Hide()
        
        h.itemPreviewName = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h.itemPreviewName:SetPoint("LEFT", h.itemPreviewIcon, "RIGHT", 10, 0)
        h.itemPreviewName:SetWidth(180)
        h.itemPreviewName:SetJustifyH("LEFT")
        
        local function UpdateItemPreview(itemID)
            local id = tonumber(itemID)
            if id and id > 0 then
                local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(id)
                if name then
                    h.itemPreviewIcon:SetTexture(icon or 134400)
                    h.itemPreviewIcon:Show()
                    h.itemPreviewName:SetText(name)
                    return
                end
            end
            h.itemPreviewIcon:Hide()
            h.itemPreviewName:SetText("")
        end
        h.UpdateItemPreview = UpdateItemPreview
        
        h.idLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.idLabel:SetPoint("TOPLEFT", h, "TOPLEFT", rightBaseX, -110)
        h.idLabel:SetText("Item ID:")
        
        h.idInput = CreateFrame("EditBox", nil, h, "InputBoxTemplate")
        h.idInput:SetSize(100, 20)
        h.idInput:SetPoint("RIGHT", h.idLabel, "LEFT", 210, 0)
        h.idInput:SetAutoFocus(false)
        h.idInput:SetNumeric(true)
        h.idInput:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            UpdateItemPreview(self:GetText())
        end)
        h.idInput:SetScript("OnTextChanged", function(self, isUserInput)
            if isUserInput then
                UpdateItemPreview(self:GetText())
            end
        end)
        
        h.durLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.durLabel:SetPoint("TOPLEFT", h.idLabel, "BOTTOMLEFT", 0, -20)
        h.durLabel:SetText("Duration:")
        
        h.durInput = CreateFrame("EditBox", nil, h, "InputBoxTemplate")
        h.durInput:SetSize(40, 20)
        h.durInput:SetPoint("RIGHT", h.durLabel, "LEFT", 210, 0)
        h.durInput:SetAutoFocus(false)
        h.durInput:SetNumeric(true)
        h.durInput:SetText("3")
        
        h.colorLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.colorLabel:SetPoint("TOPLEFT", h.durLabel, "BOTTOMLEFT", 0, -20)
        h.colorLabel:SetText("Color:")
        
        h.colorDD = addon.CreateColorDropdown(h, h.colorLabel, "LEFT", 80, -2, "default")
        
        h.cancelBtn = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
        h.cancelBtn:SetSize(80, 24)
        h.cancelBtn:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -15, 15)
        h.cancelBtn:SetText("Cancel")
        h.cancelBtn:SetScript("OnClick", function()
            h:Hide()
        end)

        h.addBtn = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
        h.addBtn:SetSize(80, 24)
        h.addBtn:SetPoint("RIGHT", h.cancelBtn, "LEFT", -10, 0)
        h.addBtn:SetText("Add Item")
        h.addBtn:SetScript("OnClick", function()
            local itemID = tonumber(h.idInput:GetText())
            local duration = tonumber(h.durInput:GetText()) or 3
            local colorKey = h.colorDD.selectedKey or "default"
            
            if itemID and itemID > 0 and h.currentProfileKey then
                local p = CooldownGlowsDB[h.currentProfileKey]
                if p then
                    if not p.items then p.items = {} end
                    p.items[itemID] = { duration = duration, color = colorKey }
                    local apf = h.activeProfileFrame
                    if apf and apf.RefreshTrackedList then
                        apf.RefreshTrackedList()
                    end
                    local isCurrentPlayer = (h.currentProfileKey == addon.Class or h.currentProfileKey == addon.CharKey)
                    if isCurrentPlayer then
                        addon.ScanActionBarItems()
                        addon.CheckItemCooldowns()
                    end
                    h:Hide()
                end
            end
        end)

        addon.ItemHelperFrame = h
        
        -- Close when Settings closes
        if SettingsPanel then
            SettingsPanel:HookScript("OnHide", function() addon.ItemHelperFrame:Hide() end)
        end
        if addon.OptionsFrame then
            addon.OptionsFrame:HookScript("OnHide", function() addon.ItemHelperFrame:Hide() end)
        end
        
        h:HookScript("OnShow", function()
            if not addon.ItemHelperFrame.isEditing then
                h.idInput:SetText("")
                h.durInput:SetText("3")
                h.durInput:SetCursorPosition(0)
                h.addBtn:SetText("Add Item")
                UIDropDownMenu_SetText(h.colorDD, "Default")
                h.colorDD.selectedKey = "default"
                h.UpdateItemPreview("")
            end
        end)
    end
    
    addon.ItemHelperFrame.isEditing = isEditMode and true or false
    addon.ItemHelperFrame.activeProfileFrame = activeProfileFrame
    addon.ItemHelperFrame.currentProfileKey = profileKey
    
    if addon.SpellHelperFrame and addon.SpellHelperFrame:IsShown() then
        addon.SpellHelperFrame:Hide()
    end
    
    addon.ItemHelperFrame:ClearAllPoints()
    if SettingsPanel and SettingsPanel:IsShown() then
        addon.ItemHelperFrame:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0)
    elseif addon.OptionsFrame and addon.OptionsFrame:IsShown() then
        addon.ItemHelperFrame:SetPoint("TOPLEFT", addon.OptionsFrame, "TOPRIGHT", 10, 0)
    else
        addon.ItemHelperFrame:SetPoint("CENTER")
    end
    
    local content = addon.ItemHelperFrame.content
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
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
        row:SetSize(280, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 0.6, 0.15)
        
        row:SetScript("OnClick", function()
            addon.ItemHelperFrame.idInput:SetText(tostring(item.itemID))
            addon.ItemHelperFrame.idInput:ClearFocus()
            addon.ItemHelperFrame.UpdateItemPreview(tostring(item.itemID))
        end)
        
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", 5, 0)
        nameText:SetWidth(260)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(string.format("|T%s:16|t |cffccaa00%s|r |cff888888(%s)|r", item.icon, item.name, item.itemID))
        
        yOffset = yOffset - 22
    end
    content:SetHeight(math.abs(yOffset))
    addon.ItemHelperFrame:Show()
end
