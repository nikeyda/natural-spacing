import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];
const segmenter = new Intl.Segmenter("und", { granularity: "grapheme" });

function fail(location, message) {
  errors.push(`${location}: ${message}`);
}

function check(condition, location, message) {
  if (!condition) fail(location, message);
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

async function readJson(relativePath) {
  const source = await readFile(path.join(root, relativePath), "utf8");
  try {
    return JSON.parse(source);
  } catch (error) {
    fail(relativePath, `invalid JSON: ${error.message}`);
    return null;
  }
}

function checkUnicodeString(value, location) {
  check(typeof value === "string", location, "must be a string");
  if (typeof value !== "string") return;

  for (let index = 0; index < value.length; index += 1) {
    const unit = value.charCodeAt(index);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      const next = value.charCodeAt(index + 1);
      if (!(next >= 0xdc00 && next <= 0xdfff)) {
        fail(location, `contains an unpaired high surrogate at UTF-16 offset ${index}`);
      } else {
        index += 1;
      }
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      fail(location, `contains an unpaired low surrogate at UTF-16 offset ${index}`);
    }
  }
}

function graphemeBoundaries(text) {
  const result = new Set([0, text.length]);
  for (const part of segmenter.segment(text)) {
    result.add(part.index);
    result.add(part.index + part.segment.length);
  }
  return result;
}

function checkRange(range, text, location, requireNonEmpty = false) {
  check(isObject(range), location, "must be an object");
  if (!isObject(range)) return;

  const { start, length } = range;
  check(Number.isInteger(start) && start >= 0, `${location}.start`, "must be a non-negative integer");
  check(Number.isInteger(length) && length >= 0, `${location}.length`, "must be a non-negative integer");
  if (!Number.isInteger(start) || !Number.isInteger(length)) return;

  const end = start + length;
  check(end <= text.length, location, `range ends at ${end}, beyond UTF-16 length ${text.length}`);
  const boundaries = graphemeBoundaries(text);
  check(boundaries.has(start), `${location}.start`, "must be an extended grapheme boundary");
  check(boundaries.has(end), `${location}.end`, "must be an extended grapheme boundary");
  if (requireNonEmpty) check(length > 0, location, "active composition must be non-empty");
}

function checkSelection(selection, text, location) {
  check(isObject(selection), location, "must be an object");
  if (!isObject(selection)) return;

  const boundaries = graphemeBoundaries(text);
  for (const key of ["anchor", "focus"]) {
    const value = selection[key];
    check(Number.isInteger(value) && value >= 0, `${location}.${key}`, "must be a non-negative integer");
    if (Number.isInteger(value)) {
      check(value <= text.length, `${location}.${key}`, `must not exceed UTF-16 length ${text.length}`);
      check(boundaries.has(value), `${location}.${key}`, "must be an extended grapheme boundary");
    }
  }
}

function applyInsertions(text, insertions) {
  let result = text;
  for (const insertion of [...insertions].reverse()) {
    result = result.slice(0, insertion.offset) + insertion.text + result.slice(insertion.offset);
  }
  return result;
}

function mapEndpoint(endpoint, insertions) {
  return endpoint + insertions.reduce(
    (shift, insertion) => shift + (endpoint >= insertion.offset ? insertion.text.length : 0),
    0,
  );
}

function onlyAddsAsciiSpaces(input, expected) {
  let inputIndex = 0;
  let expectedIndex = 0;
  while (expectedIndex < expected.length) {
    if (inputIndex < input.length && input[inputIndex] === expected[expectedIndex]) {
      inputIndex += 1;
      expectedIndex += 1;
    } else if (expected[expectedIndex] === " ") {
      expectedIndex += 1;
    } else {
      return false;
    }
  }
  return inputIndex === input.length;
}

function checkUniqueIds(items, location) {
  const seen = new Set();
  for (const [index, item] of items.entries()) {
    const itemLocation = `${location}[${index}]`;
    check(isObject(item), itemLocation, "must be an object");
    if (!isObject(item)) continue;
    check(typeof item.id === "string" && item.id.length > 0, `${itemLocation}.id`, "must be a non-empty string");
    if (typeof item.id === "string") {
      check(!seen.has(item.id), `${itemLocation}.id`, `duplicate id ${item.id}`);
      seen.add(item.id);
    }
  }
}

