local addonName, addon = ...
addon.events = CreateFrame("Frame")

-- Saved variable; initialized in ADDON_LOADED

-- Core variables
addon.Class = select(2, UnitClass("player"))
addon.CharKey = nil
addon.ProfileType = nil  -- "char" or "class"
addon.Profile = nil

local defaults = {
    spells = {},
    items = {},
    combatOnly = false
}

local cdTimer
local cacheUpdateFrame = CreateFrame("Frame")
local cacheTimer = 0
addon.spellCacheDirty = true

local function OnCacheUpdate(self, elapsed)
    cacheTimer = cacheTimer + elapsed
    if cacheTimer >= 0.5 then
        addon.spellButtonCache = {}
        addon.spellCacheDirty = false
        cacheTimer = 0
        cacheUpdateFrame:SetScript("OnUpdate", nil)
        if addon.Profile then
            addon.UpdateKnownSpells()
            addon.CheckCooldowns()
            addon.CheckItemCooldowns()
        end
    end
end

function addon.InvalidateCaches()
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
            
            -- Migrate old number-format entries to table format
            for key, profile in pairs(CooldownGlowsDB) do
                if type(profile) == "table" then
                    for _, listKey in ipairs({"spells", "items"}) do
                        if profile[listKey] then
                            for id, val in pairs(profile[listKey]) do
                                if type(val) == "number" then
                                    profile[listKey][id] = { duration = val, color = "default" }
                                end
                            end
                        end
                    end
                end
            end

            -- Build character key
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            addon.CharKey = "char:" .. playerName .. "-" .. realmName
            
            -- Ensure class profile exists
            if not CooldownGlowsDB[addon.Class] then
                CooldownGlowsDB[addon.Class] = CopyTable(defaults)
            end
            if not CooldownGlowsDB[addon.Class].items then
                CooldownGlowsDB[addon.Class].items = {}
            end
            
            -- Resolve active profile: char > class
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
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
        if cdTimer then cdTimer:Cancel() end
        cdTimer = C_Timer.NewTimer(0.1, function()
            addon.CheckCooldowns()
            addon.CheckItemCooldowns()
        end)
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        addon.UpdateKnownSpells()
        addon.InvalidateCaches()
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "PLAYER_ENTERING_WORLD"
        or event == "UPDATE_OVERRIDE_ACTIONBAR" or event == "UPDATE_BONUS_ACTIONBAR"
        or event == "UPDATE_VEHICLE_ACTIONBAR" then
        addon.InvalidateCaches()
        if event == "PLAYER_ENTERING_WORLD" then
            addon.UpdateKnownSpells()
            addon.CheckCooldowns()
            addon.CheckItemCooldowns()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if addon.pendingOpenSettings then
            addon.pendingOpenSettings = nil
            if Settings and Settings.OpenToCategory and addon.category then
                Settings.OpenToCategory(addon.category:GetID())
            else
                InterfaceOptionsFrame_OpenToCategory("CooldownGlows")
                InterfaceOptionsFrame_OpenToCategory("CooldownGlows")
            end
        end
    end
end

addon.events:RegisterEvent("ADDON_LOADED")
addon.events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon.events:RegisterEvent("BAG_UPDATE_COOLDOWN")
addon.events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
addon.events:RegisterEvent("PLAYER_ENTERING_WORLD")
addon.events:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
addon.events:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
addon.events:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
addon.events:RegisterEvent("SPELLS_CHANGED")
addon.events:RegisterEvent("PLAYER_TALENT_UPDATE")

addon.events:SetScript("OnEvent", OnEvent)

-- Slash commands
SLASH_COOLDOWNGLOWS1 = "/cooldownglows"
SLASH_COOLDOWNGLOWS2 = "/cdg"
SlashCmdList["COOLDOWNGLOWS"] = function(msg)
    if InCombatLockdown() then
        print("|cffccaa00CooldownGlows:|r Settings will open when you leave combat.")
        addon.events:RegisterEvent("PLAYER_REGEN_ENABLED")
        addon.pendingOpenSettings = true
        return
    end
    if Settings and Settings.OpenToCategory and addon.category then
        Settings.OpenToCategory(addon.category:GetID())
    else
        InterfaceOptionsFrame_OpenToCategory("CooldownGlows")
        InterfaceOptionsFrame_OpenToCategory("CooldownGlows")
    end
end
