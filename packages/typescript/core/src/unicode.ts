import type { InsertionReason } from "./types.js";
import { graphemeSegments } from "unicode-segmenter/grapheme";
import {
  HAN_RANGES,
  LATIN_RANGES,
  MARK_RANGES,
  WHITE_SPACE_RANGES,
  containsCodePoint,
} from "./unicode-17.generated.js";

export const UNICODE_VERSION = "17.0.0";

export type BoundaryCategory = "Han" | "Latin" | "AsciiDigit" | "Whitespace" | "Other";

export interface Grapheme {
  readonly text: string;
  readonly start: number;
  readonly end: number;
  readonly category: BoundaryCategory;
}

export function classifyGrapheme(text: string): BoundaryCategory {
  const codePoints = [...text].map((scalar) => scalar.codePointAt(0));
  if (codePoints.some((codePoint) =>
    codePoint !== undefined && containsCodePoint(WHITE_SPACE_RANGES, codePoint))) {
    return "Whitespace";
  }
  if (
    codePoints.length === 1 &&
    codePoints[0] !== undefined &&
    codePoints[0] >= 0x30 &&
    codePoints[0] <= 0x39
  ) {
    return "AsciiDigit";
  }

  const base = codePoints.find((codePoint) =>
    codePoint !== undefined && !containsCodePoint(MARK_RANGES, codePoint));
  if (base === undefined) return "Other";
  if (containsCodePoint(HAN_RANGES, base)) return "Han";
  if (containsCodePoint(LATIN_RANGES, base)) return "Latin";
  return "Other";
}

export function segmentText(text: string): readonly Grapheme[] {
  return [...graphemeSegments(text)].map((part) => ({
    text: part.segment,
    start: part.index,
    end: part.index + part.segment.length,
    category: classifyGrapheme(part.segment),
  }));
}

export function insertionReason(
  left: BoundaryCategory,
  right: BoundaryCategory,
): InsertionReason | null {
  if ((left === "Han" && right === "Latin") || (left === "Latin" && right === "Han")) {
    return "hanLatin";
  }
  if (
    (left === "Han" && right === "AsciiDigit") ||
    (left === "AsciiDigit" && right === "Han")
  ) {
    return "hanAsciiDigit";
  }
  return null;
}
