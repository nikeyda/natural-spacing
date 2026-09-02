# macOS host adapter audit — 2026-09-02

This record captured automated native-control evidence before the first Git commit; see the [publication readiness audit](publication-readiness-2026-09-02.md) for the current public repository and CI state. It is not real-input-source, dictation, accessibility, or application-release acceptance.

## Environment

- Host: Apple silicon Mac
- macOS: 26.5.2 (25F84)
- Xcode: 26.6 (17F113)
- Swift: 6.3.3
- Package deployment floor: macOS 10.15

## Command

```sh
swift test
```

## Results

| Test bundle | Result | Covered behavior |
|---|---:|---|
| `NaturalSpacingCoreTests` | 13/13 | Shared rules, sessions, policy recommendation, text updates, ordered ASR/dictation lifecycle and revisions, proposed edits, and all 766 Unicode 17 grapheme cases |
| `NaturalSpacingAppKitTests` | 11/11 | `NSTextView`, ASCII-digit insertion through an `NSTextField` field editor in an `NSWindow`, selection mapping, marked-text deferral and settled reconciliation, deletion suppression and edit-lifecycle reset, native undo, native change notification, multi-range fail-open, and fail-open behavior for direct and post-edit reconciliation when a host delegate rejects the validated replacement |
| `NaturalSpacingSwiftUITests` | 4/4 | Wrapper construction, default `verbatim`, direct transformed-edit binding publication, and settled `textDidChange` reconciliation into the binding |
| Total | 28/28 | XCTest bundles executed on the macOS host |

## Manual acceptance host compile

Command:

```sh
swift build \
  --package-path examples/acceptance/macos \
  --scratch-path /tmp/natural-spacing-macos-acceptance-build
```

The executable imports the public Core, AppKit, and SwiftUI products. Its
AppKit tab exposes policy, marked text, selection, last plan, text, and reset;
its SwiftUI tab embeds public `NaturalSpacingTextEditor` message/code bindings
with automatic natural-language/verbatim recommendation diagnostics.

The Swift 6.3.3 build completed successfully at the package's macOS 10.15
deployment floor. The executable was not launched, so no input source,
composition, focus, window lifecycle, dictation, or accessibility behavior is
claimed from this result.

## Remaining gates

- real Pinyin and another named input source, including commit and cancellation;
- dictation, VoiceOver input, paste UI, hardware-keyboard variations, and autofill where applicable;
- actual application focus, field-editor reuse, external binding restoration, window lifecycle, and accessibility behavior;
- supported macOS and Apple toolchain matrix.
