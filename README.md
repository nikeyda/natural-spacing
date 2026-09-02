# Natural Spacing

[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

> Source alpha. Package registry publication is intentionally disabled.

Natural Spacing is a specification-first toolkit for adding predictable spaces at Han–Latin and Han–ASCII-digit boundaries without breaking IME composition, selections, deletion intent, or native undo behavior. It is intended for interactive input and non-interactive text such as ASR, dictation, imported content, and generated prose.

## Before and after

With the `naturalLanguage` policy enabled:

```diff
- 在GitHub发布2个项目
+ 在 GitHub 发布 2 个项目
```

| Before | After |
| --- | --- |
| `支持macOS和Windows11系统` | `支持 macOS 和 Windows11 系统` |
| `今天发布v2版本` | `今天发布 v2 版本` |

The formatter inserts spaces only at direct Han–Latin and Han–ASCII-digit boundaries. Existing spacing, punctuation, Latin–digit sequences such as `React18`, and fields using the `verbatim` policy remain unchanged. The live-editor adapters are designed to produce the same visible result while preserving IME composition, selections, deletion intent, and native undo behavior; see the experimental support levels below.

## Status

Rules v1, private TypeScript/Swift/Kotlin/C#/Dart reference cores, and experimental UIKit/AppKit/SwiftUI/Web/Android Views/Jetpack Compose/WinUI/WPF/Flutter bridges are implemented. The project does **not** contain production platform adapters yet. Every existing platform bridge remains experimental until its real-input acceptance matrix passes.

The current milestone includes:

- rules v1;
- the language-neutral edit contract;
- pinned Unicode 17.0 source metadata, official grapheme test data, and generated language-neutral classification and segmentation artifacts;
- shared rule and input-session fixtures;
- a dependency-free specification validator;
- a TypeScript core and session coordinator using deterministic Unicode 17 grapheme segmentation and classification;
- Foundation-only Swift, Kotlin/JVM, dependency-free .NET 10 C#, and dependency-free Dart 3.13 cores using the same generated Unicode 17 classification and segmentation data;
- experimental WinUI 3 and WPF `TextBox` adapters sharing a host-testable settled-text coordinator;
- an SDK-verified experimental Flutter `TextInputFormatter` package and independent path-dependency consumer;
- an experimental Android Views `EditText` adapter;
- an experimental stateful Jetpack Compose `TextFieldValue` adapter;
- experimental single-selection UIKit and AppKit adapters;
- experimental iOS/macOS SwiftUI text-editor wrappers built on those native adapters;
- iPhone Simulator XCTest coverage for UIKit controls and SwiftUI binding publication;
- macOS host XCTest coverage for `NSTextView`, an `NSTextField` field editor, native undo/notification, and SwiftUI binding publication;
- experimental plain-text Web and React-compatible adapters;
- Playwright coverage for twelve native/end-to-end `input`/`textarea` scenarios in local Chrome, Edge, Firefox, and WebKit engines, including password-input fail-safe and a shared keyboard/secure/ASR policy demo;
- React 19.2.8 controlled, uncontrolled, external-reset, and undo/redo coverage across the same four engines;
- a progressive display-only `text-autospace` stylesheet;
- explainable policy recommendation and interim/final text-update APIs;
- safe cross-language policy resolution that applies only `autoApply` recommendations and otherwise falls back to `verbatim`;
- provider-neutral ordered ASR/dictation sessions in TypeScript, Swift, Kotlin, C#, and Dart, sharing lifecycle and revision fixtures without retaining transcript text;
- tested provider-neutral ASR examples for full hypotheses, explicitly append-only deltas, ordered revisions, cancellation, final closure, and utterance isolation;
- isolated npm tarball, root SwiftPM, Kotlin composite-build, .NET ProjectReference, Dart path-dependency, and Flutter path-dependency consumers that import and exercise the public APIs.

## Principles

- Fields opt in with `naturalLanguage`; the default policy is `verbatim`.
- Never rewrite an active IME composition range.
- Respect a user's decision to delete an automatically inserted space.
- Express automatic changes as small insertion patches and map the selection through them.
- Keep rule semantics in the specification and fixtures, not in one privileged language implementation.
- Keep static CSS spacing separate from stored input content.
- Resolve policy once from explicit configuration or semantic context; never switch an active editor from text heuristics alone.

## Repository map

```text
Package.swift
spec/
  rules-v1.md
  content-policy-v1.md
  edit-contract.schema.json
  unicode/17.0.0/sources.json
  unicode/17.0.0/classification-ranges.json
  unicode/17.0.0/grapheme-segmentation.json
  fixtures/rules-v1.json
  fixtures/sessions-v1.json
  fixtures/policy-v1.json
  fixtures/text-updates-v1.json
  fixtures/ordered-text-sessions-v1.json
docs/
  ordered-text-updates.md
  publication-boundary.md
  adr/
examples/
  asr/
  consumers/
scripts/
  generate-unicode-tables.mjs
  generate-grapheme-tables.mjs
  validate-spec.mjs
packages/
  dart/
  dotnet/
  flutter/
  kotlin/
  typescript/core/
  typescript/web/
  swift/
```

## Validate the specification

Node.js 20 or newer is sufficient for specification validation and the TypeScript conformance suite. The TypeScript rules no longer depend on the host runtime's Unicode release.

```sh
npm run validate
npm test
npm run test:consumer:npm
npm run test:browser
swift test
bash scripts/test-swift-consumer.sh
bash scripts/test-ios-simulator.sh
(cd packages/kotlin && ./gradlew --no-daemon conformance :android-views:testDebugUnitTest :android-views:assembleDebug :compose:testDebugUnitTest)
bash scripts/test-kotlin-consumer.sh
dotnet run --project packages/dotnet/NaturalSpacing.Conformance/NaturalSpacing.Conformance.csproj -- .
bash scripts/test-dotnet-consumer.sh
(cd packages/dart && dart pub get && dart run tool/conformance.dart ../..)
bash scripts/test-dart-consumer.sh
bash scripts/test-flutter.sh
bash scripts/test-flutter-target-builds.sh
```

The validator checks the Git candidate set for forbidden build/cache/credential paths, common secret patterns, absolute user-home paths, and broken relative Markdown links. It also checks JSON syntax, required fixture fields, unique identifiers, UTF-16 ranges, expected-selection bounds, pinned Unicode source metadata, and generated classification and segmentation ranges. `npm test` additionally checks all five classification tables and four generated native segmentation tables against their language-neutral artifacts, builds the TypeScript core, and runs rule, session, Web, and ASR tests. Every core suite runs the same 766 pinned official grapheme cases. See [the Unicode data workflow](spec/unicode/README.md) to reproduce the tables.

The repository includes a read-only GitHub Actions workflow for TypeScript/Web/ASR, a Playwright Chromium/Firefox/WebKit matrix, Swift/UIKit/AppKit/SwiftUI, Kotlin/JVM, C#/.NET, Dart/Flutter, and Windows adapter compilation. Local browser automation currently covers twelve native/end-to-end scenarios plus three React 19 scenarios in branded Chrome 152, Edge 151, Playwright Firefox 153, and Playwright WebKit 26.5: 60 browser executions, including one-transaction native undo/redo, password-input fail-safe behavior, and one executable demo sharing resolved policies across keyboard, secure, and ordered-ASR paths. CI runs the same fifteen scenarios in its three managed engines. Passing automation is not evidence that release Safari, a real IME, dictation path, assistive input source, or device matrix has passed.

Package-consumer smoke tests are intentionally separate from conformance. They verify that packed npm tarballs install and import offline, that the repository root is a valid SwiftPM dependency exposing the four Apple products, and that independent Kotlin, .NET, Dart, and Flutter projects can import their cores or adapters through source dependencies. They do not authorize registry publication or prove a tagged remote Git, Maven, NuGet, or pub dependency. Start with [the source consumer examples](examples/consumers/README.md) and see [the consumer evidence snapshot](docs/evidence/package-consumers-2026-09-02.md) for exact results and limits. Manual UIKit/SwiftUI, AppKit/SwiftUI, Android Views/Compose, Web, Flutter, WinUI 3, and WPF tools are indexed separately under [real-input acceptance hosts](examples/acceptance/README.md); compiling them does not raise a platform's support level.

For application integration, start with [Getting started from source](docs/getting-started.md). It selects the correct live-editor, non-interactive/ASR, or display-only path; documents safe policy resolution; and links each platform adapter.

## Policy recommendation and ASR

`recommendPolicy(context)` returns `naturalLanguage` or `verbatim` with confidence, reason, evidence source, and an `autoApply` flag. Secure/password safety always forces `verbatim`; outside secure input, an explicit policy takes precedence. Text-only heuristics are recommendations and never switch an active editor automatically.

`resolvePolicy(context, fallback)` is the convenience path for automatic configuration. It adopts the recommendation only when `autoApply=true`; otherwise it returns the caller's fallback, which defaults to `verbatim`. UI adapters with an optional policy also default to `verbatim`, so natural-language spacing is always an explicit or safely resolved opt-in.

`formatTextUpdate(update)` supports ASR, dictation, imported, and generated text. Interim hypotheses produce display text but no committed value; final hypotheses can be persisted. See [Content Policy and Non-interactive Text v1](spec/content-policy-v1.md).

`OrderedTextUpdateSession` adds provider-neutral utterance lifecycle and monotonic revision handling. It accepts only events for the active utterance, rejects duplicate or stale revisions, closes on a valid final event, and retains only the active utterance ID plus latest revision—not transcript text. See [Ordered ASR and dictation updates](docs/ordered-text-updates.md).

## Scope of rules v1

Rules v1 inserts U+0020 only at these direct boundaries, in either direction:

- Han ↔ Latin;
- Han ↔ ASCII digit (`0`–`9`).

It does not add rules for punctuation, full-width digits, Japanese, Korean, Markdown, source code, rich text, or `contenteditable`.

## License

Apache License 2.0. See [LICENSE](LICENSE).

Current implementation and platform support are tracked in [COMPATIBILITY.md](COMPATIBILITY.md).
The full platform order and acceptance gates are tracked in [ROADMAP.md](ROADMAP.md).
Unicode segmentation gaps are explicit in [the segmentation matrix](docs/unicode-segmentation-matrix.md), and real-input evidence follows [the platform acceptance protocol](docs/platform-acceptance.md).
The current source-publication gates are recorded in [the publication readiness audit](docs/evidence/publication-readiness-2026-09-02.md).
Apple adapter host evidence is recorded separately for [macOS](docs/evidence/macos-host-2026-09-02.md) and [iOS Simulator](docs/evidence/ios-simulator-2026-09-02.md).
Flutter SDK evidence is recorded in [the Flutter host snapshot](docs/evidence/flutter-host-2026-09-02.md).
