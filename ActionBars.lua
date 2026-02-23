local addonName, addon = ...

local BUTTON_PREFIXES = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", 
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", 
    "MultiBar6Button", "MultiBar7Button", "MultiBar8Button"
}

addon.spellButtonCache = {}

local function GetButtonActionSlot(button)
    return button._state_action or button.action
end

local function FindButtonsForSlot(slot)
    local result = {}
    if ActionBarButtonEventsFrame and ActionBarButtonEventsFrame.frames then
        for _, button in pairs(ActionBarButtonEventsFrame.frames) do
            if GetButtonActionSlot(button) == slot then table.insert(result, button) end
        end
    end
    for _, prefix in ipairs(BUTTON_PREFIXES) do
        for i=1, 12 do
            local button = _G[prefix..i]
            if button and GetButtonActionSlot(button) == slot then table.insert(result, button) end
        end
    end
    return result
end

local function LookupSpellButtons(spellID)
    local result = {}
    if not addon.knownSpells[spellID] then return result end
    local slots = C_ActionBar.FindSpellActionButtons(spellID) or {}
    for _, slot in ipairs(slots) do
        local buttons = FindButtonsForSlot(slot)
        for _, b in ipairs(buttons) do table.insert(result, b) end
    end
    return result
end

function addon.FindButtonsBySpellID(spellID)
    if not addon.spellButtonCache[spellID] then
        addon.spellButtonCache[spellID] = LookupSpellButtons(spellID)
    end
    return addon.spellButtonCache[spellID]
end
