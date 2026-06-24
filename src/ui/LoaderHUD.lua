-- =========================================================
-- FS25 Loader Control Overlay - HUD
-- =========================================================
-- Renders the loader control overlay: a framed panel with a brand
-- badge header and a procedurally-drawn control widget (see
-- ControlScheme.lua) that animates with the live loader state.
--
-- Handles smoothing, position presets, drag/resize edit mode, and
-- per-client layout persistence.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOLoaderHUD
LCOLoaderHUD = {}
local LCOLoaderHUD_mt = Class(LCOLoaderHUD)

local C   = LCOConstants.COLORS
local HUD = LCOConstants.HUD

-- Exponential smoothing toward a target (dt in seconds).
local function approach(cur, target, rate, dt)
    local t = 1 - math.exp(-rate * dt)
    return cur + (target - cur) * t
end

function LCOLoaderHUD.new(settings)
    local self = setmetatable({}, LCOLoaderHUD_mt)
    self.settings    = settings
    self.initialized = false
    self.visible     = true                -- runtime toggle (Shift+L)
    self.editMode    = false
    self.alphaMul    = 0                    -- fade factor 0..1

    self.panelX, self.panelY = LCOConstants.POSITIONS[1].x, LCOConstants.POSITIONS[1].y
    self.scale   = 1.0

    -- smoothed channels
    self.sm = {
        arm  = { position = 0.5, command = 0 },
        tool = { position = 0.5, command = 0 },
        aux  = { position = 0.5, command = 0 },
    }

    -- supplied each frame by the manager
    self.state = nil

    -- brand logo overlay cache
    self.brandOverlay   = nil
    self._brandIconPath = nil

    -- edit-mode drag/resize
    self.dragging = false
    self.resizing = false
    self.dragOffX, self.dragOffY = 0, 0
    self.resizeStartDist, self.resizeStartScale = 0, 1

    return self
end

function LCOLoaderHUD:initialize()
    if self.initialized then return end
    if createImageOverlay ~= nil then
        self.pixel = createImageOverlay("dataS/menu/base/graph_pixel.dds")
    else
        LCOLogger.warning("createImageOverlay unavailable — HUD cannot draw")
    end
    self:applyLayoutFromSettings()
    self.initialized = true
    LCOLogger.info("HUD initialized at (%.3f, %.3f) scale %.2f", self.panelX, self.panelY, self.scale)
end

function LCOLoaderHUD:delete()
    if self.pixel then delete(self.pixel); self.pixel = nil end
    if self.brandOverlay then delete(self.brandOverlay); self.brandOverlay = nil end
    self.initialized = false
end

-- ── Layout ───────────────────────────────────────────────
function LCOLoaderHUD:applyLayoutFromSettings()
    local s = self.settings
    self.scale = s.scale or 1.0
    local preset = s.positionPreset or 1
    if preset == 6 then
        self.panelX = s.customX or LCOConstants.POSITIONS[1].x
        self.panelY = s.customY or LCOConstants.POSITIONS[1].y
    else
        local p = LCOConstants.POSITIONS[preset] or LCOConstants.POSITIONS[1]
        self.panelX, self.panelY = p.x, p.y
    end
end

function LCOLoaderHUD:getRect()
    local w = HUD.BASE_W * self.scale
    local h = HUD.BASE_H * self.scale
    return self.panelX, self.panelY, w, h
end

function LCOLoaderHUD:clamp()
    local _, _, w, h = self:getRect()
    self.panelX = math.max(0.0, math.min(1.0 - w, self.panelX))
    self.panelY = math.max(0.0, math.min(1.0 - h, self.panelY))
end

-- ── Draw primitives (consumed by ControlScheme) ──────────
function LCOLoaderHUD:rect(x, y, w, h, c, a)
    if not self.pixel then return end
    local alpha = (a or c[4] or 1.0) * self.alphaMul
    setOverlayColor(self.pixel, c[1], c[2], c[3], alpha)
    renderOverlay(self.pixel, x, y, w, h)
end

function LCOLoaderHUD:border(x, y, w, h, c, t)
    t = t or 0.0015
    self:rect(x, y, w, t, c)
    self:rect(x, y + h - t, w, t, c)
    self:rect(x, y, t, h, c)
    self:rect(x + w - t, y, t, h, c)
end

