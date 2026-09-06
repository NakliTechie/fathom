const { chromium, firefox, webkit } = require('@playwright/test');
const ENGINES = { chromium, firefox, webkit };
(async () => {
  const out = [];
  for (const [name, engine] of Object.entries(ENGINES)) {
    const row = { engine: name };
    let b;
    try {
      b = await engine.launch();
      const ctx = await b.newContext({ viewport: { width: 1600, height: 900 } });
      const page = await ctx.newPage();
      const errs = [];
      page.on('pageerror', e => errs.push(String(e).slice(0, 140)));
      page.on('console', m => { if (m.type() === 'error') errs.push(m.text().slice(0, 140)); });
      await page.addInitScript(() => { try { localStorage.setItem('fathom.tour', 'done'); } catch {} });
      await page.goto('https://fathom.naklitechie.com/?p=uart_puts', { waitUntil: 'load' });
      await page.waitForFunction(() => window.fathom && window.fathom.describe().loaded, { timeout: 30000 });
      row.upper_layers = 'ok';
      row.columns = await page.evaluate(() => document.querySelectorAll('#layers .layer').length);
      row.first_frame_ms = await page.evaluate(() => window.fathom.timing().built_ms);
      // the run control
      await page.evaluate(() => { window.fathom.seek(0); window.fathom.play({ cps: 60, loop: true }); });
      await page.waitForFunction(() => window.fathom.describe().cycle > 5, { timeout: 10000 })
        .then(() => { row.run = 'ok'; }).catch(() => { row.run = 'DID NOT ADVANCE'; });
      await page.evaluate(() => window.fathom.pause());
      // the bottom layers: wasm + worker + parquet, the riskiest part cross-engine
      try {
        const t0 = Date.now();
        await page.evaluate(() => window.fathom.loadBottom());
        row.bottom_ms = Date.now() - t0;
        row.cells = await page.evaluate(() => window.fathom.stateAt('cells', 43).cells_switching);
        row.gates = await page.evaluate(() => window.fathom.stateAt('gates', 43).toggles);
        row.bottom = 'ok';
      } catch (e) { row.bottom = 'FAILED: ' + String(e.message).slice(0, 120); }
      row.errors = errs.slice(0, 3);
      await b.close();
    } catch (e) {
      row.fatal = String(e.message).slice(0, 160);
      if (b) await b.close().catch(() => {});
    }
    out.push(row);
  }
  console.log(JSON.stringify(out, null, 1));
})();
