local addonName, addon = ...

addon.CDSTATES_KEY = "CooldownGlows"
addon.activeTimers = {}

-- ═ Color Palette (Shared with OptionsUI) ═
addon.GLOW_COLORS = {
    { name = "Default",  key = "default",  color = nil },
    { name = "White",    key = "white",    color = {1, 1, 1, 1} },
    { name = "Red",      key = "red",      color = {1, 0.2, 0.2, 1} },
    { name = "Green",    key = "green",    color = {0.2, 1, 0.2, 1} },
    { name = "Blue",     key = "blue",     color = {0.3, 0.6, 1, 1} },
    { name = "Yellow",   key = "yellow",   color = {1, 0.9, 0, 1} },
    { name = "Orange",   key = "orange",   color = {1, 0.5, 0.1, 1} },
    { name = "Purple",   key = "purple",   color = {0.8, 0.3, 1, 1} },
    { name = "Pink",     key = "pink",     color = {1, 0.4, 0.7, 1} },
    { name = "Cyan",     key = "cyan",     color = {0.2, 0.9, 1, 1} },
}

addon.GLOW_COLOR_MAP = {}
for _, entry in ipairs(addon.GLOW_COLORS) do
    addon.GLOW_COLOR_MAP[entry.key] = entry
end

local function ResolveColor(key)
    local entry = addon.GLOW_COLOR_MAP[key or "default"]
    return entry and entry.color or nil
end

-- ═ Entry Helpers (used by Cooldowns.lua, Core.lua, OptionsUI.lua) ═
function addon.GetEntryColor(entry)
    return entry and entry.color or "default"
end

function addon.GetEntryDuration(entry)
    return entry and entry.duration or 3
end

-- ═══════════════════════════════════════════════════════════════════
-- Self-Contained Proc Glow (Ported from LibCustomGlow-1.0 ProcGlow)
-- Zero dependencies. Uses the same Blizzard Flipbook atlases with
-- proper Desaturation + VertexColor for accurate custom colors.
-- ═══════════════════════════════════════════════════════════════════

local GlowParent = UIParent
local GLOW_KEY = "_CDGProcGlow"

