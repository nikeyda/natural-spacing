# ADR 0003: Content spacing and display spacing are separate modes

- Status: Accepted for MVP
- Date: 2026-09-01

## Decision

`naturalLanguage` input inserts U+0020 into stored content. Static HTML may opt into CSS `text-autospace`, which changes presentation only.

The two modes must not be applied to the same editable element. Input elements, textareas, and contenteditable regions are excluded from the CSS helper.

## Consequences

- Stored values and copy behavior remain explicit.
- Browsers without `text-autospace` support degrade to unchanged static presentation.
- Rich text and contenteditable support require a future adapter and are outside MVP.
