import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { decodeUnicodeData } from "../node_modules/unicode-segmenter/core.js";
import {
  grapheme_cats,
  grapheme_data,
  grapheme_pairs,
} from "../node_modules/unicode-segmenter/_grapheme_data.js";

const unicodeVersion = "17.0.0";
const sourcePackageVersion = "0.17.3";
const maximumCodePoint = 0x10ffff;
const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const artifactPath = join(
  repositoryRoot,
  "spec",
  "unicode",
  unicodeVersion,
  "grapheme-segmentation.json",
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
  "Grapheme17DataGenerated.kt",
);
const swiftPath = join(
  repositoryRoot,
  "packages",
  "swift",
  "Sources",
  "NaturalSpacingCore",
  "Grapheme17DataGenerated.swift",
);
const csharpPath = join(
  repositoryRoot,
  "packages",
  "dotnet",
  "NaturalSpacing.Core",
  "Grapheme17Data.Generated.cs",
);
const dartPath = join(
  repositoryRoot,
  "packages",
  "dart",
  "lib",
  "src",
  "grapheme_17_data_generated.dart",
);

const packageDocument = JSON.parse(readFileSync(
  join(repositoryRoot, "node_modules", "unicode-segmenter", "package.json"),
  "utf8",
));
if (packageDocument.version !== sourcePackageVersion) {
  throw new Error(
    `Expected unicode-segmenter ${sourcePackageVersion}, found ${packageDocument.version}`,
  );
}

const mode = process.argv[2];
if (mode === "--check-generated") {
  const artifact = JSON.parse(readFileSync(artifactPath, "utf8"));
  verifyFile(kotlinPath, renderKotlin(artifact));
  verifyFile(swiftPath, renderSwift(artifact));
  verifyFile(csharpPath, renderCSharp(artifact));
  verifyFile(dartPath, renderDart(artifact));
  console.log("Generated Kotlin, Swift, C#, and Dart grapheme data matches the language-neutral artifact.");
  process.exit(0);
}
if (mode !== undefined && mode !== "--check") {
  console.error("Usage: node scripts/generate-grapheme-tables.mjs [--check|--check-generated]");
  process.exit(2);
}

const categories = materializeCategories();
const artifact = {
  unicodeVersion,
  sourcePackage: {
    name: "unicode-segmenter",
    version: sourcePackageVersion,
    license: "MIT",
  },
  categories: {
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
  },
  ranges: compressCategories(categories),
  pairMasks: [...grapheme_pairs].map(Number),
  linkers: [
    0x094d, 0x09cd, 0x0acd, 0x0b4d, 0x0c4d, 0x0d4d, 0x1039,
    0x17d2, 0x1a60, 0x1b44, 0x1bab, 0xa9c0, 0xaaf6, 0x10a3f,
    0x11133, 0x113d0, 0x1193e, 0x11a47, 0x11a99, 0x11f42,
  ],
};
const artifactOutput = renderArtifact(artifact);
const kotlinOutput = renderKotlin(artifact);
const swiftOutput = renderSwift(artifact);
const csharpOutput = renderCSharp(artifact);
const dartOutput = renderDart(artifact);

if (mode === "--check") {
  verifyFile(artifactPath, artifactOutput);
  verifyFile(kotlinPath, kotlinOutput);
  verifyFile(swiftPath, swiftOutput);
  verifyFile(csharpPath, csharpOutput);
  verifyFile(dartPath, dartOutput);
  console.log(`Verified ${artifact.ranges.length} Unicode ${unicodeVersion} grapheme ranges.`);
} else {
  writeFileSync(artifactPath, artifactOutput);
  writeFileSync(kotlinPath, kotlinOutput);
  writeFileSync(swiftPath, swiftOutput);
  writeFileSync(csharpPath, csharpOutput);
  writeFileSync(dartPath, dartOutput);
  console.log(`Generated ${artifact.ranges.length} Unicode ${unicodeVersion} grapheme ranges.`);
}

function materializeCategories() {
  const result = new Uint8Array(maximumCodePoint + 1);
  decodeUnicodeData(grapheme_data, grapheme_cats, (start, end, category) => {
    result.fill(category, start, end + 1);
  });

  result[0x3297] = 4;
  result[0x3299] = 4;
  for (let codePoint = 0xac00; codePoint <= 0xd7a3; codePoint += 1) {
    result[codePoint] = (codePoint - 0xac00) % 28 === 0 ? 7 : 8;
  }
  result.fill(13, 0xd7b0, 0xd7c7);
  result.fill(12, 0xd7cb, 0xd7fc);
  result[0xfb1e] = 3;
  result.fill(3, 0xfe00, 0xfe10);
  result.fill(2, 0xe0000, 0xe1000);
  result.fill(3, 0xe0020, 0xe0080);
  result.fill(3, 0xe0100, 0xe01f0);
  return result;
}

