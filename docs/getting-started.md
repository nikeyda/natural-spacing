# Getting started from source

Natural Spacing is currently a source alpha. Package registry publication and
tagged Git dependencies are intentionally disabled, so integrate it from a
pinned checkout and keep the dependency private to your application until a
public release is approved.

## Choose the integration path

| Text path | Use | Do not use |
|---|---|---|
| Live plain-text editor | The platform adapter or one core session per editor | Whole-string normalization on every keystroke |
| ASR, dictation, imported, or generated text | The non-interactive text-update API | An editor adapter with synthetic key events |
| Display-only Web prose | The progressive `text-autospace` CSS helper | CSS when stored or copied text must contain spaces |
| Code, URL, email, password, token, path, command, or numeric field | `verbatim` | Natural-language spacing |

Rules v1 inserts U+0020 only at Han–Latin and Han–ASCII-digit boundaries. It
does not reformat punctuation, Markdown, rich text, Japanese, or Korean.

## Resolve policy before editing starts

Every implementation exposes the same two-policy model:

- `naturalLanguage` opts a field or text stream into spacing.
- `verbatim` preserves content and is the default.

Secure/password safety is absolute and forces `verbatim`, even if a caller also
passes an explicit `naturalLanguage` policy. Outside secure input, explicit
policy and a known semantic content kind are high-confidence and may be applied
automatically. Search-query and text-only heuristics are advisory. The resolver
therefore uses `verbatim` unless the recommendation has `autoApply=true`.

Resolve the policy once when an editor or utterance is created. Do not switch
an active editor based on partial text.

TypeScript:

```ts
import { resolvePolicy } from "@natural-spacing/core";

const policy = resolvePolicy({ contentKind: "message" });
// "naturalLanguage"
```

Swift:

```swift
import NaturalSpacingCore

let policy = NaturalSpacing.resolvePolicy(
    PolicyContext(contentKind: .message)
)
```

Kotlin:

```kotlin
import dev.naturalspacing.core.ContentKind
import dev.naturalspacing.core.PolicyContext
import dev.naturalspacing.core.resolvePolicy

val policy = resolvePolicy(PolicyContext(contentKind = ContentKind.MESSAGE))
```

C#:

```csharp
using NaturalSpacing.Core;

var policy = NaturalSpacingPolicy.Resolve(
    new PolicyContext(ContentKind: ContentKind.Message));
```

Dart and Flutter:

```dart
import 'package:natural_spacing/natural_spacing.dart';

final policy = NaturalSpacingPolicy.resolve(
  const PolicyContext(contentKind: ContentKind.message),
);
```

Use `recommendPolicy`/`Recommend`/`recommend` when the product needs to explain
the recommendation or ask the user before adopting an advisory result. The
normative behavior is defined in [Content Policy and Non-interactive Text
v1](../spec/content-policy-v1.md).

### Secure controls

Always pass secure semantics to the resolver and omit the field value. Three
live-input adapters also enforce a control-level fail-safe if configuration is
wrong: Web recognizes `input[type=password]`, UIKit recognizes
`isSecureTextEntry`, and Android Views recognizes password `inputType` values
and `PasswordTransformationMethod`. Their effective policy becomes `verbatim`
without changing the configured policy object.

Do not infer broader coverage from those checks. The AppKit field-editor and
Flutter `TextInputFormatter` APIs do not reliably expose their host field's
secure semantics to these adapters, so resolve `verbatim` before constructing
them and do not attach them to password controls. WinUI and WPF password entry
uses controls other than the supported plain-text `TextBox`; those password
controls are outside the current adapter surface.

## Consume the source packages

The checked examples are the executable installation documentation for the
current alpha:

| Ecosystem | Source dependency | Checked consumer |
|---|---|---|
| npm | Offline tarballs produced from the Core and Web workspaces | [`scripts/test-npm-consumer.mjs`](../scripts/test-npm-consumer.mjs) |
| SwiftPM | Repository-root package path | [`examples/consumers/swift`](../examples/consumers/swift) |
| Kotlin/JVM | Gradle composite build with dependency substitution | [`examples/consumers/kotlin`](../examples/consumers/kotlin) |
| .NET | `ProjectReference` to `NaturalSpacing.Core` | [`examples/consumers/dotnet`](../examples/consumers/dotnet) |
| Dart | `path` dependency on `packages/dart` | [`examples/consumers/dart`](../examples/consumers/dart) |
| Flutter | `path` dependencies on the Flutter adapter and Dart core | [`examples/consumers/flutter`](../examples/consumers/flutter) |

Run all applicable consumer checks from the repository root. The exact commands
and what each check proves are in [Source consumer
examples](../examples/consumers/README.md).

