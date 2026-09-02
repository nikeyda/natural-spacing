# Manual real-input acceptance hosts

These applications make the experimental platform adapters observable during
manual keyboard, IME, dictation, hardware-keyboard, and accessibility-input
testing. They use only public source dependencies.

| Surface | Host | Compile command |
|---|---|---|
| UIKit + SwiftUI | [`ios`](ios/README.md) | `bash scripts/test-ios-acceptance-host.sh` |
| AppKit + SwiftUI | [`macos`](macos/README.md) | `swift build --package-path examples/acceptance/macos --scratch-path /tmp/natural-spacing-macos-acceptance-build` |
| Android Views + Compose | [`android`](android/README.md) | `bash scripts/test-android-acceptance-host.sh` |
| Flutter | [`flutter`](flutter/README.md) | `bash scripts/test-flutter-target-builds.sh` |
| Web | [`../web`](../web/README.md) | `npm run test:browser` |
| WinUI 3 | [`windows-winui`](windows-winui/README.md) | `bash scripts/test-windows-winui-acceptance-host.sh` |
| WPF | [`windows-wpf`](windows-wpf/README.md) | `bash scripts/test-windows-wpf-acceptance-host.sh` |

Compilation keeps a harness from drifting away from the public API. It is not
real-input evidence. Run the named matrix on the actual OS/device/input source,
use only synthetic text, and record `not run`, `pass`, `fail`, or `blocked`
according to [`docs/platform-acceptance.md`](../../docs/platform-acceptance.md).

Installing, launching, changing an input source, granting accessibility
permissions, and collecting a recording are separate actions from these build
commands.
