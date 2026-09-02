# ADR 0002: UTF-16 offsets and grapheme-safe insertion

- Status: Accepted for MVP
- Date: 2026-09-01

## Context

UIKit ranges, JavaScript DOM selections, Android/Kotlin text ranges, and Dart editing ranges can be bridged consistently through UTF-16 code-unit offsets. Unicode code points and user-perceived characters do not always have length one in UTF-16.

## Decision

The cross-language edit contract uses zero-based UTF-16 code-unit offsets and half-open ranges. Implementations must decode Unicode correctly and may insert only at Unicode extended grapheme cluster boundaries.

Rules v1 pins Unicode 17.0 and follows Unicode Standard Annex #29 for extended grapheme boundaries.

## Consequences

- Fixture ranges can be compared directly across languages.
- Implementations need explicit conversion helpers where a language uses another native index type.
- Offsets inside a surrogate pair or extended grapheme cluster are invalid, even if they are numerically within the string's UTF-16 length.
