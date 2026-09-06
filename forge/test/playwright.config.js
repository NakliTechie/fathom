// forge/test — the one Playwright harness (FATHOM.md §7: no second harness).
// Serves the repo root statically and drives index.html through window.fathom.
const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: '.',
  testMatch: /.*\.spec\.js/,
  timeout: 120000,
  retries: 0,
  workers: 1,
  reporter: [['list']],
  use: { baseURL: 'http://127.0.0.1:8793', headless: true, viewport: { width: 1440, height: 900 } },
  webServer: {
    command: 'python3 -m http.server 8793 --bind 127.0.0.1 --directory ../..',
    url: 'http://127.0.0.1:8793/index.html',
    reuseExistingServer: true,
    timeout: 20000,
  },
});
