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
  List<Project> _projects = [];
  final _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final projects = await _db.getProjects();
    setState(() => _projects = projects);
  }

  Future<void> _addProject() async {
    final nameCtl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('New Project'),
            content: TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (result == true && nameCtl.text.trim().isNotEmpty) {
      await _db.insertProject(Project(name: nameCtl.text.trim()));
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
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  return ListTile(
                    title: Text(project.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final didChange = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(project: project),
                        ),
                      );
                      if (didChange == true) _reload();
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.business),
        onPressed: _addProject,
      ),
    );
  }
}
