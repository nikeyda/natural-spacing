#if canImport(AppKit)
import AppKit
import XCTest
@testable import NaturalSpacingAppKit

@MainActor
final class NaturalSpacingAppKitAdapterTests: XCTestCase {
    func testTextFieldFieldEditorReplacementAndSelection() throws {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        let textField = NSTextField(string: "中文")
        window.contentView = NSView(frame: window.contentLayoutRect)
        window.contentView?.addSubview(textField)
        XCTAssertTrue(window.makeFirstResponder(textField))
        let fieldEditor = try XCTUnwrap(
            window.fieldEditor(true, for: textField) as? NSTextView
        )
        fieldEditor.string = textField.stringValue
        fieldEditor.setSelectedRange(NSRange(location: 1, length: 0))
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        let shouldApplyOriginal = adapter.shouldChangeText(
            in: fieldEditor,
            range: NSRange(location: 1, length: 0),
            replacementString: "2"
        )

        XCTAssertFalse(shouldApplyOriginal)
        XCTAssertTrue(fieldEditor.isFieldEditor)
        XCTAssertEqual(fieldEditor.string, "中 2 文")
        XCTAssertEqual(fieldEditor.selectedRange(), NSRange(location: 4, length: 0))
    }

    func testTextViewReplacementAndSelection() {
        let textView = NSTextView()
        textView.string = "中文"
        textView.setSelectedRange(NSRange(location: 1, length: 0))
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        let shouldApplyOriginal = adapter.shouldChangeText(
            in: textView,
            range: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertFalse(shouldApplyOriginal)
        XCTAssertEqual(textView.string, "中 A 文")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 4, length: 0))
        XCTAssertEqual(adapter.lastPlan?.decision, .applied)
    }

    func testTextViewLeavesMarkedTextUntouched() {
        let textView = MarkedTextView()
        textView.string = "中"
        textView.reportedMarkedRange = NSRange(location: 1, length: 1)
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        let shouldApplyOriginal = adapter.shouldChangeText(
            in: textView,
            range: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertTrue(shouldApplyOriginal)
        XCTAssertEqual(textView.string, "中")
        XCTAssertEqual(adapter.lastPlan?.decision, .composing)
    }

    func testTextViewReconcilesAfterCompositionEnds() {
        let textView = MarkedTextView()
        textView.string = "中"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)
        adapter.beginEditing(in: textView)

        textView.reportedMarkedRange = NSRange(location: 1, length: 1)
        textView.string = "中A"
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        adapter.textDidChange(in: textView)
        XCTAssertEqual(textView.string, "中A")

        textView.reportedMarkedRange = NSRange(location: NSNotFound, length: 0)
        adapter.textDidChange(in: textView)
        XCTAssertEqual(textView.string, "中 A")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 3, length: 0))
        XCTAssertEqual(adapter.lastPlan?.decision, .applied)
    }

    func testTextViewReplacementUsesNativeUndo() throws {
        let textView = NSTextView()
        textView.allowsUndo = true
        let delegate = UndoTextViewDelegate()
        textView.delegate = delegate
        textView.string = "中文"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        XCTAssertFalse(
            adapter.shouldChangeText(
                in: textView,
                range: NSRange(location: 1, length: 0),
                replacementString: "A"
            )
        )
        let undoManager = try XCTUnwrap(textView.undoManager)
        XCTAssertTrue(undoManager.canUndo)

        undoManager.undo()
        XCTAssertEqual(textView.string, "中文")
    }

    func testTextViewReplacementPublishesNativeChangeNotification() {
        let textView = NSTextView()
        let delegate = ChangeNotificationTextViewDelegate()
        textView.delegate = delegate
        textView.string = "中文"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        XCTAssertFalse(
            adapter.shouldChangeText(
                in: textView,
                range: NSRange(location: 1, length: 0),
                replacementString: "A"
            )
        )

        XCTAssertEqual(delegate.didChangeCount, 1)
        XCTAssertEqual(textView.string, "中 A 文")
    }

    func testTextViewFailsOpenWhenHostRejectsValidatedReplacement() {
        let textView = NSTextView()
        let delegate = RejectingTextViewDelegate()
        textView.delegate = delegate
        textView.string = "中文"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        let shouldApplyOriginal = adapter.shouldChangeText(
            in: textView,
            range: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertTrue(shouldApplyOriginal)
        XCTAssertEqual(delegate.validationCount, 1)
        XCTAssertEqual(textView.string, "中文")
        XCTAssertEqual(adapter.lastPlan?.decision, .applied)
    }

    func testSettledReconciliationKeepsNativeBaselineWhenHostRejectsReplacement() {
        let textView = NSTextView()
        let delegate = RejectingTextViewDelegate()
        textView.delegate = delegate
        textView.string = "中"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)
        adapter.beginEditing(in: textView)

        textView.string = "中A"
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        adapter.textDidChange(in: textView)

        XCTAssertEqual(textView.string, "中A")
        XCTAssertEqual(delegate.validationCount, 1)

        textView.string = "中AB"
        textView.setSelectedRange(NSRange(location: 3, length: 0))
        adapter.textDidChange(in: textView)

        XCTAssertEqual(textView.string, "中AB")
        XCTAssertEqual(delegate.validationCount, 1)
        XCTAssertEqual(adapter.lastPlan?.decision, .noChange)
    }

    func testMultipleRangesFailOpen() {
        let textView = NSTextView()
        textView.string = "中文"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        let shouldApplyOriginal = adapter.shouldChangeText(
            in: textView,
            ranges: [
                NSRange(location: 0, length: 0),
                NSRange(location: 1, length: 0),
            ],
            replacementStrings: ["A", "B"]
        )

        XCTAssertTrue(shouldApplyOriginal)
        XCTAssertNil(adapter.lastPlan)
        XCTAssertEqual(textView.string, "中文")
    }

    func testTextViewHonorsManualSpaceDeletion() {
        let textView = NSTextView()
        textView.string = "中 A"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)

        let shouldApplyOriginal = adapter.shouldChangeText(
            in: textView,
            range: NSRange(location: 1, length: 1),
            replacementString: ""
        )

        XCTAssertTrue(shouldApplyOriginal)
        XCTAssertEqual(adapter.lastPlan?.decision, .suppressed)
    }

    func testBeginEditingClearsDeletionSuppression() {
        let textView = NSTextView()
        textView.string = "中 A"
        let adapter = NaturalSpacingAppKitAdapter(policy: .naturalLanguage)
        XCTAssertTrue(adapter.shouldChangeText(
            in: textView,
            range: NSRange(location: 1, length: 1),
            replacementString: "",
            editKind: .delete
        ))
        XCTAssertEqual(adapter.lastPlan?.decision, .suppressed)
        textView.string = "中A"

        adapter.beginEditing(in: textView)
        let accepted = adapter.shouldChangeText(
            in: textView,
            range: NSRange(location: 1, length: 1),
            replacementString: "A",
            editKind: .replace
        )

        XCTAssertFalse(accepted)
        XCTAssertEqual(textView.string, "中 A")
        XCTAssertEqual(adapter.lastPlan?.decision, .applied)
    }
}

@MainActor
private final class UndoTextViewDelegate: NSObject, NSTextViewDelegate {
    let manager = UndoManager()

    func undoManager(for view: NSTextView) -> UndoManager? {
        manager
    }
}

@MainActor
private final class ChangeNotificationTextViewDelegate: NSObject, NSTextViewDelegate {
    private(set) var didChangeCount = 0

    func textDidChange(_ notification: Notification) {
        didChangeCount += 1
    }
}

@MainActor
private final class RejectingTextViewDelegate: NSObject, NSTextViewDelegate {
    private(set) var validationCount = 0

    func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        validationCount += 1
        return false
    }
}

@MainActor
private final class MarkedTextView: NSTextView {
    var reportedMarkedRange = NSRange(location: NSNotFound, length: 0)

    override func markedRange() -> NSRange {
        reportedMarkedRange
    }

    override func hasMarkedText() -> Bool {
        reportedMarkedRange.location != NSNotFound
    }
}
#endif
