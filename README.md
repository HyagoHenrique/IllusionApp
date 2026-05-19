# IllusionApp

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

## Install (pre-built release)

1. Download `IllusionApp-vX.Y.Z.zip` from the [Releases page](https://github.com/HyagoHenrique/IllusionApp/releases)
2. Unzip and move `IllusionApp.app` to `/Applications`
3. Authorize Gatekeeper (see below) — required because the release builds are unsigned
4. Grant **Screen Recording** permission when prompted (System Settings → Privacy & Security → Screen Recording)

### Gatekeeper / "app is damaged or can't be opened"

The release builds are **unsigned** (ad-hoc signature only) because notarization requires a paid Apple Developer account. macOS will block the app on first launch with one of these messages:

- *"IllusionApp" cannot be opened because the developer cannot be verified*
- *"IllusionApp" is damaged and can't be opened*

**To authorize the app:**

**Option A — Right-click → Open (easiest)**
1. In Finder, right-click (or Control-click) on `IllusionApp.app`
2. Choose **Open**
3. Click **Open** in the warning dialog
4. macOS remembers the choice; future launches work normally

**Option B — System Settings**
1. Try to open the app once (macOS will block it)
2. Open **System Settings → Privacy & Security**
3. Scroll down to the *Security* section — there will be a message about IllusionApp being blocked
4. Click **Open Anyway**
5. Confirm with your password

**Option C — Terminal (if you see "is damaged")**
The "damaged" message appears because of the quarantine attribute set when downloading from the browser. Remove it:
```bash
xattr -dr com.apple.quarantine /Applications/IllusionApp.app
```
Then open the app normally.

> **Why unsigned?** Notarizing requires Apple's Developer Program ($99/year). If you want a notarized build, clone the repo and build it yourself in Xcode with your own signing identity.

## Building

1. Open `IllusionApp.xcodeproj` in Xcode 15+
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
IllusionApp/
├── App/
│   ├── IllusionApp.swift        Entry point, connects AppDelegate
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
