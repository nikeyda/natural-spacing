# Android Views and Compose real-input acceptance host

This source-only Android application exercises the public core policy resolver
plus both Android Views and value-based Jetpack Compose adapters. Each surface
contains a natural-language message editor and a password editor deliberately
requesting `NATURAL_LANGUAGE`; the latter must resolve or remain effectively
`VERBATIM`.

Lint and build without installing or launching:

```sh
bash scripts/test-android-acceptance-host.sh
```

The Debug APK is produced under
`examples/acceptance/android/app/build/outputs/apk/debug`. Installing or
launching it is a separate action and is not part of the build command.

Use only synthetic text. Record the device, Android/API version, exact
keyboard/IME/voice/accessibility input version, repository revision, and each
attempted scenario from `docs/platform-acceptance.md`. Both surfaces show the
resolved policy, composing range, selection, last settled decision, and current
synthetic message text. Compose also shows the recommendation confidence and
reason. Password diagnostics never render the value.

At minimum, exercise Han/Latin and Han/ASCII-digit boundaries in both
directions, active composition and commit, automatic-space deletion
suppression, selection replacement, paste, undo/back, focus/lifecycle reset,
hardware keyboard, voice input, autofill, and TalkBack. Record unexecuted rows
as `not run`; an APK build alone is only compile evidence.
