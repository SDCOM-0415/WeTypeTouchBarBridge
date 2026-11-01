# WeType Touch Bar Bridge · v0.1 prototype

A native macOS Touch Bar prototype for WeType 3.0.0 on Intel T2 MacBook Pro. The app accesses *only the Accessibility tree* of WeType's candidate window and uses Apple's `NSCandidateListTouchBarItem` (not a drawing imitation). When a user touches a suggestion it sends the corresponding 1–9 physical number-row key to the current input method.

## Requirements

- macOS 15 or similar; 2018 Intel MacBook Pro with physical Touch Bar
- WeType 3.0.0 installed and active
- Xcode Command Line Tools (`xcode-select --install`), **full Xcode not needed**
- Accessibility permission for `WeTypeTouchBarBridge.app`

## Build and run

```bash
cd WeTypeTouchBarBridge
./build.sh
```

The built app is `build/WeTypeTouchBarBridge.app`. `build.sh` signs it locally with an ad-hoc signature and opens it. On first launch, authorize it in **System Settings > Privacy & Security > Accessibility** and then quit/restart the app. If permission remains off after rebuilding, remove the previous entry and add the newly built app.

1. Quit MTMR / BetterTouchTool if they are controlling the Touch Bar.
2. Choose WeType Pinyin as the macOS input method.
3. Type ordinary, non-sensitive sample pinyin in TextEdit.
4. Touch candidates on the Touch Bar, and verify they are selected correctly.
5. Menu-bar **候** menu lets you pause or quit. No auto-start is installed.

## What works / doesn't

- Candidate text is extracted by read-only Accessibility polling every 250ms; no hooking, injected libraries, altered WeType binary or cloud service.
- Candidate rendering uses the native `NSCandidateListTouchBarItem` with a system-modal Touch Bar call from a private API, originally explored by the open-source touch-baer / touchtest projects. Whether macOS Sequoia actually displays a background candidate item is **unverified**.
- The candidate control is intended to show only while 1–9 numbered candidates are present; other candidate modes are not yet supported.
- Selecting a candidate sends the original number key to WeType, **not** a call to WeType's private `candidateSelected` function. Special candidates that disable numerical selection will not work.
- Native rendering may need an `NSTextInputClient` to display as expected; this prototype does **not** provide one, so if the Touch Bar remains empty, that's a known blocker to address, not proof of a fully working native bridge.
- Uses private `DFRFoundation` / system-modal Touch Bar APIs. These are unstable and unsuitable for the Mac App Store. If their symbols are absent, the app shows `候!` in the menu bar and cannot display a background Touch Bar.
- No persistence, telemetry, networking, keylogging, or automatically installed launch daemon. Candidate data remain in process RAM except while rendered on the Touch Bar. Avoid typing sensitive data while it runs; Accessibility permission is powerful.
- Please build on a Mac. Source was prepared and inspected in a Linux environment and **has not been compiled or tested on macOS**.

## Troubleshooting

- `fatal error: 'Cocoa/Cocoa.h' file not found`: install Xcode Command Line Tools and select the correct developer directory.
- `No visible Touch Bar`: check if other Touch Bar apps conflict, check whether private APIs still work in your OS, and whether a client view is required by NSCandidateListTouchBarItem.
- `AX permission`: add the built `.app` (not Terminal) to Accessibility permissions and restart it.
- `Candidates not selected`: WeType doesn't guarantee numeric selection in every mode. Never assume a touch successfully committed text without verifying the target app.

## Sources of API design

- Apple NSCandidateListTouchBarItem and its delegate documentation
- [mrmekon/touchtest](https://github.com/mrmekon/touchtest) for system-modal background Touch Bar technique
- [a2/touch-baer](https://github.com/a2/touch-baer) for system tray and DFR APIs

License of original project files in this folder: MIT; upstream projects are credited for the API technique, no third-party source code copied.
