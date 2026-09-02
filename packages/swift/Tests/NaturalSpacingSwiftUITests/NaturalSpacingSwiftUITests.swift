import NaturalSpacingCore
import NaturalSpacingSwiftUI
import SwiftUI
import XCTest
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

final class NaturalSpacingSwiftUITests: XCTestCase {
    @MainActor
    func testEditorCanBeConstructedWithPolicyAndLengthLimit() {
        var value = "中文"
        let binding = Binding(
            get: { value },
            set: { value = $0 }
        )

        _ = NaturalSpacingTextEditor(
            text: binding,
            policy: .naturalLanguage,
            maxLengthUtf16: 40
        )
        XCTAssertEqual(value, "中文")
    }

    #if canImport(AppKit)
    @MainActor
    func testMacDefaultPolicyIsVerbatim() {
        var value = "中"
        let editor = NaturalSpacingTextEditor(
            text: Binding(
                get: { value },
                set: { value = $0 }
            )
        )
        let coordinator = editor.makeCoordinator()
        let textView = NSTextView()
        textView.string = value

        let accepted = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertTrue(accepted)
        XCTAssertEqual(textView.string, "中")
        XCTAssertEqual(value, "中")
    }

    @MainActor
    func testMacCoordinatorPublishesTransformedNativeEdit() {
        var value = "中文"
        let editor = NaturalSpacingTextEditor(
            text: Binding(
                get: { value },
                set: { value = $0 }
            ),
            policy: .naturalLanguage
        )
        let coordinator = editor.makeCoordinator()
        let textView = NSTextView()
        textView.string = value
        textView.setSelectedRange(NSRange(location: 1, length: 0))

        let accepted = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementString: "A"
        )

        XCTAssertFalse(accepted)
        XCTAssertEqual(textView.string, "中 A 文")
        XCTAssertEqual(value, "中 A 文")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 4, length: 0))
    }

    @MainActor
    func testMacCoordinatorReconcilesSettledNotificationIntoBinding() {
        var value = "中"
        let editor = NaturalSpacingTextEditor(
            text: Binding(
                get: { value },
                set: { value = $0 }
            ),
            policy: .naturalLanguage
        )
        let coordinator = editor.makeCoordinator()
        let textView = NSTextView()
        textView.string = value
        textView.setSelectedRange(NSRange(location: 1, length: 0))
        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        textView.string = "中A"
        textView.setSelectedRange(NSRange(location: 2, length: 0))
        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        XCTAssertEqual(textView.string, "中 A")
        XCTAssertEqual(value, "中 A")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 3, length: 0))
    }
    #endif

    #if canImport(UIKit)
    @MainActor
    func testIOSDefaultPolicyIsVerbatim() {
        var value = "中"
        let editor = NaturalSpacingTextEditor(
            text: Binding(
                get: { value },
                set: { value = $0 }
            )
        )
        let coordinator = editor.makeCoordinator()
        let textView = UITextView()
        textView.text = value

        let accepted = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementText: "A"
        )

        XCTAssertTrue(accepted)
        XCTAssertEqual(textView.text, "中")
        XCTAssertEqual(value, "中")
    }

    @MainActor
    func testIOSCoordinatorPublishesTransformedNativeEdit() throws {
        var value = "中文"
        let editor = NaturalSpacingTextEditor(
            text: Binding(
                get: { value },
                set: { value = $0 }
            ),
            policy: .naturalLanguage
        )
        let coordinator = editor.makeCoordinator()
        let textView = UITextView()
        textView.text = value
        let start = try XCTUnwrap(
            textView.position(from: textView.beginningOfDocument, offset: 1)
        )
        textView.selectedTextRange = try XCTUnwrap(
            textView.textRange(from: start, to: start)
        )

        let accepted = coordinator.textView(
            textView,
            shouldChangeTextIn: NSRange(location: 1, length: 0),
            replacementText: "A"
        )

        XCTAssertFalse(accepted)
        XCTAssertEqual(textView.text, "中 A 文")
        XCTAssertEqual(value, "中 A 文")
        let selection = try XCTUnwrap(textView.selectedTextRange)
        XCTAssertEqual(
            textView.offset(from: textView.beginningOfDocument, to: selection.start),
            4
        )
    }
    #endif
}
