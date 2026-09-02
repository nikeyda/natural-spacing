# Natural Spacing for Dart

This directory contains the Dart reference core and shared-fixture conformance runner. It supports normalization, edit planning, per-editor deletion intent, `.naturalLanguage` / `.verbatim` recommendation, interim/final text updates, and ordered ASR/dictation revisions.

```dart
import 'package:natural_spacing/natural_spacing.dart';

final display = NaturalSpacing.normalize(
  '在Flutter发布2个版本',
  policy: FieldPolicy.naturalLanguage,
);
// 在 Flutter 发布 2 个版本

final recommendation = NaturalSpacingPolicy.recommend(
  const PolicyContext(contentKind: ContentKind.prose),
);
final policy = NaturalSpacingPolicy.resolve(
  const PolicyContext(contentKind: ContentKind.prose),
);
```

`resolve` uses a recommendation only when `autoApply` is true; otherwise it returns `FieldPolicy.verbatim` or a caller-supplied fallback.

Secure/password context always resolves to `FieldPolicy.verbatim`, even when the explicit policy is `naturalLanguage`. Outside secure input, the explicit policy wins.

Use `OrderedTextUpdateSession` for complete revision-capable hypotheses; it passes the same 23 ordered operations as the TypeScript, Swift, Kotlin, and C# cores. See [the ordered-update guide](../../docs/ordered-text-updates.md).

Run conformance from this directory:

```sh
dart pub get
dart analyze
dart run tool/conformance.dart ../..
```

The dependency-free core uses generated Unicode 17 tables for boundary classification and segmentation. Its native state machine passes all 766 pinned official grapheme cases on Dart 3.13.3. Public package support still requires the Dart/Flutter target matrix and real input acceptance.
