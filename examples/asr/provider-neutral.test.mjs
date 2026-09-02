import assert from "node:assert/strict";
import test from "node:test";

import {
  AppendOnlyAsrBuffer,
  formatFullAsrHypothesis,
  OrderedAsrHypothesisSession,
} from "./provider-neutral.mjs";

test("full hypotheses can revise interim text without committing it", () => {
  const first = formatFullAsrHypothesis({
    text: "支持mac",
    stability: "interim",
  });
  const revised = formatFullAsrHypothesis({
    text: "支持macOS和Windows",
    stability: "interim",
  });
  const final = formatFullAsrHypothesis({
    text: "支持macOS和Windows11系统",
    stability: "final",
  });

  assert.equal(first.displayText, "支持 mac");
  assert.equal(first.committedText, null);
  assert.equal(revised.displayText, "支持 macOS 和 Windows");
  assert.equal(revised.committedText, null);
  assert.equal(final.displayText, "支持 macOS 和 Windows11 系统");
  assert.equal(final.committedText, final.displayText);
});

test("append-only deltas are assembled before spacing", () => {
  const buffer = new AppendOnlyAsrBuffer();

  const interim = buffer.accept({ delta: "今天发布v", stability: "interim" });
  const final = buffer.accept({ delta: "2版本", stability: "final" });
  const nextUtterance = buffer.accept({ delta: "开始A计划", stability: "final" });

  assert.equal(interim.displayText, "今天发布 v");
  assert.equal(interim.committedText, null);
  assert.equal(final.displayText, "今天发布 v2 版本");
  assert.equal(final.committedText, final.displayText);
  assert.equal(nextUtterance.displayText, "开始 A 计划");
});

test("structured destinations can opt out explicitly", () => {
  const result = formatFullAsrHypothesis({
    text: "git中A",
    policy: "verbatim",
    stability: "final",
  });

  assert.equal(result.displayText, "git中A");
  assert.equal(result.committedText, "git中A");
});

test("revision-capable streams ignore duplicate and out-of-order hypotheses", () => {
  const session = new OrderedAsrHypothesisSession();
  session.start("utterance-1");

  const current = session.accept({
    utteranceId: "utterance-1",
    revision: 2,
    text: "支持mac",
    stability: "interim",
  });
  const stale = session.accept({
    utteranceId: "utterance-1",
    revision: 1,
    text: "旧文本A",
    stability: "interim",
  });
  const duplicate = session.accept({
    utteranceId: "utterance-1",
    revision: 2,
    text: "重复文本B",
    stability: "interim",
  });

  assert.equal(current.accepted, true);
  assert.equal(current.output.displayText, "支持 mac");
  assert.deepEqual(stale, {
    accepted: false,
    reason: "staleRevision",
    output: null,
  });
  assert.deepEqual(duplicate, stale);
});

test("final closes an utterance and cannot be overwritten by late events", () => {
  const session = new OrderedAsrHypothesisSession();
  session.start("utterance-1");

  const final = session.accept({
    utteranceId: "utterance-1",
    revision: 3,
    text: "发布v2版本",
    stability: "final",
  });
  const late = session.accept({
    utteranceId: "utterance-1",
    revision: 4,
    text: "迟到A",
    stability: "final",
  });

  assert.equal(final.accepted, true);
  assert.equal(final.output.committedText, "发布 v2 版本");
  assert.deepEqual(late, {
    accepted: false,
    reason: "inactiveUtterance",
    output: null,
  });
});

test("cancellation isolates the next utterance from a late final", () => {
  const session = new OrderedAsrHypothesisSession();
  session.start("utterance-1");
  session.accept({
    utteranceId: "utterance-1",
    revision: 0,
    text: "旧会话A",
    stability: "interim",
  });
  assert.equal(session.cancel("utterance-1"), true);

  session.start("utterance-2");
  const lateFinal = session.accept({
    utteranceId: "utterance-1",
    revision: 1,
    text: "不应提交B",
    stability: "final",
  });
  const nextFinal = session.accept({
    utteranceId: "utterance-2",
    revision: 0,
    text: "开始C计划",
    stability: "final",
  });

  assert.equal(lateFinal.accepted, false);
  assert.equal(lateFinal.reason, "inactiveUtterance");
  assert.equal(nextFinal.accepted, true);
  assert.equal(nextFinal.output.committedText, "开始 C 计划");
});
