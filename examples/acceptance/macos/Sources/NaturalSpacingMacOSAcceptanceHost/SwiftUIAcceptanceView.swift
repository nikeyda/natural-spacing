import NaturalSpacingCore
import NaturalSpacingSwiftUI
import SwiftUI

@MainActor
struct MacOSSwiftUIAcceptanceView: View {
    private static let messageContext = PolicyContext(contentKind: .message)
    private static let codeContext = PolicyContext(contentKind: .code)

    private let messageRecommendation = NaturalSpacing.recommendPolicy(messageContext)
    private let codeRecommendation = NaturalSpacing.recommendPolicy(codeContext)
    private let messagePolicy = NaturalSpacing.resolvePolicy(messageContext)
    private let codePolicy = NaturalSpacing.resolvePolicy(codeContext)

    @State private var message = ""
    @State private var code = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Use synthetic text only. Compare binding publication, marked-text composition, selection, paste, undo, dictation, hardware keyboards, focus, lifecycle, and VoiceOver with the AppKit tab.")
                    .font(.footnote)

                sectionTitle("Message · \(messagePolicy.rawValue)")
                NaturalSpacingTextEditor(text: $message, policy: messagePolicy)
                    .frame(minHeight: 140)
                    .border(Color.secondary)
                diagnostics(
                    text: message,
                    policy: messagePolicy,
                    recommendation: messageRecommendation
                )

                sectionTitle("Code · \(codePolicy.rawValue)")
                    .padding(.top, 12)
                NaturalSpacingTextEditor(text: $code, policy: codePolicy)
                    .frame(minHeight: 140)
                    .border(Color.secondary)
                diagnostics(
                    text: code,
                    policy: codePolicy,
                    recommendation: codeRecommendation
                )

                Button("Reset SwiftUI session") {
                    message = ""
                    code = ""
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.headline)
    }

    private func diagnostics(
        text: String,
        policy: FieldPolicy,
        recommendation: PolicyRecommendation
    ) -> some View {
        Text(
            "policy=\(policy.rawValue)\n"
                + "recommendation=\(recommendation.policy.rawValue) \(recommendation.confidence.rawValue)\n"
                + "reason=\(recommendation.source.rawValue)/\(recommendation.reason.rawValue)\n"
                + "binding=\(text)"
        )
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(.secondary)
    }
}
