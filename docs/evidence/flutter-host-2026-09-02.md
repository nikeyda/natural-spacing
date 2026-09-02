# Flutter host evidence — 2026-09-02

This is SDK-level host evidence, not target-device or real-input acceptance.

## Environment

- Flutter 3.47.2 stable, framework revision `d3b14c8769`;
- Dart 3.13.2;
- macOS arm64 SDK archive from the [official Flutter release manifest](https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json);
- archive SHA-256 `f456fd6733053d9301828a2e702d6cbec872923126809aa8c48eb0a696d6cc01`, verified before extraction;
- dependencies downloaded from `https://storage.googleapis.com` and `https://pub.dev` into isolated temporary caches.

The GitHub Actions installer separately pins the official Linux x64 Flutter 3.47.2 archive SHA-256 `447878859d01ca9bfdb99a85f245af07ed8a15fedcd9d189c4749e8e92d1f185` from the [official Linux release manifest](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json).

## Command

```sh
bash scripts/test-flutter.sh
```

## Results

- Adapter package analysis: no issues;
- adapter package tests: 11/11 passed;
- independent path-consumer analysis: no issues;
- independent path-consumer application tests: 4/4 passed, including the Dart core's ordered ASR session;
- dedicated acceptance-host analysis: no issues;
- acceptance-host widget test: 1/1 passed, covering distinct natural-language and secure fail-safe fields without rendering password diagnostics.

The adapter tests cover:

- default `verbatim` pass-through;
- natural-language insertion and caret mapping;
- active composition pass-through and settled reconciliation;
- backward selection direction and affinity;
- manual automatic-space deletion suppression and reset;
- controller synchronization after an external value replacement clearing prior deletion intent;
- UTF-16 length-limit fail-open behavior;
- paste-like replacement across fragment and outer boundaries;
- simulated ASCII-digit platform input through a real Flutter `TextField`, including controller text and selection publication.

## Target compile smoke

Command:

```sh
NATURAL_SPACING_FLUTTER_TARGETS=web,macos,ios,android \
  bash scripts/test-flutter-target-builds.sh
```

The script creates a disposable Flutter application, copies the dedicated acceptance-host UI, imports the repository's Dart and Flutter packages through path dependencies, runs analysis, builds the targets, and removes the temporary application on exit. The UI exposes effective policy, selection, composing range, and non-secure text while keeping the password diagnostic hidden.

Results on the same macOS host with Xcode 26.6, JDK 17, Android API 33–36, and Android Build Tools 36.0.0:

- Darwin debug Flutter asset bundle: passed;
- Web debug build: passed; Flutter Wasm dry-run passed;
- macOS arm64 debug application: passed;
- unsigned universal iOS Simulator debug application: passed;
- Android debug APK: passed.

Flutter installed Android Build Tools 36.0.0 into the already configured Android SDK after confirming its existing accepted license. The generated macOS Xcode project emitted Flutter's standard warning that the `Flutter Assemble` run-script phase has no declared outputs; the build still completed.

## Limits

No iOS, Android, macOS, or Web Flutter application was launched, and Windows was not compiled. This evidence does not establish real IME composition ordering, soft/hardware keyboards, paste UI, autofill, accessibility, dictation, undo, controller restoration, lifecycle, or target-version compatibility.
