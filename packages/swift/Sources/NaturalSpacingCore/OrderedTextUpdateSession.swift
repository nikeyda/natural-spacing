import Foundation

public enum OrderedTextSource: String, Codable, Sendable {
    case asr
    case dictation

    var textSource: TextSource {
        switch self {
        case .asr: .asr
        case .dictation: .dictation
        }
    }
}

public enum OrderedTextUpdateReason: String, Codable, Sendable {
    case accepted
    case inactiveUtterance
    case staleRevision
    case invalidRevision
}

public struct OrderedTextUpdateEvent: Codable, Equatable, Sendable {
    public let utteranceID: String
    public let revision: Int
    public let text: String
    public let stability: TextStability

    public init(
        utteranceID: String,
        revision: Int,
        text: String,
        stability: TextStability
    ) {
        self.utteranceID = utteranceID
        self.revision = revision
        self.text = text
        self.stability = stability
    }

    private enum CodingKeys: String, CodingKey {
        case utteranceID = "utteranceId"
        case revision
        case text
        case stability
    }
}

public struct OrderedTextUpdateResult: Codable, Equatable, Sendable {
    public let accepted: Bool
    public let reason: OrderedTextUpdateReason
    public let output: FormattedTextUpdate?

    public init(
        accepted: Bool,
        reason: OrderedTextUpdateReason,
        output: FormattedTextUpdate?
    ) {
        self.accepted = accepted
        self.reason = reason
        self.output = output
    }
}

/// Coordinates complete hypotheses from revision-capable ASR or dictation
/// providers. It retains only the active utterance ID and revision, never text.
public final class OrderedTextUpdateSession {
    public let policy: FieldPolicy
    public let source: OrderedTextSource

    private var active: (utteranceID: String, lastRevision: Int)?

    public init(
        policy: FieldPolicy = .naturalLanguage,
        source: OrderedTextSource = .asr
    ) {
        self.policy = policy
        self.source = source
    }

    @discardableResult
    public func start(utteranceID: String) -> Bool {
        guard !utteranceID.isEmpty else { return false }
        active = (utteranceID, -1)
        return true
    }

    public func accept(_ event: OrderedTextUpdateEvent) -> OrderedTextUpdateResult {
        guard event.revision >= 0 else {
            return OrderedTextUpdateResult(
                accepted: false,
                reason: .invalidRevision,
                output: nil
            )
        }
        guard var current = active, current.utteranceID == event.utteranceID else {
            return OrderedTextUpdateResult(
                accepted: false,
                reason: .inactiveUtterance,
                output: nil
            )
        }
        guard event.revision > current.lastRevision else {
            return OrderedTextUpdateResult(
                accepted: false,
                reason: .staleRevision,
                output: nil
            )
        }

        current.lastRevision = event.revision
        active = current
        let output = NaturalSpacing.formatTextUpdate(
            TextUpdate(
                text: event.text,
                policy: policy,
                source: source.textSource,
                stability: event.stability
            )
        )
        if event.stability == .final { active = nil }
        return OrderedTextUpdateResult(
            accepted: true,
            reason: .accepted,
            output: output
        )
    }

    @discardableResult
    public func cancel(utteranceID: String) -> Bool {
        guard active?.utteranceID == utteranceID else { return false }
        active = nil
        return true
    }
}
