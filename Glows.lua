local addonName, addon = ...
local LCG = LibStub("LibCustomGlow-1.0")

addon.CDSTATES_KEY = "CooldownGlows"
addon.activeTimers = {}

function addon.ShowGlow(button)
    if not LCG or not LCG.ProcGlow_Start then return end
    LCG.ProcGlow_Start(button, {startAnim = true, key = addon.CDSTATES_KEY})
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
