export type FieldPolicy = "naturalLanguage" | "verbatim";

export type ContentKind =
  | "prose"
  | "title"
  | "message"
  | "note"
  | "document"
  | "transcript"
  | "asrTranscript"
  | "code"
  | "identifier"
  | "url"
  | "email"
  | "password"
  | "token"
  | "filePath"
  | "command"
  | "number"
  | "searchQuery"
  | "unknown";

export type RecommendationConfidence = "high" | "medium" | "low";
export type RecommendationSource =
  | "explicit"
  | "safety"
  | "contentKind"
  | "textHeuristic"
  | "fallback";
export type RecommendationReason =
  | "explicitPolicy"
  | "secureContent"
  | "naturalLanguageContent"
  | "structuredContent"
  | "ambiguousSearch"
  | "structuredText"
  | "mixedNaturalLanguage"
  | "insufficientEvidence";

export interface PolicyContext {
  readonly explicitPolicy?: FieldPolicy;
  readonly contentKind?: ContentKind;
  readonly text?: string;
  readonly isSecure?: boolean;
}

export interface PolicyRecommendation {
  readonly policy: FieldPolicy;
  readonly confidence: RecommendationConfidence;
  readonly source: RecommendationSource;
  readonly reason: RecommendationReason;
  readonly autoApply: boolean;
}

export type TextSource = "asr" | "dictation" | "imported" | "generated";
export type TextStability = "interim" | "final";

export interface TextUpdate {
  readonly text: string;
  readonly policy: FieldPolicy;
  readonly source: TextSource;
  readonly stability: TextStability;
}

export interface FormattedTextUpdate {
  readonly displayText: string;
  readonly committedText: string | null;
  readonly changed: boolean;
  readonly policy: FieldPolicy;
  readonly source: TextSource;
  readonly stability: TextStability;
}

export type OrderedTextSource = Extract<TextSource, "asr" | "dictation">;
export type OrderedTextUpdateReason =
  | "accepted"
  | "inactiveUtterance"
  | "staleRevision"
  | "invalidRevision";

export interface OrderedTextUpdateEvent {
  readonly utteranceId: string;
  readonly revision: number;
  readonly text: string;
  readonly stability: TextStability;
}

export interface OrderedTextUpdateResult {
  readonly accepted: boolean;
  readonly reason: OrderedTextUpdateReason;
  readonly output: FormattedTextUpdate | null;
}

export type EditKind = "insert" | "delete" | "replace" | "paste";

export type PlanDecision =
  | "applied"
  | "noChange"
  | "verbatim"
  | "composing"
  | "suppressed"
  | "lengthLimited";

export interface TextRange {
  readonly start: number;
  readonly length: number;
}

export interface TextSelection {
  readonly anchor: number;
  readonly focus: number;
}

export interface EditSnapshot {
  readonly beforeText: string;
  readonly afterUserText: string;
  readonly changedRange: TextRange;
  readonly selection: TextSelection;
  readonly composingRange: TextRange | null;
  readonly editKind: EditKind;
  readonly policy: FieldPolicy;
  readonly maxLengthUtf16: number | null;
}

export type InsertionReason = "hanLatin" | "hanAsciiDigit";

export interface Insertion {
  readonly offset: number;
  readonly text: " ";
  readonly reason: InsertionReason;
}

export interface EditPlan {
  readonly decision: PlanDecision;
  readonly insertions: readonly Insertion[];
  readonly resultText: string;
  readonly selection: TextSelection;
}

export interface ProposedEdit {
  readonly text: string;
  readonly range: TextRange;
  readonly replacementText: string;
  readonly composingRange: TextRange | null;
  readonly selectionAfterEdit?: TextSelection;
  readonly editKind: EditKind;
  readonly policy: FieldPolicy;
  readonly maxLengthUtf16: number | null;
}

export interface ProposedEditResult {
  readonly plan: EditPlan;
  readonly replacementText: string;
  readonly requiresReplacement: boolean;
}
