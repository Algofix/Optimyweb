'use strict';

// Core Web Vitals "good" thresholds (https://web.dev/articles/vitals).
const THRESHOLDS = {
  lcpMs: { good: 2500, poor: 4000 },
  inpMs: { good: 200, poor: 500 },
  clsScore: { good: 0.1, poor: 0.25 },
  fcpMs: { good: 1800, poor: 3000 },
  ttfbMs: { good: 800, poor: 1800 },
};

function classify(metric, value) {
  const t = THRESHOLDS[metric];
  if (!t || value == null) return null;
  if (value <= t.good) return 'good';
  if (value <= t.poor) return 'needs-improvement';
  return 'poor';
}

/**
 * Normalises a PageSpeed Insights v5 API response into the shape the app
 * stores in Firestore. Pure function — no external dependencies.
 */
function parsePagespeed(psi, strategy) {
  const lr = (psi && psi.lighthouseResult) || {};
  const audits = lr.audits || {};

  const numeric = (id) => {
    const a = audits[id];
    return a && typeof a.numericValue === 'number' ? a.numericValue : null;
  };

  const lab = {
    lcpMs: numeric('largest-contentful-paint'),
    clsScore: numeric('cumulative-layout-shift'),
    fcpMs: numeric('first-contentful-paint'),
    speedIndexMs: numeric('speed-index'),
    tbtMs: numeric('total-blocking-time'),
    ttiMs: numeric('interactive'),
    ttfbMs: numeric('server-response-time'),
  };

  const perf = lr.categories && lr.categories.performance;
  const performanceScore =
    perf && typeof perf.score === 'number' ? Math.round(perf.score * 100) : null;

  const leMetrics =
    (psi && psi.loadingExperience && psi.loadingExperience.metrics) || {};
  const fieldVal = (key, transform) => {
    const m = leMetrics[key];
    if (!m || typeof m.percentile !== 'number') return null;
    return transform ? transform(m.percentile) : m.percentile;
  };
  const field = {
    lcpMs: fieldVal('LARGEST_CONTENTFUL_PAINT_MS'),
    inpMs: fieldVal('INTERACTION_TO_NEXT_PAINT'),
    clsScore: fieldVal('CUMULATIVE_LAYOUT_SHIFT_SCORE', (p) => p / 100),
    fcpMs: fieldVal('FIRST_CONTENTFUL_PAINT_MS'),
    ttfbMs: fieldVal('EXPERIMENTAL_TIME_TO_FIRST_BYTE'),
  };
  const hasField = Object.values(field).some((v) => v != null);

  const opportunities = Object.keys(audits)
    .map((id) => audits[id])
    .filter(
      (a) =>
        a &&
        a.details &&
        a.details.type === 'opportunity' &&
        typeof a.details.overallSavingsMs === 'number' &&
        a.details.overallSavingsMs > 0,
    )
    .map((a) => ({
      id: a.id,
      title: a.title || a.id,
      description: a.description || '',
      savingsMs: Math.round(a.details.overallSavingsMs),
      displayValue: a.displayValue || '',
      score: typeof a.score === 'number' ? a.score : null,
    }))
    .sort((x, y) => y.savingsMs - x.savingsMs);

  return {
    strategy: strategy || 'mobile',
    performanceScore,
    lab,
    field: hasField ? field : null,
    opportunities,
  };
}

module.exports = { parsePagespeed, classify, THRESHOLDS };
