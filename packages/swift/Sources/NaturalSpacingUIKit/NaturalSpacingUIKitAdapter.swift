#if canImport(UIKit)
import NaturalSpacingCore
import UIKit

/// Experimental single-selection adapter for `UITextField` and `UITextView`.
///
/// Forward the control's delegate callback here only after application validation
/// has accepted the edit. The adapter never owns or replaces the control's delegate.
@MainActor
public final class NaturalSpacingUIKitAdapter {
    public var policy: FieldPolicy
    public var maxLengthUtf16: Int?
    public private(set) var lastPlan: EditPlan?

    private let session = NaturalSpacingSession()
    private var isApplyingReplacement = false
    private var settledText: String?

    public init(
        policy: FieldPolicy,
        maxLengthUtf16: Int? = nil
    ) {
        self.policy = policy
        self.maxLengthUtf16 = maxLengthUtf16
    }

    public func reset() {
        session.reset()
        lastPlan = nil
        settledText = nil
    }

    public func beginEditing(in textField: UITextField) {
        sync(in: textField)
    }

    public func beginEditing(in textView: UITextView) {
        sync(in: textView)
    }

    /// Resets editor intent and adopts a host-controlled text-field value.
    public func sync(in textField: UITextField) {
        session.reset()
        lastPlan = nil
        settledText = textField.text ?? ""
    }

    /// Resets editor intent and adopts a host-controlled text-view value.
    public func sync(in textView: UITextView) {
        session.reset()
        lastPlan = nil
        settledText = textView.text ?? ""
    }

    /// Forward `editingChanged` after native text-field edits.
    public func editingChanged(in textField: UITextField) {
        reconcileSettledText(
            in: textField,
            currentText: textField.text ?? "",
            policy: effectivePolicy(for: textField)
        )
    }

    /// Forward `textViewDidChange` after native text-view edits.
    public func textViewDidChange(_ textView: UITextView) {
        reconcileSettledText(
            in: textView,
            currentText: textView.text ?? "",
            policy: effectivePolicy(for: textView)
        )
    }

    /// Returns the value that the host delegate should return.
    /// A `false` result means the adapter applied a transformed replacement itself.
    public func shouldChange(
        in textField: UITextField,
        range: NSRange,
        replacementString: String,
        editKind: EditKind? = nil
    ) -> Bool {
        shouldChange(
            in: textField,
            currentText: textField.text ?? "",
            range: range,
            replacementString: replacementString,
            editKind: editKind,
            policy: effectivePolicy(for: textField)
        )
    }

    @available(iOS 26.0, *)
    public func shouldChange(
        in textField: UITextField,
        ranges: [NSRange],
        replacementString: String,
        editKind: EditKind? = nil
    ) -> Bool {
        guard ranges.count == 1, let range = ranges.first else {
            lastPlan = nil
            return true
        }
        return shouldChange(
            in: textField,
            range: range,
            replacementString: replacementString,
            editKind: editKind
        )
    }

    /// Returns the value that the host delegate should return.
    /// A `false` result means the adapter applied a transformed replacement itself.
    public func shouldChange(
        in textView: UITextView,
        range: NSRange,
        replacementText: String,
        editKind: EditKind? = nil
    ) -> Bool {
        shouldChange(
            in: textView,
            currentText: textView.text ?? "",
            range: range,
            replacementString: replacementText,
            editKind: editKind,
            policy: effectivePolicy(for: textView)
        )
    }

    @available(iOS 26.0, *)
    public func shouldChange(
        in textView: UITextView,
        ranges: [NSRange],
        replacementText: String,
        editKind: EditKind? = nil
    ) -> Bool {
        guard ranges.count == 1, let range = ranges.first else {
            lastPlan = nil
            return true
        }
        return shouldChange(
            in: textView,
            range: range,
            replacementText: replacementText,
            editKind: editKind
        )
    }

