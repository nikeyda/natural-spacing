import {
  NaturalSpacingSession,
  planProposedEdit,
  proposedEditReplacingDifference,
  type EditKind,
  type EditPlan,
  type FieldPolicy,
  type ProposedEdit,
  type TextSelection,
} from "@natural-spacing/core";

export type SupportedTextControl = HTMLInputElement | HTMLTextAreaElement;

export interface TextControlAdapterOptions {
  readonly policy: FieldPolicy;
  readonly maxLengthUtf16?: number | null;
}

export interface InputEventState {
  readonly isComposing?: boolean;
  readonly inputType?: string;
}

export interface BeforeInputEventState extends InputEventState {
  readonly cancelable?: boolean;
  readonly data?: string | null;
  preventDefault(): void;
}

export class NaturalSpacingTextControlAdapter {
  readonly control: SupportedTextControl;
  policy: FieldPolicy;
  maxLengthUtf16: number | null;
  lastPlan: EditPlan | null = null;

  #session = new NaturalSpacingSession();
  #settledValue: string;
  #isComposing = false;
  #isApplying = false;

  get effectivePolicy(): FieldPolicy {
    return this.control.type === "password" ? "verbatim" : this.policy;
  }

  constructor(control: SupportedTextControl, options: TextControlAdapterOptions) {
    this.control = control;
    this.policy = options.policy;
    this.maxLengthUtf16 = options.maxLengthUtf16 ?? null;
    this.#settledValue = control.value;
  }

  reset(): void {
    this.#session.reset();
    this.#settledValue = this.control.value;
    this.#isComposing = false;
    this.lastPlan = null;
  }

  /** Call after a host-controlled value is rendered without a user input event. */
  sync(): void {
    if (!this.#isComposing && !this.#isApplying) {
      this.#settledValue = this.control.value;
    }
  }

  handleCompositionStart(): void {
    this.#isComposing = true;
  }

  handleCompositionEnd(): EditPlan | null {
    this.#isComposing = false;
    return this.#reconcile();
  }

  /**
   * Preserves the browser undo transaction for cancellable text insertion when
   * the host supports its native insert-text command. Other edits fall through
   * to post-input reconciliation.
   */
  handleBeforeInput(event: BeforeInputEventState): EditPlan | null {
    if (
      this.#isApplying ||
      this.#isComposing ||
      event.isComposing === true ||
      event.cancelable !== true ||
      typeof event.data !== "string" ||
      !isUndoPreservingInputType(event.inputType) ||
      !supportsUndoPreservingInsert(this.control) ||
      this.control.value !== this.#settledValue
    ) {
      return null;
    }

    const edit = proposedEditForBeforeInput(this.control, event, {
      policy: this.effectivePolicy,
      maxLengthUtf16: this.maxLengthUtf16,
    });
    if (edit === null || !planProposedEdit(edit).requiresReplacement) return null;

    const result = this.#session.processProposedEdit(edit);
    this.lastPlan = result.plan;
    this.#isApplying = true;
    try {
      event.preventDefault();

      const start = edit.range.start;
      const end = start + edit.range.length;
      this.control.setSelectionRange(start, end, "forward");
      const applied = executeUndoPreservingInsert(this.control, result.replacementText);
      if (!applied) {
        this.control.setRangeText(result.replacementText, start, end, "end");
        dispatchFallbackInput(this.control, event, result.replacementText);
      }
      setControlSelection(this.control, result.plan.selection);

      this.#settledValue = result.plan.resultText;
      return result.plan;
    } finally {
      this.#isApplying = false;
    }
  }

  handleInput(event: InputEventState = {}): EditPlan | null {
    if (this.#isApplying || this.#isComposing || event.isComposing === true) {
      return null;
    }
    return this.#reconcile(editKindForInputType(event.inputType));
  }

