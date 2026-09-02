# ADR 0001: Specification-first native cores

- Status: Accepted for MVP
- Date: 2026-09-01

## Context

The boundary rules are small, but UIKit, AppKit, Android, DOM, React, WinUI, WPF, and Flutter expose different composition, selection, undo, and notification behavior. A shared native or WebAssembly runtime would not remove the need for platform input coordinators.

Independent ports without shared conformance data tend to drift.

## Decision

Use a language-neutral specification, pinned Unicode metadata, and shared JSON fixtures as the source of truth. Implement small native cores in TypeScript, Swift, Kotlin, C#, and Dart. Framework wrappers must reuse their platform core.

The TypeScript implementation will be built first for fast conformance feedback, but it is not semantically privileged.

## Consequences

- Every implementation must pass the same fixtures.
- Some algorithm code will exist in more than one language.
- A Rust/WASM/FFI core may be reconsidered if the scope later expands to document parsing, CLI, LSP, or server processing.