function LCOLoaderHUD:text(x, y, size, c, str, align, bold)
    if not str then return end
    setTextColor(c[1], c[2], c[3], (c[4] or 1.0) * self.alphaMul)
    setTextBold(bold == true)
    if align == "center" then
        setTextAlignment(RenderText.ALIGN_CENTER)
    elseif align == "right" then
        setTextAlignment(RenderText.ALIGN_RIGHT)
    else
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
    renderText(x, y, size, str)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
end

-- ── State feed + visibility ──────────────────────────────
function LCOLoaderHUD:setState(state)
    self.state = state
end

function LCOLoaderHUD:shouldShow()
    local s = self.settings
    if not s.enabled then return false end
    if not self.visible then return false end
    if s.hideInMenu and g_gui and (g_gui:getIsGuiVisible() or g_gui:getIsDialogVisible()) then
        if not self.editMode then return false end
    end
    local st = self.state
    local hasLoader = st and st.hasLoader
    if not hasLoader and not s.showWhenNoLoader and not self.editMode then
        return false
    end
    return true
end

function LCOLoaderHUD:toggleVisibility()
    self.visible = not self.visible
    return self.visible
end

-- ── Update (smoothing + fade) ────────────────────────────
function LCOLoaderHUD:update(dt)
    local dts = dt * 0.001
    local target = self:shouldShow() and 1 or 0
    self.alphaMul = approach(self.alphaMul, target, LCOConstants.TIMING.APPEAR_FADE, dts)

    local st = self.state
    if st and st.hasLoader then
        local T = LCOConstants.TIMING
        for _, key in ipairs({ "arm", "tool", "aux" }) do
            local src = st[key]
            local dst = self.sm[key]
            if src and src.present then
                dst.position = approach(dst.position, src.position or 0.5, T.POSITION_SMOOTH, dts)
                dst.command  = approach(dst.command,  src.command  or 0,   T.COMMAND_SMOOTH,  dts)
            else
                dst.command  = approach(dst.command, 0, T.COMMAND_DECAY, dts)
            end
        end
    end

    -- brand logo overlay refresh
    if st then
        local icon = st.brandIcon
        if icon ~= self._brandIconPath then
            if self.brandOverlay then delete(self.brandOverlay); self.brandOverlay = nil end
            if icon and icon ~= "" and createImageOverlay then
                local ok, ov = pcall(createImageOverlay, icon)
                if ok then self.brandOverlay = ov end
            end
            self._brandIconPath = icon
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────
function LCOLoaderHUD:draw()
    if not self.initialized or not self.pixel then return end
    if self.alphaMul <= 0.01 then return end

    local x, y, w, h = self:getRect()
    local pad = HUD.PAD * self.scale

    -- shadow + panel + border
    self:rect(x + 0.0015, y - 0.0015, w, h, C.SHADOW)
    self:rect(x, y, w, h, C.BG)
    self:border(x, y, w, h, C.BORDER, 0.0016)

    -- header
    local headH = HUD.HEADER_H * self.scale
    local headY = y + h - headH
    self:rect(x, headY, w, headH, C.HEADER_BG)

    local st = self.state
    local schemeId = (st and st.scheme) or LCOConstants.DEFAULT_SCHEME
    local scheme   = LCOConstants.SCHEMES[schemeId] or LCOConstants.SCHEMES.modern
    -- accent strip on the left edge of the header
    self:rect(x, headY, 0.0022, headH, scheme.accent)

    local textY = headY + headH * 0.30
    local tx = x + pad
    -- brand badge
    if self.settings.showBrandLogo and self.brandOverlay then
        local badge = headH * 0.72
        setOverlayColor(self.brandOverlay, 1, 1, 1, self.alphaMul)
        renderOverlay(self.brandOverlay, x + pad, headY + (headH - badge) * 0.5, badge, badge)
        tx = x + pad + badge + pad * 0.6
    end

    -- title / vehicle name
    local titleSize = headH * 0.42
    local title = g_i18n:hasText("lco_title") and g_i18n:getText("lco_title") or "Loader Control"
    if st and self.settings.showVehicleName and st.vehicleName then
        title = st.vehicleName
    end
    self:text(tx, textY, titleSize, C.VALUE, title, "left", true)

    -- scheme name (right side of header)
    local schemeName = g_i18n:hasText(scheme.nameKey) and g_i18n:getText(scheme.nameKey) or scheme.id
    self:text(x + w - pad, textY, headH * 0.34, scheme.accent, schemeName, "right", false)

    -- content area
    local cx = x + pad
    local cy = y + pad
    local cw = w - pad * 2
    local ch = h - headH - pad * 2

    if st and st.hasLoader then
        -- feed smoothed channels with presence flags from raw state
        local drawState = {
            arm  = { present = st.arm.present,  position = self.sm.arm.position,  command = self.sm.arm.command },
            tool = { present = st.tool.present, position = self.sm.tool.position, command = self.sm.tool.command },
            aux  = { present = st.aux.present,  position = self.sm.aux.position,  command = self.sm.aux.command },
        }
        if not self.settings.showPositionFill then
            drawState.arm.position  = 0.5
            drawState.tool.position = 0.5
            drawState.aux.position  = 0.5
        end
        LCOControlScheme.draw(self, schemeId, cx, cy, cw, ch, drawState)
    else
        -- "no loader" placeholder
        local msg = g_i18n:hasText("lco_no_loader") and g_i18n:getText("lco_no_loader") or "No loader attached"
        self:text(x + w * 0.5, y + h * 0.45, ch * 0.16, C.DIM, msg, "center", false)
    end

    -- edit-mode chrome
    if self.editMode then
        self:border(x, y, w, h, C.EDIT_HANDLE, 0.0022)
        local hs = HUD.RESIZE_HANDLE
        self:rect(x + w - hs, y, hs, hs, C.EDIT_HANDLE)
        local hint = g_i18n:hasText("lco_edit_hint") and g_i18n:getText("lco_edit_hint")
            or "Drag to move - corner to resize - RMB to finish"
        self:text(x, y + h + 0.006, 0.012, C.EDIT_HANDLE, hint, "left", true)
    end
