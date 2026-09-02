# ADR 0009: Generate deterministic Unicode classification tables

- Status: Accepted for MVP
- Date: 2026-09-02

## Context

Rules v1 pins Unicode 17.0, but language runtimes expose different Unicode versions and property APIs. Using host regular expressions, Foundation character sets, JVM character methods, or framework helpers directly can therefore classify the same scalar differently across platforms.

Extended-grapheme segmentation and boundary-category classification are separate concerns. A reusable UAX #29 implementation can solve segmentation, while rules v1 still needs its narrower Han, Latin, mark, and whitespace profile.

## Decision

The repository pins official Unicode 17.0 source URLs, byte counts, and SHA-256 digests in `spec/unicode/17.0.0/sources.json`.

`scripts/generate-unicode-tables.mjs` verifies those digests, evaluates the rules v1 property intersections, and emits:

- `spec/unicode/17.0.0/classification-ranges.json`, the language-neutral derived artifact;
- native generated tables for the TypeScript, Swift, Kotlin, C#, and Dart cores.

Generated ranges are sorted, disjoint, and maximally compressed. Normal tests validate the JSON structure and verify that every native table exactly matches it. A stronger `--check` mode recomputes all artifacts from a local copy of the pinned UCD files.

All five reference cores use the generated tables for classification. The TypeScript core additionally uses `unicode-segmenter` 0.17.3 for Unicode 17 extended-grapheme segmentation, so it does not use the host runtime's Unicode property escapes or `Intl.Segmenter` for rules v1 behavior.

Future cores should generate native tables from the language-neutral artifact or consume it at build time. They must not treat a passing host-runtime test as proof that the pinned Unicode profile is deterministic.

## Consequences

- Classification results can be reproduced independently of the runtime's Unicode release.
- Cross-language ports share one reviewable set of numeric ranges.
- The repository tracks generated data, but does not vendor the full UCD source files.
- Unicode upgrades require an explicit metadata, generator, segmentation, fixture, and cross-language compatibility review; changing only a runtime dependency is insufficient.
- Segmentation is handled separately by the generated-data decision in ADR 0010.
