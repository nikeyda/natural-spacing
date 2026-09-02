import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  cpSync,
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const root = resolve(import.meta.dirname, "..");
const temporaryRoot = mkdtempSync(join(tmpdir(), "natural-spacing-npm-consumer-"));
const tarballDirectory = join(temporaryRoot, "tarballs");
const consumerDirectory = join(temporaryRoot, "consumer");

try {
  mkdirSync(tarballDirectory);
  mkdirSync(consumerDirectory);

  console.log("Packing local dependency and workspace packages...");
  const unicodeSegmenterSource = join(root, "node_modules/unicode-segmenter");
  const unicodeSegmenterStaging = join(temporaryRoot, "unicode-segmenter");
  cpSync(unicodeSegmenterSource, unicodeSegmenterStaging, { recursive: true });
  const unicodeManifestPath = join(unicodeSegmenterStaging, "package.json");
  const unicodeManifest = JSON.parse(readFileSync(unicodeManifestPath, "utf8"));
  delete unicodeManifest.scripts;
  delete unicodeManifest.devDependencies;
  writeFileSync(unicodeManifestPath, JSON.stringify(unicodeManifest));
  const unicodeSegmenterTarball = pack(unicodeSegmenterStaging);
  const coreTarball = pack("packages/typescript/core");
  const webTarball = pack("packages/typescript/web");
  writeFileSync(
    join(consumerDirectory, "package.json"),
    JSON.stringify({ name: "natural-spacing-consumer-smoke", private: true, type: "module" }),
  );

  console.log("Installing tarballs into an isolated offline consumer...");
  runNpm([
    "install",
    "--offline",
    "--ignore-scripts",
    "--no-audit",
    "--no-fund",
    unicodeSegmenterTarball,
    coreTarball,
    webTarball,
  ], consumerDirectory);

  writeFileSync(
    join(consumerDirectory, "consumer.mjs"),
    `
      import assert from "node:assert/strict";
      import { normalizeNaturalLanguage, OrderedTextUpdateSession, recommendPolicy, resolvePolicy } from "@natural-spacing/core";
      import { NaturalSpacingTextControlAdapter } from "@natural-spacing/web";

      assert.equal(normalizeNaturalLanguage("发布v2版本", "naturalLanguage"), "发布 v2 版本");
      const advisory = recommendPolicy({ contentKind: "searchQuery", text: "查找iOS版本" });
      assert.equal(advisory.policy, "naturalLanguage");
      assert.equal(advisory.autoApply, false);
      assert.equal(resolvePolicy({ contentKind: "searchQuery", text: "查找iOS版本" }), "verbatim");
      assert.equal(resolvePolicy({
        explicitPolicy: "naturalLanguage",
        contentKind: "message",
        isSecure: true,
      }), "verbatim");
      const ordered = new OrderedTextUpdateSession();
      assert.equal(ordered.start("utterance-1"), true);
      const interim = ordered.accept({
        utteranceId: "utterance-1",
        revision: 0,
        text: "中2文",
        stability: "interim",
      });
      assert.equal(interim.accepted, true);
      assert.equal(interim.output.displayText, "中 2 文");
      assert.equal(interim.output.committedText, null);
      const stale = ordered.accept({
        utteranceId: "utterance-1",
        revision: 0,
        text: "ignored",
        stability: "interim",
      });
      assert.deepEqual(stale, { accepted: false, reason: "staleRevision", output: null });
      const final = ordered.accept({
        utteranceId: "utterance-1",
        revision: 1,
        text: "中2文",
        stability: "final",
      });
      assert.equal(final.output.committedText, "中 2 文");
      assert.equal(ordered.accept({
        utteranceId: "utterance-1",
        revision: 2,
        text: "ignored",
        stability: "final",
      }).reason, "inactiveUtterance");
      assert.equal(typeof NaturalSpacingTextControlAdapter, "function");
      assert.match(import.meta.resolve("@natural-spacing/web/display.css"), /display\\.css$/u);
    `,
  );
  execFileSync(process.execPath, [join(consumerDirectory, "consumer.mjs")], {
    cwd: consumerDirectory,
    stdio: "inherit",
  });

  console.log("npm consumer smoke passed: packed core and web tarballs install and import offline.");

  function pack(packagePath) {
    const output = runNpm(
      [
        "pack",
        "--ignore-scripts",
        "--json",
        "--pack-destination",
        tarballDirectory,
        packagePath,
      ],
      root,
    );
    const result = JSON.parse(output);
    assert.equal(result.length, 1, `${packagePath} must produce one tarball`);
    const tarball = join(tarballDirectory, result[0].filename);
    assert.ok(readFileSync(tarball).length > 0, `${packagePath} tarball must not be empty`);
    return tarball;
  }
} finally {
  rmSync(temporaryRoot, { recursive: true, force: true });
}

function runNpm(arguments_, cwd) {
  return execFileSync("npm", arguments_, {
    cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      npm_config_cache: join(temporaryRoot, "npm-cache"),
      npm_config_update_notifier: "false",
    },
    stdio: ["ignore", "pipe", "inherit"],
  });
}