  #reconcile(editKind?: EditKind): EditPlan | null {
    const selection = selectionFromControl(this.control);
    const edit = proposedEditReplacingDifference({
      beforeText: this.#settledValue,
      afterText: this.control.value,
      ...(selection === null ? {} : { selectionAfterEdit: selection }),
      policy: this.effectivePolicy,
      maxLengthUtf16: this.maxLengthUtf16,
    });
    if (edit === null) return null;

    const result = this.#session.processProposedEdit(
      editKind === undefined ? edit : { ...edit, editKind },
    );
    this.lastPlan = result.plan;
    if (!result.requiresReplacement) {
      this.#settledValue = this.control.value;
      return result.plan;
    }

    this.#isApplying = true;
    const currentEnd = edit.range.start + edit.replacementText.length;
    this.control.setRangeText(
      result.replacementText,
      edit.range.start,
      currentEnd,
      "preserve",
    );
    setControlSelection(this.control, result.plan.selection);
    this.#isApplying = false;
    this.#settledValue = result.plan.resultText;
    return result.plan;
  }
}

function editKindForInputType(inputType: string | undefined): EditKind | undefined {
  if (inputType === undefined) return undefined;
  if (inputType.startsWith("delete")) return "delete";
  if (inputType === "insertFromPaste" || inputType === "insertFromDrop") return "paste";
  if (inputType.startsWith("insert")) return "insert";
  return undefined;
}

function isUndoPreservingInputType(inputType: string | undefined): boolean {
  return inputType === "insertText" || inputType === "insertFromPaste";
}

function proposedEditForBeforeInput(
  control: SupportedTextControl,
  event: BeforeInputEventState,
  options: TextControlAdapterOptions,
): ProposedEdit | null {
  const selection = selectionFromControl(control);
  if (selection === null || typeof event.data !== "string") return null;
  const start = Math.min(selection.anchor, selection.focus);
  const end = Math.max(selection.anchor, selection.focus);
  const caret = start + event.data.length;
  return {
    text: control.value,
    range: { start, length: end - start },
    replacementText: event.data,
    composingRange: null,
    selectionAfterEdit: { anchor: caret, focus: caret },
    editKind: event.inputType === "insertFromPaste" ? "paste" : "insert",
    policy: options.policy,
    maxLengthUtf16: options.maxLengthUtf16 ?? null,
  };
}

function supportsUndoPreservingInsert(control: SupportedTextControl): boolean {
  const document = control.ownerDocument;
  return (
    typeof document?.execCommand === "function" &&
    (typeof document.queryCommandSupported !== "function" ||
      document.queryCommandSupported("insertText"))
  );
}

function executeUndoPreservingInsert(
  control: SupportedTextControl,
  replacementText: string,
): boolean {
  try {
    return control.ownerDocument.execCommand("insertText", false, replacementText);
  } catch {
    return false;
  }
}

function dispatchFallbackInput(
  control: SupportedTextControl,
  source: BeforeInputEventState,
  data: string,
): void {
  const InputEventConstructor = control.ownerDocument.defaultView?.InputEvent;
  const event = InputEventConstructor === undefined
    ? new Event("input", { bubbles: true })
    : new InputEventConstructor("input", {
        bubbles: true,
        data,
        ...(source.inputType === undefined ? {} : { inputType: source.inputType }),
      });
  control.dispatchEvent(event);
}

function selectionFromControl(control: SupportedTextControl): TextSelection | null {
  const { selectionStart, selectionEnd, selectionDirection } = control;
  if (selectionStart === null || selectionEnd === null) return null;
  return selectionDirection === "backward"
    ? { anchor: selectionEnd, focus: selectionStart }
    : { anchor: selectionStart, focus: selectionEnd };
}

function setControlSelection(
  control: SupportedTextControl,
  selection: TextSelection,
): void {
  const start = Math.min(selection.anchor, selection.focus);
  const end = Math.max(selection.anchor, selection.focus);
  const direction = selection.anchor > selection.focus ? "backward" : "forward";
  control.setSelectionRange(start, end, direction);
}
