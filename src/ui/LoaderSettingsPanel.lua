-- =========================================================
-- FS25 Loader Control Overlay - Settings Panel
-- =========================================================
-- Fully custom-drawn settings panel, same approach as the
-- FS25_SoilFertilizer SoilSettingsPanel. No XML, pure overlay.
-- Open/close with Alt+O (or the loaderControlSettings command).
--
-- Single page, grouped into sections, with toggle / multi /
-- stepper controls. All settings are client-local, so there is
-- no admin gating: any change just saves to the player profile.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOSettingsPanel
LCOSettingsPanel = {}
local LCOSettingsPanel_mt = Class(LCOSettingsPanel)

-- i18n with English fallback (matches SoilSettingsPanel:tr)
local function tr(key, fallback)
    if g_i18n and g_i18n.hasText and g_i18n:hasText(key) then
        local ok, text = pcall(function() return g_i18n:getText(key) end)
        if ok and text and text ~= "" then return text end
    end
    return fallback or key
end

-- ── Panel geometry (normalized, Y=0 at bottom) ───────────
local PW    = 0.44
local PH    = 0.68
local PX    = (1 - PW) / 2
local PY    = (1 - PH) / 2

local TB_H  = 0.050
local IB_H  = 0.040
local PAD   = 0.020

local ROW_H     = 0.042
local SEC_H     = 0.028
local TOGGLE_W  = 0.050
local TOGGLE_H  = 0.028
local TOGGLE_GAP = 0.004
local MULTI_W   = 0.190
local ARROW_W   = 0.024

local TS_TITLE = 0.020
local TS_BODY  = 0.0150
local TS_SMALL = 0.0130
local TS_TINY  = 0.0110

local C = {
    bg        = { 0.05, 0.06, 0.09, 0.97 },
    title_bg  = { 0.07, 0.09, 0.13, 1.0 },
    info_bg   = { 0.04, 0.05, 0.08, 1.0 },
    border    = { 0.30, 0.55, 0.95, 0.45 },
    shadow    = { 0.00, 0.00, 0.00, 0.45 },
    divider   = { 0.20, 0.22, 0.28, 0.55 },
    row_alt   = { 1.00, 1.00, 1.00, 0.025 },
    row_hover = { 0.30, 0.55, 0.95, 0.10 },
    accent    = { 0.35, 0.62, 1.00, 1.0 },
    white     = { 1.00, 1.00, 1.00, 1.0 },
    dim       = { 0.55, 0.56, 0.62, 1.0 },
    hint      = { 0.42, 0.44, 0.52, 1.0 },
    on_bg     = { 0.26, 0.58, 0.95, 1.0 },
    off_bg    = { 0.15, 0.16, 0.20, 1.0 },
    on_text   = { 0.00, 0.00, 0.00, 1.0 },
    off_text  = { 0.50, 0.52, 0.58, 1.0 },
    sel_bg    = { 0.10, 0.11, 0.15, 0.90 },
    close_hi  = { 0.88, 0.25, 0.25, 0.85 },
}

-- ── Page layout (self-contained) ─────────────────────────
local POS_OPTS = { "lco_pos_1", "lco_pos_2", "lco_pos_3", "lco_pos_4", "lco_pos_5", "lco_pos_6" }
local POS_FALLBACK = { "Left", "Right", "Lower left", "Lower right", "Bottom center", "Custom" }
local SCHEME_OPTS = { "lco_scheme_auto", "lco_scheme_modern", "lco_scheme_classic", "lco_scheme_alt" }
local SCHEME_FALLBACK = { "Auto", "Modern", "Classic", "Paddle" }

