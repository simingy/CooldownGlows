local addonName, addon = ...
addon.events = CreateFrame("Frame")

CooldownGlowsDB = CooldownGlowsDB or {}

-- Core variables
addon.Class = select(2, UnitClass("player"))
addon.Profile = nil

local defaults = {
    spells = {}, -- spellID -> duration
    combatOnly = false
}

local cdTimer
local cacheUpdateFrame = CreateFrame("Frame")
local cacheTimer = 0
addon.spellCacheDirty = true

cacheUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    if addon.spellCacheDirty then
        cacheTimer = cacheTimer + elapsed
        if cacheTimer >= 0.5 then
            addon.spellButtonCache = {}
            addon.spellCacheDirty = false
            cacheTimer = 0
            if addon.Profile then
                addon.UpdateKnownSpells()
                addon.CheckCooldowns()
            end
        end
    end
end)

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            CooldownGlowsDB = CooldownGlowsDB or {}
            
            -- Simple migration from old CDglowDB if present
            if CDglowDB and not next(CooldownGlowsDB) then
                CooldownGlowsDB = CopyTable(CDglowDB)
            end

            if not CooldownGlowsDB[addon.Class] then
                CooldownGlowsDB[addon.Class] = CopyTable(defaults)
            end
            addon.Profile = CooldownGlowsDB[addon.Class]
            
            if addon.CreateOptionsFrames then
                addon.CreateOptionsFrames()
            end
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if cdTimer then cdTimer:Cancel() end
        cdTimer = C_Timer.NewTimer(0.1, addon.CheckCooldowns)
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        addon.UpdateKnownSpells()
        addon.spellCacheDirty = true
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_OVERRIDE_ACTIONBAR" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_VEHICLE_ACTIONBAR" then
        addon.spellCacheDirty = true
        cacheTimer = 0 -- extend throttling
        if event == "PLAYER_ENTERING_WORLD" then
            addon.UpdateKnownSpells()
            addon.CheckCooldowns()
        end
    end
end

addon.events:RegisterEvent("ADDON_LOADED")
addon.events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
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
    if Settings and Settings.OpenToCategory and addon.category then
        Settings.OpenToCategory(addon.category:GetID())
    else
        InterfaceOptionsFrame_OpenToCategory("CooldownGlows")
        InterfaceOptionsFrame_OpenToCategory("CooldownGlows")
    end
end
