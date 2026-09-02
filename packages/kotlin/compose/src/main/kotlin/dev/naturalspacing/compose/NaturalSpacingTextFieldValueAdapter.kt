package dev.naturalspacing.compose

import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue
import dev.naturalspacing.core.EditPlan
import dev.naturalspacing.core.FieldPolicy
import dev.naturalspacing.core.NaturalSpacingSession
import dev.naturalspacing.core.TextSelection
import dev.naturalspacing.core.processProposedEdit
import dev.naturalspacing.core.proposedEditReplacingDifference

/**
 * Experimental value-based Compose adapter. Keep one instance per text field.
 *
 * Call [process] from `onValueChange` and publish its return value. An IME-owned
 * composition is returned unchanged; normalization runs only after composition
 * becomes null.
 */
class NaturalSpacingTextFieldValueAdapter(
    initialValue: TextFieldValue = TextFieldValue(),
    policy: FieldPolicy = FieldPolicy.VERBATIM,
    maxLengthUtf16: Int? = null,
) {
    var policy: FieldPolicy = policy
        set(value) {
            if (field != value) {
                session.reset()
                lastPlan = null
            }
            field = value
        }

    var maxLengthUtf16: Int? = maxLengthUtf16

    var lastPlan: EditPlan? = null
        private set

    private val session = NaturalSpacingSession()
    private var settledText = initialValue.text

    fun process(value: TextFieldValue): TextFieldValue {
        if (value.composition != null) {
            lastPlan = null
            return value
        }

        val edit = proposedEditReplacingDifference(
            beforeText = settledText,
            afterText = value.text,
            selectionAfterEdit = TextSelection(
                anchor = value.selection.start,
                focus = value.selection.end,
            ),
            policy = policy,
            maxLengthUtf16 = maxLengthUtf16,
        )
        if (edit == null) {
            lastPlan = null
            settledText = value.text
            return value
        }

        val result = session.processProposedEdit(edit)
        lastPlan = result.plan
        if (!result.requiresReplacement) {
            settledText = value.text
            return value
        }

        settledText = result.plan.resultText
        return value.copy(
            text = result.plan.resultText,
            selection = TextRange(
                start = result.plan.selection.anchor,
                end = result.plan.selection.focus,
            ),
            composition = null,
        )
    }

    /** Synchronizes an external/programmatic value with this field's baseline. */
    fun sync(value: TextFieldValue, clearSuppression: Boolean = true) {
        if (clearSuppression) session.reset()
        lastPlan = null
        settledText = value.text
    }

    fun reset(value: TextFieldValue = TextFieldValue()) {
        session.reset()
        lastPlan = null
        settledText = value.text
    }
}
