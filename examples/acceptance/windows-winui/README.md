# Windows WinUI 3 real-input acceptance host

This framework-dependent, unpackaged application uses public project
references to the .NET core and WinUI 3 adapter. It provides natural-language
and `verbatim` `TextBox` controls with visible composition, selection,
last-decision, and current synthetic-text status.

The UI is code-only so non-Windows CI can validate the C# and WinUI API surface
without executing the Windows-only XAML compiler. Runtime acceptance remains
Windows-only.

Build without launching:

```sh
bash scripts/test-windows-winui-acceptance-host.sh
```

`WindowsPackageType=None` follows Microsoft's unpackaged WinUI guidance. The
result requires the matching Windows App SDK runtime on the Windows test host;
this project does not claim a self-contained or single-file distribution.

A successful build is only compile evidence. On Windows, use only synthetic
text and record the Windows build, hardware or VM, exact keyboard/IME/input
source, repository revision, and each scenario from
`docs/platform-acceptance.md`. Microsoft Pinyin, third-party IMEs, speech,
Narrator, touch/hardware keyboards, paste, binding, undo, and lifecycle remain
`not run` until executed and recorded.
