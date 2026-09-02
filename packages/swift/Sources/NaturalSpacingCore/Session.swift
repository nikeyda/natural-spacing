import Foundation

public final class NaturalSpacingSession {
    private var suppressions: [SuppressedBoundary] = []
    private var lastPolicy: FieldPolicy?

    public init() {}

    public var suppressedBoundaryCount: Int {
        suppressions.count
    }

    public func reset() {
        suppressions = []
        lastPolicy = nil
    }

    public func process(_ snapshot: EditSnapshot) -> EditPlan {
        if let lastPolicy, lastPolicy != snapshot.policy {
            suppressions = []
        }
        lastPolicy = snapshot.policy
        rebaseSuppressions(for: snapshot)

        if snapshot.policy == .naturalLanguage,
            snapshot.composingRange == nil,
            let boundary = deletedSpaceBoundary(snapshot)
        {
            suppressions.removeAll { $0.offset == boundary.offset }
            suppressions.append(boundary)
        }

        let offsets = Set(suppressions.map(\.offset))
        let planned = NaturalSpacing.planEdit(snapshot, suppressedOffsets: offsets)
        let plan: EditPlan
        if planned.decision == .noChange, !suppressions.isEmpty {
            plan = EditPlan(
                decision: .suppressed,
                insertions: planned.insertions,
                resultText: planned.resultText,
                selection: planned.selection
            )
        } else {
            plan = planned
        }
        mapSuppressions(through: plan.insertions, resultText: plan.resultText)
        return plan
    }

    private func rebaseSuppressions(for snapshot: EditSnapshot) {
        let editStart = snapshot.changedRange.start
        let editEnd = editStart + snapshot.changedRange.length
        let delta = snapshot.afterUserText.utf16.count - snapshot.beforeText.utf16.count

        suppressions = suppressions.compactMap { suppression in
            var offset = suppression.offset
            if offset > editEnd || (snapshot.changedRange.length > 0 && offset == editEnd) {
                offset += delta
            } else if offset > editStart && offset < editEnd {
                return nil
            }
            guard let context = boundaryContext(snapshot.afterUserText, offset: offset),
                context.left == suppression.left,
                context.right == suppression.right
            else {
                return nil
            }
            return SuppressedBoundary(offset: offset, left: suppression.left, right: suppression.right)
        }
    }

    private func mapSuppressions(through insertions: [Insertion], resultText: String) {
        suppressions = suppressions.compactMap { suppression in
            let mapped = NaturalSpacing.map(
                selection: TextSelection(anchor: suppression.offset, focus: suppression.offset),
                through: insertions
            ).anchor
            guard let context = boundaryContext(resultText, offset: mapped),
                context.left == suppression.left,
                context.right == suppression.right
            else {
                return nil
            }
            return SuppressedBoundary(offset: mapped, left: suppression.left, right: suppression.right)
        }
    }
}

private struct SuppressedBoundary {
    let offset: Int
    let left: String
    let right: String
}

private struct BoundaryContext {
    let left: String
    let right: String
    let leftCategory: BoundaryCategory
    let rightCategory: BoundaryCategory
}

private func deletedSpaceBoundary(_ snapshot: EditSnapshot) -> SuppressedBoundary? {
    guard snapshot.editKind == .delete,
        snapshot.changedRange.length == 1,
        snapshot.beforeText.utf16.count - 1 == snapshot.afterUserText.utf16.count
    else {
        return nil
    }
    let removed = (snapshot.beforeText as NSString).substring(
        with: NSRange(location: snapshot.changedRange.start, length: 1)
    )
    guard removed == " ",
        let context = boundaryContext(snapshot.afterUserText, offset: snapshot.changedRange.start),
        NaturalSpacing.insertionReason(
            left: context.leftCategory,
            right: context.rightCategory
        ) != nil
    else {
        return nil
    }
    return SuppressedBoundary(
        offset: snapshot.changedRange.start,
        left: context.left,
        right: context.right
    )
}

private func boundaryContext(_ text: String, offset: Int) -> BoundaryContext? {
    let graphemes = NaturalSpacing.segment(text)
    guard let rightIndex = graphemes.firstIndex(where: { $0.start == offset }), rightIndex > 0 else {
        return nil
    }
    let left = graphemes[rightIndex - 1]
    let right = graphemes[rightIndex]
    guard left.end == offset else { return nil }
    return BoundaryContext(
        left: left.text,
        right: right.text,
        leftCategory: left.category,
        rightCategory: right.category
    )
}
