import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus { draft, active, done }

extension ProjectStatusX on ProjectStatus {
  String get value => name;

  static ProjectStatus fromString(String? raw) {
    return ProjectStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ProjectStatus.draft,
    );
  }

  String get label {
    switch (this) {
      case ProjectStatus.draft:
        return 'Draft';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.done:
        return 'Done';
    }
  }
}

class Project {
  const Project({
    required this.id,
    required this.name,
    this.url,
    required this.goal,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? url;
  final String goal;
  final ProjectStatus status;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Project.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Project(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled',
      url: data['url'] as String?,
      goal: data['goal'] as String? ?? '',
      status: ProjectStatusX.fromString(data['status'] as String?),
      priority: (data['priority'] as num?)?.toInt() ?? 2,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    final map = <String, dynamic>{
      'name': name,
      'url': url?.trim().isEmpty == true ? null : url?.trim(),
      'goal': goal,
      'status': status.value,
      'priority': priority,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    return map;
  }
}
