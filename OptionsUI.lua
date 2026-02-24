local addonName, addon = ...

local function ClearChildren(frame)
    if not frame then return end
    local children = {frame:GetChildren()}
    for i = 1, #children do
        children[i]:Hide()
        children[i]:SetParent(UIParent)
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

function addon.CreateColorDropdown(parent, anchorFrame, anchorPoint, xOff, yOff, selectedKey, onSelect)
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
local function CreateColorSwatch(parent, anchorTo, colorKey)
    local swatch = CreateFrame("Frame", nil, anchorTo)
    
    local isDefault = (colorKey == nil or colorKey == "default")
    local entry = addon.GLOW_COLOR_MAP[colorKey or "default"]
    
    if isDefault then
        swatch:SetSize(40, 14)
        local text = swatch:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", 0, 0)
        text:SetText("Default")
        
        swatch:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Color: Default", 1, 1, 1)
            GameTooltip:Show()
        end)
    else
        swatch:SetSize(14, 14)
        local tex = swatch:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        if entry and entry.color then
            tex:SetColorTexture(entry.color[1], entry.color[2], entry.color[3], 1)
        else
            tex:SetColorTexture(1, 1, 1, 1) -- White fallback
        end
        
        swatch:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local name = entry and entry.name or "Unknown"
            GameTooltip:SetText("Color: " .. name, 1, 1, 1)
            GameTooltip:Show()
        end)
    end
    
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
        if container.spellContent then ClearChildren(container.spellContent) end
        if container.itemContent then ClearChildren(container.itemContent) end
        
        local profile = CooldownGlowsDB[profileKey]
        if not profile then return end
        
        -- Render Spells
        local spellYOffset = -5
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

                local row = CreateFrame("Frame", nil, container.spellContent)
                row:SetSize(470, 26)
                row:SetPoint("TOPLEFT", 0, spellYOffset)
                
                local highlight = row:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetAllPoints()
                highlight:SetColorTexture(1, 1, 1, 0.05)
                
                local colorHex = "|cffffffff"
                if not isActuallyKnown then colorHex = "|cff666666" end
                
                local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                nameText:SetPoint("LEFT", 8, 0)
                nameText:SetWidth(180)
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
                
                local swatch = CreateColorSwatch(container, row, spell.color)
                swatch:SetPoint("LEFT", durText, "RIGHT", 8, 0)

                if not isActuallyKnown then
                    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    statusText:SetPoint("LEFT", swatch, "RIGHT", 5, 0)
                    statusText:SetText("|cff666666(not learned)|r")
                end
                
                local removeBtn = CreateFrame("Button", nil, row)
                removeBtn:SetPoint("RIGHT", -5, 0)
                removeBtn:SetSize(16, 16)
                
                local editBtn = CreateFrame("Button", nil, row)
                editBtn:SetPoint("RIGHT", removeBtn, "LEFT", -5, 0)
                editBtn:SetSize(16, 16)
                editBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
                editBtn:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", "ADD")
                editBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Edit spell", 1, 1, 1)
                    GameTooltip:Show()
                end)
                editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                editBtn:SetScript("OnClick", function()
                    addon.ShowSpellHelper(container, profileKey, true)
                    local h = addon.SpellHelperFrame
                    if h then
                        h.isEditing = true
                        h.idInput:SetText(tostring(spell.id))
                        h.durInput:SetText(tostring(spell.duration))
                        
                        h.colorDD.selectedKey = spell.color
                        local entry = addon.GLOW_COLOR_MAP[spell.color or "default"]
                        if entry and entry.color then
                            local r, g, b = entry.color[1], entry.color[2], entry.color[3]
                            UIDropDownMenu_SetText(h.colorDD, string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, entry.name))
                        else
                            UIDropDownMenu_SetText(h.colorDD, "Default")
                        end
                        
                        h.addBtn:SetText("Save Spell")
                        h.UpdateSpellPreview(tostring(spell.id))
                    end
                end)
                
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
                
                spellYOffset = spellYOffset - 26
            end
        end
        if container.spellContent then container.spellContent:SetHeight(math.abs(spellYOffset) + 5) end
        if container.spellEmpty then
            if profile.spells and next(profile.spells) then container.spellEmpty:Hide() else container.spellEmpty:Show() end
        end
        
        -- Render Items
        local itemYOffset = -5
        if profile.items and next(profile.items) then
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
                
                local row = CreateFrame("Frame", nil, container.itemContent)
                row:SetSize(470, 26)
                row:SetPoint("TOPLEFT", 0, itemYOffset)
                
                local highlight = row:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetAllPoints()
                highlight:SetColorTexture(1, 1, 0.6, 0.05)
                
                local colorHex = isOnBar and "|cffccaa00" or "|cff666666"
                
                local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                nameText:SetPoint("LEFT", 8, 0)
                nameText:SetWidth(180)
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
                
                local swatch = CreateColorSwatch(container, row, item.color)
                swatch:SetPoint("LEFT", durText, "RIGHT", 8, 0)

                if not isOnBar then
                    local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    statusText:SetPoint("LEFT", swatch, "RIGHT", 5, 0)
                    statusText:SetText("|cff666666(not on bar)|r")
                end
                
                local removeBtn = CreateFrame("Button", nil, row)
                removeBtn:SetPoint("RIGHT", -5, 0)
                removeBtn:SetSize(16, 16)
                
                local editBtn = CreateFrame("Button", nil, row)
                editBtn:SetPoint("RIGHT", removeBtn, "LEFT", -5, 0)
                editBtn:SetSize(16, 16)
                editBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
                editBtn:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", "ADD")
                editBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Edit item", 1, 1, 1)
                    GameTooltip:Show()
                end)
                editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                editBtn:SetScript("OnClick", function()
                    addon.ShowItemHelper(container, profileKey, true)
                    local h = addon.ItemHelperFrame
                    if h then
                        h.isEditing = true
                        h.idInput:SetText(tostring(item.id))
                        h.durInput:SetText(tostring(item.duration))
                        
                        h.colorDD.selectedKey = item.color
                        local entry = addon.GLOW_COLOR_MAP[item.color or "default"]
                        if entry and entry.color then
                            local r, g, b = entry.color[1], entry.color[2], entry.color[3]
                            UIDropDownMenu_SetText(h.colorDD, string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, entry.name))
                        else
                            UIDropDownMenu_SetText(h.colorDD, "Default")
                        end
                        
                        h.addBtn:SetText("Save Item")
                        h.UpdateItemPreview(tostring(item.id))
                    end
                end)
                
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
                
                itemYOffset = itemYOffset - 26
            end
        end
        
        if container.itemContent then container.itemContent:SetHeight(math.abs(itemYOffset) + 5) end
        if container.itemEmpty then
            if profile.items and next(profile.items) then container.itemEmpty:Hide() else container.itemEmpty:Show() end
        end
    end
    
    container.RefreshTrackedList = RefreshTrackedList
    
    -- ═══ HEADERS AND FRAMES ═══
    -- ** Spells Section **
    local spellTitle = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spellTitle:SetPoint("TOPLEFT", 5, -5)
    spellTitle:SetText("Spells")
    
    local addSpellBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    addSpellBtn:SetSize(120, 24)
    addSpellBtn:SetPoint("RIGHT", container, "TOPRIGHT", -16, -2)
    addSpellBtn:SetText("Add Spell")
    addSpellBtn:SetScript("OnClick", function()
        addon.ShowSpellHelper(container, profileKey)
    end)
    
    local spellSep = container:CreateTexture(nil, "ARTWORK")
    spellSep:SetHeight(1)
    spellSep:SetPoint("TOPLEFT", spellTitle, "BOTTOMLEFT", 0, -10)
    spellSep:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    spellSep:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    
    local spellColName = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellColName:SetPoint("TOPLEFT", spellSep, "BOTTOMLEFT", 10, -6)
    spellColName:SetText("|cffccccccName|r")
    
    local spellColID = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellColID:SetPoint("LEFT", spellColName, "LEFT", 185, 0)
    spellColID:SetText("|cffccccccID|r")
    
    local spellColDur = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellColDur:SetPoint("LEFT", spellColID, "LEFT", 75, 0)
    spellColDur:SetText("|cffccccccDuration|r")
    
    local spellColColor = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellColColor:SetPoint("LEFT", spellColDur, "LEFT", 60, 0)
    spellColColor:SetText("|cffccccccColor|r")
    
    local spellColAction = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellColAction:SetPoint("RIGHT", spellSep, "RIGHT", -22, -6)
    spellColAction:SetText("|cffccccccAction|r")
    
    local spellColSep = container:CreateTexture(nil, "ARTWORK")
    spellColSep:SetHeight(1)
    spellColSep:SetPoint("TOPLEFT", spellColName, "BOTTOMLEFT", -5, -3)
    spellColSep:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    spellColSep:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    
    local spellInset = CreateFrame("Frame", nil, container, "InsetFrameTemplate")
    spellInset:SetPoint("TOPLEFT", spellColSep, "BOTTOMLEFT", -5, -2)
    spellInset:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    spellInset:SetHeight(190)
    
    local spellScroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    spellScroll:SetPoint("TOPLEFT", spellInset, "TOPLEFT", 5, -5)
    spellScroll:SetPoint("BOTTOMRIGHT", spellInset, "BOTTOMRIGHT", -25, 5)
    
    container.spellContent = CreateFrame("Frame", nil, spellScroll)
    container.spellContent:SetSize(470, 10)
    spellScroll:SetScrollChild(container.spellContent)
    
    container.spellEmpty = spellInset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    container.spellEmpty:SetPoint("CENTER", 0, 0)
    container.spellEmpty:SetText("|cff666666No spells tracked.|r")
    container.spellEmpty:Hide()
    
    -- ** Items Section **
    local itemTitle = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemTitle:SetPoint("TOPLEFT", spellInset, "BOTTOMLEFT", 5, -15)
    itemTitle:SetText("Items")
    
    local addItemBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    addItemBtn:SetSize(120, 24)
    addItemBtn:SetPoint("RIGHT", spellInset, "BOTTOMRIGHT", 0, -25)
    addItemBtn:SetText("Add Item")
    addItemBtn:SetScript("OnClick", function()
        addon.ShowItemHelper(container, profileKey)
    end)
    
    local itemSep = container:CreateTexture(nil, "ARTWORK")
    itemSep:SetHeight(1)
    itemSep:SetPoint("TOPLEFT", itemTitle, "BOTTOMLEFT", -5, -10)
    itemSep:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    itemSep:SetColorTexture(0.4, 0.4, 0.4, 0.4)
    
    local itemColName = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemColName:SetPoint("TOPLEFT", itemSep, "BOTTOMLEFT", 10, -6)
    itemColName:SetText("|cffccccccName|r")
    
    local itemColID = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemColID:SetPoint("LEFT", itemColName, "LEFT", 185, 0)
    itemColID:SetText("|cffccccccID|r")
    
    local itemColDur = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemColDur:SetPoint("LEFT", itemColID, "LEFT", 75, 0)
    itemColDur:SetText("|cffccccccDuration|r")
    
    local itemColColor = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemColColor:SetPoint("LEFT", itemColDur, "LEFT", 60, 0)
    itemColColor:SetText("|cffccccccColor|r")
    
    local itemColAction = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemColAction:SetPoint("RIGHT", itemSep, "RIGHT", -22, -6)
    itemColAction:SetText("|cffccccccAction|r")
    
    local itemColSep = container:CreateTexture(nil, "ARTWORK")
    itemColSep:SetHeight(1)
    itemColSep:SetPoint("TOPLEFT", itemColName, "BOTTOMLEFT", -5, -3)
    itemColSep:SetPoint("RIGHT", container, "RIGHT", -16, 0)
    itemColSep:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    
    local itemInset = CreateFrame("Frame", nil, container, "InsetFrameTemplate")
    itemInset:SetPoint("TOPLEFT", itemColSep, "BOTTOMLEFT", -5, -2)
    itemInset:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -16, 0)
    
    local itemScroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    itemScroll:SetPoint("TOPLEFT", itemInset, "TOPLEFT", 5, -5)
    itemScroll:SetPoint("BOTTOMRIGHT", itemInset, "BOTTOMRIGHT", -25, 5)
    
    container.itemContent = CreateFrame("Frame", nil, itemScroll)
    container.itemContent:SetSize(470, 10)
    itemScroll:SetScrollChild(container.itemContent)
    
    container.itemEmpty = itemInset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    container.itemEmpty:SetPoint("CENTER", 0, 0)
    container.itemEmpty:SetText("|cff666666No items tracked.|r")
    container.itemEmpty:Hide()
