import 'package:cloud_firestore/cloud_firestore.dart';

enum AnalysisStatus { pending, running, complete, error, unknown }

AnalysisStatus analysisStatusFromString(String? raw) {
  switch (raw) {
    case 'pending':
      return AnalysisStatus.pending;
    case 'running':
      return AnalysisStatus.running;
    case 'complete':
      return AnalysisStatus.complete;
    case 'error':
      return AnalysisStatus.error;
    default:
      return AnalysisStatus.unknown;
  }
}

/// Core Web Vitals rating used for colour-coding metric values.
enum CwvRating { good, needsImprovement, poor }

/// "Good" thresholds, mirroring `functions/lib/pagespeed.js`.
class CwvThresholds {
  static const lcpMs = [2500.0, 4000.0];
  static const inpMs = [200.0, 500.0];
  static const clsScore = [0.1, 0.25];
  static const fcpMs = [1800.0, 3000.0];
  static const ttfbMs = [800.0, 1800.0];

  static CwvRating? rate(List<double> t, double? value) {
    if (value == null) return null;
    if (value <= t[0]) return CwvRating.good;
    if (value <= t[1]) return CwvRating.needsImprovement;
    return CwvRating.poor;
  }
}

double? _d(dynamic v) => (v as num?)?.toDouble();
int? _i(dynamic v) => (v as num?)?.toInt();

class LabMetrics {
  const LabMetrics({
    this.lcpMs,
    this.clsScore,
    this.fcpMs,
    this.speedIndexMs,
    this.tbtMs,
    this.ttiMs,
    this.ttfbMs,
  });

  final double? lcpMs;
  final double? clsScore;
  final double? fcpMs;
  final double? speedIndexMs;
  final double? tbtMs;
  final double? ttiMs;
  final double? ttfbMs;

  factory LabMetrics.fromMap(Map<String, dynamic>? m) {
    m ??= {};
    return LabMetrics(
      lcpMs: _d(m['lcpMs']),
      clsScore: _d(m['clsScore']),
      fcpMs: _d(m['fcpMs']),
      speedIndexMs: _d(m['speedIndexMs']),
      tbtMs: _d(m['tbtMs']),
      ttiMs: _d(m['ttiMs']),
      ttfbMs: _d(m['ttfbMs']),
    );
  }
}

class FieldMetrics {
  const FieldMetrics({
    this.lcpMs,
    this.inpMs,
    this.clsScore,
    this.fcpMs,
    this.ttfbMs,
  });

  final double? lcpMs;
  final double? inpMs;
  final double? clsScore;
  final double? fcpMs;
  final double? ttfbMs;

  factory FieldMetrics.fromMap(Map<String, dynamic> m) {
    return FieldMetrics(
      lcpMs: _d(m['lcpMs']),
      inpMs: _d(m['inpMs']),
      clsScore: _d(m['clsScore']),
      fcpMs: _d(m['fcpMs']),
      ttfbMs: _d(m['ttfbMs']),
    );
  }
}

class Opportunity {
  const Opportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.savingsMs,
    required this.displayValue,
  });

  final String id;
  final String title;
  final String description;
  final int savingsMs;
  final String displayValue;

  factory Opportunity.fromMap(Map<String, dynamic> m) => Opportunity(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        savingsMs: _i(m['savingsMs']) ?? 0,
        displayValue: m['displayValue'] as String? ?? '',
      );
}

class EeatSignal {
  const EeatSignal({
    required this.id,
    required this.label,
    required this.passed,
    required this.recommendation,
  });

  final String id;
  final String label;
  final bool passed;
  final String recommendation;

  factory EeatSignal.fromMap(Map<String, dynamic> m) => EeatSignal(
        id: m['id'] as String? ?? '',
        label: m['label'] as String? ?? '',
        passed: m['passed'] as bool? ?? false,
        recommendation: m['recommendation'] as String? ?? '',
      );
}

class Improvement {
  const Improvement({
    required this.id,
    required this.source,
    required this.title,
    required this.detail,
    required this.priority,
  });

  final String id;
  final String source; // 'performance' | 'eeat'
  final String title;
  final String detail;
  final int priority;

  factory Improvement.fromMap(Map<String, dynamic> m) => Improvement(
        id: m['id'] as String? ?? '',
        source: m['source'] as String? ?? '',
        title: m['title'] as String? ?? '',
        detail: m['detail'] as String? ?? '',
        priority: _i(m['priority']) ?? 0,
      );
}

class Analysis {
  const Analysis({
    required this.id,
    required this.status,
    this.url,
    this.strategy = 'mobile',
    this.performanceScore,
    this.lab = const LabMetrics(),
    this.field,
    this.opportunities = const [],
    this.eeatScore,
    this.eeatSignals = const [],
    this.improvements = const [],
    this.error,
    this.requestedAt,
    this.completedAt,
  });

  final String id;
  final AnalysisStatus status;
  final String? url;
  final String strategy;
  final int? performanceScore;
  final LabMetrics lab;
  final FieldMetrics? field;
  final List<Opportunity> opportunities;
  final int? eeatScore;
  final List<EeatSignal> eeatSignals;
  final List<Improvement> improvements;
  final String? error;
  final DateTime? requestedAt;
  final DateTime? completedAt;

  bool get isComplete => status == AnalysisStatus.complete;
  bool get isInProgress =>
      status == AnalysisStatus.pending || status == AnalysisStatus.running;

  static List<Map<String, dynamic>> _maps(dynamic v) =>
      (v as List?)?.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() ??
      const [];

  factory Analysis.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final eeat = (data['eeat'] as Map?)?.cast<String, dynamic>();
    return Analysis(
      id: doc.id,
      status: analysisStatusFromString(data['status'] as String?),
      url: data['url'] as String?,
      strategy: data['strategy'] as String? ?? 'mobile',
      performanceScore: _i(data['performanceScore']),
      lab: LabMetrics.fromMap((data['lab'] as Map?)?.cast<String, dynamic>()),
      field: data['field'] is Map
          ? FieldMetrics.fromMap((data['field'] as Map).cast<String, dynamic>())
          : null,
      opportunities:
          _maps(data['opportunities']).map(Opportunity.fromMap).toList(),
      eeatScore: eeat != null ? _i(eeat['score']) : null,
      eeatSignals:
          _maps(eeat?['signals']).map(EeatSignal.fromMap).toList(),
      improvements:
          _maps(data['improvements']).map(Improvement.fromMap).toList(),
      error: data['error'] as String?,
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
