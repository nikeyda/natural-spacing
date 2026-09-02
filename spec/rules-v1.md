# Natural Spacing Rules v1

- Status: Draft frozen for the first reference implementation
- Version: 1.0.0-draft.1
- Unicode version: 17.0.0
- Normative keywords: MUST, MUST NOT, SHOULD, MAY follow RFC 2119 meanings.

## 1. Purpose

Rules v1 defines the smallest language-neutral behavior needed to add U+0020 SPACE at direct Han–Latin and Han–ASCII-digit boundaries.

It defines canonical text behavior and runtime input constraints. It does not define framework APIs or require a particular algorithm.

## 2. Non-goals

Rules v1 does not:

- normalize punctuation or full-width characters;
- remove or replace existing whitespace;
- claim general Japanese, Korean, or CJK typography support;
- parse Markdown, HTML, source code, or rich text;
- operate inside `contenteditable`;
- define spell checking, transliteration, or word segmentation;
- require static CSS spacing to modify stored content.

## 3. Text model

### 3.1 Encoding and offsets

Text is Unicode. The edit contract expresses offsets as zero-based UTF-16 code-unit counts and ranges as half-open intervals.

An implementation MUST decode Unicode scalar values correctly. It MUST NOT classify an isolated UTF-16 surrogate as a character and MUST NOT insert inside a surrogate pair.

### 3.2 Extended grapheme clusters

Implementations MUST segment text into extended grapheme clusters according to Unicode Standard Annex #29 for Unicode 17.0.

An insertion point MUST be a boundary between two extended grapheme clusters. It MUST NOT split an emoji sequence, combining sequence, or other extended grapheme cluster.

### 3.3 Pinned Unicode properties

Character classification uses the Unicode 17.0 data sources recorded in `unicode/17.0.0/sources.json`. The reproducible language-neutral ranges are tracked in `unicode/17.0.0/classification-ranges.json`.

The generated platform tables are implementation artifacts. The versioned source metadata and this specification are normative.

## 4. Boundary categories

Each extended grapheme cluster is assigned at most one v1 boundary category. Classification uses the first scalar value in the cluster whose General_Category is not `Mn`, `Mc`, or `Me`.

If no such scalar exists, the cluster is `Other`.

### 4.1 Han

A cluster is `Han` when its classification scalar:

1. has `Script=Han` or `Script_Extensions` contains `Han`; and
2. has General_Category `Lo` or `Nl`.

This profile includes unified and compatibility ideographs and the ideographic number zero. It intentionally excludes punctuation, radicals, and symbols merely associated with East Asian text.

### 4.2 Latin

A cluster is `Latin` when its classification scalar:

1. has `Script=Latin` or `Script_Extensions` contains `Latin`; and
2. has a General_Category beginning with `L`.

Combining marks following a Latin base remain part of the same cluster and do not change the category.

### 4.3 ASCII digit

A cluster is `AsciiDigit` only when it consists of one scalar in U+0030–U+0039.

Full-width digits, Arabic-Indic digits, Roman numerals, and other Unicode numbers are not `AsciiDigit` in v1.

### 4.4 Whitespace and Other

A cluster containing a scalar with the Unicode `White_Space` property is `Whitespace`.

Every other cluster is `Other`.

U+200B ZERO WIDTH SPACE does not have the Unicode `White_Space` property and is therefore `Other` in v1.

## 5. Canonical spacing rule

Consider each pair of adjacent extended grapheme clusters.

An insertion is eligible only when the clusters are directly adjacent and their category pair is one of:

- `Han`, `Latin`;
- `Latin`, `Han`;
- `Han`, `AsciiDigit`;
- `AsciiDigit`, `Han`.

For every eligible boundary, canonical normalization inserts exactly one U+0020 SPACE.

No insertion is made when:

- either adjacent cluster is `Whitespace` or `Other`;
- punctuation, an emoji, or another cluster separates the categories;
- the pair is `Latin` and `AsciiDigit` in either direction;
- the field policy is `verbatim`.

The normalizer MUST preserve all existing code units and their order. It may add U+0020 but MUST NOT delete or replace content.

## 6. Required properties

### 6.1 Idempotency

For policy `naturalLanguage`, normalizing an already normalized string MUST return the same string:

```text
normalize(normalize(text)) = normalize(text)
```

### 6.2 Verbatim policy

`verbatim` MUST return the user's text unchanged and MUST produce no automatic patches.

The default field policy is `verbatim`. Applications MUST opt a field into `naturalLanguage` explicitly.

### 6.3 Locality

During ordinary typing, an implementation SHOULD inspect only boundaries affected by the user edit. A paste MAY scan the inserted fragment and its two outer boundaries.

Locality is a performance requirement, not a semantic difference: the result must match the eligible non-suppressed boundaries for the edit session.

## 7. Runtime input rules

Canonical normalization and a live edit session differ in one important way: the session preserves explicit user intent.

### 7.1 Composition safety

If the platform reports an active IME composition/marked range, the adapter MUST return the user's current text unchanged and MUST NOT emit automatic insertion patches.

The adapter MAY evaluate affected boundaries after composition has ended. It MUST use the platform's settled text and selection at that time.

### 7.2 User deletion suppression

If the user deletes a U+0020 at an eligible boundary and the surrounding boundary remains eligible, the adapter MUST NOT immediately reinsert it. This rule does not depend on retaining historical provenance for the space; explicit deletion is sufficient evidence of user intent.

That boundary remains suppressed for the current editing session until one of these occurs:

- either adjacent extended grapheme cluster changes;
- the field policy changes;
- the adapter starts a new editing session.

An unrelated edit elsewhere MUST NOT clear the suppression.

Submitting, saving, or blurring a field MUST NOT silently normalize the deleted space as part of rules v1. An application that wants destructive submit-time normalization must expose it as a separate, explicit operation.

### 7.3 Selection mapping

Automatic insertions are expressed against `afterUserText`, before any automatic patch is applied.

Patches MUST be applied from the greatest UTF-16 offset to the smallest. Each selection endpoint uses downstream affinity: an endpoint at or after an insertion offset moves forward by the inserted UTF-16 length.

The direction of a non-collapsed selection MUST be preserved by mapping its anchor and focus independently.

### 7.4 Native undo and notifications

The adapter SHOULD participate in the platform's native editing transaction. It MUST NOT maintain a second, competing undo history.

The adapter MUST guard against reentrant callbacks caused by its own patch application and SHOULD publish one settled value per user edit.

### 7.5 Length limit

The v1 edit contract may provide `maxLengthUtf16`.

If the user's own text is within the limit but applying all automatic patches would exceed it, the edit remains accepted and the automatic patch set is empty with decision `lengthLimited`.

Rules v1 does not apply a partial subset of automatic spaces. Application-specific limits measured in another unit must be enforced by the platform adapter before invoking the v1 core.

## 8. Patch result

The pure core returns an `EditPlan` containing:

- a decision reason;
- zero or more U+0020 insertion patches;
- the mapped selection;
- the resulting text for conformance comparison.

Every insertion patch uses an offset in `afterUserText`. Patches MUST be non-overlapping, sorted by increasing offset in serialized output, and applied in reverse order.

## 9. Conformance

An implementation conforms to rules v1 when:

1. every case in `fixtures/rules-v1.json` produces the expected text;
2. every applicable scenario in `fixtures/sessions-v1.json` produces the expected decision, patches, text, and selection;
3. all emitted offsets are valid UTF-16 extended-grapheme boundaries;
4. running canonical normalization twice is idempotent;
5. active composition produces no automatic patches.

Platform adapters additionally require their own automated and real-device IME test matrix before being described as production-ready.
