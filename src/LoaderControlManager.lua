-- =========================================================
-- FS25 Loader Control Overlay - Manager
-- =========================================================
-- Central coordinator (g_LoaderControlManager). Owns settings,
-- the loader detector, and the HUD. Registers the toggle/edit/
-- cycle hotkeys in both PLAYER and VEHICLE input contexts (pattern
-- proven in FS25_SoilFertilizer) and drives update/draw.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOManager
LCOManager = {}
local LCOManager_mt = Class(LCOManager)

function LCOManager.new(mission, modDirectory, modName)
    local self = setmetatable({}, LCOManager_mt)
    self.mission      = mission
    self.modDirectory = modDirectory
    self.modName      = modName

    self.settingsManager = LCOSettingsManager.new()
    self.settings        = LCOSettings.new(self.settingsManager)
    self.settings:load()

    self.detector = LCOLoaderDetector.new()
    self.hud      = LCOLoaderHUD.new(self.settings)
    self.panel    = LCOSettingsPanel.new(self.settings)

    -- input event id bookkeeping
    self._eventIds = {}

    LCOLogger.info("Manager created")
    return self
end

-- ── Lifecycle ────────────────────────────────────────────
function LCOManager:onMissionLoaded()
    self.hud:initialize()
    self:installInputHooks()
end

function LCOManager:update(dt)
    if self.panel then self.panel:update() end
    if not self.settings.enabled then
        -- still fade the HUD out cleanly
        self.hud:setState(self.detector.state)
        self.hud:update(dt)
        return
    end
    local state = self.detector:update(dt, self.settings)
    self.hud:setState(state)
    self.hud:update(dt)
end

function LCOManager:draw()
    self.hud:draw()
    if self.panel then self.panel:draw() end
end

function LCOManager:delete()
    -- restore the hooked class method
    if self._vehicleHookOriginal and InputBinding then
        InputBinding.endActionEventsModification = self._vehicleHookOriginal
        self._vehicleHookOriginal = nil
    end
    if self.hud then self.hud:delete() end
    if self.panel then self.panel:delete() end
    LCOLogger.info("Manager deleted")
end

-- ── Input registration (VEHICLE context only) ────────────
-- The overlay only matters while driving, so we register our hotkeys in
-- the VEHICLE input context. We purge our own previously-registered IDs
-- first so repeated context closes (seat changes, remounts) never stack
-- duplicate callbacks. Pattern adapted from FS25_SoilFertilizer.
function LCOManager:purgeEvents(binding)
    if self._eventIds then
        for _, id in ipairs(self._eventIds) do
            pcall(function() binding:removeActionEvent(id) end)
        end
    end
    self._eventIds = {}
end

