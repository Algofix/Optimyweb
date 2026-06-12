import 'package:flutter/material.dart';

import '../models/analysis.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/project_repository.dart';
import '../services/storage_service.dart';
import '../utils/image_picker.dart';
import '../widgets/analysis_section.dart';
import '../widgets/project_cover.dart';
import '../widgets/project_url_link.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _repo = ProjectRepository();
  final _storage = StorageService();
  final _taskCtrl = TextEditingController();
  bool _uploadingCover = false;
  bool _requestingAnalysis = false;

  Future<void> _runAnalysis(Project project) async {
    final url = project.url;
    if (url == null || url.trim().isEmpty) return;
    setState(() => _requestingAnalysis = true);
    try {
      await _repo.requestAnalysis(project.id, url: url.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start analysis: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingAnalysis = false);
    }
  }

  @override
  void dispose() {
    _taskCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadCover(Project project) async {
    final picked = await pickImage();
    if (picked == null || !mounted) return;
    setState(() => _uploadingCover = true);
    try {
      final url = await _storage.uploadProjectCover(
        project.id,
        picked.bytes,
        contentType: picked.contentType,
      );
      await _repo.setProjectImageUrl(project.id, url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _addTask() async {
    final title = _taskCtrl.text.trim();
    if (title.isEmpty) return;
    _taskCtrl.clear();
    try {
      await _repo.addTask(widget.projectId, title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add task: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Project project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('Remove "${project.name}" and all its tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _repo.deleteProject(widget.projectId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Project?>(
      stream: _repo.watchProject(widget.projectId),
      builder: (context, projectSnap) {
        final project = projectSnap.data;
        if (projectSnap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(projectSnap.error.toString())),
          );
        }
        if (!projectSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Project not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProjectFormScreen(existing: project),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(project),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              ProjectCover(
                imageUrl: project.imageUrl,
                uploading: _uploadingCover,
                onUpload: () => _uploadCover(project),
              ),
              const SizedBox(height: 12),
              _ProjectHeader(project: project),
              const SizedBox(height: 12),
              StreamBuilder<Analysis?>(
                stream: _repo.watchLatestAnalysis(widget.projectId),
                builder: (context, analysisSnap) {
                  return AnalysisSection(
                    analysis: analysisSnap.data,
                    hasUrl: project.url != null && project.url!.trim().isNotEmpty,
                    busy: _requestingAnalysis,
                    onRun: () => _runAnalysis(project),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 8),
                child: Text(
                  'Tasks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add a task…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<ProjectTask>>(
                stream: _repo.watchTasks(widget.projectId),
                builder: (context, taskSnap) {
                  if (taskSnap.hasError) {
                    return Center(child: Text(taskSnap.error.toString()));
                  }
                  if (!taskSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final tasks = taskSnap.data!;
                  if (tasks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No tasks yet — add one above')),
                    );
                  }
                  return Column(
                    children: tasks
                        .map(
                          (task) => CheckboxListTile(
                            value: task.done,
                            onChanged: (_) =>
                                _repo.toggleTask(widget.projectId, task),
                            title: Text(
                              task.title,
                              style: task.done
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            secondary: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  _repo.deleteTask(widget.projectId, task.id),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.url != null && project.url!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: ProjectUrlLink(
                  url: project.url!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            if (project.goal.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(project.goal, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(project.status.label)),
                Chip(label: Text('Priority ${project.priority}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
