package dev.naturalspacing.acceptance.android

import android.os.Bundle
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.ViewGroup
import android.view.inputmethod.BaseInputConnection
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.naturalspacing.android.NaturalSpacingEditTextAdapter
import dev.naturalspacing.compose.NaturalSpacingTextFieldValueAdapter
import dev.naturalspacing.core.ContentKind
import dev.naturalspacing.core.FieldPolicy
import dev.naturalspacing.core.PolicyContext
import dev.naturalspacing.core.PolicyRecommendation
import dev.naturalspacing.core.recommendPolicy
import dev.naturalspacing.core.resolvePolicy

class MainActivity : ComponentActivity() {
    private lateinit var messageEditor: EditText
    private lateinit var passwordEditor: EditText
    private lateinit var messageStatus: TextView
    private lateinit var passwordStatus: TextView
    private lateinit var messageAdapter: NaturalSpacingEditTextAdapter
    private lateinit var passwordAdapter: NaturalSpacingEditTextAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val messagePolicy = resolvePolicy(PolicyContext(contentKind = ContentKind.MESSAGE))
        check(messagePolicy == FieldPolicy.NATURAL_LANGUAGE)

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(20), dp(24), dp(32))
        }

        content.addView(label("Natural Spacing Android Acceptance", 24f))
        content.addView(label(
            "Use only synthetic text. Record the OS, device, exact IME/input source, adapter revision, and each attempted scenario. Active composing text must remain untouched.",
            15f,
        ))

        content.addView(label("Natural-language message", 18f))
        messageEditor = editor(
            hint = "Try synthetic text: 中A, A中, 中2, or 2中",
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE,
            minimumLines = 4,
        )
        content.addView(messageEditor)
        messageStatus = statusView("Message status")
        content.addView(messageStatus)

        content.addView(label("Password fail-safe", 18f))
        passwordEditor = editor(
            hint = "Synthetic password only; value is never shown below",
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD,
            minimumLines = 1,
        )
        content.addView(passwordEditor)
        passwordStatus = statusView("Password status")
        content.addView(passwordStatus)

        content.addView(label("Jetpack Compose value adapter", 18f))
        content.addView(
            ComposeView(this).apply {
                setViewCompositionStrategy(
                    ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed,
                )
                setContent { ComposeAcceptancePanel() }
            },
            margins(top = 4),
        )

        val resetButton = Button(this).apply {
            setText(R.string.reset_synthetic_text)
            contentDescription = "Reset both acceptance editors"
            setOnClickListener { resetEditors() }
        }
        content.addView(resetButton, margins(top = 12))

        val scrollView = ScrollView(this).apply {
            addView(content, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ))
        }
        setContentView(scrollView)

        messageAdapter = NaturalSpacingEditTextAdapter(
            editText = messageEditor,
            policy = messagePolicy,
        ).attach()
        passwordAdapter = NaturalSpacingEditTextAdapter(
            editText = passwordEditor,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ).attach()

        messageEditor.addTextChangedListener(statusWatcher { updateMessageStatus() })
        passwordEditor.addTextChangedListener(statusWatcher { updatePasswordStatus() })
        messageEditor.setOnFocusChangeListener { _, _ -> updateMessageStatus() }
        passwordEditor.setOnFocusChangeListener { _, _ -> updatePasswordStatus() }
        updateMessageStatus()
        updatePasswordStatus()
        messageEditor.requestFocus()
    }

    override fun onDestroy() {
        messageAdapter.detach()
        passwordAdapter.detach()
        super.onDestroy()
    }

    private fun resetEditors() {
        messageAdapter.sync {
            messageEditor.text.clear()
            messageEditor.setSelection(0)
        }
        passwordAdapter.sync {
            passwordEditor.text.clear()
            passwordEditor.setSelection(0)
        }
        messageEditor.requestFocus()
        (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager)
            .showSoftInput(messageEditor, InputMethodManager.SHOW_IMPLICIT)
        updateMessageStatus()
        updatePasswordStatus()
    }

    private fun updateMessageStatus() {
        messageEditor.post {
            val editable = messageEditor.text
            val composingStart = BaseInputConnection.getComposingSpanStart(editable)
            val composingEnd = BaseInputConnection.getComposingSpanEnd(editable)
            val decision = messageAdapter.lastPlan?.decision?.name ?: "NONE"
            messageStatus.text = buildString {
                append("policy=NATURAL_LANGUAGE")
                append("  composing=")
                append(if (composingStart >= 0 && composingEnd >= 0) "$composingStart:$composingEnd" else "none")
                append("  selection=${messageEditor.selectionStart}:${messageEditor.selectionEnd}")
                append("  decision=$decision")
                append("\ntext=${messageEditor.text}")
            }
        }
    }

    private fun updatePasswordStatus() {
        passwordEditor.post {
            val decision = passwordAdapter.lastPlan?.decision?.name ?: "NONE"
            passwordStatus.text = getString(
                R.string.password_status,
                decision,
                passwordEditor.text.length,
            )
        }
    }

    private fun statusWatcher(update: () -> Unit): TextWatcher = object : TextWatcher {
        override fun beforeTextChanged(text: CharSequence?, start: Int, count: Int, after: Int) = Unit
        override fun onTextChanged(text: CharSequence?, start: Int, before: Int, count: Int) = Unit
        override fun afterTextChanged(editable: Editable?) = update()
    }

    private fun editor(hint: String, inputType: Int, minimumLines: Int): EditText =
        EditText(this).apply {
            this.hint = hint
            this.inputType = inputType
            minLines = minimumLines
            textSize = 22f
            setSelectAllOnFocus(false)
        }

    private fun label(text: String, size: Float): TextView = TextView(this).apply {
        this.text = text
        textSize = size
        setPadding(0, dp(10), 0, dp(6))
    }

    private fun statusView(description: String): TextView = TextView(this).apply {
        contentDescription = description
        textSize = 13f
        setTextIsSelectable(true)
        setPadding(0, dp(6), 0, dp(12))
    }

    private fun margins(top: Int = 0): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(top) }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}

