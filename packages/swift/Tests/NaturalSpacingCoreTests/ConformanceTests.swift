import Foundation
import XCTest
@testable import NaturalSpacingCore

final class ConformanceTests: XCTestCase {
    func testUnicodeVersion() {
        XCTAssertEqual(NaturalSpacing.unicodeVersion, "17.0.0")
    }

    func testUnicode17GraphemeBreakData() throws {
        let url = Self.projectRoot
            .appendingPathComponent("spec/unicode/17.0.0/GraphemeBreakTest.txt")
        let source = try String(contentsOf: url, encoding: .utf8)
        var count = 0

        for line in source.split(whereSeparator: \.isNewline) {
            let payload = line.split(
                separator: "#",
                maxSplits: 1,
                omittingEmptySubsequences: false
            ).first!.trimmingCharacters(in: .whitespaces)
            if payload.isEmpty { continue }

            var text = ""
            var expected = [Int]()
            var offset = 0
            for token in payload.split(whereSeparator: \.isWhitespace) {
                if token == "÷" {
                    expected.append(offset)
                } else if token != "×" {
                    let value = try XCTUnwrap(UInt32(token, radix: 16))
                    let scalar = try XCTUnwrap(UnicodeScalar(value))
                    text.unicodeScalars.append(scalar)
                    offset += value > 0xFFFF ? 2 : 1
                }
            }
            XCTAssertEqual(Grapheme17.boundaries(text), expected, String(line))
            count += 1
        }
        XCTAssertEqual(count, 766)
    }

    func testRuleFixtures() throws {
        let document: RuleDocument = try decodeFixture("rules-v1.json")
        XCTAssertEqual(document.cases.count, 38)
        for fixture in document.cases {
            let result = NaturalSpacing.normalize(fixture.input, policy: fixture.policy)
            XCTAssertEqual(result, fixture.expected, fixture.id)
            XCTAssertEqual(
                NaturalSpacing.normalize(result, policy: fixture.policy),
                result,
                "\(fixture.id) must be idempotent"
            )
        }
    }

    func testSessionFixtures() throws {
        let document: SessionDocument = try decodeFixture("sessions-v1.json")
        XCTAssertEqual(document.scenarios.count, 13)
        for scenario in document.scenarios {
            let session = NaturalSpacingSession()
            for (index, step) in scenario.steps.enumerated() {
                XCTAssertEqual(
                    session.process(step.exchange.snapshot),
                    step.exchange.expectedPlan,
                    "\(scenario.id) step \(index + 1)"
                )
                XCTAssertEqual(
                    session.suppressedBoundaryCount,
                    step.expectedSession.suppressedBoundaryCount,
                    "\(scenario.id) step \(index + 1) suppression count"
                )
            }
        }
    }

    func testPolicyFixtures() throws {
        let document: PolicyDocument = try decodeFixture("policy-v1.json")
        XCTAssertEqual(document.cases.count, 30)
        for fixture in document.cases {
            let recommendation = NaturalSpacing.recommendPolicy(fixture.context)
            XCTAssertEqual(recommendation, fixture.expected, fixture.id)
            XCTAssertEqual(
                NaturalSpacing.resolvePolicy(fixture.context),
                recommendation.autoApply ? recommendation.policy : .verbatim,
                "\(fixture.id) automatic resolution"
            )
            if fixture.id == "search-query-is-a-recommendation" {
                XCTAssertEqual(
                    NaturalSpacing.resolvePolicy(fixture.context, fallback: .naturalLanguage),
                    .naturalLanguage
                )
            }
        }
    }

    func testTextUpdateFixtures() throws {
        let document: TextUpdateDocument = try decodeFixture("text-updates-v1.json")
        XCTAssertEqual(document.cases.count, 12)
        for fixture in document.cases {
            let result = NaturalSpacing.formatTextUpdate(fixture.update)
            XCTAssertEqual(result, fixture.expected, fixture.id)
            if fixture.update.stability == .final {
                let repeated = NaturalSpacing.formatTextUpdate(
                    TextUpdate(
                        text: result.displayText,
                        policy: fixture.update.policy,
                        source: fixture.update.source,
                        stability: fixture.update.stability
                    )
                )
                XCTAssertEqual(repeated.displayText, result.displayText, fixture.id)
            } else {
                XCTAssertNil(result.committedText, fixture.id)
            }
        }
    }

