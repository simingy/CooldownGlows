local addonName, addon = ...

addon.cdStates = {}
addon.itemCdStates = {}
addon.trackableSpellsCache = {}

function addon.UpdateTrackableSpells()
    if not addon.Profile or not addon.Profile.spells then return end
    wipe(addon.trackableSpellsCache)
    for spellID in pairs(addon.Profile.spells) do
        addon.trackableSpellsCache[spellID] = addon.IsSpellTrackable(spellID)
    end
end


function addon.IsCombatOnly()
    return addon.Profile and addon.Profile.combatOnly and not UnitAffectingCombat("player")
end

function addon.IsSpellTrackable(spellID)
    if not spellID then return false end
    
    -- WoW 12.0+ Primary Checks
    if C_SpellBook.IsSpellKnown(spellID) then return true end
    if C_SpellBook.IsSpellKnownOrOverridesKnown and C_SpellBook.IsSpellKnownOrOverridesKnown(spellID) then return true end

    local overrideID = C_Spell.GetOverrideSpell(spellID)
    if overrideID and overrideID ~= spellID and C_SpellBook.IsSpellKnown(overrideID) then
        return true
    end
    
    -- Pet spells or other abilities that might not be in the primary spellbook
    if C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) then return true end
    
    return false
end

function addon.CheckCooldowns()
    if not addon.Profile or not addon.Profile.spells then return end
    if addon.isTesting then return end
    local suppressed = addon.IsCombatOnly()
    
    -- Precise polling check for spells
    for spellID, entry in pairs(addon.Profile.spells) do
        local btn = entry.button and _G[entry.button] or nil
        
        local isTrackable = addon.trackableSpellsCache[spellID]
        if isTrackable == nil then
            isTrackable = addon.IsSpellTrackable(spellID)
            addon.trackableSpellsCache[spellID] = isTrackable
        end

        if not isTrackable then
            if btn then
                addon.HideGlow(btn)
                addon.CancelButtonTimer(btn)
            end
            addon.cdStates[spellID] = nil
        else
            local duration = addon.GetEntryDuration(entry)
            local colorKey = addon.GetEntryColor(entry)
            
            local effectiveSpellID = C_Spell.GetOverrideSpell(spellID) or spellID
            local cdInfo = C_Spell.GetSpellCooldown(effectiveSpellID)
            if (not cdInfo or not cdInfo.isActive) and effectiveSpellID ~= spellID then
                cdInfo = C_Spell.GetSpellCooldown(spellID)
            end
            
            local onCooldown = false
            if cdInfo and cdInfo.isActive and not cdInfo.isOnGCD then
                onCooldown = true
            end

            -- Max Charges Only: Even if not on a primary cooldown (or just on GCD), 
            -- check if any charges are still recharging.
            if not onCooldown then
                local chargeInfo = C_Spell.GetSpellCharges(effectiveSpellID)
                if (not chargeInfo or not chargeInfo.isActive) and effectiveSpellID ~= spellID then
                    chargeInfo = C_Spell.GetSpellCharges(spellID)
                end
                if chargeInfo and chargeInfo.isActive and chargeInfo.maxCharges and chargeInfo.maxCharges > 1 then
                    onCooldown = true
                end
            end
            
            local wasCoolingDown = addon.cdStates[spellID]
            local isReady = not onCooldown
            
            if btn then
                if suppressed then
                    addon.HideGlow(btn)
                    addon.CancelButtonTimer(btn)
                else
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
    if addon.isTesting then return end
    local suppressed = addon.IsCombatOnly()
    
    for itemID, entry in pairs(addon.Profile.items) do
        local glowDuration = addon.GetEntryDuration(entry)
        local colorKey = addon.GetEntryColor(entry)
        local btn = entry.button and _G[entry.button] or nil
        
        local onCooldown = false
        local act = btn and (btn._state_action or btn.action)
        if act and type(act) == "number" then
            -- Prefer C_ActionBar.GetActionCooldown: returns NeverSecret booleans isActive and isOnGCD
            local cdInfo = C_ActionBar.GetActionCooldown(act)
            if cdInfo and cdInfo.isActive and not cdInfo.isOnGCD then
                onCooldown = true
            end
        else
            local start, dur, enable = C_Item.GetItemCooldown(itemID)
            if enable then
                local success, result = pcall(function() return start > 0 and dur > 1.5 end)
                if success then
                    onCooldown = result
                else
                    onCooldown = true
                end
            end
        end
        
        local wasCoolingDown = addon.itemCdStates[itemID]
        local isReady = not onCooldown
        
        if btn then
            if suppressed then
                addon.HideGlow(btn)
                addon.CancelButtonTimer(btn)
            else
                addon.ApplyGlowTransition(btn, isReady, wasCoolingDown, glowDuration, colorKey)
            end
        end
        
        addon.itemCdStates[itemID] = onCooldown
    end
end
