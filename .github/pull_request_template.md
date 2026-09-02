## Summary

Describe the behavior changed and the user-visible reason for it.

## Scope

- Affected core, adapter, or documentation:
- Related specification fixture or ADR:
- Out-of-scope platforms or input sources:

## Evidence

Select only evidence actually produced by this change. See
`docs/platform-acceptance.md` for the proof levels.

- [ ] Core conformance
- [ ] Adapter compile
- [ ] Automated host or browser
- [ ] Real input on a named OS/device and input source
- [ ] Not applicable; documentation or repository-only change

Commands and results:

```text

```

## Input safety

- [ ] Active IME composition is not rewritten, or this change does not touch editing behavior.
- [ ] Secure/password input remains `verbatim`, or this change does not touch policy resolution.
- [ ] Selection, deletion suppression, undo, lifecycle reset, and host-owned value synchronization were considered where applicable.
- [ ] Tests and evidence use only synthetic text and contain no private input, audio, credentials, or proprietary logs.

## Compatibility

- [ ] `COMPATIBILITY.md` or the relevant evidence record is updated when support claims or known gaps change.
- [ ] Generated Unicode artifacts are updated and checked when classification or segmentation changes.