    private func shouldChange(
        in input: any UITextInput,
        currentText: String,
        range: NSRange,
        replacementString: String,
        editKind: EditKind?,
        policy: FieldPolicy
    ) -> Bool {
        if isApplyingReplacement { return true }
        guard let nativeRange = textRange(for: range, in: input) else { return true }

        let proposedEdit = ProposedEdit(
            text: currentText,
            range: TextRange(start: range.location, length: range.length),
            replacementText: replacementString,
            composingRange: markedRange(in: input),
            editKind: editKind ?? inferredEditKind(range: range, replacement: replacementString),
            policy: policy,
            maxLengthUtf16: maxLengthUtf16
        )
        guard let result = try? session.processProposedEdit(proposedEdit) else { return true }
        lastPlan = result.plan
        guard result.requiresReplacement else { return true }

        isApplyingReplacement = true
        input.replace(nativeRange, withText: result.replacementText)
        setSelection(result.plan.selection, in: input)
        isApplyingReplacement = false
        settledText = result.plan.resultText
        return false
    }

    private func reconcileSettledText(
        in input: any UITextInput,
        currentText: String,
        policy: FieldPolicy
    ) {
        if isApplyingReplacement { return }
        if input.markedTextRange != nil { return }
        guard let beforeText = settledText else {
            settledText = currentText
            return
        }
        guard let proposedEdit = ProposedEdit.replacingDifference(
            from: beforeText,
            to: currentText,
            selectionAfterEdit: selection(in: input),
            policy: policy,
            maxLengthUtf16: maxLengthUtf16
        ) else {
            return
        }
        guard let result = try? session.processProposedEdit(proposedEdit) else {
            settledText = currentText
            return
        }
        lastPlan = result.plan
        guard result.requiresReplacement else {
            settledText = currentText
            return
        }

        let currentRange = NSRange(
            location: proposedEdit.range.start,
            length: proposedEdit.replacementText.utf16.count
        )
        guard let nativeRange = textRange(for: currentRange, in: input) else {
            settledText = currentText
            return
        }
        isApplyingReplacement = true
        input.replace(nativeRange, withText: result.replacementText)
        setSelection(result.plan.selection, in: input)
        isApplyingReplacement = false
        settledText = result.plan.resultText
    }

    private func effectivePolicy(for textField: UITextField) -> FieldPolicy {
        textField.isSecureTextEntry ? .verbatim : policy
    }

    private func effectivePolicy(for textView: UITextView) -> FieldPolicy {
        textView.isSecureTextEntry ? .verbatim : policy
    }

    private func markedRange(in input: any UITextInput) -> TextRange? {
        guard let marked = input.markedTextRange else { return nil }
        let start = input.offset(from: input.beginningOfDocument, to: marked.start)
        let end = input.offset(from: input.beginningOfDocument, to: marked.end)
        guard start >= 0, end >= start else { return nil }
        return TextRange(start: start, length: end - start)
    }

    private func textRange(for range: NSRange, in input: any UITextInput) -> UITextRange? {
        guard range.location != NSNotFound,
            let start = input.position(from: input.beginningOfDocument, offset: range.location),
            let end = input.position(from: start, offset: range.length)
        else {
            return nil
        }
        return input.textRange(from: start, to: end)
    }

    private func setSelection(_ selection: TextSelection, in input: any UITextInput) {
        let lower = min(selection.anchor, selection.focus)
        let upper = max(selection.anchor, selection.focus)
        guard let start = input.position(from: input.beginningOfDocument, offset: lower),
            let end = input.position(from: input.beginningOfDocument, offset: upper),
            let range = input.textRange(from: start, to: end)
        else {
            return
        }
        input.selectedTextRange = range
    }

    private func selection(in input: any UITextInput) -> TextSelection? {
        guard let selected = input.selectedTextRange else { return nil }
        let anchor = input.offset(from: input.beginningOfDocument, to: selected.start)
        let focus = input.offset(from: input.beginningOfDocument, to: selected.end)
        guard anchor >= 0, focus >= 0 else { return nil }
        return TextSelection(anchor: anchor, focus: focus)
    }
}

private func inferredEditKind(range: NSRange, replacement: String) -> EditKind {
    if replacement.isEmpty, range.length > 0 { return .delete }
    if range.length == 0 { return .insert }
    return .replace
}

#endif