function validateRules(document) {
  if (!document) return 0;
  check(document.schemaVersion === "1.0.0", "rules.schemaVersion", "must be 1.0.0");
  check(document.unicodeVersion === "17.0.0", "rules.unicodeVersion", "must be 17.0.0");
  check(Array.isArray(document.cases), "rules.cases", "must be an array");
  if (!Array.isArray(document.cases)) return 0;

  checkUniqueIds(document.cases, "rules.cases");
  for (const [index, fixture] of document.cases.entries()) {
    const location = `rules.cases[${index}]`;
    if (!isObject(fixture)) continue;
    check(["naturalLanguage", "verbatim"].includes(fixture.policy), `${location}.policy`, "has an unknown policy");
    checkUnicodeString(fixture.input, `${location}.input`);
    checkUnicodeString(fixture.expected, `${location}.expected`);
    check(Array.isArray(fixture.tags) && fixture.tags.every((tag) => typeof tag === "string"), `${location}.tags`, "must be an array of strings");
    if (typeof fixture.input === "string" && typeof fixture.expected === "string") {
      if (fixture.policy === "verbatim") {
        check(fixture.expected === fixture.input, location, "verbatim output must equal input");
      } else {
        check(onlyAddsAsciiSpaces(fixture.input, fixture.expected), location, "naturalLanguage output may only add U+0020");
      }
    }
  }

  return document.cases.length;
}

function validateExchange(exchange, location) {
  check(isObject(exchange), location, "must be an object");
  if (!isObject(exchange)) return;
  const snapshot = exchange.snapshot;
  const plan = exchange.expectedPlan;
  check(isObject(snapshot), `${location}.snapshot`, "must be an object");
  check(isObject(plan), `${location}.expectedPlan`, "must be an object");
  if (!isObject(snapshot) || !isObject(plan)) return;

  checkUnicodeString(snapshot.beforeText, `${location}.snapshot.beforeText`);
  checkUnicodeString(snapshot.afterUserText, `${location}.snapshot.afterUserText`);
  if (typeof snapshot.beforeText !== "string" || typeof snapshot.afterUserText !== "string") return;

  checkRange(snapshot.changedRange, snapshot.beforeText, `${location}.snapshot.changedRange`);
  checkSelection(snapshot.selection, snapshot.afterUserText, `${location}.snapshot.selection`);
  if (snapshot.composingRange !== null) {
    checkRange(snapshot.composingRange, snapshot.afterUserText, `${location}.snapshot.composingRange`, true);
  }

  check(["insert", "delete", "replace", "paste"].includes(snapshot.editKind), `${location}.snapshot.editKind`, "has an unknown edit kind");
  check(["naturalLanguage", "verbatim"].includes(snapshot.policy), `${location}.snapshot.policy`, "has an unknown policy");
  check(snapshot.maxLengthUtf16 === null || (Number.isInteger(snapshot.maxLengthUtf16) && snapshot.maxLengthUtf16 >= 0), `${location}.snapshot.maxLengthUtf16`, "must be null or a non-negative integer");

  if (isObject(snapshot.changedRange)) {
    const { start, length } = snapshot.changedRange;
    if (Number.isInteger(start) && Number.isInteger(length) && start + length <= snapshot.beforeText.length) {
      const prefix = snapshot.beforeText.slice(0, start);
      const suffix = snapshot.beforeText.slice(start + length);
      check(snapshot.afterUserText.startsWith(prefix), location, "afterUserText does not preserve the prefix outside changedRange");
      check(snapshot.afterUserText.endsWith(suffix), location, "afterUserText does not preserve the suffix outside changedRange");
    }
  }

  checkUnicodeString(plan.resultText, `${location}.expectedPlan.resultText`);
  checkSelection(plan.selection, plan.resultText, `${location}.expectedPlan.selection`);
  const decisions = ["applied", "noChange", "verbatim", "composing", "suppressed", "lengthLimited"];
  check(decisions.includes(plan.decision), `${location}.expectedPlan.decision`, "has an unknown decision");
  check(Array.isArray(plan.insertions), `${location}.expectedPlan.insertions`, "must be an array");
  if (!Array.isArray(plan.insertions) || typeof plan.resultText !== "string") return;

  let previousOffset = -1;
  const boundaries = graphemeBoundaries(snapshot.afterUserText);
  for (const [index, insertion] of plan.insertions.entries()) {
    const insertionLocation = `${location}.expectedPlan.insertions[${index}]`;
    check(isObject(insertion), insertionLocation, "must be an object");
    if (!isObject(insertion)) continue;
    check(Number.isInteger(insertion.offset), `${insertionLocation}.offset`, "must be an integer");
    if (Number.isInteger(insertion.offset)) {
      check(insertion.offset > previousOffset, `${insertionLocation}.offset`, "insertions must be strictly increasing");
      check(boundaries.has(insertion.offset), `${insertionLocation}.offset`, "must be an extended grapheme boundary");
      previousOffset = insertion.offset;
    }
    check(insertion.text === " ", `${insertionLocation}.text`, "must be U+0020");
    check(["hanLatin", "hanAsciiDigit"].includes(insertion.reason), `${insertionLocation}.reason`, "has an unknown reason");
  }

  check(applyInsertions(snapshot.afterUserText, plan.insertions) === plan.resultText, `${location}.expectedPlan.resultText`, "does not equal afterUserText with the declared insertions");
  if (isObject(snapshot.selection) && isObject(plan.selection)) {
    check(plan.selection.anchor === mapEndpoint(snapshot.selection.anchor, plan.insertions), `${location}.expectedPlan.selection.anchor`, "does not use downstream insertion affinity");
    check(plan.selection.focus === mapEndpoint(snapshot.selection.focus, plan.insertions), `${location}.expectedPlan.selection.focus`, "does not use downstream insertion affinity");
  }

  const noPatchDecisions = ["noChange", "verbatim", "composing", "suppressed", "lengthLimited"];
  if (plan.decision === "applied") check(plan.insertions.length > 0, `${location}.expectedPlan.decision`, "applied requires an insertion");
  if (noPatchDecisions.includes(plan.decision)) check(plan.insertions.length === 0, `${location}.expectedPlan.decision`, `${plan.decision} must not contain insertions`);
  if (plan.decision === "composing") check(snapshot.composingRange !== null, `${location}.expectedPlan.decision`, "composing requires an active composingRange");
  if (plan.decision === "verbatim") check(snapshot.policy === "verbatim", `${location}.expectedPlan.decision`, "verbatim requires verbatim policy");
  if (plan.decision === "lengthLimited") check(snapshot.maxLengthUtf16 !== null, `${location}.expectedPlan.decision`, "lengthLimited requires maxLengthUtf16");
  if (snapshot.maxLengthUtf16 !== null && plan.decision === "applied") {
    check(plan.resultText.length <= snapshot.maxLengthUtf16, `${location}.expectedPlan.resultText`, "exceeds maxLengthUtf16");
  }
}

