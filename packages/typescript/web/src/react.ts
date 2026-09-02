import type { EditPlan } from "@natural-spacing/core";
import {
  NaturalSpacingTextControlAdapter,
  type InputEventState,
  type SupportedTextControl,
} from "./adapter.js";

export interface ReactLikeInputEvent {
  readonly currentTarget: SupportedTextControl;
  readonly nativeEvent: InputEventState;
}

export interface ReactLikeCompositionEvent {
  readonly currentTarget: SupportedTextControl;
}

export interface ReactTextControlHandlerOptions {
  readonly onValueChange?: (value: string, plan: EditPlan | null) => void;
}

/** React-compatible handler shapes without a runtime React dependency. */
export function createReactTextControlHandlers(
  adapter: NaturalSpacingTextControlAdapter,
  options: ReactTextControlHandlerOptions = {},
): {
  onCompositionStart(event: ReactLikeCompositionEvent): void;
  onCompositionEnd(event: ReactLikeCompositionEvent): void;
  onInput(event: ReactLikeInputEvent): void;
} {
  return {
    onCompositionStart() {
      adapter.handleCompositionStart();
    },
    onCompositionEnd(event) {
      const before = event.currentTarget.value;
      const plan = adapter.handleCompositionEnd();
      if (event.currentTarget.value !== before) {
        options.onValueChange?.(event.currentTarget.value, plan);
      }
    },
    onInput(event) {
      const plan = adapter.handleInput(event.nativeEvent);
      options.onValueChange?.(event.currentTarget.value, plan);
    },
  };
}
