import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, statSync } from "node:fs";
import { dirname, extname, resolve } from "node:path";

const repositoryRoot = resolve(import.meta.dirname, "..");
const candidateFiles = execFileSync(
  "git",
  ["ls-files", "--cached", "--others", "--exclude-standard", "-z"],
  { cwd: repositoryRoot, encoding: "utf8" },
)
  .split("\0")
  .filter(Boolean)
  .sort();

const errors = [];

const forbiddenPaths = [
  ["Finder metadata", /(^|\/)\.DS_Store$/],
  ["environment file", /(^|\/)\.env(?:\.|$)/],
  ["dependency or build cache", /(^|\/)(?:node_modules|\.build|\.gradle|\.kotlin|\.dart_tool|build)(?:\/|$)/],
  [".NET build output", /^(?:packages\/dotnet\/[^/]+|examples\/consumers\/dotnet)\/(?:bin|obj)(?:\/|$)/],
  ["test output", /(^|\/)(?:coverage|playwright-report|test-results)(?:\/|$)/],
  ["credential or signing file", /\.(?:key|pem|p12|pfx|mobileprovision|keystore|jks)$/i],
];

const sensitiveText = [
  ["private-key marker", /-----BEGIN\s+(?:RSA\s+|EC\s+|OPENSSH\s+)?PRIVATE KEY-----/],
  ["GitHub token", /\b(?:ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})\b/],
  ["OpenAI-style secret", /\bsk-[A-Za-z0-9_-]{20,}\b/],
  ["AWS access key", /\bAKIA[0-9A-Z]{16}\b/],
  ["absolute user-home path", /(?:\/Users\/[^/\s]+\/|\/home\/[^/\s]+\/|[A-Za-z]:\\Users\\[^\\\s]+\\)/],
];

for (const file of candidateFiles) {
  for (const [label, pattern] of forbiddenPaths) {
    if (pattern.test(file)) errors.push(`${file}: forbidden ${label}`);
  }

  const absolutePath = resolve(repositoryRoot, file);
  const bytes = readFileSync(absolutePath);
  if (bytes.includes(0)) continue;

  const text = bytes.toString("utf8");
  for (const [label, pattern] of sensitiveText) {
    if (pattern.test(text)) errors.push(`${file}: possible ${label}`);
  }

  if (extname(file).toLowerCase() === ".md") {
    validateMarkdownLinks(file, text);
  }
}

if (errors.length > 0) {
  console.error(`Repository validation failed:\n${errors.join("\n")}`);
  process.exit(1);
}

console.log(
  `Repository valid: ${candidateFiles.length} candidate files; no forbidden paths, ` +
    "common secret patterns, absolute user-home paths, or broken relative Markdown links.",
);

function validateMarkdownLinks(file, text) {
  for (const match of text.matchAll(/\]\(([^)]+)\)/g)) {
    let target = match[1].trim();
    if (
      target.startsWith("#") ||
      /^[a-z][a-z0-9+.-]*:/i.test(target)
    ) {
      continue;
    }

    if (target.startsWith("<") && target.endsWith(">")) {
      target = target.slice(1, -1);
    }
    target = target.split("#", 1)[0].split("?", 1)[0];
    if (target.length === 0) continue;

    let decodedTarget;
    try {
      decodedTarget = decodeURIComponent(target);
    } catch {
      errors.push(`${file}: invalid encoded Markdown target ${target}`);
      continue;
    }

    const absoluteTarget = resolve(repositoryRoot, dirname(file), decodedTarget);
    if (!existsSync(absoluteTarget)) {
      errors.push(`${file}: missing Markdown target ${target}`);
    } else if (!statSync(absoluteTarget).isFile() && !statSync(absoluteTarget).isDirectory()) {
      errors.push(`${file}: unsupported Markdown target ${target}`);
    }
  }
}
