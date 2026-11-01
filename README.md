# WeType Touch Bar Bridge v0.2 — diagnostics prototype

Source-only experiment for **MacBook Pro 2018 Touch Bar / macOS Sequoia / WeType 3.0.0**. No macOS test machine is available in this environment, so build/runtime behavior has **not** been verified. The app uses unsupported private system-modal Touch Bar APIs, which may not work on newer macOS releases.

## Run

1. Quit MTMR, BetterTouchTool and other Touch Bar customizers completely.
2. In Terminal, `cd WeTypeTouchBarBridge && ./build.sh` (Xcode Command Line Tools required).
3. In macOS System Settings → Privacy & Security → Accessibility, authorize the **newly built** `build/WeTypeTouchBarBridge.app` and relaunch it. If there are stale entries, remove and re-add the app.
4. Click the **候** menu-bar icon and select **强制测试 Touch Bar（显示测试按钮）**. This must show `WeType Bridge: Touch Bar OK` without any typing if private modal display works; touching the test button closes the test.
5. Inspect the disabled `状态：...` menu entry: it distinguishes no AX permission, missing WeType process, and candidates detected.
6. Type `nihao` in a plain editor using WeType (not a password field), then check the Touch Bar.

## Diagnostic interpretation

- **Test button does not appear**: private system-modal display or competing app is the main blocker; reading more WeType symbols will not help.
- **Test button works, candidate display does not**: likely native `NSCandidateListTouchBarItem` client/visibility behavior. This widget is designed for a text input view and might not render inside a standalone background app.
- **No candidates according to status**: Accessibility permission, process or candidate parsing issue.
- **Candidate display works but selecting doesn't**: numeric key selection is limited and cannot be assumed to work for all candidate types.

## Logging

Run from Terminal after build:

```bash
./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge 2>&1 | tee /tmp/wetype-touchbar-diagnostic.log
```

Avoid entering sensitive text while logging, because the current debug log includes the first candidate. Stop with Ctrl+C; logs remain local.

## Technical scope

The project reads WeType candidate labels via macOS Accessibility and attempts to present Apple's native `NSCandidateListTouchBarItem` via an undocumented system-modal selector. It does not alter WeType or read its memory. There is no persistence, cloud or network layer. `NSTouchBar` normally belongs to the frontmost app, and `NSCandidateListTouchBarItem` may need a real `NSTextInputClient`: neither requirement is magically solved by using the private modal API. If test presentation fails on Sequoia, this approach needs a redesign; it is **not** a finished native Touch Bar integration.
