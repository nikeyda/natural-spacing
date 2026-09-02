import { applyInsertions, planEdit } from "./plan.js";
import type {
  EditKind,
  EditPlan,
  EditSnapshot,
  FieldPolicy,
  ProposedEdit,
  ProposedEditResult,
  TextSelection,
} from "./types.js";

export function planProposedEdit(edit: ProposedEdit): ProposedEditResult {
  return processProposedEdit(edit, planEdit);
}

export function proposedEditReplacingDifference(options: {
  readonly beforeText: string;
  readonly afterText: string;
  readonly selectionAfterEdit?: TextSelection;
  readonly policy: FieldPolicy;
  readonly maxLengthUtf16?: number | null;
}): ProposedEdit | null {
  const { beforeText, afterText } = options;
  let prefix = 0;
  while (
    prefix < beforeText.length &&
    prefix < afterText.length &&
    beforeText.charCodeAt(prefix) === afterText.charCodeAt(prefix)
  ) {
    prefix += 1;
  }

  let suffix = 0;
  while (
    suffix < beforeText.length - prefix &&
    suffix < afterText.length - prefix &&
    beforeText.charCodeAt(beforeText.length - suffix - 1) ===
      afterText.charCodeAt(afterText.length - suffix - 1)
  ) {
    suffix += 1;
  }

  const oldLength = beforeText.length - prefix - suffix;
  const newLength = afterText.length - prefix - suffix;
  if (oldLength === 0 && newLength === 0) return null;
  const replacementText = afterText.slice(prefix, prefix + newLength);
  const editKind: EditKind =
    replacementText.length === 0 && oldLength > 0
      ? "delete"
      : oldLength === 0
        ? "insert"
        : "replace";

  return {
    text: beforeText,
    range: { start: prefix, length: oldLength },
    replacementText,
    composingRange: null,
    ...(options.selectionAfterEdit === undefined
      ? {}
      : { selectionAfterEdit: options.selectionAfterEdit }),
    editKind,
    policy: options.policy,
    maxLengthUtf16: options.maxLengthUtf16 ?? null,
  };
}

/** @internal */
export function processProposedEdit(
  edit: ProposedEdit,
  planner: (snapshot: EditSnapshot) => EditPlan,
): ProposedEditResult {
  if (
    !Number.isInteger(edit.range.start) ||
    !Number.isInteger(edit.range.length) ||
    edit.range.start < 0 ||
    edit.range.length < 0 ||
    edit.range.start > edit.text.length - edit.range.length
  ) {
    throw new RangeError("Proposed edit range is outside the UTF-16 text bounds.");
  }

  const afterUserText =
    edit.text.slice(0, edit.range.start) +
    edit.replacementText +
    edit.text.slice(edit.range.start + edit.range.length);
  const caret = edit.range.start + edit.replacementText.length;
  const plan = planner({
    beforeText: edit.text,
    afterUserText,
    changedRange: edit.range,
    selection: edit.selectionAfterEdit ?? { anchor: caret, focus: caret },
    composingRange: edit.composingRange,
    editKind: edit.editKind,
    policy: edit.policy,
    maxLengthUtf16: edit.maxLengthUtf16,
  });

  if (plan.decision !== "applied") {
    return {
      plan,
      replacementText: edit.replacementText,
      requiresReplacement: false,
    };
  }
  const relativeInsertions = plan.insertions.map((insertion) => ({
    ...insertion,
    offset: insertion.offset - edit.range.start,
  }));
  return {
    plan,
    replacementText: applyInsertions(edit.replacementText, relativeInsertions),
    requiresReplacement: true,
  };
}