local SECTIONS = {
    {
        header = "lco_sec_display", headerFallback = "Display",
        items = {
            { id = "enabled",          kind = "bool", label = "lco_set_enabled",          lf = "Overlay",             desc = "Show or hide the loader overlay" },
            { id = "showBrandLogo",    kind = "bool", label = "lco_set_showBrandLogo",    lf = "Brand badge",         desc = "Show the brand logo in the header" },
            { id = "showVehicleName",  kind = "bool", label = "lco_set_showVehicleName",  lf = "Vehicle name",        desc = "Show the vehicle name in the header" },
            { id = "showPositionFill", kind = "bool", label = "lco_set_showPositionFill", lf = "Position fill",       desc = "Show the actual arm and tool position" },
            { id = "showWhenNoLoader", kind = "bool", label = "lco_set_showWhenNoLoader", lf = "Show without loader", desc = "Keep the panel visible with no loader attached" },
            { id = "hideInMenu",       kind = "bool", label = "lco_set_hideInMenu",       lf = "Hide in menus",       desc = "Hide the overlay while a menu is open" },
        },
    },
    {
        header = "lco_sec_layout", headerFallback = "Layout",
        items = {
            { id = "schemeOverride", kind = "multi", label = "lco_set_schemeOverride", lf = "Control style", desc = "Force a style, or pick by brand automatically", opts = SCHEME_OPTS, optsFallback = SCHEME_FALLBACK, min = 0 },
            { id = "positionPreset", kind = "multi", label = "lco_set_positionPreset", lf = "Position",      desc = "Where the panel sits on screen",                opts = POS_OPTS,    optsFallback = POS_FALLBACK,    min = 1 },
            { id = "scale",          kind = "step",  label = "lco_set_scale",          lf = "Size",          desc = "Panel scale",                                   min = 0.60, max = 2.00, step = 0.10 },
        },
    },
    {
        header = "lco_sec_advanced", headerFallback = "Advanced",
        items = {
            { id = "debugMode", kind = "bool", label = "lco_set_debugMode", lf = "Debug logging", desc = "Verbose logging to the game log" },
        },
    },
}

-- ── Construction ─────────────────────────────────────────
function LCOSettingsPanel.new(settings)
    local self = setmetatable({}, LCOSettingsPanel_mt)
    self.settings   = settings
    self.isVisible  = false
    self.initialized = false
    self.fillOverlay = nil
    self.mouseX, self.mouseY = 0, 0
    self._clickRects = {}
    self.modVersion = ""
    local mod = g_modManager and g_modManager:getModByName("FS25_LoaderControlOverlay")
    if mod and mod.version then self.modVersion = "v" .. tostring(mod.version) end
    return self
end

function LCOSettingsPanel:initialize()
    if self.initialized then return end
    if createImageOverlay then
        self.fillOverlay = createImageOverlay("dataS/menu/base/graph_pixel.dds")
    end
    self.initialized = true
end

function LCOSettingsPanel:delete()
    if self.fillOverlay then delete(self.fillOverlay); self.fillOverlay = nil end
    self.initialized = false
end

-- ── Visibility ───────────────────────────────────────────
function LCOSettingsPanel:open()
    if not self.initialized then self:initialize() end
    self.isVisible = true
    self.savedCamRotX, self.savedCamRotY, self.savedCamRotZ = nil, nil, nil
    if getCamera and getRotation then
        local ok, cam = pcall(getCamera)
        if ok and cam and cam ~= 0 then
            local ok2, rx, ry, rz = pcall(getRotation, cam)
            if ok2 then self.savedCamRotX, self.savedCamRotY, self.savedCamRotZ = rx, ry, rz end
        end
    end
    if g_inputBinding and g_inputBinding.setShowMouseCursor then
        g_inputBinding:setShowMouseCursor(true, true)
    end
end

function LCOSettingsPanel:close()
    self.isVisible = false
    self.savedCamRotX = nil
    if g_inputBinding and g_inputBinding.setShowMouseCursor then
        g_inputBinding:setShowMouseCursor(false)
    end
    self.settings:save()
end

function LCOSettingsPanel:toggle()
    if self.isVisible then self:close() else self:open() end
end

function LCOSettingsPanel:isOpen()
    return self.isVisible
end

function LCOSettingsPanel:update()
    if not self.isVisible then return end
    if g_inputBinding and g_inputBinding.setShowMouseCursor then
        g_inputBinding:setShowMouseCursor(true, true)
    end
    if self.savedCamRotX ~= nil and getCamera and setRotation then
        local ok, cam = pcall(getCamera)
        if ok and cam and cam ~= 0 then
            pcall(setRotation, cam, self.savedCamRotX, self.savedCamRotY, self.savedCamRotZ)
        end
    end
    if g_gui and (g_gui:getIsGuiVisible() or g_gui:getIsDialogVisible()) then
        self:close()
    end
