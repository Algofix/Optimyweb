'use strict';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

const { parsePagespeed } = require('./lib/pagespeed');
const { analyzeEeat } = require('./lib/eeat');
const { buildImprovements } = require('./lib/improvements');

admin.initializeApp();

// Google PageSpeed Insights API key. Set with:
//   firebase functions:secrets:set PSI_API_KEY
const PSI_API_KEY = defineSecret('PSI_API_KEY');

const PSI_ENDPOINT =
  'https://www.googleapis.com/pagespeedonline/v5/runPagespeed';

async function fetchPagespeed(url, strategy, apiKey) {
  const params = new URLSearchParams({ url, strategy });
  params.append('category', 'performance');
  if (apiKey) params.append('key', apiKey);
  const res = await fetch(`${PSI_ENDPOINT}?${params.toString()}`);
  if (!res.ok) {
    throw new Error(`PageSpeed API ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

async function fetchHtml(url) {
  const res = await fetch(url, {
    headers: { 'User-Agent': 'OptimywebBot/1.0 (+analysis)' },
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`Page fetch ${res.status}`);
  const text = await res.text();
  // Cap to keep heuristics fast and memory bounded.
  return text.slice(0, 600 * 1024);
}

/**
 * Runs when the app creates a `projects/{projectId}/analyses/{runId}` doc with
 * status `pending`. Fetches Core Web Vitals + page HTML, analyses them, and
 * writes the results back to the run doc plus a denormalised summary on the
 * project.
 */
exports.runProjectAnalysis = onDocumentCreated(
  {
    document: 'projects/{projectId}/analyses/{runId}',
    secrets: [PSI_API_KEY],
    timeoutSeconds: 120,
    memory: '512MiB',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const run = snap.data() || {};
    if (run.status !== 'pending') return;

    const ref = snap.ref;
    const { projectId } = event.params;
    const url = run.url;
    const strategy = run.strategy || 'mobile';

    if (!url) {
      await ref.update({ status: 'error', error: 'Project has no URL.' });
      return;
    }

    await ref.update({ status: 'running' });

    try {
      const psi = await fetchPagespeed(url, strategy, PSI_API_KEY.value());
      const pagespeed = parsePagespeed(psi, strategy);

      let eeat = { score: 0, signals: [] };
      try {
        const html = await fetchHtml(url);
        eeat = analyzeEeat(html, url);
      } catch (e) {
        logger.warn(`E-E-A-T fetch failed for ${url}: ${e.message}`);
      }

      const improvements = buildImprovements(pagespeed, eeat);

      await ref.update({
        status: 'complete',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        performanceScore: pagespeed.performanceScore,
        lab: pagespeed.lab,
        field: pagespeed.field,
        opportunities: pagespeed.opportunities,
        eeat,
        improvements,
        error: null,
      });

      await admin
        .firestore()
        .doc(`projects/${projectId}`)
        .set(
          {
            latestAnalysis: {
              status: 'complete',
              performanceScore: pagespeed.performanceScore,
              eeatScore: eeat.score,
              lcpMs: pagespeed.lab.lcpMs,
              clsScore: pagespeed.lab.clsScore,
              strategy,
              completedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
          },
          { merge: true },
        );
    } catch (e) {
      logger.error(`Analysis failed for ${url}: ${e.message}`);
      await ref.update({ status: 'error', error: e.message });
      await admin
        .firestore()
        .doc(`projects/${projectId}`)
        .set({ latestAnalysis: { status: 'error' } }, { merge: true });
    }
  },
);
