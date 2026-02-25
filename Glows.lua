local addonName, addon = ...
local LCG = LibStub("LibCustomGlow-1.0")

addon.CDSTATES_KEY = "CooldownGlows"
addon.activeTimers = {}

-- ═══ Color Palette ═══
addon.GLOW_COLORS = {
    { name = "Default",  key = "default",  color = nil },
    { name = "White",    key = "white",    color = {1, 1, 1, 1} },
    { name = "Red",      key = "red",      color = {1, 0.2, 0.2, 1} },
    { name = "Green",    key = "green",    color = {0.2, 1, 0.2, 1} },
    { name = "Blue",     key = "blue",     color = {0.3, 0.5, 1, 1} },
    { name = "Yellow",   key = "yellow",   color = {1, 1, 0.2, 1} },
    { name = "Orange",   key = "orange",   color = {1, 0.5, 0.1, 1} },
    { name = "Purple",   key = "purple",   color = {0.6, 0.3, 1, 1} },
    { name = "Pink",     key = "pink",     color = {1, 0.4, 0.7, 1} },
    { name = "Cyan",     key = "cyan",     color = {0.2, 0.9, 1, 1} },
}

-- Lookup by key
addon.GLOW_COLOR_MAP = {}
for _, entry in ipairs(addon.GLOW_COLORS) do
    addon.GLOW_COLOR_MAP[entry.key] = entry
end

local function ResolveColor(colorKey)
    local entry = addon.GLOW_COLOR_MAP[colorKey or "default"]
    return entry and entry.color or nil
end

-- ═══ Glow API ═══

function addon.ShowGlow(button, colorKey)
    if not LCG or not LCG.ProcGlow_Start then return end
    local opts = { startAnim = true, key = addon.CDSTATES_KEY }
    opts.color = ResolveColor(colorKey)
    LCG.ProcGlow_Start(button, opts)
end

function addon.HideGlow(button)
    if not LCG or not LCG.ProcGlow_Stop then return end
    LCG.ProcGlow_Stop(button, addon.CDSTATES_KEY)
end

function addon.CancelButtonTimer(button)
    if addon.activeTimers[button] then
        addon.activeTimers[button]:Cancel()
        addon.activeTimers[button] = nil
    end
end

-- Shared glow logic: apply glow on transition to ready
function addon.ApplyGlowTransition(btn, isReady, wasCoolingDown, duration, colorKey)
    if isReady then
        -- Trigger glow when transitioning from "on cooldown" to "ready"
        if wasCoolingDown then
            if not btn["_ProcGlow" .. addon.CDSTATES_KEY] then
                addon.ShowGlow(btn, colorKey)
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
        -- Force hide immediately if the spell goes back on cooldown (it was cast)
        addon.HideGlow(btn)
        addon.CancelButtonTimer(btn)
    end
end



-- ═══ Profile Data Helpers ═══
-- Profile entries are {duration=N, color="key"} tables

function addon.GetEntryDuration(entry)
    if type(entry) == "number" then return entry end
    if type(entry) == "table" then return entry.duration or 3 end
    return 3
end

function addon.GetEntryColor(entry)
    if type(entry) == "table" then return entry.color or "default" end
    return "default"
end
