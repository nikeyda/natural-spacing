# iOS UIKit and SwiftUI manual acceptance host

This storyboard-free application imports `NaturalSpacingCore`,
`NaturalSpacingUIKit`, and `NaturalSpacingSwiftUI` through the repository's
public SwiftPM products. It contains two tabs:

- UIKit: a message `UITextView`, secure `UITextField`, effective policy,
  recommendation, selection, marked-text range, last-plan decision, and reset;
- SwiftUI: public `NaturalSpacingTextEditor` message and code fields resolving
  to `naturalLanguage` and `verbatim`, recommendation/binding diagnostics, and
  reset.

Password diagnostics never render the field value. Use synthetic input only.

## Compile

```sh
bash scripts/test-ios-acceptance-host.sh
```

The command builds an iOS Simulator `.app` through a local SwiftPM dependency
without development-team signing. Xcode may add its linker-generated ad-hoc
signature. The command does not boot a simulator, install the app, or launch it.

## Manual matrix

After separately authorizing installation and launch, compare both tabs with
system Pinyin,
composition commit/cancel, a representative third-party keyboard, dictation,
hardware keyboard, forward/backward selection, paste, manual automatic-space
deletion, reset, undo/redo, VoiceOver input, and password autofill. Record the
actual OS, device, input source, scenarios, and result according to
[`docs/platform-acceptance.md`](../../../docs/platform-acceptance.md).
