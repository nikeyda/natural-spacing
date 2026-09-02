# ADR 0006: Web adapters reconcile native input instead of cancelling beforeinput

- Status: Superseded by ADR 0012
- Date: 2026-09-02

## Context

Cancelling `beforeinput` and synthesizing a replacement can interfere with browser undo, autofill, accessibility input, framework event delegation, and IME behavior. Paste data is also not consistently available through one pre-edit event path. Assigning the whole `value` loses the minimal-edit and selection contracts.

## Decision

Let the browser perform the native edit. During the target's `input` event, compare the control value with the last settled value, derive one minimal UTF-16 replacement, and process it through the shared session contract. If spaces are needed, apply only that current replacement span with `setRangeText` and restore the mapped selection.

Composition events keep the previous settled value and perform no rewrite while active. Reconciliation runs after composition ends. Host-controlled programmatic updates call `sync()` explicitly. React integration uses compatible handler shapes and an `onValueChange` callback without making React a runtime dependency.

## Consequences

- Native editing occurs before library reconciliation and existing event ownership remains with the host.
- Other listeners later in the same event propagation can read the transformed control value.
- The adapter supports plain-text, single-selection `input` and `textarea` only.
- Browser undo grouping, event ordering, real IMEs, autofill, accessibility input, controlled React rendering, and hydration require real-browser acceptance before support is claimed.
