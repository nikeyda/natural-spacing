export {
  applyInsertions,
  eligibleInsertions,
  mapSelection,
  normalizeNaturalLanguage,
  planEdit,
} from "./plan.js";
export { NaturalSpacingSession } from "./session.js";
export {
  planProposedEdit,
  proposedEditReplacingDifference,
} from "./proposed-edit.js";
export { recommendPolicy, resolvePolicy } from "./policy.js";
export { formatTextUpdate } from "./text-update.js";
export { OrderedTextUpdateSession } from "./ordered-text-update-session.js";
export {
  classifyGrapheme,
  insertionReason,
  segmentText,
  UNICODE_VERSION,
} from "./unicode.js";
export type {
  ContentKind,
  EditKind,
  EditPlan,
  EditSnapshot,
  FieldPolicy,
  FormattedTextUpdate,
  Insertion,
  InsertionReason,
  OrderedTextSource,
  OrderedTextUpdateEvent,
  OrderedTextUpdateReason,
  OrderedTextUpdateResult,
  PlanDecision,
  ProposedEdit,
  ProposedEditResult,
  PolicyContext,
  PolicyRecommendation,
  RecommendationConfidence,
  RecommendationReason,
  RecommendationSource,
  TextSource,
  TextStability,
  TextUpdate,
  TextRange,
  TextSelection,
} from "./types.js";
export type { BoundaryCategory, Grapheme } from "./unicode.js";
