// The production CSP, applied locally. The local static server does not send
// _headers, so the suite ran without a CSP and the first deploy shipped a policy
// that blocked index.html's own inline scripts -- a dead shell, live, for an hour.
// These tests apply the real header to the local page.
const { test, expect } = require('./fixtures');
const fs = require('fs');
const path = require('path');

const HEADERS = path.resolve(__dirname, '../../_headers');

function productionCsp() {
  const m = fs.readFileSync(HEADERS, 'utf8').match(/Content-Security-Policy:\s*(.+)/);
  if (!m) throw new Error('no CSP in _headers');
  return m[1].trim();
}

test('_headers is not stale — its hashes are index.html\'s inline scripts', () => {
  const { execFileSync } = require('child_process');
  const out = execFileSync('python3', [path.resolve(__dirname, '../deploy/headers.py'), '--check'],
    { cwd: path.resolve(__dirname, '../..'), encoding: 'utf8' });
  expect(out).toContain('OK');
});

test('the app runs under the production CSP, with no violation', async ({ page }) => {
  const csp = productionCsp();
  const violations = [];
  page.on('console', m => { if (m.type() === 'error' && /Content Security Policy/i.test(m.text())) violations.push(m.text()); });
  // Apply the real header to the DOCUMENT only. The CSP that governs a page comes
  // from its own response; proxying every asset through the route would also push
  // the 18 MB wasm through Node for nothing.
  await page.route(/\/(\?|$)|index\.html/, async route => {
    if (route.request().resourceType() !== 'document') return route.continue();
    const res = await route.fetch();
    await route.fulfill({ response: res, headers: { ...res.headers(), 'content-security-policy': csp } });
  });
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded, { timeout: 20000 });
  const d = await page.evaluate(() => window.fathom.describe());
  expect(d.program).toBe('uart_puts');
  // the bottom layers too: wasm, a worker, and a dynamic import all sit under the CSP
  // This test's subject is the CSP, not the joins (forge/verify.py owns those):
  // assert only that wasm, the worker and the dynamic import all ran.
  const bottom = await page.evaluate(() => window.fathom.loadBottom());
  expect(bottom.gates.cycles).toBeGreaterThan(0);
  expect(bottom.cells.cells).toBeGreaterThan(0);
  expect(await page.locator('#L-cells canvas').count()).toBe(1);
  expect(violations, violations.join('\n')).toEqual([]);
});
