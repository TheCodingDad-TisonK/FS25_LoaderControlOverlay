-- =========================================================
-- FS25 Loader Control Overlay - Constants
-- =========================================================
-- All tunable values live here (SoilFertilizer-style central
-- config). Categories: HUD, COLORS, POSITIONS, SCHEMES,
-- BRAND_SCHEME, AXES, TIMING.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOConstants
LCOConstants = {}

-- ── Frontloader input axes we care about ─────────────────
-- A movingTool stores the InputAction name it responds to in tool.axis.
-- These are the canonical FS25 loader axes (confirmed: VehicleDebug.lua,
-- Cylindered movingTool registration). Matched by prefix so multi-function
-- loaders (ARM2/TOOL2/...) still classify correctly.
LCOConstants.AXES = {
    ARM  = "AXIS_FRONTLOADER_ARM",
    TOOL = "AXIS_FRONTLOADER_TOOL",
}

-- ── Timing / smoothing ───────────────────────────────────
LCOConstants.TIMING = {
    DETECT_INTERVAL   = 0.25,   -- seconds between vehicle/loader re-scans
    POSITION_SMOOTH   = 14.0,   -- higher = snappier position needle
    COMMAND_SMOOTH    = 22.0,   -- higher = snappier command deflection
    COMMAND_DECAY     = 9.0,    -- how fast the active-input glow fades to neutral
    APPEAR_FADE       = 6.0,    -- panel fade-in/out speed
}

-- ── Base layout (1080p-relative, scaled by user scale) ───
LCOConstants.HUD = {
    BASE_W   = 0.150,
    BASE_H   = 0.150,
    PAD      = 0.008,
    HEADER_H = 0.026,
    MIN_SCALE = 0.60,
    MAX_SCALE = 2.00,
    RESIZE_HANDLE = 0.010,
}

-- ── Position presets (bottom-left of panel, screen space) ─
-- index 6 = Custom (driven by drag in edit mode).
LCOConstants.POSITIONS = {
    { x = 0.012, y = 0.300 },   -- 1 Left
    { x = 0.838, y = 0.300 },   -- 2 Right
    { x = 0.012, y = 0.120 },   -- 3 Lower left
    { x = 0.838, y = 0.120 },   -- 4 Lower right
    { x = 0.425, y = 0.150 },   -- 5 Bottom center
    { x = 0.012, y = 0.300 },   -- 6 Custom (placeholder, overridden by saved layout)
}
LCOConstants.POSITION_COUNT = 5   -- presets selectable by cycling (6 is custom-on-drag)

-- ── Colors ───────────────────────────────────────────────
LCOConstants.COLORS = {
    BG          = { 0.05, 0.06, 0.07, 0.82 },
    HEADER_BG   = { 0.09, 0.10, 0.12, 0.92 },
    BORDER      = { 0.22, 0.24, 0.27, 0.55 },
    TRACK       = { 0.16, 0.17, 0.19, 0.92 },
    LABEL       = { 0.74, 0.76, 0.80, 1.00 },
    VALUE       = { 1.00, 1.00, 1.00, 1.00 },
    DIM         = { 0.50, 0.52, 0.56, 0.90 },
    SHADOW      = { 0.00, 0.00, 0.00, 0.35 },
    GLOW_UP     = { 0.36, 0.80, 1.00, 1.00 },   -- active command (raise / curl)
    GLOW_DOWN   = { 1.00, 0.62, 0.24, 1.00 },   -- active command (lower / dump)
    NEUTRAL     = { 0.62, 0.66, 0.72, 1.00 },
    EDIT_HANDLE = { 0.24, 0.62, 1.00, 0.90 },
    OK          = { 0.30, 0.85, 0.38, 1.00 },
}

-- ── Control schemes ──────────────────────────────────────
-- Each scheme is a drawing style. "accent" tints the widget so the
-- three styles read distinctly. The actual geometry is drawn in
-- ControlScheme.lua; this just carries identity + theming.
LCOConstants.SCHEMES = {
    modern = {
        id      = "modern",
        nameKey = "lco_scheme_modern",
        accent  = { 0.30, 0.74, 1.00, 1.00 },   -- electric blue (joystick / electro-hydraulic)
    },
    classic = {
        id      = "classic",
        nameKey = "lco_scheme_classic",
        accent  = { 0.95, 0.74, 0.24, 1.00 },   -- amber (mechanical dual-lever "knocker")
    },
    alt = {
        id      = "alt",
        nameKey = "lco_scheme_alt",
        accent  = { 0.55, 0.86, 0.46, 1.00 },   -- green (cab-integrated paddle)
    },
}
LCOConstants.SCHEME_ORDER = { "modern", "classic", "alt" }
LCOConstants.DEFAULT_SCHEME = "modern"

-- ── Brand → scheme heuristic ─────────────────────────────
-- Cosmetic mapping only. Brand names come from g_brandManager (dataS/brands.xml),
-- always upper-case. Anything not listed falls back to DEFAULT_SCHEME. Users can
-- override per-session with the cycle-scheme key / setting.
LCOConstants.BRAND_SCHEME = {
    -- Modern joystick / electro-hydraulic
    JOHNDEERE = "modern", FENDT = "modern", CASEIH = "modern", NEWHOLLAND = "modern",
    VALTRA = "modern", DEUTZ = "modern", DEUTZFAHR = "modern", KUBOTA = "modern",
    STEYR = "modern", SAME = "modern", CLAYSON = "modern",
    -- Classic mechanical dual-lever
    MASSEYFERGUSON = "classic", LANDINI = "classic", MCCORMICK = "classic",
    ZETOR = "classic", URSUS = "classic", LIZARD = "classic", BELARUS = "classic",
    INTERNATIONAL = "classic", VERSATILE = "classic",
    -- Cab-integrated paddle / loader specialists
    CLAAS = "alt", JCB = "alt", MANITOU = "alt", MERLO = "alt", AGCO = "alt",
    CHALLENGER = "alt", KRAMER = "alt", WEIDEMANN = "alt", SCHAFFER = "alt",
    STOLL = "alt", QUICKE = "alt",
}

return LCOConstants
