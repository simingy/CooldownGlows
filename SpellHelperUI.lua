local addonName, addon = ...

function addon.ShowSpellHelper(activeProfileFrame)
    if not addon.SpellHelperFrame then
        local h = CreateFrame("Frame", "CooldownGlowsSpellHelper", UIParent, "BasicFrameTemplateWithInset")
        h:SetSize(450, 600)
        h:SetMovable(true)
        h:EnableMouse(true)
        h:RegisterForDrag("LeftButton")
        h:SetScript("OnDragStart", h.StartMoving)
        h:SetScript("OnDragStop", h.StopMovingOrSizing)
        h:SetFrameStrata("DIALOG")
        
        -- Try to anchor to the right side of the Settings Panel or Options Frame
        if SettingsPanel and SettingsPanel:IsShown() then
            h:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0)
        elseif addon.OptionsFrame and addon.OptionsFrame:IsShown() then
            h:SetPoint("TOPLEFT", addon.OptionsFrame, "TOPRIGHT", 10, 0)
        else
            h:SetPoint("CENTER")
        end

        h.title = h:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        h.title:SetPoint("TOP", h, "TOP", 0, -5)
        h.title:SetText("Spellbook IDs")
        
        -- Column Headers
        h.headerIcon = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.headerIcon:SetPoint("TOPLEFT", h, "TOPLEFT", 15, -30)
        h.headerIcon:SetText("Spell Name")
        
        h.headerID = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.headerID:SetPoint("TOPRIGHT", h, "TOPRIGHT", -35, -30)
        h.headerID:SetText("Spell ID")

        h.scroll = CreateFrame("ScrollFrame", nil, h, "UIPanelScrollFrameTemplate")
        h.scroll:SetPoint("TOPLEFT", 10, -50)
        h.scroll:SetPoint("BOTTOMRIGHT", -30, 10)
        h.content = CreateFrame("Frame", nil, h.scroll)
        h.content:SetSize(350, 10)
        h.scroll:SetScrollChild(h.content)

        addon.SpellHelperFrame = h
        
        -- Close when Settings closes
        if SettingsPanel then
            SettingsPanel:HookScript("OnHide", function() addon.SpellHelperFrame:Hide() end)
        end
        if addon.OptionsFrame then
            addon.OptionsFrame:HookScript("OnHide", function() addon.SpellHelperFrame:Hide() end)
        end
    end
    
    -- Mutually exclusive with Item Helper
    if addon.ItemHelperFrame and addon.ItemHelperFrame:IsShown() then
        addon.ItemHelperFrame:Hide()
    end
    
    -- Re-anchor if opened from closed state
    if not addon.SpellHelperFrame:IsShown() then
        addon.SpellHelperFrame:ClearAllPoints()
        if SettingsPanel and SettingsPanel:IsShown() then
            addon.SpellHelperFrame:SetPoint("TOPLEFT", SettingsPanel, "TOPRIGHT", 10, 0)
        elseif addon.OptionsFrame and addon.OptionsFrame:IsShown() then
            addon.SpellHelperFrame:SetPoint("TOPLEFT", addon.OptionsFrame, "TOPRIGHT", 10, 0)
        else
            addon.SpellHelperFrame:SetPoint("CENTER")
        end
    end
    
    local content = addon.SpellHelperFrame.content
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

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
                    if info and info.name and not info.isPassive then
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
    
    -- Sort the spell list alphabetically by name
    table.sort(spellList, function(a, b)
        return a.name < b.name
    end)
    
    -- Render the sorted list
    for _, spell in ipairs(spellList) do
        local row = CreateFrame("Button", nil, content)
        row:SetSize(350, 20)
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.2)
        
        row:SetScript("OnClick", function()
            if activeProfileFrame and activeProfileFrame.spellInput then
                activeProfileFrame.spellInput:SetText(tostring(spell.id))
                if activeProfileFrame.spellDurationInput then
                    activeProfileFrame.spellDurationInput:SetText("3")
                end
            end
            addon.SpellHelperFrame:Hide()
        end)
        
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", 5, 0)
        nameText:SetWidth(240)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(string.format("|T%s:16|t %s", spell.icon, spell.name))
        
        local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        idText:SetPoint("RIGHT", -5, 0)
        idText:SetWidth(60)
        idText:SetJustifyH("RIGHT")
        idText:SetText(tostring(spell.id))
        
        yOffset = yOffset - 22
    end
    content:SetHeight(math.abs(yOffset))
    addon.SpellHelperFrame:Show()
end