function LCOManager:registerVehicleActions(binding)
    local function reg(action, cb)
        if InputAction[action] == nil then return end
        local ok, id = binding:registerActionEvent(InputAction[action], self, cb, false, true, false, true)
        if ok and id then
            binding:setActionEventTextVisibility(id, false)
            self._eventIds[#self._eventIds + 1] = id
        end
    end
    reg("LCO_TOGGLE_OVERLAY", self.onToggleOverlay)
    reg("LCO_EDIT_OVERLAY",   self.onEditOverlay)
    reg("LCO_CYCLE_SCHEME",   self.onCycleScheme)
    reg("LCO_CYCLE_POSITION", self.onCyclePosition)
    reg("LCO_OPEN_SETTINGS",  self.onOpenSettings)
end

function LCOManager:installInputHooks()
    if not (InputBinding and InputBinding.endActionEventsModification) then
        LCOLogger.warning("InputBinding unavailable — hotkeys disabled (console commands still work)")
        return
    end
    if self._vehicleHookOriginal then return end

    local origEnd = InputBinding.endActionEventsModification
    self._vehicleHookOriginal = origEnd
    local reentry = false
    InputBinding.endActionEventsModification = function(binding, ignoreCheck)
        -- Capture context BEFORE origEnd resets it.
        local contextName = ""
        if binding.registrationContext and binding.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
            contextName = binding.registrationContext.name or ""
        end
        origEnd(binding, ignoreCheck)

        if contextName ~= Vehicle.INPUT_CONTEXT_NAME then return end
        if reentry then return end
        local mgr = g_LoaderControlManager
        if not mgr then return end

        reentry = true
        mgr:purgeEvents(binding)
        binding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
        mgr:registerVehicleActions(binding)
        binding:endActionEventsModification()   -- routes here again; reentry guard returns early
        reentry = false
    end
    LCOLogger.info("Vehicle input hook installed")
end

-- ── Input callbacks ──────────────────────────────────────
function LCOManager:notify(msg)
    if g_currentMission and g_currentMission.hud and g_currentMission.hud.showBlinkingWarning then
        g_currentMission.hud:showBlinkingWarning(msg, 2000)
    end
end

function LCOManager:onToggleOverlay()
    local on = self.hud:toggleVisibility()
    self:notify(string.format("%s: %s",
        g_i18n:hasText("lco_title") and g_i18n:getText("lco_title") or "Loader Overlay",
        on and (g_i18n:hasText("lco_on") and g_i18n:getText("lco_on") or "ON")
            or (g_i18n:hasText("lco_off") and g_i18n:getText("lco_off") or "OFF")))
end

function LCOManager:onEditOverlay()
    self.hud:toggleEditMode()
end

function LCOManager:onCycleScheme()
    local n = self.settings:cycleSchemeOverride()
    local label
    if n == 0 then
        label = g_i18n:hasText("lco_scheme_auto") and g_i18n:getText("lco_scheme_auto") or "Auto"
    else
        local id = LCOSettings.SCHEME_BY_OVERRIDE[n]
        local sc = LCOConstants.SCHEMES[id]
        label = (sc and g_i18n:hasText(sc.nameKey) and g_i18n:getText(sc.nameKey)) or id
    end
    self:notify(string.format("%s: %s",
        g_i18n:hasText("lco_scheme") and g_i18n:getText("lco_scheme") or "Style", label))
end

function LCOManager:onCyclePosition()
    self.settings:cyclePositionPreset()
    self.hud:applyLayoutFromSettings()
end

function LCOManager:onOpenSettings()
    if self.panel then self.panel:toggle() end
end

-- ── Mouse routing ────────────────────────────────────────
-- The settings panel eats input first when it is open; otherwise the
-- HUD handles drag/resize in edit mode.
function LCOManager:onMouseEvent(posX, posY, isDown, isUp, button)
    if self.panel and self.panel:isOpen() then
        return self.panel:onMouseEvent(posX, posY, isDown, isUp, button)
    end
    return self.hud:onMouseEvent(posX, posY, isDown, isUp, button)
end

-- ── Console command surface ──────────────────────────────
function LCOManager:cmdStatus()
    local st = self.detector.state
    local s = self.settings
    print("=== Loader Control Overlay ===")
    print(string.format("Enabled: %s   Visible: %s   EditMode: %s", tostring(s.enabled), tostring(self.hud.visible), tostring(self.hud.editMode)))
    print(string.format("Scheme override: %d (%s)", s.schemeOverride, tostring(s:getSchemeOverrideName() or "Auto")))
    print(string.format("Position preset: %d   Scale: %.2f", s.positionPreset, s.scale))
    if st and st.hasLoader then
        print(string.format("Loader: YES  Vehicle: %s  Brand: %s  Scheme: %s",
            tostring(st.vehicleName), tostring(st.brandName or "?"), tostring(st.scheme)))
        print(string.format("  ARM  present=%s pos=%.2f cmd=%.2f", tostring(st.arm.present), st.arm.position, st.arm.command))
        print(string.format("  TOOL present=%s pos=%.2f cmd=%.2f", tostring(st.tool.present), st.tool.position, st.tool.command))
    else
        print("Loader: none on current vehicle")
    end
    return "ok"
end

return LCOManager
