import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const testOrigin = "https://natural-spacing.test";
const generated = path.resolve(path.dirname(fileURLToPath(import.meta.url)), ".generated");
const nativeFixture = path.join(generated, "native-fixture-entry.js");
const reactFixture = path.join(generated, "react-fixture-entry.js");
const demoFixture = path.join(generated, "demo-fixture.js");
const demoHtml = readFileSync(
  path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../examples/web/index.html"),
  "utf8",
).replace(/\s*<script type="module" src="\.\/app\.mjs"><\/script>/u, "");

test.beforeEach(async ({ page }) => {
  await installFixtureRoute(page);
  await page.goto(`${testOrigin}/native`);
  await page.addScriptTag({ path: nativeFixture });
  await page.waitForFunction(() => window.naturalSpacingReady === true);
});

test("native numeric keyboard input is reconciled in an input element", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("input");
    input.focus();
  });

  await page.keyboard.type("2");

  await expect(page.locator("#input")).toHaveValue("中 2");
  expect(await selection(page, "input")).toEqual({ start: 3, end: 3, direction: "forward" });
});

test("textarea selection replacement scans both outer boundaries", async ({ page }) => {
  await page.evaluate(() => {
    const textarea = document.querySelector("#textarea");
    textarea.value = "前中文后";
    textarea.setSelectionRange(1, 3);
    window.attachNaturalSpacing("textarea");
    textarea.focus();
  });

  await page.keyboard.insertText("A2");

  await expect(page.locator("#textarea")).toHaveValue("前 A2 后");
  expect(await selection(page, "textarea")).toEqual({ start: 5, end: 5, direction: "forward" });
});

test("clipboard paste reconciles the pasted fragment", async ({ page, context, browserName }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("input");
    input.focus();
  });

  if (browserName === "chromium") {
    await context.grantPermissions(["clipboard-read", "clipboard-write"], {
      origin: testOrigin,
    });
    await page.evaluate(() => navigator.clipboard.writeText("A2"));
    await page.keyboard.press(process.platform === "darwin" ? "Meta+V" : "Control+V");
  } else {
    await page.evaluate(() => {
      const input = document.querySelector("#input");
      input.dispatchEvent(new ClipboardEvent("paste", { bubbles: true, cancelable: true }));
      input.dispatchEvent(new InputEvent("beforeinput", {
        bubbles: true,
        cancelable: true,
        data: "A2",
        inputType: "insertFromPaste",
      }));
    });
  }

  await expect(page.locator("#input")).toHaveValue("中 A2");
  expect(await selection(page, "input")).toEqual({ start: 4, end: 4, direction: "forward" });
});

test("composition events preserve marked text until compositionend", async ({ page }) => {
  const duringComposition = await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("input");
    input.dispatchEvent(new CompositionEvent("compositionstart", { bubbles: true }));
    input.value = "中A";
    input.setSelectionRange(2, 2);
    input.dispatchEvent(new InputEvent("input", {
      bubbles: true,
      data: "A",
      inputType: "insertCompositionText",
      isComposing: true,
    }));
    return input.value;
  });
  expect(duringComposition).toBe("中A");

  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.dispatchEvent(new CompositionEvent("compositionend", {
      bubbles: true,
      data: "A",
    }));
  });

  await expect(page.locator("#input")).toHaveValue("中 A");
  expect(await selection(page, "input")).toEqual({ start: 3, end: 3, direction: "forward" });
});

test("backspace keeps a deleted automatic space suppressed", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中 A";
    input.setSelectionRange(2, 2);
    window.attachNaturalSpacing("input");
    input.focus();
  });

  await page.keyboard.press("Backspace");

  await expect(page.locator("#input")).toHaveValue("中A");
  expect(await selection(page, "input")).toMatchObject({ start: 1, end: 1 });
});

test("UTF-16 length limits fail open to the native edit", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("input", {
      policy: "naturalLanguage",
      maxLengthUtf16: 2,
    });
    input.focus();
  });

  await page.keyboard.type("A");

  await expect(page.locator("#input")).toHaveValue("中A");
  expect(await selection(page, "input")).toMatchObject({ start: 2, end: 2 });
});

test("verbatim policy preserves eligible boundaries", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("input", { policy: "verbatim" });
    input.focus();
  });

  await page.keyboard.type("A");

  await expect(page.locator("#input")).toHaveValue("中A");
});

test("password input overrides a configured natural-language policy", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#password");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("password", { policy: "naturalLanguage" });
    input.focus();
  });

  await page.keyboard.type("A");

  await expect(page.locator("#password")).toHaveValue("中A");
});