end

-- ── Apply a change ───────────────────────────────────────
function LCOSettingsPanel:requestChange(id, value)
    self.settings:set(id, value)
    local mgr = g_LoaderControlManager
    if mgr and mgr.hud then
        if id == "positionPreset" or id == "scale" then
            mgr.hud:applyLayoutFromSettings()
        end
    end
end

-- ── Draw primitives ──────────────────────────────────────
function LCOSettingsPanel:drawRect(x, y, w, h, col, alpha)
    if not self.fillOverlay then return end
    setOverlayColor(self.fillOverlay, col[1], col[2], col[3], alpha or col[4] or 1.0)
    renderOverlay(self.fillOverlay, x, y, w, h)
end

function LCOSettingsPanel:drawText(x, y, size, text, col, align, bold)
    setTextColor(col[1], col[2], col[3], col[4] or 1.0)
    setTextBold(bold == true)
    setTextAlignment(align or RenderText.ALIGN_LEFT)
    renderText(x, y, size, text)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
end

function LCOSettingsPanel:registerClick(id, x, y, w, h, data)
    table.insert(self._clickRects, { id = id, x = x, y = y, w = w, h = h, data = data })
end

function LCOSettingsPanel:hitTest(rx, ry, rw, rh, mx, my)
    return mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh
end

-- ── Controls ─────────────────────────────────────────────
function LCOSettingsPanel:drawToggle(rightX, y, id)
    local isOn = self.settings[id] == true
    local offX = rightX - TOGGLE_W * 2 - TOGGLE_GAP
    local onX  = rightX - TOGGLE_W

    self:drawRect(offX, y, TOGGLE_W, TOGGLE_H, (not isOn) and C.dim or C.off_bg, (not isOn) and 0.90 or 0.60)
    self:drawText(offX + TOGGLE_W * 0.5, y + TOGGLE_H * 0.24, TS_TINY, "OFF", (not isOn) and C.white or C.off_text, RenderText.ALIGN_CENTER, not isOn)

    self:drawRect(onX, y, TOGGLE_W, TOGGLE_H, isOn and C.on_bg or C.off_bg, isOn and 1.0 or 0.60)
    self:drawText(onX + TOGGLE_W * 0.5, y + TOGGLE_H * 0.24, TS_TINY, "ON", isOn and C.on_text or C.off_text, RenderText.ALIGN_CENTER, isOn)

    self:registerClick("set_" .. id, offX, y, TOGGLE_W, TOGGLE_H, { id = id, value = false })
    self:registerClick("set_" .. id .. "_on", onX, y, TOGGLE_W, TOGGLE_H, { id = id, value = true })
end

function LCOSettingsPanel:drawMulti(rightX, y, item)
    local id   = item.id
    local minV = item.min or 0
    local val  = self.settings[id] or minV
    local idx  = val - minV + 1
    local curKey = item.opts[idx] or item.opts[1]
    local curFb  = item.optsFallback[idx] or item.optsFallback[1] or "?"
    local current = tr(curKey, curFb)

    local labelW = MULTI_W - ARROW_W * 2
    local leftX  = rightX - MULTI_W
    local midX   = leftX + ARROW_W
    local rightBX = midX + labelW

    local lHover = self:hitTest(leftX, y, ARROW_W, TOGGLE_H, self.mouseX, self.mouseY)
    self:drawRect(leftX, y, ARROW_W, TOGGLE_H, C.off_bg)
    self:drawText(leftX + ARROW_W * 0.5, y + TOGGLE_H * 0.22, TS_TINY, "<", lHover and C.accent or C.dim, RenderText.ALIGN_CENTER, true)

    self:drawRect(midX, y, labelW, TOGGLE_H, C.sel_bg)
    self:drawText(midX + labelW * 0.5, y + TOGGLE_H * 0.22, TS_TINY, current, C.white, RenderText.ALIGN_CENTER, false)

    local rHover = self:hitTest(rightBX, y, ARROW_W, TOGGLE_H, self.mouseX, self.mouseY)
    self:drawRect(rightBX, y, ARROW_W, TOGGLE_H, C.off_bg)
    self:drawText(rightBX + ARROW_W * 0.5, y + TOGGLE_H * 0.22, TS_TINY, ">", rHover and C.accent or C.dim, RenderText.ALIGN_CENTER, true)

    self:registerClick("multi_" .. id .. "_p", leftX, y, ARROW_W, TOGGLE_H, { id = id, dir = -1, item = item })
    self:registerClick("multi_" .. id .. "_n", rightBX, y, ARROW_W, TOGGLE_H, { id = id, dir = 1, item = item })
