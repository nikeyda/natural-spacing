# Natural Spacing

[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

> ソースコードのアルファ版です。パッケージレジストリへの公開は意図的に無効化されています。

Natural Spacing は、IME の変換中テキスト、選択範囲、削除意図、ネイティブの Undo 動作を壊すことなく、漢字とラテン文字、漢字と ASCII 数字の境界に予測可能な空白を追加する、仕様優先のツールキットです。対話的な入力だけでなく、ASR、音声入力、インポートされたコンテンツ、生成文章などの非対話的なテキストも対象とします。

## ステータス

ルール v1、非公開の TypeScript/Swift/Kotlin/C#/Dart リファレンスコア、および実験的な UIKit/AppKit/SwiftUI/Web/Android Views/Jetpack Compose/WinUI/WPF/Flutter ブリッジが実装されています。本プロジェクトには、まだ本番向けのプラットフォームアダプターは含まれていません。既存の各プラットフォームブリッジは、実入力の受け入れマトリクスを通過するまで実験的な扱いです。

現在のマイルストーンには以下が含まれます。

- ルール v1。
- プログラミング言語に依存しない編集コントラクト。
- バージョンを固定した Unicode 17.0 ソースメタデータ、公式の書記素テストデータ、生成済みの言語非依存な分類・分割アーティファクト。
- 共有ルールおよび入力セッション fixtures。
- 依存関係を持たない仕様バリデーター。
- 決定的な Unicode 17 書記素分割・分類を使用する TypeScript コアおよびセッションコーディネーター。
- 同じ生成済み Unicode 17 分類・分割データを使用する、Foundation のみに依存する Swift コア、Kotlin/JVM コア、依存関係のない .NET 10 C# コア、依存関係のない Dart 3.13 コア。
- ホストからテスト可能な確定テキストコーディネーターを共有する、実験的な WinUI 3 および WPF `TextBox` アダプター。
- SDK で検証済みの実験的な Flutter `TextInputFormatter` パッケージと、独立したパス依存コンシューマー。
- 実験的な Android Views `EditText` アダプター。
- 実験的なステートフル Jetpack Compose `TextFieldValue` アダプター。
- 実験的な単一選択 UIKit および AppKit アダプター。
- それらのネイティブアダプター上に構築された、実験的な iOS/macOS SwiftUI テキストエディターラッパー。
- UIKit コントロールと SwiftUI binding の反映を対象とする iPhone Simulator XCTest カバレッジ。
- `NSTextView`、`NSTextField` の field editor、ネイティブの Undo/通知、SwiftUI binding の反映を対象とする macOS ホスト XCTest カバレッジ。
- 実験的なプレーンテキスト Web アダプターおよび React 互換アダプター。
- ローカルの Chrome、Edge、Firefox、WebKit エンジン上の 12 個のネイティブ/エンドツーエンド `input`/`textarea` シナリオを対象とする Playwright カバレッジ。パスワード入力のフェイルセーフと、キーボード/セキュア入力/ASR で共通のポリシーデモを含みます。
- 同じ 4 エンジン上での React 19.2.8 の controlled、uncontrolled、外部リセット、Undo/Redo カバレッジ。
- 表示だけに作用する、段階的な `text-autospace` スタイルシート。
- 説明可能なポリシー推奨 API と interim/final テキスト更新 API。
- `autoApply` の推奨だけを自動適用し、それ以外は `verbatim` にフォールバックする、安全な言語横断ポリシー解決。
- TypeScript、Swift、Kotlin、C#、Dart におけるプロバイダー非依存の順序付き ASR/音声入力セッション。ライフサイクルと revision の fixtures を共有し、文字起こし本文は保持しません。
- 完全仮説、明示的な追記専用 delta、順序付き revision、キャンセル、final クローズ、utterance 分離を対象とする、テスト済みのプロバイダー非依存 ASR サンプル。
- 公開 API をインポートして実行する、分離された npm tarball、ルート SwiftPM、Kotlin composite build、.NET ProjectReference、Dart パス依存、Flutter パス依存の各コンシューマー。

## 原則

- フィールドは `naturalLanguage` を明示的に選択します。デフォルトポリシーは `verbatim` です。
- アクティブな IME 変換範囲は絶対に書き換えません。
- 自動挿入された空白を削除するというユーザーの判断を尊重します。
- 自動変更は小さな挿入 patch として表現し、その patch を通して選択範囲をマッピングします。
- ルールの意味は仕様と fixtures に保持し、特定言語の実装だけを唯一の正としません。
- 静的な CSS の空白表示と、保存される入力内容を分離します。
- 明示設定または意味的コンテキストからポリシーを一度だけ解決します。テキストのヒューリスティクスだけを根拠に、編集中のエディターのポリシーを切り替えません。

## リポジトリ構成

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

## 仕様の検証

仕様の検証と TypeScript 適合性スイートの実行には Node.js 20 以降で十分です。TypeScript のルールは、ホストランタイムの Unicode バージョンに依存しません。

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

バリデーターは、Git の公開候補ファイル集合に禁止されたビルド/キャッシュ/認証情報のパス、一般的なシークレットパターン、ユーザーのホームディレクトリを含む絶対パス、壊れた相対 Markdown リンクがないか確認します。また、JSON 構文、fixture の必須フィールド、一意な識別子、UTF-16 範囲、期待される選択範囲の境界、固定された Unicode ソースメタデータ、生成済み分類・分割範囲も確認します。`npm test` はさらに、5 つの分類テーブルと 4 つの生成済みネイティブ分割テーブルを言語非依存アーティファクトと照合し、TypeScript コアをビルドして、ルール、セッション、Web、ASR のテストを実行します。各コアのテストスイートは、同じ 766 件の固定された公式書記素ケースを実行します。テーブルの再生成方法は [Unicode データワークフロー](spec/unicode/README.md) を参照してください。

リポジトリには、TypeScript/Web/ASR、Playwright の Chromium/Firefox/WebKit マトリクス、Swift/UIKit/AppKit/SwiftUI、Kotlin/JVM、C#/.NET、Dart/Flutter、および Windows アダプターのコンパイルを対象とする読み取り専用 GitHub Actions ワークフローがあります。ローカルのブラウザー自動化では、Chrome 152、Edge 151、Playwright Firefox 153、Playwright WebKit 26.5 上の 12 個のネイティブ/エンドツーエンドシナリオと 3 個の React 19 シナリオ、合計 60 回のブラウザー実行をカバーします。単一トランザクションのネイティブ Undo/Redo、パスワード入力のフェイルセーフ、キーボード/セキュア入力/順序付き ASR で解決済みポリシーを共有する実行可能なデモを含みます。CI は管理された 3 エンジンで同じ 15 シナリオを実行します。自動化の成功は、リリース版 Safari/Firefox、実際の IME、音声入力経路、支援入力ソース、実機マトリクスの合格を意味しません。

パッケージコンシューマーの smoke test は、適合性テストと意図的に分離されています。パック済み npm tarball のオフラインインストールとインポート、リポジトリルートが 4 つの Apple product を公開する有効な SwiftPM 依存であること、独立した Kotlin、.NET、Dart、Flutter プロジェクトがソース依存を通じてコアまたはアダプターをインポートできることを検証します。これらはレジストリ公開を許可せず、tag 付きリモート Git、Maven、NuGet、pub の依存関係を証明しません。[ソースコンシューマーのサンプル](examples/consumers/README.md)から始め、正確な結果と制限は[コンシューマー証拠のスナップショット](docs/evidence/package-consumers-2026-09-02.md)を参照してください。UIKit/SwiftUI、AppKit/SwiftUI、Android Views/Compose、Web、Flutter、WinUI 3、WPF の手動ツールは、[実入力受け入れホスト](examples/acceptance/README.md)に別途掲載されています。コンパイルだけではプラットフォームのサポートレベルは上がりません。

アプリケーションへの統合は、[ソースから始める](docs/getting-started.md)を参照してください。ライブエディター、非対話/ASR、表示専用のいずれか適切な経路を選び、安全なポリシー解決を説明し、各プラットフォームアダプターへ案内します。

## ポリシー推奨と ASR

`recommendPolicy(context)` は、信頼度、理由、証拠ソース、`autoApply` フラグとともに `naturalLanguage` または `verbatim` を返します。セキュア/パスワードのコンテキストでは常に `verbatim` が強制されます。セキュア入力以外では明示ポリシーが優先されます。テキストだけのヒューリスティクスは推奨にとどまり、アクティブなエディターを自動的に切り替えません。

`resolvePolicy(context, fallback)` は自動設定用の簡便な経路です。`autoApply=true` の場合だけ推奨を採用し、それ以外では呼び出し側の fallback を返します。fallback のデフォルトは `verbatim` です。ポリシーが省略可能な UI アダプターも `verbatim` をデフォルトとするため、自然言語の空白処理は必ず明示的、または安全な解決を経て有効になります。

`formatTextUpdate(update)` は ASR、音声入力、インポートされたコンテンツ、生成テキストを扱います。interim 仮説は表示用テキストを生成しますが committed value は持たず、final 仮説は永続化できます。[コンテンツポリシーと非対話テキスト v1](spec/content-policy-v1.md)を参照してください。

`OrderedTextUpdateSession` は、プロバイダー非依存の utterance ライフサイクルと単調増加 revision 処理を追加します。アクティブな utterance のイベントだけを受け入れ、重複または古い revision を拒否し、有効な final イベントで閉じます。保持するのはアクティブな utterance ID と最新 revision だけで、文字起こし本文は保持しません。[順序付き ASR と音声入力の更新](docs/ordered-text-updates.md)を参照してください。

## ルール v1 の範囲

ルール v1 は、次の直接境界に限って双方向に U+0020 を挿入します。

- 漢字 ↔ ラテン文字。
- 漢字 ↔ ASCII 数字（`0`–`9`）。

句読点、全角数字、日本語、韓国語、Markdown、ソースコード、リッチテキスト、`contenteditable` に対するルールは追加しません。

## ライセンス

Apache License 2.0。[LICENSE](LICENSE) を参照してください。

現在の実装とプラットフォームサポートは [COMPATIBILITY.md](COMPATIBILITY.md) に記録されています。
プラットフォームの完全な順序と受け入れゲートは [ROADMAP.md](ROADMAP.md) に記録されています。
Unicode 分割の不足は[分割マトリクス](docs/unicode-segmentation-matrix.md)に明記され、実入力の証拠は[プラットフォーム受け入れプロトコル](docs/platform-acceptance.md)に従います。
現在のソース公開ゲートは[公開準備監査](docs/evidence/publication-readiness-2026-09-02.md)に記録されています。
Apple アダプターのホスト証拠は、[macOS](docs/evidence/macos-host-2026-09-02.md) と [iOS Simulator](docs/evidence/ios-simulator-2026-09-02.md) に分けて記録されています。
Flutter SDK の証拠は [Flutter ホストスナップショット](docs/evidence/flutter-host-2026-09-02.md) に記録されています。
