// forge/test/descent.test.js -- the C4 checkpoint, as a script.
//
// Drives a full descent and a full ascent THROUGH THE AGENT FACE, never the
// DOM, and asserts layer coherence at every stop. Returns a verdict object;
// exit code is the caller's (a harness reads `ok`).
//
// Run today from the browser pane's console or javascript tool:
//     await (await import('./forge/test/descent.test.js')).run(window.fathom, document)
// A Playwright harness (C5, shared with the guide capture) calls the same
// function. The DOM reads below are ASSERTIONS about what the face did, not
// the way the test drives the instrument.
export async function run(fathom, document) {
  const log = [];
  const fail = (m) => { log.push('FAIL ' + m); };
  if (!fathom.describe().loaded) return { ok: false, log: ['no descent loaded'] };
  await fathom.loadBottom();

  const stopState = (c) => {
    const p = fathom.stateAt('pipe', c), g = fathom.stateAt('gates', c), cl = fathom.stateAt('cells', c);
    const focusEl = document.querySelector('#layers .layer.focus');
    return {
      cycles: [p.cycle, g.cycle, cl.cycle],
      scrub: +document.getElementById('scrub').value,
      bar: +document.querySelector('#L-gates .bar.now').dataset.cycle,
      col: +document.querySelector('#L-pipe .col.now').dataset.cycle,
      focusDom: focusEl ? focusEl.id.replace(/^L-/, '') : null,
    };
  };

  const prog = fathom.describe().program;
  const srcFile = `forge/program/${prog}.c`;
  const plan = [
    ['source', `${srcFile}:${firstExecutedLine(fathom, srcFile)}`],
    ['ir', undefined], ['asm', undefined], ['arch', 'sp'],
    ['pipe', undefined], ['gates', undefined], ['cells', undefined],
  ];
  const stops = [];
  for (const [layer, sel] of plan) {
    const r = fathom.descend(layer, sel);
    const s = stopState(r.cycle);
    const coherent = s.cycles.every(v => v === r.cycle) && s.scrub === r.cycle && s.bar === r.cycle && s.col === r.cycle;
    if (!coherent) fail(`${layer}: cycles ${JSON.stringify(s)} != ${r.cycle}`);
    if (s.focusDom !== layer || fathom.focus() !== layer) fail(`${layer}: focus is ${s.focusDom}/${fathom.focus()}`);
    if (r.depth !== stops.length + 1) fail(`${layer}: depth ${r.depth}`);
    stops.push({ layer, cycle: r.cycle, depth: r.depth, coherent });
  }
  if (fathom.trail().length !== plan.length) fail(`trail length ${fathom.trail().length}`);

  const ascent = [];
  const expect = stops.map(s => s.layer).reverse().slice(1).concat([null]);
  for (const want of expect) {
    const r = fathom.ascend();
    const s = stopState(r.cycle);
    if (r.layer !== want) fail(`ascend: at ${r.layer}, expected ${want}`);
    if (want && (s.focusDom !== want || fathom.focus() !== want)) fail(`ascend ${want}: focus ${s.focusDom}`);
    if (want) { const st = stops.find(x => x.layer === want); if (st.cycle !== r.cycle) fail(`ascend ${want}: cycle ${r.cycle} != ${st.cycle}`); }
    ascent.push({ layer: r.layer, cycle: r.cycle, depth: r.depth });
  }
  if (fathom.focus() !== null || fathom.trail().length !== 0) fail('did not return to all layers');

  const agentCalls = fathom.history().filter(h => h.door === 'agent' && (h.op === 'descend' || h.op === 'ascend')).length;
  if (agentCalls !== plan.length * 2) fail(`agent-door calls ${agentCalls} != ${plan.length * 2}`);

  const ok = log.length === 0;
  return { ok, program: prog, stops, ascent, agentCalls, log: ok ? ['OK'] : log };
}

function firstExecutedLine(fathom, file) {
  // the lowest source line of `file` that any executed instruction came from
  let best = Infinity;
  for (let c = 0; ; c++) {
    let s; try { s = fathom.stateAt('source', c); } catch { break; }
    if (s === undefined) break;
    for (const ref of s) { const [f, line] = [ref.slice(0, ref.lastIndexOf(':', ref.lastIndexOf(':') - 1)), +ref.split(':').at(-2)]; if (f === file && line < best) best = line; }
    if (c > fathom.describe().cycles) break;
  }
  return best === Infinity ? 1 : best;
}
