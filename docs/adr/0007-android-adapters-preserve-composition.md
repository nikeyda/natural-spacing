# ADR 0007: Android adapters preserve platform composition state

- Status: Accepted for experimental Android Views; Compose portion superseded by ADR 0011
- Date: 2026-09-02

## Context

Android editable text carries an explicit composing span. Replacing the whole `Editable` from a `TextWatcher` can destroy that span, disturb the IME connection, and fragment selection or undo behavior. Compose state-based text fields expose user edits through `TextFieldState` and `InputTransformation`, with composition and selection represented in the state buffer.

## Proposed decision

The Android Views adapter will read composing bounds from `BaseInputConnection.getComposingSpanStart` and `getComposingSpanEnd`. It will not rewrite while either bound is active. After composition settles, it will derive one UTF-16 difference from the last settled value and apply only that minimal replacement through the existing `Editable`, restoring selection and guarding re-entrant watchers. Because host `InputFilter` instances may alter, reject, or throw while processing the automatic replacement, the adapter will restore its guard in all paths and adopt the actual control text as its new baseline whenever the planned result does not land.

Intentional host-owned changes use `sync { ... }`, which keeps the watcher guarded while synchronous `setText` callbacks run, then resets deletion intent and adopts the actual value. A no-argument `sync()` is retained for values already changed through another controlled path and performs the same state reset.

The original Compose proposal targeted state-based text fields and a custom `InputTransformation`. ADR 0011 supersedes that portion after review of the public composition APIs; the Android Views decision remains unchanged.

Both adapters will resolve `.naturalLanguage` or `.verbatim` before the editing session and keep that policy stable until an explicit field lifecycle change.

## Acceptance gates

- Shared Kotlin fixtures continue to pass on supported Android runtimes.
- Gboard, representative vendor IMEs, dictation, hardware keyboard, paste, selection replacement, deletion suppression, max length, accessibility input, and undo/back behavior pass on real devices.
- Compose tests and real-input records prove composing ranges are never modified and only one settled value is published per edit.
