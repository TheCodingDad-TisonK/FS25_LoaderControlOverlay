-- =========================================================
-- FS25 Loader Control Overlay - Loader Detector
-- =========================================================
-- Finds the loader on the controlled vehicle and reads its live
-- state directly from the moving tools:
--   * position  — normalized curRot/curTrans  (where the arm/tool IS)
--   * command   — movingTool.move+externalMove (what the player is
--                 commanding THIS frame: the "responds to input" signal)
--
-- No action-event registration and no input-context juggling: reading
-- the tools works for keyboard, controller, and AI drivers alike.
--
-- API anchors (verified against FS25-Community-LUADOC):
--   Cylindered movingTool.axis / .move / .curRot / .rotMin / .rotMax
--   Vehicle:getBrand() -> g_brandManager:getBrandByIndex()
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOLoaderDetector
LCOLoaderDetector = {}
local LCOLoaderDetector_mt = Class(LCOLoaderDetector)

local ARM_AXIS  = LCOConstants.AXES.ARM
local TOOL_AXIS = LCOConstants.AXES.TOOL

function LCOLoaderDetector.new()
    local self = setmetatable({}, LCOLoaderDetector_mt)
    self.scanTimer = 0
    self.cachedTools = { arm = nil, tool = nil, aux = nil }
    self.cachedRoot  = nil
    self.state = {
        hasLoader      = false,
        vehicleName    = nil,
        brandName      = nil,
        brandTitle     = nil,
        brandIcon      = nil,
        autoScheme     = LCOConstants.DEFAULT_SCHEME,
        scheme         = LCOConstants.DEFAULT_SCHEME,
        arm  = { present = false, position = 0.5, command = 0 },
        tool = { present = false, position = 0.5, command = 0 },
        aux  = { present = false, position = 0.5, command = 0 },
    }
    return self
end

-- ── Controlled root vehicle ──────────────────────────────
function LCOLoaderDetector.getControlledRootVehicle()
    local vehicle
    if g_localPlayer and type(g_localPlayer.getIsInVehicle) == "function" then
        local ok, inV = pcall(function() return g_localPlayer:getIsInVehicle() end)
        if ok and inV then
            local ok2, v = pcall(function() return g_localPlayer:getCurrentVehicle() end)
            if ok2 then vehicle = v end
        end
    end
    if not vehicle and g_currentMission then
        vehicle = g_currentMission.controlledVehicle
    end
    if not vehicle then return nil end

    -- Resolve to the root of the attach tree (the tractor).
    if type(vehicle.getRootVehicle) == "function" then
        local ok, root = pcall(function() return vehicle:getRootVehicle() end)
        if ok and root then return root end
    end
    return vehicle.rootVehicle or vehicle
end

