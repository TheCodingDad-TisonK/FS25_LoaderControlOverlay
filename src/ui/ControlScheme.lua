-- =========================================================
-- FS25 Loader Control Overlay - Control Schemes
-- =========================================================
-- Procedural, asset-free rendering of three loader control styles.
-- Each scheme visualizes two channels:
--   ARM  channel.position (0=down .. 1=up)   channel.command (-1 lower .. +1 raise)
--   TOOL channel.position (0=dump .. 1=curl) channel.command (-1 dump  .. +1 curl)
--
-- Only filled rectangles + text are used (engine-safe, resolution
-- independent). The HUD passes a drawing context `hud` exposing
-- rect()/border()/text() and the smoothed channel state.
-- =========================================================
-- Authors: TisonK, arissani
-- =========================================================

---@class LCOControlScheme
LCOControlScheme = {}

local C = LCOConstants.COLORS

-- ── helpers ──────────────────────────────────────────────
local function dim(c, f)
    return { c[1] * f, c[2] * f, c[3] * f, c[4] }
end

-- Colour for an active command (raise/curl = up glow, lower/dump = down glow).
local function commandColor(cmd, accent)
    if cmd > 0.06 then
        return C.GLOW_UP
    elseif cmd < -0.06 then
        return C.GLOW_DOWN
    end
    return dim(accent, 0.80)
end

-- Label + percentage for a channel.
local function channelPct(channel)
    if not channel.present then return "--" end
    return string.format("%d%%", math.floor((channel.position or 0) * 100 + 0.5))
end

-- =========================================================
-- MODERN — joystick command pad + twin position bars
-- =========================================================
local function drawModern(hud, x, y, w, h, state, accent)
    local arm, tool = state.arm, state.tool

    -- Left: square command pad.
    local pad = math.min(h * 0.96, w * 0.52)
    local px = x
    local py = y + (h - pad) * 0.5
    hud:rect(px, py, pad, pad, C.TRACK)
    hud:border(px, py, pad, pad, accent, 0.0016)
    -- faint crosshair
    hud:rect(px + pad * 0.5 - 0.0006, py + pad * 0.10, 0.0012, pad * 0.80, dim(accent, 0.45))
    hud:rect(px + pad * 0.10, py + pad * 0.5 - 0.0006, pad * 0.80, 0.0012, dim(accent, 0.45))

    -- moving dot: x = tool command, y = arm command
    local cx = px + pad * 0.5
    local cy = py + pad * 0.5
    local r  = pad * 0.40
    local tcmd = tool.present and (tool.command or 0) or 0
    local acmd = arm.present and (arm.command or 0) or 0
    local dotX = cx + tcmd * r
    local dotY = cy + acmd * r
    local ds = pad * 0.16
    -- soft trail rectangle from center to dot
    local dotCol = commandColor((math.abs(acmd) >= math.abs(tcmd)) and acmd or tcmd, accent)
    hud:rect(dotX - ds * 0.5, dotY - ds * 0.5, ds, ds, dotCol)

    -- Right: two vertical position bars (ARM, TOOL).
    local barsX = x + pad + w * 0.06
    local barAreaW = (x + w) - barsX
    local barW = barAreaW * 0.40
    local gap  = barAreaW * 0.20
    local barH = h * 0.72
    local barY = y + h * 0.06
    local labelSize = h * 0.10

    local function vbar(bx, channel, label)
        hud:rect(bx, barY, barW, barH, C.TRACK)
        if channel.present then
            local fillH = barH * (channel.position or 0)
            local col = commandColor(channel.command or 0, accent)
            -- position fill is accent; the top cap glows toward the active command
            hud:rect(bx, barY, barW, math.max(0.0009, fillH), dim(accent, 0.9))
            if math.abs(channel.command or 0) > 0.06 then
                hud:rect(bx, barY + fillH - 0.0016, barW, 0.0032, col)
            end
        end
        hud:text(bx + barW * 0.5, barY + barH + h * 0.03, labelSize, C.LABEL, label, "center", true)
        hud:text(bx + barW * 0.5, barY - h * 0.12, labelSize, C.VALUE, channelPct(channel), "center", false)
    end

    vbar(barsX, arm, "ARM")
    vbar(barsX + barW + gap, tool, "TOOL")
end

