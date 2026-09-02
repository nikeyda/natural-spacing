import Foundation

public enum FieldPolicy: String, Codable, Sendable {
    case naturalLanguage
    case verbatim
}

public enum EditKind: String, Codable, Sendable {
    case insert
    case delete
    case replace
    case paste
}

public enum PlanDecision: String, Codable, Sendable {
    case applied
    case noChange
    case verbatim
    case composing
    case suppressed
    case lengthLimited
}

public struct TextRange: Codable, Equatable, Sendable {
    public let start: Int
    public let length: Int

    public init(start: Int, length: Int) {
        self.start = start
        self.length = length
    }
}

public struct TextSelection: Codable, Equatable, Sendable {
    public let anchor: Int
    public let focus: Int

    public init(anchor: Int, focus: Int) {
        self.anchor = anchor
        self.focus = focus
    }
}

public struct EditSnapshot: Codable, Equatable, Sendable {
    public let beforeText: String
    public let afterUserText: String
    public let changedRange: TextRange
    public let selection: TextSelection
    public let composingRange: TextRange?
    public let editKind: EditKind
    public let policy: FieldPolicy
    public let maxLengthUtf16: Int?

    public init(
        beforeText: String,
        afterUserText: String,
        changedRange: TextRange,
        selection: TextSelection,
        composingRange: TextRange?,
        editKind: EditKind,
        policy: FieldPolicy,
        maxLengthUtf16: Int?
    ) {
        self.beforeText = beforeText
        self.afterUserText = afterUserText
        self.changedRange = changedRange
        self.selection = selection
        self.composingRange = composingRange
        self.editKind = editKind
        self.policy = policy
        self.maxLengthUtf16 = maxLengthUtf16
    }
}

public enum InsertionReason: String, Codable, Sendable {
    case hanLatin
    case hanAsciiDigit
}

public struct Insertion: Codable, Equatable, Sendable {
    public let offset: Int
    public let text: String
    public let reason: InsertionReason

    public init(offset: Int, reason: InsertionReason) {
        self.offset = offset
        self.text = " "
        self.reason = reason
    }
}

public struct EditPlan: Codable, Equatable, Sendable {
    public let decision: PlanDecision
    public let insertions: [Insertion]
    public let resultText: String
    public let selection: TextSelection

    public init(
        decision: PlanDecision,
        insertions: [Insertion],
        resultText: String,
        selection: TextSelection
    ) {
        self.decision = decision
        self.insertions = insertions
        self.resultText = resultText
        self.selection = selection
    }
}

public enum NaturalSpacing {
    public static let unicodeVersion = "17.0.0"
}