end

-- ═══════════════════════════════════════════
-- MAIN OPTIONS FRAME
-- ═══════════════════════════════════════════

function addon.CreateOptionsFrames()
    local f = CreateFrame("Frame", "CooldownGlowsOptionsFrame", UIParent)
    f.name = "CooldownGlows"
    addon.OptionsFrame = f
    
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
            charProfilePanel.spellContent = nil
            charProfilePanel.itemContent = nil
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
        -- Wipe stale glow states from old profile
        wipe(addon.cdStates)
        wipe(addon.itemCdStates)
        for btn, timer in pairs(addon.activeTimers) do
            timer:Cancel()
            addon.HideGlow(btn)
        end
        wipe(addon.activeTimers)
        RefreshCharTab()
        addon.CheckCooldowns()
        addon.CheckItemCooldowns()
    end)
    
    deleteCharBtn:SetScript("OnClick", function()
        CooldownGlowsDB[addon.CharKey] = nil
        addon.Profile = CooldownGlowsDB[addon.Class]
        addon.ProfileType = "class"
        -- Wipe stale glow states from old profile
        wipe(addon.cdStates)
        wipe(addon.itemCdStates)
        for btn, timer in pairs(addon.activeTimers) do
            timer:Cancel()
            addon.HideGlow(btn)
        end
        wipe(addon.activeTimers)
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
    local mainCategory = Settings.RegisterCanvasLayoutCategory(f, "CooldownGlows")
    Settings.RegisterAddOnCategory(mainCategory)
    addon.category = mainCategory
end