function validateSessions(document) {
  if (!document) return { scenarios: 0, steps: 0 };
  check(document.schemaVersion === "1.0.0", "sessions.schemaVersion", "must be 1.0.0");
  check(document.offsetEncoding === "utf16", "sessions.offsetEncoding", "must be utf16");
  check(Array.isArray(document.scenarios), "sessions.scenarios", "must be an array");
  if (!Array.isArray(document.scenarios)) return { scenarios: 0, steps: 0 };

  checkUniqueIds(document.scenarios, "sessions.scenarios");
  let stepCount = 0;
  const editKinds = new Set();
  const decisions = new Set();
  const insertionReasons = new Set();
  const boundaryDirections = new Set();
  for (const [scenarioIndex, scenario] of document.scenarios.entries()) {
    const scenarioLocation = `sessions.scenarios[${scenarioIndex}]`;
    if (!isObject(scenario)) continue;
    check(Array.isArray(scenario.steps) && scenario.steps.length > 0, `${scenarioLocation}.steps`, "must be a non-empty array");
    if (!Array.isArray(scenario.steps)) continue;

    let previousResult = null;
    for (const [stepIndex, step] of scenario.steps.entries()) {
      stepCount += 1;
      const stepLocation = `${scenarioLocation}.steps[${stepIndex}]`;
      check(isObject(step), stepLocation, "must be an object");
      if (!isObject(step)) continue;
      validateExchange(step.exchange, `${stepLocation}.exchange`);
      const snapshot = step.exchange?.snapshot;
      const plan = step.exchange?.expectedPlan;
      if (isObject(snapshot) && typeof snapshot.editKind === "string") {
        editKinds.add(snapshot.editKind);
      }
      if (isObject(plan) && typeof plan.decision === "string") {
        decisions.add(plan.decision);
      }
      if (isObject(snapshot) && typeof snapshot.afterUserText === "string" && isObject(plan) && Array.isArray(plan.insertions)) {
        for (const insertion of plan.insertions) {
          if (!isObject(insertion)) continue;
          if (typeof insertion.reason === "string") insertionReasons.add(insertion.reason);
          if (Number.isInteger(insertion.offset)) {
            const direction = basicBoundaryDirection(snapshot.afterUserText, insertion.offset);
            if (direction !== null) boundaryDirections.add(direction);
          }
        }
      }
      const count = step.expectedSession?.suppressedBoundaryCount;
      check(Number.isInteger(count) && count >= 0, `${stepLocation}.expectedSession.suppressedBoundaryCount`, "must be a non-negative integer");
      const beforeText = step.exchange?.snapshot?.beforeText;
      if (previousResult !== null) {
        check(beforeText === previousResult, `${stepLocation}.exchange.snapshot.beforeText`, "must equal the previous step resultText");
      }
      previousResult = step.exchange?.expectedPlan?.resultText ?? null;
    }
  }

  for (const editKind of ["insert", "delete", "replace", "paste"]) {
    check(editKinds.has(editKind), `sessions.editKindCoverage.${editKind}`, "must have a step");
  }
  for (const decision of ["applied", "noChange", "verbatim", "composing", "suppressed", "lengthLimited"]) {
    check(decisions.has(decision), `sessions.decisionCoverage.${decision}`, "must have a step");
  }
  for (const reason of ["hanLatin", "hanAsciiDigit"]) {
    check(insertionReasons.has(reason), `sessions.insertionReasonCoverage.${reason}`, "must have an insertion");
  }
  for (const direction of ["han-latin", "latin-han", "han-digit", "digit-han"]) {
    check(boundaryDirections.has(direction), `sessions.boundaryDirectionCoverage.${direction}`, "must have an insertion");
  }
  return { scenarios: document.scenarios.length, steps: stepCount };
}

