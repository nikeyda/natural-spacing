# Contributing

Natural Spacing is specification-first. A rule change is incomplete unless it updates all affected artifacts.

## Before opening a change

1. Read `spec/rules-v1.md` and the relevant ADR.
2. Keep the change within the current milestone.
3. Add at least one positive and one negative fixture for a semantic rule change.
4. Run the checks for every affected core. `npm test` is the minimum for specification or generated-data changes.

## Local checks

The GitHub workflow runs these independent gates:

```sh
npm test
npm run test:consumer:npm
npm run test:browser
swift test
bash scripts/test-swift-consumer.sh
swift build --package-path examples/acceptance/macos --scratch-path /tmp/natural-spacing-macos-acceptance-build
bash scripts/test-ios-acceptance-host.sh
bash scripts/test-ios-simulator.sh
(cd packages/kotlin && ./gradlew --no-daemon conformance :android-views:testDebugUnitTest :android-views:assembleDebug :compose:testDebugUnitTest)
bash scripts/test-kotlin-consumer.sh
bash scripts/test-android-acceptance-host.sh
dotnet run --project packages/dotnet/NaturalSpacing.Conformance/NaturalSpacing.Conformance.csproj -- .
bash scripts/test-dotnet-consumer.sh
bash scripts/test-windows-winui-acceptance-host.sh
bash scripts/test-windows-wpf-acceptance-host.sh
(cd packages/dart && dart pub get && dart format --output=none --set-exit-if-changed lib tool && dart analyze && dart run tool/conformance.dart ../..)
bash scripts/test-dart-consumer.sh
bash scripts/test-flutter.sh
bash scripts/test-flutter-target-builds.sh
```

Local browser runs require installed Chrome and Edge; the command builds development-only native-control and React fixtures before running the browser matrices. CI installs Playwright's Chromium, Firefox, and WebKit runtimes. Windows CI also cross-compiles the WinUI 3 and WPF projects. These automated builds and host-browser checks do not replace the real-input acceptance matrices in `COMPATIBILITY.md`.

## Change requirements

- Do not add platform-specific behavior to the language-neutral rule specification.
- Do not rewrite active IME composition text.
- Do not introduce a runtime dependency without an ADR explaining why it is necessary.
- Keep generated Unicode data and its source/version metadata reviewable.
- Preserve fixture identifiers after release; add new cases instead of repurposing old ones.

The project uses the Apache License 2.0. By submitting a contribution, you agree that it is licensed under that license.

## Reporting input behavior

Use the input-method bug form for keyboard, IME, dictation, composition,
selection, undo, autofill, and accessibility-input problems. Report the exact
host control and input source, use only synthetic text, and identify the
evidence level from `docs/platform-acceptance.md`. A compile, simulator, or
automated-host result is not evidence that a real input source works.
