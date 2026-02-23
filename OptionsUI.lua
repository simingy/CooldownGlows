local addonName, addon = ...

local profileFrames = {}

local function ClearChildren(frame)
    if not frame then return end
    local children = {frame:GetChildren()}
    for i = 1, #children do
        children[i]:Hide()
        children[i]:SetParent(nil)
    end
end

local function FormatClassName(className)
    if not className then return "" end
    if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[className] then
        return LOCALIZED_CLASS_NAMES_MALE[className]
    end
    local lower = className:lower()
    return lower:gsub("^%l", string.upper)
end

local function RefreshSpellList(pf, className, isSyncing)
    ClearChildren(pf.content)
    
    local yOffset = -5
    local targetProfile = CooldownGlowsDB[className]
    if not targetProfile or not targetProfile.spells then return end
    
    -- Sort spells alphabetically by name for consistent display
    local sortedSpells = {}
    for spellID, duration in pairs(targetProfile.spells) do
        local info = C_Spell.GetSpellInfo(spellID)
        table.insert(sortedSpells, {
            id = spellID,
            duration = duration,
            name = info and info.name or ("Spell " .. spellID),
            icon = info and info.iconID or 134400
        })
    end
    table.sort(sortedSpells, function(a, b) return a.name < b.name end)
    
    for _, spell in ipairs(sortedSpells) do
        local isActuallyKnown = true
        if not isSyncing and className == addon.Class then
            isActuallyKnown = (addon.knownSpells[spell.id] == true)
        end

        local row = CreateFrame("Frame", nil, pf.content)
        row:SetSize(500, 26)
        row:SetPoint("TOPLEFT", 0, yOffset)
        
        -- Hover highlight
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.05)
        
        -- Alternating row background
        if math.fmod(#sortedSpells - #sortedSpells + yOffset, 2) == 0 then
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0, 0, 0, 0.15)
        end
        
        local colorHex = "|cffffffff"
        if not isSyncing and not isActuallyKnown then
            colorHex = "|cff666666"
        end
        
        -- Icon + Name
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("LEFT", 8, 0)
        nameText:SetWidth(200)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(string.format("|T%s:14:14:0:0|t  %s%s|r", spell.icon, colorHex, spell.name))

        -- Spell ID
        local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        idText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
        idText:SetWidth(70)
        idText:SetJustifyH("CENTER")
        idText:SetText(string.format("%s%s|r", colorHex, tostring(spell.id)))

        -- Duration
        local durText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        durText:SetPoint("LEFT", idText, "RIGHT", 5, 0)
        durText:SetWidth(50)
        durText:SetJustifyH("CENTER")
        durText:SetText(string.format("%s%ss|r", colorHex, spell.duration))

        -- Status indicator for unknown spells
        if not isSyncing and not isActuallyKnown then
            local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            statusText:SetPoint("LEFT", durText, "RIGHT", 5, 0)
            statusText:SetText("|cff666666(not learned)|r")
        end
        
        -- Delete button (smaller, less obtrusive)
        local removeBtn = CreateFrame("Button", nil, row)
        removeBtn:SetPoint("RIGHT", -5, 0)
        removeBtn:SetSize(16, 16)
        removeBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
        removeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove spell", 1, 0.2, 0.2)
            GameTooltip:Show()
        end)
        removeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        removeBtn:SetScript("OnClick", function()
            targetProfile.spells[spell.id] = nil
            RefreshSpellList(pf, className)
            if className == addon.Class then
                addon.CheckCooldowns()
            end
        end)
        
        yOffset = yOffset - 26
    end
    pf.content:SetHeight(math.abs(yOffset) + 5)
end

