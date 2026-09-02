package dev.naturalspacing.core

data class ProposedEdit(
    val text: String,
    val range: TextRange,
    val replacementText: String,
    val composingRange: TextRange? = null,
    val selectionAfterEdit: TextSelection? = null,
    val editKind: EditKind,
    val policy: FieldPolicy,
    val maxLengthUtf16: Int? = null,
)

data class ProposedEditResult(
    val plan: EditPlan,
    val replacementText: String,
    val requiresReplacement: Boolean,
)

fun proposedEditReplacingDifference(
    beforeText: String,
    afterText: String,
    selectionAfterEdit: TextSelection? = null,
    policy: FieldPolicy,
    maxLengthUtf16: Int? = null,
): ProposedEdit? {
    var prefix = 0
    while (prefix < beforeText.length && prefix < afterText.length &&
        beforeText[prefix] == afterText[prefix]
    ) prefix++

    var suffix = 0
    while (suffix < beforeText.length - prefix && suffix < afterText.length - prefix &&
        beforeText[beforeText.length - suffix - 1] == afterText[afterText.length - suffix - 1]
    ) suffix++

    val oldLength = beforeText.length - prefix - suffix
    val newLength = afterText.length - prefix - suffix
    if (oldLength == 0 && newLength == 0) return null
    val replacement = afterText.substring(prefix, prefix + newLength)
    val kind = when {
        replacement.isEmpty() && oldLength > 0 -> EditKind.DELETE
        oldLength == 0 -> EditKind.INSERT
        else -> EditKind.REPLACE
    }
    return ProposedEdit(
        text = beforeText,
        range = TextRange(prefix, oldLength),
        replacementText = replacement,
        selectionAfterEdit = selectionAfterEdit,
        editKind = kind,
        policy = policy,
        maxLengthUtf16 = maxLengthUtf16,
    )
}

fun NaturalSpacing.planProposedEdit(edit: ProposedEdit): ProposedEditResult =
    processProposedEdit(edit, NaturalSpacing::planEdit)

fun NaturalSpacingSession.processProposedEdit(edit: ProposedEdit): ProposedEditResult =
    processProposedEdit(edit, this::process)

private fun processProposedEdit(
    edit: ProposedEdit,
    planner: (EditSnapshot) -> EditPlan,
): ProposedEditResult {
    require(edit.range.start >= 0 && edit.range.length >= 0 &&
        edit.range.start <= edit.text.length - edit.range.length
    ) { "Proposed edit range is outside the UTF-16 text bounds." }

    val afterUserText = edit.text.substring(0, edit.range.start) + edit.replacementText +
        edit.text.substring(edit.range.start + edit.range.length)
    val caret = edit.range.start + edit.replacementText.length
    val plan = planner(
        EditSnapshot(
            beforeText = edit.text,
            afterUserText = afterUserText,
            changedRange = edit.range,
            selection = edit.selectionAfterEdit ?: TextSelection(caret, caret),
            composingRange = edit.composingRange,
            editKind = edit.editKind,
            policy = edit.policy,
            maxLengthUtf16 = edit.maxLengthUtf16,
        ),
    )
    if (plan.decision != PlanDecision.APPLIED) {
        return ProposedEditResult(plan, edit.replacementText, false)
    }
    val relative = plan.insertions.map { it.copy(offset = it.offset - edit.range.start) }
    return ProposedEditResult(
        plan,
        NaturalSpacing.apply(relative, edit.replacementText),
        true,
    )
}
