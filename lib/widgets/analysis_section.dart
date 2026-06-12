import 'package:flutter/material.dart';

import '../models/analysis.dart';

String _formatMs(double? v) {
  if (v == null) return '—';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} s';
  return '${v.round()} ms';
}

String _formatCls(double? v) => v == null ? '—' : v.toStringAsFixed(2);

Color _ratingColor(CwvRating? r, ColorScheme cs) {
  switch (r) {
    case CwvRating.good:
      return const Color(0xFF0CCE6B);
    case CwvRating.needsImprovement:
      return const Color(0xFFFFA400);
    case CwvRating.poor:
      return const Color(0xFFFF4E42);
    case null:
      return cs.outlineVariant;
  }
}

Color _scoreColor(int? score) {
  if (score == null) return const Color(0xFF9AA0A6);
  if (score >= 90) return const Color(0xFF0CCE6B);
  if (score >= 50) return const Color(0xFFFFA400);
  return const Color(0xFFFF4E42);
}

/// Dashboard that triggers and displays an automated Core Web Vitals +
/// E-E-A-T analysis for a project.
class AnalysisSection extends StatelessWidget {
  const AnalysisSection({
    super.key,
    required this.analysis,
    required this.hasUrl,
    required this.busy,
    required this.onRun,
  });

  final Analysis? analysis;
  final bool hasUrl;
  final bool busy;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = analysis;
    final inProgress = busy || (a?.isInProgress ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Web Vitals & E-E-A-T',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.icon(
                  onPressed: (!hasUrl || inProgress) ? null : onRun,
                  icon: inProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    inProgress
                        ? 'Analyzing…'
                        : (a?.isComplete == true ? 'Re-run' : 'Run analysis'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _body(context, a, inProgress),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Analysis? a, bool inProgress) {
    final theme = Theme.of(context);
    if (!hasUrl) {
      return _hint(theme, 'Add a website URL to this project to analyze it.');
    }
    if (a == null && !inProgress) {
      return _hint(
        theme,
        'No analysis yet. Run one to get Core Web Vitals (LCP, INP, CLS) '
        'and E-E-A-T signals with prioritized improvements.',
      );
    }
    if (inProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Analyzing ${a?.url ?? ''}…', style: theme.textTheme.bodySmall),
        ],
      );
    }
    if (a!.status == AnalysisStatus.error) {
      return _hint(
        theme,
        'Analysis failed: ${a.error ?? 'unknown error'}',
        color: theme.colorScheme.error,
      );
    }

    final field = a.field;
    final lcp = field?.lcpMs ?? a.lab.lcpMs;
    final inp = field?.inpMs ?? a.lab.tbtMs; // TBT is the lab proxy for INP
    final inpIsField = field?.inpMs != null;
    final cls = field?.clsScore ?? a.lab.clsScore;
    final fcp = field?.fcpMs ?? a.lab.fcpMs;
    final ttfb = field?.ttfbMs ?? a.lab.ttfbMs;
    final source = field != null ? 'field (CrUX)' : 'lab';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreRing(label: 'Performance', score: a.performanceScore),
            _ScoreRing(label: 'E-E-A-T', score: a.eeatScore),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Core Web Vitals',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('· $source', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricCard(
              label: 'LCP',
              value: _formatMs(lcp),
              rating: CwvThresholds.rate(CwvThresholds.lcpMs, lcp),
            ),
            _MetricCard(
              label: inpIsField ? 'INP' : 'TBT',
              value: _formatMs(inp),
              rating: CwvThresholds.rate(CwvThresholds.inpMs, inp),
            ),
            _MetricCard(
              label: 'CLS',
              value: _formatCls(cls),
              rating: CwvThresholds.rate(CwvThresholds.clsScore, cls),
            ),
            _MetricCard(
              label: 'FCP',
              value: _formatMs(fcp),
              rating: CwvThresholds.rate(CwvThresholds.fcpMs, fcp),
            ),
            _MetricCard(
              label: 'TTFB',
              value: _formatMs(ttfb),
              rating: CwvThresholds.rate(CwvThresholds.ttfbMs, ttfb),
            ),
          ],
        ),
        if (a.improvements.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Recommended improvements',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...a.improvements.map((i) => _ImprovementTile(improvement: i)),
        ],
        if (a.eeatSignals.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('E-E-A-T signals',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...a.eeatSignals.map((s) => _SignalTile(signal: s)),
        ],
      ],
    );
  }

  Widget _hint(ThemeData theme, String text, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.label, required this.score});
  final String label;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(score);
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: (score ?? 0) / 100,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                score?.toString() ?? '—',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.rating,
  });
  final String label;
  final String value;
  final CwvRating? rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _ratingColor(rating, theme.colorScheme);
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ImprovementTile extends StatelessWidget {
  const _ImprovementTile({required this.improvement});
  final Improvement improvement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPerf = improvement.source == 'performance';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${improvement.priority}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPerf ? Icons.bolt : Icons.verified_user_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        improvement.title,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (improvement.detail.isNotEmpty)
                  Text(improvement.detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});
  final EeatSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            signal.passed ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: signal.passed
                ? const Color(0xFF0CCE6B)
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.label, style: theme.textTheme.bodyMedium),
                if (!signal.passed && signal.recommendation.isNotEmpty)
                  Text(
                    signal.recommendation,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
