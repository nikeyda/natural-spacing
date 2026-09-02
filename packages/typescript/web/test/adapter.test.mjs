import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  NaturalSpacingTextControlAdapter,
  bindNaturalSpacing,
  createReactTextControlHandlers,
} from "../dist/index.js";

test("input reconciliation changes only the edited fragment", () => {
  const control = new FakeTextControl("中文");
  const adapter = new NaturalSpacingTextControlAdapter(control, {
    policy: "naturalLanguage",
  });

  control.nativeEdit("中2文", 2);
  const plan = adapter.handleInput({ inputType: "insertText" });

  assert.equal(control.value, "中 2 文");
  assert.equal(control.selectionStart, 4);
  assert.equal(control.selectionEnd, 4);
  assert.equal(plan?.decision, "applied");
  assert.deepEqual(control.replacements, [{ replacement: " 2 ", start: 1, end: 2 }]);
});

test("composition is untouched until it settles", () => {
  const control = new FakeTextControl("中");
  const adapter = new NaturalSpacingTextControlAdapter(control, {
    policy: "naturalLanguage",
  });

  adapter.handleCompositionStart();
  control.nativeEdit("中A", 2);
  assert.equal(adapter.handleInput({ isComposing: true }), null);
  assert.equal(control.value, "中A");

  const plan = adapter.handleCompositionEnd();
  assert.equal(control.value, "中 A");
  assert.equal(control.selectionStart, 3);
  assert.equal(plan?.decision, "applied");
});

test("deleting an automatic space remains suppressed", () => {
  const control = new FakeTextControl("中 A");
  const adapter = new NaturalSpacingTextControlAdapter(control, {
    policy: "naturalLanguage",
  });

  control.nativeEdit("中A", 1);
  const plan = adapter.handleInput({ inputType: "deleteContentBackward" });

  assert.equal(control.value, "中A");
  assert.equal(plan?.decision, "suppressed");
  assert.equal(control.replacements.length, 0);
});

test("length limits fail open to the native value", () => {
  const control = new FakeTextControl("中");
  const adapter = new NaturalSpacingTextControlAdapter(control, {
    policy: "naturalLanguage",
    maxLengthUtf16: 2,
  });

  control.nativeEdit("中A", 2);
  const plan = adapter.handleInput({ inputType: "insertText" });

  assert.equal(control.value, "中A");
  assert.equal(plan?.decision, "lengthLimited");
});

test("password inputs force verbatim even when natural language is configured", () => {
  const control = new FakeTextControl("中");
  control.type = "password";
  const adapter = new NaturalSpacingTextControlAdapter(control, {
    policy: "naturalLanguage",
  });

  control.nativeEdit("中A", 2);
  const plan = adapter.handleInput({ inputType: "insertText" });

  assert.equal(control.value, "中A");
  assert.equal(plan?.decision, "verbatim");
  assert.equal(adapter.policy, "naturalLanguage");
  assert.equal(adapter.effectivePolicy, "verbatim");
});

test("backward selection direction survives insertion mapping", () => {
  const control = new FakeTextControl("中文");
  const adapter = new NaturalSpacingTextControlAdapter(control, {
    policy: "naturalLanguage",
  });

  control.value = "中A文";
  control.setSelectionRange(1, 2, "backward");
  adapter.handleInput({ inputType: "insertText" });

  assert.equal(control.value, "中 A 文");
  assert.equal(control.selectionDirection, "backward");
  assert.equal(control.selectionStart, 2);
  assert.equal(control.selectionEnd, 4);
});

test("React-compatible handlers publish the transformed value", () => {
  const control = new FakeTextControl("中");
  const adapter = new NaturalSpacingTextControlAdapter(control, {
    policy: "naturalLanguage",
  });
  const values = [];
  const handlers = createReactTextControlHandlers(adapter, {
    onValueChange(value, plan) {
      values.push([value, plan?.decision ?? null]);
    },
  });

  control.nativeEdit("中A", 2);
  handlers.onInput({
    currentTarget: control,
    nativeEvent: { inputType: "insertText" },
  });

  assert.deepEqual(values, [["中 A", "applied"]]);
});

