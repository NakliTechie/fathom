// Cold-cache timing against the live origin. A fresh browser context per run,
// so nothing is cached: a first visit over the real network.
const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch();
  const out = [];
  for (const p of ['uart_puts', 'popcount']) {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    const errs = [];
    page.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
    page.on('pageerror', e => errs.push(String(e)));
    await page.goto(`https://fathom.naklitechie.com/?p=${p}`, { waitUntil: 'load' });
    await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded, { timeout: 30000 });
    const t = await page.evaluate(() => window.fathom.timing());
    const kb = await page.evaluate(() => Math.round(performance.getEntriesByType('resource').reduce((n, r) => n + (r.transferSize || 0), 0) / 1024));
    out.push({ run: p, first_frame_ms: t.built_ms, response_ms: t.response_ms, dom_ms: t.dom_ms, transferred_kb: kb, console_errors: errs.length });
    await ctx.close();
  }
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  await page.goto('https://fathom.naklitechie.com/?p=uart_puts', { waitUntil: 'load' });
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const b = await page.evaluate(async () => { const t0 = performance.now(); const s = await window.fathom.loadBottom(); return { wall_ms: Math.round(performance.now() - t0), gates_ms: s.gates.ms, cells_ms: s.cells.ms, cells: s.cells.cells }; });
  out.push({ run: 'uart_puts + bottom layers (cold)', ...b });
  await ctx.close();
  await browser.close();
  console.log(JSON.stringify(out, null, 1));
})();
