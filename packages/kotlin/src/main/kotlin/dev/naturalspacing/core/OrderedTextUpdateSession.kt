package dev.naturalspacing.core

/**
 * Coordinates complete hypotheses from revision-capable ASR or dictation
 * providers. Only the active utterance ID and revision are retained.
 */
class OrderedTextUpdateSession(
    val policy: FieldPolicy = FieldPolicy.NATURAL_LANGUAGE,
    val source: OrderedTextSource = OrderedTextSource.ASR,
) {
    private data class Active(val utteranceId: String, var lastRevision: Long)

    private var active: Active? = null

    fun start(utteranceId: String): Boolean {
        if (utteranceId.isEmpty()) return false
        active = Active(utteranceId, -1)
        return true
    }

    fun accept(event: OrderedTextUpdateEvent): OrderedTextUpdateResult {
        if (event.revision < 0) return rejected(OrderedTextUpdateReason.INVALID_REVISION)
        val current = active
        if (current?.utteranceId != event.utteranceId) {
            return rejected(OrderedTextUpdateReason.INACTIVE_UTTERANCE)
        }
        if (event.revision <= current.lastRevision) {
            return rejected(OrderedTextUpdateReason.STALE_REVISION)
        }

        current.lastRevision = event.revision
        val output = formatTextUpdate(
            TextUpdate(
                event.text,
                policy,
                when (source) {
                    OrderedTextSource.ASR -> TextSource.ASR
                    OrderedTextSource.DICTATION -> TextSource.DICTATION
                },
                event.stability,
            ),
        )
        if (event.stability == TextStability.FINAL) active = null
        return OrderedTextUpdateResult(true, OrderedTextUpdateReason.ACCEPTED, output)
    }

    fun cancel(utteranceId: String): Boolean {
        if (active?.utteranceId != utteranceId) return false
        active = null
        return true
    }

    private fun rejected(reason: OrderedTextUpdateReason) =
        OrderedTextUpdateResult(false, reason, null)
}
