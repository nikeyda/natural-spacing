# Natural Spacing for Jetpack Compose

This experimental adapter targets value-based Compose text fields using `TextFieldValue`. Keep one adapter per field and publish the returned value from `onValueChange`.

```kotlin
var value by remember { mutableStateOf(TextFieldValue()) }
val spacing = remember {
    NaturalSpacingTextFieldValueAdapter(
        initialValue = value,
        policy = FieldPolicy.NATURAL_LANGUAGE,
    )
}

TextField(
    value = value,
    onValueChange = { value = spacing.process(it) },
)
```

The adapter defaults to `FieldPolicy.VERBATIM`. Opt in explicitly as above, or pass `resolvePolicy(...)` for a known semantic content kind. When application state intentionally replaces the field value, call `spacing.sync(value)`. Changing `policy` clears remembered deletion suppressions.

`lastPlan` exposes the most recent settled edit decision for diagnostics. It is
cleared during active composition, external synchronization, reset, and policy
changes; applications must not use it to take ownership of IME composition.

The adapter returns a value with a non-null IME composition unchanged and retains the last settled baseline. It only generates a minimal replacement after Compose reports `composition == null`. This follows the official [`TextFieldValue` composition contract](https://developer.android.com/reference/kotlin/androidx/compose/ui/text/input/TextFieldValue).

State-based `TextFieldState` is the direction recommended by current Compose guidance, but this project does not yet expose an `InputTransformation`: the public transformation receiver does not provide enough composition ownership information for this library to make the same safety claim. See the official [state-based migration guidance](https://developer.android.com/develop/ui/compose/text/migrate-state-based).

Run the host tests from `packages/kotlin`:

```sh
./gradlew :compose:testDebugUnitTest
```

These tests are pure host evidence. Gboard, vendor IMEs, voice input, TalkBack, hardware keyboards, state restoration, and device lifecycle remain acceptance gates.

For manual real-input work, the combined [Android Views and Compose acceptance
host](../../../examples/acceptance/android/README.md) embeds real
`BasicTextField` message and secure surfaces. Compiling its APK is still not
device or IME evidence.
