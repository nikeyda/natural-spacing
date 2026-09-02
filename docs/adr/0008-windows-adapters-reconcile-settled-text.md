# ADR 0008: Windows adapters reconcile only settled text

- Status: Accepted for experimental adapters
- Date: 2026-09-02

## Context

WinUI 3 `TextBox` exposes explicit `TextCompositionStarted`, `TextCompositionChanged`, and `TextCompositionEnded` events. WPF exposes composition start, update, and completed input through `TextCompositionManager`. Both controls also expose UTF-16 selection offsets and a writable `SelectedText` surface.

Rewriting the whole `Text` value during composition can disrupt the candidate window, selection, data binding, and native undo behavior. Treating every `TextChanged` callback as final also loses the user's intent when an automatically inserted space is deleted.

## Decision

- Keep one shared, platform-independent `NaturalSpacingObservedTextSession` per control; it owns the `NaturalSpacingSession` deletion intent and settled-text baseline.
- Mark WinUI input as composing between composition-started and composition-ended events.
- Mark WPF input as composing between `PreviewTextInputStart` and completed `PreviewTextInput` events.
- Ignore intermediate text changes and enqueue reconciliation after composition has settled.
- Derive the user's minimal UTF-16 replacement from the previous settled value and the current control value.
- Apply only the minimal normalization difference through `Select` plus `SelectedText`; never assign the entire field merely to add spaces.
- Compare the control's value with the plan after applying; if the host rejects or changes the replacement, resynchronize the coordinator to the actual value.
- Preserve the control selection through the shared edit plan.
- Require callers to invoke `Sync()` after an intentional external model replacement.

The WinUI class library pins the stable top-level `Microsoft.WindowsAppSDK` 2.4.0 package. It disables PRI generation because the adapter library contains no XAML or resources; API compilation remains enabled.

## Consequences

The bridge is small, composition-aware, and shares the same deletion-suppression contract as the other cores. Seven cross-platform checks exercise the observed-text coordinator without pretending to execute a Windows control, including recovery after a rejected host replacement. A macOS host can restore the official reference packages and compile both Windows adapters.

Cross-compilation cannot establish actual Windows event ordering, IME cancellation behavior, data-binding publication count, accessibility input, or undo grouping. The adapters remain experimental until those behaviors pass on supported Windows versions.

## Sources

- [WinUI `TextBox`](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.textbox)
- [WPF `TextCompositionManager`](https://learn.microsoft.com/en-us/dotnet/api/system.windows.input.textcompositionmanager)
- [Microsoft.WindowsAppSDK 2.4.0](https://www.nuget.org/packages/Microsoft.WindowsAppSDK/2.4.0)
