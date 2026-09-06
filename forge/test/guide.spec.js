// @guide — reproducible captures for the guide. Drives the instrument through
// window.fathom, then screenshots. Re-run to regenerate; never hand-edit output.
const { test } = require('@playwright/test');
const path = require('path');
const OUT = path.resolve(__dirname, '../../guide/captures');
const shot = (page, name) => page.screenshot({ path: path.join(OUT, name + '.png'), fullPage: false });

test('@guide captures', async ({ page }) => {
  await page.goto('/index.html?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await page.evaluate(() => document.fonts.ready);
  await shot(page, '01-all-layers');                                   // the instrument as it opens
  await page.evaluate(() => window.fathom.seek(43));                   // the first UART byte retiring
  await shot(page, '02-cycle-43');
  await page.evaluate(() => window.fathom.descend('source', 'forge/program/uart_puts.c:5'));
  await shot(page, '03-descend-source');
  await page.evaluate(() => window.fathom.descend('asm'));
  await shot(page, '04-descend-asm');
  await page.evaluate(() => window.fathom.descend('pipe'));
  await shot(page, '05-descend-pipe');
  await page.evaluate(async () => { await window.fathom.loadBottom(); });
  await page.evaluate(() => window.fathom.descend('gates'));
  await page.waitForTimeout(150);
  await shot(page, '06-descend-gates');
  await page.evaluate(() => window.fathom.descend('cells'));
  await page.waitForTimeout(150);
  await shot(page, '07-descend-cells');
  await page.evaluate(() => { while (window.fathom.trail().length) window.fathom.ascend(); });
  await page.evaluate(() => window.fathom.help(true));
  await shot(page, '08-help');
  await page.evaluate(() => window.fathom.help(false));
  await page.goto('/index.html?p=popcount');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await page.evaluate(async () => { await window.fathom.loadBottom(); window.fathom.seek(122); });
  await page.waitForTimeout(200);
  await shot(page, '09-popcount-branch-flush');
});
