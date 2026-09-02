# Package consumer evidence — 2026-09-02

This snapshot verifies source-package consumption before any public repository, Git tag, or registry release exists. It is not publication approval.

## npm tarballs

Command:

```sh
npm run test:consumer:npm
```

The smoke test builds and packs the TypeScript core and Web packages, stages the pinned `unicode-segmenter` runtime dependency, installs all tarballs offline into an isolated temporary package, and imports the core, Web adapter, and CSS export. It exercises normalization, policy recommendation, safe policy resolution including secure override, the ordered text-update session, and the exported binding class. The ordered stream verifies accepted interim display without persistence, stale-revision rejection, final persistence, and rejection after final closure.

Result: passed.

## Swift Package Manager

Commands:

```sh
swift test
bash scripts/test-swift-consumer.sh
bash scripts/test-ios-simulator.sh
```

The public Swift manifest is at the repository root because SwiftPM resolves a Git dependency from that root. An independent executable package depends on the root package and imports `NaturalSpacingCore`, `NaturalSpacingAppKit`, and `NaturalSpacingSwiftUI`. The consumer exercises recommendation, safe resolution including secure override, normalization, ordered interim/stale/final/closed updates, and adapter construction. Root package tests pass 28/28 on the macOS host; the iPhone Air/iOS 26.4 Simulator suite passes 25/25.

Result: passed for a local path dependency. A future remote URL and tag remain unverified.

## Kotlin/JVM and Android adapters

Command:

```sh
bash scripts/test-kotlin-consumer.sh
```

An independent Gradle application includes the Kotlin source build as a composite build and uses explicit dependency substitution for the core, Android Views, and Compose modules. Its JVM executable imports the public policy, resolution, normalization, and ordered text-update APIs and verifies automatic natural-language selection, secure override, the safe advisory fallback, and the interim/stale/final/closed ordered lifecycle. A separate API 35 Android library submodule imports `NaturalSpacingEditTextAdapter` and `NaturalSpacingTextFieldValueAdapter`, resolves a message policy through the core, and assembles a Debug AAR. The temporary `consumer.local` coordinates exist only inside this smoke test and do not choose future Maven groups or artifact names.

Result: JVM execution and independent Android Views/Compose consumer compilation passed locally with Gradle 8.13, Kotlin 2.0.20, AGP 8.11.1, API 35, and JDK 17.

## .NET

Command:

```sh
bash scripts/test-dotnet-consumer.sh
```

An independent .NET 10 executable references `NaturalSpacing.Core.csproj`, imports the public policy, resolution, `NaturalSpacingFormatter`, `NaturalSpacingObservedTextSession`, and `OrderedTextUpdateSession` APIs, and verifies automatic natural-language selection, secure override, the safe advisory fallback, Han/ASCII-digit observed-edit coordination with selection mapping, and the interim/stale/final/closed ordered ASR lifecycle. The consumer test exposed a collision between the former `NaturalSpacing` type and its top-level namespace; the pre-release API was renamed to `NaturalSpacingFormatter`, so ordinary consumers no longer need a type alias or fully qualified name.

Result: passed locally with .NET SDK 10.0.400/runtime 10.0.11.

## Dart package

Command:

```sh
bash scripts/test-dart-consumer.sh
```

An independent Dart executable declares `packages/dart` as a path dependency, imports `package:natural_spacing/natural_spacing.dart`, and exercises recommendation, safe resolution including secure override, normalization, advisory fallback, and the interim/stale/final/closed ordered text-update lifecycle with an isolated pub cache.

Result: passed locally with Dart 3.13.3.

## Flutter package

Command:

```sh
bash scripts/test-flutter.sh
```

An independent Flutter application declares direct path dependencies on the Dart core and Flutter adapter. It imports `NaturalSpacingTextInputFormatter` and `OrderedTextUpdateSession`, verifies explicit natural-language spacing and selection mapping, verifies the safe default `verbatim` behavior, mounts a real `TextField` whose policy is resolved from a message content kind, and exercises ordered ASR updates.

Result: analyzer clean and 4/4 consumer application tests passed locally with Flutter 3.47.2/Dart 3.13.2. A disposable source consumer also built a Darwin bundle, Web debug output, macOS debug app, unsigned iOS Simulator app, and Android debug APK. The adapter package's separate 11/11 formatter/`TextField` host tests passed.

## Remaining packaging gates

- Final repository and package names, registry namespaces, owners, and versions are undecided.
- npm packages remain `private: true` at `0.0.0`; Dart remains `publish_to: none` at `0.0.0`.
- Kotlin core plus Android Views/Compose and .NET source dependencies are verified, but Maven and NuGet artifacts are not; their coordinates remain undecided.
- Flutter source consumption is verified, but pub registry consumption and target-runtime acceptance are not.
- No GitHub Actions run, signed tag, remote Git dependency, registry install, or provenance attestation exists yet.
