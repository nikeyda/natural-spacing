# Ordered ASR and dictation updates

Use `OrderedTextUpdateSession` when an ASR or dictation provider emits a complete, revisable hypothesis with an utterance ID and monotonically increasing revision.

Resolve the policy once before starting the utterance. `asrTranscript` resolves automatically to `naturalLanguage`; structured destinations should pass `verbatim` explicitly.

## Lifecycle

1. Create one session for one logical stream and fixed policy/source.
2. Call `start` with a non-empty provider-owned utterance ID.
3. Pass each complete hypothesis to `accept` with a non-negative revision.
4. Render accepted interim `displayText`, but do not persist it.
5. Persist only accepted final `committedText`; final closes the utterance.
6. Call `cancel` when the provider cancels an utterance.

Duplicate or older revisions return `staleRevision`. Events for another, cancelled, or finalized utterance return `inactiveUtterance`. Negative revisions return `invalidRevision`. Rejected events never produce output.

For every provider callback, inspect `accepted` before reading `output`:

```text
if result is rejected:
    ignore the hypothesis and record result.reason without user text
else:
    render result.output.displayText
    if result.output.committedText exists:
        persist result.output.committedText
```

An accepted interim result always has a display value and no committed value.
An accepted final result has both values and closes the utterance. A provider
reconnect or revision reset must therefore start a new provider-owned utterance
ID before revision zero is accepted again; do not reuse an ID to bypass stale
revision protection.

The session retains only the active utterance ID and latest revision. It does not retain hypothesis text.

## TypeScript

```ts
import { OrderedTextUpdateSession } from "@natural-spacing/core";

const session = new OrderedTextUpdateSession({ policy, source: "asr" });
if (!session.start(providerUtteranceId)) throw new Error("empty utterance ID");

const result = session.accept({
  utteranceId: providerUtteranceId,
  revision: providerRevision,
  text: canonicalFullHypothesis,
  stability: "interim",
});

if (result.accepted && result.output !== null) {
  render(result.output.displayText);
  if (result.output.committedText !== null) persist(result.output.committedText);
}
```

## Swift

```swift
import NaturalSpacingCore

let session = OrderedTextUpdateSession(policy: policy, source: .asr)
guard session.start(utteranceID: providerUtteranceID) else { return }

let result = session.accept(OrderedTextUpdateEvent(
    utteranceID: providerUtteranceID,
    revision: providerRevision,
    text: canonicalFullHypothesis,
    stability: .interim
))

if result.accepted, let output = result.output {
    render(output.displayText)
    if let committed = output.committedText { persist(committed) }
}
```

## Kotlin

```kotlin
import dev.naturalspacing.core.*

val session = OrderedTextUpdateSession(policy, OrderedTextSource.ASR)
check(session.start(providerUtteranceId)) { "empty utterance ID" }

val result = session.accept(OrderedTextUpdateEvent(
    providerUtteranceId,
    providerRevision,
    canonicalFullHypothesis,
    TextStability.INTERIM,
))

result.output?.takeIf { result.accepted }?.let { output ->
    render(output.displayText)
    output.committedText?.let(::persist)
}
```

## C#

```csharp
using NaturalSpacing.Core;

var session = new OrderedTextUpdateSession(policy, OrderedTextSource.Asr);
if (!session.Start(providerUtteranceId))
    throw new ArgumentException("Empty utterance ID.");

var result = session.Accept(new OrderedTextUpdateEvent(
    providerUtteranceId,
    providerRevision,
    canonicalFullHypothesis,
    TextStability.Interim));

if (result is { Accepted: true, Output: not null })
{
    Render(result.Output.DisplayText);
    if (result.Output.CommittedText is { } committed) Persist(committed);
}
```

## Dart and Flutter

```dart
import 'package:natural_spacing/natural_spacing.dart';

final session = OrderedTextUpdateSession(
  policy: policy,
  source: OrderedTextSource.asr,
);
if (!session.start(providerUtteranceId)) {
  throw ArgumentError.value(providerUtteranceId, 'providerUtteranceId');
}

final result = session.accept(OrderedTextUpdateEvent(
  utteranceId: providerUtteranceId,
  revision: providerRevision,
  text: canonicalFullHypothesis,
  stability: TextStability.interim,
));

final output = result.accepted ? result.output : null;
if (output != null) {
  render(output.displayText);
  final committed = output.committedText;
  if (committed != null) persist(committed);
}
```

## Provider boundary

The ordered API expects complete current hypotheses. If a provider explicitly guarantees append-only deltas, assemble them into one canonical hypothesis before formatting. Do not use an append-only buffer for providers that revise earlier words.

Provider integrations still need tests for reconnects, revision resets or wraparound, retries, error mapping, cancellation races, and the provider's exact finalization semantics. Treat provider text as sensitive: use synthetic transcripts in tests, and do not put hypothesis text in rejection telemetry.
