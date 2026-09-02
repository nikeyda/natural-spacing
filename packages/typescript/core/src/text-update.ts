import { normalizeNaturalLanguage } from "./plan.js";
import type { FormattedTextUpdate, TextUpdate } from "./types.js";

export function formatTextUpdate(update: TextUpdate): FormattedTextUpdate {
  const displayText = normalizeNaturalLanguage(update.text, update.policy);
  return {
    displayText,
    committedText: update.stability === "final" ? displayText : null,
    changed: displayText !== update.text,
    policy: update.policy,
    source: update.source,
    stability: update.stability,
  };
}
