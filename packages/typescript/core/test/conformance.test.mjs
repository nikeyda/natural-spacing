import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import test from "node:test";

import {
  classifyGrapheme,
  formatTextUpdate,
  NaturalSpacingSession,
  OrderedTextUpdateSession,
  UNICODE_VERSION,
  normalizeNaturalLanguage,
  planProposedEdit,
  proposedEditReplacingDifference,
  recommendPolicy,
  resolvePolicy,
  segmentText,
} from "../dist/index.js";

const rules = await readFixture("../../../../spec/fixtures/rules-v1.json");
const sessions = await readFixture("../../../../spec/fixtures/sessions-v1.json");
const policies = await readFixture("../../../../spec/fixtures/policy-v1.json");
const textUpdates = await readFixture("../../../../spec/fixtures/text-updates-v1.json");
const orderedTextSessions = await readFixture("../../../../spec/fixtures/ordered-text-sessions-v1.json");
const unicodeSources = await readFixture("../../../../spec/unicode/17.0.0/sources.json");
const graphemeBreakTestBytes = await readFile(
  new URL("../../../../spec/unicode/17.0.0/GraphemeBreakTest.txt", import.meta.url),
);

test("core exposes the pinned Unicode version", () => {
  assert.equal(UNICODE_VERSION, "17.0.0");
});

test("generated Unicode tables enforce the v1 category profile", () => {
  assert.equal(classifyGrapheme("K"), "Latin", "Kelvin sign is a Latin letter");
  assert.equal(classifyGrapheme("〡"), "Han", "Hangzhou numeral one is Han Nl");
  assert.equal(classifyGrapheme("˗"), "Other", "Latin Script_Extensions alone does not admit a symbol");
  assert.equal(classifyGrapheme("\u0363"), "Other", "a mark-only grapheme has no base");
  assert.equal(classifyGrapheme("\u202f"), "Whitespace", "White_Space takes precedence");
});

test("vendored Unicode grapheme tests match pinned source metadata", () => {
  const metadata = unicodeSources.files.find((item) => item.name === "GraphemeBreakTest.txt");
  assert.ok(metadata);
  assert.equal(graphemeBreakTestBytes.length, metadata.bytes);
  assert.equal(
    createHash("sha256").update(graphemeBreakTestBytes).digest("hex"),
    metadata.sha256,
  );
});

