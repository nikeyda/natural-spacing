# ADR 0011: Use a value-based Compose adapter while composition ownership is explicit

- Status: Accepted for experimental adapter
- Date: 2026-09-02

## Context

Compose `TextFieldValue` exposes the IME-owned composition as `TextRange?`. Its contract states that passing a value with `composition = null` while a composition exists applies that composition. Therefore a formatter must return an actively composing value unchanged, including its composition object.

Current state-based text fields are the direction recommended by Android. `TextFieldState` exposes composition, but the public `InputTransformation` receiver is a `TextFieldBuffer`; it is designed to mutate user input and does not provide the same explicit composition-ownership check inside the transformation. Mutating external state from an input transformation is also discouraged.

## Decision

The first public Compose bridge is a stateful `NaturalSpacingTextFieldValueAdapter` for value-based fields.

- Keep one adapter per field and initialize it from the field's current value.
- When `value.composition != null`, return that exact `TextFieldValue` instance and keep the last settled baseline unchanged.
- After composition becomes null, derive one UTF-16 difference from the last settled text and pass it through the shared Kotlin session.
- Return `TextFieldValue.copy` only for a settled automatic replacement, preserving selection direction and leaving composition null.
- Require `sync` after an intentional external/programmatic state replacement.
- Do not expose a state-based `InputTransformation` until its implementation can prove the same composition guarantees through public API and real IME tests.

## Consequences

- The adapter can explicitly preserve IME ownership and reuse the same deletion-suppression contract as Android Views.
- Value-based Compose fields retain their known state-synchronization responsibilities; `sync` makes the external reset boundary explicit.
- Seven host tests cover composition deferral and commit, selection direction, manual space deletion, policy and length pass-through, external reset, and the safe default `.verbatim` policy.
- Host tests and API 35 compilation do not establish Gboard, vendor IME, voice input, TalkBack, hardware keyboard, state restoration, or device support.
