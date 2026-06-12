import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/project_repository.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.existing});

  final Project? existing;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProjectRepository();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _goalCtrl;
  late ProjectStatus _status;
  late int _priority;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.url ?? '');
    _goalCtrl = TextEditingController(text: p?.goal ?? '');
    _status = p?.status ?? ProjectStatus.draft;
    _priority = p?.priority ?? 2;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final project = Project(
        id: widget.existing?.id ?? '',
        name: _nameCtrl.text.trim(),
        url: _urlCtrl.text.trim(),
        goal: _goalCtrl.text.trim(),
        status: _status,
        priority: _priority,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
        imageUrl: widget.existing?.imageUrl,
      );
      await _repo.saveProject(project, isNew: !_isEdit);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit project' : 'New project'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Project name',
                hintText: 'e.g. Main website redesign',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Website URL (optional)',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goalCtrl,
              decoration: const InputDecoration(
                labelText: 'Optimization goal',
                hintText: 'What should improve?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProjectStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ProjectStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('High')),
                DropdownMenuItem(value: 2, child: Text('Medium')),
                DropdownMenuItem(value: 3, child: Text('Low')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
