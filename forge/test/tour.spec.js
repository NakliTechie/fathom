// The first visit, and the tour. The reason both exist: a reader could not tell
// what to do at first glance.
const { test, expect } = require('@playwright/test');

test('a first visit is met by the welcome, which says what the machine is', async ({ page }) => {
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await expect(page.locator('#welcome')).toBeVisible();
  const text = await page.locator('#welcome').innerText();
  expect(text).toContain('three-stage RV32I');
  expect(text).not.toMatch(/\bx86\b/);                      // claims vocabulary (FATHOM.md §2)
  expect(text).not.toMatch(/your computer/i);
  await page.locator('#w-skip').click();
  await expect(page.locator('#welcome')).toBeHidden();
  // the choice sticks: a second visit goes straight to the instrument
  await page.reload();
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await expect(page.locator('#welcome')).toBeHidden();
});

test('the tour walks nine stops and moves the instrument at each one', async ({ page }) => {
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await page.locator('#w-tour').click();
  await expect(page.locator('#tour')).toBeVisible();

  const total = await page.evaluate(() => +document.querySelector('#tour .card .step').textContent.split(' of ')[1]);
  expect(total).toBeGreaterThan(5);
  const seen = [];
  for (let i = 0; ; i++) {
    const card = page.locator('#tour .card');
    await expect(card).toBeVisible();
    const step = await page.evaluate(() => ({
      label: document.querySelector('#tour .card .step').textContent,
      title: document.querySelector('#tour .card h3').textContent,
      focus: window.fathom.focus(),
      cycle: window.fathom.describe().cycle,
      spot: (() => { const r = document.querySelector('#tour .spot').getBoundingClientRect(); return Math.round(r.width * r.height); })(),
    }));
    seen.push(step);
    expect(step.spot, `stop ${i + 1} spotlights nothing`).toBeGreaterThan(0);
    const last = step.label === `${total} of ${total}`;
    await page.locator('#tour #t-next').click();
    await page.waitForTimeout(250);
    if (last) break;
    expect(i).toBeLessThan(total + 2);
  }
  expect(seen).toHaveLength(total);
  await expect(page.locator('#tour')).toBeHidden();
  // it drove the instrument: the cycle moved, layers were focused, the bottom loaded
  expect(new Set(seen.map(s => s.cycle)).size).toBeGreaterThan(1);
  expect(seen.map(s => s.focus)).toContain('cells');
  const loaded = await page.evaluate(() => window.fathom.describe().loaded_layers);
  expect(loaded).toContain('gates');
  expect(loaded).toContain('cells');
  // and it left the instrument open, not stuck in a descent
  expect(await page.evaluate(() => window.fathom.focus())).toBeNull();
});

test('the tour is on the agent face and closes cleanly', async ({ page }) => {
  await page.addInitScript(() => { try { localStorage.setItem('fathom.tour', 'done'); } catch {} });
  await page.goto('/?p=chase');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const at = await page.evaluate(() => window.fathom.tour(2));
  expect(at.step).toBe(3);
  expect(at.of).toBeGreaterThan(5);
  const closed = await page.evaluate(() => window.fathom.tour(-1));
  expect(closed).toBeNull();
  await expect(page.locator('#tour')).toBeHidden();
});

test('any stop can be entered directly — a late one satisfies what it needs', async ({ page }) => {
  await page.addInitScript(() => { try { localStorage.setItem('fathom.tour', 'done'); } catch {} });
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  // straight to the cells stop, found by name, with nothing before it having run
  const at = await page.evaluate(async () => {
    for (let i = 0; i < 20; i++) {
      const r = await window.fathom.tour(i);
      if (!r) break;
      if (/silicon plan/i.test(r.title)) return r;
      if (r.step === r.of) break;
    }
    return null;
  });
  expect(at, 'no stop named "the actual silicon plan"').not.toBeNull();
  await page.waitForFunction(() => window.fathom.focus() === 'cells', { timeout: 30000 });
  const st = await page.evaluate(() => ({
    focus: window.fathom.focus(),
    loaded: window.fathom.describe().loaded_layers,
    spot: (() => { const r = document.querySelector('#tour .spot').getBoundingClientRect(); return Math.round(r.width); })(),
  }));
  expect(st.loaded).toContain('cells');
  expect(st.spot, 'the cells column should be the wide one, not a rail').toBeGreaterThan(200);
});
