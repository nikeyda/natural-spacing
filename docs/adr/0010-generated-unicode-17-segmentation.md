# ADR 0010: Generate deterministic Unicode 17 segmentation data

- Status: Accepted for MVP
- Date: 2026-09-02

## Context

Rules v1 uses Unicode 17.0 extended-grapheme boundaries and UTF-16 offsets. Host primitives do not provide the same behavior: the 2026-09-02 audit found 8 mismatches for Swift `Character`, 251 for JDK 17 `BreakIterator`, 17 for .NET 10 `StringInfo`, and 9 for Dart `characters` 1.4.1 across the 766 official Unicode 17 cases.

The TypeScript core already uses `unicode-segmenter` 0.17.3 and passes the complete pinned test data. Shipping different host-dependent behavior in every language would make cursor mapping and edit plans disagree at exactly the boundaries the shared contract is intended to standardize.

## Decision

Use `unicode-segmenter` 0.17.3 as the reviewed implementation source and pin its MIT attribution. `scripts/generate-grapheme-tables.mjs` materializes its Unicode 17 categories, pair masks, and Indic linker set into `spec/unicode/17.0.0/grapheme-segmentation.json`.

Native ports render deterministic tables from that language-neutral artifact and use the same small UAX #29 state machine. The Swift, Kotlin, C#, and Dart ports perform binary lookup over 1,618 compressed ranges, report UTF-16 boundaries, and independently pass all 766 cases in the pinned `GraphemeBreakTest.txt` on their audited runtimes.

The generated artifact is validated for its pinned source package, category map, scalar bounds, ordering, disjointness, maximal compression, pair-mask vocabulary, and sorted linker set. Generation and stale-file checks are part of normal repository validation.

Every native core renders its table from the same artifact; normal repository validation rejects stale generated source.

## Consequences

- Core behavior no longer depends on the Unicode version bundled with a host runtime.
- TypeScript and native ports share traceable data and equivalent state transitions without requiring a JSON parser at runtime.
- Generated native tables increase source size; correctness and auditability take priority over premature compression in the MVP.
- Passing the 766 pure segmentation cases does not prove platform adapter, IME, selection, undo, or real-device behavior.
- Unicode upgrades require reviewing the upstream implementation, regenerating all artifacts, and rerunning every native conformance suite.
