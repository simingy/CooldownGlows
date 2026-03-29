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
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    if IsSpellKnown and IsSpellKnown(spellID, true) then return true end
    if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then return true end
    return false
end

function addon.CheckCooldowns()
    if not addon.Profile or not addon.Profile.spells then return end
    local suppressed = addon.IsCombatOnly()
    
    for spellID, entry in pairs(addon.Profile.spells) do
        local btn = entry.button and _G[entry.button] or nil
        
        if not addon.trackableSpellsCache[spellID] then
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
            else
                local chargeInfo = C_Spell.GetSpellCharges(spellID)
                if chargeInfo and chargeInfo.isActive then
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
        local btn = entry.button and _G[entry.button] or nil
        
        local start, dur, enable = C_Item.GetItemCooldown(itemID)
        local onCooldown = (start and start > 0 and dur and dur > 1.5)
        
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
