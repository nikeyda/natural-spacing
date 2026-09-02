# Windows coordinator evidence — 2026-09-02

This record separates platform-independent C# coordination evidence from native Windows control evidence. No WinUI or WPF control was executed on macOS.

## Environment

- macOS 26.5.2 arm64;
- .NET SDK 10.0.400 and runtime 10.0.11;
- Windows App SDK 2.4.0 for WinUI 3 cross-compilation;
- .NET 10 WindowsDesktop targeting pack for WPF cross-compilation.

## Commands

```sh
dotnet run --project packages/dotnet/NaturalSpacing.Conformance/NaturalSpacing.Conformance.csproj -- .
dotnet build packages/dotnet/NaturalSpacing.WinUI/NaturalSpacing.WinUI.csproj -c Release
dotnet build packages/dotnet/NaturalSpacing.Wpf/NaturalSpacing.Wpf.csproj -c Release
bash scripts/test-windows-winui-acceptance-host.sh
bash scripts/test-windows-wpf-acceptance-host.sh
```

## Results

- C# conformance: 97 shared fixture checks, 4 proposed-edit bridge checks, 5 focused generated-Unicode checks, 7 observed-text coordinator checks, 23 ordered ASR/dictation operations, and 766 Unicode 17 grapheme checks passed;
- WinUI 3 adapter: Release cross-compile passed with zero warnings and zero errors;
- WPF adapter: Release cross-compile passed with zero warnings and zero errors;
- WinUI 3 code-only unpackaged acceptance target: Release cross-compile passed with zero warnings and zero errors through public project references;
- WPF manual acceptance executable: Release cross-compile passed with zero warnings and zero errors through public project references.

Both adapters expose their last settled plan as read-only diagnostic state and clear it when a host synchronizes an external value. The WinUI and WPF acceptance hosts use that state to display the actual coordinator decision rather than inferring it from final text.

`NaturalSpacingObservedTextSession` is used by both adapters and covers:

- Han/ASCII-digit insertion and selection mapping;
- automatic-space deletion suppression;
- external model synchronization and session reset;
- active-composition deferral followed by settled reconciliation;
- `.verbatim` baseline advancement without replacement;
- UTF-16 length-limit fail-open behavior;
- resynchronization after a host rejects the proposed replacement.

## Limits

Cross-platform coordinator checks and the WinUI/WPF acceptance cross-compiles do not execute `DispatcherQueue`, WPF `Dispatcher`, `TextCompositionManager`, WinUI composition events, `TextBox`, binding publication, native selection, undo/redo, Microsoft Pinyin, third-party IMEs, speech input, touch/hardware keyboards, Narrator, paste UI, lifecycle, or supported Windows versions. Those remain mandatory Windows acceptance gates.
