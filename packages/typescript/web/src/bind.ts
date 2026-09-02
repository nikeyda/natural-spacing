import {
  NaturalSpacingTextControlAdapter,
  type SupportedTextControl,
  type TextControlAdapterOptions,
} from "./adapter.js";

export interface BoundNaturalSpacing {
  readonly adapter: NaturalSpacingTextControlAdapter;
  dispose(): void;
}

export function bindNaturalSpacing(
  control: SupportedTextControl,
  options: TextControlAdapterOptions,
): BoundNaturalSpacing {
  const adapter = new NaturalSpacingTextControlAdapter(control, options);
  const compositionStart = () => adapter.handleCompositionStart();
  const compositionEnd = () => adapter.handleCompositionEnd();
  const beforeInput = (event: Event) => adapter.handleBeforeInput(event as InputEvent);
  const input = (event: Event) => adapter.handleInput(event as InputEvent);

  control.addEventListener("compositionstart", compositionStart);
  control.addEventListener("compositionend", compositionEnd);
  control.addEventListener("beforeinput", beforeInput);
  control.addEventListener("input", input);

  return {
    adapter,
    dispose() {
      control.removeEventListener("compositionstart", compositionStart);
      control.removeEventListener("compositionend", compositionEnd);
      control.removeEventListener("beforeinput", beforeInput);
      control.removeEventListener("input", input);
    },
  };
}
