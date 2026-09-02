package dev.naturalspacing.core

object NaturalSpacing {
    const val UNICODE_VERSION = "17.0.0"

    fun normalize(text: String, policy: FieldPolicy = FieldPolicy.VERBATIM): String =
        if (policy == FieldPolicy.NATURAL_LANGUAGE) apply(eligibleInsertions(text), text) else text

    fun planEdit(snapshot: EditSnapshot): EditPlan = planEdit(snapshot, emptySet())

    internal fun planEdit(snapshot: EditSnapshot, suppressedOffsets: Set<Int>): EditPlan {
        if (snapshot.policy == FieldPolicy.VERBATIM) return unchanged(snapshot, PlanDecision.VERBATIM)
        if (snapshot.composingRange != null) return unchanged(snapshot, PlanDecision.COMPOSING)

        val replacementLength = snapshot.afterUserText.length -
            (snapshot.beforeText.length - snapshot.changedRange.length)
        val start = snapshot.changedRange.start
        val end = start + replacementLength
        val eligible = eligibleInsertions(snapshot.afterUserText).filter { it.offset in start..end }
        val insertions = eligible.filter { it.offset !in suppressedOffsets }
        if (insertions.isEmpty()) {
            return unchanged(
                snapshot,
                if (eligible.isEmpty()) PlanDecision.NO_CHANGE else PlanDecision.SUPPRESSED,
            )
        }

        val result = apply(insertions, snapshot.afterUserText)
        if (snapshot.maxLengthUtf16 != null && result.length > snapshot.maxLengthUtf16) {
            return unchanged(snapshot, PlanDecision.LENGTH_LIMITED)
        }
        return EditPlan(
            PlanDecision.APPLIED,
            insertions,
            result,
            mapSelection(snapshot.selection, insertions),
        )
    }

    internal fun eligibleInsertions(text: String): List<Insertion> {
        val graphemes = segment(text)
        return (1 until graphemes.size).mapNotNull { index ->
            val right = graphemes[index]
            insertionReason(graphemes[index - 1].category, right.category)?.let {
                Insertion(right.start, it)
            }
        }
    }

    internal fun mapSelection(selection: TextSelection, insertions: List<Insertion>): TextSelection {
        fun map(value: Int) = value + insertions.sumOf { if (value >= it.offset) it.text.length else 0 }
        return TextSelection(map(selection.anchor), map(selection.focus))
    }

    internal fun apply(insertions: List<Insertion>, text: String): String {
        val result = StringBuilder(text)
        insertions.asReversed().forEach { result.insert(it.offset, it.text) }
        return result.toString()
    }

    internal fun insertionReason(left: Category, right: Category): InsertionReason? = when {
        (left == Category.HAN && right == Category.LATIN) ||
            (left == Category.LATIN && right == Category.HAN) -> InsertionReason.HAN_LATIN
        (left == Category.HAN && right == Category.ASCII_DIGIT) ||
            (left == Category.ASCII_DIGIT && right == Category.HAN) -> InsertionReason.HAN_ASCII_DIGIT
        else -> null
    }

    internal fun segment(text: String): List<Grapheme> {
        val boundaries = Grapheme17.boundaries(text)
        return (1 until boundaries.size).map { index ->
            val start = boundaries[index - 1]
            val end = boundaries[index]
            val value = text.substring(start, end)
            Grapheme(value, start, end, classify(value))
        }
    }

    private fun classify(grapheme: String): Category {
        val points = grapheme.codePoints().toArray()
        if (points.any { Unicode17.contains(Unicode17.whiteSpaceRanges, it) }) {
            return Category.WHITESPACE
        }
        if (points.size == 1 && points[0] in '0'.code..'9'.code) return Category.ASCII_DIGIT
        val base = points.firstOrNull { !Unicode17.contains(Unicode17.markRanges, it) }
            ?: return Category.OTHER
        if (Unicode17.contains(Unicode17.hanRanges, base)) return Category.HAN
        if (Unicode17.contains(Unicode17.latinRanges, base)) return Category.LATIN
        return Category.OTHER
    }

    private fun unchanged(snapshot: EditSnapshot, decision: PlanDecision) = EditPlan(
        decision,
        emptyList(),
        snapshot.afterUserText,
        snapshot.selection,
    )
}

internal enum class Category { HAN, LATIN, ASCII_DIGIT, WHITESPACE, OTHER }
internal data class Grapheme(val text: String, val start: Int, val end: Int, val category: Category)
