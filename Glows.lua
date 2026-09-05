local addonName, addon = ...

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
    if frame.ProcStartAnim then frame.ProcStartAnim:Stop() end
    if frame.ProcLoopAnim then frame.ProcLoopAnim:Stop() end
    if frame.ProcStart then frame.ProcStart:Hide() end
    if frame.ProcLoop then frame.ProcLoop:Hide() end
    frame:ClearAllPoints()
    local parent = frame:GetParent()
    if parent and parent[GLOW_KEY] then
        parent[GLOW_KEY] = nil
    end
    frame:SetParent(GlowParent)
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
    f.ProcLoop:SetAlpha(1)
    f.ProcLoop:SetAllPoints()

    -- Loop animation (repeating flipbook)
    f.ProcLoopAnim = f:CreateAnimationGroup()
    f.ProcLoopAnim:SetLooping("REPEAT")

    local flipbookRepeat = f.ProcLoopAnim:CreateAnimation("FlipBook")
    flipbookRepeat:SetTarget(f.ProcLoop)
    flipbookRepeat:SetDuration(1)
    flipbookRepeat:SetOrder(1)
    flipbookRepeat:SetFlipBookRows(6)
    flipbookRepeat:SetFlipBookColumns(5)
    flipbookRepeat:SetFlipBookFrames(30)
    flipbookRepeat:SetFlipBookFrameWidth(0)
    flipbookRepeat:SetFlipBookFrameHeight(0)
    f.ProcLoopAnim.flipbookRepeat = flipbookRepeat

    -- Start animation (one-shot flipbook burst, then transitions to loop)
    f.ProcStartAnim = f:CreateAnimationGroup()

    local flipbookStart = f.ProcStartAnim:CreateAnimation("FlipBook")
    flipbookStart:SetTarget(f.ProcStart)
    flipbookStart:SetDuration(0.3)
    flipbookStart:SetOrder(1)
    flipbookStart:SetFlipBookRows(6)
    flipbookStart:SetFlipBookColumns(5)
    flipbookStart:SetFlipBookFrames(30)
    flipbookStart:SetFlipBookFrameWidth(0)
    flipbookStart:SetFlipBookFrameHeight(0)

    f.ProcStartAnim:SetScript("OnFinished", function(self)
        local parent = self:GetParent()
        parent.ProcStart:Hide()
        parent.ProcLoop:SetAlpha(1)
        parent.ProcLoop:Show()
        parent.ProcLoopAnim:Play()
    end)

    function f:StartGlow()
        local width, height = self:GetSize()
        if not width or width <= 0 then width = 63 end
        if not height or height <= 0 then height = 63 end
        self.ProcStart:SetSize((width / 42 * 150) / 1.4, (height / 42 * 150) / 1.4)
        self.ProcStart:SetAlpha(1)
        self.ProcStart:Show()
        self.ProcLoop:Hide()
        self.ProcLoopAnim:Stop()
        self.ProcStartAnim:Stop()
        self.ProcStartAnim:Play()
    end

    f:SetScript("OnShow", f.StartGlow)
    f:SetScript("OnHide", function(self)
        self.ProcStartAnim:Stop()
        self.ProcLoopAnim:Stop()
        self.ProcStart:Hide()
        self.ProcLoop:Hide()
    end)
end

-- Configure color and animation state on an existing glow frame
local function SetupProcGlow(f, color)
    -- Apply color: desaturate + vertex color for accurate tinting
    if not color then
        f.ProcStart:SetDesaturated(false)
        f.ProcStart:SetVertexColor(1, 1, 1, 1)
        f.ProcLoop:SetDesaturated(false)
        f.ProcLoop:SetVertexColor(1, 1, 1, 1)
    else
        f.ProcStart:SetDesaturated(true)
        f.ProcStart:SetVertexColor(color[1], color[2], color[3], color[4])
        f.ProcLoop:SetDesaturated(true)
        f.ProcLoop:SetVertexColor(color[1], color[2], color[3], color[4])
    end
end

-- ═ Public API ═

function addon.ShowGlow(button, colorKey)
    if not button then return end

    local color = ResolveColor(colorKey)

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
    f:SetFrameLevel(button:GetFrameLevel() + 8)

    local width, height = button:GetSize()
    if not width or width <= 0 then width = 45 end
    if not height or height <= 0 then height = 45 end
    f:ClearAllPoints()
    f:SetSize(width * 1.4, height * 1.4)
    f:SetPoint("CENTER", button, "CENTER", 0, 0)

    SetupProcGlow(f, color)
    if f:IsShown() then
        f:StartGlow()
    else
        f:Show()
    end
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
            addon.CancelButtonTimer(btn)
            addon.ShowGlow(btn, colorKey)

            if duration and duration > 0 then
                addon.activeTimers[btn] = C_Timer.NewTimer(duration, function()
                    addon.HideGlow(btn)
                    addon.activeTimers[btn] = nil
                end)
            end
        end
    else
        addon.HideGlow(btn)
        addon.CancelButtonTimer(btn)
    end
end
