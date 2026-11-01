# WeType Touch Bar Bridge v0.3 (experimental)

Target: macOS Sequoia 15 on Intel MacBook Pro with Touch Bar, WeType 3.0.0.

## Changes

- Poll WeType Accessibility candidate window on a serial **background** queue every 100 ms instead of on the AppKit main thread every 250 ms.
- Show four candidates per Touch Bar page with previous/next buttons, including later candidates (up to those exposed as numbered 1-9 by WeType).
- Reset the page when the candidate list changes and discard candidate touches after a 1.5-second stale-data window.
- Keep native `NSCandidateListTouchBarItem`; this still depends on unsupported/private system-wide Touch Bar presentation.

## Build / run

Run `./build.sh` on the Mac (Xcode Command Line Tools required). The build script stops the prior bridge process, ad-hoc signs, and opens the app.

If Gatekeeper rejects `open`, run the built executable directly:

`./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge`

Grant Accessibility permission in System Settings > Privacy & Security > Accessibility. Menu-bar icon: 候.

## Limitations

- Built source is **not macOS-compiled/tested** in the current environment. If you hit a compiler error, capture the full terminal output.
- The hardware Touch Bar has limited horizontal space, so all candidates cannot be visible simultaneously. Use ‹ and › for other pages.
- Only WeType's visible numbered candidates are available; no hidden pages/extended candidate list.
- Key-based selection may fail for special candidates or unusual modes. Confirm with disposable text first.
- The bridge uses macOS private Touch Bar presentation API and may break on OS upgrades.
- Accessibility data is processed locally; no saved candidate text or network upload. Do not test with secrets.
