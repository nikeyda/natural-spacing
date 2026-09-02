# NaturalSpacing Swift

Private Swift reference package containing the Foundation core and experimental UIKit/AppKit adapters. The package is not published and does not claim production Apple-platform support.

```swift
import NaturalSpacingCore

let context = PolicyContext(contentKind: .transcript)
let recommendation = NaturalSpacing.recommendPolicy(context)
let policy = NaturalSpacing.resolvePolicy(context)

let text = NaturalSpacing.normalize(
    "今天发布v2版本",
    policy: policy
)
```

Secure/password context always resolves to `.verbatim`, even when the explicit policy is `.naturalLanguage`. Outside secure input, the explicit policy wins.

For revision-capable ASR or dictation, use `OrderedTextUpdateSession`. Its behavior is shared with TypeScript, Kotlin, C#, and Dart through 23 language-neutral operations; see [the ordered-update guide](../../docs/ordered-text-updates.md).

Use one adapter instance per editor. The adapter does not take ownership of a control's delegate. Application validation should run first, then forward accepted edits.

## UIKit

Forward `UITextFieldDelegate` or `UITextViewDelegate` callbacks and the corresponding did-change callback. The latter reconciles committed IME text only after `markedTextRange` becomes `nil`.

```swift
import NaturalSpacingUIKit

let spacing = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)

func textFieldDidBeginEditing(_ textField: UITextField) {
    spacing.beginEditing(in: textField)
}

func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
) -> Bool {
    spacing.shouldChange(in: textField, range: range, replacementString: string)
}

@objc func editingChanged(_ textField: UITextField) {
    spacing.editingChanged(in: textField)
}
```

For paste, pass `editKind: .paste`. iOS 26 multi-range overloads intentionally pass through edits containing more than one range.

`beginEditing(in:)` starts a fresh editor lifecycle: it clears remembered manual-space deletions and adopts the control's current value. After an intentional programmatic value replacement, call `sync(in:)` to perform the same reset without implying a focus event:

```swift
textField.text = modelValue
spacing.sync(in: textField)
```

UIKit forces an effective `.verbatim` policy whenever `isSecureTextEntry` is true, even if the adapter was configured with `.naturalLanguage`.

## AppKit

`NSTextView` can use its should-change callback plus `textDidChange(in:)`. An `NSTextField` uses a shared `NSTextView` field editor, so seed and reconcile that editor from `controlTextDidBeginEditing` and `controlTextDidChange`.

The field editor does not reliably expose whether its owning field is secure. Resolve `.verbatim` before creating an AppKit adapter for sensitive input, and do not treat the UIKit fail-safe as AppKit evidence.

```swift
import NaturalSpacingAppKit

let spacing = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

func textDidBeginEditing(_ notification: Notification) {
    guard let textView = notification.object as? NSTextView else { return }
    spacing.beginEditing(in: textView)
}

func textView(
    _ textView: NSTextView,
    shouldChangeTextIn affectedCharRange: NSRange,
    replacementString: String?
) -> Bool {
    spacing.shouldChangeText(
        in: textView,
        range: affectedCharRange,
        replacementString: replacementString
    )
}

func textDidChange(_ notification: Notification) {
    guard let textView = notification.object as? NSTextView else { return }
    spacing.textDidChange(in: textView)
}
```

As on UIKit, `beginEditing(in:)` clears prior deletion intent. Use `sync(in:)` after an intentional programmatic value replacement.

The AppKit path uses `performValidatedReplacement`. Automated host tests cover `NSTextView`, an `NSTextField` field editor inside an `NSWindow`, selection, native undo and change notification, marked-text settlement, deletion suppression, and multi-range fail-open. These checks are not a substitute for real input-source, dictation, accessibility, field-editor lifecycle, or application acceptance.

## SwiftUI

The experimental `NaturalSpacingTextEditor` is a minimal multi-line wrapper backed by `UITextView` on iOS and `NSTextView` on macOS. It reuses the native adapters so marked text is deferred rather than normalized in place.

```swift
import NaturalSpacingSwiftUI
import SwiftUI

struct NotesView: View {
    @State private var text = ""

    var body: some View {
        NaturalSpacingTextEditor(
            text: $text,
            policy: .naturalLanguage
        )
    }
}
```

The wrapper defaults to `.verbatim`; pass `.naturalLanguage` explicitly or use `NaturalSpacing.resolvePolicy` when product semantics allow automatic resolution. It has macOS construction, default-policy, and direct/settled binding-publication evidence plus iOS Simulator default-policy and transformed-binding evidence. It does not yet claim real keyboard, IME, dictation, accessibility, lifecycle, or device acceptance.

The core uses generated Unicode 17 tables for classification and segmentation rather than Swift runtime Unicode behavior. Its native state machine passes all 766 pinned official grapheme cases on Swift 6.3.3/macOS. The supported Apple toolchain/OS matrix remains open.

Run the shared-fixture tests from the repository root:

```sh
swift test
```
