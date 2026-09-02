package dev.naturalspacing.core

enum class FieldPolicy { NATURAL_LANGUAGE, VERBATIM }
enum class EditKind { INSERT, DELETE, REPLACE, PASTE }
enum class PlanDecision { APPLIED, NO_CHANGE, VERBATIM, COMPOSING, SUPPRESSED, LENGTH_LIMITED }
enum class InsertionReason { HAN_LATIN, HAN_ASCII_DIGIT }

data class TextRange(val start: Int, val length: Int)
data class TextSelection(val anchor: Int, val focus: Int)
data class Insertion(val offset: Int, val reason: InsertionReason, val text: String = " ")

data class EditSnapshot(
    val beforeText: String,
    val afterUserText: String,
    val changedRange: TextRange,
    val selection: TextSelection,
    val composingRange: TextRange?,
    val editKind: EditKind,
    val policy: FieldPolicy,
    val maxLengthUtf16: Int?,
)

data class EditPlan(
    val decision: PlanDecision,
    val insertions: List<Insertion>,
    val resultText: String,
    val selection: TextSelection,
)

enum class ContentKind {
    PROSE, TITLE, MESSAGE, NOTE, DOCUMENT, TRANSCRIPT, ASR_TRANSCRIPT,
    CODE, IDENTIFIER, URL, EMAIL, PASSWORD, TOKEN, FILE_PATH, COMMAND,
    NUMBER, SEARCH_QUERY, UNKNOWN,
}

enum class RecommendationConfidence { HIGH, MEDIUM, LOW }
enum class RecommendationSource { EXPLICIT, SAFETY, CONTENT_KIND, TEXT_HEURISTIC, FALLBACK }
enum class RecommendationReason {
    EXPLICIT_POLICY, SECURE_CONTENT, NATURAL_LANGUAGE_CONTENT, STRUCTURED_CONTENT,
    AMBIGUOUS_SEARCH, STRUCTURED_TEXT, MIXED_NATURAL_LANGUAGE, INSUFFICIENT_EVIDENCE,
}

data class PolicyContext(
    val explicitPolicy: FieldPolicy? = null,
    val contentKind: ContentKind? = null,
    val text: String? = null,
    val isSecure: Boolean? = null,
)

data class PolicyRecommendation(
    val policy: FieldPolicy,
    val confidence: RecommendationConfidence,
    val source: RecommendationSource,
    val reason: RecommendationReason,
    val autoApply: Boolean,
)

enum class TextSource { ASR, DICTATION, IMPORTED, GENERATED }
enum class TextStability { INTERIM, FINAL }

data class TextUpdate(
    val text: String,
    val policy: FieldPolicy,
    val source: TextSource,
    val stability: TextStability,
)

data class FormattedTextUpdate(
    val displayText: String,
    val committedText: String?,
    val changed: Boolean,
    val policy: FieldPolicy,
    val source: TextSource,
    val stability: TextStability,
)

enum class OrderedTextSource { ASR, DICTATION }
enum class OrderedTextUpdateReason { ACCEPTED, INACTIVE_UTTERANCE, STALE_REVISION, INVALID_REVISION }

data class OrderedTextUpdateEvent(
    val utteranceId: String,
    val revision: Long,
    val text: String,
    val stability: TextStability,
)

data class OrderedTextUpdateResult(
    val accepted: Boolean,
    val reason: OrderedTextUpdateReason,
    val output: FormattedTextUpdate?,
)