For one executable integration rather than separate snippets, open
[`examples/web/index.html`](../examples/web/index.html) from a local server after
building Core and Web. Its [`app.mjs`](../examples/web/app.mjs) resolves one
message context, one intentionally conflicting secure context, and one ASR
transcript context; it then wires live keyboard input, password preservation,
and ordered interim/final ASR output. The same module is bundled into the
Playwright matrix and passes in all four local engines.

## Connect a live editor

Keep one stateful adapter or session per editor. Its state preserves deletion
intent: if a user removes an automatically inserted space, the same session does
not immediately restore it.

- Web and React: [`packages/typescript/web/README.md`](../packages/typescript/web/README.md)
- UIKit, AppKit, and SwiftUI: [`packages/swift/README.md`](../packages/swift/README.md)
- Android Views and Jetpack Compose: [`packages/kotlin/README.md`](../packages/kotlin/README.md)
- WinUI 3 and WPF: [`packages/dotnet/README.md`](../packages/dotnet/README.md)
- Flutter: [`packages/flutter/README.md`](../packages/flutter/README.md)

For every host:

1. Resolve or explicitly choose the policy before editing begins.
2. Keep composition text unchanged while the IME has an active composing range.
3. Let application validation and length limiting run in the documented order.
4. Preserve the adapter instance for the editor's lifetime.
5. Call the adapter's `sync` or `reset` operation after replacing the document
   programmatically, as documented by that platform.
6. Dispose or detach bindings when the control is retired.

Host builds and automated control tests are not real keyboard, IME, dictation,
accessibility, or device acceptance. Use the [platform acceptance
protocol](platform-acceptance.md) before claiming production support.

## Format ASR and other non-interactive updates

The text-update API returns both a display value and an optional committed
value. Interim hypotheses may be shown but have no committed value. A final
hypothesis returns the normalized value for persistence.

TypeScript:

```ts
import { formatTextUpdate, resolvePolicy } from "@natural-spacing/core";

const policy = resolvePolicy({ contentKind: "asrTranscript" });
const result = formatTextUpdate({
  text: "今天发布v2版本",
  policy,
  source: "asr",
  stability: "interim",
});

render(result.displayText);
if (result.committedText !== null) persist(result.committedText);
```

Swift:

```swift
import NaturalSpacingCore

let policy = NaturalSpacing.resolvePolicy(
    PolicyContext(contentKind: .asrTranscript)
)
let result = NaturalSpacing.formatTextUpdate(TextUpdate(
    text: "今天发布v2版本",
    policy: policy,
    source: .asr,
    stability: .interim
))
```

Kotlin:

```kotlin
import dev.naturalspacing.core.*

val policy = resolvePolicy(PolicyContext(contentKind = ContentKind.ASR_TRANSCRIPT))
val result = formatTextUpdate(TextUpdate(
    text = "今天发布v2版本",
    policy = policy,
    source = TextSource.ASR,
    stability = TextStability.INTERIM,
))
```

C#:

```csharp
using NaturalSpacing.Core;

var policy = NaturalSpacingPolicy.Resolve(
    new PolicyContext(ContentKind: ContentKind.AsrTranscript));
var result = NaturalSpacingPolicy.Format(new TextUpdate(
    "今天发布v2版本",
    policy,
    TextSource.Asr,
    TextStability.Interim));
```

Dart and Flutter:

```dart
import 'package:natural_spacing/natural_spacing.dart';

final policy = NaturalSpacingPolicy.resolve(
  const PolicyContext(contentKind: ContentKind.asrTranscript),
);
final result = NaturalSpacingPolicy.format(TextUpdate(
  text: '今天发布v2版本',
  policy: policy,
  source: TextSource.asr,
  stability: TextStability.interim,
));
```

Change the stability to `final`, `FINAL`, `Final`, or `finalValue` for the
language in use before reading and persisting `committedText`. For streaming
providers, use `OrderedTextUpdateSession` to enforce utterance identity,
monotonically increasing revisions, cancellation, and final closure. The same
public API is available in TypeScript, Swift, Kotlin, C#, and Dart/Flutter and
is documented in [Ordered ASR and dictation updates](ordered-text-updates.md).
Append-only deltas are safe only when the provider explicitly guarantees that
contract. The tested [provider-neutral ASR
example](../examples/asr/provider-neutral.mjs) also demonstrates that narrower
adapter.

## Before shipping

- Run the shared conformance suite and the consumer check for your ecosystem.
- Run the relevant host adapter suite.
- Execute the real-input matrix for the target OS, keyboard/IME, dictation,
  paste, selection, undo/redo, accessibility input, and lifecycle behavior.
- Keep unsupported rich-text and multi-selection surfaces in `verbatim` mode.
- Check [the compatibility matrix](../COMPATIBILITY.md) for the current proof
  level instead of inferring support from a successful compile.