function compressCategories(categories) {
  const ranges = [];
  let start = 0;
  let previous = categories[0];
  for (let codePoint = 1; codePoint <= maximumCodePoint + 1; codePoint += 1) {
    const category = codePoint <= maximumCodePoint ? categories[codePoint] : 0;
    if (category === previous) continue;
    if (previous !== 0) ranges.push([start, codePoint - 1, previous]);
    start = codePoint;
    previous = category;
  }
  return ranges;
}

function renderArtifact(value) {
  const header = [
    "{",
    `  "unicodeVersion": ${JSON.stringify(value.unicodeVersion)},`,
    `  "sourcePackage": ${JSON.stringify(value.sourcePackage)},`,
    `  "categories": ${JSON.stringify(value.categories)},`,
    "  \"ranges\": [",
  ];
  const ranges = value.ranges.map((range) => `    [${range.join(", ")}]`);
  const footer = [
    "  ],",
    `  "pairMasks": ${JSON.stringify(value.pairMasks)},`,
    `  "linkers": ${JSON.stringify(value.linkers)}`,
    "}",
  ];
  return `${[...header, ranges.join(",\n"), ...footer].join("\n")}\n`;
}

function renderKotlin(value) {
  const rangeLines = value.ranges.map(([start, end, category]) =>
    `        ${toHex(start)}, ${toHex(end)}, ${category},`);
  return `// Generated by scripts/generate-grapheme-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; derived from unicode-segmenter ${sourcePackageVersion} under the MIT license.\n\n` +
    `package dev.naturalspacing.core\n\n` +
    `internal object Grapheme17Data {\n` +
    `    private val ranges = intArrayOf(\n${rangeLines.join("\n")}\n    )\n\n` +
    `    val pairMasks = intArrayOf(\n        ${value.pairMasks.join(", ")},\n    )\n\n` +
    `    private val linkers = intArrayOf(\n        ${value.linkers.map(toHex).join(", ")},\n    )\n\n` +
    `    fun category(codePoint: Int): Int {\n` +
    `        var low = 0\n` +
    `        var high = ranges.size / 3 - 1\n` +
    `        while (low <= high) {\n` +
    `            val middle = (low + high) ushr 1\n` +
    `            val start = ranges[middle * 3]\n` +
    `            val end = ranges[middle * 3 + 1]\n` +
    `            if (codePoint < start) high = middle - 1\n` +
    `            else if (codePoint > end) low = middle + 1\n` +
    `            else return ranges[middle * 3 + 2]\n` +
    `        }\n` +
    `        return 0\n` +
    `    }\n\n` +
    `    fun isLinker(codePoint: Int): Boolean = linkers.binarySearch(codePoint) >= 0\n` +
    `}\n`;
}

function renderSwift(value) {
  const rangeLines = value.ranges.map(([start, end, category]) =>
    `        ${toHex(start)}, ${toHex(end)}, ${category},`);
  return `// Generated by scripts/generate-grapheme-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; derived from unicode-segmenter ${sourcePackageVersion} under the MIT license.\n\n` +
    `enum Grapheme17Data {\n` +
    `    private static let ranges: [UInt32] = [\n${rangeLines.join("\n")}\n    ]\n\n` +
    `    static let pairMasks = [\n        ${value.pairMasks.join(", ")},\n    ]\n\n` +
    `    private static let linkers: [UInt32] = [\n        ${value.linkers.map(toHex).join(", ")},\n    ]\n\n` +
    `    static func category(_ codePoint: UInt32) -> Int {\n` +
    `        var low = 0\n` +
    `        var high = ranges.count / 3 - 1\n` +
    `        while low <= high {\n` +
    `            let middle = (low + high) >> 1\n` +
    `            let start = ranges[middle * 3]\n` +
    `            let end = ranges[middle * 3 + 1]\n` +
    `            if codePoint < start { high = middle - 1 }\n` +
    `            else if codePoint > end { low = middle + 1 }\n` +
    `            else { return Int(ranges[middle * 3 + 2]) }\n` +
    `        }\n` +
    `        return 0\n` +
    `    }\n\n` +
    `    static func isLinker(_ codePoint: UInt32) -> Bool {\n` +
    `        var low = 0\n` +
    `        var high = linkers.count - 1\n` +
    `        while low <= high {\n` +
    `            let middle = (low + high) >> 1\n` +
    `            let value = linkers[middle]\n` +
    `            if codePoint < value { high = middle - 1 }\n` +
    `            else if codePoint > value { low = middle + 1 }\n` +
    `            else { return true }\n` +
    `        }\n` +
    `        return false\n` +
    `    }\n` +
    `}\n`;
}

