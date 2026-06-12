'use strict';

// Merges Core Web Vitals opportunities and failing E-E-A-T signals into a
// single, ranked list of actionable improvements. Pure function.

function buildImprovements(pagespeed, eeat) {
  const items = [];

  const opps = (pagespeed && pagespeed.opportunities) || [];
  for (const o of opps) {
    items.push({
      id: `cwv:${o.id}`,
      source: 'performance',
      title: o.title,
      detail: o.displayValue || o.description || '',
      // Rank performance items by estimated time saved.
      weight: o.savingsMs || 0,
    });
  }

  const signals = (eeat && eeat.signals) || [];
  for (const s of signals) {
    if (s.passed) continue;
    items.push({
      id: `eeat:${s.id}`,
      source: 'eeat',
      title: s.label,
      detail: s.recommendation || '',
      // Scale E-E-A-T weights into a comparable range with perf savings.
      weight: (s.weight || 1) * 400,
    });
  }

  items.sort((a, b) => b.weight - a.weight);

  return items.map((it, i) => ({
    id: it.id,
    source: it.source,
    title: it.title,
    detail: it.detail,
    priority: i + 1,
  }));
}

module.exports = { buildImprovements };