function basicBoundaryDirection(text, offset) {
  const left = Array.from(text.slice(0, offset)).at(-1);
  const right = Array.from(text.slice(offset)).at(0);
  const leftCategory = basicCoverageCategory(left);
  const rightCategory = basicCoverageCategory(right);
  if (leftCategory === null || rightCategory === null) return null;
  return `${leftCategory}-${rightCategory}`;
}

function basicCoverageCategory(character) {
  if (character === undefined) return null;
  if (/^[A-Za-z]$/.test(character)) return "latin";
  if (/^[0-9]$/.test(character)) return "digit";
  const scalar = character.codePointAt(0);
  return scalar >= 0x3400 && scalar <= 0x9fff ? "han" : null;
}

function validatePolicies(document) {
  if (!document) return 0;
  check(document.schemaVersion === "1.0.0", "policies.schemaVersion", "must be 1.0.0");
  check(Array.isArray(document.cases), "policies.cases", "must be an array");
  if (!Array.isArray(document.cases)) return 0;
  checkUniqueIds(document.cases, "policies.cases");

  for (const [index, fixture] of document.cases.entries()) {
    const location = `policies.cases[${index}]`;
    if (!isObject(fixture)) continue;
    check(isObject(fixture.context), `${location}.context`, "must be an object");
    check(isObject(fixture.expected), `${location}.expected`, "must be an object");
    if (!isObject(fixture.context) || !isObject(fixture.expected)) continue;
    const expected = fixture.expected;
    check(["naturalLanguage", "verbatim"].includes(expected.policy), `${location}.expected.policy`, "has an unknown policy");
    check(["high", "medium", "low"].includes(expected.confidence), `${location}.expected.confidence`, "has an unknown confidence");
    check(["explicit", "safety", "contentKind", "textHeuristic", "fallback"].includes(expected.source), `${location}.expected.source`, "has an unknown source");
    check(typeof expected.reason === "string" && expected.reason.length > 0, `${location}.expected.reason`, "must be a non-empty string");
    check(typeof expected.autoApply === "boolean", `${location}.expected.autoApply`, "must be a boolean");
    if (expected.source === "textHeuristic") {
      check(expected.autoApply === false, `${location}.expected.autoApply`, "text heuristics must not auto-apply");
    }
    const isSecure = fixture.context.isSecure === true || fixture.context.contentKind === "password";
    if (fixture.context.explicitPolicy !== undefined && !isSecure) {
      check(expected.policy === fixture.context.explicitPolicy, location, "explicit policy must win outside secure content");
    }
    if (isSecure) {
      check(expected.policy === "verbatim", location, "secure content must be verbatim");
      check(expected.source === "safety", location, "secure content must report the safety source");
      check(expected.reason === "secureContent", location, "secure content must report the secureContent reason");
      check(expected.autoApply === true, location, "secure content must auto-apply verbatim");
    }
  }

  const semanticExpectations = {
    prose: ["naturalLanguage", "contentKind", "naturalLanguageContent"],
    title: ["naturalLanguage", "contentKind", "naturalLanguageContent"],
    message: ["naturalLanguage", "contentKind", "naturalLanguageContent"],
    note: ["naturalLanguage", "contentKind", "naturalLanguageContent"],
    document: ["naturalLanguage", "contentKind", "naturalLanguageContent"],
    transcript: ["naturalLanguage", "contentKind", "naturalLanguageContent"],
    asrTranscript: ["naturalLanguage", "contentKind", "naturalLanguageContent"],
    code: ["verbatim", "contentKind", "structuredContent"],
    identifier: ["verbatim", "contentKind", "structuredContent"],
    url: ["verbatim", "contentKind", "structuredContent"],
    email: ["verbatim", "contentKind", "structuredContent"],
    password: ["verbatim", "safety", "secureContent"],
    token: ["verbatim", "contentKind", "structuredContent"],
    filePath: ["verbatim", "contentKind", "structuredContent"],
    command: ["verbatim", "contentKind", "structuredContent"],
    number: ["verbatim", "contentKind", "structuredContent"],
  };
  const supportedKinds = new Set([
    ...Object.keys(semanticExpectations),
    "searchQuery",
    "unknown",
  ]);

  for (const [index, fixture] of document.cases.entries()) {
    const kind = fixture?.context?.contentKind;
    if (kind !== undefined) {
      check(supportedKinds.has(kind), `policies.cases[${index}].context.contentKind`, "has an unknown content kind");
    }
  }

  for (const [kind, [policy, source, reason]] of Object.entries(semanticExpectations)) {
    const fixture = document.cases.find(
      (candidate) =>
        isObject(candidate) &&
        isObject(candidate.context) &&
        candidate.context.contentKind === kind &&
        candidate.context.explicitPolicy === undefined &&
        candidate.context.isSecure !== true,
    );
    check(fixture !== undefined, `policies.semanticCoverage.${kind}`, "must have a direct semantic fixture");
    if (!isObject(fixture) || !isObject(fixture.expected)) continue;
    check(fixture.expected.policy === policy, `policies.semanticCoverage.${kind}.policy`, `must be ${policy}`);
    check(fixture.expected.confidence === "high", `policies.semanticCoverage.${kind}.confidence`, "must be high");
    check(fixture.expected.source === source, `policies.semanticCoverage.${kind}.source`, `must be ${source}`);
    check(fixture.expected.reason === reason, `policies.semanticCoverage.${kind}.reason`, `must be ${reason}`);
    check(fixture.expected.autoApply === true, `policies.semanticCoverage.${kind}.autoApply`, "must be true");
  }

  return document.cases.length;
}

