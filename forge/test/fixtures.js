// Shared harness setup. Most tests are not first visits: they seed the flag the
// welcome overlay checks, so it stays out of the way. The tests that are ABOUT
// the first visit (tour.spec.js) clear it deliberately.
const base = require('@playwright/test');

exports.test = base.test.extend({
  page: async ({ page }, use) => {
    await page.addInitScript(() => { try { localStorage.setItem('fathom.tour', 'done'); } catch {} });
    await use(page);
  },
});
exports.expect = base.expect;