    func testOrderedTextUpdateSessionFixtures() throws {
        let document: OrderedTextSessionDocument = try decodeFixture(
            "ordered-text-sessions-v1.json"
        )
        XCTAssertEqual(document.scenarios.count, 4)
        XCTAssertEqual(document.scenarios.flatMap(\.operations).count, 23)
        for scenario in document.scenarios {
            let session = OrderedTextUpdateSession(
                policy: scenario.policy,
                source: scenario.source
            )
            for (index, operation) in scenario.operations.enumerated() {
                let message = "\(scenario.id) operation \(index + 1)"
                switch operation.kind {
                case .start:
                    XCTAssertEqual(
                        session.start(utteranceID: operation.utteranceID ?? ""),
                        operation.expected.started,
                        message
                    )
                case .cancel:
                    XCTAssertEqual(
                        session.cancel(utteranceID: operation.utteranceID ?? ""),
                        operation.expected.cancelled,
                        message
                    )
                case .accept:
                    XCTAssertEqual(
                        session.accept(try XCTUnwrap(operation.event)),
                        operation.expected.result,
                        message
                    )
                }
            }
        }
    }

    func testResetAndPolicyChangeClearSuppressions() {
        let deletion = EditSnapshot(
            beforeText: "中 A",
            afterUserText: "中A",
            changedRange: TextRange(start: 1, length: 1),
            selection: TextSelection(anchor: 1, focus: 1),
            composingRange: nil,
            editKind: .delete,
            policy: .naturalLanguage,
            maxLengthUtf16: nil
        )
        let session = NaturalSpacingSession()
        XCTAssertEqual(session.process(deletion).decision, .suppressed)
        XCTAssertEqual(session.suppressedBoundaryCount, 1)
        session.reset()
        XCTAssertEqual(session.suppressedBoundaryCount, 0)

        XCTAssertEqual(session.process(deletion).decision, .suppressed)
        let verbatim = EditSnapshot(
            beforeText: "中A",
            afterUserText: "中B",
            changedRange: TextRange(start: 1, length: 1),
            selection: TextSelection(anchor: 1, focus: 1),
            composingRange: nil,
            editKind: .replace,
            policy: .verbatim,
            maxLengthUtf16: nil
        )
        XCTAssertEqual(session.process(verbatim).decision, .verbatim)
        XCTAssertEqual(session.suppressedBoundaryCount, 0)
    }

    func testProposedEditProducesNativeReplacementFragment() throws {
        let result = try NaturalSpacing.planProposedEdit(
            ProposedEdit(
                text: "中文",
                range: TextRange(start: 1, length: 0),
                replacementText: "A",
                editKind: .insert,
                policy: .naturalLanguage
            )
        )

        XCTAssertEqual(result.replacementText, " A ")
        XCTAssertTrue(result.requiresReplacement)
        XCTAssertEqual(result.plan.resultText, "中 A 文")
        XCTAssertEqual(result.plan.selection, TextSelection(anchor: 4, focus: 4))
    }

    func testProposedEditPreservesComposition() throws {
        let result = try NaturalSpacing.planProposedEdit(
            ProposedEdit(
                text: "中",
                range: TextRange(start: 1, length: 0),
                replacementText: "A",
                composingRange: TextRange(start: 1, length: 1),
                editKind: .insert,
                policy: .naturalLanguage
            )
        )

        XCTAssertEqual(result.plan.decision, .composing)
        XCTAssertEqual(result.replacementText, "A")
        XCTAssertFalse(result.requiresReplacement)
    }