function validateTextUpdates(document) {
  if (!document) return 0;
  check(document.schemaVersion === "1.0.0", "textUpdates.schemaVersion", "must be 1.0.0");
  check(Array.isArray(document.cases), "textUpdates.cases", "must be an array");
  if (!Array.isArray(document.cases)) return 0;
  checkUniqueIds(document.cases, "textUpdates.cases");

  for (const [index, fixture] of document.cases.entries()) {
    const location = `textUpdates.cases[${index}]`;
    if (!isObject(fixture)) continue;
    check(isObject(fixture.update), `${location}.update`, "must be an object");
    check(isObject(fixture.expected), `${location}.expected`, "must be an object");
    if (!isObject(fixture.update) || !isObject(fixture.expected)) continue;
    const update = fixture.update;
    const expected = fixture.expected;
    checkUnicodeString(update.text, `${location}.update.text`);
    checkUnicodeString(expected.displayText, `${location}.expected.displayText`);
    check(["naturalLanguage", "verbatim"].includes(update.policy), `${location}.update.policy`, "has an unknown policy");
    check(["asr", "dictation", "imported", "generated"].includes(update.source), `${location}.update.source`, "has an unknown source");
    check(["interim", "final"].includes(update.stability), `${location}.update.stability`, "has an unknown stability");
    check(expected.policy === update.policy, location, "expected policy must preserve update policy");
    check(expected.source === update.source, location, "expected source must preserve update source");
    check(expected.stability === update.stability, location, "expected stability must preserve update stability");
    if (typeof update.text === "string" && typeof expected.displayText === "string") {
      check(expected.changed === (update.text !== expected.displayText), `${location}.expected.changed`, "does not match the text difference");
      check(onlyAddsAsciiSpaces(update.text, expected.displayText), location, "display text may only add U+0020");
      if (update.policy === "verbatim") {
        check(expected.displayText === update.text, location, "verbatim display text must be unchanged");
      }
    }
    if (update.stability === "interim") {
      check(expected.committedText === null, `${location}.expected.committedText`, "interim text must not be committed");
    } else {
      check(expected.committedText === expected.displayText, `${location}.expected.committedText`, "final committed text must equal display text");
    }
  }

  for (const source of ["asr", "dictation", "imported", "generated"]) {
    check(
      document.cases.some((fixture) => fixture?.update?.source === source),
      `textUpdates.sourceCoverage.${source}`,
      "must have a fixture",
    );
  }
  for (const policy of ["naturalLanguage", "verbatim"]) {
    for (const stability of ["interim", "final"]) {
      check(
        document.cases.some(
          (fixture) =>
            fixture?.update?.source === "asr" &&
            fixture.update.policy === policy &&
            fixture.update.stability === stability,
        ),
        `textUpdates.asrCoverage.${policy}.${stability}`,
        "must have an ASR fixture",
      );
    }
  }
  return document.cases.length;
}

