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

test('manifest ⊇ command bus — every callable on the face is in the manifest, and vice versa', async ({ page }) => {
  await page.goto('/fathom.html?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const r = await page.evaluate(() => {
    const f = window.fathom;
    const callable = Object.keys(f).filter(k => typeof f[k] === 'function').sort();
    const listed = f.manifest.map(m => m.name).sort();
    return { callable, listed, missing: callable.filter(k => !listed.includes(k)), stale: listed.filter(k => !callable.includes(k)) };
  });
  expect(r.missing, 'callable but not in manifest: ' + r.missing.join(',')).toEqual([]);
  expect(r.stale, 'in manifest but not callable: ' + r.stale.join(',')).toEqual([]);
});

test('export(range) is bounded and coherent — uart_puts', async ({ page }) => {
  await page.goto('/fathom.html?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const r = await page.evaluate(async () => {
    const f = window.fathom;
    let unbounded = null; try { f.export(); } catch (e) { unbounded = e.message; }
    await f.loadBottom();
    const x = f.export({ from: 40, to: 46 });
    return { unbounded, cycles: x.pipe.length, first: x.pipe[0].cycle, exec: x.exec.length, gates: x.gates.length, schema: x.schema };
  });
  expect(r.unbounded).toContain('bounded');
  expect(r.cycles).toBe(7); expect(r.first).toBe(40); expect(r.gates).toBe(7); expect(r.schema).toBe('fathom.export/1');
});

test('?p= is a name, never a path or markup', async ({ page }) => {
  await page.goto('/fathom.html?p=%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const d = await page.evaluate(() => window.fathom.describe());
  expect(d.program).toBe('uart_puts');
  expect(await page.locator('img').count()).toBe(0);
});
