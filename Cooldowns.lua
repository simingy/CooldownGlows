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
    if C_Spell.IsSpellDisplayable(spellID) then return true end
    
    -- Validity check for spells not in spellbook (e.g. items, toys, or seasonal spells)
    local info = C_Spell.GetSpellInfo(spellID)
    return (info and info.name ~= nil)
end

function addon.CheckCooldowns()
    if not addon.Profile or not addon.Profile.spells then return end
    local suppressed = addon.IsCombatOnly()
    
    -- Precise polling check for spells
    for spellID, entry in pairs(addon.Profile.spells) do
        local btn = entry.button and _G[entry.button] or nil
        
        local isTrackable = addon.trackableSpellsCache[spellID]
        if not isTrackable then
            if btn then
                addon.HideGlow(btn)
                addon.CancelButtonTimer(btn)
            end
            addon.cdStates[spellID] = nil
        else
            local duration = addon.GetEntryDuration(entry)
            local colorKey = addon.GetEntryColor(entry)
            
            local cdInfo = C_Spell.GetSpellCooldown(spellID)
            
            local onCooldown = false
            if cdInfo and cdInfo.isActive and not cdInfo.isOnGCD then
                onCooldown = true
            end

            -- Max Charges Only: Even if not on a primary cooldown (or just on GCD), 
            -- check if any charges are still recharging.
            if not onCooldown then
                local chargeInfo = C_Spell.GetSpellCharges(spellID)
                if chargeInfo and chargeInfo.isActive and chargeInfo.maxCharges > 1 then
                    onCooldown = true
                end
            end
            
            local wasCoolingDown = addon.cdStates[spellID]
            local isReady = not onCooldown
            
            if not addon.isTesting and btn then
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
    local suppressed = addon.IsCombatOnly()
    
    for itemID, entry in pairs(addon.Profile.items) do
        local glowDuration = addon.GetEntryDuration(entry)
        local colorKey = addon.GetEntryColor(entry)
        local btn = entry.button and _G[entry.button] or nil
        
        local start, dur, enable = C_Item.GetItemCooldown(itemID)
        
        -- Use pcall for magnitude comparisons as items return secret numbers in tainted contexts
        local onCooldown = false
        if start and dur then
            local success, result = pcall(function() return start > 0 and dur > 1.5 end)
            -- If secret or failed, assume on cooldown for safety
            onCooldown = (not success) or result
        end
        
        local wasCoolingDown = addon.itemCdStates[itemID]
        local isReady = not onCooldown
        
        if not addon.isTesting and btn then
            if suppressed then
                addon.HideGlow(btn)
                addon.CancelButtonTimer(btn)
            else
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