function validateOrderedTextSessions(document) {
  if (!document) return { scenarios: 0, operations: 0 };
  check(document.schemaVersion === "1.0.0", "orderedTextSessions.schemaVersion", "must be 1.0.0");
  check(Array.isArray(document.scenarios), "orderedTextSessions.scenarios", "must be an array");
  if (!Array.isArray(document.scenarios)) return { scenarios: 0, operations: 0 };
  checkUniqueIds(document.scenarios, "orderedTextSessions.scenarios");

  let operationCount = 0;
  const kinds = new Set();
  const reasons = new Set();
  const policies = new Set();
  const sources = new Set();
  const stabilities = new Set();
  const startResults = new Set();
  const cancelResults = new Set();

  for (const [scenarioIndex, scenario] of document.scenarios.entries()) {
    const scenarioLocation = `orderedTextSessions.scenarios[${scenarioIndex}]`;
    if (!isObject(scenario)) continue;
    check(["naturalLanguage", "verbatim"].includes(scenario.policy), `${scenarioLocation}.policy`, "has an unknown policy");
    check(["asr", "dictation"].includes(scenario.source), `${scenarioLocation}.source`, "must be asr or dictation");
    if (typeof scenario.policy === "string") policies.add(scenario.policy);
    if (typeof scenario.source === "string") sources.add(scenario.source);
    check(Array.isArray(scenario.operations) && scenario.operations.length > 0, `${scenarioLocation}.operations`, "must be a non-empty array");
    if (!Array.isArray(scenario.operations)) continue;

    for (const [operationIndex, operation] of scenario.operations.entries()) {
      operationCount += 1;
      const location = `${scenarioLocation}.operations[${operationIndex}]`;
      check(isObject(operation), location, "must be an object");
      if (!isObject(operation)) continue;
      check(["start", "accept", "cancel"].includes(operation.kind), `${location}.kind`, "has an unknown operation kind");
      if (typeof operation.kind === "string") kinds.add(operation.kind);
      check(isObject(operation.expected), `${location}.expected`, "must be an object");
      if (!isObject(operation.expected)) continue;

      if (operation.kind === "start") {
        check(typeof operation.utteranceId === "string", `${location}.utteranceId`, "must be a string");
        check(typeof operation.expected.started === "boolean", `${location}.expected.started`, "must be a boolean");
        if (typeof operation.expected.started === "boolean") startResults.add(operation.expected.started);
        if (operation.expected.started === true) {
          check(operation.utteranceId.length > 0, `${location}.utteranceId`, "successful start requires a non-empty ID");
        }
        continue;
      }

      if (operation.kind === "cancel") {
        check(typeof operation.utteranceId === "string", `${location}.utteranceId`, "must be a string");
        check(typeof operation.expected.cancelled === "boolean", `${location}.expected.cancelled`, "must be a boolean");
        if (typeof operation.expected.cancelled === "boolean") cancelResults.add(operation.expected.cancelled);
        continue;
      }

      if (operation.kind !== "accept") continue;
      check(isObject(operation.event), `${location}.event`, "must be an object");
      if (!isObject(operation.event)) continue;
      const event = operation.event;
      const expected = operation.expected;
      check(typeof event.utteranceId === "string" && event.utteranceId.length > 0, `${location}.event.utteranceId`, "must be a non-empty string");
      check(Number.isSafeInteger(event.revision), `${location}.event.revision`, "must be a safe integer");
      checkUnicodeString(event.text, `${location}.event.text`);
      check(["interim", "final"].includes(event.stability), `${location}.event.stability`, "has an unknown stability");
      if (typeof event.stability === "string") stabilities.add(event.stability);
      check(typeof expected.accepted === "boolean", `${location}.expected.accepted`, "must be a boolean");
      check(["accepted", "inactiveUtterance", "staleRevision", "invalidRevision"].includes(expected.reason), `${location}.expected.reason`, "has an unknown reason");
      if (typeof expected.reason === "string") reasons.add(expected.reason);

      if (expected.accepted === true) {
        check(expected.reason === "accepted", `${location}.expected.reason`, "accepted result must use accepted reason");
        check(isObject(expected.output), `${location}.expected.output`, "accepted result must contain output");
      } else {
        check(expected.reason !== "accepted", `${location}.expected.reason`, "rejected result cannot use accepted reason");
        check(expected.output === null, `${location}.expected.output`, "rejected result must not contain output");
      }
      if (expected.reason === "invalidRevision") {
        check(event.revision < 0, `${location}.event.revision`, "invalidRevision fixture must use a negative revision");
      }

      if (!isObject(expected.output)) continue;
      const output = expected.output;
      checkUnicodeString(output.displayText, `${location}.expected.output.displayText`);
      check(output.policy === scenario.policy, `${location}.expected.output.policy`, "must preserve the session policy");
      check(output.source === scenario.source, `${location}.expected.output.source`, "must preserve the session source");
      check(output.stability === event.stability, `${location}.expected.output.stability`, "must preserve event stability");
      if (typeof event.text === "string" && typeof output.displayText === "string") {
        check(output.changed === (event.text !== output.displayText), `${location}.expected.output.changed`, "does not match the text difference");
        check(onlyAddsAsciiSpaces(event.text, output.displayText), location, "display text may only add U+0020");
        if (scenario.policy === "verbatim") {
          check(output.displayText === event.text, location, "verbatim output must be unchanged");
        }
      }
      if (event.stability === "interim") {
        check(output.committedText === null, `${location}.expected.output.committedText`, "interim output must not be committed");
      } else {
        check(output.committedText === output.displayText, `${location}.expected.output.committedText`, "final committed text must equal display text");
      }
    }
  }

  for (const kind of ["start", "accept", "cancel"]) {
    check(kinds.has(kind), `orderedTextSessions.operationCoverage.${kind}`, "must have an operation");
  }
  for (const reason of ["accepted", "inactiveUtterance", "staleRevision", "invalidRevision"]) {
    check(reasons.has(reason), `orderedTextSessions.reasonCoverage.${reason}`, "must have an accept result");
  }
  for (const policy of ["naturalLanguage", "verbatim"]) {
    check(policies.has(policy), `orderedTextSessions.policyCoverage.${policy}`, "must have a scenario");
  }
  for (const source of ["asr", "dictation"]) {
    check(sources.has(source), `orderedTextSessions.sourceCoverage.${source}`, "must have a scenario");
  }
  for (const stability of ["interim", "final"]) {
    check(stabilities.has(stability), `orderedTextSessions.stabilityCoverage.${stability}`, "must have an event");
  }
  for (const result of [true, false]) {
    check(startResults.has(result), `orderedTextSessions.startCoverage.${result}`, "must have a start result");
    check(cancelResults.has(result), `orderedTextSessions.cancelCoverage.${result}`, "must have a cancel result");
  }

  return { scenarios: document.scenarios.length, operations: operationCount };
}

