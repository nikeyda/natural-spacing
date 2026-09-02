# NaturalSpacing.Core for .NET

This directory contains the dependency-free C# reference core, its shared-fixture conformance runner, and experimental WinUI 3 and WPF plain-text adapters. They target .NET 10. The Windows adapters have been cross-compiled only and are not production-supported.

## Use the core

```csharp
using NaturalSpacing.Core;

var display = NaturalSpacingFormatter.Normalize(
    "在Windows11发布2个版本",
    FieldPolicy.NaturalLanguage);
// "在 Windows11 发布 2 个版本"

var recommendation = NaturalSpacingPolicy.Recommend(
    new PolicyContext(ContentKind: ContentKind.Prose));
// NaturalLanguage, high confidence, safe to auto-apply

var policy = NaturalSpacingPolicy.Resolve(
    new PolicyContext(ContentKind: ContentKind.SearchQuery));
// Verbatim: the NaturalLanguage recommendation is advisory for search

var interim = NaturalSpacingPolicy.Format(new TextUpdate(
    "今天发布v2版本",
    FieldPolicy.NaturalLanguage,
    TextSource.Asr,
    TextStability.Interim));
// DisplayText is formatted; CommittedText remains null.
```

Secure/password context always resolves to `FieldPolicy.Verbatim`, even when the explicit policy is `NaturalLanguage`. Outside secure input, the explicit policy wins.

For live editors, keep one `NaturalSpacingSession` per field. Feed it settled UTF-16 snapshots only, or use `ProcessProposedEdit` when the host control provides a proposed replacement. Never rewrite an active composition range.

## Run conformance

From the repository root:

```sh
dotnet run \
  --project packages/dotnet/NaturalSpacing.Conformance/NaturalSpacing.Conformance.csproj \
  -- .
```

The runner consumes the same JSON fixtures and pinned Unicode 17 grapheme data as the TypeScript, Swift, Kotlin, and Dart implementations. The generated native segmenter passes all 766 official cases on .NET 10.0.11. Seven additional checks exercise `NaturalSpacingObservedTextSession`: ASCII-digit insertion, deletion suppression, external synchronization, composition deferral/settlement, `.verbatim`, length-limit fail-open, and resynchronization after a host rejects the proposed replacement. These platform-independent results are separate from Windows event-loop, IME, selection, and undo compatibility.

`OrderedTextUpdateSession` provides the same revision, utterance, cancellation, and final-closure contract as the other four cores and passes all 23 shared ordered operations. See [the ordered-update guide](../../docs/ordered-text-updates.md).

## Experimental Windows controls

Both adapters default to `FieldPolicy.Verbatim`. Pass `NaturalLanguage` explicitly as below, or use `NaturalSpacingPolicy.Resolve` for a known semantic content kind.

The adapters support plain-text `TextBox` only. WinUI `PasswordBox` and WPF `PasswordBox` are separate, unsupported control surfaces and must not be routed through these adapters.

WinUI 3:

```csharp
using NaturalSpacing.Core;
using NaturalSpacing.WinUI;

using var spacing = new NaturalSpacingTextBoxAdapter(
    notesTextBox,
    FieldPolicy.NaturalLanguage);
```

WPF:

```csharp
using NaturalSpacing.Core;
using NaturalSpacing.Wpf;

using var spacing = new NaturalSpacingTextBoxAdapter(
    notesTextBox,
    FieldPolicy.NaturalLanguage);
```

Keep the adapter alive for the lifetime of the control and dispose it when the control is retired. If application state intentionally replaces `Text`, call `spacing.Sync()` afterward so the next user edit is compared with the new baseline.

Both adapters use `NaturalSpacingObservedTextSession` for the settled baseline and deletion intent. They defer while an IME composition is active and then apply a minimal `SelectedText` replacement. After applying, they compare the real control value with the planned value and resynchronize if the host rejected or altered the replacement. Both expose the last settled `EditPlan` through read-only `LastPlan` and clear it on `Sync()`; this is diagnostic state, not real-input evidence. They still require real Windows validation for Microsoft Pinyin and representative third-party IMEs, speech input, paste, touch keyboard, selection, data binding, accessibility, undo/redo, and lifecycle behavior.

The code-only WinUI and XAML-based WPF manual hosts under `examples/acceptance`
compile against these public projects. The WinUI host is framework-dependent
and unpackaged; it follows Microsoft's `WindowsPackageType=None` guidance and
requires the matching Windows App SDK runtime on the test machine.
