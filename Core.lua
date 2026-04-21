local addonName, addon = ...
addon.events = CreateFrame("Frame")

-- Saved variable; initialized in ADDON_LOADED

-- Core variables
addon.CharKey = nil
addon.ProfileType = nil  -- "char" or "class"
addon.Profile = nil

function addon.Print(fmt, ...)
    if addon.Profile and addon.Profile.debug then
        print("|cff00cc00CDG Debug:|r " .. string.format(fmt, ...))
    end
end

local cdUpdateFrame = CreateFrame("Frame")
local cdTimerAccum = 0
local function CdOnUpdate(self, elapsed)
    cdTimerAccum = cdTimerAccum + elapsed
    if cdTimerAccum >= 0.05 then
        cdTimerAccum = 0
        if addon.Profile then
            addon.CheckCooldowns()
            addon.CheckItemCooldowns()
        end
    end
end
cdUpdateFrame:SetScript("OnUpdate", CdOnUpdate)

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            CooldownGlowsDB = CooldownGlowsDB or {}
            
            -- Simple migration from old CDglowDB if present
            if CDglowDB and not next(CooldownGlowsDB) then
                CooldownGlowsDB = CopyTable(CDglowDB)
            end
            
            addon.Class = select(2, UnitClass("player"))
            addon.CharKey = "char:" .. UnitName("player") .. "-" .. GetRealmName()
            
            -- Ensure class profile exists
            if not CooldownGlowsDB[addon.Class] then
                CooldownGlowsDB[addon.Class] = { spells = {}, items = {}, debug = false }
            end
            if not CooldownGlowsDB[addon.Class].items then
                CooldownGlowsDB[addon.Class].items = {}
            end
            
            -- Load profile (char-specific or class fallback)
            if CooldownGlowsDB[addon.CharKey] then
                if not CooldownGlowsDB[addon.CharKey].items then
                    CooldownGlowsDB[addon.CharKey].items = {}
                end
                addon.Profile = CooldownGlowsDB[addon.CharKey]
                addon.ProfileType = "char"
            else
                addon.Profile = CooldownGlowsDB[addon.Class]
                addon.ProfileType = "class"
            end
            
            if addon.CreateOptionsFrames then
                addon.CreateOptionsFrames()
            end
            
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        addon.UpdateTrackableSpells()
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon.UpdateTrackableSpells()
        addon.CheckCooldowns()
        addon.CheckItemCooldowns()
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.UpdateTrackableSpells()
        if addon.pendingOpenSettings then
            addon.pendingOpenSettings = nil
            Settings.OpenToCategory(addon.category:GetID())
        end
        addon.CheckCooldowns()
        addon.CheckItemCooldowns()
    end
end

addon.events:RegisterEvent("ADDON_LOADED")
addon.events:RegisterEvent("PLAYER_ENTERING_WORLD")
addon.events:RegisterEvent("SPELLS_CHANGED")
addon.events:RegisterEvent("PLAYER_TALENT_UPDATE")

addon.events:RegisterEvent("PLAYER_REGEN_ENABLED")

addon.events:SetScript("OnEvent", OnEvent)

-- Slash commands
SLASH_COOLDOWNGLOWS1 = "/cooldownglows"
SLASH_COOLDOWNGLOWS2 = "/cdg"
SlashCmdList["COOLDOWNGLOWS"] = function(msg)
    msg = msg:lower():trim()
    if msg == "test" then
        print("|cff00cc00CooldownGlows Test:|r Triggering all tracked glows...")
        if not addon.Profile then print("  Profile not loaded.") return end
        
        addon.isTesting = true
        local maxDur = 0
        
        local function triggerGlows(list)
            if not list then return end
            for id, entry in pairs(list) do
                local btn = entry.button and _G[entry.button]
                if btn then
                    local colorKey = addon.GetEntryColor(entry)
                    local duration = addon.GetEntryDuration(entry)
                    if duration > maxDur then maxDur = duration end
                    addon.ApplyGlowTransition(btn, true, true, duration, colorKey)
                end
            end
        end
        
        triggerGlows(addon.Profile.spells)
        triggerGlows(addon.Profile.items)
        
        if maxDur > 0 then
            C_Timer.After(maxDur + 0.5, function() addon.isTesting = false end)
        else
            addon.isTesting = false
        end
        
        print("  Test complete. Glows will fade based on individual spell/item durations.")
        return
    end

    if msg == "cache" then
        print("|cff00cc00CooldownGlows Static Map:|r")
        if not addon.Profile then print("  Profile not loaded.") return end
        
        print("  Tracked Spells:")
        for id, entry in pairs(addon.Profile.spells) do
            local name = C_Spell.GetSpellInfo(id) and C_Spell.GetSpellInfo(id).name or "Unknown"
            local btnName = entry.button or "|cffff3333None|r"
            print(string.format("    - %s (%d): %s", name, id, btnName))
        end
        
        print("  Tracked Items:")
        for id, entry in pairs(addon.Profile.items) do
            local name = C_Item.GetItemInfo(id) or "Unknown"
            local btnName = entry.button or "|cffff3333None|r"
            print(string.format("    - %s (%d): %s", name, id, btnName))
        end
        return
    end

    if msg == "" then
        if InCombatLockdown() then
            print("|cffccaa00CooldownGlows:|r Settings will open when you leave combat.")
            addon.events:RegisterEvent("PLAYER_REGEN_ENABLED")
            addon.pendingOpenSettings = true
            return
        end
        Settings.OpenToCategory(addon.category:GetID())
        return
    end

    print("|cffccaa00CooldownGlows Commands:|r")
    print("  /cdg - Open settings")
    print("  /cdg cache - View button-to-spell mappings")
    print("  /cdg test - Trigger glows on all tracked buttons")
end
