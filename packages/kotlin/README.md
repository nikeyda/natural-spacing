# Natural Spacing Kotlin

Private Kotlin/JVM reference core. Rules, interactive sessions, policy recommendation, and ASR/non-interactive text updates currently match all 97 shared fixture checks, with four additional proposed-edit checks and 23 ordered text-update operations, on Kotlin 2.0.20 and JDK 17. Its generated Unicode 17 segmenter also passes all 766 pinned official grapheme cases.

```kotlin
val context = PolicyContext(contentKind = ContentKind.MESSAGE)
val recommendation = recommendPolicy(context)
val policy = resolvePolicy(context)
val text = NaturalSpacing.normalize("今天发布v2版本", policy)
```

`resolvePolicy` uses a recommendation only when `autoApply` is true; otherwise it returns `VERBATIM` or a caller-supplied fallback.

Secure/password context always resolves to `VERBATIM`, even when the explicit policy is `NATURAL_LANGUAGE`. Outside secure input, the explicit policy wins.

Revision-capable ASR and dictation providers can use `OrderedTextUpdateSession`; see [the five-language ordered-update guide](../../docs/ordered-text-updates.md).

Run with the checked-in Gradle 8.13 wrapper:

```sh
./gradlew --no-daemon conformance
```

The wrapper distribution is protected by its official SHA-256 checksum. The repository does not yet include a published artifact. Two experimental Android library modules are present:

- `android/`: an `EditText`/`TextWatcher` adapter;
- `compose/`: a stateful value-based `TextFieldValue` adapter for Compose UI Text 1.11.3.

Run their current compile and host-test gates with:

```sh
./gradlew :android-views:testDebugUnitTest :android-views:assembleDebug :compose:testDebugUnitTest
```

Both modules compile against API 35. Android Views has twelve Robolectric `EditText` host tests, including password input-type and transformation fail-safes, recovery when an `InputFilter` alters or throws, and host-owned value synchronization including a throwing update block; Compose has seven value-adapter host tests. The independent consumer under `examples/consumers/kotlin/android-host` imports both adapters through temporary composite substitutions and assembles a Debug AAR, proving source consumption without assigning public Maven coordinates. Neither module has device or real IME acceptance. Classification and segmentation use generated Unicode 17 data rather than JDK Unicode behavior.
