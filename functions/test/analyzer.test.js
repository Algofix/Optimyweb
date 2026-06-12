'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const { parsePagespeed, classify } = require('../lib/pagespeed');
const { analyzeEeat } = require('../lib/eeat');
const { buildImprovements } = require('../lib/improvements');

const psi = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'fixtures', 'psi_sample.json'), 'utf8'),
);
const html = fs.readFileSync(
  path.join(__dirname, 'fixtures', 'sample_page.html'),
  'utf8',
);

test('parsePagespeed extracts performance score', () => {
  const r = parsePagespeed(psi, 'mobile');
  assert.equal(r.performanceScore, 72);
  assert.equal(r.strategy, 'mobile');
});

test('parsePagespeed extracts lab metrics', () => {
  const { lab } = parsePagespeed(psi, 'mobile');
  assert.equal(Math.round(lab.lcpMs), 3200);
  assert.equal(lab.clsScore, 0.08);
  assert.equal(lab.ttfbMs, 650);
  assert.equal(lab.tbtMs, 420);
});

test('parsePagespeed extracts CrUX field data (CLS scaled)', () => {
  const { field } = parsePagespeed(psi, 'mobile');
  assert.ok(field);
  assert.equal(field.lcpMs, 2400);
  assert.equal(field.inpMs, 180);
  assert.equal(field.clsScore, 0.08); // percentile 8 -> 0.08
});

test('parsePagespeed lists opportunities sorted by savings, drops zero-savings', () => {
  const { opportunities } = parsePagespeed(psi, 'mobile');
  assert.equal(opportunities.length, 2); // unminified-javascript (0ms) excluded
  assert.equal(opportunities[0].id, 'uses-optimized-images');
  assert.equal(opportunities[0].savingsMs, 1200);
  assert.equal(opportunities[1].savingsMs, 900);
});

test('classify applies Core Web Vitals thresholds', () => {
  assert.equal(classify('lcpMs', 2000), 'good');
  assert.equal(classify('lcpMs', 3200), 'needs-improvement');
  assert.equal(classify('lcpMs', 4500), 'poor');
  assert.equal(classify('clsScore', 0.05), 'good');
  assert.equal(classify('clsScore', 0.3), 'poor');
});

test('analyzeEeat scores a well-formed page highly', () => {
  const r = analyzeEeat(html, 'https://example.com/');
  assert.equal(r.score, 100);
  assert.ok(r.signals.every((s) => s.passed));
});

test('analyzeEeat flags missing signals on a bare page', () => {
  const r = analyzeEeat('<html><body>hi</body></html>', 'http://x.test/');
  assert.ok(r.score < 50);
  const https = r.signals.find((s) => s.id === 'https');
  assert.equal(https.passed, false);
  assert.ok(https.recommendation.length > 0);
});

test('buildImprovements merges and ranks perf + e-e-a-t items', () => {
  const ps = parsePagespeed(psi, 'mobile');
  const eeat = analyzeEeat('<html><body>hi</body></html>', 'http://x.test/');
  const imp = buildImprovements(ps, eeat);
  assert.ok(imp.length >= 3);
  // Highest weighted (image savings 1200ms) should outrank a 1-weight signal.
  assert.equal(imp[0].id, 'cwv:uses-optimized-images');
  assert.equal(imp[0].priority, 1);
  assert.ok(imp.some((i) => i.source === 'eeat'));
});