function renderCSharp(value) {
  const rangeLines = value.ranges.map(([start, end, category]) =>
    `        ${toHex(start)}, ${toHex(end)}, ${category},`);
  return `// Generated by scripts/generate-grapheme-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; derived from unicode-segmenter ${sourcePackageVersion} under the MIT license.\n\n` +
    `namespace NaturalSpacing.Core;\n\n` +
    `internal static class Grapheme17Data\n{\n` +
    `    private static readonly int[] Ranges =\n    [\n${rangeLines.join("\n")}\n    ];\n\n` +
    `    internal static readonly int[] PairMasks =\n    [\n        ${value.pairMasks.join(", ")},\n    ];\n\n` +
    `    private static readonly int[] Linkers =\n    [\n        ${value.linkers.map(toHex).join(", ")},\n    ];\n\n` +
    `    internal static int Category(int codePoint)\n    {\n` +
    `        var low = 0;\n` +
    `        var high = Ranges.Length / 3 - 1;\n` +
    `        while (low <= high)\n        {\n` +
    `            var middle = (low + high) >> 1;\n` +
    `            var start = Ranges[middle * 3];\n` +
    `            var end = Ranges[middle * 3 + 1];\n` +
    `            if (codePoint < start) high = middle - 1;\n` +
    `            else if (codePoint > end) low = middle + 1;\n` +
    `            else return Ranges[middle * 3 + 2];\n` +
    `        }\n` +
    `        return 0;\n` +
    `    }\n\n` +
    `    internal static bool IsLinker(int codePoint) => Array.BinarySearch(Linkers, codePoint) >= 0;\n` +
    `}\n`;
}

function renderDart(value) {
  const rangeLines = value.ranges.flatMap(([start, end, category]) => [
    `    ${toHex(start)},`,
    `    ${toHex(end)},`,
    `    ${category},`,
  ]);
  const pairMaskLines = value.pairMasks.map((mask) => `    ${mask},`);
  const linkerLines = value.linkers.map((linker) => `    ${toHex(linker)},`);
  return `// Generated by scripts/generate-grapheme-tables.mjs. Do not edit.\n` +
    `// Unicode ${unicodeVersion}; derived from unicode-segmenter ${sourcePackageVersion} under the MIT license.\n\n` +
    `final class Grapheme17Data {\n` +
    `  static const ranges = <int>[\n${rangeLines.join("\n")}\n  ];\n\n` +
    `  static const pairMasks = <int>[\n${pairMaskLines.join("\n")}\n  ];\n\n` +
    `  static const linkers = <int>[\n${linkerLines.join("\n")}\n  ];\n\n` +
    `  static int category(int codePoint) {\n` +
    `    var low = 0;\n` +
    `    var high = ranges.length ~/ 3 - 1;\n` +
    `    while (low <= high) {\n` +
    `      final middle = (low + high) >> 1;\n` +
    `      final start = ranges[middle * 3];\n` +
    `      final end = ranges[middle * 3 + 1];\n` +
    `      if (codePoint < start) {\n` +
    `        high = middle - 1;\n` +
    `      } else if (codePoint > end) {\n` +
    `        low = middle + 1;\n` +
    `      } else {\n` +
    `        return ranges[middle * 3 + 2];\n` +
    `      }\n` +
    `    }\n` +
    `    return 0;\n` +
    `  }\n\n` +
    `  static bool isLinker(int codePoint) => _binarySearch(linkers, codePoint);\n\n` +
    `  static bool _binarySearch(List<int> values, int target) {\n` +
    `    var low = 0;\n` +
    `    var high = values.length - 1;\n` +
    `    while (low <= high) {\n` +
    `      final middle = (low + high) >> 1;\n` +
    `      final value = values[middle];\n` +
    `      if (target < value) {\n` +
    `        high = middle - 1;\n` +
    `      } else if (target > value) {\n` +
    `        low = middle + 1;\n` +
    `      } else {\n` +
    `        return true;\n` +
    `      }\n` +
    `    }\n` +
    `    return false;\n` +
    `  }\n` +
    `}\n`;
}

function verifyFile(filePath, expected) {
  const actual = readFileSync(filePath, "utf8");
  if (actual !== expected) throw new Error(`${filePath} is stale.`);
}

function toHex(value) {
  return `0x${value.toString(16).toUpperCase()}`;
}
