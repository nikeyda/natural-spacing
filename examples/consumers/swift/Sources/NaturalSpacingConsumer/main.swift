import NaturalSpacingAppKit
import NaturalSpacingCore
import NaturalSpacingSwiftUI

@main
struct NaturalSpacingConsumer {
    @MainActor
    static func main() {
        let context = PolicyContext(contentKind: .message)
        let recommendation = NaturalSpacing.recommendPolicy(context)
        let policy = NaturalSpacing.resolvePolicy(context)
        let normalized = NaturalSpacing.normalize("发布v2版本", policy: policy)
        let adapter = NaturalSpacingAppKitAdapter(policy: policy)
        let ordered = OrderedTextUpdateSession(policy: policy, source: .asr)
        precondition(ordered.start(utteranceID: "utterance-1"))
        let interim = ordered.accept(
            OrderedTextUpdateEvent(
                utteranceID: "utterance-1",
                revision: 0,
                text: "中2文",
                stability: .interim
            )
        )
        let stale = ordered.accept(
            OrderedTextUpdateEvent(
                utteranceID: "utterance-1",
                revision: 0,
                text: "ignored",
                stability: .interim
            )
        )
        let final = ordered.accept(
            OrderedTextUpdateEvent(
                utteranceID: "utterance-1",
                revision: 1,
                text: "中2文",
                stability: .final
            )
        )
        let afterFinal = ordered.accept(
            OrderedTextUpdateEvent(
                utteranceID: "utterance-1",
                revision: 2,
                text: "ignored",
                stability: .final
            )
        )

        precondition(recommendation.autoApply)
        precondition(policy == .naturalLanguage)
        precondition(NaturalSpacing.resolvePolicy(PolicyContext(
            explicitPolicy: .naturalLanguage,
            contentKind: .message,
            isSecure: true
        )) == .verbatim)
        precondition(normalized == "发布 v2 版本")
        precondition(adapter.policy == policy)
        precondition(interim.output?.displayText == "中 2 文")
        precondition(interim.output?.committedText == nil)
        precondition(stale.reason == .staleRevision && stale.output == nil)
        precondition(final.output?.committedText == "中 2 文")
        precondition(afterFinal.reason == .inactiveUtterance)
        _ = NaturalSpacingTextEditor.self
    }
}
