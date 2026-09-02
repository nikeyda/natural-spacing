# Flutter manual acceptance host

This small Flutter application exposes two public-package paths:

- a message field resolved to `naturalLanguage`;
- a password field deliberately requesting `naturalLanguage` but safely
  resolved to `verbatim`.

The diagnostics show the effective policy, selection, composing range, and
non-secure text. Password text remains hidden. Use synthetic input only.

## Compile checks

Run the host test and analyzer:

```sh
NATURAL_SPACING_FLUTTER=/path/to/flutter bash scripts/test-flutter.sh
```

Compile disposable applications with this host UI for available targets:

```sh
NATURAL_SPACING_FLUTTER=/path/to/flutter \
NATURAL_SPACING_FLUTTER_TARGETS=web,macos,ios,android \
bash scripts/test-flutter-target-builds.sh
```

Windows must be built and run on Windows. Installing or launching any generated
artifact is a separate action. A successful build is not real-input evidence.

## Manual matrix

On each actual target, cover composition and commit, forward/backward
selection, paste, manual auto-space deletion, reset, native undo/redo, autofill,
dictation where available, hardware keyboards, and accessibility input. Record
the result using [`docs/platform-acceptance.md`](../../../docs/platform-acceptance.md).
