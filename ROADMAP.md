# Roadmap

Natural Spacing targets iOS, macOS, Android, Web, Windows, and Flutter. A platform is not supported merely because its language core passes shared fixtures; its native input, IME, selection, undo, paste, length-limit, and ASR/dictation gates must also pass.

## Completed foundation

- Rules v1 and UTF-16 edit contract;
- Unicode 17.0 source metadata;
- generated, language-neutral Unicode 17 classification ranges, five native tables, and reproducibility checks;
- rule, interactive-session, policy, non-interactive text, and ordered ASR/dictation fixtures;
- TypeScript reference core with deterministic Unicode 17 segmentation and classification;
- Foundation-only Swift reference core with deterministic Unicode 17 segmentation;
- proposed-edit bridge and experimental UIKit/AppKit single-selection adapters;
- experimental iOS/macOS SwiftUI `NaturalSpacingTextEditor` wrappers reusing the native adapters;
- experimental native Web/React-compatible adapters and display-only CSS helper;
- Kotlin/JVM reference core passing all shared fixtures;
- generated Kotlin Unicode 17 segmenter passing all 766 pinned official grapheme cases;
- experimental Android Views and value-based Jetpack Compose library modules built by the checked-in Gradle wrapper;
- dependency-free C#/.NET 10 reference core passing all shared fixtures and pinned Unicode 17 grapheme cases;
- dependency-free Dart 3.13 reference core passing all shared fixtures and pinned Unicode 17 grapheme cases;
- explainable `.naturalLanguage` / `.verbatim` recommendation;
- safe five-language policy resolution with a default `.verbatim` fallback;
- ASR/dictation interim-display and final-commit contract;
- provider-neutral ordered ASR/dictation lifecycle and revision contract in all five cores;
- isolated npm tarball, repository-root SwiftPM, Kotlin composite-build core plus Android Views/Compose source-consumer, .NET ProjectReference, Dart path-dependency, and Flutter path-dependency smoke tests.

## Development order

### 1. Swift core

**Status:** private reference implementation uses generated Unicode 17 classification and segmentation, passes the shared fixtures, and passes all 766 pinned official grapheme cases on Swift 6.3.3/macOS. The cross-version Apple matrix remains open.

Implement the shared rule, policy, text-update, edit-plan, and session contracts in a Swift Package without UIKit or AppKit dependencies.

**Gate:** all shared fixtures match the TypeScript reference output exactly.

### 2. iOS adapters

**Status:** experimental UIKit delegate-forwarding bridge and a SwiftUI `NaturalSpacingTextEditor` backed by `UITextView` cross-compile against iPhoneOS 26.5. On iPhone Air/iOS 26.4 Simulator, 9 UIKit adapter tests and 3 SwiftUI tests pass alongside 13 core tests, including shared ordered ASR/dictation conformance, secure-text fail-safe behavior, programmatic-value synchronization, edit-lifecycle deletion-intent reset, and verification that the wrapper defaults to `.verbatim`. A storyboard-free UIKit/SwiftUI acceptance app imports the public SwiftPM products: its UIKit tab displays automatic policy recommendation/resolution and input diagnostics, while its SwiftUI tab exposes message/code wrapper bindings for direct comparison. It compiles for arm64+x86_64 Simulator without development-team signing but has not been installed or launched. Real keyboard, marked-text, accessibility, dictation, supported-version, and physical-device acceptance remain open.

- UIKit: `UITextField` and `UITextView`;
- SwiftUI wrapper reusing the UIKit coordinator where composition/selection access requires it;
- system keyboard, dictation, paste, hardware keyboard, and representative third-party keyboard testing.

**Gate:** marked text is never rewritten, selection/undo remain native, and one settled value is published per user edit.

### 3. macOS adapters

**Status:** experimental AppKit bridge has eleven automated host tests covering `NSTextView`, an `NSTextField` field editor, selection, marked-text reconciliation, deletion intent and lifecycle reset, native undo, change notification, multi-range fail-open, and direct plus post-edit host rejection of a validated replacement. The macOS SwiftUI wrapper has four tests covering construction, default `.verbatim`, and direct/settled binding publication. A combined public-product acceptance executable now provides AppKit and SwiftUI tabs for same-input-source comparison and compiles at the macOS 10.15 package floor, but has not been launched. Real input sources, dictation, accessibility, application lifecycle, and the supported-version matrix remain open.

