local addonName, addon = ...

function addon.ShowSpellHelper(activeProfileFrame, profileKey, isEditMode)
    if not addon.SpellHelperFrame then
        local h = CreateFrame("Frame", "CooldownGlowsSpellHelper", UIParent, "BasicFrameTemplateWithInset")
        h:SetSize(600, 500)
        h:SetMovable(true)
        h:EnableMouse(true)
        h:RegisterForDrag("LeftButton")
        h:SetScript("OnDragStart", h.StartMoving)
        h:SetScript("OnDragStop", h.StopMovingOrSizing)
        h:SetFrameStrata("DIALOG")
        
        h.title = h:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        h.title:SetPoint("TOP", h, "TOP", 0, -5)
        h.title:SetText("Add Spell")
        
        -- == LEFT PANE (Spell List) ==
        h.headerIcon = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.headerIcon:SetPoint("TOPLEFT", h, "TOPLEFT", 15, -30)
        h.headerIcon:SetText("Spell Name (ID)")

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
        
        h.spellPreviewIcon = h:CreateTexture(nil, "ARTWORK")
        h.spellPreviewIcon:SetSize(40, 40)
        h.spellPreviewIcon:SetPoint("TOPLEFT", h, "TOPLEFT", rightBaseX, -50)
        h.spellPreviewIcon:Hide()
        
        h.spellPreviewName = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h.spellPreviewName:SetPoint("LEFT", h.spellPreviewIcon, "RIGHT", 10, 0)
        h.spellPreviewName:SetWidth(180)
        h.spellPreviewName:SetJustifyH("LEFT")
        
        local function UpdateSpellPreview(spellID)
            local id = tonumber(spellID)
            if id and id > 0 then
                local info = C_Spell.GetSpellInfo(id)
                if info and info.name then
                    h.spellPreviewIcon:SetTexture(info.iconID or 134400)
                    h.spellPreviewIcon:Show()
                    h.spellPreviewName:SetText(info.name)
                    return
                end
            end
            h.spellPreviewIcon:Hide()
            h.spellPreviewName:SetText("")
        end
        h.UpdateSpellPreview = UpdateSpellPreview
        
        h.idLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.idLabel:SetPoint("TOPLEFT", h, "TOPLEFT", rightBaseX, -110)
        h.idLabel:SetText("Spell ID:")
        
        h.idInput = CreateFrame("EditBox", nil, h, "InputBoxTemplate")
        h.idInput:SetSize(100, 20)
        h.idInput:SetPoint("RIGHT", h.idLabel, "LEFT", 210, 0)
        h.idInput:SetAutoFocus(false)
        h.idInput:SetNumeric(true)
        h.idInput:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            UpdateSpellPreview(self:GetText())
        end)
        h.idInput:SetScript("OnTextChanged", function(self, isUserInput)
            if isUserInput then
                UpdateSpellPreview(self:GetText())
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
        h.addBtn:SetText("Add Spell")
        h.addBtn:SetScript("OnClick", function()
            local spellID = tonumber(h.idInput:GetText())
            local duration = tonumber(h.durInput:GetText()) or 3
            local colorKey = h.colorDD.selectedKey or "default"
            
            if spellID and spellID > 0 and h.currentProfileKey then
                local p = CooldownGlowsDB[h.currentProfileKey]
                if p then
                    p.spells[spellID] = { duration = duration, color = colorKey }
                    local apf = h.activeProfileFrame
                    if apf and apf.RefreshTrackedList then
                        apf.RefreshTrackedList()
                    end
                    local isCurrentPlayer = (h.currentProfileKey == addon.Class or h.currentProfileKey == addon.CharKey)
                    if isCurrentPlayer then
                        addon.UpdateKnownSpells()
                        addon.CheckCooldowns()
                    end
                    h:Hide()
                end
            end
        end)

        addon.SpellHelperFrame = h
        
        if SettingsPanel then
            SettingsPanel:HookScript("OnHide", function() addon.SpellHelperFrame:Hide() end)
        end
        if addon.OptionsFrame then
            addon.OptionsFrame:HookScript("OnHide", function() addon.SpellHelperFrame:Hide() end)
        end
        
        h:HookScript("OnShow", function()
            if not addon.SpellHelperFrame.isEditing then
                h.idInput:SetText("")
                h.durInput:SetText("3")
                h.durInput:SetCursorPosition(0)
                h.addBtn:SetText("Add Spell")
                UIDropDownMenu_SetText(h.colorDD, "Default")
                h.colorDD.selectedKey = "default"
                h.UpdateSpellPreview("")
            end
        end)
    end
    
    addon.SpellHelperFrame.isEditing = isEditMode and true or false
    addon.SpellHelperFrame.activeProfileFrame = activeProfileFrame
    addon.SpellHelperFrame.currentProfileKey = profileKey
    
    if addon.ItemHelperFrame and addon.ItemHelperFrame:IsShown() then
        addon.ItemHelperFrame:Hide()
    end
    
    addon.SpellHelperFrame:ClearAllPoints()
    if SettingsPanel and SettingsPanel:IsShown() then
        addon.SpellHelperFrame:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0)
    elseif addon.OptionsFrame and addon.OptionsFrame:IsShown() then
        addon.SpellHelperFrame:SetPoint("TOPLEFT", addon.OptionsFrame, "TOPRIGHT", 10, 0)
    else
        addon.SpellHelperFrame:SetPoint("CENTER")
    end
    
    local content = addon.SpellHelperFrame.content

    if not addon.SpellHelperFrame.spellButtonsCreated then
        for _, child in ipairs({content:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        addon.SpellHelperFrame.spellButtonsCreated = true
        
        local yOffset = -5
        local tabs = C_SpellBook.GetNumSpellBookSkillLines()
        local spellList = {}
        
        for i = 1, tabs do
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
            if skillLineInfo and skillLineInfo.name ~= "General" then
                local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
                for j = offset + 1, offset + numSlots do
                    local spellType, spellID = C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                    if (spellType == Enum.SpellBookItemType.Spell or spellType == Enum.SpellBookItemType.FutureSpell) and spellID then
                        local info = C_Spell.GetSpellInfo(spellID)
                        local isKnown = IsSpellKnown(spellID) or IsSpellKnownOrOverridesKnown(spellID)
                        if info and info.name and not info.isPassive and isKnown then
                            table.insert(spellList, {
                                id = spellID,
                                name = info.name,
                                icon = info.iconID or 134400
                            })
                        end
                    end
                end
            end
        end
        
        table.sort(spellList, function(a, b) return a.name < b.name end)
        
        for _, spell in ipairs(spellList) do
            local row = CreateFrame("Button", nil, content)
            row:SetSize(280, 20)
            row:SetPoint("TOPLEFT", 0, yOffset)
            
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.2)
            
            row:SetScript("OnClick", function()
                addon.SpellHelperFrame.idInput:SetText(tostring(spell.id))
                addon.SpellHelperFrame.idInput:ClearFocus()
                addon.SpellHelperFrame.UpdateSpellPreview(tostring(spell.id))
            end)
            
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("LEFT", 5, 0)
            nameText:SetWidth(260)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(string.format("|T%s:16|t %s |cff888888(%s)|r", spell.icon, spell.name, spell.id))
            
            yOffset = yOffset - 22
        end
        content:SetHeight(math.abs(yOffset))
        
        if not addon.SpellHelperFrame.spellEventFrame then
            local eventFrame = CreateFrame("Frame")
            eventFrame:RegisterEvent("SPELLS_CHANGED")
            eventFrame:SetScript("OnEvent", function()
                addon.SpellHelperFrame.spellButtonsCreated = false
            end)
            addon.SpellHelperFrame.spellEventFrame = eventFrame
        end
    end
    
    addon.SpellHelperFrame:Show()
end
