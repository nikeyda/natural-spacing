# Android Views and Compose host evidence — 2026-09-02

This is Robolectric host-control evidence, not emulator, real-keyboard, real-IME, accessibility, dictation, or physical-device acceptance.

## Environment

- macOS 26.5.2 arm64;
- OpenJDK 17.0.18;
- Gradle 8.13 with Kotlin plugin 2.0.20 and Android Gradle Plugin 8.11.1;
- Android compile SDK 35 and minimum SDK 23;
- Robolectric 4.16, pinned as a test-only dependency.

## Command

Run from `packages/kotlin`:

```sh
./gradlew --no-daemon :android-views:testDebugUnitTest
```

## Result

`NaturalSpacingEditTextAdapterTest`: 12/12 passed against Robolectric API 35.

The tests attach a real `EditText` to a Robolectric `Activity` and cover:

- direct ASCII-digit insertion with text and selection publication;
- `.verbatim` preserving the native edit;
- password `inputType` forcing `verbatim` even when `naturalLanguage` is configured;
- `PasswordTransformationMethod` forcing the same fail-safe;
- active composing-span deferral followed by settled reconciliation;
- user deletion of an automatically inserted space without immediate reinsertion;
- host `InputFilter` alteration or exception while applying automatic spaces preserving the native text, selection, settled baseline, and future reconciliation;
- controlled `sync { ... }` host updates bypassing synchronous watcher interpretation and clearing deletion intent;
- plain `sync()` adopting the current control value and clearing deletion intent;
- throwing `sync { ... }` updates restoring the watcher guard and adopting the actual changed value before propagating the exception;
- adapter detachment stopping further reconciliation.

The API 35 Release AAR also assembles separately. Robolectric and JUnit are test-only dependencies and do not enter the adapter's runtime dependency graph.

## Compose adapter result

`NaturalSpacingTextFieldValueAdapterTest`: 7/7 passed. The same tests now also
verify that the public read-only `lastPlan` reports settled applied/verbatim
decisions and is cleared for active composition and external synchronization.

## Manual acceptance APK compile

Command:

```sh
bash scripts/test-android-acceptance-host.sh
```

The source-composite application imports both public Android Views and Compose
adapter modules. Its single scrollable screen exposes equivalent
natural-language and secure fail-safe editors for both UI systems. The Compose
surface additionally shows recommendation confidence/reason, composition,
selection, and `lastPlan` while hiding password text.

Android Lint reported no issues and the Debug APK assembled successfully. The
APK manifest reports application ID `dev.naturalspacing.acceptance.android`,
minimum SDK 23, target/compile SDK 35. DEX inspection confirms the app's Compose
code and `NaturalSpacingTextFieldValueAdapter` are present. The APK was not
installed or launched.

## Limits

No Android application or IME was launched. This evidence does not establish Gboard or vendor-IME event ordering, voice input, TalkBack, hardware keyboards, paste UI, autofill, undo/back behavior, rich spans, process restoration, activity/fragment lifecycle, supported API-level coverage, or physical-device behavior.
