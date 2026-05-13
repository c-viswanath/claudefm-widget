<div align="center">
  <img src="icon_preview.png" width="120" alt="Claude FM icon" />
  <h1>Claude FM Widget</h1>
  <p>A minimal floating macOS widget that plays the <a href="https://www.youtube.com/watch?v=YmQ7jRgf4f0">Claude FM</a> 24/7 lo-fi live stream — music for thinking & building.</p>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" />
</div>

---

## Install (easiest — no Xcode needed)

### 1. Download the DMG

Grab **`ClaudeFM.dmg`** from the [latest release](../../releases/latest).

### 2. Open the DMG and drag to Applications

Double-click the DMG → drag **Claude FM** into the **Applications** folder.

### 3. First-launch: bypass Gatekeeper

Because the app is ad-hoc signed (not notarized), macOS will block it on the first open.
Pick **one** of these two ways to fix it:

**Option A — Right-click method (no Terminal needed)**
> Right-click `Claude FM.app` in Applications → **Open** → click **Open** in the dialog.
> You only need to do this once.

**Option B — Terminal (one command)**
```bash
xattr -rd com.apple.quarantine /Applications/ClaudeFM.app
```

Then just double-click the app normally from now on.

---

## What it does

| Feature | Detail |
|---|---|
| Always-on-top | Floats above all windows and Spaces |
| No Dock icon | Lives quietly in the background |
| Minimal UI | Live badge · stream title · close button |
| Draggable | Click & drag from the bottom bar |
| Quit | Click `×` or press `Cmd+Q` |

---

## Build from source

**Requirements:** macOS 13+, Xcode Command Line Tools, Python 3 + Pillow (for the icon)

```bash
# Clone
git clone https://github.com/c-viswanath/claudefm-widget.git
cd claudefm-widget

# Install icon dependency (first time only)
pip3 install pillow

# Run directly
./run.sh

# — or — build a distributable DMG
./package.sh
```

---

## Project structure

```
claudefm-widget/
├── Sources/ClaudeFMWidget/
│   ├── main.swift            # entry point, no Dock icon
│   ├── AppDelegate.swift     # floating NSPanel setup
│   ├── ContentView.swift     # SwiftUI UI (live badge, bottom bar)
│   └── YouTubePlayerView.swift # WKWebView embedding Claude FM
├── create_icon.py            # generates AppIcon.icns from pixel art
├── package.sh                # builds .app bundle + .dmg
├── run.sh                    # quick launch for development
└── Package.swift
```

---

## License

MIT