end

function LCOSettingsPanel:drawStepper(rightX, y, item)
    local id  = item.id
    local val = self.settings[id] or item.min
    local labelW = MULTI_W - ARROW_W * 2
    local leftX  = rightX - MULTI_W
    local midX   = leftX + ARROW_W
    local rightBX = midX + labelW

    local lHover = self:hitTest(leftX, y, ARROW_W, TOGGLE_H, self.mouseX, self.mouseY)
    self:drawRect(leftX, y, ARROW_W, TOGGLE_H, C.off_bg)
    self:drawText(leftX + ARROW_W * 0.5, y + TOGGLE_H * 0.22, TS_TINY, "-", lHover and C.accent or C.dim, RenderText.ALIGN_CENTER, true)

    self:drawRect(midX, y, labelW, TOGGLE_H, C.sel_bg)
    self:drawText(midX + labelW * 0.5, y + TOGGLE_H * 0.22, TS_TINY, string.format("%.2f x", val), C.white, RenderText.ALIGN_CENTER, false)

    local rHover = self:hitTest(rightBX, y, ARROW_W, TOGGLE_H, self.mouseX, self.mouseY)
    self:drawRect(rightBX, y, ARROW_W, TOGGLE_H, C.off_bg)
    self:drawText(rightBX + ARROW_W * 0.5, y + TOGGLE_H * 0.22, TS_TINY, "+", rHover and C.accent or C.dim, RenderText.ALIGN_CENTER, true)

    self:registerClick("step_" .. id .. "_d", leftX, y, ARROW_W, TOGGLE_H, { id = id, dir = -1, item = item })
    self:registerClick("step_" .. id .. "_u", rightBX, y, ARROW_W, TOGGLE_H, { id = id, dir = 1, item = item })
end

-- ── Draw ─────────────────────────────────────────────────
function LCOSettingsPanel:draw()
    if not self.isVisible or not self.initialized or not g_currentMission then return end
    self._clickRects = {}

    -- dim + panel
    self:drawRect(0, 0, 1, 1, C.shadow, 0.40)
    self:drawRect(PX + 0.004, PY - 0.004, PW, PH, C.shadow, 0.55)
    self:drawRect(PX, PY, PW, PH, C.bg)
    local bw = 0.0015
    self:drawRect(PX, PY, PW, bw, C.border)
    self:drawRect(PX, PY + PH - bw, PW, bw, C.border)
    self:drawRect(PX, PY, bw, PH, C.border)
    self:drawRect(PX + PW - bw, PY, bw, PH, C.border)

    -- rows
    local x = PX + PAD
    local w = PW - PAD * 2
    local y = PY + PH - TB_H - 0.012
    local rowIdx = 0
    for _, sec in ipairs(SECTIONS) do
        y = y - SEC_H
        self:drawText(x, y + SEC_H * 0.30, TS_SMALL, tr(sec.header, sec.headerFallback), C.accent, RenderText.ALIGN_LEFT, true)
        self:drawRect(x, y, w, 0.0008, C.divider, 0.5)
        for _, item in ipairs(sec.items) do
            y = y - ROW_H
            rowIdx = rowIdx + 1
            self:drawRow(x, y, w, item, rowIdx)
        end
        y = y - 0.006
    end

    self:drawTitleBar()
    self:drawInfoBar()
end

