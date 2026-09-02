import Foundation

public struct ProposedEdit: Equatable, Sendable {
    public let text: String
    public let range: TextRange
    public let replacementText: String
    public let composingRange: TextRange?
    public let selectionAfterEdit: TextSelection?
    public let editKind: EditKind
    public let policy: FieldPolicy
    public let maxLengthUtf16: Int?

    public init(
        text: String,
        range: TextRange,
        replacementText: String,
        composingRange: TextRange? = nil,
        selectionAfterEdit: TextSelection? = nil,
        editKind: EditKind,
        policy: FieldPolicy,
        maxLengthUtf16: Int? = nil
    ) {
        self.text = text
        self.range = range
        self.replacementText = replacementText
        self.composingRange = composingRange
        self.selectionAfterEdit = selectionAfterEdit
        self.editKind = editKind
        self.policy = policy
        self.maxLengthUtf16 = maxLengthUtf16
    }
}

public extension ProposedEdit {
    static func replacingDifference(
        from beforeText: String,
        to afterText: String,
        selectionAfterEdit: TextSelection? = nil,
        policy: FieldPolicy,
        maxLengthUtf16: Int? = nil
    ) -> ProposedEdit? {
        let old = Array(beforeText.utf16)
        let new = Array(afterText.utf16)
        var prefix = 0
        while prefix < old.count, prefix < new.count, old[prefix] == new[prefix] {
            prefix += 1
        }
        var suffix = 0
        while suffix < old.count - prefix,
            suffix < new.count - prefix,
            old[old.count - suffix - 1] == new[new.count - suffix - 1]
        {
            suffix += 1
        }

        let oldLength = old.count - prefix - suffix
        let newLength = new.count - prefix - suffix
        guard oldLength > 0 || newLength > 0 else { return nil }
        let replacement = (afterText as NSString).substring(
            with: NSRange(location: prefix, length: newLength)
        )
        let kind: EditKind
        if replacement.isEmpty, oldLength > 0 {
            kind = .delete
        } else if oldLength == 0 {
            kind = .insert
        } else {
            kind = .replace
        }
        return ProposedEdit(
            text: beforeText,
            range: TextRange(start: prefix, length: oldLength),
            replacementText: replacement,
            selectionAfterEdit: selectionAfterEdit,
            editKind: kind,
            policy: policy,
            maxLengthUtf16: maxLengthUtf16
        )
    }
}

public struct ProposedEditResult: Equatable, Sendable {
    public let plan: EditPlan
    public let replacementText: String

    public init(plan: EditPlan, replacementText: String) {
        self.plan = plan
        self.replacementText = replacementText
    }

    public var requiresReplacement: Bool {
        plan.decision == .applied
    }
}

public enum ProposedEditError: Error, Equatable, Sendable {
    case invalidRange
}

public extension NaturalSpacing {
    static func planProposedEdit(_ edit: ProposedEdit) throws -> ProposedEditResult {
        try proposedEditResult(edit) { planEdit($0) }
    }
}

public extension NaturalSpacingSession {
    func processProposedEdit(_ edit: ProposedEdit) throws -> ProposedEditResult {
        try NaturalSpacing.proposedEditResult(edit) { self.process($0) }
    }
}

private extension NaturalSpacing {
    static func proposedEditResult(
        _ edit: ProposedEdit,
        planner: (EditSnapshot) -> EditPlan
    ) throws -> ProposedEditResult {
        guard edit.range.start >= 0,
            edit.range.length >= 0,
            edit.range.start <= edit.text.utf16.count - edit.range.length
        else {
            throw ProposedEditError.invalidRange
        }

        let afterUserText = (edit.text as NSString).replacingCharacters(
            in: NSRange(location: edit.range.start, length: edit.range.length),
            with: edit.replacementText
        )
        let caret = edit.range.start + edit.replacementText.utf16.count
        let selection = edit.selectionAfterEdit
            ?? TextSelection(anchor: caret, focus: caret)
        let plan = planner(
            EditSnapshot(
                beforeText: edit.text,
                afterUserText: afterUserText,
                changedRange: edit.range,
                selection: selection,
                composingRange: edit.composingRange,
                editKind: edit.editKind,
                policy: edit.policy,
                maxLengthUtf16: edit.maxLengthUtf16
            )
        )

        guard plan.decision == .applied else {
            return ProposedEditResult(plan: plan, replacementText: edit.replacementText)
        }
        let relativeInsertions = plan.insertions.map {
            Insertion(offset: $0.offset - edit.range.start, reason: $0.reason)
        }
        return ProposedEditResult(
            plan: plan,
            replacementText: apply(insertions: relativeInsertions, to: edit.replacementText)
        )
    }
}
