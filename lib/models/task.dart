import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.title,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  factory ProjectTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProjectTask(
      id: doc.id,
      title: data['title'] as String? ?? '',
      done: data['done'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'done': done,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
