import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const unicodeVersion = "17.0.0";
const maximumCodePoint = 0x10ffff;
const scriptBit = { latin: 1, han: 2 };
const categoryBit = { letter: 1, hanEligible: 2, mark: 4 };

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const artifactPath = join(
  repositoryRoot,
  "spec",
  "unicode",
  unicodeVersion,
  "classification-ranges.json",
);
const typescriptPath = join(
  repositoryRoot,
  "packages",
  "typescript",
  "core",
  "src",
  "unicode-17.generated.ts",
);
const csharpPath = join(
  repositoryRoot,
  "packages",
  "dotnet",
  "NaturalSpacing.Core",
  "Unicode17.Generated.cs",
);
const swiftPath = join(
  repositoryRoot,
  "packages",
  "swift",
  "Sources",
  "NaturalSpacingCore",
  "Unicode17Generated.swift",
);
const kotlinPath = join(
  repositoryRoot,
  "packages",
  "kotlin",
  "src",
  "main",
  "kotlin",
  "dev",
  "naturalspacing",
  "core",
  "Unicode17Generated.kt",
);
const dartPath = join(
  repositoryRoot,
  "packages",
  "dart",
  "lib",
  "src",
  "unicode_17_generated.dart",
);

const [modeOrDirectory, possibleDirectory] = process.argv.slice(2);
if (modeOrDirectory === "--check-generated") {
  const artifact = JSON.parse(readFileSync(artifactPath, "utf8"));
  verifyGeneratedFile(typescriptPath, renderTypeScript(artifact.ranges));
  verifyGeneratedFile(csharpPath, renderCSharp(artifact.ranges));
  verifyGeneratedFile(swiftPath, renderSwift(artifact.ranges));
  verifyGeneratedFile(kotlinPath, renderKotlin(artifact.ranges));
  verifyGeneratedFile(dartPath, renderDart(artifact.ranges));
  console.log("Generated TypeScript, C#, Swift, Kotlin, and Dart Unicode tables match the language-neutral artifact.");
  process.exit(0);
}

const checkOnly = modeOrDirectory === "--check";
const ucdDirectory = checkOnly ? possibleDirectory : modeOrDirectory;
if (ucdDirectory === undefined) {
  console.error(
    "Usage: node scripts/generate-unicode-tables.mjs [--check] <ucd-directory>\n" +
    "       node scripts/generate-unicode-tables.mjs --check-generated",
  );
  process.exit(2);
}

const metadataPath = join(
  repositoryRoot,
  "spec",
  "unicode",
  unicodeVersion,
  "sources.json",
);
const metadata = JSON.parse(readFileSync(metadataPath, "utf8"));
const requiredFiles = [
  "Scripts.txt",
  "ScriptExtensions.txt",
  "PropList.txt",
  "UnicodeData.txt",
];

for (const name of requiredFiles) verifySource(name);

const scripts = new Uint8Array(maximumCodePoint + 1);
for (const range of propertyRanges(readText("Scripts.txt"))) {
  const bit = range.property === "Latin" ? scriptBit.latin :
    range.property === "Han" ? scriptBit.han : 0;
  if (bit !== 0) scripts.fill(bit, range.start, range.end + 1);
}

for (const range of propertyRanges(readText("ScriptExtensions.txt"))) {
  const values = new Set(range.property.split(/\s+/u));
  let bits = 0;
  if (values.has("Latn")) bits |= scriptBit.latin;
  if (values.has("Hani")) bits |= scriptBit.han;
  scripts.fill(bits, range.start, range.end + 1);
}

const categories = new Uint8Array(maximumCodePoint + 1);
let pendingRange = null;
for (const line of dataLines(readText("UnicodeData.txt"))) {
  const fields = line.split(";");
  const codePoint = Number.parseInt(fields[0], 16);
  const name = fields[1];
  const category = fields[2];
  if (name.endsWith(", First>")) {
    pendingRange = { start: codePoint, category };
    continue;
  }
  if (name.endsWith(", Last>")) {
    if (pendingRange === null || pendingRange.category !== category) {
      throw new Error(`Malformed UnicodeData range ending at U+${fields[0]}`);
    }
    categories.fill(categoryBits(category), pendingRange.start, codePoint + 1);
    pendingRange = null;
    continue;
  }
  categories[codePoint] = categoryBits(category);
}
if (pendingRange !== null) throw new Error("Unclosed UnicodeData First range");

const whitespace = new Uint8Array(maximumCodePoint + 1);
for (const range of propertyRanges(readText("PropList.txt"))) {
  if (range.property === "White_Space") {
    whitespace.fill(1, range.start, range.end + 1);
  }
}

const latin = compress((codePoint) =>
  (scripts[codePoint] & scriptBit.latin) !== 0 &&
  (categories[codePoint] & categoryBit.letter) !== 0);
