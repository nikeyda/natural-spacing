import Foundation

public extension NaturalSpacing {
    static func normalize(
        _ text: String,
        policy: FieldPolicy = .verbatim
    ) -> String {
        guard policy == .naturalLanguage else { return text }
        return apply(insertions: eligibleInsertions(in: text), to: text)
    }

    static func planEdit(_ snapshot: EditSnapshot) -> EditPlan {
        planEdit(snapshot, suppressedOffsets: [])
    }
}

extension NaturalSpacing {
    static func eligibleInsertions(in text: String) -> [Insertion] {
        let graphemes = segment(text)
        guard graphemes.count > 1 else { return [] }
        return (1..<graphemes.count).compactMap { index in
            let left = graphemes[index - 1]
            let right = graphemes[index]
            guard let reason = insertionReason(left: left.category, right: right.category) else {
                return nil
            }
            return Insertion(offset: right.start, reason: reason)
        }
    }

    static func planEdit(
        _ snapshot: EditSnapshot,
        suppressedOffsets: Set<Int>
    ) -> EditPlan {
        if snapshot.policy == .verbatim {
            return unchangedPlan(snapshot, decision: .verbatim)
        }
        if snapshot.composingRange != nil {
            return unchangedPlan(snapshot, decision: .composing)
        }

        let replacementLength = snapshot.afterUserText.utf16.count
            - (snapshot.beforeText.utf16.count - snapshot.changedRange.length)
        let affectedStart = snapshot.changedRange.start
        let affectedEnd = affectedStart + replacementLength
        let eligible = eligibleInsertions(in: snapshot.afterUserText).filter {
            $0.offset >= affectedStart && $0.offset <= affectedEnd
        }
        let insertions = eligible.filter { !suppressedOffsets.contains($0.offset) }
        guard !insertions.isEmpty else {
            return unchangedPlan(
                snapshot,
                decision: eligible.isEmpty ? .noChange : .suppressed
            )
        }

        let resultText = apply(insertions: insertions, to: snapshot.afterUserText)
        if let limit = snapshot.maxLengthUtf16, resultText.utf16.count > limit {
            return unchangedPlan(snapshot, decision: .lengthLimited)
        }
        return EditPlan(
            decision: .applied,
            insertions: insertions,
            resultText: resultText,
            selection: map(selection: snapshot.selection, through: insertions)
        )
    }

    static func apply(insertions: [Insertion], to text: String) -> String {
        var result = text
        for insertion in insertions.reversed() {
            let index = stringIndex(utf16Offset: insertion.offset, in: result)
            result.insert(contentsOf: insertion.text, at: index)
        }
        return result
    }

    static func map(selection: TextSelection, through insertions: [Insertion]) -> TextSelection {
        func map(_ endpoint: Int) -> Int {
            endpoint + insertions.reduce(0) { shift, insertion in
                shift + (endpoint >= insertion.offset ? insertion.text.utf16.count : 0)
            }
        }
        return TextSelection(anchor: map(selection.anchor), focus: map(selection.focus))
    }

    static func stringIndex(utf16Offset: Int, in text: String) -> String.Index {
        let utf16Index = text.utf16.index(text.utf16.startIndex, offsetBy: utf16Offset)
        return String.Index(utf16Index, within: text)!
    }

    private static func unchangedPlan(
        _ snapshot: EditSnapshot,
        decision: PlanDecision
    ) -> EditPlan {
        EditPlan(
            decision: decision,
            insertions: [],
            resultText: snapshot.afterUserText,
            selection: snapshot.selection
        )
    }
}
