# Provider-neutral ASR example

ASR providers generally expose one of two stream shapes:

- a complete current hypothesis on every callback, where later interim values may revise earlier text;
- provider-documented append-only deltas.

Always assemble the canonical full hypothesis before spacing it. `formatFullAsrHypothesis` accepts full interim/final values. `OrderedAsrHypothesisSession` is an example-facing alias of the core `OrderedTextUpdateSession`, which also exists in Swift, Kotlin, C#, and Dart. It adds explicit utterance identity, monotonically increasing revision handling, final closure, and cancellation for revision-capable full-hypothesis streams. `AppendOnlyAsrBuffer` is deliberately named and limited to providers that guarantee append-only deltas; do not use it for revision-capable streams.

For an ordered full-hypothesis stream:

```js
const session = new OrderedAsrHypothesisSession();
session.start(providerUtteranceId);

const accepted = session.accept({
  utteranceId: providerUtteranceId,
  revision: providerSequence,
  text: canonicalFullHypothesis,
  stability: "interim",
});
```

The provider integration must use a unique ID per utterance and map its ordering primitive to a non-negative, monotonically increasing integer. Duplicate or older revisions, events for inactive utterances, and events arriving after final/cancel are ignored. Starting a new utterance replaces the active identity; call `cancel` explicitly when the provider reports cancellation.

Interim output is for display only and returns `committedText: null`. Persist or publish text only after a final event returns a committed value. Use `.verbatim` explicitly for code, commands, identifiers, URLs, or other structured destinations.

```sh
npm run test:asr
```

The example does not log audio, hypotheses, or transcripts. The ordered session retains only the active utterance ID and latest revision, never hypothesis text. Production integrations should preserve that privacy boundary and add provider-specific retry, reconnect, sequence-wrap, and error-mapping tests.
