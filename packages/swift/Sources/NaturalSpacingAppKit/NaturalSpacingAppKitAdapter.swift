#if canImport(AppKit)
import AppKit
import NaturalSpacingCore

/// Experimental single-selection adapter for `NSTextView`, including the field
/// editor used by `NSTextField`.
///
/// Forward the text view delegate callback here only after application validation
/// has accepted the edit. The adapter never owns or replaces the text view's delegate.
@MainActor
public final class NaturalSpacingAppKitAdapter {
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

    public func beginEditing(in textView: NSTextView) {
        sync(in: textView)
    }

    /// Resets editor intent and adopts a host-controlled value as the baseline.
    public func sync(in textView: NSTextView) {
        session.reset()
        lastPlan = nil
        settledText = textView.string
    }

    /// Forward `textDidChange` or `controlTextDidChange` here. For an
    /// `NSTextField`, pass its active field editor as `textView`.
    public func textDidChange(in textView: NSTextView) {
        if isApplyingReplacement { return }
        if textView.hasMarkedText() { return }
        guard let beforeText = settledText else {
            settledText = textView.string
            return
        }
        let currentText = textView.string
        let selected = textView.selectedRange()
        guard let proposedEdit = ProposedEdit.replacingDifference(
            from: beforeText,
            to: currentText,
            selectionAfterEdit: TextSelection(
                anchor: selected.location,
                focus: selected.location + selected.length
            ),
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
        if apply(result, to: textView, range: currentRange) {
            settledText = result.plan.resultText
        } else {
            settledText = currentText
        }
    }

    /// Returns the value that the host delegate should return.
    /// A `false` result means the adapter performed a validated replacement itself.
    public func shouldChangeText(
        in textView: NSTextView,
        range: NSRange,
        replacementString: String?,
        editKind: EditKind? = nil
    ) -> Bool {
        if isApplyingReplacement { return true }
        guard let replacementString else { return true }

        let markedRange = textView.markedRange()
        let composition = textView.hasMarkedText()
            ? NaturalSpacingCore.TextRange(
                start: markedRange.location,
                length: markedRange.length
            )
            : nil
        let proposedEdit = ProposedEdit(
            text: textView.string,
            range: NaturalSpacingCore.TextRange(
                start: range.location,
                length: range.length
            ),
            replacementText: replacementString,
            composingRange: composition,
            editKind: editKind ?? inferredEditKind(range: range, replacement: replacementString),
            policy: policy,
            maxLengthUtf16: maxLengthUtf16
        )
        guard let result = try? session.processProposedEdit(proposedEdit) else { return true }
        lastPlan = result.plan
        guard result.requiresReplacement else { return true }

        guard apply(result, to: textView, range: range) else {
            return true
        }
        settledText = result.plan.resultText
        return false
    }

    public func shouldChangeText(
        in textView: NSTextView,
        ranges: [NSRange],
        replacementStrings: [String]?,
        editKind: EditKind? = nil
    ) -> Bool {
        guard ranges.count == 1,
            let range = ranges.first,
            let replacementStrings,
            replacementStrings.count == 1,
            let replacement = replacementStrings.first
        else {
            lastPlan = nil
            return true
        }
        return shouldChangeText(
            in: textView,
            range: range,
            replacementString: replacement,
            editKind: editKind
        )
    }

    @discardableResult
    private func apply(
        _ result: ProposedEditResult,
        to textView: NSTextView,
        range: NSRange
    ) -> Bool {
        isApplyingReplacement = true
        let replacement = NSAttributedString(
            string: result.replacementText,
            attributes: textView.typingAttributes
        )
        let didReplace = textView.performValidatedReplacement(in: range, with: replacement)
        if didReplace {
            let start = min(result.plan.selection.anchor, result.plan.selection.focus)
            let length = abs(result.plan.selection.focus - result.plan.selection.anchor)
            textView.setSelectedRange(NSRange(location: start, length: length))
        }
        isApplyingReplacement = false
        return didReplace
    }
}

private func inferredEditKind(range: NSRange, replacement: String) -> EditKind {
    if replacement.isEmpty, range.length > 0 { return .delete }
    if range.length == 0 { return .insert }
    return .replace
}

#endif
