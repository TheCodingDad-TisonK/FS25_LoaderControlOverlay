-- =========================================================
-- FS25 Loader Control Overlay - Settings
-- =========================================================
-- Live settings object. Holds current values (generated from the
-- schema), validates them, and delegates persistence to the
-- SettingsManager. Mutators clamp + persist in one place.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOSettings
LCOSettings = {}
local LCOSettings_mt = Class(LCOSettings)

function LCOSettings.new(manager)
    local self = setmetatable({}, LCOSettings_mt)
    self.manager = manager

    -- Seed defaults so every field exists before load().
    for _, def in ipairs(LCOSettingsSchema.definitions) do
        self[def.id] = def.default
    end
    return self
end

function LCOSettings:load()
    if self.manager then
        self.manager:load(self)
    end
    self:validate()
end

function LCOSettings:save()
    if self.manager then
        return self.manager:save(self)
    end
    return false
end

--- Clamp every value back into its schema bounds.
function LCOSettings:validate()
    for _, def in ipairs(LCOSettingsSchema.definitions) do
        local v = self[def.id]
        if def.type == "boolean" then
            self[def.id] = (v == true)
        elseif def.type == "number" then
            if type(v) ~= "number" then v = def.default end
            if def.min and v < def.min then v = def.min end
            if def.max and v > def.max then v = def.max end
            self[def.id] = v
        end
    end
end

function LCOSettings:set(id, value)
    self[id] = value
    self:validate()
    self:save()
end

function LCOSettings:toggle(id)
    self:set(id, not self[id])
    return self[id]
end

-- ── Scheme override ──────────────────────────────────────
-- 0 = Auto, 1 = Modern, 2 = Classic, 3 = Alt
LCOSettings.SCHEME_BY_OVERRIDE = { [1] = "modern", [2] = "classic", [3] = "alt" }

function LCOSettings:getSchemeOverrideName()
    return LCOSettings.SCHEME_BY_OVERRIDE[self.schemeOverride or 0]   -- nil = Auto
end

function LCOSettings:cycleSchemeOverride()
    local n = (self.schemeOverride or 0) + 1
    if n > 3 then n = 0 end
    self:set("schemeOverride", n)
    return n
end

-- ── Position preset ──────────────────────────────────────
function LCOSettings:cyclePositionPreset()
    local n = (self.positionPreset or 1) + 1
    if n > LCOConstants.POSITION_COUNT then n = 1 end
    self:set("positionPreset", n)
    return n
end

return LCOSettings