const han = compress((codePoint) =>
  (scripts[codePoint] & scriptBit.han) !== 0 &&
  (categories[codePoint] & categoryBit.hanEligible) !== 0);
const marks = compress((codePoint) =>
  (categories[codePoint] & categoryBit.mark) !== 0);
const whiteSpace = compress((codePoint) => whitespace[codePoint] !== 0);

const ranges = {
  latin: toPairs(latin),
  han: toPairs(han),
  mark: toPairs(marks),
  whiteSpace: toPairs(whiteSpace),
};
const artifact = {
  unicodeVersion,
  generatedFrom: requiredFiles,
  definitions: {
    latin: "(Script=Latin or Script_Extensions contains Latin) and General_Category=L*",
    han: "(Script=Han or Script_Extensions contains Han) and General_Category in {Lo,Nl}",
    mark: "General_Category=M*",
    whiteSpace: "White_Space=true",
  },
  ranges,
};
const artifactOutput = renderArtifact(artifact);
const typescriptOutput = renderTypeScript(ranges);
const csharpOutput = renderCSharp(ranges);
const swiftOutput = renderSwift(ranges);
const kotlinOutput = renderKotlin(ranges);
const dartOutput = renderDart(ranges);

if (checkOnly) {
  verifyGeneratedFile(artifactPath, artifactOutput);
  verifyGeneratedFile(typescriptPath, typescriptOutput);
  verifyGeneratedFile(csharpPath, csharpOutput);
  verifyGeneratedFile(swiftPath, swiftOutput);
  verifyGeneratedFile(kotlinPath, kotlinOutput);
  verifyGeneratedFile(dartPath, dartOutput);
} else {
  writeFileSync(artifactPath, artifactOutput);
  writeFileSync(typescriptPath, typescriptOutput);
  writeFileSync(csharpPath, csharpOutput);
  writeFileSync(swiftPath, swiftOutput);
  writeFileSync(kotlinPath, kotlinOutput);
  writeFileSync(dartPath, dartOutput);
}

console.log(
  `${checkOnly ? "Verified" : "Generated"} Unicode ${unicodeVersion} tables: ` +
  `${latin.length / 2} Latin, ${han.length / 2} Han, ` +
  `${marks.length / 2} Mark, ${whiteSpace.length / 2} White_Space ranges.`,
);

function renderTypeScript(generatedRanges) {
  return `// Generated by scripts/generate-unicode-tables.mjs. Do not edit.\n` +
  `// Unicode ${unicodeVersion}; source hashes are verified against spec/unicode/${unicodeVersion}/sources.json.\n\n` +
  emitTable("LATIN_RANGES", flatten(generatedRanges.latin)) +
  emitTable("HAN_RANGES", flatten(generatedRanges.han)) +
  emitTable("MARK_RANGES", flatten(generatedRanges.mark)) +
  emitTable("WHITE_SPACE_RANGES", flatten(generatedRanges.whiteSpace)) +
  `export function containsCodePoint(ranges: Uint32Array, codePoint: number): boolean {\n` +
  `  let low = 0;\n` +
  `  let high = ranges.length / 2 - 1;\n` +
  `  while (low <= high) {\n` +
  `    const middle = (low + high) >>> 1;\n` +
  `    const start = ranges[middle * 2];\n` +
  `    const end = ranges[middle * 2 + 1];\n` +
  `    if (start === undefined || end === undefined) return false;\n` +
  `    if (codePoint < start) high = middle - 1;\n` +
  `    else if (codePoint > end) low = middle + 1;\n` +
  `    else return true;\n` +
  `  }\n` +
  `  return false;\n` +
  `}\n`;
}

function renderCSharp(generatedRanges) {
  return `// Generated by scripts/generate-unicode-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; source hashes are verified against spec/unicode/${unicodeVersion}/sources.json.\n\n` +
    `namespace NaturalSpacing.Core;\n\n` +
    `internal static class Unicode17\n{\n` +
    emitCSharpTable("LatinRanges", flatten(generatedRanges.latin)) +
    emitCSharpTable("HanRanges", flatten(generatedRanges.han)) +
    emitCSharpTable("MarkRanges", flatten(generatedRanges.mark)) +
    emitCSharpTable("WhiteSpaceRanges", flatten(generatedRanges.whiteSpace)) +
    `    internal static bool Contains(int[] ranges, int codePoint)\n` +
    `    {\n` +
    `        var low = 0;\n` +
    `        var high = ranges.Length / 2 - 1;\n` +
    `        while (low <= high)\n` +
    `        {\n` +
    `            var middle = (low + high) >>> 1;\n` +
    `            var start = ranges[middle * 2];\n` +
    `            var end = ranges[middle * 2 + 1];\n` +
    `            if (codePoint < start) high = middle - 1;\n` +
    `            else if (codePoint > end) low = middle + 1;\n` +
    `            else return true;\n` +
    `        }\n` +
    `        return false;\n` +
    `    }\n` +
    `}\n`;
}

