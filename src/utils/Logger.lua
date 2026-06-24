-- =========================================================
-- FS25 Loader Control Overlay - Logger
-- =========================================================
-- Centralized logging with a consistent [LoaderControl] prefix
-- and debug-mode gating.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOLogger
LCOLogger = {}

local PREFIX = "[LoaderControl]"

--- Debug message (only printed when debug mode is on).
function LCOLogger.debug(msg, ...)
    local mgr = g_LoaderControlManager
    if mgr and mgr.settings and mgr.settings.debugMode then
        local ok, formatted = pcall(string.format, PREFIX .. " DEBUG: " .. msg, ...)
        print(ok and formatted or (PREFIX .. " DEBUG: " .. tostring(msg)))
    end
end

--- Info message (always printed).
function LCOLogger.info(msg, ...)
    local ok, formatted = pcall(string.format, PREFIX .. " " .. msg, ...)
    print(ok and formatted or (PREFIX .. " " .. tostring(msg)))
end

--- Warning message (always printed).
function LCOLogger.warning(msg, ...)
    local ok, formatted = pcall(string.format, PREFIX .. " WARNING: " .. msg, ...)
    print(ok and formatted or (PREFIX .. " WARNING: " .. tostring(msg)))
end

--- Error message (always printed).
function LCOLogger.error(msg, ...)
    local ok, formatted = pcall(string.format, PREFIX .. " ERROR: " .. msg, ...)
    print(ok and formatted or (PREFIX .. " ERROR: " .. tostring(msg)))
end
