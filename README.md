# WeType Touch Bar Bridge v0.6 — Native-style candidate highlight

Based on the **working v0.5** implementation. This release **only changes candidate appearance**:

- Keep the background AX reader, 100ms poll, variable-width `NSScrubber` cells and numeric key selection.
- Add a continuous blue-gray surface with 9pt corner radius to the scrubber.
- Give the **first candidate** a brighter rectangular highlight while the remaining candidates blend into the shared surface.
- Reapply candidate styling whenever `NSScrubber` recycles a cell.
- Menu-bar version marker is **候6** and logs use `[Perf] v0.6`.

## Build and run (MacBook Pro with Touch Bar)

```bash
cd ~/Downloads/WeTypeTouchBarBridge-v0.6
chmod +x build.sh
./build.sh
```

`build.sh` stops older processes with the same executable name. If Gatekeeper blocks opening an ad-hoc signed app, run the executable from the project folder:

```bash
./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge
```

Grant the freshly built application Accessibility permission if macOS asks.

## Implementation note

The native Apple Chinese IME has an internal visual style not exposed as a stable public API. These RGB values are an **approximation** to the user's Touch Bar screenshot; this project uses AppKit layer-backed views. Native hardware screenshot and macOS build verification are still required. The selected first candidate background might differ in precise dimensions from Apple's version.

## Troubleshooting

If a Touch Bar item is still black, inspect whether `NSScrubber` or `NSScrubberTextItemView` is overriding the layer appearance on your macOS build. That can be addressed by a custom `NSScrubberItemView` with its own child label and drawn background. Do not change AX polling to fix a visual issue.

