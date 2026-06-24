-- =========================================================
-- FS25 Loader Control Overlay - Entry Point
-- =========================================================
-- Loads modules in dependency order, hooks the FS25 mission
-- lifecycle, routes mouse events, and registers console commands.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================
-- COPYRIGHT: All rights reserved. Unauthorized redistribution or
-- claiming this code as your own is prohibited.
-- =========================================================

local modDirectory = g_currentModDirectory
local modName      = g_currentModName

-- Source order: utilities/config first, then core, UI, manager.
source(modDirectory .. "src/utils/Logger.lua")
source(modDirectory .. "src/config/Constants.lua")
source(modDirectory .. "src/config/SettingsSchema.lua")
source(modDirectory .. "src/settings/SettingsManager.lua")
source(modDirectory .. "src/settings/Settings.lua")
source(modDirectory .. "src/core/LoaderDetector.lua")
source(modDirectory .. "src/ui/ControlScheme.lua")
source(modDirectory .. "src/ui/LoaderHUD.lua")
source(modDirectory .. "src/LoaderControlManager.lua")

local mgr = nil

-- ── Lifecycle hooks ──────────────────────────────────────
local function load(mission)
    if mgr ~= nil then return end
    mgr = LCOManager.new(mission, modDirectory, modName)
    if mgr == nil then
        LCOLogger.error("LCOManager.new() returned nil — mod will not function")
        return
    end
    getfenv(0)["g_LoaderControlManager"] = mgr
    LCOLogger.info("Loaded")
end

local function loadedMission(mission, node)
    if mission.cancelLoading then return end
    if mgr == nil then
        LCOLogger.error("loadedMission: manager is nil")
        return
    end
    mgr:onMissionLoaded()
end

local function unload()
    if mgr ~= nil then
        mgr:delete()
        mgr = nil
        getfenv(0)["g_LoaderControlManager"] = nil
    end
end

Mission00.load = Utils.appendedFunction(Mission00.load, load)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
FSBaseMission.delete = Utils.prependedFunction(FSBaseMission.delete, unload)

FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, function(mission, dt)
    if mgr then mgr:update(dt) end
end)

FSBaseMission.draw = Utils.appendedFunction(FSBaseMission.draw, function(mission)
    if not mission.isRunning then return end
    if mgr then mgr:draw() end
end)

-- ── Mouse routing (edit-mode drag/resize) ────────────────
local lcoMouseHandler = {}
function lcoMouseHandler:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    if mgr then
        local consumed = mgr:onMouseEvent(posX, posY, isDown, isUp, button)
        eventUsed = consumed or eventUsed
    end
    return eventUsed
end
addModEventListener(lcoMouseHandler)

-- ── Console commands ─────────────────────────────────────
LCO_CONSOLE = {}

function LCO_CONSOLE:help()
    print("=== Loader Control Overlay — commands ===")
    print("loaderControlStatus            - show current state")
    print("loaderControlToggle            - show/hide the overlay")
    print("loaderControlScheme <0-3>      - 0 Auto, 1 Modern, 2 Classic, 3 Alt")
    print("loaderControlScale <0.6-2.0>   - set HUD scale")
    print("loaderControlDebug             - toggle debug logging")
    print("loaderControlReset             - reset settings to defaults")
    return "see console output"
end

function LCO_CONSOLE:status()
    if g_LoaderControlManager then return g_LoaderControlManager:cmdStatus() end
    return "Loader Control Overlay not initialized"
end

function LCO_CONSOLE:toggle()
    if not g_LoaderControlManager then return "not initialized" end
    local on = g_LoaderControlManager.hud:toggleVisibility()
    return "Overlay " .. (on and "shown" or "hidden")
end

function LCO_CONSOLE:scheme(n)
    if not g_LoaderControlManager then return "not initialized" end
    n = tonumber(n)
    if n == nil or n < 0 or n > 3 then return "usage: loaderControlScheme <0-3>" end
    g_LoaderControlManager.settings:set("schemeOverride", n)
    return string.format("schemeOverride = %d", n)
end

function LCO_CONSOLE:scale(v)
    if not g_LoaderControlManager then return "not initialized" end
    v = tonumber(v)
    if v == nil then return "usage: loaderControlScale <0.6-2.0>" end
    g_LoaderControlManager.settings:set("scale", v)
    g_LoaderControlManager.hud:applyLayoutFromSettings()
    return string.format("scale = %.2f", g_LoaderControlManager.settings.scale)
end

function LCO_CONSOLE:debug()
    if not g_LoaderControlManager then return "not initialized" end
    local on = g_LoaderControlManager.settings:toggle("debugMode")
    return "debug = " .. tostring(on)
end

function LCO_CONSOLE:reset()
    if not g_LoaderControlManager then return "not initialized" end
    g_LoaderControlManager.settingsManager:applyDefaults(g_LoaderControlManager.settings)
    g_LoaderControlManager.settings:save()
    g_LoaderControlManager.hud:applyLayoutFromSettings()
    return "settings reset to defaults"
end

addConsoleCommand("loaderControl",       "Loader Control Overlay: list commands", "help",   LCO_CONSOLE)
addConsoleCommand("loaderControlStatus", "Loader Control Overlay: show state",     "status", LCO_CONSOLE)
addConsoleCommand("loaderControlToggle", "Loader Control Overlay: show/hide",      "toggle", LCO_CONSOLE)
addConsoleCommand("loaderControlScheme", "Loader Control Overlay: set style 0-3",  "scheme", LCO_CONSOLE)
addConsoleCommand("loaderControlScale",  "Loader Control Overlay: set scale",      "scale",  LCO_CONSOLE)
addConsoleCommand("loaderControlDebug",  "Loader Control Overlay: toggle debug",   "debug",  LCO_CONSOLE)
addConsoleCommand("loaderControlReset",  "Loader Control Overlay: reset settings", "reset",  LCO_CONSOLE)

print("========================================")
print("  FS25 Loader Control Overlay LOADED")
print("  by TisonK & arissani")
print("  Type 'loaderControl' for commands")
print("========================================")