function LCOSettingsPanel:drawRow(x, y, w, item, rowIdx)
    if rowIdx % 2 == 0 then self:drawRect(x, y, w, ROW_H, C.row_alt) end
    if self:hitTest(x, y, w, ROW_H, self.mouseX, self.mouseY) then
        self:drawRect(x, y, w, ROW_H, C.row_hover)
    end

    self:drawText(x + 0.006, y + ROW_H * 0.55, TS_BODY, tr(item.label, item.lf), C.white, RenderText.ALIGN_LEFT, true)
    self:drawText(x + 0.006, y + ROW_H * 0.16, TS_TINY, tr("lco_desc_" .. item.id, item.desc), C.dim, RenderText.ALIGN_LEFT, false)

    local ctrlX = x + w - 0.010
    local ctrlY = y + (ROW_H - TOGGLE_H) / 2
    if item.kind == "bool" then
        self:drawToggle(ctrlX, ctrlY, item.id)
    elseif item.kind == "multi" then
        self:drawMulti(ctrlX, ctrlY, item)
    elseif item.kind == "step" then
        self:drawStepper(ctrlX, ctrlY, item)
    end

    self:drawRect(x, y, w, 0.0005, C.divider, 0.30)
end

function LCOSettingsPanel:drawTitleBar()
    local ty = PY + PH - TB_H
    self:drawRect(PX, ty, PW, TB_H, C.title_bg)
    self:drawRect(PX, ty, 0.003, TB_H, C.accent)
    local title = tr("lco_title", "Loader Control") .. "  " .. tr("lco_settings", "Settings")
    self:drawText(PX + PAD, ty + TB_H * 0.32, TS_TITLE, title, C.white, RenderText.ALIGN_LEFT, true)
    if self.modVersion ~= "" then
        self:drawText(PX + PW - 0.058, ty + TB_H * 0.38, TS_TINY, self.modVersion, C.hint, RenderText.ALIGN_RIGHT, false)
    end

    -- close X
    local bs = 0.030
    local bx = PX + PW - bs - 0.006
    local by = ty + (TB_H - bs) / 2
    local hover = self:hitTest(bx, by, bs, bs, self.mouseX, self.mouseY)
    self:drawRect(bx, by, bs, bs, hover and C.close_hi or C.off_bg)
    self:drawText(bx + bs * 0.5, by + bs * 0.26, TS_BODY, "X", C.white, RenderText.ALIGN_CENTER, true)
    self:registerClick("close", bx, by, bs, bs, nil)
end

function LCOSettingsPanel:drawInfoBar()
    local by = PY
    self:drawRect(PX, by, PW, IB_H, C.info_bg)
    self:drawText(PX + PAD, by + IB_H * 0.34, TS_TINY,
        tr("lco_settings_hint", "Click outside or X to close   *   saved per player"),
        C.hint, RenderText.ALIGN_LEFT, false)
end

-- ── Mouse ────────────────────────────────────────────────
function LCOSettingsPanel:onMouseEvent(posX, posY, isDown, isUp, button)
    if not self.isVisible then return false end
    self.mouseX, self.mouseY = posX, posY
    if not isDown then return true end
    if button ~= Input.MOUSE_BUTTON_LEFT then return true end

    for _, r in ipairs(self._clickRects) do
        if self:hitTest(r.x, r.y, r.w, r.h, posX, posY) then
            self:handleClick(r.id, r.data)
            return true
        end
    end
    if not self:hitTest(PX, PY, PW, PH, posX, posY) then
        self:close()
    end
    return true
end

function LCOSettingsPanel:handleClick(id, data)
    if id == "close" then
        self:close()
        return
    end
    if not data then return end

    if id:sub(1, 4) == "set_" then
        self:requestChange(data.id, data.value)

    elseif id:sub(1, 6) == "multi_" then
        local item = data.item
        local minV = item.min or 0
        local maxV = minV + #item.opts - 1
        local cur  = self.settings[data.id] or minV
        local nxt  = cur + data.dir
        if nxt < minV then nxt = maxV elseif nxt > maxV then nxt = minV end
        self:requestChange(data.id, nxt)

    elseif id:sub(1, 5) == "step_" then
        local item = data.item
        local cur  = self.settings[data.id] or item.min
        local nxt  = cur + data.dir * item.step
        -- round to step to avoid float drift
        nxt = math.floor(nxt / item.step + 0.5) * item.step
        if nxt < item.min then nxt = item.min elseif nxt > item.max then nxt = item.max end
        self:requestChange(data.id, nxt)
    end
end

return LCOSettingsPanel
