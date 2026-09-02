#if canImport(UIKit)
import NaturalSpacingCore
import NaturalSpacingUIKit
import SwiftUI
import UIKit

/// Experimental plain-text SwiftUI editor backed by `UITextView`.
///
/// The binding receives native composing text for display, while automatic
/// spacing is deferred until UIKit reports that composition has settled.
@MainActor
public struct NaturalSpacingTextEditor: UIViewRepresentable {
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

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.text = text
        context.coordinator.adapter.beginEditing(in: textView)
        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.adapter.policy = policy
        context.coordinator.adapter.maxLengthUtf16 = maxLengthUtf16
        guard textView.text != text else { return }
        textView.text = text
        context.coordinator.adapter.sync(in: textView)
    }

    @MainActor
    public final class Coordinator: NSObject, UITextViewDelegate {
        fileprivate var text: Binding<String>
        fileprivate let adapter: NaturalSpacingUIKitAdapter

        fileprivate init(
            text: Binding<String>,
            policy: FieldPolicy,
            maxLengthUtf16: Int?
        ) {
            self.text = text
            adapter = NaturalSpacingUIKitAdapter(
                policy: policy,
                maxLengthUtf16: maxLengthUtf16
            )
        }

        public func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText value: String
        ) -> Bool {
            let accepted = adapter.shouldChange(
                in: textView,
                range: range,
                replacementText: value
            )
            if !accepted { publish(textView.text) }
            return accepted
        }

        public func textViewDidChange(_ textView: UITextView) {
            adapter.textViewDidChange(textView)
            publish(textView.text)
        }

        private func publish(_ value: String) {
            if text.wrappedValue != value { text.wrappedValue = value }
        }
    }
}
#endif