test("segmenter passes Unicode 17 GraphemeBreakTest", () => {
  let caseCount = 0;
  const lines = graphemeBreakTestBytes.toString("utf8").split(/\r?\n/u);
  for (const [index, rawLine] of lines.entries()) {
    const sequence = rawLine.replace(/#.*$/u, "").trim();
    if (!sequence.startsWith("÷")) continue;

    let value = "";
    const expectedBoundaries = [];
    for (const token of sequence.split(/\s+/u)) {
      if (token === "÷") expectedBoundaries.push(value.length);
      else if (token !== "×") value += String.fromCodePoint(Number.parseInt(token, 16));
    }
    const actualBoundaries = [0, ...segmentText(value).map((grapheme) => grapheme.end)];
    assert.deepEqual(actualBoundaries, expectedBoundaries, `GraphemeBreakTest line ${index + 1}`);
    caseCount += 1;
  }
  assert.equal(caseCount, 766);
});

for (const fixture of rules.cases) {
  test(`rule: ${fixture.id}`, () => {
    const result = normalizeNaturalLanguage(fixture.input, fixture.policy);
    assert.equal(result, fixture.expected);
    assert.equal(normalizeNaturalLanguage(result, fixture.policy), result, "must be idempotent");
  });
}

for (const scenario of sessions.scenarios) {
  test(`session: ${scenario.id}`, () => {
    const session = new NaturalSpacingSession();
    for (const [index, step] of scenario.steps.entries()) {
      const actual = session.process(step.exchange.snapshot);
      assert.deepEqual(actual, step.exchange.expectedPlan, `step ${index + 1} edit plan`);
      assert.equal(
        session.suppressedBoundaryCount,
        step.expectedSession.suppressedBoundaryCount,
        `step ${index + 1} suppression count`,
      );
    }
  });
}

for (const fixture of policies.cases) {
  test(`policy: ${fixture.id}`, () => {
    assert.deepEqual(recommendPolicy(fixture.context), fixture.expected);
    assert.equal(
      resolvePolicy(fixture.context),
      fixture.expected.autoApply ? fixture.expected.policy : "verbatim",
      "automatic resolution must fall back when recommendation is advisory",
    );
    if (fixture.id === "search-query-is-a-recommendation") {
      assert.equal(resolvePolicy(fixture.context, "naturalLanguage"), "naturalLanguage");
    }
  });
}

for (const fixture of textUpdates.cases) {
  test(`text update: ${fixture.id}`, () => {
    const result = formatTextUpdate(fixture.update);
    assert.deepEqual(result, fixture.expected);
    if (fixture.update.stability === "final") {
      assert.equal(
        formatTextUpdate({ ...fixture.update, text: result.displayText }).displayText,
        result.displayText,
        "final formatting must be idempotent",
      );
    } else {
      assert.equal(result.committedText, null, "interim text must not be committed");
    }
  });
}

for (const scenario of orderedTextSessions.scenarios) {
  test(`ordered text session: ${scenario.id}`, () => {
    const session = new OrderedTextUpdateSession({
      policy: scenario.policy,
      source: scenario.source,
    });
    for (const [index, operation] of scenario.operations.entries()) {
      if (operation.kind === "start") {
        assert.equal(
          session.start(operation.utteranceId),
          operation.expected.started,
          `operation ${index + 1} start`,
        );
      } else if (operation.kind === "cancel") {
        assert.equal(
          session.cancel(operation.utteranceId),
          operation.expected.cancelled,
          `operation ${index + 1} cancel`,
        );
      } else {
        assert.deepEqual(
          session.accept(operation.event),
          operation.expected,
          `operation ${index + 1} accept`,
        );
      }
    }
  });
}

test("secure recommendation returns before reading text", () => {
  const context = {
    isSecure: true,
    get text() {
      throw new Error("secure text must not be inspected");
    },
  };
  assert.equal(recommendPolicy(context).reason, "secureContent");
});

test("explicit recommendation returns before reading text", () => {
  const context = {
    explicitPolicy: "naturalLanguage",
    get text() {
      throw new Error("explicit policy must not inspect text");
    },
  };
  assert.equal(recommendPolicy(context).reason, "explicitPolicy");
});

test("reset and policy changes clear deletion suppressions", () => {
  const session = new NaturalSpacingSession();
  const deletion = {
    beforeText: "中 A",
    afterUserText: "中A",
    changedRange: { start: 1, length: 1 },
    selection: { anchor: 1, focus: 1 },
    composingRange: null,
    editKind: "delete",
    policy: "naturalLanguage",
    maxLengthUtf16: null,
  };

  assert.equal(session.process(deletion).decision, "suppressed");
  assert.equal(session.suppressedBoundaryCount, 1);
  session.reset();
  assert.equal(session.suppressedBoundaryCount, 0);

  assert.equal(session.process(deletion).decision, "suppressed");
  assert.equal(
    session.process({
      ...deletion,
      beforeText: "中A",
      afterUserText: "中B",
      changedRange: { start: 1, length: 1 },
      editKind: "replace",
      policy: "verbatim",
    }).decision,
    "verbatim",
  );
  assert.equal(session.suppressedBoundaryCount, 0);
});

test("proposed edit returns a native replacement fragment", () => {
  const result = planProposedEdit({
    text: "中文",
    range: { start: 1, length: 0 },
    replacementText: "A",
    composingRange: null,
    editKind: "insert",
    policy: "naturalLanguage",
    maxLengthUtf16: null,
  });

  assert.equal(result.replacementText, " A ");
  assert.equal(result.plan.resultText, "中 A 文");
  assert.deepEqual(result.plan.selection, { anchor: 4, focus: 4 });
  assert.equal(result.requiresReplacement, true);
});

test("proposed edit finds a minimal UTF-16 difference", () => {
  const edit = proposedEditReplacingDifference({
    beforeText: "中🙂文",
    afterText: "中🙂A文",
    selectionAfterEdit: { anchor: 4, focus: 4 },
    policy: "naturalLanguage",
  });

  assert.deepEqual(edit?.range, { start: 3, length: 0 });
  assert.equal(edit?.replacementText, "A");
  assert.equal(edit?.editKind, "insert");
  assert.equal(
    proposedEditReplacingDifference({
      beforeText: "相同",
      afterText: "相同",
      policy: "naturalLanguage",
    }),
    null,
  );
});

test("proposed edit rejects an invalid UTF-16 range", () => {
  assert.throws(
    () =>
      planProposedEdit({
        text: "中",
        range: { start: 2, length: 0 },
        replacementText: "A",
        composingRange: null,
        editKind: "insert",
        policy: "naturalLanguage",
        maxLengthUtf16: null,
      }),
    RangeError,
  );
});

async function readFixture(relativePath) {
  return JSON.parse(await readFile(new URL(relativePath, import.meta.url), "utf8"));
}
