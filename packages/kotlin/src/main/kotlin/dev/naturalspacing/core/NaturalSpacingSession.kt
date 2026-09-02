package dev.naturalspacing.core

class NaturalSpacingSession {
    private var suppressions = mutableListOf<SuppressedBoundary>()
    private var lastPolicy: FieldPolicy? = null

    val suppressedBoundaryCount: Int get() = suppressions.size

    fun reset() {
        suppressions.clear()
        lastPolicy = null
    }

    fun process(snapshot: EditSnapshot): EditPlan {
        if (lastPolicy != null && lastPolicy != snapshot.policy) suppressions.clear()
        lastPolicy = snapshot.policy
        rebase(snapshot)
        if (snapshot.policy == FieldPolicy.NATURAL_LANGUAGE && snapshot.composingRange == null) {
            deletedBoundary(snapshot)?.let { boundary ->
                suppressions.removeAll { it.offset == boundary.offset }
                suppressions += boundary
            }
        }
        val planned = NaturalSpacing.planEdit(snapshot, suppressions.map { it.offset }.toSet())
        val plan = if (planned.decision == PlanDecision.NO_CHANGE && suppressions.isNotEmpty()) {
            planned.copy(decision = PlanDecision.SUPPRESSED)
        } else planned
        suppressions = suppressions.mapNotNull { suppression ->
            val mapped = NaturalSpacing.mapSelection(
                TextSelection(suppression.offset, suppression.offset),
                plan.insertions,
            ).anchor
            boundaryContext(plan.resultText, mapped)?.takeIf {
                it.left == suppression.left && it.right == suppression.right
            }?.let { suppression.copy(offset = mapped) }
        }.toMutableList()
        return plan
    }

    private fun rebase(snapshot: EditSnapshot) {
        val start = snapshot.changedRange.start
        val end = start + snapshot.changedRange.length
        val delta = snapshot.afterUserText.length - snapshot.beforeText.length
        suppressions = suppressions.mapNotNull { suppression ->
            var offset = suppression.offset
            if (offset > end || (snapshot.changedRange.length > 0 && offset == end)) offset += delta
            else if (offset > start && offset < end) return@mapNotNull null
            boundaryContext(snapshot.afterUserText, offset)?.takeIf {
                it.left == suppression.left && it.right == suppression.right
            }?.let { suppression.copy(offset = offset) }
        }.toMutableList()
    }
}

private data class SuppressedBoundary(val offset: Int, val left: String, val right: String)
private data class BoundaryContext(val left: String, val right: String, val leftCategory: Category, val rightCategory: Category)

private fun deletedBoundary(snapshot: EditSnapshot): SuppressedBoundary? {
    if (snapshot.editKind != EditKind.DELETE || snapshot.changedRange.length != 1 ||
        snapshot.beforeText.length - 1 != snapshot.afterUserText.length ||
        snapshot.beforeText.substring(snapshot.changedRange.start, snapshot.changedRange.start + 1) != " "
    ) return null
    val context = boundaryContext(snapshot.afterUserText, snapshot.changedRange.start) ?: return null
    if (NaturalSpacing.insertionReason(context.leftCategory, context.rightCategory) == null) return null
    return SuppressedBoundary(snapshot.changedRange.start, context.left, context.right)
}

private fun boundaryContext(text: String, offset: Int): BoundaryContext? {
    val graphemes = NaturalSpacing.segment(text)
    val rightIndex = graphemes.indexOfFirst { it.start == offset }
    if (rightIndex <= 0) return null
    val left = graphemes[rightIndex - 1]
    val right = graphemes[rightIndex]
    if (left.end != offset) return null
    return BoundaryContext(left.text, right.text, left.category, right.category)
}
