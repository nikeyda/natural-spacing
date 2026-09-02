# Web manual acceptance host

This native HTML host imports `@natural-spacing/core` and
`@natural-spacing/web` from their local build outputs. It exposes:

- a message input resolved to `naturalLanguage`;
- a password input safely resolved to `verbatim`;
- configured/effective policy, current selection, composition state, last plan
  decision, and last browser input event diagnostics;
- ordered interim/final ASR text handling;
- a separate display-only `text-autospace` example.

Password diagnostics never render the input value. Use synthetic input only.

## Run locally

Build the packages, then serve the repository root over HTTP:

```sh
npm ci
npm run build:core
npm run build:web
python3 -m http.server 8000
```

Open `http://localhost:8000/examples/web/`. Starting the server and opening a
browser are separate from the automated build and test commands.

## Automated browser gate

```sh
npm run test:browser
```

The managed browser matrix does not substitute for release-browser, real IME,
mobile keyboard, system clipboard, password manager, screen reader, or actual
undo/redo acceptance. Record those results according to
[`docs/platform-acceptance.md`](../../docs/platform-acceptance.md).