@Composable
private fun ComposeAcceptancePanel() {
    val messageContext = remember { PolicyContext(contentKind = ContentKind.MESSAGE) }
    val passwordContext = remember {
        PolicyContext(
            explicitPolicy = FieldPolicy.NATURAL_LANGUAGE,
            contentKind = ContentKind.PASSWORD,
            isSecure = true,
        )
    }
    val messageRecommendation = remember { recommendPolicy(messageContext) }
    val passwordRecommendation = remember { recommendPolicy(passwordContext) }
    val messagePolicy = remember { resolvePolicy(messageContext) }
    val passwordPolicy = remember { resolvePolicy(passwordContext) }
    val messageAdapter = remember {
        NaturalSpacingTextFieldValueAdapter(policy = messagePolicy)
    }
    val passwordAdapter = remember {
        NaturalSpacingTextFieldValueAdapter(policy = passwordPolicy)
    }
    var messageValue by remember { mutableStateOf(TextFieldValue()) }
    var passwordValue by remember { mutableStateOf(TextFieldValue()) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFFF4F4F4))
            .padding(12.dp),
    ) {
        BasicText(
            text = "Compose message · ${messagePolicy.name}",
            style = TextStyle(color = Color.Black, fontSize = 16.sp),
        )
        Spacer(Modifier.height(8.dp))
        BasicTextField(
            value = messageValue,
            onValueChange = { messageValue = messageAdapter.process(it) },
            textStyle = TextStyle(color = Color.Black, fontSize = 20.sp),
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 96.dp)
                .background(Color.White)
                .border(1.dp, Color.Gray)
                .padding(12.dp)
                .semantics { contentDescription = "Compose natural-language message" },
        )
        BasicText(
            text = composeStatus(
                policy = messagePolicy,
                recommendation = messageRecommendation,
                value = messageValue,
                decision = messageAdapter.lastPlan?.decision?.name ?: "NONE",
                hideText = false,
            ),
            style = TextStyle(color = Color.DarkGray, fontSize = 12.sp),
            modifier = Modifier.padding(top = 6.dp),
        )

        Spacer(Modifier.height(20.dp))
        BasicText(
            text = "Compose password · ${passwordPolicy.name}",
            style = TextStyle(color = Color.Black, fontSize = 16.sp),
        )
        Spacer(Modifier.height(8.dp))
        BasicTextField(
            value = passwordValue,
            onValueChange = { passwordValue = passwordAdapter.process(it) },
            textStyle = TextStyle(color = Color.Black, fontSize = 20.sp),
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.White)
                .border(1.dp, Color.Gray)
                .padding(12.dp)
                .semantics { contentDescription = "Compose password forced verbatim" },
        )
        BasicText(
            text = composeStatus(
                policy = passwordPolicy,
                recommendation = passwordRecommendation,
                value = passwordValue,
                decision = passwordAdapter.lastPlan?.decision?.name ?: "NONE",
                hideText = true,
            ),
            style = TextStyle(color = Color.DarkGray, fontSize = 12.sp),
            modifier = Modifier.padding(top = 6.dp),
        )

        Spacer(Modifier.height(16.dp))
        BasicText(
            text = "Reset Compose session",
            style = TextStyle(color = Color.White, fontSize = 15.sp),
            modifier = Modifier
                .background(Color(0xFF3157A4))
                .clickable {
                    messageValue = TextFieldValue()
                    passwordValue = TextFieldValue()
                    messageAdapter.reset(messageValue)
                    passwordAdapter.reset(passwordValue)
                }
                .padding(horizontal = 16.dp, vertical = 12.dp)
                .semantics { contentDescription = "Reset Compose acceptance editors" },
        )
    }
}

private fun composeStatus(
    policy: FieldPolicy,
    recommendation: PolicyRecommendation,
    value: TextFieldValue,
    decision: String,
    hideText: Boolean,
): String = buildString {
    append("policy=${policy.name}")
    append(" recommendation=${recommendation.policy.name}/${recommendation.confidence.name}")
    append(" reason=${recommendation.source.name}/${recommendation.reason.name}")
    append("\ncomposition=${value.composition?.let { "${it.start}:${it.end}" } ?: "none"}")
    append(" selection=${value.selection.start}:${value.selection.end}")
    append(" decision=$decision")
    append("\ntext=${if (hideText) "<hidden>" else value.text}")
}
