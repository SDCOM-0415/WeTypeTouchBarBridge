# WeType Touch Bar Bridge

Bring a native-style candidate bar to the MacBook Pro Touch Bar while using **WeType / 微信输入法** on macOS.

> Independent community project, not affiliated with Tencent or Apple. Currently tested by the project user on an Intel Touch Bar MacBook Pro running macOS Sequoia. This repository contains **source code**, not a notarized binary.

![Touch Bar candidate interface](docs/touchbar-v0.7.png)

## Features (v0.7)

- Read current WeType candidate text through the macOS Accessibility API.
- Show interactive candidates on the Touch Bar using an AppKit `NSScrubber`.
- Measure each candidate's actual text width, with horizontal scrolling for overflow.
- Native-inspired continuous background and highlighted first candidate.
- **Right-aligned candidate group**, next to the macOS Control Strip area.
- Touch to choose a candidate (mapped to the corresponding WeType numeric selection key).
- Background AX polling with performance diagnostics.

## Requirements

- Intel Mac with a physical Touch Bar (tested on a 2018 13-inch MacBook Pro).
- macOS with AppKit Touch Bar support (tested on macOS Sequoia).
- WeType installed and enabled (`com.tencent.inputmethod.wetype`).
- Xcode Command Line Tools (`xcode-select --install`).
- Accessibility permission for the built helper app (and potentially the terminal used to launch it).

## Build and run

```bash
chmod +x build.sh
./build.sh
```

The script compiles the app with `xcrun clang`, ad-hoc signs it, and attempts to open the resulting bundle:

```text
build/WeTypeTouchBarBridge.app
```

Because this is an ad-hoc-signed, unnotarized development build, macOS may refuse to launch it through Finder. If needed, start the executable directly from Terminal:

```bash
./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge
```

Grant Accessibility permissions in **System Settings → Privacy & Security → Accessibility**. A menu bar item marked **候7** can be used to diagnose the Touch Bar display.

## How it works

1. Discover the WeType input-method process.
2. Read its accessible candidate window using `AXUIElement`.
3. Update the Touch Bar on the main thread when the candidate data changes.
4. Render variable-width, right-aligned candidate views; selection sends the corresponding number key to WeType.

The helper uses **undocumented Touch Bar system-modal APIs** to present a background app's Touch Bar content. They may change or stop working after macOS updates. This approach is not guaranteed to work with every input method version or every app.

## Privacy and limitations

- Accessibility access may expose text currently being composed. The app is designed for local use; examine its source and permissions before running it.
- Diagnostic logs may contain metadata about candidate updates. Avoid sharing detailed logs containing private text.
- Candidate selection currently simulates numeric keys; it depends on WeType's visible candidate numbering, and can fail if candidate ordering/keys change.
- No notarized or universally compatible binary is provided.
- The source was iterated with automated assistance; it has been user-tested on one setup, not validated on a broad macOS matrix.

## License

MIT. See [LICENSE](LICENSE).
