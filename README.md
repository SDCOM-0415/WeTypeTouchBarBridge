# WeType Touch Bar Bridge v0.4 — Native candidate sizing

This experimental version removes v0.3 manual pagination and fixed four-candidate pages.
It sends the entire visible WeType candidate array to `NSCandidateListTouchBarItem`, letting
macOS choose candidate width from the rendered content and manage clipping/scrolling.

## Build

On the Intel Mac: `./build.sh`. If Finder is blocked, run
`./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge`.

Requires Accessibility permission for this new app path, macOS 15, WeType 3.0.0,
Touch Bar hardware, and Xcode Command Line Tools.

## Known constraints

- The candidate list's actual size and scrolling remain controlled by AppKit.
- Only candidates currently exposed in WeType's accessibility window are copied.
- Touch-to-select sends the matching numbered key, and special candidates may differ.
- Uses unsupported/private macOS system modal Touch Bar presentation.
- **Not compiled or tested on macOS in the build environment.**
- Treat input data as private; the app reads candidates in memory only.
