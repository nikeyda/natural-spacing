# iOS Simulator adapter audit — 2026-09-02

This record is automated simulator evidence, not real-keyboard, real-device, dictation, accessibility, or third-party-IME acceptance.

## Environment

- Host: Apple silicon macOS
- Xcode: 26.6 (build 17F113)
- Test destination: iPhone Air Simulator
- Simulator runtime: iOS 26.4 (23E244)
- Build SDK: iPhoneSimulator 26.5
- Package deployment floor: iOS 13

## Command

```sh
bash scripts/test-ios-simulator.sh
```

The script selects the first available iPhone Simulator at runtime rather than pinning a machine-specific UDID.

## Results

| Test bundle | Result | Covered behavior |
|---|---:|---|
| `NaturalSpacingCoreTests` | 13/13 | Shared rules, sessions, policy recommendation, ASR/text updates, ordered ASR/dictation lifecycle and revisions, proposed edits, and all 766 Unicode 17 grapheme cases |
| `NaturalSpacingUIKitTests` | 9/9 | ASCII-digit insertion through `UITextField`, `UITextView`, selection mapping, two-sided replacement, deleted-space suppression, edit-lifecycle deletion-intent reset, programmatic-value synchronization, UTF-16 length limit, `.verbatim`, `isSecureTextEntry` forcing `verbatim`, and iOS 26 multi-range fail-open |
| `NaturalSpacingSwiftUITests` | 3/3 | Wrapper construction, default `verbatim`, and coordinator publication of a transformed `UITextView` edit into its binding |
| Total | 25/25 | XCTest bundles executed in the iOS Simulator process |

The resulting `xcresult` was generated under the temporary derived-data directory and is not a committed artifact.

## Manual acceptance host compile

Command:

```sh
bash scripts/test-ios-acceptance-host.sh
```

The storyboard-free application imports the public `NaturalSpacingCore`,
`NaturalSpacingUIKit`, and `NaturalSpacingSwiftUI` SwiftPM products. Its UIKit
tab uses message and password fields with automatic policy resolution and
exposes recommendation confidence/source/reason, selection, marked-text range,
and last-plan diagnostics without rendering the password value. Its SwiftUI tab
uses the public `NaturalSpacingTextEditor` for automatically resolved message
and code fields and exposes recommendation plus binding publication for manual
comparison with UIKit.

The Xcode 26.6 build produced a valid iOS Simulator `.app` for both arm64 and
x86_64, with bundle ID `dev.naturalspacing.acceptance.ios` and minimum iOS 13.
Development-team signing was disabled; Xcode emitted only its linker-generated
ad-hoc signature. The app was not installed or launched, so this remains compile
evidence rather than real-input evidence.

## Remaining gates

- system Pinyin and representative third-party keyboards;
- actual marked-text composition, commit, cancellation, and undo;
- hardware keyboard, paste UI, dictation, VoiceOver input, and autofill;
- supported iOS version and physical-device matrix;
- application lifecycle, focus, reuse, and external binding restoration beyond the focused simulator tests.
