# Windows WPF real-input acceptance host

This executable uses public project references to the .NET core and WPF
adapter. It provides a natural-language message `TextBox` and a structured
`verbatim` `TextBox`, with visible composition, selection, last-decision, and
current synthetic-text status.

Cross-compile without launching:

```sh
bash scripts/test-windows-wpf-acceptance-host.sh
```

The command produces a Release Windows executable but does not run it. A
successful cross-compile is only compile evidence; it does not prove WPF event
ordering, Microsoft Pinyin, speech input, Narrator, touch keyboard, hardware
keyboard, paste, binding, or undo behavior.

On Windows, use only synthetic text and record the Windows build, hardware or
VM, exact keyboard/IME/input-source version, repository revision, and each
scenario from `docs/platform-acceptance.md`. Record unexecuted rows as
`not run`.
