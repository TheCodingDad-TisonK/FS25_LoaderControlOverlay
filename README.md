<div align="center">

# 🚜 FS25 Loader Control Overlay
### *Your Loader, Brand by Brand*

[![Downloads](https://img.shields.io/github/downloads/TheCodingDad-TisonK/FS25_LoaderControlOverlay/total?style=for-the-badge&logo=github&color=4cbeff&logoColor=white)](https://github.com/TheCodingDad-TisonK/FS25_LoaderControlOverlay/releases)
[![Release](https://img.shields.io/github/v/release/TheCodingDad-TisonK/FS25_LoaderControlOverlay?style=for-the-badge&logo=tag&color=4cbeff&logoColor=white)](https://github.com/TheCodingDad-TisonK/FS25_LoaderControlOverlay/releases/latest)
[![License](https://img.shields.io/badge/license-CC%20BY--NC--ND%204.0-lightgrey?style=for-the-badge&logo=creativecommons&logoColor=white)](https://creativecommons.org/licenses/by-nc-nd/4.0/)
<a href="https://paypal.me/TheCodingDad">
  <img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="Donate via PayPal" height="50">
</a>

<br>

> *"Climbed out of the old Massey and into a brand-new Deere and spent the first ten minutes hunting for the loader lever. Every cab is laid out different. By the time I found it I'd already dumped half a bucket of silage on the yard."*

<br>

**Every tractor handles its loader a little differently. This overlay shows you which one you're driving.**

A live on-screen panel that reads your front loader's actual moving parts and animates them as you work. Raise, lower, curl and dump, and the overlay moves with you. The control style restyles itself to match the tractor brand, and it wears the real brand badge straight from the game.

`Singleplayer` • `Multiplayer` • `Client-side HUD` • `No dependencies` • `26 languages`

</div>

> [!TIP]
> Driving a brand the overlay styles "wrong" for your taste? Tap **Alt+J** to cycle the style by hand: Auto → Modern → Classic → Paddle. Your choice sticks.

> [!NOTE]
> This is a HUD and nothing more. It reads loader state and draws it. It never touches gameplay, physics, or your loader's behaviour, so it is safe to run in multiplayer and alongside anything else.

---

## 🆕 What's New in v1.0.0.0

**New:**
- Live front-loader overlay that reads the loader's moving tools every frame, showing real arm height and bucket angle plus the direction you are commanding right now
- Three brand-aware control styles, drawn entirely in code: **Modern** joystick pad, **Classic** lever knockers, **Paddle** rocker switches
- The authentic in-game brand badge in the panel header
- Optional third-function (AUX) row when the loader exposes one
- Edit mode: drag to move, drag the corner to resize, layout saved per player
- Position presets, scale, style override, and toggles for the badge, vehicle name and position fill
- Hotkeys plus a full set of console commands
- 26-language localization

---

## ✨ Features

### 🕹️ Live Loader Readout

The overlay reads the loader's moving tools directly every frame, so it shows two things at once:

| Reading | Where it comes from | What you see |
|---|---|---|
| **Position** | The arm and tool's actual angle | How high the arm is and how far the bucket is curled, right now |
| **Command** | The input you are feeding the loader | A glow in the direction you are pushing: raise/lower, curl/dump |

Because it reads the loader itself and not just your keypress, it works the same whether you drive on **keyboard**, **controller**, or hand the job to an **AI worker**.

### 🎨 Brand-Aware Styles

The widget restyles itself based on the tractor's brand. Each style is drawn from scratch, so there are no blurry textures and it stays crisp at any resolution.

| Style | Looks like | Fits brands such as |
|---|---|---|
| 🔵 **Modern** | A joystick command pad with twin position bars | John Deere, Fendt, Case IH, New Holland, Valtra, Deutz-Fahr, Kubota, Steyr |
| 🟠 **Classic** | Two mechanical lever "knockers" in a gated slot | Massey Ferguson, Landini, McCormick, Zetor, Ursus, Belarus |
| 🟢 **Paddle** | Stacked rocker switches that glow on the active side | Claas, JCB, Manitou, Merlo, Kramer, Weidemann, Stoll, Quicke |

Anything the overlay does not recognise falls back to Modern, and you can always override the choice yourself with **Alt+J** or the `loaderControlScheme` command.

### 🏷️ Real Brand Badge

The header shows the genuine brand logo pulled from the game's own brand list, so a Fendt loader wears the Fendt badge and a Claas wears Claas. Turn it off if you prefer a cleaner panel.

### 🖱️ Make It Yours

| Tweak | How |
|---|---|
| **Move it** | Alt+K, then drag |
| **Resize it** | Alt+K, then drag the corner |
| **Pin a corner** | Alt+H cycles the position presets |
| **Lock a style** | Alt+J, or `loaderControlScheme 0-3` |
| **Scale it** | `loaderControlScale 0.6-2.0` |
| **Hide the badge / name / fill** | Settings, saved per player |

Every preference is stored per player in your `modSettings` folder, so it follows you between savegames and survives a reconnect on a dedicated server.

---

## 🎮 Controls

Active while you are seated in a vehicle, which is where the overlay lives. All keys are rebindable in **Options → Controls**.

| Action | Default | What it does |
|---|---|---|
| **Toggle overlay** | `Alt + L` | Show or hide it |
| **Move / resize** | `Alt + K` | Edit mode: drag to move, drag the corner to resize, right click to finish |
| **Cycle style** | `Alt + J` | Auto → Modern → Classic → Paddle |
| **Cycle position** | `Alt + H` | Step through the position presets |

---

## 🖥️ Console Commands

Open the console with **`~`** and type `loaderControl` for the list. These work anywhere.

| Command | Arguments | Description |
|---|---|---|
| `loaderControl` | — | List the commands |
| `loaderControlStatus` | — | Show the loader and brand it detected |
| `loaderControlToggle` | — | Show or hide the overlay |
| `loaderControlScheme` | `0` `1` `2` `3` | Auto / Modern / Classic / Paddle |
| `loaderControlScale` | `0.6` – `2.0` | Set the panel size |
| `loaderControlDebug` | — | Toggle verbose logging |
| `loaderControlReset` | — | Reset all settings to defaults |

---

## 🚀 Quick Start

```
1. Attach a front loader to any tractor and climb in
2. The overlay appears, styled for that brand, wearing its badge
3. Work the loader — the arm and bucket on screen move with yours
4. Push raise/lower or curl/dump — watch the active side glow
5. Alt+K to drag it somewhere comfortable, drag the corner to size it
6. Alt+J if you want a different control style
7. Jump into another brand and watch the panel change to match
```

> [!TIP]
> The position fill (how high the arm sits) needs a loader that reports its arm angle. Almost all base-game and most modded loaders do. If a loader only feeds the overlay command and not position, you still get the live direction glow.

---

## 🛠️ Installation

**1. Download** `FS25_LoaderControlOverlay.zip` from the [latest release](https://github.com/TheCodingDad-TisonK/FS25_LoaderControlOverlay/releases/latest).

**2. Copy** the ZIP (do not extract) into your mods folder:

| Platform | Path |
|---|---|
| 🪟 Windows | `%USERPROFILE%\Documents\My Games\FarmingSimulator2025\mods\` |
| 🍎 macOS | `~/Library/Application Support/FarmingSimulator2025/mods/` |

**3. Enable** *Loader Control Overlay* in the in-game mod manager.

**4. Drive** any tractor with a front loader. The overlay does the rest.

---

## 🤝 Compatibility

| Area | Status |
|---|---|
| 🎮 **Singleplayer** | Fully supported |
| 🌐 **Multiplayer** | Fully supported. The overlay is client-side, so every player has their own layout and nothing is synced |
| 🚜 **Loaders** | Works with any loader that uses the standard `AXIS_FRONTLOADER_ARM` and `AXIS_FRONTLOADER_TOOL` controls, including most modded loaders |
| 🧩 **Other mods** | No dependencies and no gameplay hooks, so it plays nicely with everything |

---

## 💬 Community

> [!TIP]
> Want to share ideas, request a brand style, or report something odd? Join the **[FS25 Modding Community Discord](https://discord.gg/Th2pnq36)**.

Found a bug? [Open an issue](https://github.com/TheCodingDad-TisonK/FS25_LoaderControlOverlay/issues/new/choose) and the template will walk you through what to include.

---

## 📝 License

This mod is licensed under **[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/)**.

You may share it in its original form with attribution. You may not sell it, modify and redistribute it, or reupload it under a different name or authorship.

**Authors:** TisonK &nbsp;·&nbsp; arissani &nbsp;·&nbsp; **Version:** 1.0.0.0

© 2026 TisonK and arissani — See [LICENSE](LICENSE) for full terms.

---

<div align="center">

*Farming Simulator 25 is published by GIANTS Software. This is an independent fan creation, not affiliated with or endorsed by GIANTS Software.*

*Every loader, at a glance.* 🚜

</div>
