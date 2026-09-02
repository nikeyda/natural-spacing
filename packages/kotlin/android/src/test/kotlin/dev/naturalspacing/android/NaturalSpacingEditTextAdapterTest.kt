package dev.naturalspacing.android

import android.app.Activity
import android.os.Looper
import android.text.InputFilter
import android.text.InputType
import android.text.method.PasswordTransformationMethod
import android.view.inputmethod.BaseInputConnection
import android.widget.EditText
import dev.naturalspacing.core.FieldPolicy
import dev.naturalspacing.core.PlanDecision
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import org.junit.After
import org.junit.Before
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode
import org.robolectric.android.controller.ActivityController

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
@LooperMode(LooperMode.Mode.PAUSED)
class NaturalSpacingEditTextAdapterTest {
    private lateinit var activityController: ActivityController<Activity>

    @Before
    fun setUp() {
        activityController = Robolectric.buildActivity(Activity::class.java).setup()
    }

    @After
    fun tearDown() {
        activityController.pause().stop().destroy()
    }

    @Test
    fun digitInsertionUpdatesTextAndSelection() {
        val editText = editText("中文", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()

        editText.text.insert(1, "2")

        assertEquals("中 2 文", editText.text.toString())
        assertEquals(4, editText.selectionStart)
        assertEquals(4, editText.selectionEnd)
        assertEquals(PlanDecision.APPLIED, adapter.lastPlan?.decision)
    }

    @Test
    fun verbatimPolicyLeavesNativeEditUntouched() {
        val editText = editText("中文", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.VERBATIM,
        ).attach()

        editText.text.insert(1, "2")

        assertEquals("中2文", editText.text.toString())
        assertEquals(2, editText.selectionStart)
        assertEquals(PlanDecision.VERBATIM, adapter.lastPlan?.decision)
    }

    @Test
    fun passwordInputTypeForcesVerbatim() {
        val editText = editText("中文", selection = 1).apply {
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
            setText("中文")
            setSelection(1)
        }
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()

        editText.text.insert(1, "2")

        assertEquals("中2文", editText.text.toString())
        assertEquals(PlanDecision.VERBATIM, adapter.lastPlan?.decision)
    }

    @Test
    fun passwordTransformationForcesVerbatim() {
        val editText = editText("中文", selection = 1).apply {
            transformationMethod = PasswordTransformationMethod.getInstance()
        }
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()

        editText.text.insert(1, "2")

        assertEquals("中2文", editText.text.toString())
        assertEquals(PlanDecision.VERBATIM, adapter.lastPlan?.decision)
    }

    @Test
    fun composingTextIsReconciledOnlyAfterCompositionSettles() {
        val editText = editText("中文", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()
        BaseInputConnection.setComposingSpans(editText.text)

        editText.text.insert(1, "2")

        assertEquals("中2文", editText.text.toString())
        assertNull(adapter.lastPlan)

        BaseInputConnection.removeComposingSpans(editText.text)
        shadowOf(Looper.getMainLooper()).idle()

        assertEquals("中 2 文", editText.text.toString())
        assertEquals(4, editText.selectionStart)
        assertEquals(PlanDecision.APPLIED, adapter.lastPlan?.decision)
    }

    @Test
    fun deletingAutomaticSpaceSuppressesImmediateReinsertion() {
        val editText = editText("中文", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()
        editText.text.insert(1, "2")

        editText.text.delete(1, 2)

        assertEquals("中2 文", editText.text.toString())
        assertEquals(PlanDecision.SUPPRESSED, adapter.lastPlan?.decision)
    }

    @Test
    fun rejectedFilteredReplacementKeepsNativeTextSelectionAndBaseline() {
        val editText = editText("中文", selection = 1)
        var rejectedReplacementCount = 0
        editText.filters = arrayOf(InputFilter { source, start, end, _, _, _ ->
            val incoming = source.subSequence(start, end).toString()
            val filtered = incoming.replace(" ", "")
            if (incoming == filtered) {
                null
            } else {
                rejectedReplacementCount += 1
                filtered
            }
        })
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()

        editText.text.insert(1, "2")

        assertEquals("中2文", editText.text.toString())
        assertEquals(2, editText.selectionStart)
        assertEquals(2, editText.selectionEnd)
        assertEquals(1, rejectedReplacementCount)

        editText.text.append("!")

        assertEquals("中2文!", editText.text.toString())
        assertEquals(1, rejectedReplacementCount)
        assertEquals(PlanDecision.NO_CHANGE, adapter.lastPlan?.decision)
    }

    @Test
    fun throwingFilterDoesNotLeaveAdapterApplyingOrBaselineSpeculative() {
        val editText = editText("中文", selection = 1)
        editText.filters = arrayOf(InputFilter { source, start, end, _, _, _ ->
            if (source.subSequence(start, end).contains(' ')) {
                error("host filter rejected automatic spaces")
            }
            null
        })
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()

        assertFailsWith<IllegalStateException> {
            editText.text.insert(1, "2")
        }
        assertEquals("中2文", editText.text.toString())
        assertEquals(2, editText.selectionStart)

        editText.filters = emptyArray()
        editText.text.append("!")

        assertEquals("中2文!", editText.text.toString())
        assertEquals(PlanDecision.NO_CHANGE, adapter.lastPlan?.decision)
    }

    @Test
    fun hostUpdateIsNotReinterpretedAndClearsDeletionSuppression() {
        val editText = editText("中", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()
        editText.text.append("A")
        editText.text.delete(1, 2)
        assertEquals("中A", editText.text.toString())
        assertEquals(PlanDecision.SUPPRESSED, adapter.lastPlan?.decision)

        adapter.sync {
            editText.setText("中A")
            editText.setSelection(2)
        }

        assertEquals("中A", editText.text.toString())
        assertEquals(2, editText.selectionStart)
        assertNull(adapter.lastPlan)

        adapter.sync {
            editText.setText("中")
            editText.setSelection(1)
        }
        editText.text.append("A")

        assertEquals("中 A", editText.text.toString())
        assertEquals(3, editText.selectionStart)
        assertEquals(PlanDecision.APPLIED, adapter.lastPlan?.decision)
    }

    @Test
    fun plainSyncAdoptsCurrentValueAndClearsDeletionSuppression() {
        val editText = editText("中", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()
        editText.text.append("A")
        editText.text.delete(1, 2)
        assertEquals(PlanDecision.SUPPRESSED, adapter.lastPlan?.decision)

        adapter.sync()
        editText.text.delete(1, 2)
        editText.text.append("A")

        assertEquals("中 A", editText.text.toString())
        assertEquals(PlanDecision.APPLIED, adapter.lastPlan?.decision)
    }

    @Test
    fun throwingHostUpdateStillAdoptsActualValueAndRestoresWatcher() {
        val editText = editText("中", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()

        assertFailsWith<IllegalStateException> {
            adapter.sync {
                editText.setText("中A")
                editText.setSelection(2)
                error("host update failed after changing the control")
            }
        }

        assertEquals("中A", editText.text.toString())
        assertEquals(2, editText.selectionStart)
        assertNull(adapter.lastPlan)

        editText.text.append("!")

        assertEquals("中A!", editText.text.toString())
        assertEquals(PlanDecision.NO_CHANGE, adapter.lastPlan?.decision)
    }

    @Test
    fun detachStopsReconciliation() {
        val editText = editText("中文", selection = 1)
        val adapter = NaturalSpacingEditTextAdapter(
            editText = editText,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()
        adapter.detach()

        editText.text.insert(1, "2")

        assertEquals("中2文", editText.text.toString())
        assertNull(adapter.lastPlan)
    }

    private fun editText(text: String, selection: Int): EditText =
        EditText(activityController.get()).apply {
            setText(text)
            setSelection(selection)
            activityController.get().setContentView(this)
        }
}
