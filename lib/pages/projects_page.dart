// lib/pages/projects_page.dart

import 'package:flutter/material.dart';
import '../models/project.dart';
import '../db/database_helper.dart';
import 'project_detail_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _db = DatabaseHelper();
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await _db.getProjects();
    setState(() => _projects = list);
  }

  /// Adds or edits a project.  If [project] is non-null, it's an edit.
  Future<void> _showAddEditDialog([Project? project]) async {
    final isEdit = project != null;
    final nameCtl = TextEditingController(text: project?.name ?? '');

    final didConfirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isEdit ? 'Edit Project' : 'New Project'),
            content: TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Project Name'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          ),
    );

    if (didConfirm == true && nameCtl.text.trim().isNotEmpty) {
      final name = nameCtl.text.trim();
      if (isEdit) {
        // Update existing
        await _db.updateProject(Project(id: project!.id, name: name));
      } else {
        // Insert new
        await _db.insertProject(Project(name: name));
      }
      _reload();
    }
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Project'),
            content: Text('Are you sure you want to delete "${project.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _db.deleteProject(project.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body:
          _projects.isEmpty
              ? const Center(child: Text('No projects yet.'))
              : ListView.builder(
                itemCount: _projects.length,
                itemBuilder: (ctx, i) {
                  final p = _projects[i];
                  return ListTile(
                    title: Text(
                      p.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.tealAccent,
                          ),
                          onPressed: () => _showAddEditDialog(p),
                        ),
                        // Delete button
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(p),
                        ),
                        // Navigate into project
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                    onTap: () async {
                      final didChange = await Navigator.push<bool>(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(project: p),
                        ),
                      );
                      if (didChange == true) _reload();
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add_business),
        onPressed: () => _showAddEditDialog(),
      ),
    );
  }
}
