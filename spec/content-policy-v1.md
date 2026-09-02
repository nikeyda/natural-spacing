# Content Policy and Non-interactive Text v1

- Status: Draft frozen for the first cross-platform implementations
- Version: 1.0.0-draft.2
- Depends on: Natural Spacing Rules v1

## 1. Purpose

This specification lets applications choose or recommend `.naturalLanguage` and `.verbatim` consistently for keyboard input, ASR, dictation, imported text, and generated text.

The recommendation API does not introduce a third field policy. It returns one of the existing policies plus evidence describing whether an application may safely apply it automatically.

## 2. Precedence and stability

Policy resolution follows this order:

1. Secure input, including `isSecure=true` or `contentKind=password`, MUST use `verbatim` without inspecting its value. This safety rule overrides an explicit `naturalLanguage` policy.
2. Outside secure input, an explicit developer or user policy MUST win.
3. A known semantic content kind MAY produce a high-confidence automatic choice.
4. Current text MAY produce a recommendation, but MUST NOT silently switch an active editing session.
5. Insufficient evidence falls back to `verbatim`.

Applications SHOULD resolve an automatic policy when a field or text pipeline is configured. They MUST NOT repeatedly re-resolve from every keystroke and change policy without explicit user or developer action.

## 3. Content kinds

### 3.1 Natural-language kinds

These kinds recommend `naturalLanguage` with high confidence and `autoApply=true`:

- `prose`;
- `title`;
- `message`;
- `note`;
- `document`;
- `transcript`;
- `asrTranscript`.

### 3.2 Verbatim kinds

These kinds recommend `verbatim` with high confidence and `autoApply=true`:

- `code`;
- `identifier`;
- `url`;
- `email`;
- `password`;
- `token`;
- `filePath`;
- `command`;
- `number`.

### 3.3 Ambiguous kinds

`searchQuery` recommends `naturalLanguage` with medium confidence unless the available text has strong structured-text evidence. It MUST use `autoApply=false`.

`unknown` uses text evidence when available and otherwise falls back to `verbatim` with low confidence and `autoApply=false`.

## 4. Recommendation result

A recommendation contains:

- `policy`: `naturalLanguage` or `verbatim`;
- `confidence`: `high`, `medium`, or `low`;
- `source`: `explicit`, `safety`, `contentKind`, `textHeuristic`, or `fallback`;
- `reason`: a stable machine-readable reason;
- `autoApply`: whether the result is safe to apply automatically at configuration time.

Text-only heuristics MUST use `autoApply=false`, including strong URL, email, path, identifier, or code evidence. This prevents content changes from silently changing an active field's behavior.

### 4.1 Safe automatic resolution

Implementations SHOULD expose a convenience resolver equivalent to:

```text
recommendation = recommendPolicy(context)
resolved = recommendation.autoApply ? recommendation.policy : fallback
```

The default fallback MUST be `verbatim`. A caller MAY provide `naturalLanguage` as its fallback when its own product context has already made that choice. The resolver MUST NOT convert an advisory text heuristic or ambiguous content-kind recommendation into an automatic policy without that caller-supplied fallback.

## 5. Privacy and security

When `isSecure=true` or `contentKind=password`, the recommendation and resolver MUST return `verbatim` before considering an explicit policy or running text heuristics. Implementations SHOULD omit the value entirely for secure fields.

Recommendation APIs MUST NOT log inspected text. Fixtures and diagnostics MUST use synthetic content.

## 6. Non-interactive text updates

The shared non-interactive API accepts:

- `text`;
- explicit resolved `policy`;
- `source`: `asr`, `dictation`, `imported`, or `generated`;
- `stability`: `interim` or `final`.

It returns:

- `displayText`: normalized according to the resolved policy;
- `committedText`: the same value for `final`, otherwise `null`;
- `changed`;
- the unchanged source, stability, and policy metadata.

### 6.1 ASR and dictation

Interim ASR hypotheses MAY be normalized for display, but MUST NOT be treated as stable persisted content or fed back into the recognizer.

Final hypotheses MAY use `committedText` for persistence.

When an ASR provider emits delta tokens rather than a complete hypothesis, the integration MUST first assemble the current hypothesis. Formatting individual delta tokens cannot detect a Han–Latin or Han–digit boundary split across two chunks.

### 6.2 Ordered revisable hypotheses

Implementations SHOULD expose an ordered session for providers that emit complete revisable hypotheses. The session accepts:

- a non-empty utterance ID established by `start`;
- a non-negative monotonically increasing revision;
- the provider's complete current hypothesis;
- `interim` or `final` stability.

The session MUST reject duplicate or older revisions, events for inactive utterances, and negative revisions without producing formatted output. An accepted `final` event MUST close the active utterance so late events cannot overwrite committed text. Explicit cancellation MUST close only the matching utterance. Starting a valid utterance MUST replace the active identity and reset its revision baseline.

The session MUST retain no hypothesis text after returning an event. It MAY retain only the active utterance ID, the latest accepted revision, and configuration metadata.

### 6.3 Imported and generated text

Imported or generated final text can use the same canonical normalization. Structured documents, Markdown, source code, and rich text remain outside rules v1 and SHOULD resolve to `verbatim` until a structure-aware adapter exists.

## 7. Conformance

An implementation conforms when:

1. all cases in `fixtures/policy-v1.json` match exactly;
2. all cases in `fixtures/text-updates-v1.json` match exactly;
3. explicit and secure choices are evaluated before text inspection;
4. text-only results never set `autoApply=true`;
5. interim updates always return `committedText=null`;
6. final updates are idempotent under repeated formatting.
7. safe automatic resolution uses the recommendation only when `autoApply=true`, otherwise the caller's fallback.
8. all scenarios in `fixtures/ordered-text-sessions-v1.json` match exactly.
