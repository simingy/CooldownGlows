local addonName, addon = ...

function addon.ShowSpellHelper(activeProfileFrame, profileKey, isEditMode)
    if not addon.SpellHelperFrame then
        local h = CreateFrame("Frame", "CooldownGlowsSpellHelper", UIParent, "BasicFrameTemplateWithInset")
        h:SetSize(680, 530)
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
        h.spellPreviewIcon:SetTexture(134400) -- Question mark
        h.spellPreviewIcon:SetDesaturated(true)
        h.spellPreviewIcon:SetAlpha(0.5)
        
        h.spellPreviewName = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h.spellPreviewName:SetPoint("LEFT", h.spellPreviewIcon, "RIGHT", 10, 0)
        h.spellPreviewName:SetWidth(180)
        h.spellPreviewName:SetJustifyH("LEFT")
        h.spellPreviewName:SetText("No spell selected")
        h.spellPreviewName:SetTextColor(0.5, 0.5, 0.5)
        
        local function UpdateSpellPreview(spellID)
            local id = tonumber(spellID)
            if id and id > 0 then
                local info = C_Spell.GetSpellInfo(id)
                if info and info.name then
                    h.spellPreviewIcon:SetTexture(info.iconID or 134400)
                    h.spellPreviewIcon:SetDesaturated(false)
                    h.spellPreviewIcon:SetAlpha(1.0)
                    h.spellPreviewName:SetText(info.name)
                    h.spellPreviewName:SetTextColor(1, 0.82, 0) -- Default GameFontNormal color
                    return
                end
            end
            h.spellPreviewIcon:SetTexture(134400)
            h.spellPreviewIcon:SetDesaturated(true)
            h.spellPreviewIcon:SetAlpha(0.5)
            h.spellPreviewName:SetText("No spell selected")
            h.spellPreviewName:SetTextColor(0.5, 0.5, 0.5)
        end
        h.UpdateSpellPreview = UpdateSpellPreview
        
        h.idLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.idLabel:SetPoint("TOPLEFT", h, "TOPLEFT", rightBaseX, -110)
        h.idLabel:SetText("Spell ID:")
        
        h.idInput = CreateFrame("EditBox", nil, h, "InputBoxTemplate")
        h.idInput:SetSize(100, 20)
        h.idInput:SetPoint("RIGHT", h.idLabel, "LEFT", 265, 0)
        h.idInput:SetAutoFocus(false)
        h.idInput:SetNumeric(true)
        local function AutoSelectButton(spellID)
            local id = tonumber(spellID)
            if not id or id <= 0 then return end
            local found = addon.FindButtonsBySpellID(id)
            if found and #found > 0 and found[1]:GetName() then
                local btnName = found[1]:GetName()
                UIDropDownMenu_SetText(h.btnFrameDD, btnName)
                h.btnFrameDD.selectedValue = btnName
            end
        end
        h.AutoSelectButton = AutoSelectButton

        h.idInput:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            UpdateSpellPreview(self:GetText())
        end)
        h.idInput:SetScript("OnTextChanged", function(self, isUserInput)
            if isUserInput then
                UpdateSpellPreview(self:GetText())
                AutoSelectButton(self:GetText())
            end
        end)
        
        h.durLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.durLabel:SetPoint("TOPLEFT", h.idLabel, "BOTTOMLEFT", 0, -20)
        h.durLabel:SetText("Duration:")
        
        h.durInput = CreateFrame("EditBox", nil, h, "InputBoxTemplate")
        h.durInput:SetSize(40, 20)
        h.durInput:SetPoint("RIGHT", h.durLabel, "LEFT", 265, 0)
        h.durInput:SetAutoFocus(false)
        h.durInput:SetNumeric(true)
        h.durInput:SetText("3")
        
        h.colorLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.colorLabel:SetPoint("TOPLEFT", h.durLabel, "BOTTOMLEFT", 0, -20)
        h.colorLabel:SetText("Color:")
        
        h.colorDD = addon.CreateColorDropdown(h, h.colorLabel, "LEFT", 80, -2, "default")
        h.colorDD:ClearAllPoints()
        h.colorDD:SetPoint("RIGHT", h.colorLabel, "LEFT", 280, -3)
        
        h.btnFrameLabel = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.btnFrameLabel:SetPoint("TOPLEFT", h.colorLabel, "BOTTOMLEFT", 0, -20)
        h.btnFrameLabel:SetText("Target Frame:")

        h.btnFrameDD = CreateFrame("Frame", "CooldownGlowsSpellTargetDD", h, "UIDropDownMenuTemplate")
        h.btnFrameDD:SetPoint("RIGHT", h.btnFrameLabel, "LEFT", 280, -3)
        UIDropDownMenu_SetWidth(h.btnFrameDD, 130)
        
        UIDropDownMenu_Initialize(h.btnFrameDD, function(self, level, menuList)
            level = level or 1
            if level == 1 then
                local id = tonumber(h.idInput:GetText())
                local found = id and addon.FindButtonsBySpellID(id) or {}
                
                local info = UIDropDownMenu_CreateInfo()
                info.text = "-- Currently Found on Bars --"
                info.isTitle = true
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)
                
                local hasFound = false
                for _, btn in ipairs(found) do
                    local name = btn:GetName()
                    if name then
                        hasFound = true
                        local bInfo = UIDropDownMenu_CreateInfo()
                        bInfo.text = name
                        bInfo.value = name
                        bInfo.func = function()
                            UIDropDownMenu_SetText(h.btnFrameDD, name)
                            h.btnFrameDD.selectedValue = name
                            CloseDropDownMenus()
                        end
                        UIDropDownMenu_AddButton(bInfo, level)
                    end
                end
                
                if not hasFound then
                    local noneInfo = UIDropDownMenu_CreateInfo()
                    noneInfo.text = "None found for this Spell ID"
                    noneInfo.disabled = true
                    noneInfo.notCheckable = true
                    UIDropDownMenu_AddButton(noneInfo, level)
                end
                
                local div = UIDropDownMenu_CreateInfo()
                div.text = " "
                div.isTitle = true
                div.notCheckable = true
                UIDropDownMenu_AddButton(div, level)
                
                local stdHeader = UIDropDownMenu_CreateInfo()
                stdHeader.text = "-- Standard Action Bars --"
                stdHeader.isTitle = true
                stdHeader.notCheckable = true
                UIDropDownMenu_AddButton(stdHeader, level)
                
                local stdBars = {
                    {"Action Bar 1", "ActionButton"},
                    {"Bottom Left Bar", "MultiBarBottomLeftButton"},
                    {"Bottom Right Bar", "MultiBarBottomRightButton"},
                    {"Right Bar", "MultiBarRightButton"},
                    {"Left Bar", "MultiBarLeftButton"},
                    {"Action Bar 5", "MultiBar5Button"},
                    {"Action Bar 6", "MultiBar6Button"},
                    {"Action Bar 7", "MultiBar7Button"},
                    {"Action Bar 8", "MultiBar8Button"}
                }
                for _, bar in ipairs(stdBars) do
                    local stdInfo = UIDropDownMenu_CreateInfo()
                    stdInfo.text = bar[1]
                    stdInfo.hasArrow = true
                    stdInfo.menuList = bar[2]
                    stdInfo.notCheckable = true
                    UIDropDownMenu_AddButton(stdInfo, level)
                end
            elseif level == 2 then
                for i = 1, 12 do
                    local name = menuList .. i
                    local btnInfo = UIDropDownMenu_CreateInfo()
                    btnInfo.text = name
                    btnInfo.value = name
                    btnInfo.func = function()
                        UIDropDownMenu_SetText(h.btnFrameDD, name)
                        h.btnFrameDD.selectedValue = name
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(btnInfo, level)
                end
            end
        end)
        UIDropDownMenu_SetText(h.btnFrameDD, "")

        h.infoText = h:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        h.infoText:SetPoint("TOPLEFT", h.btnFrameLabel, "BOTTOMLEFT", 0, -30)
        h.infoText:SetWidth(220)
        h.infoText:SetJustifyH("LEFT")
        h.infoText:SetText("Triggers glow when cooldown finishes.\n\n* Required: Provide the Exact UI Button Frame name (e.g. ActionButton1) by selecting.")
        h.infoText:SetTextColor(0.7, 0.7, 0.7)

        h.cancelBtn = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
        h.cancelBtn:SetSize(70, 24)
        h.cancelBtn:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -15, 15)
        h.cancelBtn:SetText("Cancel")
        h.cancelBtn:SetScript("OnClick", function() h:Hide() end)

        h.addBtn = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
        h.addBtn:SetSize(90, 26)
        h.addBtn:SetPoint("RIGHT", h.cancelBtn, "LEFT", -5, 0)
        h.addBtn:SetText("Save Spell")
        h.addBtn:SetScript("OnClick", function()
            local spellID = tonumber(h.idInput:GetText())
            local duration = tonumber(h.durInput:GetText()) or 3
            local colorKey = h.colorDD.selectedKey or "default"
            local targetBtnName = h.btnFrameDD.selectedValue or (h.btnFrameDD.Text and h.btnFrameDD.Text:GetText()) or ""
            
            if targetBtnName == "" then
                addon.Print("Error: You must assign a Target Frame.")
                return
            end
            
            if spellID and spellID > 0 and h.currentProfileKey then
                local p = CooldownGlowsDB[h.currentProfileKey]
                if p then
                    if not p.spells then p.spells = {} end
                    p.spells[spellID] = { duration = duration, color = colorKey, button = targetBtnName }
                    local apf = h.activeProfileFrame
                    if apf and apf.RefreshTrackedList then apf.RefreshTrackedList() end
                    local isCurrentPlayer = (h.currentProfileKey == addon.Class or h.currentProfileKey == addon.CharKey)
                    if isCurrentPlayer then
                        if addon.UpdateTrackableSpells then addon.UpdateTrackableSpells() end
                        addon.CheckCooldowns()
                    end
                    h:Hide()
                end
            end
        end)
        
        h.testBtn = CreateFrame("Button", nil, h, "UIPanelButtonTemplate")
        h.testBtn:SetSize(70, 24)
        h.testBtn:SetPoint("RIGHT", h.addBtn, "LEFT", -5, 0)
        h.testBtn:SetText("Test")
        h.testBtn:SetScript("OnClick", function()
            local targetBtnName = h.btnFrameDD.selectedValue or (h.btnFrameDD.Text and h.btnFrameDD.Text:GetText()) or ""
            local btn = targetBtnName ~= "" and _G[targetBtnName] or nil
            if btn then
                local duration = tonumber(h.durInput:GetText()) or 3
                local colorKey = h.colorDD.selectedKey or "default"
                if addon.testTimer then
                    addon.testTimer:Cancel()
                    addon.testTimer = nil
                end
                addon.isTesting = true
                addon.ApplyGlowTransition(btn, true, true, duration, colorKey)
                addon.testTimer = C_Timer.NewTimer(duration + 0.5, function()
                    addon.isTesting = false
                    addon.testTimer = nil
                end)
            else
                addon.Print("Error: Cannot test, frame not found.")
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
                h.btnFrameDD.selectedValue = nil
                UIDropDownMenu_SetText(h.btnFrameDD, "")
                h.addBtn:SetText("Save")
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
        addon.SpellHelperFrame.spellRows = addon.SpellHelperFrame.spellRows or {}
        for _, r in ipairs(addon.SpellHelperFrame.spellRows) do
            r:Hide()
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
                    local spellType, actionID, spellID = C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                    spellID = spellID or actionID -- fall back to actionID for non-overridden spells
                    if spellType == Enum.SpellBookItemType.Spell and spellID then
                        local info = C_Spell.GetSpellInfo(spellID)
                        local isKnown = C_SpellBook.IsSpellKnown(spellID)
                        local isPassive = C_SpellBook.IsSpellBookItemPassive(j, Enum.SpellBookSpellBank.Player)
                        if info and info.name and not isPassive and isKnown then
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
        
        for idx, spell in ipairs(spellList) do
            local row = addon.SpellHelperFrame.spellRows[idx]
            if not row then
                row = CreateFrame("Button", nil, content)
                row:SetSize(280, 20)
                local highlight = row:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetAllPoints()
                highlight:SetColorTexture(1, 1, 1, 0.2)
                local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                nameText:SetPoint("LEFT", 5, 0)
                nameText:SetWidth(260)
                nameText:SetJustifyH("LEFT")
                row.nameText = nameText
                addon.SpellHelperFrame.spellRows[idx] = row
            end
            
            row:SetPoint("TOPLEFT", 0, yOffset)
            row.nameText:SetText(string.format("|T%s:16|t %s |cff888888(%s)|r", spell.icon, spell.name, spell.id))
            
            row:SetScript("OnClick", function()
                addon.SpellHelperFrame.idInput:SetText(tostring(spell.id))
                addon.SpellHelperFrame.idInput:ClearFocus()
                addon.SpellHelperFrame.UpdateSpellPreview(tostring(spell.id))
                local found = addon.FindButtonsBySpellID(spell.id)
                if found and #found > 0 and found[1]:GetName() then
                    local btnName = found[1]:GetName()
                    UIDropDownMenu_SetText(addon.SpellHelperFrame.btnFrameDD, btnName)
                    addon.SpellHelperFrame.btnFrameDD.selectedValue = btnName
                else
                    UIDropDownMenu_SetText(addon.SpellHelperFrame.btnFrameDD, "")
                    addon.SpellHelperFrame.btnFrameDD.selectedValue = nil
                end
            end)
            row:Show()
            
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
