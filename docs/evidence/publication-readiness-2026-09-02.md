# Publication readiness audit — 2026-09-02

This is the source-alpha publication record for [`nikeyda/natural-spacing`](https://github.com/nikeyda/natural-spacing). It does not authorize registry package publication.

## Cleared checks

- The candidate repository is isolated under the documented publication boundary. A text scan found no workspace owner path, company source path, credential, private key, or proprietary product identifier in candidate source files.
- Apache-2.0 is present for the project. Unicode License V3 is retained with the vendored official test data. The complete MIT notice for `unicode-segmenter` 0.17.3 is retained in `THIRD_PARTY_NOTICES.md`.
- Runtime dependencies are intentionally narrow:
  - TypeScript core: `unicode-segmenter` 0.17.3;
  - Swift, Kotlin core, C#, and Dart cores: no third-party runtime dependency;
  - Compose adapter: AndroidX Compose UI Text 1.11.3;
  - Web uses the local TypeScript core; Flutter uses the local Dart core and Flutter SDK.
- Playwright 1.62.1 is a development-only browser automation dependency under Apache-2.0; it is not part of either npm package's runtime dependency graph.
- React and ReactDOM 19.2.8 plus esbuild 0.28.2 are development-only dependencies for the real React browser fixture; none is part of the published Web package's runtime dependency graph.
- Robolectric 4.16 and JUnit 4.13.2 are development-only dependencies for Android Views host tests; neither is part of the Android adapter's runtime dependency graph.
- Both `npm audit --omit=dev --audit-level=high` and the full `npm audit --audit-level=high` reported zero known vulnerabilities on this date, including the development-only Playwright dependency.
- npm package dry-runs contained only declared README, build output, stylesheet, and manifest files. Both packages remain `private: true` at version `0.0.0`, so registry publication is deliberately disabled.
- Packed TypeScript core and Web tarballs install offline into an isolated consumer and expose their declared JavaScript and CSS entry points.
- The repository root is a valid SwiftPM package; independent Swift, Kotlin, .NET, Dart, and Flutter projects import and exercise their public cores or adapters through local source dependencies without enabling a registry.
- Generated classification and segmentation source matches the language-neutral Unicode 17 artifacts.
- TypeScript, Swift, Kotlin, C#, and Dart expose the same safe policy-resolution rule: secure/password context forces `verbatim` even when explicit `naturalLanguage` is also present; otherwise only `autoApply=true` recommendations are adopted automatically, and advisory results use a caller fallback that defaults to `verbatim`. Optional UI-adapter policies also default to `verbatim`.
- The same five cores consume four provider-neutral ordered ASR/dictation scenarios with 23 operations. Their session state retains only the active utterance ID and latest accepted revision, not transcript text.
- Kotlin includes a Gradle 8.13 wrapper whose distribution URL is protected by the official SHA-256 checksum.
- The public repository uses `main` and Apache-2.0. The repository validator reports 230 source-publication candidates; `.DS_Store`, Kotlin compiler state, dependency trees, build products, and test output are ignored. `npm run validate:repository` reproduces the candidate-path, common-secret, absolute user-home path, and relative Markdown-link checks locally and in CI.
- A source-alpha getting-started guide now routes developers to live-editor, ASR/non-interactive, or display-only integration, documents safe policy resolution in all five cores, and links the executable source consumers.

## Verification snapshot

| Gate | Result |
|---|---|
| TypeScript core | 107/107 tests, including all four Han/Latin/ASCII-digit boundary directions in interactive sessions, 30 policy fixtures with secure/password override coverage, exhaustive direct semantic fixtures for all 16 automatically resolvable content kinds, a complete two-policy/two-stability ASR update matrix, four ordered-session scenarios with 23 operations, and 766/766 Unicode 17 grapheme cases; packed core and Web tarballs install and import in an isolated offline consumer whose ordered stream covers interim display, stale rejection, final persistence, and final closure |
| Web native/CSS | 11/11 host behaviors; 12/12 real-DOM/end-to-end scenarios pass in Chrome 152.0.7977.65, Edge 151.0.4129.93, Playwright Firefox 153, and Playwright WebKit 26.5 (48/48 browser executions), including direct ASCII-digit keyboard input, ordinary-input undo/redo, password input forcing `verbatim`, and the executable keyboard/secure/ordered-ASR policy demo. The demo also exposes configured/effective policy, composition, selection, last-plan, and input-event diagnostics; the four-engine test verifies password diagnostics hide the value. Together with three React scenarios, the local matrix passes 60/60. System clipboard is native only in Chromium; the other engines use synthetic paste/beforeinput events. A repeated Firefox cold-start navigation timeout was resolved by an explicit 60-second per-test budget; retries remain disabled, and the final full matrix passed cleanly |
| React 19.2.8 | Controlled, uncontrolled, external-reset, and controlled undo/redo behavior pass 3/3 scenarios in all four engines (12/12 browser executions) using native DOM-ref binding |
| ASR examples | 6/6 provider-neutral tests for revisable full hypotheses and explicitly append-only deltas; ordered lifecycle/revision semantics are supplied by the shared five-language core contract |
| Swift/UIKit/AppKit/SwiftUI | Root SwiftPM package tests: 28/28, including 13 core, 11 AppKit, and 4 macOS SwiftUI tests; AppKit includes fail-open behavior for direct and post-edit reconciliation plus edit-lifecycle deletion-intent reset; an independent package imports Core/AppKit/SwiftUI; a combined AppKit/SwiftUI manual host imports those same public products and compiles at the macOS 10.15 floor without launch. iPhone Air/iOS 26.4 Simulator: 25/25 across 13 core, 9 UIKit, and 3 SwiftUI tests; UIKit includes secure-text fail-safe behavior, programmatic-value synchronization, and edit-lifecycle deletion-intent reset; both core suites include the ordered-session fixtures and all 766 grapheme cases, optional SwiftUI policy defaults to `verbatim`, and iOS 13 target cross-compiles against iPhoneOS 26.5. A separate public-SwiftPM UIKit/SwiftUI acceptance app exposes automatic recommendation/resolution, UIKit input diagnostics, and public-wrapper SwiftUI bindings, and compiles as an arm64+x86_64 Simulator app without development-team signing; it has not been launched |
| Kotlin/JVM | Checked-in Gradle wrapper passes 97 shared + 4 bridge + 23 ordered-session + 766 grapheme checks; an independent composite build imports the core and exercises interim/stale/final/closed ordered handling without choosing Maven coordinates |
| C#/.NET | 97 shared + 4 bridge + 5 focused classification + 7 observed-text coordinator + 23 ordered-session + 766 grapheme checks; the observed-text checks include recovery after a rejected host replacement; an independent ProjectReference consumer imports the core and exercises interim/stale/final/closed ordered handling; its smoke test prompted the pre-release entry point rename to the unambiguous `NaturalSpacingFormatter` |
| Android Views | API 35 Android Release AAR assembles; 12/12 Robolectric `EditText` host tests pass for ASCII-digit insertion, `.verbatim`, password input-type and transformation fail-safes, composing-span settlement, deletion suppression, detachment, fail-open resynchronization when an `InputFilter` alters or throws, and controlled/plain synchronization of host-owned value changes including a throwing update block; an independent Android library consumer imports the adapter through a temporary composite substitution; the combined Views/Compose acceptance APK passes Lint and assembles without install or launch |
| Jetpack Compose | API 35 Android library compiles; 7/7 value-adapter host tests pass, including ASCII-digit insertion, default `verbatim`, and `lastPlan` lifecycle diagnostics; the independent Android library consumer imports the adapter, and the combined acceptance APK contains real `BasicTextField` message/password surfaces with policy recommendation, composition, selection, and decision diagnostics |
| WinUI 3 and WPF | Both adapters use the seven-check observed-text coordinator, expose the last settled plan, and resynchronize after a host replacement does not land; adapter Release cross-compiles pass with zero warnings and zero errors; separate WinUI and WPF acceptance targets also cross-compile with zero warnings and zero errors but have not run on Windows |
| Dart | Analyzer clean; 97 shared + 4 bridge + 23 ordered-session + 766 grapheme checks; an independent path-dependency consumer imports the core and exercises interim/stale/final/closed ordered handling |
| Flutter | Flutter 3.47.2 analyzer clean; 11/11 formatter/`TextField` host tests, including simulated platform insertion of an ASCII digit and controller synchronization after an external value replacement, and 4/4 independent application tests pass, including ordered ASR handling. A dedicated natural-language/secure acceptance UI passes 1/1 widget test and compiles through disposable bundle, Web, macOS, iOS Simulator, and Android builds; CI installer pins the official Linux 3.47.2 archive SHA-256 |

The GitHub Actions workflow pins actions to full commit SHAs. [Public run 33584648951](https://github.com/nikeyda/natural-spacing/actions/runs/33584648951) passed all seven jobs at source head `a11b3e2a71ec089682a5613739ce3869dcd42c39`: TypeScript/Web/ASR, Swift/UIKit/AppKit/SwiftUI, Kotlin/JVM/Android Views/Compose, C#/.NET, Dart, Flutter, and WinUI 3/WPF. The first two public runs exposed three hosted-runner portability defects—missing Android SDK setup, an unformatted Dart conformance source, and insufficient D8 heap for the Android acceptance APK—and the fixes are included in the passing head. This result does not establish release Safari/Firefox, mobile browsers, React composition/paste/concurrency/hydration, non-Chromium system clipboard, composition-commit undo, command fallback, autofill/accessibility, or real IMEs. Android, UIKit, WinUI/WPF, Flutter, and real input sources still require the acceptance matrices recorded elsewhere.

Detailed local package-consumer evidence and its limits are recorded in [the package consumer snapshot](package-consumers-2026-09-02.md). Android control evidence and its limits are recorded in [the Android Views host snapshot](android-host-2026-09-02.md). Windows coordinator and cross-compile evidence is recorded in [the Windows coordinator snapshot](windows-coordinator-2026-09-02.md).

## Publication decision record

The first milestone is published as the public `nikeyda/natural-spacing` source alpha under Apache-2.0. All npm, Maven, NuGet, pub, and other registry publication remains disabled and their final coordinates are deferred.

The confirmed publication identity is:

1. GitHub owner and initial maintainer: `nikeyda`.
2. Public Git author: `nikey <45325116+nikeyda@users.noreply.github.com>`.
3. Public distribution license: Apache-2.0.

GitHub private vulnerability reporting is enabled. No GitHub release, signed tag, package registry, or provenance publication has been created.

## Recommendation

Keep every package registry disabled and every native adapter labeled experimental until its platform acceptance gate passes. The next milestone should collect real keyboard, IME, dictation, undo, accessibility, and device evidence before any support claim or tagged release. Do not describe cross-compilation or pure-core conformance as real-input support.
