local addonName, addon = ...

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

-- ═══ Color Dropdown Helper ═══
local colorDropdownCounter = 0

local function CreateColorDropdown(parent, anchorFrame, anchorPoint, xOff, yOff, selectedKey, onSelect)
    colorDropdownCounter = colorDropdownCounter + 1
    local name = "CooldownGlowsColorDD" .. colorDropdownCounter
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dd:SetPoint(anchorPoint or "LEFT", anchorFrame, "RIGHT", xOff or 6, yOff or 0)
    UIDropDownMenu_SetWidth(dd, 80)
    
    local function UpdateText(key)
        local entry = addon.GLOW_COLOR_MAP[key or "default"]
        if entry and entry.color then
            local r, g, b = entry.color[1], entry.color[2], entry.color[3]
            UIDropDownMenu_SetText(dd, string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, entry.name))
        else
            UIDropDownMenu_SetText(dd, "Default")
        end
    end
    UpdateText(selectedKey)
    
    UIDropDownMenu_Initialize(dd, function()
        for _, colorEntry in ipairs(addon.GLOW_COLORS) do
            local info = UIDropDownMenu_CreateInfo()
            if colorEntry.color then
                local r, g, b = colorEntry.color[1], colorEntry.color[2], colorEntry.color[3]
                info.text = string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, colorEntry.name)
            else
                info.text = colorEntry.name
            end
            info.value = colorEntry.key
            info.notCheckable = true
            info.func = function()
                dd.selectedKey = colorEntry.key
                UpdateText(colorEntry.key)
                CloseDropDownMenus()
                if onSelect then onSelect(colorEntry.key) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    dd.selectedKey = selectedKey or "default"
    return dd
end