function validateUnicodeSources(document) {
  if (!document) return 0;
  check(document.unicodeVersion === "17.0.0", "unicode.unicodeVersion", "must be 17.0.0");
  check(Array.isArray(document.files), "unicode.files", "must be an array");
  if (!Array.isArray(document.files)) return 0;
  const required = new Set([
    "Scripts.txt",
    "ScriptExtensions.txt",
    "PropList.txt",
    "UnicodeData.txt",
    "GraphemeBreakProperty.txt",
    "GraphemeBreakTest.txt",
    "emoji-data.txt",
  ]);
  for (const [index, file] of document.files.entries()) {
    const location = `unicode.files[${index}]`;
    check(isObject(file), location, "must be an object");
    if (!isObject(file)) continue;
    required.delete(file.name);
    check(typeof file.url === "string" && file.url.includes("/17.0.0/"), `${location}.url`, "must be a pinned Unicode 17.0.0 URL");
    check(Number.isInteger(file.bytes) && file.bytes > 0, `${location}.bytes`, "must be a positive integer");
    check(typeof file.sha256 === "string" && /^[0-9a-f]{64}$/.test(file.sha256), `${location}.sha256`, "must be a lowercase SHA-256 digest");
  }
  check(required.size === 0, "unicode.files", `missing required files: ${[...required].join(", ")}`);
  return document.files.length;
}

function validateUnicodeRanges(document) {
  if (!document) return 0;
  check(document.unicodeVersion === "17.0.0", "unicodeRanges.unicodeVersion", "must be 17.0.0");
  check(Array.isArray(document.generatedFrom), "unicodeRanges.generatedFrom", "must be an array");
  const requiredSources = ["Scripts.txt", "ScriptExtensions.txt", "PropList.txt", "UnicodeData.txt"];
  if (Array.isArray(document.generatedFrom)) {
    check(
      JSON.stringify(document.generatedFrom) === JSON.stringify(requiredSources),
      "unicodeRanges.generatedFrom",
      `must equal ${JSON.stringify(requiredSources)}`,
    );
  }
  check(isObject(document.definitions), "unicodeRanges.definitions", "must be an object");
  check(isObject(document.ranges), "unicodeRanges.ranges", "must be an object");
  if (!isObject(document.ranges)) return 0;

  let rangeCount = 0;
  for (const name of ["latin", "han", "mark", "whiteSpace"]) {
    const ranges = document.ranges[name];
    const location = `unicodeRanges.ranges.${name}`;
    check(Array.isArray(ranges), location, "must be an array");
    if (!Array.isArray(ranges)) continue;
    let previousEnd = -2;
    for (const [index, range] of ranges.entries()) {
      const rangeLocation = `${location}[${index}]`;
      check(Array.isArray(range) && range.length === 2, rangeLocation, "must be a [start, end] pair");
      if (!Array.isArray(range) || range.length !== 2) continue;
      const [start, end] = range;
      check(Number.isInteger(start) && start >= 0, `${rangeLocation}[0]`, "must be a non-negative integer");
      check(Number.isInteger(end) && end <= 0x10ffff, `${rangeLocation}[1]`, "must not exceed U+10FFFF");
      if (!Number.isInteger(start) || !Number.isInteger(end)) continue;
      check(start <= end, rangeLocation, "start must not exceed end");
      check(start > previousEnd + 1, rangeLocation, "ranges must be sorted, disjoint, and maximally compressed");
      previousEnd = end;
      rangeCount += 1;
    }
  }
  return rangeCount;
}

