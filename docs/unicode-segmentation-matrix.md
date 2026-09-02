# Unicode segmentation matrix

Rules v1 requires Unicode 17.0 extended-grapheme boundaries. Classification and segmentation are separate gates. All five cores now pin both behaviors to Unicode 17: TypeScript uses the audited upstream package directly, while Swift, Kotlin, C#, and Dart use generated native data plus equivalent state machines.

| Core | Classification | Extended-grapheme segmentation | Current evidence | Remaining release gate |
|---|---|---|---|---|
| TypeScript | Generated Unicode 17 ranges | `unicode-segmenter` 0.17.3, Unicode 17 | Shared fixtures, focused category tests, and the pinned official `GraphemeBreakTest.txt` pass on Node.js 24 | Supported Node, browser, and bundler matrix |
| Swift | Generated Unicode 17 ranges | Generated Unicode 17 data and native state machine | Shared fixtures plus all 766 pinned official cases pass on Swift 6.3.3/macOS | Supported Apple toolchain/OS matrix and real IME acceptance |
| Kotlin/JVM | Generated Unicode 17 ranges | Generated Unicode 17 data and native state machine | Shared fixtures plus all 766 pinned official cases pass on Kotlin 2.0.20/JDK 17 | Supported JDK/Android matrix and real IME acceptance |
| C#/.NET | Generated Unicode 17 ranges | Generated Unicode 17 data and native state machine | Shared fixtures plus all 766 pinned official cases pass on .NET 10.0.11 | Supported .NET/Windows matrix and real IME acceptance |
| Dart | Generated Unicode 17 ranges | Generated Unicode 17 data and native state machine | Shared fixtures plus all 766 pinned official cases pass on Dart 3.13.3 | Supported Dart/Flutter target matrix and real IME acceptance |

The current shared fixtures exercise surrogate pairs, combining marks, and one emoji ZWJ sequence. The full Unicode 17 `GraphemeBreakTest.txt` is pinned and enforced independently by all five core suites.

The dated counts and runtime versions are recorded in [the 2026-09-02 segmentation audit](evidence/unicode-segmentation-2026-09-02.md). They are snapshots, not permanent allowances.

Platform adapters have an additional responsibility: they must never invoke normalization inside an active composing or marked range, even when the pure core's segmentation is correct.
