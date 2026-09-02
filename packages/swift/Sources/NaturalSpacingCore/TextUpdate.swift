import Foundation

public enum TextSource: String, Codable, Sendable {
    case asr
    case dictation
    case imported
    case generated
}

public enum TextStability: String, Codable, Sendable {
    case interim
    case final
}

public struct TextUpdate: Codable, Equatable, Sendable {
    public let text: String
    public let policy: FieldPolicy
    public let source: TextSource
    public let stability: TextStability

    public init(
        text: String,
        policy: FieldPolicy,
        source: TextSource,
        stability: TextStability
    ) {
        self.text = text
        self.policy = policy
        self.source = source
        self.stability = stability
    }
}

public struct FormattedTextUpdate: Codable, Equatable, Sendable {
    public let displayText: String
    public let committedText: String?
    public let changed: Bool
    public let policy: FieldPolicy
    public let source: TextSource
    public let stability: TextStability

    public init(
        displayText: String,
        committedText: String?,
        changed: Bool,
        policy: FieldPolicy,
        source: TextSource,
        stability: TextStability
    ) {
        self.displayText = displayText
        self.committedText = committedText
        self.changed = changed
        self.policy = policy
        self.source = source
        self.stability = stability
    }
}

public extension NaturalSpacing {
    static func formatTextUpdate(_ update: TextUpdate) -> FormattedTextUpdate {
        let displayText = normalize(update.text, policy: update.policy)
        return FormattedTextUpdate(
            displayText: displayText,
            committedText: update.stability == .final ? displayText : nil,
            changed: displayText != update.text,
            policy: update.policy,
            source: update.source,
            stability: update.stability
        )
    }
}
