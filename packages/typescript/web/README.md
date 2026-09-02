# Natural Spacing Web

Experimental, dependency-free adapter for native `input` and `textarea` controls. The native binding uses a narrow hybrid strategy: cancellable non-composition typing and paste that require spacing use `beforeinput` plus the browser's undo-preserving insert command; all other edits let the browser edit first and reconcile only the minimal UTF-16 range during `input` propagation.

```ts
import { bindNaturalSpacing } from "@natural-spacing/web";

const input = document.querySelector("input");
if (input) {
  const binding = bindNaturalSpacing(input, { policy: "naturalLanguage" });
  // binding.dispose() when the control is removed.
}
```

The adapter never modifies an active composition. It keeps the last settled value and reconciles after `compositionend`. `input[type=password]` always uses an effective `verbatim` policy, even if `naturalLanguage` was configured. Call `adapter.sync()` when a controlled host renders a programmatic value without a user input event.

For React, the recommended path is to attach `bindNaturalSpacing` to the DOM ref in a layout effect, update controlled state synchronously from React's `onChange`, call `adapter.sync()` after externally rendered values, and dispose the binding on unmount. This preserves the native target listener and its verified undo path without adding React as a package runtime dependency. `createReactTextControlHandlers` remains available as a post-input compatibility surface, but does not carry the native-binding undo evidence.

```tsx
const ref = useRef<HTMLInputElement>(null);
const binding = useRef<BoundNaturalSpacing | null>(null);

useLayoutEffect(() => {
  binding.current = bindNaturalSpacing(ref.current!, { policy: "naturalLanguage" });
  return () => binding.current?.dispose();
}, []);

useLayoutEffect(() => binding.current?.adapter.sync(), [value]);

return <input ref={ref} value={value} onChange={(event) => setValue(event.currentTarget.value)} />;
```

This package is not production-supported. Twelve native/end-to-end scenarios and three React 19.2.8 scenarios currently pass in Chrome 152, Edge 151, Playwright Firefox 153, and Playwright WebKit 26.5, for 60 local browser executions. The end-to-end scenario mounts [`examples/web/app.mjs`](../../../examples/web/app.mjs) and shares resolved policies across live keyboard input, secure input, and ordered ASR. React coverage includes controlled/uncontrolled input, external state reset, and controlled native undo/redo using the DOM-ref binding pattern. Chromium uses the system clipboard path; Firefox/WebKit use a synthetic `paste` then `beforeinput(insertFromPaste)` sequence because Playwright does not expose those clipboard permissions there. These are automated host-browser checks, not evidence for release Safari or a real IME. Release-channel Safari/Firefox, mobile browsers, React composition/paste/concurrency/hydration, composition-commit undo, non-Chromium system clipboard, password-manager/autofill, accessibility input, command fallback, and real IMEs remain acceptance gates. It intentionally supports only plain-text single-selection `input` and `textarea` controls; `contenteditable` and rich text are out of scope.

Run the browser matrix after the normal unit suite:

```sh
npm test
npm run test:browser
```

Local runs use installed branded Chrome and Edge plus Playwright Firefox and WebKit. CI installs Playwright's headless Chromium, Firefox, and WebKit runtimes and runs the same fifteen native/end-to-end and React scenarios in those three engines.

## Display-only CSS

`@natural-spacing/web/display.css` exposes a progressive `.natural-spacing-display` class using `text-autospace: normal` only when the browser recognizes it. Apply the class to prose display containers, never to editable controls. CSS rendering does not change copied or stored text and is therefore a separate capability from the input adapter.

CSS Text Level 4 still describes `text-autospace`, but interoperable browser implementation is not yet an assumption of this package. Unsupported browsers simply ignore the guarded rule.
