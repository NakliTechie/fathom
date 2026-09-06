// Columns at three widths. The live-check flagged this: seven columns were verified
// only at 1568 px, and below that each column was narrower than its content.
const { test, expect } = require('./fixtures');

const WIDTHS = [
  { name: 'wide',    w: 1920, h: 1000, minCol: 240 },
  { name: 'laptop',  w: 1280, h: 800,  minCol: 220 },
  { name: 'phone',   w: 390,  h: 844,  minCol: 260 },
];

for (const v of WIDTHS) {
  test(`columns stay readable and the page never scrolls sideways — ${v.name} ${v.w}px`, async ({ page }) => {
    await page.setViewportSize({ width: v.w, height: v.h });
    await page.goto('/?p=uart_puts');
    await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
    const m = await page.evaluate(() => {
      const L = document.getElementById('layers');
      const cols = [...document.querySelectorAll('#layers .layer')].map(e => e.getBoundingClientRect().width);
      return {
        cols: cols.map(Math.round),
        docOverflowX: document.documentElement.scrollWidth > document.documentElement.clientWidth,
        bodyOverflowX: document.body.scrollWidth > document.body.clientWidth,
        stripScrolls: L.scrollWidth > L.clientWidth,
      };
    });
    expect(m.cols).toHaveLength(7);
    // no column is narrower than the floor: a column too thin to read is the defect
    expect(Math.min(...m.cols), `narrowest column ${Math.min(...m.cols)}px`).toBeGreaterThanOrEqual(v.minCol);
    // the PAGE never scrolls sideways; only the layer strip may
    expect(m.docOverflowX, 'the document scrolls sideways').toBe(false);
    expect(m.bodyOverflowX, 'the body scrolls sideways').toBe(false);
  });
}

test('a descent keeps the focused column on screen at laptop width', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  await page.evaluate(() => window.fathom.loadBottom());
  for (const layer of ['source', 'asm', 'pipe', 'cells']) {
    const r = await page.evaluate((l) => {
      window.fathom.descend(l);
      const b = document.getElementById('L-' + l).getBoundingClientRect();
      return { left: Math.round(b.left), right: Math.round(b.right), w: Math.round(b.width), vw: innerWidth };
    }, layer);
    expect(r.w, `${layer} focused column is only ${r.w}px`).toBeGreaterThan(300);
    expect(r.left, `${layer} starts off-screen`).toBeGreaterThanOrEqual(-1);
    expect(r.right, `${layer} ends off-screen`).toBeLessThanOrEqual(r.vw + 1);
  }
});

test('the tour reads its numbers from the artifact, not from a literal', async ({ page }) => {
  await page.goto('/?p=uart_puts');
  await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded);
  const text = await page.evaluate(async () => {
    await window.fathom.tour(7);
    return document.querySelector('#tour .card p').textContent;
  });
  const cells = await page.evaluate(() => fetch('/artifacts/uart_puts/descent.json').then(r => r.json()).then(a => a.cells.cells.length));
  expect(text).toContain(cells.toLocaleString());
});
