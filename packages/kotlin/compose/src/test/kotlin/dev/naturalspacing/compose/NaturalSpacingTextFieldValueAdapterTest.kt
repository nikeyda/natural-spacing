package dev.naturalspacing.compose

import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue
import dev.naturalspacing.core.FieldPolicy
import dev.naturalspacing.core.PlanDecision
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertSame

class NaturalSpacingTextFieldValueAdapterTest {
    @Test
    fun insertsSpacesAndMapsSelection() {
        val adapter = NaturalSpacingTextFieldValueAdapter(
            TextFieldValue("中文"),
            policy = FieldPolicy.NATURAL_LANGUAGE,
        )

        val result = adapter.process(
            TextFieldValue("中2文", selection = TextRange(2)),
        )

        assertEquals("中 2 文", result.text)
        assertEquals(TextRange(4), result.selection)
        assertEquals(null, result.composition)
        assertEquals(PlanDecision.APPLIED, adapter.lastPlan?.decision)
    }

    @Test
    fun preservesImeCompositionThenReconcilesItsCommit() {
        val adapter = NaturalSpacingTextFieldValueAdapter(
            TextFieldValue("中"),
            policy = FieldPolicy.NATURAL_LANGUAGE,
        )
        val composing = TextFieldValue(
            text = "中A",
            selection = TextRange(2),
            composition = TextRange(1, 2),
        )

        assertSame(composing, adapter.process(composing))
        assertNull(adapter.lastPlan)
        assertEquals(
            TextFieldValue("中 A", selection = TextRange(3)),
            adapter.process(composing.copy(composition = null)),
        )
        assertEquals(PlanDecision.APPLIED, adapter.lastPlan?.decision)
    }

    @Test
    fun honorsManualAutomaticSpaceDeletion() {
        val adapter = NaturalSpacingTextFieldValueAdapter(
            TextFieldValue("中 A"),
            policy = FieldPolicy.NATURAL_LANGUAGE,
        )

        val deleted = TextFieldValue("中A", selection = TextRange(1))

        assertSame(deleted, adapter.process(deleted))
        assertSame(deleted, adapter.process(deleted))
    }

    @Test
    fun preservesBackwardSelectionDirection() {
        val adapter = NaturalSpacingTextFieldValueAdapter(
            TextFieldValue(""),
            policy = FieldPolicy.NATURAL_LANGUAGE,
        )

        val result = adapter.process(
            TextFieldValue("中A文", selection = TextRange(3, 0)),
        )

        assertEquals("中 A 文", result.text)
        assertEquals(TextRange(5, 0), result.selection)
    }

    @Test
    fun verbatimAndLengthLimitedValuesPassThrough() {
        val verbatim = NaturalSpacingTextFieldValueAdapter(
            initialValue = TextFieldValue("中"),
            policy = FieldPolicy.VERBATIM,
        )
        val proposed = TextFieldValue("中A", selection = TextRange(2))
        assertSame(proposed, verbatim.process(proposed))

        val limited = NaturalSpacingTextFieldValueAdapter(
            initialValue = TextFieldValue("中"),
            policy = FieldPolicy.NATURAL_LANGUAGE,
            maxLengthUtf16 = 2,
        )
        assertSame(proposed, limited.process(proposed))
    }

    @Test
    fun syncResetsTheProgrammaticBaseline() {
        val adapter = NaturalSpacingTextFieldValueAdapter(TextFieldValue("中"))
        val external = TextFieldValue("外部A", selection = TextRange(3))
        adapter.process(TextFieldValue("中A", selection = TextRange(2)))
        assertEquals(PlanDecision.VERBATIM, adapter.lastPlan?.decision)
        adapter.sync(external)

        assertNull(adapter.lastPlan)
        assertSame(external, adapter.process(external))
    }

    @Test
    fun defaultPolicyIsVerbatim() {
        val adapter = NaturalSpacingTextFieldValueAdapter(TextFieldValue("中"))
        val proposed = TextFieldValue("中A", selection = TextRange(2))

        assertSame(proposed, adapter.process(proposed))
        assertEquals(PlanDecision.VERBATIM, adapter.lastPlan?.decision)
    }
}
