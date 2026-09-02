import NaturalSpacingCore
import NaturalSpacingUIKit
import SwiftUI
import UIKit

@main
@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let uiKitController = UINavigationController(
            rootViewController: AcceptanceViewController()
        )
        uiKitController.tabBarItem = UITabBarItem(title: "UIKit", image: nil, tag: 0)

        let swiftUIController = UIHostingController(rootView: SwiftUIAcceptanceView())
        swiftUIController.tabBarItem = UITabBarItem(title: "SwiftUI", image: nil, tag: 1)

        let tabs = UITabBarController()
        tabs.viewControllers = [uiKitController, swiftUIController]
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

@MainActor
final class AcceptanceViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    private static let messageContext = PolicyContext(contentKind: .message)
    private static let passwordContext = PolicyContext(
        explicitPolicy: .naturalLanguage,
        contentKind: .password,
        isSecure: true
    )

    private let messageRecommendation = NaturalSpacing.recommendPolicy(messageContext)
    private let passwordRecommendation = NaturalSpacing.recommendPolicy(passwordContext)
    private let messagePolicy = NaturalSpacing.resolvePolicy(
        messageContext
    )
    private let passwordPolicy = NaturalSpacing.resolvePolicy(
        passwordContext
    )

    private lazy var messageAdapter = NaturalSpacingUIKitAdapter(policy: messagePolicy)
    private lazy var passwordAdapter = NaturalSpacingUIKitAdapter(policy: passwordPolicy)

    private let messageView = UITextView()
    private let passwordField = UITextField()
    private let messageDiagnostics = UILabel()
    private let passwordDiagnostics = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Natural Spacing acceptance"
        view.backgroundColor = .systemBackground
        configureControls()
        configureLayout()
        messageAdapter.sync(in: messageView)
        passwordAdapter.sync(in: passwordField)
        refreshDiagnostics()
    }

    private func configureControls() {
        let instructions = UILabel()
        instructions.numberOfLines = 0
        instructions.font = .preferredFont(forTextStyle: .footnote)
        instructions.text = "Use synthetic text only. Test composition, selection, paste, deletion, undo, dictation, hardware keyboards, and VoiceOver separately."
        instructions.accessibilityIdentifier = "acceptance.instructions"

        messageView.delegate = self
        messageView.font = .preferredFont(forTextStyle: .body)
        messageView.layer.borderColor = UIColor.separator.cgColor
        messageView.layer.borderWidth = 1
        messageView.layer.cornerRadius = 8
        messageView.autocorrectionType = .yes
        messageView.accessibilityLabel = "Message natural language"
        messageView.accessibilityIdentifier = "acceptance.message"
        messageView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)

        passwordField.delegate = self
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect
        passwordField.autocorrectionType = .no
        passwordField.spellCheckingType = .no
        passwordField.textContentType = .password
        passwordField.placeholder = "Password · forced verbatim"
        passwordField.accessibilityLabel = "Password forced verbatim"
        passwordField.accessibilityIdentifier = "acceptance.password"
        passwordField.addTarget(self, action: #selector(passwordEditingChanged), for: .editingChanged)

        for label in [messageDiagnostics, passwordDiagnostics] {
            label.numberOfLines = 0
            label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            label.textColor = .secondaryLabel
        }
        messageDiagnostics.accessibilityIdentifier = "acceptance.message.diagnostics"
        passwordDiagnostics.accessibilityIdentifier = "acceptance.password.diagnostics"

        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset session", for: .normal)
        resetButton.accessibilityIdentifier = "acceptance.reset"
        resetButton.addTarget(self, action: #selector(resetSession), for: .touchUpInside)

        let messageTitle = sectionTitle("Message · \(messagePolicy.rawValue)")
        let passwordTitle = sectionTitle("Password · \(passwordPolicy.rawValue)")
        let stack = UIStackView(arrangedSubviews: [
            instructions,
            messageTitle,
            messageView,
            messageDiagnostics,
            passwordTitle,
            passwordField,
            passwordDiagnostics,
            resetButton,
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(24, after: instructions)
        stack.setCustomSpacing(24, after: messageDiagnostics)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.accessibilityIdentifier = "acceptance.stack"

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            messageView.heightAnchor.constraint(equalToConstant: 120),
        ])
    }

    private func configureLayout() {
        messageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.text = text
        return label
    }

    @objc private func passwordEditingChanged() {
        passwordAdapter.editingChanged(in: passwordField)
        refreshDiagnostics()
    }

    @objc private func resetSession() {
        messageView.text = ""
        passwordField.text = ""
        messageAdapter.sync(in: messageView)
        passwordAdapter.sync(in: passwordField)
        refreshDiagnostics()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        messageAdapter.beginEditing(in: textView)
        refreshDiagnostics()
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let result = messageAdapter.shouldChange(
            in: textView,
            range: range,
            replacementText: text
        )
        DispatchQueue.main.async { [weak self] in self?.refreshDiagnostics() }
        return result
    }

    func textViewDidChange(_ textView: UITextView) {
        messageAdapter.textViewDidChange(textView)
        refreshDiagnostics()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        refreshDiagnostics()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        passwordAdapter.beginEditing(in: textField)
        refreshDiagnostics()
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let result = passwordAdapter.shouldChange(
            in: textField,
            range: range,
            replacementString: string
        )
        DispatchQueue.main.async { [weak self] in self?.refreshDiagnostics() }
        return result
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func refreshDiagnostics() {
        messageDiagnostics.text = diagnostics(
            policy: messagePolicy,
            recommendation: messageRecommendation,
            input: messageView,
            text: messageView.text,
            plan: messageAdapter.lastPlan
        )
        passwordDiagnostics.text = diagnostics(
            policy: passwordPolicy,
            recommendation: passwordRecommendation,
            input: passwordField,
            text: nil,
            plan: passwordAdapter.lastPlan
        )
    }

    private func diagnostics(
        policy: FieldPolicy,
        recommendation: PolicyRecommendation,
        input: any UITextInput,
        text: String?,
        plan: EditPlan?
    ) -> String {
        let textValue = text ?? "<hidden>"
        return [
            "policy=\(policy.rawValue)",
            "recommendation=\(recommendation.policy.rawValue) \(recommendation.confidence.rawValue)",
            "reason=\(recommendation.source.rawValue)/\(recommendation.reason.rawValue)",
            "text=\(textValue)",
            "selection=\(rangeDescription(input.selectedTextRange, in: input))",
            "composing=\(rangeDescription(input.markedTextRange, in: input))",
            "decision=\(plan?.decision.rawValue ?? "none")",
        ].joined(separator: "\n")
    }

    private func rangeDescription(_ range: UITextRange?, in input: any UITextInput) -> String {
        guard let range else { return "none" }
        let start = input.offset(from: input.beginningOfDocument, to: range.start)
        let end = input.offset(from: input.beginningOfDocument, to: range.end)
        return "\(start)..\(end)"
    }
}
