# ADR 0005: Platform adapters forward delegates and reconcile settled text

- Status: Accepted for experimental Apple adapters
- Date: 2026-09-02

## Context

UIKit and AppKit applications commonly already own their text-control delegates. Replacing those delegates with a library proxy creates lifecycle, validation, notification, and retention conflicts. Rewriting a control's entire text value also risks losing attributed content, selection, and native undo behavior.

IME composition must remain untouched, but some input systems expose the final committed value only through a did-change callback. AppKit `NSTextField` also edits through a shared `NSTextView` field editor rather than exposing a range-based delegate callback itself.

## Decision

Adapters never own or replace host delegates. The host forwards accepted single-range should-change callbacks and did-change callbacks to one adapter instance per editor.

Pre-edit handling transforms only the proposed replacement fragment. UIKit applies it through `UITextInput.replace`; AppKit uses `performValidatedReplacement`. During marked text, the adapter passes edits through. After the marked range clears, a UTF-16 minimal diff against the last settled text is reconciled through the same core proposed-edit contract.

Multi-range edits are passed through unchanged in the first adapter milestone. Ambiguous or invalid platform ranges fail open to native editing.

## Consequences

- Existing delegate ownership and application validation remain intact.
- AppKit changes participate in native validated replacement and undo.
- Composition is not rewritten while active, and committed text has a reconciliation path.
- Integrators must forward lifecycle callbacks and keep one adapter per editor.
- Multi-range behavior, UIKit undo/notification behavior, real IME commit timing, dictation, rich text, and field-editor behavior remain acceptance gates rather than supported claims.