-- ═══ Color Swatch for Tracked List ═══
local function CreateColorSwatch(parent, row, colorKey, onClick)
    local swatch = CreateFrame("Button", nil, row)
    swatch:SetSize(14, 14)
    local entry = addon.GLOW_COLOR_MAP[colorKey or "default"]
    local tex = swatch:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    if entry and entry.color then
        tex:SetColorTexture(entry.color[1], entry.color[2], entry.color[3], 1)
    else
        tex:SetColorTexture(0.9, 0.8, 0.2, 1)
    end
    swatch.tex = tex
    swatch:SetScript("OnClick", function()
        -- Cycle to next color
        local currentIdx = 1
        for i, c in ipairs(addon.GLOW_COLORS) do
            if c.key == (colorKey or "default") then currentIdx = i; break end
        end
        local nextIdx = (currentIdx % #addon.GLOW_COLORS) + 1
        if onClick then onClick(addon.GLOW_COLORS[nextIdx].key) end
    end)
    swatch:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local name = entry and entry.name or "Default"
        GameTooltip:SetText("Color: " .. name .. " (click to cycle)", 1, 1, 1)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return swatch
end

-- ═══════════════════════════════════════════
-- PROFILE CONTENT BUILDER
-- ═══════════════════════════════════════════

local function BuildProfileContent(container, profileKey)
    local targetProfile = CooldownGlowsDB[profileKey]
    if not targetProfile then return end
    
    local isCurrentPlayer = (profileKey == addon.Class or profileKey == addon.CharKey)
    
    -- ═══ REFRESH TRACKED LIST ═══
    local function RefreshTrackedList()
        ClearChildren(container.listContent)
        local yOffset = -5
        
        local profile = CooldownGlowsDB[profileKey]
        if not profile then return end
        
        -- Render Spells
        if profile.spells and next(profile.spells) then
            local sortedSpells = {}
            for spellID, entry in pairs(profile.spells) do
                local info = C_Spell.GetSpellInfo(spellID)
                table.insert(sortedSpells, {
                    id = spellID,
                    duration = addon.GetEntryDuration(entry),
                    color = addon.GetEntryColor(entry),
                    name = info and info.name or ("Spell " .. spellID),
                    icon = info and info.iconID or 134400
                })
            end
            table.sort(sortedSpells, function(a, b) return a.name < b.name end)
            
            for _, spell in ipairs(sortedSpells) do
                local isActuallyKnown = true
                if isCurrentPlayer then
                    isActuallyKnown = (addon.knownSpells[spell.id] == true)
                end

                local row = CreateFrame("Frame", nil, container.listContent)
                row:SetSize(500, 26)
                row:SetPoint("TOPLEFT", 0, yOffset)
                
                local highlight = row:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetAllPoints()
                highlight:SetColorTexture(1, 1, 1, 0.05)
                
                local colorHex = "|cffffffff"
                if not isActuallyKnown then colorHex = "|cff666666" end
                
                local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                nameText:SetPoint("LEFT", 8, 0)
                nameText:SetWidth(200)
                nameText:SetJustifyH("LEFT")
                nameText:SetText(string.format("|T%s:14:14:0:0|t  %s%s|r", spell.icon, colorHex, spell.name))

                local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                idText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
                idText:SetWidth(70)
                idText:SetJustifyH("CENTER")
                idText:SetText(string.format("%s%s|r", colorHex, tostring(spell.id)))

                local durText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                durText:SetPoint("LEFT", idText, "RIGHT", 5, 0)
                durText:SetWidth(50)
                durText:SetJustifyH("CENTER")
                durText:SetText(string.format("%s%ss|r", colorHex, spell.duration))
                
                local swatch = CreateColorSwatch(container, row, spell.color, function(newKey)
                    profile.spells[spell.id] = { duration = spell.duration, color = newKey }
                    RefreshTrackedList()
                end)
                swatch:SetPoint("LEFT", durText, "RIGHT", 8, 0)

                if not isActuallyKnown then
                    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    statusText:SetPoint("LEFT", swatch, "RIGHT", 5, 0)
                    statusText:SetText("|cff666666(not learned)|r")
                end
                
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
                    profile.spells[spell.id] = nil
                    RefreshTrackedList()
                    if isCurrentPlayer then
                        addon.CheckCooldowns()
                    end
                end)
                
                yOffset = yOffset - 26
            end
        end
        
        -- Render Items
        if profile.items and next(profile.items) then
            local sepFrame = CreateFrame("Frame", nil, container.listContent)
            sepFrame:SetSize(500, 20)
            sepFrame:SetPoint("TOPLEFT", 0, yOffset - 4)
            local sepLabel = sepFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sepLabel:SetPoint("LEFT", 8, 0)
            sepLabel:SetText("|cffccaa00— Items —|r")
            yOffset = yOffset - 24
            
            local sortedItems = {}
            for itemID, entry in pairs(profile.items) do
                local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
                table.insert(sortedItems, {
                    id = itemID,
                    duration = addon.GetEntryDuration(entry),
                    color = addon.GetEntryColor(entry),
                    name = name or ("Item " .. itemID),
                    icon = icon or 134400
                })
            end
            table.sort(sortedItems, function(a, b) return a.name < b.name end)
            
            for _, item in ipairs(sortedItems) do
                local isOnBar = true
                if addon.IsItemOnActionBar then
                    isOnBar = addon.IsItemOnActionBar(item.id)
                end
                
                local row = CreateFrame("Frame", nil, container.listContent)
                row:SetSize(500, 26)
                row:SetPoint("TOPLEFT", 0, yOffset)
                
                local highlight = row:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetAllPoints()
                highlight:SetColorTexture(1, 1, 1, 0.05)
                
                local colorHex = isOnBar and "|cffccaa00" or "|cff666666"
                
                local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                nameText:SetPoint("LEFT", 8, 0)
                nameText:SetWidth(200)
                nameText:SetJustifyH("LEFT")
                nameText:SetText(string.format("|T%s:14:14:0:0|t  %s%s|r", item.icon, colorHex, item.name))

                local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                idText:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
                idText:SetWidth(70)
                idText:SetJustifyH("CENTER")
                idText:SetText(string.format("%s%s|r", colorHex, tostring(item.id)))

                local durText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                durText:SetPoint("LEFT", idText, "RIGHT", 5, 0)
                durText:SetWidth(50)
                durText:SetJustifyH("CENTER")
                durText:SetText(string.format("%s%ss|r", colorHex, item.duration))
                
                local swatch = CreateColorSwatch(container, row, item.color, function(newKey)
                    profile.items[item.id] = { duration = item.duration, color = newKey }
                    RefreshTrackedList()
                end)
                swatch:SetPoint("LEFT", durText, "RIGHT", 8, 0)

                if not isOnBar then
                    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    statusText:SetPoint("LEFT", swatch, "RIGHT", 5, 0)
                    statusText:SetText("|cff666666(not on bar)|r")
                end
                
                local removeBtn = CreateFrame("Button", nil, row)
                removeBtn:SetPoint("RIGHT", -5, 0)
                removeBtn:SetSize(16, 16)
                removeBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
                removeBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Remove item", 1, 0.2, 0.2)
                    GameTooltip:Show()
                end)
                removeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                removeBtn:SetScript("OnClick", function()
                    profile.items[item.id] = nil
                    RefreshTrackedList()
                    if isCurrentPlayer then
                        addon.CheckItemCooldowns()
                    end
                end)
                
                yOffset = yOffset - 26
            end
        end
        
        container.listContent:SetHeight(math.abs(yOffset) + 5)
        
        local hasSpells = profile.spells and next(profile.spells)
        local hasItems = profile.items and next(profile.items)
        if hasSpells or hasItems then
            container.emptyText:Hide()
        else
            container.emptyText:Show()
        end
    end
    
    container.RefreshTrackedList = RefreshTrackedList
    
    -- ═══ ADD SPELL ROW ═══
    local spellLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellLabel:SetPoint("TOPLEFT", 0, 0)
    spellLabel:SetText("Add Spell")
    
    container.spellInput = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    container.spellInput:SetSize(80, 20)
    container.spellInput:SetPoint("LEFT", spellLabel, "RIGHT", 12, 0)
    container.spellInput:SetAutoFocus(false)
    container.spellInput:SetNumeric(true)
    
    local spellDurLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellDurLabel:SetPoint("LEFT", container.spellInput, "RIGHT", 10, 0)
    spellDurLabel:SetText("Duration:")
    
    container.spellDurationInput = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    container.spellDurationInput:SetSize(30, 20)
    container.spellDurationInput:SetPoint("LEFT", spellDurLabel, "RIGHT", 6, 0)
    container.spellDurationInput:SetAutoFocus(false)
    container.spellDurationInput:SetNumeric(true)
    container.spellDurationInput:SetText("3")
    
    container.spellColorDD = CreateColorDropdown(container, container.spellDurationInput, "LEFT", 6, 0, "default")

    local addSpellBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    addSpellBtn:SetSize(60, 22)
    addSpellBtn:SetPoint("LEFT", container.spellColorDD, "RIGHT", -10, 2)
    addSpellBtn:SetText("Add")
    addSpellBtn:SetScript("OnClick", function()
        local spellID = tonumber(container.spellInput:GetText())
        local duration = tonumber(container.spellDurationInput:GetText()) or 3
        local colorKey = container.spellColorDD.selectedKey or "default"
        if spellID and spellID > 0 then
            local p = CooldownGlowsDB[profileKey]
            if p then
                p.spells[spellID] = { duration = duration, color = colorKey }
                container.spellInput:SetText("")
                container.spellDurationInput:SetText("3")
                RefreshTrackedList()
                if isCurrentPlayer then
                    addon.UpdateKnownSpells()
                    addon.CheckCooldowns()
                end
            end
        end
    end)
    
    local spellHelperBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    spellHelperBtn:SetSize(90, 22)
    spellHelperBtn:SetPoint("LEFT", addSpellBtn, "RIGHT", 5, 0)
    spellHelperBtn:SetText("Spell Helper")
    spellHelperBtn:SetScript("OnClick", function()
        addon.ShowSpellHelper(container)
    end)
    
    -- ═══ ADD ITEM ROW ═══
    local itemLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLabel:SetPoint("TOPLEFT", spellLabel, "BOTTOMLEFT", 0, -16)
    itemLabel:SetText("|cffccaa00Add Item|r")
    
    container.itemInput = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    container.itemInput:SetSize(80, 20)
    container.itemInput:SetPoint("LEFT", itemLabel, "RIGHT", 12, 0)
    container.itemInput:SetAutoFocus(false)
    container.itemInput:SetNumeric(true)
    
    local itemDurLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemDurLabel:SetPoint("LEFT", container.itemInput, "RIGHT", 10, 0)
    itemDurLabel:SetText("Duration:")
    
    container.itemDurationInput = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    container.itemDurationInput:SetSize(30, 20)
    container.itemDurationInput:SetPoint("LEFT", itemDurLabel, "RIGHT", 6, 0)
    container.itemDurationInput:SetAutoFocus(false)
    container.itemDurationInput:SetNumeric(true)
    container.itemDurationInput:SetText("3")
    
    container.itemColorDD = CreateColorDropdown(container, container.itemDurationInput, "LEFT", 6, 0, "default")
    
    local addItemBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    addItemBtn:SetSize(60, 22)
    addItemBtn:SetPoint("LEFT", container.itemColorDD, "RIGHT", -10, 2)
    addItemBtn:SetText("Add")
    addItemBtn:SetScript("OnClick", function()
        local itemID = tonumber(container.itemInput:GetText())
        local dur = tonumber(container.itemDurationInput:GetText()) or 3
        local colorKey = container.itemColorDD.selectedKey or "default"
        if itemID and itemID > 0 then
            local p = CooldownGlowsDB[profileKey]
            if p then
                if not p.items then p.items = {} end
                p.items[itemID] = { duration = dur, color = colorKey }
                container.itemInput:SetText("")
                container.itemDurationInput:SetText("3")
                RefreshTrackedList()
                if isCurrentPlayer then
                    addon.ScanActionBarItems()
                    addon.CheckItemCooldowns()
                end
            end
        end
    end)
    
    local itemHelperBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    itemHelperBtn:SetSize(90, 22)
    itemHelperBtn:SetPoint("LEFT", addItemBtn, "RIGHT", 5, 0)
    itemHelperBtn:SetText("Item Helper")
    itemHelperBtn:SetScript("OnClick", function()
        addon.ShowItemHelper(container)
    end)
    
    -- ═══ TRACKED LIST ═══
    local listSep = container:CreateTexture(nil, "ARTWORK")
    listSep:SetHeight(1)
    listSep:SetPoint("TOPLEFT", itemLabel, "BOTTOMLEFT", 0, -12)
    listSep:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    listSep:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    
    local colName = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colName:SetPoint("TOPLEFT", listSep, "BOTTOMLEFT", 10, -6)
    colName:SetText("|cffccccccName|r")
    
    local colID = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colID:SetPoint("LEFT", colName, "LEFT", 205, 0)
    colID:SetText("|cffccccccID|r")
    
    local colDur = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colDur:SetPoint("LEFT", colID, "LEFT", 75, 0)
    colDur:SetText("|cffccccccDuration|r")
    
    local colSep = container:CreateTexture(nil, "ARTWORK")
    colSep:SetHeight(1)
    colSep:SetPoint("TOPLEFT", colName, "BOTTOMLEFT", -5, -3)
    colSep:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    colSep:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    
    local listInset = CreateFrame("Frame", nil, container, "InsetFrameTemplate")
    listInset:SetPoint("TOPLEFT", colSep, "BOTTOMLEFT", -5, -2)
    listInset:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    
    local listScroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", listInset, "TOPLEFT", 5, -5)
    listScroll:SetPoint("BOTTOMRIGHT", listInset, "BOTTOMRIGHT", -25, 5)
    
    container.listContent = CreateFrame("Frame", nil, listScroll)
    container.listContent:SetSize(500, 10)
    listScroll:SetScrollChild(container.listContent)
    
    container.emptyText = listInset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    container.emptyText:SetPoint("CENTER", 0, 0)
    container.emptyText:SetText("|cff666666No spells or items tracked.|r")
    container.emptyText:SetJustifyH("CENTER")
    container.emptyText:Hide()
