package dev.naturalspacing.core

private val naturalKinds = setOf(
    ContentKind.PROSE, ContentKind.TITLE, ContentKind.MESSAGE, ContentKind.NOTE,
    ContentKind.DOCUMENT, ContentKind.TRANSCRIPT, ContentKind.ASR_TRANSCRIPT,
)
private val verbatimKinds = setOf(
    ContentKind.CODE, ContentKind.IDENTIFIER, ContentKind.URL, ContentKind.EMAIL,
    ContentKind.PASSWORD, ContentKind.TOKEN, ContentKind.FILE_PATH, ContentKind.COMMAND,
    ContentKind.NUMBER,
)
private val structuredPatterns = listOf(
    Regex("^(?:[a-z][a-z0-9+.-]*://|www\\.)", RegexOption.IGNORE_CASE),
    Regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", RegexOption.IGNORE_CASE),
    Regex("^(?:[A-Za-z]:[\\\\/]|~?[\\\\/])"),
    Regex("^(?:[A-Za-z_$][A-Za-z0-9_$-]*[.:/@\\\\])+[A-Za-z0-9_$.-]+$"),
    Regex("(?:=>|::|</?[A-Za-z][^>]*>|\\{[^}]*}|`[^`]*`)"),
)

fun recommendPolicy(context: PolicyContext = PolicyContext()): PolicyRecommendation {
    if (context.isSecure == true || context.contentKind == ContentKind.PASSWORD) {
        return recommendation(FieldPolicy.VERBATIM, RecommendationConfidence.HIGH, RecommendationSource.SAFETY, RecommendationReason.SECURE_CONTENT, true)
    }
    context.explicitPolicy?.let {
        return recommendation(it, RecommendationConfidence.HIGH, RecommendationSource.EXPLICIT, RecommendationReason.EXPLICIT_POLICY, true)
    }
    val kind = context.contentKind ?: ContentKind.UNKNOWN
    if (kind in naturalKinds) return recommendation(FieldPolicy.NATURAL_LANGUAGE, RecommendationConfidence.HIGH, RecommendationSource.CONTENT_KIND, RecommendationReason.NATURAL_LANGUAGE_CONTENT, true)
    if (kind in verbatimKinds) return recommendation(FieldPolicy.VERBATIM, RecommendationConfidence.HIGH, RecommendationSource.CONTENT_KIND, RecommendationReason.STRUCTURED_CONTENT, true)
    if (context.text?.trim()?.let { value -> value.isNotEmpty() && structuredPatterns.any { it.containsMatchIn(value) } } == true) {
        return recommendation(FieldPolicy.VERBATIM, RecommendationConfidence.MEDIUM, RecommendationSource.TEXT_HEURISTIC, RecommendationReason.STRUCTURED_TEXT, false)
    }
    if (kind == ContentKind.SEARCH_QUERY) return recommendation(FieldPolicy.NATURAL_LANGUAGE, RecommendationConfidence.MEDIUM, RecommendationSource.CONTENT_KIND, RecommendationReason.AMBIGUOUS_SEARCH, false)
    if (context.text?.let { NaturalSpacing.eligibleInsertions(it).isNotEmpty() } == true) {
        return recommendation(FieldPolicy.NATURAL_LANGUAGE, RecommendationConfidence.MEDIUM, RecommendationSource.TEXT_HEURISTIC, RecommendationReason.MIXED_NATURAL_LANGUAGE, false)
    }
    return recommendation(FieldPolicy.VERBATIM, RecommendationConfidence.LOW, RecommendationSource.FALLBACK, RecommendationReason.INSUFFICIENT_EVIDENCE, false)
}

fun resolvePolicy(
    context: PolicyContext = PolicyContext(),
    fallback: FieldPolicy = FieldPolicy.VERBATIM,
): FieldPolicy {
    val recommended = recommendPolicy(context)
    return if (recommended.autoApply) recommended.policy else fallback
}

fun formatTextUpdate(update: TextUpdate): FormattedTextUpdate {
    val display = NaturalSpacing.normalize(update.text, update.policy)
    return FormattedTextUpdate(
        display,
        if (update.stability == TextStability.FINAL) display else null,
        display != update.text,
        update.policy,
        update.source,
        update.stability,
    )
}

private fun recommendation(
    policy: FieldPolicy,
    confidence: RecommendationConfidence,
    source: RecommendationSource,
    reason: RecommendationReason,
    autoApply: Boolean,
) = PolicyRecommendation(policy, confidence, source, reason, autoApply)
