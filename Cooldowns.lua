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
            local targetCharges = addon.GetEntryCharges(entry)
            
            local buttons = addon.FindButtonsBySpellID(spellID)
            local cdInfo = C_Spell.GetSpellCooldown(spellID)
            local currentCharges = C_Spell.GetSpellCastCount(spellID) or 0
            
            local onCooldown = false
            
            for _, btn in ipairs(buttons) do
                local onRegularCD = btn.cooldown and btn.cooldown:IsShown()
                local isCoolingDownRegular = onRegularCD and cdInfo and not cdInfo.isOnGCD
                
                if targetCharges > 0 then
                    -- Custom charge threshold: Ignore GCD and short cooldowns entirely.
                    -- Rely strictly on the explicit cast count API.
                    if currentCharges < targetCharges then
                        onCooldown = true
                        break
                    end
                else
                    -- Default (max charges check): Check regular non-GCD cooldowns,
                    -- then conditionally check if chargeCooldown is running.
                    local onChargeCD = btn.chargeCooldown and btn.chargeCooldown:IsShown()
                    
                    if isCoolingDownRegular then
                        onCooldown = true
                        break
                    elseif onChargeCD then
                        -- chargeCooldown doesn't trigger for GCD, so it's safe to check standalone
                        onCooldown = true
                        break
                    end
                end
            end
            
            local shouldGlow = not suppressed and C_Spell.IsSpellUsable(spellID) and not onCooldown
            for _, btn in ipairs(buttons) do
                addon.ApplyGlowTransition(btn, shouldGlow, addon.cdStates[spellID], duration, colorKey)
            end
            
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
        
        local hasItem = C_Item.GetItemCount(itemID) > 0
        local isUsable = hasItem and C_Item.IsUsableItem(itemID)
        local shouldGlow = not suppressed and isUsable and not onCooldown
        
        for _, btn in ipairs(buttons) do
            addon.ApplyGlowTransition(btn, shouldGlow, addon.itemCdStates[itemID], duration, colorKey)
        end
        
        addon.itemCdStates[itemID] = onCooldown
    end
end
