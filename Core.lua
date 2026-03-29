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
        self:SetScript("OnUpdate", nil)
        addon.cdCheckPending = false
        if addon.Profile then
            addon.CheckCooldowns()
            addon.CheckItemCooldowns()
        end
    end
end
local cacheUpdateFrame = CreateFrame("Frame")
local cacheTimer = 0
addon.spellCacheDirty = true

local function OnCacheUpdate(self, elapsed)
    cacheTimer = cacheTimer + elapsed
    if cacheTimer >= 0.5 then
        addon.spellButtonCache = {}
        addon.spellCacheDirty = false
        addon.cacheInvalidationPending = false
        cacheUpdateFrame:SetScript("OnUpdate", nil)
        if addon.Profile then
            addon.UpdateKnownSpells()
            addon.CheckCooldowns()
            addon.CheckItemCooldowns()
        end
    end
end

local lastInvalidation = 0
local INVALIDATION_THROTTLE = 10.0 -- At most one structural update per 10s during combat

function addon.InvalidateCaches()
    local now = GetTime()
    if InCombatLockdown() then
        if now - lastInvalidation < INVALIDATION_THROTTLE then
            addon.cacheInvalidationPending = true
            return
        end
        addon.Print("Cache rebuild (in-combat, throttled)")
    end

    lastInvalidation = now
    addon.cacheInvalidationPending = false
    addon.spellCacheDirty = true
    addon.itemCacheDirty = true
    cacheTimer = 0
    cacheUpdateFrame:SetScript("OnUpdate", OnCacheUpdate)
end

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
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" or event == "BAG_UPDATE_COOLDOWN" then
        -- Cooldown state changes: lightweight check, no cache rebuild
        if not addon.cdCheckPending then
            addon.cdCheckPending = true
            cdTimerAccum = 0
            cdUpdateFrame:SetScript("OnUpdate", CdOnUpdate)
        end
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        if not InCombatLockdown() then
            addon.UpdateKnownSpells()
        end
        addon.InvalidateCaches()
    elseif event == "ACTIONBAR_SLOT_CHANGED"
        or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_OVERRIDE_ACTIONBAR"
        or event == "UPDATE_VEHICLE_ACTIONBAR" then
        addon.InvalidateCaches()
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon.UpdateKnownSpells()
        addon.InvalidateCaches()
        addon.CheckCooldowns()
        addon.CheckItemCooldowns()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended: flush any pending structural updates
        if addon.cacheInvalidationPending then
            addon.Print("Combat ended. Flushing pending cache update.")
            addon.UpdateKnownSpells()
            addon.InvalidateCaches()
        end
        if addon.pendingOpenSettings then
            addon.pendingOpenSettings = nil
            Settings.OpenToCategory(addon.category:GetID())
        end
    end
end

addon.events:RegisterEvent("ADDON_LOADED")
addon.events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon.events:RegisterEvent("SPELL_UPDATE_CHARGES")
addon.events:RegisterEvent("BAG_UPDATE_COOLDOWN")
addon.events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
addon.events:RegisterEvent("PLAYER_ENTERING_WORLD")
addon.events:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
addon.events:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
addon.events:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
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
        
        for id, entry in pairs(addon.Profile.spells) do
            local buttons = addon.FindButtonsBySpellID(id)
            local colorKey = addon.GetEntryColor(entry)
            local duration = addon.GetEntryDuration(entry)
            for _, btn in ipairs(buttons or {}) do
                -- Use ApplyGlowTransition to trigger the full logic (glow + timer)
                addon.ApplyGlowTransition(btn, true, true, duration, colorKey)
            end
        end
        for id, entry in pairs(addon.Profile.items) do
            local buttons = addon.FindButtonsByItemID(id)
            local colorKey = addon.GetEntryColor(entry)
            local duration = addon.GetEntryDuration(entry)
            for _, btn in ipairs(buttons or {}) do
                addon.ApplyGlowTransition(btn, true, true, duration, colorKey)
            end
        end
        print("  Test complete. Glows will fade based on individual spell durations or casting.")
        return
    end

    if msg == "cache" then
        print("|cff00cc00CooldownGlows Cache:|r")
        if not addon.Profile then print("  Profile not loaded.") return end
        
        print("  Tracked Spells:")
        for id, _ in pairs(addon.Profile.spells) do
            local name = C_Spell.GetSpellInfo(id) and C_Spell.GetSpellInfo(id).name or "Unknown"
            local buttons = addon.FindButtonsBySpellID(id)
            local btnNames = {}
            for _, b in ipairs(buttons or {}) do table.insert(btnNames, b:GetName() or tostring(b)) end
            print(string.format("    - %s (%d): %s", name, id, #btnNames > 0 and table.concat(btnNames, ", ") or "|cffff3333None|r"))
        end
        
        print("  Tracked Items:")
        for id, _ in pairs(addon.Profile.items) do
            local name = C_Item.GetItemInfo(id) or "Unknown"
            local buttons = addon.FindButtonsByItemID(id)
            local btnNames = {}
            for _, b in ipairs(buttons or {}) do table.insert(btnNames, b:GetName() or tostring(b)) end
            print(string.format("    - %s (%d): %s", name, id, #btnNames > 0 and table.concat(btnNames, ", ") or "|cffff3333None|r"))
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
