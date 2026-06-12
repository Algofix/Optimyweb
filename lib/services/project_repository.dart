import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/analysis.dart';
import '../models/project.dart';
import '../models/task.dart';

class ProjectRepository {
  ProjectRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection('projects');

  Stream<List<Project>> watchProjects({ProjectStatus? statusFilter}) {
    final Query<Map<String, dynamic>> query =
        _projects.orderBy('updatedAt', descending: true);

    return query.snapshots().map((snap) {
      var list = snap.docs.map(Project.fromFirestore).toList();
      if (statusFilter != null) {
        list = list.where((p) => p.status == statusFilter).toList();
      }
      return list;
    });
  }

  Stream<Project?> watchProject(String id) {
    return _projects.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Project.fromFirestore(doc);
    });
  }

  Future<String> saveProject(Project project, {bool isNew = false}) async {
    final ref = isNew ? _projects.doc() : _projects.doc(project.id);
    await ref.set(project.copyWithId(ref.id).toFirestore(isNew: isNew));
    return ref.id;
  }

  Future<void> deleteProject(String id) async {
    final tasks = await _projects.doc(id).collection('tasks').get();
    final batch = _db.batch();
    for (final doc in tasks.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_projects.doc(id));
    await batch.commit();
  }

  Stream<List<ProjectTask>> watchTasks(String projectId) {
    return _projects
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(ProjectTask.fromFirestore).toList());
  }

  Future<void> addTask(String projectId, String title) async {
    await _projects.doc(projectId).collection('tasks').add({
      'title': title.trim(),
      'done': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _touchProject(projectId);
  }

  Future<void> toggleTask(String projectId, ProjectTask task) async {
    await _projects.doc(projectId).collection('tasks').doc(task.id).update({
      'done': !task.done,
    });
    await _touchProject(projectId);
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _projects.doc(projectId).collection('tasks').doc(taskId).delete();
    await _touchProject(projectId);
  }

  /// Latest analysis run for a project (most recently requested).
  Stream<Analysis?> watchLatestAnalysis(String projectId) {
    return _projects
        .doc(projectId)
        .collection('analyses')
        .orderBy('requestedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : Analysis.fromFirestore(snap.docs.first));
  }

  /// Queues an analysis run. The `runProjectAnalysis` Cloud Function picks up
  /// the `pending` doc, fetches Core Web Vitals + E-E-A-T, and fills it in.
  Future<void> requestAnalysis(
    String projectId, {
    required String url,
    String strategy = 'mobile',
  }) async {
    await _projects.doc(projectId).collection('analyses').add({
      'status': 'pending',
      'url': url,
      'strategy': strategy,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setProjectImageUrl(String projectId, String url) async {
    await _projects.doc(projectId).update({
      'imageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _touchProject(String projectId) async {
    await _projects.doc(projectId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

extension on Project {
  Project copyWithId(String id) => Project(
        id: id,
        name: name,
        url: url,
        goal: goal,
        status: status,
        priority: priority,
        createdAt: createdAt,
        updatedAt: updatedAt,
        imageUrl: imageUrl,
      );
}