function renderSwift(generatedRanges) {
  return `// Generated by scripts/generate-unicode-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; source hashes are verified against spec/unicode/${unicodeVersion}/sources.json.\n\n` +
    `enum Unicode17 {\n` +
    emitSwiftTable("latinRanges", flatten(generatedRanges.latin)) +
    emitSwiftTable("hanRanges", flatten(generatedRanges.han)) +
    emitSwiftTable("markRanges", flatten(generatedRanges.mark)) +
    emitSwiftTable("whiteSpaceRanges", flatten(generatedRanges.whiteSpace)) +
    `    static func contains(_ ranges: [UInt32], _ codePoint: UInt32) -> Bool {\n` +
    `        var low = 0\n` +
    `        var high = ranges.count / 2 - 1\n` +
    `        while low <= high {\n` +
    `            let middle = (low + high) >> 1\n` +
    `            let start = ranges[middle * 2]\n` +
    `            let end = ranges[middle * 2 + 1]\n` +
    `            if codePoint < start {\n` +
    `                high = middle - 1\n` +
    `            } else if codePoint > end {\n` +
    `                low = middle + 1\n` +
    `            } else {\n` +
    `                return true\n` +
    `            }\n` +
    `        }\n` +
    `        return false\n` +
    `    }\n` +
    `}\n`;
}

function renderKotlin(generatedRanges) {
  return `// Generated by scripts/generate-unicode-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; source hashes are verified against spec/unicode/${unicodeVersion}/sources.json.\n\n` +
    `package dev.naturalspacing.core\n\n` +
    `internal object Unicode17 {\n` +
    emitKotlinTable("latinRanges", flatten(generatedRanges.latin)) +
    emitKotlinTable("hanRanges", flatten(generatedRanges.han)) +
    emitKotlinTable("markRanges", flatten(generatedRanges.mark)) +
    emitKotlinTable("whiteSpaceRanges", flatten(generatedRanges.whiteSpace)) +
    `    fun contains(ranges: IntArray, codePoint: Int): Boolean {\n` +
    `        var low = 0\n` +
    `        var high = ranges.size / 2 - 1\n` +
    `        while (low <= high) {\n` +
    `            val middle = (low + high) ushr 1\n` +
    `            val start = ranges[middle * 2]\n` +
    `            val end = ranges[middle * 2 + 1]\n` +
    `            if (codePoint < start) high = middle - 1\n` +
    `            else if (codePoint > end) low = middle + 1\n` +
    `            else return true\n` +
    `        }\n` +
    `        return false\n` +
    `    }\n` +
    `}\n`;
}

function renderDart(generatedRanges) {
  return `// Generated by scripts/generate-unicode-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; source hashes are verified against spec/unicode/${unicodeVersion}/sources.json.\n\n` +
    `final class Unicode17 {\n` +
    emitDartTable("latinRanges", flatten(generatedRanges.latin)) +
    emitDartTable("hanRanges", flatten(generatedRanges.han)) +
    emitDartTable("markRanges", flatten(generatedRanges.mark)) +
    emitDartTable("whiteSpaceRanges", flatten(generatedRanges.whiteSpace)) +
    `  static bool contains(List<int> ranges, int codePoint) {\n` +
    `    var low = 0;\n` +
    `    var high = ranges.length ~/ 2 - 1;\n` +
    `    while (low <= high) {\n` +
    `      final middle = (low + high) >> 1;\n` +
    `      final start = ranges[middle * 2];\n` +
    `      final end = ranges[middle * 2 + 1];\n` +
    `      if (codePoint < start) {\n` +
    `        high = middle - 1;\n` +
    `      } else if (codePoint > end) {\n` +
    `        low = middle + 1;\n` +
    `      } else {\n` +
    `        return true;\n` +
    `      }\n` +
    `    }\n` +
    `    return false;\n` +
    `  }\n` +
    `}\n`;
}

function renderArtifact(generatedArtifact) {
  const lines = [
    "{",
    `  "unicodeVersion": ${JSON.stringify(generatedArtifact.unicodeVersion)},`,
    `  "generatedFrom": ${JSON.stringify(generatedArtifact.generatedFrom)},`,
    `  "definitions": ${JSON.stringify(generatedArtifact.definitions, null, 2).replaceAll("\n", "\n  ")},`,
    "  \"ranges\": {",
    `    "latin": ${renderPairs(generatedArtifact.ranges.latin, 4)},`,
    `    "han": ${renderPairs(generatedArtifact.ranges.han, 4)},`,
    `    "mark": ${renderPairs(generatedArtifact.ranges.mark, 4)},`,
    `    "whiteSpace": ${renderPairs(generatedArtifact.ranges.whiteSpace, 4)}`,
    "  }",
    "}",
  ];
  return `${lines.join("\n")}\n`;
}

