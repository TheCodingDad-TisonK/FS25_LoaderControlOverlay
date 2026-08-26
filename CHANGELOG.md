# Changelog

All notable changes to FS25 Loader Control Overlay are documented here.

## [1.0.1.0] - 2026-08-26

- Settings panel (Alt+O) sizing fixed so nothing clips, and the Alt+O binding now works in the on-foot context too.
- Full 26-language localization for the settings panel.

## [1.0.0.0] - Initial release

- Live front-loader control overlay that reads the loader's moving tools each frame
  (arm height + tool curl position, and the active command direction).
- Three brand-aware control styles, drawn procedurally:
  - **Modern** — joystick command pad + twin position bars.
  - **Classic** — twin mechanical lever "knockers".
  - **Paddle** — stacked rocker switches.
- Authentic in-game brand badge in the header.
- Optional third-function (AUX) indicator when the loader exposes one.
- Edit mode: drag to move, drag the corner to resize; layout saved per player.
- Position presets, scale, style override, and toggles for the brand badge,
  vehicle name, and position fill.
- In-game settings panel (Alt+O) with all options grouped and saved per player.
- Hotkeys (Alt+L / Alt+K / Alt+J / Alt+H / Alt+O) and a full set of console commands.
- Client-side and multiplayer-friendly. No gameplay changes, no dependencies.
- 26-language localization.
