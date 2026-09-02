import dev.naturalspacing.core.ContentKind
import dev.naturalspacing.core.FieldPolicy
import dev.naturalspacing.core.NaturalSpacing
import dev.naturalspacing.core.OrderedTextSource
import dev.naturalspacing.core.OrderedTextUpdateEvent
import dev.naturalspacing.core.OrderedTextUpdateSession
import dev.naturalspacing.core.PolicyContext
import dev.naturalspacing.core.TextStability
import dev.naturalspacing.core.recommendPolicy
import dev.naturalspacing.core.resolvePolicy

fun main() {
    val context = PolicyContext(contentKind = ContentKind.MESSAGE)
    val recommendation = recommendPolicy(context)
    val policy = resolvePolicy(context)
    val normalized = NaturalSpacing.normalize("发布v2版本", policy)

    check(recommendation.autoApply)
    check(policy == FieldPolicy.NATURAL_LANGUAGE)
    check(resolvePolicy(PolicyContext(
        explicitPolicy = FieldPolicy.NATURAL_LANGUAGE,
        contentKind = ContentKind.MESSAGE,
        isSecure = true,
    )) == FieldPolicy.VERBATIM)
    check(normalized == "发布 v2 版本")

    val ordered = OrderedTextUpdateSession(policy, OrderedTextSource.ASR)
    check(ordered.start("utterance-1"))
    val interim = ordered.accept(
        OrderedTextUpdateEvent("utterance-1", 0, "中2文", TextStability.INTERIM),
    )
    check(interim.output?.displayText == "中 2 文")
    check(interim.output?.committedText == null)
    val stale = ordered.accept(
        OrderedTextUpdateEvent("utterance-1", 0, "ignored", TextStability.INTERIM),
    )
    check(!stale.accepted && stale.output == null)
    val final = ordered.accept(
        OrderedTextUpdateEvent("utterance-1", 1, "中2文", TextStability.FINAL),
    )
    check(final.output?.committedText == "中 2 文")
    check(!ordered.accept(
        OrderedTextUpdateEvent("utterance-1", 2, "ignored", TextStability.FINAL),
    ).accepted)

    val advisory = PolicyContext(
        contentKind = ContentKind.SEARCH_QUERY,
        text = "发布v2版本",
    )
    check(resolvePolicy(advisory) == FieldPolicy.VERBATIM)
}
