/**
 * tests/e2e/smoke.spec.js
 * 
 * Phase 07 — Playwright Browser Smoke Suite
 * 
 * Purpose: 
 * Verifies the "Last Mile" of the deployment by ensuring the live storefront 
 * successfully renders in a real browser (Chromium).
 * 
 * Assertions: 
 * Focus on stable UI elements meaningful for smoke checks 
 * rather than detailed E2E business flows
 */

const { test, expect } = require('@playwright/test');

test('storefront root loads and key landing content is visible', async ({ page }) => {
  // Navigate to the configured base URL 
  // 'domcontentloaded' is used for speed, as we only need the initial 
  // HTML/DOM structure to begin our smoke checks.
  const response = await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Ensure the server actually responded with a success code (200-299).
  expect(response && response.ok()).toBeTruthy();

  // Verify key landing-page content that should remain visible on a healthy storefront.
  await expect(page).toHaveTitle(/WeaveSocks/i);
  await expect(page.getByText('We love socks!')).toBeVisible();
  await expect(page.getByText('Hot this week')).toBeVisible();
});

test('storefront renders at least one catalogue image', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });

  // Verify that at least one catalogue image is rendered in the storefront.
  // This keeps the smoke check stable without depending on one exact product entry.
  const productImages = page.locator('img[src*="/catalogue/images/"]');

  await expect(productImages.first()).toBeVisible();
});