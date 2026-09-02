# Unicode 17 segmentation audit — 2026-09-02

This snapshot compares the exact extended-grapheme primitive currently used by each core with all 766 cases in Unicode 17.0 `GraphemeBreakTest.txt`.

## Input integrity

- Source: `spec/unicode/17.0.0/GraphemeBreakTest.txt`
- Bytes: 126570
- SHA-256: `e2d134d2c52919bace503ebb6a551c1855fe1a1faec18478c78fff254a1793ec`
- Boundary offsets compared as UTF-16 code units

## Results

| Core primitive | Runtime | Passed | Mismatched | Result |
|---|---|---:|---:|---|
| `unicode-segmenter` 0.17.3 | Node.js 24.14.0 | 766 | 0 | Conforms for this pinned data |
| Swift `Character` | Swift 6.3.3 / macOS | 758 | 8 | Release blocker |
| `BreakIterator.getCharacterInstance` | Java 17.0.18 | 515 | 251 | Release blocker |
| `StringInfo.GetTextElementEnumerator` | .NET 10.0.11 | 749 | 17 | Release blocker |
| `characters` 1.4.1 | Dart 3.13.3 / macOS ARM64 | 757 | 9 | Release blocker |

## Project implementation results

| Project implementation | Runtime | Passed | Mismatched | Result |
|---|---|---:|---:|---|
| `unicode-segmenter` 0.17.3 | Node.js 24.14.0 | 766 | 0 | Conforms for this pinned data |
| Generated Unicode 17 data and `Grapheme17` state machine | Swift 6.3.3 / macOS | 766 | 0 | Conforms for this pinned data |
| Generated Unicode 17 data and `Grapheme17` state machine | Kotlin 2.0.20 / Java 17.0.18 | 766 | 0 | Conforms for this pinned data |
| Generated Unicode 17 data and `Grapheme17` state machine | .NET 10.0.11 | 766 | 0 | Conforms for this pinned data |
| Generated Unicode 17 data and `Grapheme17` state machine | Dart 3.13.3 / macOS ARM64 | 766 | 0 | Conforms for this pinned data |

All project results are enforced by their core conformance suites against the same checked-in file. The TypeScript suite additionally verifies its pinned byte count and SHA-256 before running the cases. The first table preserves diagnostic snapshots of host/library primitives; passing project implementations do not retroactively make those primitives conformant.

## Interpretation

- Generated Unicode 17 classification tables fixed cross-runtime category drift, but do not fix grapheme segmentation.
- The five cores can agree on the current 97 shared fixture checks while still disagreeing with the complete Unicode test data.
- All five cores have cleared the pinned pure-core segmentation gate.
- Native cores remain private references until their supported runtime/OS matrices, packaging, and real IME acceptance are complete.
- Platform IME acceptance remains a separate gate even after pure segmentation reaches 766/766.
