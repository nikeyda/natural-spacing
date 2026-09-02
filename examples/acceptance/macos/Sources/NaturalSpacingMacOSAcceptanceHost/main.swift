import AppKit
import NaturalSpacingAppKit
import NaturalSpacingCore
import SwiftUI

@MainActor
private final class AcceptanceHost: NSObject, NSApplicationDelegate, NSTextViewDelegate {
    private static let messageContext = PolicyContext(contentKind: .message)

    private let recommendation = NaturalSpacing.recommendPolicy(messageContext)
    private let policy = NaturalSpacing.resolvePolicy(messageContext)
    private var window: NSWindow!
    private var textView: NSTextView!
    private var statusLabel: NSTextField!
    private var adapter: NaturalSpacingAppKitAdapter!

    func applicationDidFinishLaunching(_ notification: Notification) {
        precondition(policy == .naturalLanguage)
        adapter = NaturalSpacingAppKitAdapter(policy: policy)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Natural Spacing macOS Acceptance"
        window.center()

        let tabView = NSTabView(frame: window.contentView!.bounds)
        tabView.autoresizingMask = [.width, .height]
        window.contentView = tabView

        let appKitPanel = NSView(frame: NSRect(x: 0, y: 0, width: 760, height: 500))
        appKitPanel.autoresizingMask = [.width, .height]
        let appKitTab = NSTabViewItem(identifier: "appkit")
        appKitTab.label = "AppKit"
        appKitTab.view = appKitPanel
        tabView.addTabViewItem(appKitTab)

        let swiftUIPanel = NSHostingView(rootView: MacOSSwiftUIAcceptanceView())
        swiftUIPanel.autoresizingMask = [.width, .height]
        let swiftUITab = NSTabViewItem(identifier: "swiftui")
        swiftUITab.label = "SwiftUI"
        swiftUITab.view = swiftUIPanel
        tabView.addTabViewItem(swiftUITab)

        let instructions = NSTextField(wrappingLabelWithString: "Type synthetic text with the named input source. The host resolves message semantics to naturalLanguage, preserves active marked text, and reconciles only settled edits.")
        instructions.frame = NSRect(x: 24, y: 452, width: 712, height: 44)
        instructions.autoresizingMask = [.width, .minYMargin]
        appKitPanel.addSubview(instructions)

        let scrollView = NSScrollView(frame: NSRect(x: 24, y: 154, width: 712, height: 280))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true

        textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.autoresizingMask = [.width]
        textView.isRichText = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.font = .systemFont(ofSize: 26)
        textView.delegate = self
        textView.setAccessibilityLabel("Natural language acceptance editor")
        scrollView.documentView = textView
        appKitPanel.addSubview(scrollView)

        statusLabel = NSTextField(wrappingLabelWithString: "")
        statusLabel.frame = NSRect(x: 24, y: 62, width: 712, height: 76)
        statusLabel.autoresizingMask = [.width, .maxYMargin]
        statusLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        statusLabel.setAccessibilityLabel("Editor status")
        appKitPanel.addSubview(statusLabel)

        let resetButton = NSButton(
            title: "Reset synthetic text",
            target: self,
            action: #selector(resetEditor)
        )
        resetButton.frame = NSRect(x: 24, y: 20, width: 180, height: 30)
        resetButton.autoresizingMask = [.maxYMargin]
        appKitPanel.addSubview(resetButton)

        adapter.beginEditing(in: textView)
        updateStatus()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(textView)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func textDidBeginEditing(_ notification: Notification) {
        adapter.beginEditing(in: textView)
        updateStatus()
    }

    func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        adapter.shouldChangeText(
            in: textView,
            range: affectedCharRange,
            replacementString: replacementString
        )
    }

    func textDidChange(_ notification: Notification) {
        adapter.textDidChange(in: textView)
        updateStatus()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        updateStatus()
    }

    @objc private func resetEditor() {
        textView.string = ""
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        adapter.sync(in: textView)
        window.makeFirstResponder(textView)
        updateStatus()
    }

    private func updateStatus() {
        let selection = textView.selectedRange()
        let decision = adapter.lastPlan.map { String(describing: $0.decision) } ?? "none"
        statusLabel.stringValue = "policy=\(policy.rawValue)  recommendation=\(recommendation.policy.rawValue)/\(recommendation.confidence.rawValue)  reason=\(recommendation.source.rawValue)/\(recommendation.reason.rawValue)\nmarked=\(textView.hasMarkedText())  selection=\(selection.location):\(selection.length)  decision=\(decision)\ntext=\(String(reflecting: textView.string))"
    }
}

let application = NSApplication.shared
private let delegate = AcceptanceHost()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