-- =========================================================
-- CLASSIC — twin mechanical levers ("knockers")
-- =========================================================
local function drawClassic(hud, x, y, w, h, state, accent)
    local arm, tool = state.arm, state.tool
    local slotW = w * 0.16
    local slotH = h * 0.72
    local slotY = y + h * 0.10
    local centerGap = w * 0.30
    local leftX  = x + w * 0.5 - centerGap * 0.5 - slotW
    local rightX = x + w * 0.5 + centerGap * 0.5
    local labelSize = h * 0.10

    local function lever(sx, channel, label)
        -- gate slot
        hud:rect(sx, slotY, slotW, slotH, C.TRACK)
        hud:border(sx, slotY, slotW, slotH, dim(accent, 0.7), 0.0014)
        -- notches top/bottom
        hud:rect(sx - slotW * 0.25, slotY + slotH - 0.0026, slotW * 1.5, 0.0026, dim(accent, 0.5))
        hud:rect(sx - slotW * 0.25, slotY, slotW * 1.5, 0.0026, dim(accent, 0.5))

        if channel.present then
            local pos = channel.position or 0
            local knobH = slotH * 0.12
            local knobY = slotY + (slotH - knobH) * pos
            -- lever shaft
            hud:rect(sx + slotW * 0.5 - 0.0012, slotY + knobH * 0.5, 0.0024, (knobY - slotY), dim(accent, 0.6))
            -- knob (wider than slot)
            local cmd = channel.command or 0
            local knobCol = (math.abs(cmd) > 0.06) and commandColor(cmd, accent) or accent
            hud:rect(sx - slotW * 0.28, knobY, slotW * 1.56, knobH, knobCol)
            -- command glow segment above/below knob
            if cmd > 0.06 then
                hud:rect(sx, slotY + slotH - 0.004, slotW, 0.004, C.GLOW_UP)
            elseif cmd < -0.06 then
                hud:rect(sx, slotY, slotW, 0.004, C.GLOW_DOWN)
            end
        else
            hud:rect(sx, slotY + slotH * 0.5 - 0.001, slotW, 0.002, C.DIM)
        end

        hud:text(sx + slotW * 0.5, slotY + slotH + h * 0.04, labelSize, C.LABEL, label, "center", true)
        hud:text(sx + slotW * 0.5, slotY - h * 0.12, labelSize, C.VALUE, channelPct(channel), "center", false)
    end

    lever(leftX, arm, "ARM")
    lever(rightX, tool, "TOOL")
end

-- =========================================================
-- ALT — stacked horizontal paddle/rocker switches
-- =========================================================
local function drawAlt(hud, x, y, w, h, state, accent)
    local arm, tool = state.arm, state.tool
    local rockH = h * 0.26
    local rockW = w * 0.78
    local rockX = x + w * 0.20
    local gap   = h * 0.16
    local topY  = y + h * 0.58
    local botY  = topY - rockH - gap
    local labelSize = h * 0.10

    local function rocker(ry, channel, label)
        hud:rect(rockX, ry, rockW, rockH, C.TRACK)
        hud:border(rockX, ry, rockW, rockH, dim(accent, 0.7), 0.0014)
        -- center divider
        hud:rect(rockX + rockW * 0.5 - 0.0008, ry, 0.0016, rockH, dim(accent, 0.6))

        if channel.present then
            local cmd = channel.command or 0
            -- glow the commanded half
            if cmd < -0.06 then
                hud:rect(rockX, ry, rockW * 0.5, rockH, dim(C.GLOW_DOWN, 0.9))
            elseif cmd > 0.06 then
                hud:rect(rockX + rockW * 0.5, ry, rockW * 0.5, rockH, dim(C.GLOW_UP, 0.9))
            end
            -- position pip sliding along the rocker
            local pos = channel.position or 0
            local pipW = rockW * 0.07
            local pipX = rockX + (rockW - pipW) * pos
            hud:rect(pipX, ry - 0.002, pipW, rockH + 0.004, accent)
        else
            hud:rect(rockX, ry + rockH * 0.5 - 0.001, rockW, 0.002, C.DIM)
        end

        hud:text(rockX - w * 0.02, ry + rockH * 0.5, labelSize, C.LABEL, label, "right", true)
        hud:text(rockX + rockW + w * 0.02, ry + rockH * 0.5, labelSize, C.VALUE, channelPct(channel), "left", false)
    end

    rocker(topY, arm, "ARM")
    rocker(botY, tool, "TOOL")
end

-- =========================================================
-- Dispatch + AUX indicator
-- =========================================================
local DRAW = {
    modern  = drawModern,
    classic = drawClassic,
    alt     = drawAlt,
}

--- Draw the loader widget for `schemeId` inside rect (x,y,w,h).
function LCOControlScheme.draw(hud, schemeId, x, y, w, h, state)
    local scheme = LCOConstants.SCHEMES[schemeId] or LCOConstants.SCHEMES[LCOConstants.DEFAULT_SCHEME]
    local accent = scheme.accent

    -- reserve a slim strip at the bottom for a 3rd-function (AUX) indicator
    local auxH = 0
    if state.aux and state.aux.present then
        auxH = h * 0.12
    end
    local drawer = DRAW[scheme.id] or drawModern
    drawer(hud, x, y + auxH, w, h - auxH, state, accent)

    if auxH > 0 then
        local aux = state.aux
        hud:text(x, y, h * 0.085, C.LABEL, "AUX", "left", true)
        local trackX = x + w * 0.16
        local trackW = w * 0.84
        hud:rect(trackX, y + auxH * 0.30, trackW, auxH * 0.30, C.TRACK)
        local col = commandColor(aux.command or 0, accent)
        hud:rect(trackX, y + auxH * 0.30, trackW * (aux.position or 0), auxH * 0.30, col)
    end
end

return LCOControlScheme
