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
            for _, btn in ipairs(buttons) do
                local onRegularCD = btn.cooldown and btn.cooldown:IsShown()
                local isCoolingDownRegular = onRegularCD and cdInfo and not cdInfo.isOnGCD
                local onChargeCD = btn.chargeCooldown and btn.chargeCooldown:IsShown()
                
                if isCoolingDownRegular or onChargeCD then
                    onCooldown = true
                    break
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
        local duration = addon.GetEntryDuration(entry)
        local colorKey = addon.GetEntryColor(entry)
        local buttons = addon.FindButtonsByItemID(itemID)
        
        local onCooldown = false
        for _, btn in ipairs(buttons) do
            if btn.cooldown and btn.cooldown:IsShown() then
                onCooldown = true
                break
            end
        end
        
        local wasCoolingDown = addon.itemCdStates[itemID]
        local isReady = not onCooldown
        
        if suppressed then
            for _, btn in ipairs(buttons) do
                addon.HideGlow(btn)
                addon.CancelButtonTimer(btn)
            end
        else
            for _, btn in ipairs(buttons) do
                addon.ApplyGlowTransition(btn, isReady, wasCoolingDown, duration, colorKey)
            end
        end
        
        addon.itemCdStates[itemID] = onCooldown
    end
end



