import { formatTextUpdate } from "./text-update.js";
import type {
  FieldPolicy,
  OrderedTextSource,
  OrderedTextUpdateEvent,
  OrderedTextUpdateResult,
} from "./types.js";

/**
 * Coordinates complete hypotheses from revision-capable ASR or dictation
 * providers. The session retains only the active utterance ID and revision,
 * never hypothesis text.
 */
export class OrderedTextUpdateSession {
  readonly policy: FieldPolicy;
  readonly source: OrderedTextSource;
  #active: { utteranceId: string; lastRevision: number } | null = null;

  constructor({
    policy = "naturalLanguage",
    source = "asr",
  }: {
    policy?: FieldPolicy;
    source?: OrderedTextSource;
  } = {}) {
    this.policy = policy;
    this.source = source;
  }

  start(utteranceId: string): boolean {
    if (utteranceId.length === 0) return false;
    this.#active = { utteranceId, lastRevision: -1 };
    return true;
  }

  accept(event: OrderedTextUpdateEvent): OrderedTextUpdateResult {
    if (!Number.isSafeInteger(event.revision) || event.revision < 0) {
      return { accepted: false, reason: "invalidRevision", output: null };
    }
    if (this.#active?.utteranceId !== event.utteranceId) {
      return { accepted: false, reason: "inactiveUtterance", output: null };
    }
    if (event.revision <= this.#active.lastRevision) {
      return { accepted: false, reason: "staleRevision", output: null };
    }

    this.#active.lastRevision = event.revision;
    const output = formatTextUpdate({
      text: event.text,
      policy: this.policy,
      source: this.source,
      stability: event.stability,
    });
    if (event.stability === "final") this.#active = null;
    return { accepted: true, reason: "accepted", output };
  }

  cancel(utteranceId: string): boolean {
    if (this.#active?.utteranceId !== utteranceId) return false;
    this.#active = null;
    return true;
  }
}
