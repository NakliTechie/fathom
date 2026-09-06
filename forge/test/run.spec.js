// Running the program. A scrub bar alone never says "this is a machine that runs";
// these assert that pressing Run actually advances every layer on one clock.
const { test, expect } = require('./fixtures');

test('Run advances the cycle, and Pause holds it', async ({ page }) => {
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await page.evaluate(() => { window.fathom.seek(0); window.fathom.play({ cps: 30, loop: false }); });
  expect(await page.evaluate(() => window.fathom.playing().on)).toBe(true);
  await page.waitForFunction(() => window.fathom.describe().cycle > 10, { timeout: 10000 });
  const moving = await page.evaluate(() => window.fathom.describe().cycle);
  await page.evaluate(() => window.fathom.pause());
  const a = await page.evaluate(() => window.fathom.describe().cycle);
  await page.waitForTimeout(500);
  const b = await page.evaluate(() => window.fathom.describe().cycle);
  expect(moving).toBeGreaterThan(10);
  expect(b, 'the cycle moved after pause').toBe(a);
  expect(await page.evaluate(() => window.fathom.playing().on)).toBe(false);
});

test('running moves every layer, and the registers actually change', async ({ page }) => {
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await page.evaluate(() => window.fathom.loadBottom());
  // sample the register file while it runs: it must not be a still picture
  const seen = await page.evaluate(async () => {
    const f = window.fathom;
    f.seek(0); f.play({ cps: 60, loop: true });
    const snaps = [];
    for (let i = 0; i < 12; i++) {
      await new Promise(r => setTimeout(r, 60));
      const s = f.stateAt('arch');
      snaps.push({ cycle: f.describe().cycle, sp: s.regs.x2, a0: s.regs.x10, gates: f.stateAt('gates').toggles });
    }
    f.pause();
    return snaps;
  });
  expect(new Set(seen.map(s => s.cycle)).size, 'the cycle never changed').toBeGreaterThan(4);
  expect(new Set(seen.map(s => s.a0)).size, 'a0 never changed while running').toBeGreaterThan(1);
  expect(new Set(seen.map(s => s.gates)).size, 'gate activity never changed').toBeGreaterThan(1);
  // the DOM followed, not just the model
  const domCycle = await page.evaluate(() => +document.getElementById('scrub').value);
  const modelCycle = await page.evaluate(() => window.fathom.describe().cycle);
  expect(domCycle).toBe(modelCycle);
});

test('loop wraps at the end; without loop it stops on the last cycle', async ({ page }) => {
  await page.goto('/?p=chase');                                   // 80 cycles: quickest to the end
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const end = await page.evaluate(() => window.fathom.describe().cycles - 1);
  await page.evaluate((e) => { window.fathom.seek(e - 3); window.fathom.play({ cps: 30, loop: false }); }, end);
  await page.waitForFunction(() => window.fathom.playing().on === false, { timeout: 10000 });
  expect(await page.evaluate(() => window.fathom.describe().cycle), 'should stop on the last cycle').toBe(end);
  // with loop on, it passes the end and keeps going
  await page.evaluate((e) => { window.fathom.seek(e - 2); window.fathom.play({ cps: 60, loop: true }); }, end);
  await page.waitForFunction((e) => window.fathom.describe().cycle < e - 5, end, { timeout: 10000 });
  expect(await page.evaluate(() => window.fathom.playing().on)).toBe(true);
  await page.evaluate(() => window.fathom.pause());
});

test('the space bar runs it, and dragging the scrub bar takes the wheel back', async ({ page }) => {
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await page.locator('body').press(' ');
  expect(await page.evaluate(() => window.fathom.playing().on)).toBe(true);
  await page.waitForFunction(() => window.fathom.describe().cycle > 3, { timeout: 10000 });
  // a real drag on the scrub bar should pause: the reader took control
  await page.locator('#scrub').fill('60');
  await page.locator('#scrub').dispatchEvent('input');
  expect(await page.evaluate(() => window.fathom.playing().on), 'scrubbing should pause the run').toBe(false);
  expect(await page.evaluate(() => window.fathom.describe().cycle)).toBe(60);
});
