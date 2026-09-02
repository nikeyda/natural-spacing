package consumer.naturalspacing.android

import android.widget.EditText
import androidx.compose.ui.text.input.TextFieldValue
import dev.naturalspacing.android.NaturalSpacingEditTextAdapter
import dev.naturalspacing.compose.NaturalSpacingTextFieldValueAdapter
import dev.naturalspacing.core.ContentKind
import dev.naturalspacing.core.PolicyContext
import dev.naturalspacing.core.resolvePolicy

fun attachMessageSpacing(editText: EditText): NaturalSpacingEditTextAdapter =
    NaturalSpacingEditTextAdapter(
        editText = editText,
        policy = resolvePolicy(PolicyContext(contentKind = ContentKind.MESSAGE)),
    ).attach()

fun createMessageValueAdapter(
    initialValue: TextFieldValue,
): NaturalSpacingTextFieldValueAdapter =
    NaturalSpacingTextFieldValueAdapter(
        initialValue = initialValue,
        policy = resolvePolicy(PolicyContext(contentKind = ContentKind.MESSAGE)),
    )
