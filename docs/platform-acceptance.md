# Platform acceptance protocol

This document records the evidence required before an adapter moves from `experimental` to `supported`. Core conformance, SDK compilation, simulator testing, and real-input acceptance are separate proof levels.

## Evidence levels

| Level | Meaning | Examples |
|---|---|---|
| Core | Pure rules and edit contracts match shared fixtures | `npm test`, Swift/Kotlin/C#/Dart conformance |
| Compile | Adapter builds against a named SDK | UIKit SDK build, Android API build, Windows App SDK build |
| Automated host | Native control tests run without a real input method | AppKit selection and undo tests |
| Real input | Named keyboard, IME, dictation, or assistive input passes on a named OS/device | Gboard composition, Microsoft Pinyin, macOS Pinyin, iOS dictation |

Only the last level can support a claim about a real input source. Record `not run`, `pass`, `fail`, or `blocked`; never infer `pass` from a lower level.

## Common scenarios

Every editable adapter must cover these synthetic scenarios:

1. Type Han then Latin, and Latin then Han.
2. Type Han then ASCII digit, and ASCII digit then Han.
3. Keep active composition unchanged; reconcile only after a settled commit.
4. Delete an automatic space and confirm it stays suppressed until the adjacent boundary changes or the session resets.
5. Replace a selection that creates eligible boundaries on both sides.
6. Preserve forward and backward selection direction.
7. Paste mixed text and scan only the fragment plus its two outer boundaries.
8. Respect the UTF-16 maximum without partially applying spaces.
9. Preserve native undo/redo as one user-visible edit transaction.
10. Handle programmatic reset, blur/focus, reuse, and adapter disposal without stale suppression state.
11. Keep secure/password controls `verbatim` even if natural-language behavior is configured accidentally.
12. Verify accessibility input, hardware keyboard, and dictation/speech separately where the platform exposes them.

Use only synthetic text. Do not retain real user input, audio, keyboard telemetry, credentials, or proprietary application logs.

## Platform matrix

