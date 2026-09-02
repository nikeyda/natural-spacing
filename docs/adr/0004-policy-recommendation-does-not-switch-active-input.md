# ADR 0004: Policy recommendation does not switch active input

- Status: Accepted for MVP
- Date: 2026-09-02

## Context

Developers need help choosing `naturalLanguage` or `verbatim`, but inferring policy from text on every keystroke can change behavior mid-session, surprise users, and expose secure content to unnecessary inspection.

## Decision

Keep exactly two field policies. Add a resolver that returns a policy, confidence, evidence source, reason, and `autoApply` flag.

Explicit configuration and secure-field safety take precedence. Known semantic content kinds may be auto-applied at configuration time. Text-only heuristics are recommendations and never set `autoApply=true`.

An active editor keeps its resolved policy until the developer, user, or field lifecycle explicitly changes it.

## Consequences

- Common prose, transcript, code, URL, and password fields require little configuration.
- Ambiguous search and unknown fields remain explainable and conservative.
- Platform adapters do not need to duplicate heuristics or change policy during composition.