function validateGraphemeSegmentation(document) {
  if (!document) return 0;
  check(document.unicodeVersion === "17.0.0", "grapheme.unicodeVersion", "must be 17.0.0");
  check(
    JSON.stringify(document.sourcePackage) === JSON.stringify({
      name: "unicode-segmenter",
      version: "0.17.3",
      license: "MIT",
    }),
    "grapheme.sourcePackage",
    "must identify unicode-segmenter 0.17.3 under the MIT license",
  );

  const expectedCategories = {
    any: 0,
    cr: 1,
    control: 2,
    extend: 3,
    extendedPictographic: 4,
    l: 5,
    lf: 6,
    lv: 7,
    lvt: 8,
    prepend: 9,
    regionalIndicator: 10,
    spacingMark: 11,
    t: 12,
    v: 13,
    zwj: 14,
    indicConsonant: 15,
  };
  check(
    JSON.stringify(document.categories) === JSON.stringify(expectedCategories),
    "grapheme.categories",
    "must match the pinned category map",
  );

  check(Array.isArray(document.ranges), "grapheme.ranges", "must be an array");
  if (Array.isArray(document.ranges)) {
    let previousEnd = -1;
    let previousCategory = -1;
    for (const [index, range] of document.ranges.entries()) {
      const location = `grapheme.ranges[${index}]`;
      check(Array.isArray(range) && range.length === 3, location, "must be a [start, end, category] triple");
      if (!Array.isArray(range) || range.length !== 3) continue;
      const [start, end, category] = range;
      check(Number.isInteger(start) && start >= 0, `${location}[0]`, "must be a non-negative integer");
      check(Number.isInteger(end) && end <= 0x10ffff, `${location}[1]`, "must not exceed U+10FFFF");
      check(Number.isInteger(category) && category >= 1 && category <= 15, `${location}[2]`, "must be a category from 1 through 15");
      if (!Number.isInteger(start) || !Number.isInteger(end) || !Number.isInteger(category)) continue;
      check(start <= end, location, "start must not exceed end");
      check(start > previousEnd, location, "ranges must be sorted and disjoint");
      check(
        start !== previousEnd + 1 || category !== previousCategory,
        location,
        "adjacent ranges with the same category must be compressed",
      );
      previousEnd = end;
      previousCategory = category;
    }
  }

  check(Array.isArray(document.pairMasks) && document.pairMasks.length === 256, "grapheme.pairMasks", "must contain 256 entries");
  if (Array.isArray(document.pairMasks)) {
    for (const [index, mask] of document.pairMasks.entries()) {
      check([0, 1, 2, 4, 8].includes(mask), `grapheme.pairMasks[${index}]`, "must be a known state mask");
    }
  }

  check(Array.isArray(document.linkers), "grapheme.linkers", "must be an array");
  if (Array.isArray(document.linkers)) {
    let previous = -1;
    for (const [index, codePoint] of document.linkers.entries()) {
      const location = `grapheme.linkers[${index}]`;
      check(Number.isInteger(codePoint) && codePoint >= 0 && codePoint <= 0x10ffff, location, "must be a Unicode scalar value");
      if (!Number.isInteger(codePoint)) continue;
      check(codePoint > previous, location, "must be sorted and unique");
      check(!(codePoint >= 0xd800 && codePoint <= 0xdfff), location, "must not be a surrogate");
      previous = codePoint;
    }
  }

  return Array.isArray(document.ranges) ? document.ranges.length : 0;
}

function validateSchema(document) {
  if (!document) return;
  check(document.$schema === "https://json-schema.org/draft/2020-12/schema", "schema.$schema", "must use JSON Schema 2020-12");
  check(isObject(document.$defs), "schema.$defs", "must define reusable contract types");
  for (const name of ["range", "selection", "editSnapshot", "insertion", "editPlan"]) {
    check(isObject(document.$defs?.[name]), `schema.$defs.${name}`, "is required");
  }
}

const [schema, rules, sessions, policies, textUpdates, orderedTextSessions, unicode, unicodeRanges, graphemeSegmentation] = await Promise.all([
  readJson("spec/edit-contract.schema.json"),
  readJson("spec/fixtures/rules-v1.json"),
  readJson("spec/fixtures/sessions-v1.json"),
  readJson("spec/fixtures/policy-v1.json"),
  readJson("spec/fixtures/text-updates-v1.json"),
  readJson("spec/fixtures/ordered-text-sessions-v1.json"),
  readJson("spec/unicode/17.0.0/sources.json"),
  readJson("spec/unicode/17.0.0/classification-ranges.json"),
  readJson("spec/unicode/17.0.0/grapheme-segmentation.json"),
]);

validateSchema(schema);
const ruleCount = validateRules(rules);
const sessionCount = validateSessions(sessions);
const policyCount = validatePolicies(policies);
const textUpdateCount = validateTextUpdates(textUpdates);
const orderedTextSessionCount = validateOrderedTextSessions(orderedTextSessions);
const unicodeFileCount = validateUnicodeSources(unicode);
const unicodeRangeCount = validateUnicodeRanges(unicodeRanges);
const graphemeRangeCount = validateGraphemeSegmentation(graphemeSegmentation);

if (errors.length > 0) {
  console.error(`Specification validation failed with ${errors.length} error(s):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exitCode = 1;
} else {
  console.log(
    `Specification valid: ${ruleCount} rule fixtures, ${sessionCount.scenarios} session scenarios, ` +
      `${sessionCount.steps} session steps, ${policyCount} policy fixtures, ` +
      `${textUpdateCount} text-update fixtures, ${orderedTextSessionCount.scenarios} ordered text-update scenarios, ` +
      `${orderedTextSessionCount.operations} ordered text-update operations, ${unicodeFileCount} pinned Unicode files, ` +
      `${unicodeRangeCount} generated classification ranges, ` +
      `${graphemeRangeCount} generated grapheme ranges.`,
  );
}
