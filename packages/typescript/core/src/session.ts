import { mapSelection, planEditWithSuppressedOffsets } from "./plan.js";
import { processProposedEdit } from "./proposed-edit.js";
import type {
  EditPlan,
  EditSnapshot,
  FieldPolicy,
  Insertion,
  ProposedEdit,
  ProposedEditResult,
} from "./types.js";
import { insertionReason, segmentText } from "./unicode.js";

interface SuppressedBoundary {
  readonly offset: number;
  readonly left: string;
  readonly right: string;
}

export class NaturalSpacingSession {
  #suppressions: SuppressedBoundary[] = [];
  #lastPolicy: FieldPolicy | undefined;

  get suppressedBoundaryCount(): number {
    return this.#suppressions.length;
  }

  reset(): void {
    this.#suppressions = [];
    this.#lastPolicy = undefined;
  }

  process(snapshot: EditSnapshot): EditPlan {
    if (this.#lastPolicy !== undefined && this.#lastPolicy !== snapshot.policy) {
      this.#suppressions = [];
    }
    this.#lastPolicy = snapshot.policy;
    this.#rebaseSuppressions(snapshot);

    if (snapshot.policy === "naturalLanguage" && snapshot.composingRange === null) {
      const deletedBoundary = deletedSpaceBoundary(snapshot);
      if (deletedBoundary !== null) this.#addSuppression(deletedBoundary);
    }

    const planned = planEditWithSuppressedOffsets(
      snapshot,
      new Set(this.#suppressions.map(({ offset }) => offset)),
    );
    const plan =
      planned.decision === "noChange" && this.#suppressions.length > 0
        ? { ...planned, decision: "suppressed" as const }
        : planned;
    this.#mapSuppressionsThrough(plan.insertions, plan.resultText);
    return plan;
  }

  processProposedEdit(edit: ProposedEdit): ProposedEditResult {
    return processProposedEdit(edit, (snapshot) => this.process(snapshot));
  }

  #addSuppression(boundary: SuppressedBoundary): void {
    this.#suppressions = this.#suppressions.filter(({ offset }) => offset !== boundary.offset);
    this.#suppressions.push(boundary);
  }

  #rebaseSuppressions(snapshot: EditSnapshot): void {
    const editStart = snapshot.changedRange.start;
    const editEnd = editStart + snapshot.changedRange.length;
    const delta = snapshot.afterUserText.length - snapshot.beforeText.length;
    const rebased: SuppressedBoundary[] = [];

    for (const suppression of this.#suppressions) {
      let offset = suppression.offset;
      if (offset > editEnd || (snapshot.changedRange.length > 0 && offset === editEnd)) {
        offset += delta;
      } else if (offset > editStart && offset < editEnd) {
        continue;
      }

      const context = boundaryContext(snapshot.afterUserText, offset);
      if (context?.left === suppression.left && context.right === suppression.right) {
        rebased.push({ ...suppression, offset });
      }
    }
    this.#suppressions = rebased;
  }

  #mapSuppressionsThrough(insertions: readonly Insertion[], resultText: string): void {
    const mapped: SuppressedBoundary[] = [];
    for (const suppression of this.#suppressions) {
      const offset = mapSelection(
        { anchor: suppression.offset, focus: suppression.offset },
        insertions,
      ).anchor;
      const context = boundaryContext(resultText, offset);
      if (context?.left === suppression.left && context.right === suppression.right) {
        mapped.push({ ...suppression, offset });
      }
    }
    this.#suppressions = mapped;
  }
}

function deletedSpaceBoundary(snapshot: EditSnapshot): SuppressedBoundary | null {
  if (snapshot.editKind !== "delete" || snapshot.changedRange.length !== 1) return null;
  const start = snapshot.changedRange.start;
  if (snapshot.beforeText.slice(start, start + 1) !== " ") return null;
  if (snapshot.afterUserText.length !== snapshot.beforeText.length - 1) return null;

  const context = boundaryContext(snapshot.afterUserText, start);
  if (context === null || insertionReason(context.leftCategory, context.rightCategory) === null) {
    return null;
  }
  return { offset: start, left: context.left, right: context.right };
}

function boundaryContext(text: string, offset: number): {
  readonly left: string;
  readonly right: string;
  readonly leftCategory: ReturnType<typeof segmentText>[number]["category"];
  readonly rightCategory: ReturnType<typeof segmentText>[number]["category"];
} | null {
  const graphemes = segmentText(text);
  const rightIndex = graphemes.findIndex((grapheme) => grapheme.start === offset);
  if (rightIndex <= 0) return null;
  const left = graphemes[rightIndex - 1];
  const right = graphemes[rightIndex];
  if (left === undefined || right === undefined || left.end !== offset) return null;
  return {
    left: left.text,
    right: right.text,
    leftCategory: left.category,
    rightCategory: right.category,
  };
}