end

-- ═══════════════════════════════════════════
-- MAIN OPTIONS FRAME
-- ═══════════════════════════════════════════

function addon.CreateOptionsFrames()
    local f = CreateFrame("Frame", "CooldownGlowsOptionsFrame", UIParent)
    f.name = "CooldownGlows"
    
    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("CooldownGlows")
    
    -- ═══ TAB BUTTONS ═══
    local TAB_GENERAL = 1
    local TAB_CLASS = 2
    local TAB_CHAR = 3
    local activeTab = TAB_GENERAL
    
    local tabButtons = {}
    local tabContainers = {}
    
    local function CreateTab(parent, id, label, xOffset)
        local tab = CreateFrame("Button", "CooldownGlowsTab" .. id, parent)
        tab:SetSize(140, 28)
        tab:SetPoint("TOPLEFT", title, "BOTTOMLEFT", xOffset, -10)
        
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
        tab.bg = bg
        
        local border = tab:CreateTexture(nil, "BORDER")
        border:SetPoint("BOTTOMLEFT")
        border:SetPoint("BOTTOMRIGHT")
        border:SetHeight(2)
        border:SetColorTexture(0.8, 0.6, 0, 1)
        border:Hide()
        tab.border = border
        
        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", 0, 0)
        text:SetText(label)
        tab.text = text
        
        tab:SetScript("OnEnter", function(self)
            if activeTab ~= id then
                self.bg:SetColorTexture(0.25, 0.25, 0.25, 0.8)
            end
        end)
        tab:SetScript("OnLeave", function(self)
            if activeTab ~= id then
                self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
            end
        end)
        
        tabButtons[id] = tab
        return tab
    end
    
    local function SetActiveTab(id)
        activeTab = id
        for tabId, btn in pairs(tabButtons) do
            if tabId == id then
                btn.bg:SetColorTexture(0.2, 0.2, 0.2, 1)
                btn.border:Show()
                btn.text:SetFontObject("GameFontHighlight")
            else
                btn.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
                btn.border:Hide()
                btn.text:SetFontObject("GameFontNormal")
            end
        end
        for tabId, container in pairs(tabContainers) do
            if tabId == id then
                container:Show()
            else
                container:Hide()
            end
        end
    end
    
    -- Create tab buttons
    local classTabLabel = FormatClassName(addon.Class)
    local charName = UnitName("player") or "Character"
    
    local tabGeneral = CreateTab(f, TAB_GENERAL, "General", 0)
    local tabClass = CreateTab(f, TAB_CLASS, classTabLabel, 145)
    local tabChar = CreateTab(f, TAB_CHAR, charName, 290)
    
    tabGeneral:SetScript("OnClick", function() SetActiveTab(TAB_GENERAL) end)
    tabClass:SetScript("OnClick", function() SetActiveTab(TAB_CLASS) end)
    tabChar:SetScript("OnClick", function() SetActiveTab(TAB_CHAR) end)
    
    -- Active profile badges
    local function UpdateTabBadges()
        local classActive = addon.ProfileType == "class"
        local charActive = addon.ProfileType == "char"
        
        if classActive then
            tabClass.text:SetText(classTabLabel .. "  |cff00cc00(Active)|r")
        else
            tabClass.text:SetText(classTabLabel)
        end
        
        if charActive then
            tabChar.text:SetText(charName .. "  |cff00cc00(Active)|r")
        else
            tabChar.text:SetText(charName)
        end
    end
    
    -- ═══ TAB CONTAINERS ═══
    -- Separator under tabs
    local tabSep = f:CreateTexture(nil, "ARTWORK")
    tabSep:SetHeight(1)
    tabSep:SetPoint("TOPLEFT", tabGeneral, "BOTTOMLEFT", 0, -2)
    tabSep:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    tabSep:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    
    -- ─── GENERAL TAB ───
    local generalContainer = CreateFrame("Frame", nil, f)
    generalContainer:SetPoint("TOPLEFT", tabSep, "BOTTOMLEFT", 0, -12)
    generalContainer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 10)
    tabContainers[TAB_GENERAL] = generalContainer
    
    local settingsHeader = generalContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsHeader:SetPoint("TOPLEFT", 0, 0)
    settingsHeader:SetText("General Settings")
    
    local combatOnlyCheckbox = CreateFrame("CheckButton", nil, generalContainer, "UICheckButtonTemplate")
    combatOnlyCheckbox:SetPoint("TOPLEFT", settingsHeader, "BOTTOMLEFT", -2, -8)
    combatOnlyCheckbox.text:SetText("Only glow during combat")
    combatOnlyCheckbox.text:SetFontObject("GameFontHighlightSmall")
    combatOnlyCheckbox:SetScript("OnClick", function(self)
        if addon.Profile then
            addon.Profile.combatOnly = self:GetChecked()
            addon.CheckCooldowns()
        end
    end)
    
    -- Active profile info
    local profileInfoSep = generalContainer:CreateTexture(nil, "ARTWORK")
    profileInfoSep:SetHeight(1)
    profileInfoSep:SetPoint("TOPLEFT", combatOnlyCheckbox, "BOTTOMLEFT", 2, -14)
    profileInfoSep:SetPoint("RIGHT", generalContainer, "RIGHT", 0, 0)
    profileInfoSep:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    
    local profileInfoHeader = generalContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileInfoHeader:SetPoint("TOPLEFT", profileInfoSep, "BOTTOMLEFT", 0, -12)
    profileInfoHeader:SetText("Active Profile")
    
    local profileInfoText = generalContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profileInfoText:SetPoint("TOPLEFT", profileInfoHeader, "BOTTOMLEFT", 2, -6)
    
    local function UpdateProfileInfo()
        if addon.ProfileType == "char" then
            local charDisplay = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
            profileInfoText:SetText("|cff00cc00Character profile|r: " .. charDisplay .. "\n|cff888888Class profile is overridden.|r")
        else
            local cObj = C_ClassColor.GetClassColor(addon.Class)
            local colorHex = cObj and cObj:GenerateHexColorMarkup() or "|cffffffff"
            profileInfoText:SetText("|cff00cc00Class profile|r: " .. colorHex .. FormatClassName(addon.Class) .. "|r\n|cff888888No character profile exists.|r")
        end
    end
    
    -- ─── CLASS PROFILE TAB ───
    local classContainer = CreateFrame("Frame", nil, f)
    classContainer:SetPoint("TOPLEFT", tabSep, "BOTTOMLEFT", 0, -12)
    classContainer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 10)
    classContainer:Hide()
    tabContainers[TAB_CLASS] = classContainer
    
    BuildProfileContent(classContainer, addon.Class)
    
    -- ─── CHARACTER PROFILE TAB ───
    local charContainer = CreateFrame("Frame", nil, f)
    charContainer:SetPoint("TOPLEFT", tabSep, "BOTTOMLEFT", 0, -12)
    charContainer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 10)
    charContainer:Hide()
    tabContainers[TAB_CHAR] = charContainer
    
    -- Placeholder for when no char profile exists
    local charEmptyPanel = CreateFrame("Frame", nil, charContainer)
    charEmptyPanel:SetAllPoints()
    
    local charEmptyText = charEmptyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charEmptyText:SetPoint("TOP", 0, -20)
    charEmptyText:SetText("|cff888888No character profile exists for this character.|nCreate one to override the class profile.|r")
    charEmptyText:SetJustifyH("CENTER")
    
    local createCharBtn = CreateFrame("Button", nil, charEmptyPanel, "UIPanelButtonTemplate")
    createCharBtn:SetSize(200, 28)
    createCharBtn:SetPoint("TOP", charEmptyText, "BOTTOM", 0, -14)
    createCharBtn:SetText("Create from Class Profile")
    
    -- Active char profile panel
    local charProfilePanel = CreateFrame("Frame", nil, charContainer)
    charProfilePanel:SetAllPoints()
    charProfilePanel:Hide()
    
    local deleteCharBtn = CreateFrame("Button", nil, charContainer, "UIPanelButtonTemplate")
    deleteCharBtn:SetSize(160, 22)
    deleteCharBtn:SetPoint("TOPRIGHT", charContainer, "TOPRIGHT", 0, 0)
    deleteCharBtn:SetText("Delete Char Profile")
    deleteCharBtn:SetFrameLevel(charContainer:GetFrameLevel() + 10)
    deleteCharBtn:Hide()
    
    local function RefreshCharTab()
        if CooldownGlowsDB[addon.CharKey] then
            charEmptyPanel:Hide()
            charProfilePanel:Show()
            deleteCharBtn:Show()
            
            -- Rebuild profile content
            ClearChildren(charProfilePanel)
            charProfilePanel.listContent = nil
            charProfilePanel.emptyText = nil
            BuildProfileContent(charProfilePanel, addon.CharKey)
            if charProfilePanel.RefreshTrackedList then
                charProfilePanel.RefreshTrackedList()
            end
        else
            charEmptyPanel:Show()
            charProfilePanel:Hide()
            deleteCharBtn:Hide()
        end
        UpdateTabBadges()
        UpdateProfileInfo()
    end
    
    createCharBtn:SetScript("OnClick", function()
        -- Copy class profile to char profile
        CooldownGlowsDB[addon.CharKey] = CopyTable(CooldownGlowsDB[addon.Class])
        addon.Profile = CooldownGlowsDB[addon.CharKey]
        addon.ProfileType = "char"
        RefreshCharTab()
        addon.CheckCooldowns()
        addon.CheckItemCooldowns()
    end)
    
    deleteCharBtn:SetScript("OnClick", function()
        CooldownGlowsDB[addon.CharKey] = nil
        addon.Profile = CooldownGlowsDB[addon.Class]
        addon.ProfileType = "class"
        RefreshCharTab()
        addon.CheckCooldowns()
        addon.CheckItemCooldowns()
    end)
    
    -- ═══ OnShow ═══
    f:SetScript("OnShow", function()
        if addon.Profile then
            if addon.Profile.combatOnly == nil then addon.Profile.combatOnly = false end
            combatOnlyCheckbox:SetChecked(addon.Profile.combatOnly)
        end
        
        UpdateProfileInfo()
        UpdateTabBadges()
        
        -- Refresh class tab
        if classContainer.RefreshTrackedList then
            addon.UpdateKnownSpells()
            classContainer.RefreshTrackedList()
        end
        
        -- Refresh char tab
        RefreshCharTab()
        
        SetActiveTab(activeTab)
    end)
    
    -- ═══ Register ═══
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local mainCategory = Settings.RegisterCanvasLayoutCategory(f, "CooldownGlows")
        Settings.RegisterAddOnCategory(mainCategory)
        addon.category = mainCategory
    else
        InterfaceOptions_AddCategory(f)
    end
end
