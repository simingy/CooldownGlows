local addonName, addon = ...

local BUTTON_PREFIXES = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", 
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", 
    "MultiBar6Button", "MultiBar7Button", "MultiBar8Button"
}
local MAX_ACTION_SLOT = 180

-- Map action slot → buttons, deduplicating via seen set
local function FindButtonsForSlot(slot)
    local result = {}
    local seen = {}
    
    -- Primary source: Blizzard's ActionBarButtonEventsFrame
    if ActionBarButtonEventsFrame and type(ActionBarButtonEventsFrame.frames) == "table" then
        for _, button in pairs(ActionBarButtonEventsFrame.frames) do
            if type(button) == "table" then
                local act = button._state_action or button.action
                if act == slot and not seen[button] then
                    seen[button] = true
                    result[#result + 1] = button
                end
            end
        end
    end
    
    -- Fallback: scan known bar prefixes (catches addon bars)
    for _, prefix in ipairs(BUTTON_PREFIXES) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if type(button) == "table" then
                local act = button._state_action or button.action
                if act == slot and not seen[button] then
                    seen[button] = true
                    result[#result + 1] = button
                end
            end
        end
    end
    
    return result
end

-- ═══ Spell Buttons ═══

function addon.FindButtonsBySpellID(spellID)
    local result = {}
    local seen = {}
    
    -- Track both the base spell ID and its dynamic talent override (if one exists)
    local allSlots = {}
    local baseSlots = C_ActionBar.FindSpellActionButtons(spellID)
    if baseSlots then
        for _, s in ipairs(baseSlots) do
            allSlots[#allSlots + 1] = s
        end
    end
    
    local overrideID = C_Spell.GetOverrideSpell(spellID)
    if overrideID and overrideID ~= spellID then
        local overrideSlots = C_ActionBar.FindSpellActionButtons(overrideID)
        if overrideSlots then
            for _, s in ipairs(overrideSlots) do
                allSlots[#allSlots + 1] = s
            end
        end
    end
    
    for _, slot in ipairs(allSlots) do
        for _, btn in ipairs(FindButtonsForSlot(slot)) do
            if not seen[btn] then
                seen[btn] = true
                result[#result + 1] = btn
            end
        end
    end
    return result
end

-- ═══ Item Buttons ═══

function addon.FindButtonsByItemID(itemID)
    local result = {}
    local seen = {}
    for slot = 1, MAX_ACTION_SLOT do
        if HasAction(slot) then
            local actionType, id = GetActionInfo(slot)
            if actionType == "item" and id == itemID then
                for _, button in ipairs(FindButtonsForSlot(slot)) do
                    if not seen[button] then
                        seen[button] = true
                        result[#result + 1] = button
                    end
                end
            end
        end
    end
    return result
end

function addon.GetActionBarItems()
    local items = {}
    local seen = {}
    for slot = 1, MAX_ACTION_SLOT do
        if HasAction(slot) then
            local actionType, id = GetActionInfo(slot)
            if actionType == "item" and id and not seen[id] then
                seen[id] = true
                local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(id)
                if name then
                    items[#items + 1] = {
                        itemID = id,
                        name = name,
                        icon = icon or 134400
                    }
                end
            end
        end
    end
    table.sort(items, function(a, b) return a.name < b.name end)
    return items
end