test("native binding uses cancellable beforeinput for an undo-preserving insertion", () => {
  const control = new FakeTextControl("中");
  bindNaturalSpacing(control, { policy: "naturalLanguage" });

  const event = beforeInputEvent("insertText", "A");
  control.dispatchEvent(event);

  assert.equal(event.defaultPrevented, true);
  assert.equal(control.value, "中 A");
  assert.equal(control.selectionStart, 3);
  assert.deepEqual(control.commands, [{ command: "insertText", value: " A" }]);
});

test("beforeinput fallback does not lose text when the editing command fails", () => {
  const control = new FakeTextControl("中");
  control.ownerDocument.execCommand = () => false;
  let inputEvents = 0;
  control.addEventListener("input", () => inputEvents += 1);
  bindNaturalSpacing(control, { policy: "naturalLanguage" });

  const event = beforeInputEvent("insertText", "A");
  control.dispatchEvent(event);

  assert.equal(event.defaultPrevented, true);
  assert.equal(control.value, "中 A");
  assert.equal(control.selectionStart, 3);
  assert.equal(inputEvents, 1);
});

test("native binding can be disposed", () => {
  const control = new FakeTextControl("中");
  const binding = bindNaturalSpacing(control, { policy: "naturalLanguage" });

  control.nativeEdit("中A", 2);
  control.dispatchEvent(inputEvent("insertText"));
  assert.equal(control.value, "中 A");

  binding.dispose();
  control.nativeEdit("中A文", 3);
  control.dispatchEvent(inputEvent("insertText"));
  assert.equal(control.value, "中A文");
});

test("display CSS is guarded and excludes editable controls", async () => {
  const css = await readFile(new URL("../styles/display.css", import.meta.url), "utf8");
  assert.match(css, /@supports \(text-autospace: normal\)/);
  assert.match(css, /:not\(input\)/);
  assert.match(css, /:not\(textarea\)/);
  assert.match(css, /:not\(\[contenteditable\]\)/);
});

class FakeTextControl extends EventTarget {
  constructor(value) {
    super();
    this.type = "text";
    this.value = value;
    this.selectionStart = value.length;
    this.selectionEnd = value.length;
    this.selectionDirection = "none";
    this.replacements = [];
    this.commands = [];
    this.ownerDocument = {
      queryCommandSupported: (command) => command === "insertText",
      execCommand: (command, _showUI, value) => {
        this.commands.push({ command, value });
        const start = this.selectionStart;
        const end = this.selectionEnd;
        this.setRangeText(value, start, end);
        this.setSelectionRange(start + value.length, start + value.length, "none");
        this.dispatchEvent(inputEvent("insertText"));
        return true;
      },
    };
  }

  nativeEdit(value, caret) {
    this.value = value;
    this.setSelectionRange(caret, caret, "none");
  }

  setRangeText(replacement, start, end) {
    this.replacements.push({ replacement, start, end });
    this.value = this.value.slice(0, start) + replacement + this.value.slice(end);
  }

  setSelectionRange(start, end, direction = "none") {
    this.selectionStart = start;
    this.selectionEnd = end;
    this.selectionDirection = direction;
  }
}

function inputEvent(inputType, isComposing = false) {
  const event = new Event("input");
  Object.defineProperties(event, {
    inputType: { value: inputType },
    isComposing: { value: isComposing },
  });
  return event;
}

function beforeInputEvent(inputType, data) {
  const event = new Event("beforeinput", { cancelable: true });
  Object.defineProperties(event, {
    inputType: { value: inputType },
    data: { value: data },
    isComposing: { value: false },
  });
  return event;
}
