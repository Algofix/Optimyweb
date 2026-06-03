import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/project_repository.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ProjectRepository();
  ProjectStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimyweb'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                ...ProjectStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: status.label,
                      selected: _filter == status,
                      onTap: () => setState(() => _filter = status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Project>>(
        stream: _repo.watchProjects(statusFilter: _filter),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return _EmptyState(
              onCreate: () => _openForm(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final project = projects[index];
              return _ProjectCard(
                project: project,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProjectDetailScreen(projectId: project.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New project'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProjectFormScreen(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusBadge(status: project.status),
                ],
              ),
              if (project.url != null && project.url!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  project.url!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (project.goal.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.goal,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case ProjectStatus.draft:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
      case ProjectStatus.active:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
      case ProjectStatus.done:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No projects yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Track websites and improvements you are optimizing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create first project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Could not load projects',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Run flutterfire configure and enable Firestore in Firebase Console.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
