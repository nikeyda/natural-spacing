# `@natural-spacing/core`

Private TypeScript reference implementation for rules v1. The package is not published.

## API

```ts
import {
  NaturalSpacingSession,
  OrderedTextUpdateSession,
  formatTextUpdate,
  normalizeNaturalLanguage,
  planEdit,
  recommendPolicy,
  resolvePolicy,
} from "@natural-spacing/core";
```

- `normalizeNaturalLanguage(text, policy)` performs explicit full-text canonical normalization.
- `planEdit(snapshot)` returns patches only for the changed fragment and its outer boundaries.
- `NaturalSpacingSession` additionally preserves deletion suppressions across user edits.
- `recommendPolicy(context)` recommends one of the two policies without silently changing active input.
- `resolvePolicy(context, fallback)` adopts only recommendations marked `autoApply`; advisory results use the caller's fallback (`verbatim` by default).
- `formatTextUpdate(update)` formats ASR/dictation interim display text and final committed text.
- `OrderedTextUpdateSession` rejects stale, inactive, or invalid provider revisions and closes an utterance after final output.

Secure/password context always resolves to `verbatim`, even when `explicitPolicy` is `naturalLanguage`. Outside secure input, the explicit policy wins.

All edit offsets count UTF-16 code units. Insertions use U+0020 and selection endpoints use downstream affinity.

## Runtime status

The core uses one zero-dependency MIT package, `unicode-segmenter` 0.17.3, for deterministic Unicode 17 extended-grapheme segmentation. Script, general-category, mark, and whitespace classification uses generated Unicode 17 tables derived from the repository's pinned source metadata. Rules v1 therefore does not depend on host `Intl.Segmenter`, Unicode property escapes, or the host runtime's Unicode release.

`npm test` verifies that the TypeScript table exactly matches the language-neutral generated artifact and runs all 766 cases in the pinned Unicode 17 `GraphemeBreakTest.txt`. The package remains private until the supported JavaScript/browser runtime matrix passes. Platform adapters must not claim support based only on these Node tests.