-- ── Gather every vehicle in the attach tree ──────────────
local function gatherChildVehicles(root)
    if root == nil then return {} end
    if type(root.getChildVehicles) == "function" then
        local ok, list = pcall(function() return root:getChildVehicles() end)
        if ok and type(list) == "table" and #list > 0 then
            return list
        end
    end

    -- Fallback: manual recursion through attacher joints.
    local result, visited = {}, {}
    local function visit(v)
        if v == nil or visited[v] then return end
        visited[v] = true
        result[#result + 1] = v
        local spec = v.spec_attacherJoints
        if spec and spec.attachedImplements then
            for _, impl in pairs(spec.attachedImplements) do
                if impl and impl.object then visit(impl.object) end
            end
        end
    end
    visit(root)
    return result
end

-- ── Read one moving tool's normalized position + command ─
local function readTool(tool)
    local position
    if tool.rotMax ~= nil and tool.rotMin ~= nil and tool.curRot then
        local axis = tool.rotationAxis or 1
        local denom = tool.rotMax - tool.rotMin
        local cur = tool.curRot[axis]
        if denom ~= 0 and cur ~= nil then
            position = (cur - tool.rotMin) / denom
        end
    elseif tool.transMax ~= nil and tool.transMin ~= nil and tool.curTrans then
        local axis = tool.translationAxis or 1
        local denom = tool.transMax - tool.transMin
        local cur = tool.curTrans[axis]
        if denom ~= 0 and cur ~= nil then
            position = (cur - tool.transMin) / denom
        end
    end
    if position == nil then position = 0.5 end
    if position < 0 then position = 0 elseif position > 1 then position = 1 end

    local command = (tool.move or 0) + (tool.externalMove or 0)
    if command < -1 then command = -1 elseif command > 1 then command = 1 end

    return position, command
end

-- ── Heavy scan (throttled): find loader tools + brand ────
function LCOLoaderDetector:scan(settings)
    local root = LCOLoaderDetector.getControlledRootVehicle()
    self.cachedRoot = root
    self.cachedTools = { arm = nil, tool = nil, aux = nil }

    if root == nil then
        self.state.hasLoader = false
        return
    end

    -- Find one representative movingTool per loader channel.
    local vehicles = gatherChildVehicles(root)
    for _, v in ipairs(vehicles) do
        local cyl = v.spec_cylindered
        if cyl and cyl.movingTools then
            for _, tool in ipairs(cyl.movingTools) do
                local axisName = tool.axis
                if type(axisName) == "string" then
                    if axisName:sub(1, #ARM_AXIS) == ARM_AXIS then
                        if not self.cachedTools.arm then self.cachedTools.arm = tool end
                    elseif axisName:sub(1, #TOOL_AXIS) == TOOL_AXIS then
                        if not self.cachedTools.tool then self.cachedTools.tool = tool end
                    elseif axisName:sub(1, 16) == "AXIS_FRONTLOADER" then
                        if not self.cachedTools.aux then self.cachedTools.aux = tool end
                    end
                end
            end
        end
    end

    local hasLoader = (self.cachedTools.arm ~= nil) or (self.cachedTools.tool ~= nil)
    self.state.hasLoader = hasLoader
    if not hasLoader then return end

    -- Vehicle display name.
    local name
    if type(root.getFullName) == "function" then
        local ok, n = pcall(function() return root:getFullName() end)
        if ok then name = n end
    end
    if not name and type(root.getName) == "function" then
        local ok, n = pcall(function() return root:getName() end)
        if ok then name = n end
    end
    self.state.vehicleName = name

    -- Brand → auto scheme.
    local brandName, brandTitle, brandIcon
    if type(root.getBrand) == "function" and g_brandManager then
        local ok, idx = pcall(function() return root:getBrand() end)
        if ok and idx then
            local ok2, brand = pcall(function() return g_brandManager:getBrandByIndex(idx) end)
            if ok2 and brand then
                brandName  = brand.name
                brandTitle = brand.title
                brandIcon  = brand.image
            end
        end
    end
    self.state.brandName  = brandName
    self.state.brandTitle = brandTitle
    self.state.brandIcon  = brandIcon

    local auto = (brandName and LCOConstants.BRAND_SCHEME[brandName]) or LCOConstants.DEFAULT_SCHEME
    self.state.autoScheme = auto

    -- Effective scheme (override wins).
    local override = settings and settings:getSchemeOverrideName()
    self.state.scheme = override or auto
end

-- ── Per-frame light read of cached tools ─────────────────
function LCOLoaderDetector:readFrame()
    local function apply(channel, tool)
        if tool == nil then
            channel.present = false
            return
        end
        local ok, pos, cmd = pcall(readTool, tool)
        if ok then
            channel.present  = true
            channel.position = pos
            channel.command  = cmd
        else
            channel.present = false
        end
    end
    apply(self.state.arm,  self.cachedTools.arm)
    apply(self.state.tool, self.cachedTools.tool)
    apply(self.state.aux,  self.cachedTools.aux)
end

-- ── Public update ────────────────────────────────────────
function LCOLoaderDetector:update(dt, settings)
    self.scanTimer = self.scanTimer + dt * 0.001
    if self.scanTimer >= LCOConstants.TIMING.DETECT_INTERVAL or self.cachedRoot == nil then
        self.scanTimer = 0
        self:scan(settings)
    else
        -- keep effective scheme in sync with a live override change
        if self.state.hasLoader and settings then
            local override = settings:getSchemeOverrideName()
            self.state.scheme = override or self.state.autoScheme
        end
    end

    if self.state.hasLoader then
        self:readFrame()
    end
    return self.state
end

return LCOLoaderDetector