test("end-to-end demo shares policy decisions across keyboard, secure, and ASR paths", async ({ page }) => {
  await page.setContent(demoHtml);
  await page.evaluate(() => {
    document.querySelector("[data-message]").value = "中";
    document.querySelector("[data-password]").value = "中";
  });
  await page.addScriptTag({ path: demoFixture });
  await page.waitForFunction(() => window.naturalSpacingDemo !== undefined);

  const policies = await page.evaluate(() => window.naturalSpacingDemo.policies);
  expect(policies).toEqual({
    message: "naturalLanguage",
    password: "verbatim",
    asr: "naturalLanguage",
  });

  const message = page.locator("[data-message]");
  await message.evaluate((input) => input.setSelectionRange(input.value.length, input.value.length));
  await message.focus();
  await page.keyboard.type("A");
  await expect(message).toHaveValue("中 A");
  await expect(page.locator("[data-message-status]")).toContainText(
    "effectivePolicy=naturalLanguage",
  );
  await expect(page.locator("[data-message-status]")).toContainText("text=中 A");

  const password = page.locator("[data-password]");
  await password.evaluate((input) => input.setSelectionRange(input.value.length, input.value.length));
  await password.focus();
  await page.keyboard.type("A");
  await expect(password).toHaveValue("中A");
  await expect(page.locator("[data-password-status]")).toContainText(
    "effectivePolicy=verbatim",
  );
  await expect(page.locator("[data-password-status]")).toContainText("text=<hidden>");
  await expect(page.locator("[data-password-status]")).not.toContainText("中A");

  await page.locator("[data-asr-interim]").click();
  await expect(page.locator("[data-asr-display]")).toHaveText("今天发布 v2 版本");
  await expect(page.locator("[data-asr-committed]")).toHaveText("");

  await page.locator("[data-asr-final]").click();
  await expect(page.locator("[data-asr-committed]")).toHaveText("今天发布 v2 版本");
});

test("sync accepts an externally rendered baseline", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    const adapter = window.attachNaturalSpacing("input");
    input.value = "文";
    input.setSelectionRange(1, 1);
    adapter.sync();
    input.focus();
  });

  await page.keyboard.type("B");

  await expect(page.locator("#input")).toHaveValue("文 B");
  expect(await selection(page, "input")).toEqual({ start: 3, end: 3, direction: "forward" });
});

test("native undo and redo keep the user edit and automatic spacing together", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("input");
    input.focus();
  });

  await page.keyboard.type("A");
  await expect(page.locator("#input")).toHaveValue("中 A");

  await page.keyboard.press(process.platform === "darwin" ? "Meta+Z" : "Control+Z");

  await expect(page.locator("#input")).toHaveValue("中");
  expect(await selection(page, "input")).toMatchObject({ start: 1, end: 1 });

  await page.keyboard.press(process.platform === "darwin" ? "Meta+Shift+Z" : "Control+Shift+Z");

  await expect(page.locator("#input")).toHaveValue("中 A");
  expect(await selection(page, "input")).toMatchObject({ start: 3, end: 3 });
});

test("disposing the native binding stops reconciliation", async ({ page }) => {
  await page.evaluate(() => {
    const input = document.querySelector("#input");
    input.value = "中";
    input.setSelectionRange(1, 1);
    window.attachNaturalSpacing("input");
    window.disposeNaturalSpacing("input");
    input.focus();
  });

  await page.keyboard.type("A");

  await expect(page.locator("#input")).toHaveValue("中A");
});

test("React controlled input publishes spacing and native undo redo", async ({ page }) => {
  await openReactFixture(page);
  const input = page.locator("#react-controlled");
  const state = page.locator("#react-controlled-state");
  await input.focus();

  await page.keyboard.type("A");
  await expect(input).toHaveValue("中 A");
  await expect(state).toHaveText("中 A");

  await page.keyboard.press(process.platform === "darwin" ? "Meta+Z" : "Control+Z");
  await expect(input).toHaveValue("中");
  await expect(state).toHaveText("中");

  await page.keyboard.press(process.platform === "darwin" ? "Meta+Shift+Z" : "Control+Shift+Z");
  await expect(input).toHaveValue("中 A");
  await expect(state).toHaveText("中 A");
});

test("React controlled external reset synchronizes the adapter baseline", async ({ page }) => {
  await openReactFixture(page);
  await page.locator("#react-controlled-reset").click();
  const input = page.locator("#react-controlled");
  await expect(input).toHaveValue("文");
  await expect(page.locator("#react-controlled-state")).toHaveText("文");

  await input.focus();
  await page.keyboard.type("B");

  await expect(input).toHaveValue("文 B");
  await expect(page.locator("#react-controlled-state")).toHaveText("文 B");
});

test("React uncontrolled input keeps native DOM ownership", async ({ page }) => {
  await openReactFixture(page);
  const input = page.locator("#react-uncontrolled");
  await input.focus();

  await page.keyboard.type("A");

  await expect(input).toHaveValue("中 A");
});

async function selection(page, id) {
  return page.evaluate((controlId) => {
    const control = document.getElementById(controlId);
    return {
      start: control.selectionStart,
      end: control.selectionEnd,
      direction: control.selectionDirection,
    };
  }, id);
}

async function openReactFixture(page) {
  await page.goto(`${testOrigin}/react`);
  await page.addScriptTag({ path: reactFixture });
  await page.waitForFunction(() => window.reactFixtureReady === true);
}

async function installFixtureRoute(page) {
  await page.route(`${testOrigin}/**`, (route) => route.fulfill({
    status: 200,
    contentType: "text/html",
    body: "<!doctype html><html><head><meta charset=\"utf-8\"></head><body><div id=\"root\"></div></body></html>",
  }));
}
