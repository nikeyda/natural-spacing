#if canImport(AppKit)
import AppKit
import NaturalSpacingAppKit
import NaturalSpacingCore
import SwiftUI

/// Experimental plain-text SwiftUI editor backed by `NSTextView`.
///
/// The binding receives native marked text for display, while automatic
/// spacing is deferred until AppKit reports that composition has settled.
@MainActor
public struct NaturalSpacingTextEditor: NSViewRepresentable {
    @Binding private var text: String
    private let policy: FieldPolicy
    private let maxLengthUtf16: Int?

    public init(
        text: Binding<String>,
        policy: FieldPolicy = .verbatim,
        maxLengthUtf16: Int? = nil
    ) {
        _text = text
        self.policy = policy
        self.maxLengthUtf16 = maxLengthUtf16
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, policy: policy, maxLengthUtf16: maxLengthUtf16)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.string = text
        scrollView.documentView = textView
        context.coordinator.adapter.beginEditing(in: textView)
        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.adapter.policy = policy
        context.coordinator.adapter.maxLengthUtf16 = maxLengthUtf16
        guard let textView = scrollView.documentView as? NSTextView,
            textView.string != text
        else {
            return
        }
        textView.string = text
        context.coordinator.adapter.sync(in: textView)
    }

    @MainActor
    public final class Coordinator: NSObject, NSTextViewDelegate {
        fileprivate var text: Binding<String>
        fileprivate let adapter: NaturalSpacingAppKitAdapter

        fileprivate init(
            text: Binding<String>,
            policy: FieldPolicy,
            maxLengthUtf16: Int?
        ) {
            self.text = text
            adapter = NaturalSpacingAppKitAdapter(
                policy: policy,
                maxLengthUtf16: maxLengthUtf16
            )
        }

        public func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            let accepted = adapter.shouldChangeText(
                in: textView,
                range: affectedCharRange,
                replacementString: replacementString
            )
            if !accepted { publish(textView.string) }
            return accepted
        }

        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            adapter.textDidChange(in: textView)
            publish(textView.string)
        }

        private func publish(_ value: String) {
            if text.wrappedValue != value { text.wrappedValue = value }
        }
    }
}
#endif
