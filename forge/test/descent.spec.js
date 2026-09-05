// The C4 checkpoint, headless: forge/test/descent.test.js on every program.
const { test, expect } = require('@playwright/test');
const PROGRAMS = ['uart_puts', 'popcount', 'chase', 'sum'];

for (const p of PROGRAMS) {
  test(`descent and ascent through the agent face — ${p}`, async ({ page }) => {
    const errors = [];
    page.on('pageerror', e => errors.push(String(e)));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await page.goto(`/fathom.html?p=${p}`);
    await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
    const r = await page.evaluate(async () => {
      const m = await import('/forge/test/descent.test.js');
      return m.run(window.fathom, document);
    });
    expect(r.log, r.log.join('\n')).toEqual(['OK']);
    expect(r.ok).toBe(true);
    expect(r.stops).toHaveLength(7);
    expect(r.agentCalls).toBe(14);
    expect(errors, errors.join('\n')).toEqual([]);
  });
}

test('first frame is useful within the 5 s gate — uart_puts', async ({ page }) => {
  await page.goto('/fathom.html?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const t = await page.evaluate(() => window.fathom.timing());
  expect(t.built_ms).toBeLessThan(5000);
  const rows = await page.locator('#L-source .row').count();
  expect(rows).toBeGreaterThan(10);
});
