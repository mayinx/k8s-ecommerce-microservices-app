// tests/e2e/playwright.config.js
//
// Playwright configuration 
// Purpose:
// - Keep execution deterministic in CI by avoiding parallelism
// - Capture useful failure artifacts without adding too much overhead

const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  // Look for test files in the current directory (tests/e2e/)
  testDir: '.',

  // A larger assertion timeout helps with live environment rendering delays
  expect: {
    timeout: 10000,
  },

  use: {
    // Base URL to use in actions like `await page.goto('/')`.
    baseURL: process.env.BASE_URL || 'https://dev-sockshop.cdco.dev',

    // Run headless (without browser gui) for CI-friendly, non-interactive execution.
    // (mandatory for CI) 
    headless: true,

    // Minimize storage overhead by only saving artifacts on failure
    //
    // Save a screenshot only when a test fails.
    screenshot: 'only-on-failure',
    //
    // Capture a trace (recorded debug package/artifact) on the first retry 
    // to aid debugging when retries are enabled.
    trace: 'on-first-retry',
  },

  // Fail the build on CI if you accidentally left 'test.only' in the source code.
  // (to prevent committing debug code (test.only) to the main branch)
  forbidOnly: !!process.env.CI,

  // Keep execution serial (1 worker) to ensure stability in resource-constrained CI runners
  //
  // Do not run tests in parallel.
  fullyParallel: false,
  //
  // Opt out of parallel tests on CI.
  workers: process.env.CI ? 1 : undefined,

  // Retry on CI only (to filter out temporary network errors/blibs). 
  retries: process.env.CI ? 1 : 0,

  // Show readable live console output and also generate an HTML report artifact for later inspection
  reporter: [     
    ['list'], // show live console output 
    ['html', { open: 'never' }], // HTML report is saved as an artifact, but not auto-opened (CI-friendly)
  ],

  // Browser config.
  projects: [
    {
      name: 'chromium',
      use: {
        // For now (smoke check): Limit to one browser for speed and consistency.
        browserName: 'chromium',
      },
    },
  ],
});