# Natural Spacing

[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

> 源码 Alpha 阶段。项目目前有意关闭所有包注册表发布。

Natural Spacing 是一个规范优先的工具集，用于在汉字与拉丁字母、汉字与 ASCII 数字的边界处添加可预测的空格，同时不破坏 IME 组合输入、选区、删除意图或原生撤销行为。它既适用于交互式输入，也适用于 ASR、听写、导入内容和生成文本等非交互式文本。

## 使用前后

启用 `naturalLanguage` 策略后：

```diff
- 在GitHub发布2个项目
+ 在 GitHub 发布 2 个项目
```

| 使用前 | 使用后 |
| --- | --- |
| `支持macOS和Windows11系统` | `支持 macOS 和 Windows11 系统` |
| `今天发布v2版本` | `今天发布 v2 版本` |

格式化器只在汉字与拉丁字母、汉字与 ASCII 数字直接相邻的边界处插入空格。已有空格、标点、`React18` 这样的拉丁字母与数字组合，以及使用 `verbatim` 策略的字段都保持不变。实时编辑器适配层旨在产生同样的可见结果，同时保护 IME 组合输入、选区、删除意图和原生撤销行为；当前实验性支持等级见下文。

## 当前状态

规则 v1、私有的 TypeScript/Swift/Kotlin/C#/Dart 参考核心，以及实验性的 UIKit/AppKit/SwiftUI/Web/Android Views/Jetpack Compose/WinUI/WPF/Flutter 桥接层均已实现。项目目前尚不包含生产级平台适配器。所有现有平台桥接层在通过真实输入验收矩阵之前，均保持实验性状态。

当前里程碑包括：

- 规则 v1；
- 与编程语言无关的编辑契约；
- 固定版本的 Unicode 17.0 源元数据、官方字素测试数据，以及生成的语言无关分类与分段产物；
- 共享的规则和输入会话 fixtures；
- 零依赖的规范校验器；
- 使用确定性 Unicode 17 字素分段与分类的 TypeScript 核心和会话协调器；
- 仅依赖 Foundation 的 Swift 核心、Kotlin/JVM 核心、零依赖的 .NET 10 C# 核心，以及零依赖的 Dart 3.13 核心，它们使用相同的 Unicode 17 分类与分段生成数据；
- 实验性的 WinUI 3 和 WPF `TextBox` 适配器，共用可进行宿主测试的文本稳定态协调器；
- 经过 SDK 验证的实验性 Flutter `TextInputFormatter` 包，以及独立的路径依赖消费者；
- 实验性的 Android Views `EditText` 适配器；
- 实验性的有状态 Jetpack Compose `TextFieldValue` 适配器；
- 实验性的单选区 UIKit 和 AppKit 适配器；
- 基于上述原生适配器构建的实验性 iOS/macOS SwiftUI 文本编辑器封装；
- 面向 UIKit 控件和 SwiftUI binding 发布行为的 iPhone Simulator XCTest 覆盖；
- 面向 `NSTextView`、`NSTextField` field editor、原生撤销/通知和 SwiftUI binding 发布行为的 macOS 宿主 XCTest 覆盖；
- 实验性的纯文本 Web 及 React 兼容适配器；
- Playwright 覆盖本地 Chrome、Edge、Firefox 和 WebKit 引擎中的 12 个原生/端到端 `input`/`textarea` 场景，包括密码输入的安全降级，以及共享键盘、安全输入和 ASR 策略的演示；
- React 19.2.8 的受控、非受控、外部重置和撤销/重做行为，覆盖上述四种引擎；
- 渐进增强、仅影响显示的 `text-autospace` 样式表；
- 可解释的策略推荐，以及 interim/final 文本更新 API；
- 跨语言的安全策略解析：只自动采用 `autoApply` 推荐，否则回退到 `verbatim`；
- TypeScript、Swift、Kotlin、C# 和 Dart 中与提供商无关的有序 ASR/听写会话，共享生命周期与 revision fixtures，且不保留转写文本；
- 已测试的、与提供商无关的 ASR 示例，覆盖完整假设、明确的仅追加 delta、有序 revision、取消、final 关闭和 utterance 隔离；
- 隔离的 npm tarball、根 SwiftPM、Kotlin composite build、.NET ProjectReference、Dart 路径依赖和 Flutter 路径依赖消费者，用于导入并调用公共 API。

## 设计原则

- 字段必须显式选择 `naturalLanguage`；默认策略为 `verbatim`。
- 绝不改写活跃的 IME 组合输入范围。
- 尊重用户删除自动插入空格的决定。
- 将自动修改表达为小型插入 patch，并通过 patch 映射选区。
- 规则语义保存在规范和 fixtures 中，不让某一种语言实现成为唯一真值源。
- 静态 CSS 间距与持久化的输入内容相互独立。
- 只根据显式配置或语义上下文解析一次策略；绝不只凭文本启发式判断，在编辑过程中切换活跃编辑器的策略。

## 仓库结构

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

## 验证规范

Node.js 20 或更高版本足以运行规范校验和 TypeScript 一致性测试。TypeScript 规则不再依赖宿主运行时的 Unicode 版本。

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

校验器会检查 Git 候选文件集合中被禁止的构建、缓存及凭证路径，常见密钥模式，用户主目录绝对路径和失效的相对 Markdown 链接。它还会检查 JSON 语法、fixture 必填字段、唯一标识符、UTF-16 范围、预期选区边界、固定版本的 Unicode 源元数据，以及生成的分类与分段范围。`npm test` 还会根据语言无关产物检查五种语言的分类表和四种原生语言的分段表，构建 TypeScript 核心，并运行规则、会话、Web 和 ASR 测试。所有核心测试套件都会运行同一组固定版本的 766 个官方字素用例。生成方式见 [Unicode 数据工作流](spec/unicode/README.md)。

仓库包含一个只读的 GitHub Actions 工作流，覆盖 TypeScript/Web/ASR、Playwright Chromium/Firefox/WebKit 矩阵、Swift/UIKit/AppKit/SwiftUI、Kotlin/JVM、C#/.NET、Dart/Flutter 以及 Windows 适配器编译。本地浏览器自动化目前覆盖品牌版 Chrome 152、Edge 151、Playwright Firefox 153 和 Playwright WebKit 26.5 中的 12 个原生/端到端场景，以及 3 个 React 19 场景，共 60 次浏览器执行；其中包括单事务原生撤销/重做、密码输入安全降级，以及一个在键盘、安全输入和有序 ASR 路径间共享解析策略的可执行演示。CI 在三种托管引擎中运行相同的 15 个场景。自动化通过并不能证明正式版 Safari/Firefox、真实 IME、听写路径、辅助输入源或设备矩阵已经通过验收。

包消费者 smoke test 与一致性测试有意分离。它们验证打包后的 npm tarball 能离线安装和导入，仓库根目录是一个有效的 SwiftPM 依赖并公开四个 Apple product，以及独立 Kotlin、.NET、Dart 和 Flutter 项目能通过源码依赖导入核心或适配器。它们不授权注册表发布，也不能证明带 tag 的远程 Git、Maven、NuGet 或 pub 依赖可用。请从[源码消费者示例](examples/consumers/README.md)开始，并参阅[消费者证据快照](docs/evidence/package-consumers-2026-09-02.md)了解准确结果和限制。UIKit/SwiftUI、AppKit/SwiftUI、Android Views/Compose、Web、Flutter、WinUI 3 和 WPF 的手动工具单独收录在[真实输入验收宿主](examples/acceptance/README.md)中；仅仅完成编译不会提升对应平台的支持等级。

应用接入请从[从源码开始](docs/getting-started.md)入手。它会帮助选择正确的实时编辑器、非交互式/ASR 或仅显示路径，说明安全策略解析方式，并链接各平台适配器。

## 策略推荐与 ASR

`recommendPolicy(context)` 返回 `naturalLanguage` 或 `verbatim`，并附带置信度、原因、证据来源和 `autoApply` 标记。安全/密码上下文始终强制使用 `verbatim`；在安全输入之外，显式策略优先。纯文本启发式结果只作为建议，绝不会自动切换活跃编辑器。

`resolvePolicy(context, fallback)` 是用于自动配置的便捷入口。只有在 `autoApply=true` 时才采用推荐策略；否则返回调用方提供的 fallback，默认值为 `verbatim`。策略为可选参数的 UI 适配器同样默认使用 `verbatim`，因此自然语言间距始终需要显式启用或经过安全解析后启用。

`formatTextUpdate(update)` 支持 ASR、听写、导入内容和生成文本。Interim 假设会生成显示文本，但不产生 committed value；final 假设可以持久化。参阅[内容策略与非交互式文本 v1](spec/content-policy-v1.md)。

`OrderedTextUpdateSession` 增加了与提供商无关的 utterance 生命周期和单调递增 revision 处理。它只接受活跃 utterance 的事件，拒绝重复或过期 revision，在有效 final 事件后关闭，并且只保留活跃 utterance ID 和最新 revision，不保留转写文本。参阅[有序 ASR 与听写更新](docs/ordered-text-updates.md)。

## 规则 v1 的范围

规则 v1 仅在以下直接边界处双向插入 U+0020：

- 汉字 ↔ 拉丁字母；
- 汉字 ↔ ASCII 数字（`0`–`9`）。

它不会为标点、全角数字、日文、韩文、Markdown、源代码、富文本或 `contenteditable` 添加规则。

## 许可证

Apache License 2.0。参阅 [LICENSE](LICENSE)。

当前实现与平台支持情况记录在 [COMPATIBILITY.md](COMPATIBILITY.md) 中。
完整的平台顺序和验收门槛记录在 [ROADMAP.md](ROADMAP.md) 中。
Unicode 分段缺口明确记录在[分段矩阵](docs/unicode-segmentation-matrix.md)中，真实输入证据遵循[平台验收协议](docs/platform-acceptance.md)。
当前源码发布门槛记录在[发布就绪审计](docs/evidence/publication-readiness-2026-09-02.md)中。
Apple 适配器宿主证据分别记录在 [macOS](docs/evidence/macos-host-2026-09-02.md) 和 [iOS Simulator](docs/evidence/ios-simulator-2026-09-02.md) 文档中。
Flutter SDK 证据记录在 [Flutter 宿主快照](docs/evidence/flutter-host-2026-09-02.md)中。
