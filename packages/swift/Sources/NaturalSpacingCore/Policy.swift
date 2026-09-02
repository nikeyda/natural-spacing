import Foundation

public enum ContentKind: String, Codable, Sendable {
    case prose
    case title
    case message
    case note
    case document
    case transcript
    case asrTranscript
    case code
    case identifier
    case url
    case email
    case password
    case token
    case filePath
    case command
    case number
    case searchQuery
    case unknown
}

public enum RecommendationConfidence: String, Codable, Sendable {
    case high
    case medium
    case low
}

public enum RecommendationSource: String, Codable, Sendable {
    case explicit
    case safety
    case contentKind
    case textHeuristic
    case fallback
}

public enum RecommendationReason: String, Codable, Sendable {
    case explicitPolicy
    case secureContent
    case naturalLanguageContent
    case structuredContent
    case ambiguousSearch
    case structuredText
    case mixedNaturalLanguage
    case insufficientEvidence
}

public struct PolicyContext: Codable, Equatable, Sendable {
    public let explicitPolicy: FieldPolicy?
    public let contentKind: ContentKind?
    public let text: String?
    public let isSecure: Bool?

    public init(
        explicitPolicy: FieldPolicy? = nil,
        contentKind: ContentKind? = nil,
        text: String? = nil,
        isSecure: Bool? = nil
    ) {
        self.explicitPolicy = explicitPolicy
        self.contentKind = contentKind
        self.text = text
        self.isSecure = isSecure
    }
}

public struct PolicyRecommendation: Codable, Equatable, Sendable {
    public let policy: FieldPolicy
    public let confidence: RecommendationConfidence
    public let source: RecommendationSource
    public let reason: RecommendationReason
    public let autoApply: Bool

    public init(
        policy: FieldPolicy,
        confidence: RecommendationConfidence,
        source: RecommendationSource,
        reason: RecommendationReason,
        autoApply: Bool
    ) {
        self.policy = policy
        self.confidence = confidence
        self.source = source
        self.reason = reason
        self.autoApply = autoApply
    }
}

public extension NaturalSpacing {
    static func recommendPolicy(_ context: PolicyContext = PolicyContext()) -> PolicyRecommendation {
        if context.isSecure == true || context.contentKind == .password {
            return recommendation(.verbatim, .high, .safety, .secureContent, true)
        }
        if let explicit = context.explicitPolicy {
            return recommendation(explicit, .high, .explicit, .explicitPolicy, true)
        }

        let kind = context.contentKind ?? .unknown
        if naturalLanguageKinds.contains(kind) {
            return recommendation(
                .naturalLanguage,
                .high,
                .contentKind,
                .naturalLanguageContent,
                true
            )
        }
        if verbatimKinds.contains(kind) {
            return recommendation(.verbatim, .high, .contentKind, .structuredContent, true)
        }
        if let text = context.text, looksStructured(text) {
            return recommendation(.verbatim, .medium, .textHeuristic, .structuredText, false)
        }
        if kind == .searchQuery {
            return recommendation(
                .naturalLanguage,
                .medium,
                .contentKind,
                .ambiguousSearch,
                false
            )
        }
        if let text = context.text, !eligibleInsertions(in: text).isEmpty {
            return recommendation(
                .naturalLanguage,
                .medium,
                .textHeuristic,
                .mixedNaturalLanguage,
                false
            )
        }
        return recommendation(.verbatim, .low, .fallback, .insufficientEvidence, false)
    }

    /// Resolves a policy for automatic use. Advisory recommendations use the
    /// caller's fallback instead of silently changing an active field.
    static func resolvePolicy(
        _ context: PolicyContext = PolicyContext(),
        fallback: FieldPolicy = .verbatim
    ) -> FieldPolicy {
        let recommended = recommendPolicy(context)
        return recommended.autoApply ? recommended.policy : fallback
    }

    private static var naturalLanguageKinds: Set<ContentKind> {
        [.prose, .title, .message, .note, .document, .transcript, .asrTranscript]
    }

    private static var verbatimKinds: Set<ContentKind> {
        [.code, .identifier, .url, .email, .password, .token, .filePath, .command, .number]
    }

    private static func recommendation(
        _ policy: FieldPolicy,
        _ confidence: RecommendationConfidence,
        _ source: RecommendationSource,
        _ reason: RecommendationReason,
        _ autoApply: Bool
    ) -> PolicyRecommendation {
        PolicyRecommendation(
            policy: policy,
            confidence: confidence,
            source: source,
            reason: reason,
            autoApply: autoApply
        )
    }

    private static func looksStructured(_ text: String) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        let patterns = [
            #"^(?:[a-z][a-z0-9+.-]*://|www\.)"#,
            #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#,
            #"^(?:[A-Za-z]:[\\/]|~?[\\/])"#,
            #"^(?:[A-Za-z_$][A-Za-z0-9_$-]*[.:/@\\])+[A-Za-z0-9_$.-]+$"#,
            #"(?:=>|::|</?[A-Za-z][^>]*>|\{[^}]*\}|`[^`]*`)"#,
        ]
        return patterns.contains { pattern in
            value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }
}
