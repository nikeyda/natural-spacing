# Natural Spacing

[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

> 소스 알파 단계입니다. 패키지 레지스트리 게시는 의도적으로 비활성화되어 있습니다.

Natural Spacing은 IME 조합 입력, 선택 영역, 삭제 의도, 네이티브 실행 취소 동작을 해치지 않으면서 한자와 라틴 문자, 한자와 ASCII 숫자 경계에 예측 가능한 공백을 추가하기 위한 명세 우선 도구 모음입니다. 대화형 입력뿐 아니라 ASR, 받아쓰기, 가져온 콘텐츠, 생성된 문장과 같은 비대화형 텍스트도 대상으로 합니다.

## 상태

규칙 v1, 비공개 TypeScript/Swift/Kotlin/C#/Dart 참조 코어, 실험적 UIKit/AppKit/SwiftUI/Web/Android Views/Jetpack Compose/WinUI/WPF/Flutter 브리지가 구현되어 있습니다. 이 프로젝트에는 아직 프로덕션용 플랫폼 어댑터가 포함되어 있지 않습니다. 기존의 모든 플랫폼 브리지는 실제 입력 승인 매트릭스를 통과할 때까지 실험적 상태로 유지됩니다.

현재 마일스톤에는 다음 항목이 포함됩니다.

- 규칙 v1;
- 프로그래밍 언어에 독립적인 편집 계약;
- 버전이 고정된 Unicode 17.0 소스 메타데이터, 공식 자소 테스트 데이터, 생성된 언어 독립적 분류 및 분할 산출물;
- 공유 규칙 및 입력 세션 fixtures;
- 의존성이 없는 명세 검증기;
- 결정적 Unicode 17 자소 분할 및 분류를 사용하는 TypeScript 코어와 세션 코디네이터;
- 동일한 생성 Unicode 17 분류 및 분할 데이터를 사용하는 Foundation 전용 Swift 코어, Kotlin/JVM 코어, 의존성이 없는 .NET 10 C# 코어, 의존성이 없는 Dart 3.13 코어;
- 호스트에서 테스트할 수 있는 안정화 텍스트 코디네이터를 공유하는 실험적 WinUI 3 및 WPF `TextBox` 어댑터;
- SDK로 검증된 실험적 Flutter `TextInputFormatter` 패키지와 독립적인 경로 의존성 소비자;
- 실험적 Android Views `EditText` 어댑터;
- 실험적 상태 기반 Jetpack Compose `TextFieldValue` 어댑터;
- 실험적 단일 선택 UIKit 및 AppKit 어댑터;
- 해당 네이티브 어댑터를 기반으로 만든 실험적 iOS/macOS SwiftUI 텍스트 편집기 래퍼;
- UIKit 컨트롤과 SwiftUI binding 반영을 위한 iPhone Simulator XCTest 커버리지;
- `NSTextView`, `NSTextField` field editor, 네이티브 실행 취소/알림, SwiftUI binding 반영을 위한 macOS 호스트 XCTest 커버리지;
- 실험적 일반 텍스트 Web 및 React 호환 어댑터;
- 로컬 Chrome, Edge, Firefox, WebKit 엔진의 12개 네이티브/엔드투엔드 `input`/`textarea` 시나리오에 대한 Playwright 커버리지. 비밀번호 입력 안전 동작과 키보드/보안 입력/ASR 공유 정책 데모를 포함합니다;
- 동일한 네 엔진에서 React 19.2.8의 controlled, uncontrolled, 외부 재설정, 실행 취소/다시 실행 커버리지;
- 표시만 변경하는 점진적 `text-autospace` 스타일시트;
- 설명 가능한 정책 추천 API와 interim/final 텍스트 업데이트 API;
- `autoApply` 추천만 자동 적용하고 그 외에는 `verbatim`으로 폴백하는 안전한 언어 간 정책 해석;
- TypeScript, Swift, Kotlin, C#, Dart에서 제공자에 독립적인 순서 보장 ASR/받아쓰기 세션. 수명 주기와 revision fixtures를 공유하며 전사 텍스트는 보관하지 않습니다;
- 전체 가설, 명시적 추가 전용 delta, 순서 보장 revision, 취소, final 종료, utterance 격리를 다루는 검증된 제공자 독립적 ASR 예제;
- 공개 API를 가져와 실행하는 격리된 npm tarball, 루트 SwiftPM, Kotlin composite build, .NET ProjectReference, Dart 경로 의존성, Flutter 경로 의존성 소비자.

## 원칙

- 필드는 `naturalLanguage`를 명시적으로 선택해야 하며 기본 정책은 `verbatim`입니다.
- 활성 IME 조합 입력 범위는 절대 다시 쓰지 않습니다.
- 자동으로 삽입된 공백을 삭제하려는 사용자의 결정을 존중합니다.
- 자동 변경은 작은 삽입 patch로 표현하고 그 patch를 통해 선택 영역을 매핑합니다.
- 규칙 의미는 명세와 fixtures에 유지하며 특정 언어 구현 하나를 유일한 기준으로 삼지 않습니다.
- 정적 CSS 공백 표시와 저장되는 입력 콘텐츠를 분리합니다.
- 명시적 설정 또는 의미적 컨텍스트에서 정책을 한 번만 해석합니다. 텍스트 휴리스틱만으로 활성 편집기의 정책을 전환하지 않습니다.

## 저장소 구조

```text
Package.swift
spec/
  rules-v1.md
  content-policy-v1.md
  edit-contract.schema.json
  unicode/17.0.0/sources.json
  unicode/17.0.0/classification-ranges.json
  unicode/17.0.0/grapheme-segmentation.json
  fixtures/rules-v1.json
  fixtures/sessions-v1.json
  fixtures/policy-v1.json
  fixtures/text-updates-v1.json
  fixtures/ordered-text-sessions-v1.json
docs/
  ordered-text-updates.md
  publication-boundary.md
  adr/
examples/
  asr/
  consumers/
scripts/
  generate-unicode-tables.mjs
  generate-grapheme-tables.mjs
  validate-spec.mjs
packages/
  dart/
  dotnet/
  flutter/
  kotlin/
  typescript/core/
  typescript/web/
  swift/
```

## 명세 검증

명세 검증과 TypeScript 적합성 스위트에는 Node.js 20 이상이면 충분합니다. TypeScript 규칙은 더 이상 호스트 런타임의 Unicode 버전에 의존하지 않습니다.

```sh
npm run validate
npm test
npm run test:consumer:npm
npm run test:browser
swift test
bash scripts/test-swift-consumer.sh
bash scripts/test-ios-simulator.sh
(cd packages/kotlin && ./gradlew --no-daemon conformance :android-views:testDebugUnitTest :android-views:assembleDebug :compose:testDebugUnitTest)
bash scripts/test-kotlin-consumer.sh
dotnet run --project packages/dotnet/NaturalSpacing.Conformance/NaturalSpacing.Conformance.csproj -- .
bash scripts/test-dotnet-consumer.sh
(cd packages/dart && dart pub get && dart run tool/conformance.dart ../..)
bash scripts/test-dart-consumer.sh
bash scripts/test-flutter.sh
bash scripts/test-flutter-target-builds.sh
```

검증기는 Git 공개 후보 파일 집합에 금지된 빌드/캐시/자격 증명 경로, 일반적인 비밀 패턴, 사용자 홈 디렉터리 절대 경로, 깨진 상대 Markdown 링크가 없는지 확인합니다. 또한 JSON 문법, fixture 필수 필드, 고유 식별자, UTF-16 범위, 예상 선택 영역 경계, 고정된 Unicode 소스 메타데이터, 생성된 분류 및 분할 범위를 검사합니다. `npm test`는 다섯 개의 분류 테이블과 네 개의 생성된 네이티브 분할 테이블을 언어 독립적 산출물과 대조하고, TypeScript 코어를 빌드하며, 규칙/세션/Web/ASR 테스트를 실행합니다. 모든 코어 테스트 스위트는 동일하게 고정된 766개의 공식 자소 사례를 실행합니다. 테이블 재생성 방법은 [Unicode 데이터 워크플로](spec/unicode/README.md)를 참고하세요.

저장소에는 TypeScript/Web/ASR, Playwright Chromium/Firefox/WebKit 매트릭스, Swift/UIKit/AppKit/SwiftUI, Kotlin/JVM, C#/.NET, Dart/Flutter, Windows 어댑터 컴파일을 위한 읽기 전용 GitHub Actions 워크플로가 포함되어 있습니다. 로컬 브라우저 자동화는 현재 Chrome 152, Edge 151, Playwright Firefox 153, Playwright WebKit 26.5에서 12개의 네이티브/엔드투엔드 시나리오와 3개의 React 19 시나리오를 다룹니다. 총 60회의 브라우저 실행에는 단일 트랜잭션 네이티브 실행 취소/다시 실행, 비밀번호 입력 안전 동작, 키보드/보안 입력/순서 보장 ASR 경로에서 해석된 정책을 공유하는 실행 가능한 데모가 포함됩니다. CI는 관리형 세 엔진에서 동일한 15개 시나리오를 실행합니다. 자동화 통과는 배포판 Safari/Firefox, 실제 IME, 받아쓰기 경로, 보조 입력 소스 또는 실기기 매트릭스가 통과했음을 의미하지 않습니다.

패키지 소비자 smoke test는 적합성 테스트와 의도적으로 분리되어 있습니다. 패키징된 npm tarball의 오프라인 설치 및 가져오기, 저장소 루트가 네 개의 Apple product를 노출하는 유효한 SwiftPM 의존성인지, 독립적인 Kotlin/.NET/Dart/Flutter 프로젝트가 소스 의존성으로 코어 또는 어댑터를 가져올 수 있는지를 검증합니다. 이는 레지스트리 게시를 허가하지 않으며 tag가 있는 원격 Git, Maven, NuGet 또는 pub 의존성을 증명하지 않습니다. [소스 소비자 예제](examples/consumers/README.md)에서 시작하고 정확한 결과와 한계는 [소비자 증거 스냅샷](docs/evidence/package-consumers-2026-09-02.md)을 참고하세요. UIKit/SwiftUI, AppKit/SwiftUI, Android Views/Compose, Web, Flutter, WinUI 3, WPF 수동 도구는 [실제 입력 승인 호스트](examples/acceptance/README.md)에 별도로 정리되어 있습니다. 컴파일만으로 플랫폼 지원 수준이 올라가지는 않습니다.

애플리케이션 통합은 [소스에서 시작하기](docs/getting-started.md)를 참고하세요. 실시간 편집기, 비대화형/ASR, 표시 전용 경로 중 알맞은 방식을 선택하고 안전한 정책 해석을 설명하며 각 플랫폼 어댑터로 연결합니다.

## 정책 추천과 ASR

`recommendPolicy(context)`는 신뢰도, 이유, 증거 출처, `autoApply` 플래그와 함께 `naturalLanguage` 또는 `verbatim`을 반환합니다. 보안/비밀번호 컨텍스트에서는 항상 `verbatim`을 강제합니다. 보안 입력이 아닌 경우 명시적 정책이 우선합니다. 텍스트 전용 휴리스틱은 추천일 뿐이며 활성 편집기를 자동으로 전환하지 않습니다.

`resolvePolicy(context, fallback)`은 자동 설정을 위한 편의 경로입니다. `autoApply=true`일 때만 추천을 채택하고, 그 외에는 호출자가 지정한 fallback을 반환합니다. 기본 fallback은 `verbatim`입니다. 정책이 선택 사항인 UI 어댑터도 `verbatim`을 기본값으로 사용하므로 자연어 공백 처리는 항상 명시적으로 선택하거나 안전한 해석을 거쳐 활성화해야 합니다.

`formatTextUpdate(update)`는 ASR, 받아쓰기, 가져온 콘텐츠, 생성된 텍스트를 지원합니다. interim 가설은 표시용 텍스트를 만들지만 committed value는 없으며 final 가설은 저장할 수 있습니다. [콘텐츠 정책 및 비대화형 텍스트 v1](spec/content-policy-v1.md)을 참고하세요.

`OrderedTextUpdateSession`은 제공자에 독립적인 utterance 수명 주기와 단조 증가 revision 처리를 추가합니다. 활성 utterance의 이벤트만 허용하고 중복 또는 오래된 revision을 거부하며 유효한 final 이벤트에서 종료합니다. 활성 utterance ID와 최신 revision만 유지하고 전사 텍스트는 보관하지 않습니다. [순서 보장 ASR 및 받아쓰기 업데이트](docs/ordered-text-updates.md)를 참고하세요.

## 규칙 v1 범위

규칙 v1은 다음 직접 경계에만 양방향으로 U+0020을 삽입합니다.

- 한자 ↔ 라틴 문자;
- 한자 ↔ ASCII 숫자(`0`–`9`).

구두점, 전각 숫자, 일본어, 한국어, Markdown, 소스 코드, 서식 있는 텍스트 또는 `contenteditable`에는 규칙을 추가하지 않습니다.

## 라이선스

Apache License 2.0. [LICENSE](LICENSE)를 참고하세요.

현재 구현과 플랫폼 지원은 [COMPATIBILITY.md](COMPATIBILITY.md)에 기록되어 있습니다.
전체 플랫폼 순서와 승인 게이트는 [ROADMAP.md](ROADMAP.md)에 기록되어 있습니다.
Unicode 분할의 미지원 항목은 [분할 매트릭스](docs/unicode-segmentation-matrix.md)에 명시되어 있으며 실제 입력 증거는 [플랫폼 승인 프로토콜](docs/platform-acceptance.md)을 따릅니다.
현재 소스 게시 게이트는 [게시 준비 감사](docs/evidence/publication-readiness-2026-09-02.md)에 기록되어 있습니다.
Apple 어댑터 호스트 증거는 [macOS](docs/evidence/macos-host-2026-09-02.md)와 [iOS Simulator](docs/evidence/ios-simulator-2026-09-02.md)에 각각 기록되어 있습니다.
Flutter SDK 증거는 [Flutter 호스트 스냅샷](docs/evidence/flutter-host-2026-09-02.md)에 기록되어 있습니다.
