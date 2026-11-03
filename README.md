# Windows Rising

A muted olive-green, Linux-inspired "rice" for Windows 11 (build 26200, 1920×1200 at 125% scaling).
Dark olive surfaces, sage accents, frosted-glass windows, no bright cyan or RGB.

Palette:

| Role | Hex |
|---|---|
| Background | `#151A14` |
| Surface | `#20271D` / `#222A20` |
| Elevated | `#30392C` |
| Border | `#45513F` |
| Sage accent | `#93A586` |
| Highlight | `#B6C3A6` |
| Text | `#E2E6D8` |
| Secondary text | `#A9B4A0` |

## What's here

| Folder | Tool | What it does |
|---|---|---|
| `yasb/` | [YASB](https://github.com/amnweb/yasb) v2.0.7 | Top bar: START, workspaces, active window, CAVA visualizer, media controls + album art (`media` in `controls_only` mode plus `media_lite`), clock, app taskbar with grouping, tray popup, CPU / RAM / battery / volume |
| `komorebi/` | [Komorebi](https://github.com/LGUG2Z/komorebi) + [whkd](https://github.com/LGUG2Z/whkd) | Tiling window manager config and hotkeys |
| `mica/` | [Mica For Everyone](https://github.com/MicaForEveryone/MicaForEveryone) 1.3.1.2 | Dark title bars and Acrylic backdrop rules per app |
| `wezterm/` | [WezTerm](https://wezterm.org) | Olive palette, Acrylic, tabs, keybindings |
| `terminal/` | PowerShell profile + [Fastfetch](https://github.com/fastfetch-cli/fastfetch) + [oh-my-posh](https://ohmyposh.dev) | Startup screen (Firefly logo + system info) and prompt |
| `windows/` | Windows registry | Sage accent color (and a file to restore the default blue) |
| `windhawk/` | [Windhawk](https://windhawk.net) | Notes for the File Explorer styling mod |

## Install

Paths below are the ones this setup uses. Adjust them if your tools live elsewhere.

1. **YASB** — copy `yasb/config.yaml` and `yasb/styles.css` to `%USERPROFILE%\.config\yasb\`, then run `yasbc reload`.
   Needs a Nerd Font (`JetBrainsMono Nerd Font`) and the Segoe Fluent Icons font (ships with Windows 11).
2. **Komorebi / whkd** — copy `komorebi/komorebi.json`, `applications.json` and `komorebi.bar.json` to `%USERPROFILE%\.config\komorebi\`, and `komorebi/whkdrc` to `%USERPROFILE%\.config\whkdrc`.
   `komorebi.json` has one absolute path to `applications.json` with the author's username in it; edit it.
3. **Mica For Everyone** — copy `mica/MicaForEveryone.conf` next to `MicaForEveryone.exe` (this setup also keeps an identical copy in `%LOCALAPPDATA%\Mica For Everyone\`). Restart Mica For Everyone.
   The `CabinetWClass` (File Explorer) rule is deliberately set to no backdrop, because Windhawk styles Explorer instead and stacking both double-blurs it.
4. **WezTerm** — copy `wezterm/wezterm.lua` to `%USERPROFILE%\.wezterm.lua`. Requires a WezTerm build with `win32_system_backdrop` (20240203 works).
5. **Terminal startup** — copy `terminal/` to `D:\Tools\terminal\` (or edit the paths inside `profile.ps1` and `fastfetch.jsonc`), then point both PowerShell profiles at it:
   ```powershell
   ". 'D:\Tools\terminal\profile.ps1'" | Set-Content $PROFILE.CurrentUserCurrentHost
   ```
   Install Fastfetch and oh-my-posh (`winget install Fastfetch-cli.Fastfetch JanDeDobbeleer.OhMyPosh`).
6. **Accent color** — double-click `windows/accent-sage.reg`, then sign out and back in. This is per-user (HKCU) only.

## File Explorer (Windhawk)

Explorer is styled with Windhawk's official **Windows 11 File Explorer Styler** mod (v1.7.2), not a patched `explorer.exe`:

- Theme: `TintedGlass`
- Translucent background effect: `Blur (AccentBlurBehind)` (Acrylic turns flat gray when the window loses focus; this does not)

Windhawk runs elevated and stores mod settings in an admin-only registry key, so they are set in its UI: open the mod, go to **Settings**, choose the theme and effect, and save.
Disable the mod's toggle in Windhawk to revert Explorer instantly.

## The Firefly logo

`terminal/assets/firefly.png` is the source shape. `terminal/build-firefly-small.ps1` regenerates `firefly-small.txt` from it using terminal-cell-aware scaling with 2×3 sextant glyphs (`-Columns 38 -CellW 11 -CellH 27` for this setup's font and 125% scaling). Fastfetch reads `firefly-small.txt` via `file-raw`.
`profile.ps1` picks a layout from the window width: logo beside info at 106+ columns, logo above info at 66+, info only below that.

## Notes and limits

- The wallpaper is not included.
- YASB's taskbar fits about 11 distinct app buttons; beyond that icons compress. Grouping is on to help.
- The Windows accent only changes accent-driven colors (Task Manager's heat-map, selection, focus). Task Manager keeps its own native backdrop.
- Mica For Everyone has no color options; tint comes from the accent and, in Explorer, from Windhawk.

## Revert

- YASB / WezTerm / Komorebi / Mica: restore your previous config files and reload each tool.
- Accent: double-click `windows/accent-default-blue.reg`, then sign out and back in.
- Explorer: switch off the Windhawk mod (or `winget uninstall RamenSoftware.Windhawk`).