end

-- ── Edit mode ────────────────────────────────────────────
function LCOLoaderHUD:enterEditMode()
    self.editMode = true
    if g_inputBinding and g_inputBinding.setShowMouseCursor then
        g_inputBinding:setShowMouseCursor(true, true)
    end
    LCOLogger.debug("Edit mode ON")
end

function LCOLoaderHUD:exitEditMode()
    self.editMode = false
    self.dragging = false
    self.resizing = false
    if g_inputBinding and g_inputBinding.setShowMouseCursor then
        g_inputBinding:setShowMouseCursor(false)
    end
    self:saveLayout()
    LCOLogger.debug("Edit mode OFF — pos=(%.3f,%.3f) scale=%.2f", self.panelX, self.panelY, self.scale)
end

function LCOLoaderHUD:toggleEditMode()
    if self.editMode then self:exitEditMode() else self:enterEditMode() end
end

function LCOLoaderHUD:saveLayout()
    local s = self.settings
    s.positionPreset = 6
    s.customX = self.panelX
    s.customY = self.panelY
    s.scale   = self.scale
    s:validate()
    s:save()
end

-- Mouse handling in edit mode. Returns true if the event was consumed.
function LCOLoaderHUD:onMouseEvent(posX, posY, isDown, isUp, button)
    if not self.editMode then return false end

    if isDown and button == Input.MOUSE_BUTTON_RIGHT then
        self:exitEditMode()
        return true
    end

    local x, y, w, h = self:getRect()
    local hs = HUD.RESIZE_HANDLE

    if isDown and button == Input.MOUSE_BUTTON_LEFT then
        -- corner handle (bottom-right)
        if posX >= x + w - hs and posX <= x + w and posY >= y and posY <= y + hs then
            self.resizing = true
            local cxc, cyc = x + w * 0.5, y + h * 0.5
            self.resizeStartDist  = math.sqrt((posX - cxc) ^ 2 + (posY - cyc) ^ 2)
            self.resizeStartScale = self.scale
            return true
        end
        if posX >= x and posX <= x + w and posY >= y and posY <= y + h then
            self.dragging = true
            self.dragOffX = posX - self.panelX
            self.dragOffY = posY - self.panelY
            return true
        end
        return false
    end

    if isUp and button == Input.MOUSE_BUTTON_LEFT then
        if self.dragging or self.resizing then
            self.dragging = false
            self.resizing = false
            self:clamp()
            self:saveLayout()
            return true
        end
        return false
    end

    if self.dragging then
        self.panelX = posX - self.dragOffX
        self.panelY = posY - self.dragOffY
        self:clamp()
        return true
    end

    if self.resizing then
        local cxc, cyc = x + w * 0.5, y + h * 0.5
        local d = math.sqrt((posX - cxc) ^ 2 + (posY - cyc) ^ 2)
        local delta = (d - self.resizeStartDist) * 3.0
        self.scale = math.max(HUD.MIN_SCALE, math.min(HUD.MAX_SCALE, self.resizeStartScale + delta))
        self:clamp()
        return true
    end

    return false
end

return LCOLoaderHUD
