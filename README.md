# ScreenMirror

A macOS app that mirrors any region of your screen into a floating, always-on-top window.

## Features

- **Region selection** — drag to pick any area of the screen
- **Floating mirror window** — stays above all other apps, freely positionable and resizable
- **Multiple mirrors** — up to 6 simultaneous mirror windows
- **Opacity control** — 10% / 25% / 50% / 75% / 100%
- **Lock mode** — locks position/size and makes clicks pass through. Unlock all via menu bar (⌘U)
- **60 fps capture** — powered by ScreenCaptureKit's SCStream

## Requirements

- macOS 14 Sonoma or later
- Screen Recording permission (the system will prompt on first launch)

## Building

1. Open `ScreenMirror.xcodeproj` in Xcode 15+
2. Select your development team in *Signing & Capabilities*
3. Build & Run (`⌘R`)

> **Note:** The app sandbox is disabled so ScreenCaptureKit can capture other apps' content. For Mac App Store distribution you would need to enable the sandbox and use the `com.apple.security.screen-capture` entitlement instead.

## Usage

1. Click the **rectangle-on-rectangle** icon in the menu bar
2. Choose **Mirror a region…** (`⌘M`)
3. Drag to select the area you want to mirror
4. The mirror window appears — drag it anywhere, resize freely
5. Hover the mirror to reveal controls:
   - **Eye** — opacity
   - **Open lock** — lock the window (clicks pass through, position frozen)
   - **✕** — close the mirror
6. To unlock all locked mirrors: menu bar → **Unlock all screens** (`⌘U`)

## Architecture

```
ScreenMirror/
├── App/
│   ├── ScreenMirrorApp.swift        Entry point, connects AppDelegate
│   └── AppDelegate.swift            Status bar, orchestrates selection → mirror flow
├── Features/
│   ├── Selection/
│   │   ├── SelectionOverlayWindow   Fullscreen NSWindow for the drag-select UI
│   │   └── SelectionView            SwiftUI drag gesture + visual feedback
│   ├── Mirror/
│   │   ├── MirrorWindow             NSWindow subclass (floating level, click-through)
│   │   ├── MirrorView               Renders frames + hover controls
│   │   └── MirrorViewModel          Drives capture lifecycle, CMSampleBuffer → CGImage
│   └── Capture/
│       └── ScreenCaptureManager     SCStream wrapper, publishes frames as AsyncStream
└── Shared/
    ├── Models/MirrorRegion          Value type: rect + displayID
    └── Extensions/CGRect+Extensions Coordinate system conversions
```

## License

MIT — see [LICENSE](LICENSE).