function addon.CreateOptionsFrames()
    -- ═══════════════════════════════════════════
    -- MAIN SETTINGS PAGE
    -- ═══════════════════════════════════════════
    local f = CreateFrame("Frame", "CooldownGlowsOptionsFrame", UIParent)
    f.name = "CooldownGlows"
    
    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CooldownGlows")
    
    -- Subtitle / description
    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("|cff888888Highlights action bar buttons when spell cooldowns finish.|r")
    
    -- Separator line
    local sep1 = f:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
    sep1:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    sep1:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    
    -- Settings Section
    local settingsHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsHeader:SetPoint("TOPLEFT", sep1, "BOTTOMLEFT", 0, -12)
    settingsHeader:SetText("General Settings")
    
    local combatOnlyCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    combatOnlyCheckbox:SetPoint("TOPLEFT", settingsHeader, "BOTTOMLEFT", -2, -8)
    combatOnlyCheckbox.text:SetText("Only glow during combat")
    combatOnlyCheckbox.text:SetFontObject("GameFontHighlightSmall")
    combatOnlyCheckbox:SetScript("OnClick", function(self)
        if addon.Profile then
            addon.Profile.combatOnly = self:GetChecked()
            addon.CheckCooldowns()
        end
    end)
    
    -- Separator line
    local sep2 = f:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT", combatOnlyCheckbox, "BOTTOMLEFT", 2, -12)
    sep2:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    sep2:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    
    -- Profiles Section
    local pTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pTitle:SetPoint("TOPLEFT", sep2, "BOTTOMLEFT", 0, -12)
    pTitle:SetText("Character Profiles")
    
    local pDesc = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pDesc:SetPoint("TOPLEFT", pTitle, "BOTTOMLEFT", 0, -4)
    pDesc:SetText("|cff888888Click a profile to configure its tracked spells.|r")
    
    -- Column headers
    local headerName = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerName:SetPoint("TOPLEFT", pDesc, "BOTTOMLEFT", 10, -14)
    headerName:SetText("|cffccccccClass|r")
    
    local headerStatus = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerStatus:SetPoint("LEFT", headerName, "LEFT", 210, 0)
    headerStatus:SetText("|cffccccccStatus|r")
    
    -- Header separator
    local headerSep = f:CreateTexture(nil, "ARTWORK")
    headerSep:SetHeight(1)
    headerSep:SetPoint("TOPLEFT", headerName, "BOTTOMLEFT", -5, -4)
    headerSep:SetPoint("RIGHT", f, "RIGHT", -40, 0)
    headerSep:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    
    local listInset = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
    listInset:SetPoint("TOPLEFT", headerSep, "BOTTOMLEFT", -5, -2)
    listInset:SetSize(500, 160)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listInset, "TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", listInset, "BOTTOMRIGHT", -25, 5)
    
    local pListContent = CreateFrame("Frame", nil, scrollFrame)
    pListContent:SetSize(450, 10)
    scrollFrame:SetScrollChild(pListContent)
    
    local function RefreshProfileList()
        ClearChildren(pListContent)
        local yOffset = -2
        for className, _ in pairs(CooldownGlowsDB) do
            local row = CreateFrame("Frame", nil, pListContent)
            row:SetSize(450, 24)
            row:SetPoint("TOPLEFT", 0, yOffset)
            
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.08)
            
            local isActive = (className == addon.Class)
            local colorHex = "|cffffffff"
            if isActive then
                local cObj = C_ClassColor.GetClassColor(className)
                if cObj then colorHex = cObj:GenerateHexColorMarkup() end
            end
            
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameText:SetPoint("LEFT", 10, 0)
            nameText:SetWidth(200)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(colorHex .. FormatClassName(className) .. "|r")
            
            local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            statusText:SetPoint("LEFT", nameText, "LEFT", 210, 0)
            statusText:SetWidth(100)
            statusText:SetJustifyH("LEFT")
            if isActive then
                statusText:SetText("|cff00cc00Active|r")
            else
                statusText:SetText("|cff666666Off-spec|r")
            end
            
            -- Spell count
            local profile = CooldownGlowsDB[className]
            local spellCount = 0
            if profile and profile.spells then
                for _ in pairs(profile.spells) do spellCount = spellCount + 1 end
            end
            local countText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            countText:SetPoint("LEFT", statusText, "RIGHT", 10, 0)
            countText:SetText("|cff888888" .. spellCount .. " spells|r")
            
            -- Delete button
            local removeBtn = CreateFrame("Button", nil, row)
            removeBtn:SetPoint("RIGHT", -5, 0)
            removeBtn:SetSize(14, 14)
            removeBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
            removeBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Delete profile: " .. FormatClassName(className), 1, 0.2, 0.2)
                GameTooltip:Show()
            end)
            removeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            removeBtn:SetScript("OnClick", function()
                CooldownGlowsDB[className] = nil
                if profileFrames[className] then profileFrames[className]:Hide() end
                RefreshProfileList()
            end)
            yOffset = yOffset - 24
        end
        pListContent:SetHeight(math.abs(yOffset) + 5)
    end
    
    f:SetScript("OnShow", function()
        RefreshProfileList()
        if addon.Profile then
            if addon.Profile.combatOnly == nil then addon.Profile.combatOnly = false end
            combatOnlyCheckbox:SetChecked(addon.Profile.combatOnly)
        end
    end)

    -- ═══════════════════════════════════════════
    -- REGISTER WITH SETTINGS
    -- ═══════════════════════════════════════════
    local mainCategory
    if Settings and Settings.RegisterCanvasLayoutCategory then
        mainCategory = Settings.RegisterCanvasLayoutCategory(f, "CooldownGlows")
        Settings.RegisterAddOnCategory(mainCategory)
        addon.category = mainCategory
    else
        InterfaceOptions_AddCategory(f)
    end
    
    -- ═══════════════════════════════════════════
    -- PER-CLASS PROFILE PAGES
    -- ═══════════════════════════════════════════
    for className, _ in pairs(CooldownGlowsDB) do
        local pf = CreateFrame("Frame", "CooldownGlowsProfileFrame_" .. className, UIParent)
        pf:Hide()
        pf.name = FormatClassName(className)
        pf.parent = f.name
        
        -- Class-colored title
        local classColor = "|cffffffff"
        local cObj = C_ClassColor.GetClassColor(className)
        if cObj then classColor = cObj:GenerateHexColorMarkup() end
        
        local pTitle = pf:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        pTitle:SetPoint("TOPLEFT", 16, -16)
        pTitle:SetText(classColor .. pf.name .. "|r Profile")
        
        local pDesc = pf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pDesc:SetPoint("TOPLEFT", pTitle, "BOTTOMLEFT", 0, -4)
        pDesc:SetText("|cff888888Add spells to track. A glow will appear on the action bar when a spell comes off cooldown.|r")
        
        -- Separator
        local sep = pf:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("TOPLEFT", pDesc, "BOTTOMLEFT", 0, -10)
        sep:SetPoint("RIGHT", pf, "RIGHT", -16, 0)
        sep:SetColorTexture(0.4, 0.4, 0.4, 0.4)
        
        -- Input row
        pf.spellInputLabel = pf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pf.spellInputLabel:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 0, -12)
        pf.spellInputLabel:SetText("Spell ID:")
        
        pf.spellInput = CreateFrame("EditBox", nil, pf, "InputBoxTemplate")
        pf.spellInput:SetSize(80, 20)
        pf.spellInput:SetPoint("LEFT", pf.spellInputLabel, "RIGHT", 8, 0)
        pf.spellInput:SetAutoFocus(false)
        pf.spellInput:SetNumeric(true)
        
        pf.durationInputLabel = pf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pf.durationInputLabel:SetPoint("LEFT", pf.spellInput, "RIGHT", 12, 0)
        pf.durationInputLabel:SetText("Duration (s):")
        
        pf.durationInput = CreateFrame("EditBox", nil, pf, "InputBoxTemplate")
        pf.durationInput:SetSize(40, 20)
        pf.durationInput:SetPoint("LEFT", pf.durationInputLabel, "RIGHT", 8, 0)
        pf.durationInput:SetAutoFocus(false)
        pf.durationInput:SetNumeric(true)
        pf.durationInput:SetText("3")

        pf.addButton = CreateFrame("Button", nil, pf, "UIPanelButtonTemplate")
        pf.addButton:SetSize(80, 22)
        pf.addButton:SetPoint("LEFT", pf.durationInput, "RIGHT", 12, 0)
        pf.addButton:SetText("Add")
        pf.addButton:SetScript("OnClick", function()
            local spellID = tonumber(pf.spellInput:GetText())
            local duration = tonumber(pf.durationInput:GetText()) or 0
            if spellID and spellID > 0 then
                local targetProfile = CooldownGlowsDB[className]
                if targetProfile then
                    targetProfile.spells[spellID] = duration
                    pf.spellInput:SetText("")
                    pf.durationInput:SetText("3")
                    RefreshSpellList(pf, className)
                    if className == addon.Class then
                        addon.UpdateKnownSpells()
                        addon.CheckCooldowns()
                    end
                end
            end
        end)
        
        pf.helperBtn = CreateFrame("Button", nil, pf, "UIPanelButtonTemplate")
        pf.helperBtn:SetSize(100, 22)
        pf.helperBtn:SetPoint("LEFT", pf.addButton, "RIGHT", 5, 0)
        pf.helperBtn:SetText("Spell Helper")
        pf.helperBtn:SetScript("OnClick", function()
            addon.ShowSpellHelper(pf)
        end)
        
        -- Column headers for the spell list
        local colName = pf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        colName:SetPoint("TOPLEFT", pf.spellInputLabel, "BOTTOMLEFT", 10, -20)
        colName:SetText("|cffccccccSpell|r")
        
        local colID = pf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        colID:SetPoint("LEFT", colName, "LEFT", 205, 0)
        colID:SetText("|cffccccccID|r")
        
        local colDur = pf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        colDur:SetPoint("LEFT", colID, "LEFT", 75, 0)
        colDur:SetText("|cffccccccDuration|r")
        
        -- Column header separator
        local colSep = pf:CreateTexture(nil, "ARTWORK")
        colSep:SetHeight(1)
        colSep:SetPoint("TOPLEFT", colName, "BOTTOMLEFT", -5, -3)
        colSep:SetPoint("RIGHT", pf, "RIGHT", -30, 0)
        colSep:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        
        local listInset = CreateFrame("Frame", nil, pf, "InsetFrameTemplate")
        listInset:SetPoint("TOPLEFT", colSep, "BOTTOMLEFT", -5, -2)
        listInset:SetPoint("BOTTOMRIGHT", pf, "BOTTOMRIGHT", -10, 10)
        
        pf.scrollFrame = CreateFrame("ScrollFrame", nil, pf, "UIPanelScrollFrameTemplate")
        pf.scrollFrame:SetPoint("TOPLEFT", listInset, "TOPLEFT", 5, -5)
        pf.scrollFrame:SetPoint("BOTTOMRIGHT", listInset, "BOTTOMRIGHT", -25, 5)
        
        pf.content = CreateFrame("Frame", nil, pf.scrollFrame)
        pf.content:SetSize(500, 10)
        pf.scrollFrame:SetScrollChild(pf.content)
        
        -- Syncing indicator (subtle, bottom-right)
        pf.loadingText = listInset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pf.loadingText:SetPoint("BOTTOMRIGHT", -5, 5)
        pf.loadingText:SetText("|cff666666Syncing spellbook...|r")
        pf.loadingText:Hide()
        
        -- Empty state text
        pf.emptyText = listInset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pf.emptyText:SetPoint("CENTER", 0, 0)
        pf.emptyText:SetText("|cff666666No spells configured.\nUse Spell Helper or enter a Spell ID above.|r")
        pf.emptyText:SetJustifyH("CENTER")
        pf.emptyText:Hide()
        
        pf:SetScript("OnShow", function()
            -- Optimistic render: show spells immediately, then update known-status
            RefreshSpellList(pf, className, true)
            
            local targetProfile = CooldownGlowsDB[className]
            local hasSpells = targetProfile and targetProfile.spells and next(targetProfile.spells)
            if hasSpells then
                pf.emptyText:Hide()
                pf.loadingText:Show()
            else
                pf.emptyText:Show()
                pf.loadingText:Hide()
            end
            
            C_Timer.After(0.01, function()
                if className == addon.Class then
                    addon.UpdateKnownSpells()
                end
                RefreshSpellList(pf, className, false)
                pf.loadingText:Hide()
                if not hasSpells then pf.emptyText:Show() end
            end)
        end)
        
        if Settings and Settings.RegisterCanvasLayoutCategory then
            Settings.RegisterCanvasLayoutSubcategory(mainCategory, pf, pf.name)
        else
            InterfaceOptions_AddCategory(pf)
        end
        profileFrames[className] = pf
    end
end
