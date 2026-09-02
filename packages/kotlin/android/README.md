# Natural Spacing Android Views

Experimental Android library module for `EditText`, built on the shared Kotlin session contract.

Build it from `packages/kotlin`:

```sh
./gradlew :android-views:testDebugUnitTest :android-views:assembleDebug
```

```kotlin
val spacing = NaturalSpacingEditTextAdapter(
    editText = binding.message,
    policy = FieldPolicy.NATURAL_LANGUAGE,
).attach()

override fun onDestroyView() {
    spacing.detach()
    super.onDestroyView()
}
```

The adapter coexists with existing `TextWatcher` instances, changes only the current minimal UTF-16 replacement, maps selection, preserves manual deletion of inserted spaces, and delays reconciliation while Android composing spans are active. If an `InputFilter` rejects, alters, or throws while applying the automatic replacement, the adapter restores its reentrancy guard, preserves the native text and selection, clears speculative session state, and adopts the actual control value as its baseline before propagating any host exception.

Because `EditText.setText()` invokes watchers synchronously, wrap intentional host updates so they cannot be mistaken for user input:

```kotlin
spacing.sync {
    binding.message.setText(modelValue)
    binding.message.setSelection(modelValue.length)
}
```

The block overload resets deletion intent and adopts the actual value even if the host update throws. The no-argument `sync()` remains available to adopt a value already changed by another controlled mechanism, and now also resets deletion intent.

Twelve Robolectric 4.16 host tests exercise an `EditText` attached to an `Activity`: ASCII-digit insertion, `.verbatim`, password `inputType` and `PasswordTransformationMethod` fail-safes, composing-span settlement, automatic-space deletion suppression, `InputFilter` alteration/exception recovery, controlled/plain synchronization including a throwing update block, and detachment. They are host evidence, not emulator, real IME, accessibility, or device evidence. Gboard, vendor IMEs, dictation, accessibility input, paste, password-manager/autofill, undo/back behavior, rich spans, lifecycle, and real devices remain mandatory acceptance gates. Compose is provided as a separate experimental module.