-- Frame pool with proper cleanup
local function ProcGlowResetter(framePool, frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
    local parent = frame:GetParent()
    if parent and parent[GLOW_KEY] then
        parent[GLOW_KEY] = nil
    end
end

local ProcGlowPool = CreateFramePool("Frame", GlowParent, nil, ProcGlowResetter)

-- Build the glow frame with textures and animations (runs once per frame)
local function InitProcGlow(f)
    -- Start burst texture
    f.ProcStart = f:CreateTexture(nil, "ARTWORK")
    f.ProcStart:SetBlendMode("ADD")
    f.ProcStart:SetAtlas("UI-HUD-ActionBar-Proc-Start-Flipbook")
    f.ProcStart:SetAlpha(1)
    f.ProcStart:SetSize(150, 150)
    f.ProcStart:SetPoint("CENTER")

    -- Loop texture
    f.ProcLoop = f:CreateTexture(nil, "ARTWORK")
    f.ProcLoop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
    f.ProcLoop:SetAlpha(0)
    f.ProcLoop:SetAllPoints()

    -- Loop animation (repeating flipbook)
    f.ProcLoopAnim = f:CreateAnimationGroup()
    f.ProcLoopAnim:SetLooping("REPEAT")
    f.ProcLoopAnim:SetToFinalAlpha(true)

    local alphaRepeat = f.ProcLoopAnim:CreateAnimation("Alpha")
    alphaRepeat:SetChildKey("ProcLoop")
    alphaRepeat:SetFromAlpha(1)
    alphaRepeat:SetToAlpha(1)
    alphaRepeat:SetDuration(.001)
    alphaRepeat:SetOrder(0)

    local flipbookRepeat = f.ProcLoopAnim:CreateAnimation("FlipBook")
    flipbookRepeat:SetChildKey("ProcLoop")
    flipbookRepeat:SetDuration(1)
    flipbookRepeat:SetOrder(0)
    flipbookRepeat:SetFlipBookRows(6)
    flipbookRepeat:SetFlipBookColumns(5)
    flipbookRepeat:SetFlipBookFrames(30)
    flipbookRepeat:SetFlipBookFrameWidth(0)
    flipbookRepeat:SetFlipBookFrameHeight(0)
    f.ProcLoopAnim.flipbookRepeat = flipbookRepeat

    -- Start animation (one-shot flipbook burst, then transitions to loop)
    f.ProcStartAnim = f:CreateAnimationGroup()
    f.ProcStartAnim:SetToFinalAlpha(true)

    local flipbookStartAlphaIn = f.ProcStartAnim:CreateAnimation("Alpha")
    flipbookStartAlphaIn:SetChildKey("ProcStart")
    flipbookStartAlphaIn:SetDuration(.001)
    flipbookStartAlphaIn:SetOrder(0)
    flipbookStartAlphaIn:SetFromAlpha(1)
    flipbookStartAlphaIn:SetToAlpha(1)

    local flipbookStart = f.ProcStartAnim:CreateAnimation("FlipBook")
    flipbookStart:SetChildKey("ProcStart")
    flipbookStart:SetDuration(0.3)
    flipbookStart:SetOrder(1)
    flipbookStart:SetFlipBookRows(6)
    flipbookStart:SetFlipBookColumns(5)
    flipbookStart:SetFlipBookFrames(30)
    flipbookStart:SetFlipBookFrameWidth(0)
    flipbookStart:SetFlipBookFrameHeight(0)

    local flipbookStartAlphaOut = f.ProcStartAnim:CreateAnimation("Alpha")
    flipbookStartAlphaOut:SetChildKey("ProcStart")
    flipbookStartAlphaOut:SetDuration(.001)
    flipbookStartAlphaOut:SetOrder(2)
    flipbookStartAlphaOut:SetFromAlpha(1)
    flipbookStartAlphaOut:SetToAlpha(0)

    f.ProcStartAnim:SetScript("OnFinished", function(self)
        self:GetParent().ProcLoopAnim:Play()
        self:GetParent().ProcLoop:Show()
    end)
end

-- Configure color and animation state on an existing glow frame
local function SetupProcGlow(f, color)
    f:SetScript("OnHide", function(self)
        if self.ProcStartAnim:IsPlaying() then
            self.ProcStartAnim:Stop()
        end
        if self.ProcLoopAnim:IsPlaying() then
            self.ProcLoopAnim:Stop()
        end
    end)
    f:SetScript("OnShow", function(self)
        if not self.ProcStartAnim:IsPlaying() and not self.ProcLoopAnim:IsPlaying() then
            local width, height = self:GetSize()
            self.ProcStart:SetSize((width / 42 * 150) / 1.4, (height / 42 * 150) / 1.4)
            self.ProcStart:Show()
            self.ProcLoop:Hide()
            self.ProcStartAnim:Play()
        end
    end)

    -- Apply color: desaturate + vertex color for accurate tinting
    if not color then
        f.ProcStart:SetDesaturated(nil)
        f.ProcStart:SetVertexColor(1, 1, 1, 1)
        f.ProcLoop:SetDesaturated(nil)
        f.ProcLoop:SetVertexColor(1, 1, 1, 1)
    else
        f.ProcStart:SetDesaturated(1)
        f.ProcStart:SetVertexColor(color[1], color[2], color[3], color[4])
        f.ProcLoop:SetDesaturated(1)
        f.ProcLoop:SetVertexColor(color[1], color[2], color[3], color[4])
    end
end

-- ═ Public API ═

function addon.ShowGlow(button, colorKey)
    if not button then return end

    local color = ResolveColor(colorKey)
    local frameLevel = 8

    local f
    if button[GLOW_KEY] then
        -- Reuse existing glow frame
        f = button[GLOW_KEY]
    else
        -- Acquire from pool
        local new
        f, new = ProcGlowPool:Acquire()
        if new then
            InitProcGlow(f)
        end
        button[GLOW_KEY] = f
    end

    f:SetParent(button)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(button:GetFrameLevel() + 50)

    local width, height = button:GetSize()
    f:ClearAllPoints()
    f:SetSize(width * 1.4, height * 1.4)
    f:SetPoint("CENTER", button, "CENTER", 0, 0)

    SetupProcGlow(f, color)
    f:Show()
end

function addon.HideGlow(button)
    if not button then return end
    local f = button[GLOW_KEY]
    if f then
        ProcGlowPool:Release(f)
    end
end

function addon.CancelButtonTimer(button)
    if addon.activeTimers[button] then
        addon.activeTimers[button]:Cancel()
        addon.activeTimers[button] = nil
    end
end

-- ═ Shared Glow Transition Logic ═
function addon.ApplyGlowTransition(btn, isReady, wasCoolingDown, duration, colorKey)
    if isReady then
        if wasCoolingDown then
            if not btn["_CDGProcGlow"] or not btn["_CDGProcGlow"]:IsVisible() then
                addon.ShowGlow(btn, colorKey)
                addon.CancelButtonTimer(btn)

                if duration and duration > 0 then
                    addon.activeTimers[btn] = C_Timer.NewTimer(duration, function()
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
