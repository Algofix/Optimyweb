'use strict';

// E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness) is not
// something Google exposes a score for. These are transparent, heuristic
// on-page signals that correlate with the quality factors Google describes.
// Pure function — operates on raw HTML, no external dependencies.

function test(re, html) {
  return re.test(html);
}

function analyzeEeat(html, pageUrl) {
  const h = html || '';
  const url = pageUrl || '';

  const checks = [
    {
      id: 'https',
      label: 'Served over HTTPS',
      weight: 2,
      passed: url.startsWith('https://'),
      recommendation: 'Serve the site over HTTPS to establish baseline trust.',
    },
    {
      id: 'structured-data',
      label: 'Structured data (schema.org)',
      weight: 2,
      passed:
        test(/application\/ld\+json/i, h) ||
        test(/itemtype=["']https?:\/\/schema\.org/i, h),
      recommendation:
        'Add schema.org structured data (Organization, Article, Person) so search engines can verify entities.',
    },
    {
      id: 'author',
      label: 'Identifiable author / byline',
      weight: 2,
      passed:
        test(/rel=["']author["']/i, h) ||
        test(/"@type"\s*:\s*"Person"/i, h) ||
        test(/class=["'][^"']*author/i, h),
      recommendation:
        'Attribute content to a named author with a bio to demonstrate expertise and experience.',
    },
    {
      id: 'about',
      label: 'About page linked',
      weight: 1,
      passed: test(/href=["'][^"']*about/i, h),
      recommendation: 'Link a clear About page describing who is behind the site.',
    },
    {
      id: 'contact',
      label: 'Contact information linked',
      weight: 1,
      passed: test(/href=["'][^"']*contact/i, h) || test(/mailto:/i, h),
      recommendation: 'Provide reachable contact details to build trust.',
    },
    {
      id: 'privacy',
      label: 'Privacy / policy page',
      weight: 1,
      passed: test(/href=["'][^"']*(privacy|terms)/i, h),
      recommendation: 'Publish privacy and terms pages, a key trust signal.',
    },
    {
      id: 'freshness',
      label: 'Publish / update dates',
      weight: 1,
      passed:
        test(/datePublished|dateModified/i, h) || test(/<time[\s>]/i, h),
      recommendation:
        'Expose published/updated dates so readers and crawlers can judge freshness.',
    },
    {
      id: 'citations',
      label: 'External citations',
      weight: 1,
      passed: (h.match(/<a\s[^>]*href=["']https?:\/\//gi) || []).length >= 2,
      recommendation:
        'Cite authoritative external sources to support claims.',
    },
  ];

  const signals = checks.map((c) => ({
    id: c.id,
    label: c.label,
    passed: c.passed,
    weight: c.weight,
    recommendation: c.passed ? '' : c.recommendation,
  }));

  const total = checks.reduce((s, c) => s + c.weight, 0);
  const earned = checks.reduce((s, c) => s + (c.passed ? c.weight : 0), 0);
  const score = total > 0 ? Math.round((earned / total) * 100) : 0;

  return { score, signals };
}

module.exports = { analyzeEeat };
