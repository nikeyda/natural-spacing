# ADR 0012: Web native binding uses a hybrid input path to preserve undo

- Status: Accepted for experimental Web adapter
- Date: 2026-09-02
- Supersedes: ADR 0006 for the native binding

## Context

ADR 0006 chose post-input reconciliation for every Web edit. Real-browser tests confirmed the text, composition deferral, selection, deletion-intent, and lifecycle behavior, but also found that applying the automatic replacement with `setRangeText` after the native `input` event invalidated the control's undo transaction in Chrome 152 and Edge 151. A control experiment showed native typing could undo and redo normally, while the post-input replacement could not.

[Input Events Level 2](https://www.w3.org/TR/input-events-2/) defines `beforeinput` as cancellable for non-composition edits such as `insertText`, and exposes inserted plain text through `InputEvent.data`. Events inside an active IME composition are not cancellable. There is no modern standard API for replacing an `input` or `textarea` selection while joining the browser's native undo transaction; Chromium's supported `insertText` editing command preserves that transaction, but the command is a legacy compatibility surface.

## Decision

Use a narrow hybrid path in `bindNaturalSpacing`:

1. For a cancellable, non-composing `insertText` or `insertFromPaste` event with string data, a synchronized baseline, and browser support for the `insertText` command, preview the proposed edit through the shared contract.
2. Intercept only when the preview requires automatic spacing. Process the stateful session exactly once, cancel the native event, and insert the planned replacement through the browser editing command.
3. If command execution unexpectedly fails after interception, fail safe to the same minimal `setRangeText` replacement and emit an `input` event so text is not lost.
4. Let unchanged, `.verbatim`, length-limited, deleting, composing, unsupported, and unsynchronized edits follow the native edit and existing post-input reconciliation path.
5. Keep the runtime-free React-compatible handler on the post-input path. For React integrations that require the verified undo behavior, attach `bindNaturalSpacing` directly to the DOM ref, publish the transformed value synchronously through React `onChange`, and call `sync()` after external renders. Verify this path in a real React controlled/uncontrolled browser fixture.

## Consequences

- Normal typing that requires spacing preserves one browser undo/redo transaction in the verified Chrome, Edge, Playwright Firefox, and Playwright WebKit matrix. Chromium also verifies the system clipboard path; Firefox/WebKit currently verify the specified synthetic paste/beforeinput sequence.
- Active IME text is still never cancelled or rewritten; composition commit remains a post-input path and requires real-IME undo acceptance.
- The legacy editing command is tightly scoped behind capability checks and is not presented as cross-browser support.
- React 19.2.8 controlled/uncontrolled input, external reset, and ordinary-input undo/redo pass through DOM-ref binding in all four local engines.
- Release Safari/Firefox, mobile browsers, non-Chromium system clipboard, autofill, assistive input, React composition/paste/concurrency/hydration, real IMEs, and command-fallback behavior remain explicit acceptance gates.
