import {
  formatTextUpdate,
  OrderedTextUpdateSession,
} from "../../packages/typescript/core/dist/index.js";

/**
 * Formats a provider event that already contains the complete current
 * hypothesis. Interim values are display-only; final values may be committed.
 */
export function formatFullAsrHypothesis({
  text,
  stability,
  policy = "naturalLanguage",
}) {
  return formatTextUpdate({
    text,
    policy,
    source: "asr",
    stability,
  });
}

/**
 * Coordinates revision-capable providers that emit complete hypotheses.
 *
 * Call `start` with a provider-owned, unique utterance ID before accepting
 * events. Revisions must be monotonically increasing integers. The session
 * stores only the active ID and last revision; hypothesis text is formatted
 * and returned without being retained.
 */
export { OrderedTextUpdateSession as OrderedAsrHypothesisSession };

/**
 * Example adapter for providers that explicitly guarantee append-only deltas.
 * Revision-capable providers must assemble their own canonical full hypothesis
 * before calling formatFullAsrHypothesis.
 */
export class AppendOnlyAsrBuffer {
  #text = "";
  #policy;

  constructor({ policy = "naturalLanguage" } = {}) {
    this.#policy = policy;
  }

  accept({ delta, stability }) {
    this.#text += delta;
    const result = formatFullAsrHypothesis({
      text: this.#text,
      policy: this.#policy,
      stability,
    });
    if (stability === "final") this.#text = "";
    return result;
  }

  reset() {
    this.#text = "";
  }
}