| Surface | Minimum real-input coverage before support | Current status |
|---|---|---|
| UIKit | Supported iOS versions; system Pinyin, hardware keyboard, dictation, paste, representative third-party keyboard, VoiceOver input | Automated simulator only: 9 adapter tests pass on iPhone Air/iOS 26.4, including secure-text fail-safe behavior, programmatic-value synchronization, and edit-lifecycle deletion-intent reset. A combined UIKit/SwiftUI acceptance app imports the public SwiftPM products, exposes resolved-policy/recommendation/selection/composition/decision diagnostics, and compiles as an arm64+x86_64 Simulator app; it has not been installed or launched. No real input source or physical-device run |
| SwiftUI on iOS | UIKit matrix plus binding publication, external binding reset, SwiftUI lifecycle, and focus changes | Automated simulator only: construction, default `verbatim`, and transformed binding publication pass. The combined acceptance app has real public-wrapper message/code editors with automatic policy recommendation/resolution and binding diagnostics for comparison with UIKit; it has compiled but not launched. No real input source, lifecycle matrix, or physical-device run |
| AppKit | Supported macOS versions; Pinyin and another input source, `NSTextView`, `NSTextField` field editor, dictation, VoiceOver, undo | Automated host only: 11 adapter tests pass on macOS 26.5.2, including a real `NSWindow` field editor, native undo/notification, marked-text settlement, deletion-intent lifecycle reset, multi-range fail-open, and fail-open behavior for direct and post-edit reconciliation when the host rejects a validated replacement. A combined AppKit/SwiftUI manual host compiles against the public Swift products; its AppKit tab exposes policy, marked text, selection, decision, and current text. Its existence is not real-input evidence. No real input source, dictation, VoiceOver, or supported-version matrix has run. |
| SwiftUI on macOS | AppKit matrix plus binding publication, external binding reset, SwiftUI lifecycle, and focus changes | Automated host only: construction, default `verbatim`, and direct/settled binding publication pass. The combined host includes real public-wrapper message/code editors with automatic policy recommendation and binding diagnostics; it has compiled but not launched. No real input source, external restoration, lifecycle, focus, or accessibility matrix |
| Web/React | Chrome, Safari, Firefox; desktop IME, mobile IME where supported, controlled/uncontrolled React, autofill, screen reader | Automated browser only: twelve native/end-to-end plus three React 19.2.8 scenarios pass in Chrome 152, Edge 151, Playwright Firefox 153, and WebKit 26.5 (60 executions), including password fail-safe behavior and a shared keyboard/secure/ordered-ASR policy demo. The same native demo is a manual acceptance host exposing configured/effective policy, composition, selection, last decision, and input-event diagnostics while hiding the password value. No real IME or composition-commit undo, release Safari/Firefox, mobile, non-Chromium system clipboard, React composition/paste/concurrency/hydration, password-manager/autofill, command-fallback, or screen-reader run |
| Android Views | Supported API levels; Gboard, representative vendor IME, voice input, TalkBack, hardware keyboard, autofill | Automated host only: 12/12 Robolectric `EditText` tests pass on API 35 for ASCII-digit insertion, `.verbatim`, password input-type/transformation fail-safes, composing-span settlement, deletion suppression, detachment, fail-open resynchronization when an `InputFilter` alters or throws, and controlled/plain synchronization of host-owned value changes including a throwing update block. A separate installable acceptance APK imports both Views and Compose public source modules and exposes equivalent natural-language and password fail-safe controls; its existence is not device or real-input evidence. No emulator/device, real IME, voice input, TalkBack, hardware keyboard, password manager/autofill, undo/back, paste UI, or lifecycle matrix has run. |
| Jetpack Compose | Value-based adapter plus any future state-based path selected by the public API; same Android input matrix; external state reset/restoration | Seven host tests pass, including `lastPlan` lifecycle diagnostics. The shared installable acceptance APK contains real `BasicTextField` message/password surfaces with policy recommendation, composition, selection, and settled-decision diagnostics; it has compiled and passed Lint but has not been launched. |
| WinUI 3 | Supported Windows versions; Microsoft Pinyin, representative third-party IME, speech input, Narrator, touch and hardware keyboards | Shared observed-text coordinator passes 7/7 cross-platform checks, including recovery after a rejected host replacement, and the adapter cross-compiles with zero warnings/errors. A code-only unpackaged WinUI acceptance target cross-compiles against public project references and exposes policy, composition, selection, last decision, and current synthetic text; its existence is not Windows-host or real-input evidence. No WinUI control/event-loop, real IME, speech, Narrator, keyboard, paste, binding, undo, or lifecycle run has occurred. |
| WPF | Supported Windows versions; `TextCompositionManager` lifecycle, Microsoft Pinyin, speech input, Narrator, undo/data binding | Shared observed-text coordinator passes 7/7 cross-platform checks, including recovery after a rejected host replacement, and the adapter cross-compiles with zero warnings/errors. A separate WPF acceptance executable compiles against public project references and exposes policy, composition, selection, last decision, and current synthetic text; its existence is not Windows-host or real-input evidence. No WPF control/event-loop, `TextCompositionManager`, IME, speech, Narrator, keyboard, paste, binding, undo, or lifecycle run has occurred. |
| Flutter | iOS, Android, macOS, Windows, and Web; composition, selection, paste, autofill, accessibility, hardware keyboard, dictation, undo | Flutter 3.47.2 analyzer plus 11 formatter/`TextField` tests, including controller synchronization, 4 consumer application tests, and a dedicated acceptance-host widget test. The acceptance UI exposes natural-language and secure fail-safe fields with policy, selection, and composing diagnostics, and is used by compile-only bundle/Web/macOS/iOS Simulator/Android target builds; no app launch or real input |

## Result record

Each executed row should include:

- date and commit SHA;
- hardware or VM model;
- OS and SDK/runtime version;
- keyboard/IME/input-source name and version;
- adapter and host-control type;
- scenario identifiers attempted;
- pass/fail/blocked result with a minimal sanitized reproduction;
- evidence location and reviewer.

Compatibility documentation may summarize results, but the underlying record must remain reviewable and must clearly identify gaps.
