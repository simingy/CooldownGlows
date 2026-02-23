local addonName, addon = ...

addon.knownSpells = {}
addon.cdStates = {}

function addon.UpdateKnownSpells()
    if not addon.Profile then return end
    addon.knownSpells = {}
    
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
    if not addon.Profile then return end
    local suppressed = addon.IsCombatOnly()
    
    for spellID, duration in pairs(addon.Profile.spells) do
        if addon.knownSpells[spellID] then
            local buttons = addon.FindButtonsBySpellID(spellID)
            local cdInfo = C_Spell.GetSpellCooldown(spellID)
            
            local anyButtonOnCooldown = false
            for _, btn in ipairs(buttons) do
                local btnOnCooldown = false
                if btn.cooldown and btn.cooldown:IsShown() then
                    btnOnCooldown = cdInfo and not cdInfo.isOnGCD
                end

                if btnOnCooldown then
                    anyButtonOnCooldown = true
                    break
                end
            end
            
            for _, btn in ipairs(buttons) do
                local shouldGlow = not suppressed and C_Spell.IsSpellUsable(spellID) and not anyButtonOnCooldown

                if shouldGlow then
                    if addon.cdStates[spellID] == true then
                        if not btn["_ProcGlow" .. addon.CDSTATES_KEY] then
                            addon.ShowGlow(btn)
                            addon.CancelButtonTimer(btn)
                            if duration > 0 then
                                addon.activeTimers[btn] = C_Timer.After(duration, function() 
                                    addon.HideGlow(btn) 
                                    addon.activeTimers[btn] = nil
                                end)
                            end
                        end
                    end
                else
                    addon.HideGlow(btn)
                    addon.CancelButtonTimer(btn)
                end
            end
            
            addon.cdStates[spellID] = anyButtonOnCooldown
        end
    end
end