    func testProposedEditSessionHonorsDeletedSpace() throws {
        let session = NaturalSpacingSession()
        let result = try session.processProposedEdit(
            ProposedEdit(
                text: "中 A",
                range: TextRange(start: 1, length: 1),
                replacementText: "",
                editKind: .delete,
                policy: .naturalLanguage
            )
        )

        XCTAssertEqual(result.plan.decision, .suppressed)
        XCTAssertEqual(result.replacementText, "")
        XCTAssertFalse(result.requiresReplacement)
        XCTAssertEqual(session.suppressedBoundaryCount, 1)
    }

    func testProposedEditRejectsInvalidRange() {
        XCTAssertThrowsError(
            try NaturalSpacing.planProposedEdit(
                ProposedEdit(
                    text: "中",
                    range: TextRange(start: 2, length: 0),
                    replacementText: "A",
                    editKind: .insert,
                    policy: .naturalLanguage
                )
            )
        ) { error in
            XCTAssertEqual(error as? ProposedEditError, .invalidRange)
        }
    }

    func testProposedEditFindsMinimalUtf16Difference() throws {
        let edit = try XCTUnwrap(
            ProposedEdit.replacingDifference(
                from: "中🙂文",
                to: "中🙂A文",
                selectionAfterEdit: TextSelection(anchor: 4, focus: 4),
                policy: .naturalLanguage
            )
        )

        XCTAssertEqual(edit.range, TextRange(start: 3, length: 0))
        XCTAssertEqual(edit.replacementText, "A")
        XCTAssertEqual(edit.editKind, .insert)
        XCTAssertNil(
            ProposedEdit.replacingDifference(
                from: "相同",
                to: "相同",
                policy: .naturalLanguage
            )
        )
    }

    private func decodeFixture<T: Decodable>(_ name: String) throws -> T {
        let url = Self.projectRoot
            .appendingPathComponent("spec/fixtures", isDirectory: true)
            .appendingPathComponent(name)
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    private static let projectRoot: URL = {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 {
            url.deleteLastPathComponent()
        }
        return url
    }()
}

private struct RuleDocument: Decodable {
    let cases: [RuleFixture]
}

private struct RuleFixture: Decodable {
    let id: String
    let policy: FieldPolicy
    let input: String
    let expected: String
}

private struct SessionDocument: Decodable {
    let scenarios: [SessionScenario]
}

private struct SessionScenario: Decodable {
    let id: String
    let steps: [SessionStep]
}

private struct SessionStep: Decodable {
    let exchange: EditExchange
    let expectedSession: ExpectedSession
}

private struct EditExchange: Decodable {
    let snapshot: EditSnapshot
    let expectedPlan: EditPlan
}

private struct ExpectedSession: Decodable {
    let suppressedBoundaryCount: Int
}

private struct PolicyDocument: Decodable {
    let cases: [PolicyFixture]
}

private struct PolicyFixture: Decodable {
    let id: String
    let context: PolicyContext
    let expected: PolicyRecommendation
}

private struct TextUpdateDocument: Decodable {
    let cases: [TextUpdateFixture]
}

private struct TextUpdateFixture: Decodable {
    let id: String
    let update: TextUpdate
    let expected: FormattedTextUpdate
}

private struct OrderedTextSessionDocument: Decodable {
    let scenarios: [OrderedTextSessionFixture]
}

private struct OrderedTextSessionFixture: Decodable {
    let id: String
    let policy: FieldPolicy
    let source: OrderedTextSource
    let operations: [OrderedTextSessionOperation]
}

private struct OrderedTextSessionOperation: Decodable {
    enum Kind: String, Decodable {
        case start
        case accept
        case cancel
    }

    let kind: Kind
    let utteranceID: String?
    let event: OrderedTextUpdateEvent?
    let expected: Expected

    private enum CodingKeys: String, CodingKey {
        case kind
        case utteranceID = "utteranceId"
        case event
        case expected
    }

    struct Expected: Decodable {
        let started: Bool?
        let cancelled: Bool?
        let accepted: Bool?
        let reason: OrderedTextUpdateReason?
        let output: FormattedTextUpdate?

        var result: OrderedTextUpdateResult? {
            guard let accepted, let reason else { return nil }
            return OrderedTextUpdateResult(
                accepted: accepted,
                reason: reason,
                output: output
            )
        }
    }
}