- AppKit: `NSTextField` and `NSTextView`;
- SwiftUI on macOS through the shared AppKit-aware coordinator;
- dictation, input sources, hardware keyboard, selection, paste, and native undo testing.

AppKit exposes marked text and replacement through [`NSTextInputClient`](https://developer.apple.com/documentation/appkit/nstextinputclient), including `hasMarkedText`, `markedRange`, `setMarkedText`, and `insertText`. The adapter must observe these semantics rather than treating macOS as a larger iOS text field.

**Gate:** all shared fixtures pass and real macOS marked-text/dictation sessions remain intact.

### 4. Web adapters

**Status:** experimental plain-text `input`/`textarea` hybrid before/post-input reconciliation, runtime-free React-compatible integration, and guarded display CSS are implemented. Eleven host behaviors, twelve native/end-to-end scenarios, and three React 19.2.8 scenarios pass in Chrome 152, Edge 151, Playwright Firefox 153, and Playwright WebKit 26.5 (60 executions), including `input[type=password]` forcing `verbatim` and a shared keyboard/secure/ordered-ASR policy demo. The same demo now serves as a manual acceptance host with configured/effective policy, composition, selection, last-plan, and input-event diagnostics; its password diagnostics are verified to hide the value. Release Safari/Firefox, mobile browsers, non-Chromium system clipboard, real IMEs and composition-commit undo, real-browser command fallback, password-manager/autofill/accessibility, and React composition/paste/concurrency/hydration remain open.

- native `input` and `textarea` adapter;
- controlled and uncontrolled React DOM-ref integration;
- static CSS `text-autospace` helper kept separate from stored content;
- Chrome, Safari, Firefox, desktop/mobile IME and undo matrix.

**Gate:** `beforeinput`/`input` reconciliation, composition, selection, paste, and framework state remain consistent.

### 5. Kotlin and Android adapters

**Status:** Kotlin/JVM rule, session, policy, safe-resolution, and text-update contracts pass all 97 shared fixture checks, four proposed-edit bridge checks, and 23 ordered ASR/dictation operations on Kotlin 2.0.20/JDK 17. Generated Unicode 17 classification and segmentation remove dependence on JDK Unicode behavior, and the project segmenter passes all 766 pinned official grapheme cases. The checked-in Gradle wrapper builds experimental Android Views and Compose UI Text 1.11.3 adapters against API 35. Twelve Robolectric `EditText` host tests cover ASCII-digit insertion, `.verbatim`, password input-type and transformation fail-safes, composition settlement, deletion suppression, detachment, fail-open resynchronization when an `InputFilter` alters or throws, and controlled/plain synchronization of host-owned value changes including a throwing update block. Seven Compose host tests cover composition deferral, commit reconciliation, deletion suppression, selection mapping, policy/length pass-through, external baseline synchronization, default `.verbatim`, and `lastPlan` lifecycle diagnostics. A separate Android library consumer compiles imports of both adapters through temporary composite-build substitutions without selecting future Maven coordinates. The installable acceptance APK now embeds both Views and real Compose `BasicTextField` natural-language/password surfaces, passes Lint, and assembles without install or launch.

- Kotlin core;
- Android Views editable controls;
- Jetpack Compose `TextFieldValue` path, followed by a state-based path only when the public API can preserve the same composition guarantees;
- Gboard, vendor IMEs, dictation, hardware keyboard, and accessibility input testing.

**Gate:** shared fixtures and the Android real-device matrix pass.

### 6. C#/.NET and Windows adapters

**Status:** dependency-free C# core uses generated Unicode 17 classification and segmentation, passes all 97 shared fixture checks plus four proposed-edit bridge, five focused Unicode, seven observed-text coordinator, 23 ordered ASR/dictation checks, and all 766 pinned official grapheme cases on .NET SDK 10.0.400/runtime 10.0.11. Experimental settled-input WinUI 3 and WPF `TextBox` adapters share that tested coordinator, expose the last settled plan for diagnostics, resynchronize to the control's actual text if a minimal replacement is rejected, and cross-compile against Windows App SDK 2.4.0 and .NET 10 WindowsDesktop on macOS with zero warnings or errors. Separate WinUI and WPF manual-acceptance targets also cross-compile through public project references. Native Windows event ordering, composition, selection, binding, undo, and speech behavior still require a Windows verification environment.

- C# core with the same public contracts;
- Windows App SDK / WinUI 3 `TextBox` first;
- WPF `TextBox` second;
- custom editor guidance through `CoreTextEditContext` only when standard controls are insufficient.

WinUI `TextBox` exposes composition start/change/end events and synchronous text-changing hooks in the [Windows App SDK API](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.textbox). WPF exposes composition lifecycle through [`TextCompositionManager`](https://learn.microsoft.com/en-us/dotnet/api/system.windows.input.textcompositionmanager). Custom Windows editors can use [`CoreTextEditContext`](https://learn.microsoft.com/en-us/uwp/api/windows.ui.text.core.coretexteditcontext), which covers keyboard, speech, and IME text services.

**Gate:** Chinese IME, speech input, selection, undo, paste, touch keyboard, and hardware keyboard pass on supported Windows versions.

### 7. Dart and Flutter adapters

**Status:** dependency-free Dart core uses generated Unicode 17 classification and segmentation, passes all 97 shared fixture checks plus four proposed-edit bridge checks and 23 ordered ASR/dictation checks, and passes all 766 pinned official grapheme cases on Dart 3.13.3. The experimental formatter targets Flutter 3.47 and follows Flutter's collapsed-composition rule. On Flutter 3.47.2/Dart 3.13.2, analysis is clean and 11 formatter/`TextField` host tests pass, including controller synchronization that clears prior deletion intent; an independent path-dependency application passes 4 tests, including ordered ASR handling. A dedicated acceptance UI adds natural-language and secure fail-safe fields plus policy, selection, and composing diagnostics, and the disposable Web, macOS, iOS Simulator, and Android builds now compile that UI. Windows compile plus all target-runtime and real-input acceptance remains open.

- Dart core;
- `TextInputFormatter`-based Flutter adapter;
- iOS, Android, macOS, and Windows desktop acceptance.

**Gate:** shared fixtures pass and composing regions are never modified on every target platform.

### 8. ASR and text-pipeline examples

**Status:** TypeScript, Swift, Kotlin, C#, and Dart consume four shared ordered-session scenarios with 23 lifecycle/revision operations covering ASR and dictation, `.naturalLanguage` and `.verbatim`, interim/final updates, invalid or stale revisions, inactive utterances, cancellation, restart, and final closure. The session retains only the active utterance ID and latest revision. Six additional TypeScript provider-neutral example tests cover revisable full hypotheses and explicitly append-only deltas. Real provider retry, reconnect, sequence-wrap, error, cancellation, ordering, and revision/delta mappings remain open.

Add small provider-neutral examples for:

- full interim hypotheses;
- final hypotheses;
- delta-token assembly before formatting;
- imported/generated prose;
- explicit structured-content opt-out.

Examples must not log real user audio or transcripts.

### 9. Public alpha

Before public GitHub or registry publication:

- finalize project/package names and ownership;
- complete IP, license, attribution, security-contact, and privacy review;
- verify the selected GitHub URL/tag through a remote SwiftPM consumer and decide registry namespaces;
- add Kotlin Maven and .NET NuGet consumer checks when their artifact coordinates are approved;
- publish conformance results and truthful compatibility status;
- keep unsupported adapters clearly marked experimental or absent.

## Release sequence

- `0.1.0-alpha`: specification, TypeScript, Swift core, iOS/macOS adapters;
- `0.2.0-alpha`: Web/React/CSS and ASR examples;
- `0.3.0-beta`: Kotlin/Android and C#/Windows;
- `0.4.0-beta`: Dart/Flutter;
- `1.0.0`: every claimed platform passes its automated and real-input acceptance matrix.
