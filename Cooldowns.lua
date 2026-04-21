local addonName, addon = ...

addon.cdStates = {}
addon.itemCdStates = {}
addon.trackableSpellsCache = {}

function addon.UpdateTrackableSpells()
    if not addon.Profile or not addon.Profile.spells then return end
    wipe(addon.trackableSpellsCache)
    for spellID in pairs(addon.Profile.spells) do
        local trackable = addon.IsSpellTrackable(spellID)
        local chargeInfo = C_Spell.GetSpellCharges(spellID)
        local hasCharges = (chargeInfo ~= nil and chargeInfo.maxCharges > 1)
        addon.trackableSpellsCache[spellID] = { trackable = trackable, hasCharges = hasCharges }
    end
end


function addon.IsCombatOnly()
    return addon.Profile and addon.Profile.combatOnly and not UnitAffectingCombat("player")
end

function addon.IsSpellTrackable(spellID)
    if not spellID then return false end
    -- Broad check for 12.0.5
    if C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) then return true end
    if C_Spell.IsSpellDisplayable and C_Spell.IsSpellDisplayable(spellID) then return true end
    
    -- Fallbacks
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    if IsSpellKnown and IsSpellKnown(spellID) then return true end
    if GetSpellInfo(spellID) then return true end -- Ultimate fallback
    return false
end

function addon.CheckCooldowns()
    if not addon.Profile or not addon.Profile.spells then return end
    local suppressed = addon.IsCombatOnly()
    
    for spellID, entry in pairs(addon.Profile.spells) do
        local btn = entry.button and _G[entry.button] or nil
        
        local cache = addon.trackableSpellsCache[spellID]
        if not cache or not cache.trackable then
            if btn then
                addon.HideGlow(btn)
                addon.CancelButtonTimer(btn)
            end
            addon.cdStates[spellID] = nil
        else
            local duration = addon.GetEntryDuration(entry)
            local colorKey = addon.GetEntryColor(entry)
            
            local cdInfo = C_Spell.GetSpellCooldown(spellID)
            local gcdInfo = C_Spell.GetSpellCooldown(61304) or { startTime = 0, duration = 0, isActive = false }
            
            local onCooldown = false
            if cdInfo and cdInfo.isActive then
                -- Compare with GCD. Interrupts like Mind Freeze should usually have duration 0 for GCD
                local isOnGCD = gcdInfo.isActive and (cdInfo.startTime > 0) and (cdInfo.startTime == gcdInfo.startTime) and (cdInfo.duration == gcdInfo.duration)
                if not isOnGCD then
                    onCooldown = true
                end
            elseif cache.hasCharges then
                -- ONLY check charges if we know the spell actually has them
                local chargeInfo = C_Spell.GetSpellCharges(spellID)
                if chargeInfo and chargeInfo.isActive and chargeInfo.maxCharges > 0 then
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
