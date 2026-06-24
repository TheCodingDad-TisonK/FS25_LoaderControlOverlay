-- =========================================================
-- FS25 Loader Control Overlay - Settings Manager
-- =========================================================
-- Persists per-client settings to the user profile (modSettings),
-- so they survive across savegames and dedicated-server reconnects.
-- Layout: modSettings/FS25_LoaderControlOverlay/Settings/local.xml
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOSettingsManager
LCOSettingsManager = {}
local LCOSettingsManager_mt = Class(LCOSettingsManager)

LCOSettingsManager.MOD_NAME = "FS25_LoaderControlOverlay"
LCOSettingsManager.XMLTAG   = "LoaderControlOverlay"

function LCOSettingsManager.new()
    return setmetatable({}, LCOSettingsManager_mt)
end

--- Resolve (and create) the mod profile directory under modSettings.
function LCOSettingsManager.getModProfileDir()
    local ok, profilePath = pcall(getUserProfileAppPath)
    if ok and profilePath and profilePath ~= "" then
        local last = profilePath:sub(-1)
        if last ~= "/" and last ~= "\\" then
            profilePath = profilePath .. "/"
        end
        local base = profilePath .. "modSettings/" .. LCOSettingsManager.MOD_NAME
        createFolder(profilePath .. "modSettings")
        createFolder(base)
        createFolder(base .. "/Settings")
        return base
    end
    return nil
end

function LCOSettingsManager:getSettingsPath()
    local base = LCOSettingsManager.getModProfileDir()
    if base then
        return base .. "/Settings/local.xml"
    end
    return nil
end

function LCOSettingsManager:applyDefaults(settingsObject)
    for _, def in ipairs(LCOSettingsSchema.definitions) do
        settingsObject[def.id] = def.default
    end
end

function LCOSettingsManager:load(settingsObject)
    local path = self:getSettingsPath()
    if not path or not fileExists(path) then
        self:applyDefaults(settingsObject)
        LCOLogger.debug("No saved settings — using defaults")
        return
    end

    local xml = XMLFile.load("lco_cfg", path)
    if not xml then
        self:applyDefaults(settingsObject)
        return
    end

    for _, def in ipairs(LCOSettingsSchema.definitions) do
        local key = self.XMLTAG .. "." .. def.id
        if def.type == "boolean" then
            settingsObject[def.id] = xml:getBool(key, def.default)
        elseif def.type == "number" then
            if LCOSettingsSchema.isFloat(def) then
                settingsObject[def.id] = xml:getFloat(key, def.default)
            else
                settingsObject[def.id] = xml:getInt(key, def.default)
            end
        end
    end

    xml:delete()
    LCOLogger.info("Settings loaded: %s", path)
end

function LCOSettingsManager:save(settingsObject)
    local path = self:getSettingsPath()
    if not path then
        LCOLogger.warning("save: settings path unavailable")
        return false
    end

    local xml = XMLFile.create("lco_cfg", path, self.XMLTAG)
    if not xml then return false end

    for _, def in ipairs(LCOSettingsSchema.definitions) do
        local key = self.XMLTAG .. "." .. def.id
        if def.type == "boolean" then
            xml:setBool(key, settingsObject[def.id] == true)
        elseif def.type == "number" then
            if LCOSettingsSchema.isFloat(def) then
                xml:setFloat(key, settingsObject[def.id] or def.default)
            else
                xml:setInt(key, settingsObject[def.id] or def.default)
            end
        end
    end

    xml:save()
    xml:delete()
    LCOLogger.debug("Settings saved: %s", path)
    return true
end

return LCOSettingsManager
