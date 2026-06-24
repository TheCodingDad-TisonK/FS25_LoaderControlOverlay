# FS25 Loader Control Overlay

Version 1.0.0.0, by TisonK and arissani.

An on-screen overlay that shows your tractor's front loader controls and animates them as you drive. Raise, lower, curl and dump, and the overlay moves with you. The look changes depending on the tractor brand, and it shows the real brand logo from the game.

## What it does

It reads the loader's moving parts every frame, so you see the actual arm height and bucket angle, plus the direction you're pushing right now. Works with keyboard, controller and AI workers.

The control style changes with the brand:

- Modern: a joystick pad with two position bars (John Deere, Fendt, Case IH, New Holland, Valtra...)
- Classic: two mechanical lever knockers (Massey Ferguson, Landini, McCormick, Zetor...)
- Paddle: stacked rocker switches (Claas, JCB, Manitou, Kramer, Stoll, Quicke...)

It's just a HUD, so there are no gameplay changes. It works in multiplayer and each player has their own layout. You can move it, resize it, scale it, lock the style, and turn the brand logo, vehicle name or position fill on and off. Everything saves per player.

## Controls

These work while you're in a vehicle, which is where the overlay shows up. You can rebind them all in Options, Controls.

| Action | Default key | What it does |
|--------|-------------|--------------|
| Toggle overlay | `Alt + L` | Show or hide it |
| Move / resize | `Alt + K` | Edit mode: drag to move, drag the corner to resize, right click to finish |
| Cycle style | `Alt + J` | Auto, Modern, Classic, Paddle |
| Cycle position | `Alt + H` | Step through the position presets |

## Console commands

Open the console with `~` and type any of these. They work anywhere.

| Command | What it does |
|---------|--------------|
| `loaderControl` | List the commands |
| `loaderControlStatus` | Show the current loader and brand it detected |
| `loaderControlToggle` | Show or hide the overlay |
| `loaderControlScheme <0-3>` | 0 Auto, 1 Modern, 2 Classic, 3 Paddle |
| `loaderControlScale <0.6-2.0>` | Set the size |
| `loaderControlDebug` | Toggle debug logging |
| `loaderControlReset` | Reset settings to defaults |

## Install

1. Grab `FS25_LoaderControlOverlay.zip` from the Releases page.
2. Put it in your `My Games/FarmingSimulator2025/mods` folder.
3. Turn it on in the mod menu.

## Compatibility

Singleplayer and multiplayer. It works with any front loader that uses the standard `AXIS_FRONTLOADER_ARM` and `AXIS_FRONTLOADER_TOOL` controls, including most modded ones. No other mods needed.

## Languages

All 26 game languages.

## Credits

By TisonK and arissani. All rights reserved. Please don't re-upload it or claim it as your own.
