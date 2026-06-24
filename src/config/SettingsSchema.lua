-- =========================================================
-- FS25 Loader Control Overlay - Settings Schema
-- =========================================================
-- Single source of truth for every setting. Drives defaults,
-- validation, and disk persistence. Add a setting once here.
--
-- All settings are localOnly: this is a client-side HUD, so each
-- player keeps their own layout/preferences (stored in modSettings).
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOSettingsSchema
LCOSettingsSchema = {}

-- type: "boolean" | "number"
-- number settings carry min/max for validation and cycling.
LCOSettingsSchema.definitions = {
    { id = "enabled",          type = "boolean", default = true  },
    { id = "showBrandLogo",    type = "boolean", default = true  },
    { id = "showVehicleName",  type = "boolean", default = true  },
    { id = "showPositionFill", type = "boolean", default = true  },
    { id = "showWhenNoLoader", type = "boolean", default = false },
    { id = "hideInMenu",       type = "boolean", default = true  },
    { id = "debugMode",        type = "boolean", default = false },

    -- 0 = Auto (brand-based), 1 = Modern, 2 = Classic, 3 = Alt
    { id = "schemeOverride",   type = "number",  default = 0, min = 0, max = 3 },
    -- 1..6 position presets (6 = custom, set by dragging in edit mode)
    { id = "positionPreset",   type = "number",  default = 1, min = 1, max = 6 },
    -- HUD scale (float)
    { id = "scale",            type = "number",  default = 1.0, min = 0.60, max = 2.00 },
    -- saved custom position (only meaningful when positionPreset == 6)
    { id = "customX",          type = "number",  default = 0.012, min = 0.0, max = 1.0 },
    { id = "customY",          type = "number",  default = 0.300, min = 0.0, max = 1.0 },
}

--- Returns a fresh table of { id = default } for all settings.
function LCOSettingsSchema.getAllDefaults()
    local t = {}
    for _, def in ipairs(LCOSettingsSchema.definitions) do
        t[def.id] = def.default
    end
    return t
end

--- True when a number setting should be persisted/handled as a float.
function LCOSettingsSchema.isFloat(def)
    if def.type ~= "number" then return false end
    return (def.default ~= math.floor(def.default))
        or (def.min and def.min ~= math.floor(def.min))
        or (def.max and def.max ~= math.floor(def.max))
end

return LCOSettingsSchema
