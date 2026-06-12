# Optimyweb Cloud Functions

Automated **Core Web Vitals** + **E-E-A-T** analysis backend.

## How it works

When the app creates an analysis run document at
`projects/{projectId}/analyses/{runId}` with `status: "pending"`, the
`runProjectAnalysis` Firestore trigger:

1. Calls the **PageSpeed Insights** API for the project URL (Core Web Vitals:
   LCP, INP, CLS, FCP, TTFB + Lighthouse opportunities).
2. Fetches the page HTML and runs transparent **E-E-A-T** heuristics
   (HTTPS, structured data, author/byline, about/contact/privacy pages,
   freshness dates, external citations).
3. Merges both into a ranked `improvements` list.
4. Writes results back to the run doc (`status: "complete"`) and a denormalised
   `latestAnalysis` summary on the project.

The analysis logic is dependency-free and unit-tested:

```bash
cd functions
npm test          # node --test against fixtures in test/
```

## Deploy

```bash
cd functions && npm install
firebase functions:secrets:set PSI_API_KEY   # Google PageSpeed Insights API key
firebase deploy --only functions
```

Requires the Blaze plan (outbound network to PageSpeed Insights + target sites).

## Notes

- E-E-A-T has no official Google score/API; the signals here are a transparent,
  editable heuristic in `lib/eeat.js`.
- Core Web Vitals thresholds mirror the client (`lib/pagespeed.js` ↔
  `lib/models/analysis.dart`).
