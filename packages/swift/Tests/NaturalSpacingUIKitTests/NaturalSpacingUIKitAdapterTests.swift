#if canImport(UIKit)
import NaturalSpacingCore
@testable import NaturalSpacingUIKit
import UIKit
import XCTest

@MainActor
final class NaturalSpacingUIKitAdapterTests: XCTestCase {
    func testTextFieldReplacementAndSelection() throws {
        let textField = UITextField()
        textField.text = "中文"
        try setSelection(1, in: textField)
        let adapter = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)

        let accepted = adapter.shouldChange(
            in: textField,
            range: NSRange(location: 1, length: 0),
            replacementString: "2"
        )

        XCTAssertFalse(accepted)
        XCTAssertEqual(textField.text, "中 2 文")
        XCTAssertEqual(selectionOffset(in: textField), 4)
        XCTAssertEqual(adapter.lastPlan?.decision, .applied)
    }

    func testTextViewReplacementScansBothOuterBoundaries() throws {
        let textView = UITextView()
        textView.text = "前中文后"
        try setSelection(1, in: textView)
        let adapter = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)

        let accepted = adapter.shouldChange(
            in: textView,
            range: NSRange(location: 1, length: 2),
            replacementText: "A2"
        )

        XCTAssertFalse(accepted)
        XCTAssertEqual(textView.text, "前 A2 后")
        XCTAssertEqual(selectionOffset(in: textView), 5)
    }

    func testDeletedAutomaticSpaceRemainsSuppressed() {
        let textField = UITextField()
        textField.text = "中 A"
        let adapter = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)

        let accepted = adapter.shouldChange(
            in: textField,
            range: NSRange(location: 1, length: 1),
            replacementString: "",
            editKind: .delete
        )

        XCTAssertTrue(accepted)
        XCTAssertEqual(adapter.lastPlan?.decision, .suppressed)
    }

    func testBeginEditingClearsDeletionSuppression() {
        let textField = UITextField()
        textField.text = "中 A"
        let adapter = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)
        XCTAssertTrue(adapter.shouldChange(
            in: textField,
            range: NSRange(location: 1, length: 1),
            replacementString: "",
            editKind: .delete
        ))
        XCTAssertEqual(adapter.lastPlan?.decision, .suppressed)
        textField.text = "中A"

        adapter.beginEditing(in: textField)
        let accepted = adapter.shouldChange(
            in: textField,
            range: NSRange(location: 1, length: 1),
            replacementString: "A",
            editKind: .replace
        )

        XCTAssertFalse(accepted)
        XCTAssertEqual(textField.text, "中 A")
        XCTAssertEqual(adapter.lastPlan?.decision, .applied)
    }

    func testSyncAdoptsProgrammaticTextViewValue() {
        let textView = UITextView()
        textView.text = "中"
        let adapter = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)
        adapter.beginEditing(in: textView)

        textView.text = "中A"
        adapter.sync(in: textView)
        adapter.textViewDidChange(textView)

        XCTAssertEqual(textView.text, "中A")
        XCTAssertNil(adapter.lastPlan)
    }

    func testLengthLimitFailsOpenToUIKit() {
        let textField = UITextField()
        textField.text = "中"
        let adapter = NaturalSpacingUIKitAdapter(
            policy: .naturalLanguage,
            maxLengthUtf16: 2
        )

        let accepted = adapter.shouldChange(
            in: textField,
            range: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertTrue(accepted)
        XCTAssertEqual(adapter.lastPlan?.decision, .lengthLimited)
    }

    func testVerbatimPolicyLeavesUIKitEditNative() {
        let textField = UITextField()
        textField.text = "中"
        let adapter = NaturalSpacingUIKitAdapter(policy: .verbatim)

        let accepted = adapter.shouldChange(
            in: textField,
            range: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertTrue(accepted)
        XCTAssertEqual(adapter.lastPlan?.decision, .verbatim)
    }

    func testSecureTextFieldForcesVerbatim() {
        let textField = UITextField()
        textField.text = "中"
        textField.isSecureTextEntry = true
        let adapter = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)

        let accepted = adapter.shouldChange(
            in: textField,
            range: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertTrue(accepted)
        XCTAssertEqual(textField.text, "中")
        XCTAssertEqual(adapter.policy, .naturalLanguage)
        XCTAssertEqual(adapter.lastPlan?.decision, .verbatim)
    }

    @available(iOS 26.0, *)
    func testMultipleRangesFailOpen() {
        let textView = UITextView()
        textView.text = "中文"
        let adapter = NaturalSpacingUIKitAdapter(policy: .naturalLanguage)

        let accepted = adapter.shouldChange(
            in: textView,
            ranges: [
                NSRange(location: 0, length: 0),
                NSRange(location: 1, length: 0),
            ],
            replacementText: "A"
        )

        XCTAssertTrue(accepted)
        XCTAssertNil(adapter.lastPlan)
        XCTAssertEqual(textView.text, "中文")
    }
}

@MainActor
private func setSelection(_ offset: Int, in input: any UITextInput) throws {
    let start = try XCTUnwrap(
        input.position(from: input.beginningOfDocument, offset: offset)
    )
    input.selectedTextRange = try XCTUnwrap(input.textRange(from: start, to: start))
}

@MainActor
private func selectionOffset(in input: any UITextInput) -> Int? {
    guard let selection = input.selectedTextRange else { return nil }
    return input.offset(from: input.beginningOfDocument, to: selection.start)
}
#endif