function renderPairs(pairs, indentation) {
  const spaces = " ".repeat(indentation);
  const entries = pairs.map(([start, end]) =>
    `${spaces}  [${start}, ${end}]`);
  return `[\n${entries.join(",\n")}\n${spaces}]`;
}

function verifyGeneratedFile(filePath, expected) {
  const actual = readFileSync(filePath, "utf8");
  if (actual !== expected) {
    throw new Error(
      `${filePath} is stale. Regenerate it from the pinned Unicode ${unicodeVersion} sources.`,
    );
  }
}

function verifySource(name) {
  const expected = metadata.files.find((entry) => entry.name === name);
  if (expected === undefined) throw new Error(`Missing metadata for ${name}`);
  const bytes = readFileSync(join(resolve(ucdDirectory), name));
  const sha256 = createHash("sha256").update(bytes).digest("hex");
  if (bytes.length !== expected.bytes || sha256 !== expected.sha256) {
    throw new Error(
      `${name} does not match pinned metadata: ` +
      `${bytes.length}/${sha256} != ${expected.bytes}/${expected.sha256}`,
    );
  }
}

function readText(name) {
  return readFileSync(join(resolve(ucdDirectory), name), "utf8");
}

function dataLines(text) {
  return text.split(/\r?\n/u).filter((line) => line.length > 0);
}

function propertyRanges(text) {
  const result = [];
  for (const rawLine of text.split(/\r?\n/u)) {
    const line = rawLine.replace(/#.*$/u, "").trim();
    if (line.length === 0) continue;
    const [encodedRange, property] = line.split(";").map((value) => value.trim());
    if (encodedRange === undefined || property === undefined) {
      throw new Error(`Malformed property line: ${rawLine}`);
    }
    const [startText, endText = startText] = encodedRange.split("..");
    result.push({
      start: Number.parseInt(startText, 16),
      end: Number.parseInt(endText, 16),
      property,
    });
  }
  return result;
}

function categoryBits(category) {
  let bits = 0;
  if (category.startsWith("L")) bits |= categoryBit.letter;
  if (category === "Lo" || category === "Nl") bits |= categoryBit.hanEligible;
  if (category.startsWith("M")) bits |= categoryBit.mark;
  return bits;
}

function compress(predicate) {
  const result = [];
  let start = -1;
  for (let codePoint = 0; codePoint <= maximumCodePoint; codePoint++) {
    if (predicate(codePoint)) {
      if (start < 0) start = codePoint;
    } else if (start >= 0) {
      result.push(start, codePoint - 1);
      start = -1;
    }
  }
  if (start >= 0) result.push(start, maximumCodePoint);
  return result;
}

function toPairs(values) {
  const pairs = [];
  for (let index = 0; index < values.length; index += 2) {
    pairs.push([values[index], values[index + 1]]);
  }
  return pairs;
}

function flatten(pairs) {
  return pairs.flatMap(([start, end]) => [start, end]);
}

function emitTable(name, values) {
  const lines = [];
  for (let index = 0; index < values.length; index += 12) {
    lines.push(
      `  ${values.slice(index, index + 12).map(toHex).join(", ")},`,
    );
  }
  return `export const ${name} = new Uint32Array([\n${lines.join("\n")}\n]);\n\n`;
}

function emitCSharpTable(name, values) {
  const lines = [];
  for (let index = 0; index < values.length; index += 12) {
    lines.push(
      `        ${values.slice(index, index + 12).map(toHex).join(", ")},`,
    );
  }
  return `    internal static readonly int[] ${name} =\n    [\n${lines.join("\n")}\n    ];\n\n`;
}

function emitSwiftTable(name, values) {
  const lines = [];
  for (let index = 0; index < values.length; index += 12) {
    lines.push(`        ${values.slice(index, index + 12).map(toHex).join(", ")},`);
  }
  return `    static let ${name}: [UInt32] = [\n${lines.join("\n")}\n    ]\n\n`;
}

function emitKotlinTable(name, values) {
  const lines = [];
  for (let index = 0; index < values.length; index += 12) {
    lines.push(`        ${values.slice(index, index + 12).map(toHex).join(", ")},`);
  }
  return `    val ${name} = intArrayOf(\n${lines.join("\n")}\n    )\n\n`;
}

function emitDartTable(name, values) {
  const lines = values.map((value) => `    ${toHex(value)},`);
  return `  static const ${name} = <int>[\n${lines.join("\n")}\n  ];\n\n`;
}

function toHex(value) {
  return `0x${value.toString(16).toUpperCase()}`;
}
