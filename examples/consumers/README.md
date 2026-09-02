# Source consumer examples

These examples verify that another project can import Natural Spacing without relying on the repository's conformance runner. Registry publication remains disabled, so every example uses a local source dependency.

| Ecosystem | Dependency under test | Command |
|---|---|---|
| npm | Packed TypeScript Core and Web tarballs installed offline | `npm run test:consumer:npm` |
| SwiftPM | Repository-root package path exposing Core, UIKit, AppKit, and SwiftUI products | `bash scripts/test-swift-consumer.sh` |
| Kotlin/JVM + Android adapters | Gradle composite build with test-only substituted coordinates | `bash scripts/test-kotlin-consumer.sh` |
| .NET | `ProjectReference` to `NaturalSpacing.Core` | `bash scripts/test-dotnet-consumer.sh` |
| Dart | Path dependency on `packages/dart` | `bash scripts/test-dart-consumer.sh` |
| Flutter | Path dependencies on the Flutter adapter and Dart core | `bash scripts/test-flutter.sh` |

Each executable checks a high-confidence natural-language context, normalization of `发布v2版本`, the safe `verbatim` fallback for an advisory search-query recommendation, and the public ordered text-update session. The five core consumers exercise accepted interim display, stale-revision rejection, final persistence, and final closure. The Swift example also imports the AppKit and SwiftUI products; npm additionally verifies the Web class and CSS export. The Kotlin composite consumer runs the JVM core executable and compiles a separate Android library importing both the Android Views and Compose adapters through temporary `consumer.local` substitutions. The Flutter consumer is a minimal `TextField` application with an ordered ASR test; `scripts/test-flutter-target-builds.sh` generates disposable platform shells and builds bundle plus Web by default.

These are source-consumption checks, not registry checks. Maven, NuGet, pub, tagged SwiftPM URL, and public npm installation remain release gates until names, owners, and versions are approved.

The browser-focused [`examples/web/app.mjs`](../web/app.mjs) is complementary:
it is not a packaging smoke test, but an executable end-to-end integration of
policy resolution, native keyboard binding, secure-field preservation, and
ordered ASR interim/final handling. Playwright runs it in Chrome, Edge,
Firefox, and WebKit.

Manual real-input harnesses live separately under `examples/acceptance`; they
do not raise a platform's support level until the named matrix is executed and
recorded according to `docs/platform-acceptance.md`.
