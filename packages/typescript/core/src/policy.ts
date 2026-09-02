import { eligibleInsertions } from "./plan.js";
import type {
  ContentKind,
  PolicyContext,
  PolicyRecommendation,
} from "./types.js";

const naturalLanguageKinds = new Set<ContentKind>([
  "prose",
  "title",
  "message",
  "note",
  "document",
  "transcript",
  "asrTranscript",
]);

const verbatimKinds = new Set<ContentKind>([
  "code",
  "identifier",
  "url",
  "email",
  "password",
  "token",
  "filePath",
  "command",
  "number",
]);

export function recommendPolicy(context: PolicyContext = {}): PolicyRecommendation {
  if (context.isSecure === true || context.contentKind === "password") {
    return recommendation("verbatim", "high", "safety", "secureContent", true);
  }

  if (context.explicitPolicy !== undefined) {
    return recommendation(context.explicitPolicy, "high", "explicit", "explicitPolicy", true);
  }

  const contentKind = context.contentKind ?? "unknown";
  if (naturalLanguageKinds.has(contentKind)) {
    return recommendation(
      "naturalLanguage",
      "high",
      "contentKind",
      "naturalLanguageContent",
      true,
    );
  }
  if (verbatimKinds.has(contentKind)) {
    return recommendation("verbatim", "high", "contentKind", "structuredContent", true);
  }

  if (context.text !== undefined && looksStructured(context.text)) {
    return recommendation("verbatim", "medium", "textHeuristic", "structuredText", false);
  }

  if (contentKind === "searchQuery") {
    return recommendation(
      "naturalLanguage",
      "medium",
      "contentKind",
      "ambiguousSearch",
      false,
    );
  }

  if (context.text !== undefined && eligibleInsertions(context.text).length > 0) {
    return recommendation(
      "naturalLanguage",
      "medium",
      "textHeuristic",
      "mixedNaturalLanguage",
      false,
    );
  }

  return recommendation("verbatim", "low", "fallback", "insufficientEvidence", false);
}

/**
 * Resolves a policy for automatic use without silently applying a heuristic
 * recommendation. Recommendations with `autoApply=false` use the caller's
 * fallback, which is `verbatim` by default.
 */
export function resolvePolicy(
  context: PolicyContext = {},
  fallback: PolicyRecommendation["policy"] = "verbatim",
): PolicyRecommendation["policy"] {
  const recommended = recommendPolicy(context);
  return recommended.autoApply ? recommended.policy : fallback;
}

function recommendation(
  policy: PolicyRecommendation["policy"],
  confidence: PolicyRecommendation["confidence"],
  source: PolicyRecommendation["source"],
  reason: PolicyRecommendation["reason"],
  autoApply: boolean,
): PolicyRecommendation {
  return { policy, confidence, source, reason, autoApply };
}

function looksStructured(text: string): boolean {
  const value = text.trim();
  if (value.length === 0) return false;
  if (/^(?:[a-z][a-z0-9+.-]*:\/\/|www\.)/i.test(value)) return true;
  if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) return true;
  if (/^(?:[A-Za-z]:[\\/]|~?[\\/])/.test(value)) return true;
  if (/^(?:[A-Za-z_$][A-Za-z0-9_$-]*[.:/@\\])+[A-Za-z0-9_$.-]+$/.test(value)) {
    return true;
  }
  return /(?:=>|::|<\/?[A-Za-z][^>]*>|\{[^}]*\}|`[^`]*`)/.test(value);
}
