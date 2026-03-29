local addonName, addon = ...

addon.knownSpells = {}
addon.cdStates = {}
addon.itemCdStates = {}

function addon.UpdateKnownSpells()
    if not addon.Profile then return end
    wipe(addon.knownSpells)
    
    local tabs = C_SpellBook.GetNumSpellBookSkillLines()
    for i = 1, tabs do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
        if skillLineInfo then
            local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems
            for j = offset + 1, offset + numSlots do
                local spellType, spellID = C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
                if (spellType == Enum.SpellBookItemType.Spell or spellType == Enum.SpellBookItemType.FutureSpell) and spellID then
                    addon.knownSpells[spellID] = true
                end
            end
        end
    end
    
    local count = 0
    for _ in pairs(addon.knownSpells) do count = count + 1 end
    addon.Print("Scanned spellbook: %d spells tracked.", count)
end

function addon.IsCombatOnly()
    return addon.Profile and addon.Profile.combatOnly and not UnitAffectingCombat("player")
end

function addon.CheckCooldowns()
    if not addon.Profile or not addon.Profile.spells then return end
    local suppressed = addon.IsCombatOnly()
    
    for spellID, entry in pairs(addon.Profile.spells) do
        if addon.knownSpells[spellID] then
            local duration = addon.GetEntryDuration(entry)
            local colorKey = addon.GetEntryColor(entry)
            
            local buttons = addon.FindButtonsBySpellID(spellID)
            local cdInfo = C_Spell.GetSpellCooldown(spellID)
            
            local onCooldown = false
            if cdInfo and cdInfo.isActive and not cdInfo.isOnGCD then
                onCooldown = true
            else
                local chargeInfo = C_Spell.GetSpellCharges(spellID)
                if chargeInfo and chargeInfo.isActive then
                    onCooldown = true
                end
            end
            
            -- wasCoolingDown tracks ACTUAL cooldown state only (not suppression)
            local wasCoolingDown = addon.cdStates[spellID]
            local isReady = not onCooldown
            
            if suppressed then
                -- While suppressed, hide any active glows but don't touch state
                for _, btn in ipairs(buttons) do
                    addon.HideGlow(btn)
                    addon.CancelButtonTimer(btn)
                end
            else
                for _, btn in ipairs(buttons) do
                    if isReady and wasCoolingDown then
                        local info = C_Spell.GetSpellInfo(spellID)
                        addon.Print("Spell READY: %s (ID: %d) on %s", info and info.name or "Unknown", spellID, btn:GetName() or tostring(btn))
                    end
                    addon.ApplyGlowTransition(btn, isReady, wasCoolingDown, duration, colorKey)
                end
            end
            
            -- Always track the REAL cooldown state, independent of suppression
            addon.cdStates[spellID] = onCooldown
        end
    end
end

function addon.CheckItemCooldowns()
    if not addon.Profile or not addon.Profile.items then return end
    local suppressed = addon.IsCombatOnly()
    
    for itemID, entry in pairs(addon.Profile.items) do
        local glowDuration = addon.GetEntryDuration(entry)
        local colorKey = addon.GetEntryColor(entry)
        local buttons = addon.FindButtonsByItemID(itemID)
        
        local start, dur, enable = C_Item.GetItemCooldown(itemID)
        local onCooldown = (start > 0 and dur > 0)
        
        local wasCoolingDown = addon.itemCdStates[itemID]
        local isReady = not onCooldown
        
        if suppressed then
            for _, btn in ipairs(buttons) do
                addon.HideGlow(btn)
                addon.CancelButtonTimer(btn)
            end
        else
            for _, btn in ipairs(buttons) do
                if isReady and wasCoolingDown then
                    local name = C_Item.GetItemInfo(itemID)
                    addon.Print("Item READY: %s (ID: %d)", name or "Unknown", itemID)
                end
                addon.ApplyGlowTransition(btn, isReady, wasCoolingDown, glowDuration, colorKey)
            end
        end
        
        addon.itemCdStates[itemID] = onCooldown
    end
end
