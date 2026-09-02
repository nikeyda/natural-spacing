import { defineConfig } from "@playwright/test";

const projects = process.env.CI
  ? [
      { name: "firefox", use: { browserName: "firefox" } },
      { name: "webkit", use: { browserName: "webkit" } },
      { name: "chromium", use: { browserName: "chromium" } },
    ]
  : [
      { name: "firefox", use: { browserName: "firefox" } },
      { name: "webkit", use: { browserName: "webkit" } },
      { name: "chrome", use: { browserName: "chromium", channel: "chrome" } },
      { name: "edge", use: { browserName: "chromium", channel: "msedge" } },
    ];

export default defineConfig({
  testDir: "packages/typescript/web/test",
  testMatch: "browser.spec.mjs",
  // Firefox cold starts can spend more than 30 seconds before the first
  // intercepted HTTPS fixture navigation commits on loaded macOS hosts.
  // Keep retries disabled so a genuine functional failure remains visible.
  timeout: 60_000,
  fullyParallel: false,
  workers: 1,
  reporter: "line",
  use: {
    headless: true,
    trace: "retain-on-failure",
  },
  projects,
});
