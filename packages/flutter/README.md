# Natural Spacing for Flutter

This package contains an experimental `TextInputFormatter` for Flutter 3.47 or newer. Its source follows Flutter's requirement to leave non-collapsed composing ranges unchanged. Flutter 3.47.2 analysis and 11 formatter/`TextField` host tests pass, including controller synchronization after an external value replacement; an independent path-dependency consumer application passes 4 tests, including use of the Dart core's ordered ASR session. Disposable target builds pass for Web, macOS, iOS Simulator, and Android. No application has been accepted on a target device or real input source.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:natural_spacing/natural_spacing.dart' as core;
import 'package:natural_spacing_flutter/natural_spacing_flutter.dart';

final spacing = NaturalSpacingTextInputFormatter(
  policy: core.FieldPolicy.naturalLanguage,
  maxLengthUtf16: 500,
);

TextField(
  inputFormatters: [
    LengthLimitingTextInputFormatter(500),
    spacing,
  ],
);
```

The formatter defaults to `core.FieldPolicy.verbatim`. Opt in explicitly as above, or pass the result of `core.NaturalSpacingPolicy.resolve` for a known semantic content kind.

`TextInputFormatter` does not receive the owning `TextField.obscureText` value. Keep password fields on the default `verbatim` policy and do not attach a natural-language formatter to them.

Place the formatter after a length limiter and pass the same UTF-16 maximum so an automatic space is skipped instead of exceeding the field contract. Keep one formatter instance per editor; its session remembers when a user intentionally deletes an inserted space. Call `reset()` when the editor begins a logically new document.

Programmatic controller changes do not run input formatters. After replacing `controller.value` or `controller.text`, call `sync()` so deletion intent from the previous value cannot leak into the next platform edit:

```dart
controller.value = nextValue;
spacing.sync();
```

For ASR, imported, or generated text, use `NaturalSpacingPolicy.format` from the Dart core instead.

From the repository root, run the package and independent consumer gates with:

```sh
bash scripts/test-flutter.sh
bash scripts/test-flutter-target-builds.sh
```

The target-build script creates a disposable app, imports this package and the Dart core by path, builds a host bundle plus Web by default, and deletes the generated app. Set `NATURAL_SPACING_FLUTTER_TARGETS=web,macos,ios,android` on a configured macOS host to run the broader compile matrix. A successful build is not real-input acceptance.

Before support is claimed, run the composing, selection, paste, autofill, accessibility, hardware-keyboard, dictation, and undo matrix on iOS, Android, macOS, Windows, and Web.
