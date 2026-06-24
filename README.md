# FS25 Loader Control Overlay

**Version:** 1.0.0.0
**Game:** Farming Simulator 25
**Authors:** TisonK & arissani

A dynamic on-screen overlay that shows your tractor's **front loader controls** and animates them **live** as you raise, lower, curl and dump. The control style adapts to the vehicle **brand**, and the panel carries the authentic brand badge pulled straight from the game.

---

## What it does

- **Live loader readout.** Reads the loader's actual moving tools every frame — arm height and tool curl positions, plus the direction you're commanding right now. Works with keyboard, controller, and AI helpers.
- **Brand-aware styling.** The widget restyles itself based on the tractor brand:
  - **Modern** — a joystick command pad with twin position bars (John Deere, Fendt, Case IH, New Holland, Valtra...).
  - **Classic** — twin mechanical lever "knockers" (Massey Ferguson, Landini, McCormick, Zetor...).
  - **Paddle** — stacked rocker switches (Claas, JCB, Manitou, Kramer, Stoll, Quicke...).
- **Authentic brand badge.** The real in-game brand logo is shown in the header.
- **Fully client-side.** It's a HUD — no gameplay changes, multiplayer-friendly, nothing to sync.
- **Configurable.** Move/resize it, pin it to a preset corner, override the style, toggle the brand badge / vehicle name / position fill, all saved per player.

---

## Controls (default)

| Action | Default key | What it does |
|--------|-------------|--------------|
| Toggle overlay | `Alt + L` | Show / hide the overlay |
| Move / resize | `Alt + K` | Enter edit mode (drag to move, drag corner to resize, RMB to finish) |
| Cycle style | `Alt + J` | Auto → Modern → Classic → Paddle |
| Cycle position | `Alt + H` | Step through the position presets |

Hotkeys are active **while seated in a vehicle** (that's where the overlay lives); the console commands below work anywhere. All keys are rebindable in **Options → Controls**.

---

## Console commands

Open the console with `~` and type:

| Command | Description |
|---------|-------------|
| `loaderControl` | List all commands |
| `loaderControlStatus` | Show current loader/brand/state |
| `loaderControlToggle` | Show / hide the overlay |
| `loaderControlScheme <0-3>` | 0 Auto · 1 Modern · 2 Classic · 3 Paddle |
| `loaderControlScale <0.6-2.0>` | Set HUD scale |
| `loaderControlDebug` | Toggle debug logging |
| `loaderControlReset` | Reset settings to defaults |

---

## Installation

1. Download `FS25_LoaderControlOverlay.zip` from the [Releases](../../releases) page.
2. Drop it into your `My Games/FarmingSimulator2025/mods` folder.
3. Enable it in the in-game mod menu.

---

## Compatibility

- Singleplayer and multiplayer (client-side HUD; each player has their own layout).
- Works with any vehicle exposing a front loader (`AXIS_FRONTLOADER_ARM` / `AXIS_FRONTLOADER_TOOL`), including most modded loaders.
- No dependencies.

---

## Languages

Ships with all 26 FS25 languages.

---

## Credits

Built by **TisonK** and **arissani**.

All rights reserved. Please do not re-upload or claim this work as your own.
