# macOS AppKit and SwiftUI real-input acceptance host

This executable is a manual evidence harness for the experimental AppKit and
SwiftUI adapters. It depends on the repository's public Core, AppKit, and
SwiftUI products and is not part of the library package or an automated-support
claim. The window contains two tabs:

- AppKit: marked-text, selection, `lastPlan`, policy, and current text;
- SwiftUI: public `NaturalSpacingTextEditor` message/code bindings with
  automatic natural-language/verbatim recommendation diagnostics.

Run it with:

```sh
swift run \
  --package-path examples/acceptance/macos \
  --scratch-path /tmp/natural-spacing-macos-acceptance \
  NaturalSpacingMacOSAcceptanceHost
```

Use only synthetic text. Before a result can count as real-input evidence,
record the hardware, macOS version, exact input source, repository revision,
host control, and each attempted scenario from `docs/platform-acceptance.md`.
Compare both tabs under the same named input source. The AppKit status exposes
the resolved policy, marked-text state, selection, last spacing decision, and
current text; the SwiftUI status exposes policy recommendation and binding
publication.

At minimum, exercise:

1. Han then Latin and Latin then Han.
2. Han then ASCII digit and ASCII digit then Han.
3. Pinyin composition without modification of active marked text.
4. Deletion of an inserted space, followed by another edit at the same boundary.
5. Selection replacement, paste, native undo/redo, focus loss/restoration, and reset.

Do not call a row passed from visual text alone. Inspect composition, selection,
undo, and lifecycle behavior separately, and record unexecuted rows as `not run`.
