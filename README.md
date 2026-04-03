# FarmRPG Browser

A lightweight native macOS browser wrapper for [FarmRPG.com](https://farmrpg.com/). Designed to be snapped into a corner of your screen while gaming — set the transparency, pin it on top, and never forget about your farm.

Inspired by [this Reddit post](https://www.reddit.com/r/FarmRPG/comments/1s92s47/i_built_a_lightweight_browser_for_farmrpg/) describing a compact browser overlay for FarmRPG with always-on-top, transparency, and hide/show hotkey features.

## Features

- **Lightweight** — Native Swift + WKWebView using the system WebKit engine. No bundled browser, binary under 5MB.
- **Always on Top** — Pin the window above all other apps while you game.
- **Transparency Slider** — Adjust window opacity from 30% to 100% so you can see through it.
- **Global Hide/Show Hotkey** — Press `Cmd+Shift+F` from any app to toggle the window. Hide it when things get intense, bring it back when they cool off.
- **Snap to Corners** — Snap the window to any screen corner or center with one click or `Cmd+1` through `Cmd+5`.
- **Zoom Control** — Scale the page from 25% to 125% with a slider or type an exact percentage. Great for fitting FarmRPG into a small overlay.
- **Persistent Settings** — Window position, size, opacity, zoom, and always-on-top state are saved and restored across launches.
- **Collapsible Controls** — All controls live in a dropdown panel that tucks away into the titlebar when you don't need them.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+Shift+F` | Global hide/show (works from any app) |
| `Cmd+T` | Toggle always on top |
| `Cmd+1-5` | Snap to corners / center |
| `Cmd++` | Zoom in |
| `Cmd+-` | Zoom out |
| `Cmd+0` | Reset zoom to 100% |
| `Cmd+R` | Reload page |
| `Cmd+[` / `Cmd+]` | Back / Forward |

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+

## Build & Run

```bash
# Clone the repo
git clone https://github.com/EmeraldPi/farmrpg-browser.git
cd farmrpg-browser

# Build and run (debug)
swift build && swift run

# Or build a release .app bundle
./bundle.sh
open "FarmRPG Browser.app"

# Install to Applications
cp -r "FarmRPG Browser.app" /Applications/
```

## Disclaimer

This entire project was vibecoded with [Claude Code](https://claude.ai/claude-code). Every line of Swift, every menu item, every constraint — all of it generated through conversation with an AI. Use at your own risk, and maybe don't look too closely at the code.
