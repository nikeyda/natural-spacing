import type {
  EditPlan,
  EditSnapshot,
  FieldPolicy,
  Insertion,
  TextSelection,
} from "./types.js";
import { insertionReason, segmentText } from "./unicode.js";

export function eligibleInsertions(text: string): readonly Insertion[] {
  const graphemes = segmentText(text);
  const insertions: Insertion[] = [];

  for (let index = 1; index < graphemes.length; index += 1) {
    const left = graphemes[index - 1];
    const right = graphemes[index];
    if (left === undefined || right === undefined) continue;
    const reason = insertionReason(left.category, right.category);
    if (reason !== null) insertions.push({ offset: right.start, text: " ", reason });
  }
  return insertions;
}

export function applyInsertions(text: string, insertions: readonly Insertion[]): string {
  let result = text;
  for (let index = insertions.length - 1; index >= 0; index -= 1) {
    const insertion = insertions[index];
    if (insertion !== undefined) {
      result = result.slice(0, insertion.offset) + insertion.text + result.slice(insertion.offset);
    }
  }
  return result;
}

export function mapSelection(
  selection: TextSelection,
  insertions: readonly Insertion[],
): TextSelection {
  const map = (endpoint: number): number =>
    endpoint +
    insertions.reduce(
      (shift, insertion) => shift + (endpoint >= insertion.offset ? insertion.text.length : 0),
      0,
    );

  return { anchor: map(selection.anchor), focus: map(selection.focus) };
}

export function normalizeNaturalLanguage(
  text: string,
  policy: FieldPolicy = "verbatim",
): string {
  if (policy === "verbatim") return text;
  return applyInsertions(text, eligibleInsertions(text));
}

export function planEdit(snapshot: EditSnapshot): EditPlan {
  return planEditWithSuppressedOffsets(snapshot, new Set<number>());
}

/** @internal */
export function planEditWithSuppressedOffsets(
  snapshot: EditSnapshot,
  suppressedOffsets: ReadonlySet<number>,
): EditPlan {
  if (snapshot.policy === "verbatim") return unchangedPlan(snapshot, "verbatim");
  if (snapshot.composingRange !== null) return unchangedPlan(snapshot, "composing");

  const eligible = eligibleInsertionsForEdit(snapshot);
  const insertions = eligible.filter((insertion) => !suppressedOffsets.has(insertion.offset));
  if (insertions.length === 0) {
    return unchangedPlan(snapshot, eligible.length > 0 ? "suppressed" : "noChange");
  }

  const resultText = applyInsertions(snapshot.afterUserText, insertions);
  if (snapshot.maxLengthUtf16 !== null && resultText.length > snapshot.maxLengthUtf16) {
    return unchangedPlan(snapshot, "lengthLimited");
  }

  return {
    decision: "applied",
    insertions,
    resultText,
    selection: mapSelection(snapshot.selection, insertions),
  };
}

function eligibleInsertionsForEdit(snapshot: EditSnapshot): readonly Insertion[] {
  const replacementLength =
    snapshot.afterUserText.length -
    (snapshot.beforeText.length - snapshot.changedRange.length);
  const affectedStart = snapshot.changedRange.start;
  const affectedEnd = affectedStart + replacementLength;
  return eligibleInsertions(snapshot.afterUserText).filter(
    ({ offset }) => offset >= affectedStart && offset <= affectedEnd,
  );
}

function unchangedPlan(snapshot: EditSnapshot, decision: EditPlan["decision"]): EditPlan {
  return {
    decision,
    insertions: [],
    resultText: snapshot.afterUserText,
    selection: snapshot.selection,
  };
}
