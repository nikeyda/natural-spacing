package dev.naturalspacing.android

import android.text.Editable
import android.text.InputType
import android.text.Selection
import android.text.TextWatcher
import android.text.method.PasswordTransformationMethod
import android.view.inputmethod.BaseInputConnection
import android.widget.EditText
import dev.naturalspacing.core.EditPlan
import dev.naturalspacing.core.FieldPolicy
import dev.naturalspacing.core.NaturalSpacingSession
import dev.naturalspacing.core.TextSelection
import dev.naturalspacing.core.processProposedEdit
import dev.naturalspacing.core.proposedEditReplacingDifference

/**
 * Experimental plain-text `EditText` adapter. Use one instance per control.
 * It does not replace existing listeners and never rewrites an active composing span.
 */
class NaturalSpacingEditTextAdapter(
    private val editText: EditText,
    var policy: FieldPolicy,
    var maxLengthUtf16: Int? = null,
) : TextWatcher {
    var lastPlan: EditPlan? = null
        private set

    private val session = NaturalSpacingSession()
    private var settledText = editText.text?.toString().orEmpty()
    private var attached = false
    private var applying = false
    private var reconciliationPosted = false

    fun attach(): NaturalSpacingEditTextAdapter {
        if (!attached) {
            attached = true
            settledText = editText.text?.toString().orEmpty()
            editText.addTextChangedListener(this)
        }
        return this
    }

    fun detach() {
        if (attached) {
            editText.removeTextChangedListener(this)
            attached = false
        }
    }

    /** Adopts the current control value after a programmatic change and resets editor intent. */
    fun sync() {
        if (applying) return
        session.reset()
        settledText = editText.text?.toString().orEmpty()
        lastPlan = null
    }

    /**
     * Runs a host-controlled update without interpreting its synchronous
     * `TextWatcher` callbacks as user input, then adopts the actual value.
     */
    fun sync(update: () -> Unit) {
        check(!applying) { "Cannot start a host update while the adapter is applying a replacement" }
        applying = true
        try {
            update()
        } finally {
            applying = false
            session.reset()
            settledText = editText.text?.toString().orEmpty()
            lastPlan = null
        }
    }

    fun reset() {
        session.reset()
        settledText = editText.text?.toString().orEmpty()
        lastPlan = null
    }

    override fun beforeTextChanged(text: CharSequence?, start: Int, count: Int, after: Int) = Unit

    override fun onTextChanged(text: CharSequence?, start: Int, before: Int, count: Int) = Unit

    override fun afterTextChanged(editable: Editable?) {
        if (applying || editable == null) return
        if (hasComposingText(editable)) {
            postSettledReconciliation()
            return
        }
        reconcile(editable)
    }

    private fun postSettledReconciliation() {
        if (reconciliationPosted) return
        reconciliationPosted = true
        editText.post {
            reconciliationPosted = false
            if (!attached || applying) return@post
            val editable = editText.text ?: return@post
            if (!hasComposingText(editable)) reconcile(editable)
        }
    }

    private fun reconcile(editable: Editable) {
        val currentText = editable.toString()
        val selection = currentSelection(editable)
        val edit = proposedEditReplacingDifference(
            beforeText = settledText,
            afterText = currentText,
            selectionAfterEdit = selection,
            policy = effectivePolicy(),
            maxLengthUtf16 = maxLengthUtf16,
        ) ?: return
        val result = session.processProposedEdit(edit)
        lastPlan = result.plan
        if (!result.requiresReplacement) {
            settledText = currentText
            return
        }

        applying = true
        val nativeSelection = currentSelection(editable)
        try {
            val currentEnd = edit.range.start + edit.replacementText.length
            editable.replace(edit.range.start, currentEnd, result.replacementText)
            val actualText = editable.toString()
            if (actualText == result.plan.resultText) {
                setSelection(editable, result.plan.selection)
            } else {
                session.reset()
                if (nativeSelection != null) setSelection(editable, nativeSelection)
            }
            settledText = actualText
        } catch (error: Throwable) {
            session.reset()
            settledText = editable.toString()
            if (nativeSelection != null) setSelection(editable, nativeSelection)
            throw error
        } finally {
            applying = false
        }
    }

    private fun currentSelection(editable: Editable): TextSelection? {
        val anchor = Selection.getSelectionStart(editable)
        val focus = Selection.getSelectionEnd(editable)
        return if (anchor >= 0 && focus >= 0) TextSelection(anchor, focus) else null
    }

    private fun setSelection(editable: Editable, selection: TextSelection) {
        val anchor = selection.anchor.coerceIn(0, editable.length)
        val focus = selection.focus.coerceIn(0, editable.length)
        Selection.setSelection(editable, anchor, focus)
    }

    private fun hasComposingText(editable: Editable?): Boolean = editable != null &&
        BaseInputConnection.getComposingSpanStart(editable) >= 0 &&
        BaseInputConnection.getComposingSpanEnd(editable) >= 0

    private fun effectivePolicy(): FieldPolicy =
        if (isPasswordInput()) FieldPolicy.VERBATIM else policy

    private fun isPasswordInput(): Boolean {
        if (editText.transformationMethod is PasswordTransformationMethod) return true
        val inputClass = editText.inputType and InputType.TYPE_MASK_CLASS
        val variation = editText.inputType and InputType.TYPE_MASK_VARIATION
        return when (inputClass) {
            InputType.TYPE_CLASS_TEXT -> variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD
            InputType.TYPE_CLASS_NUMBER -> variation == InputType.TYPE_NUMBER_VARIATION_PASSWORD
            else -> false
        }
    }
}
