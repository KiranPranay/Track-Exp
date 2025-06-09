// lib/pages/projects_page.dart

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/project.dart';
import '../models/expense.dart';
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

  Future<Directory> _getExportDirectory() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = Directory('/storage/emulated/0/Download');
    } else {
      final downloads = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      baseDir =
          (downloads != null && downloads.isNotEmpty)
              ? downloads.first
              : await getApplicationDocumentsDirectory();
    }
    final exportDir = Directory(p.join(baseDir.path, 'Track_Expense', 'data'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  Future<void> _exportGroupedCsv() async {
    final projects = await _db.getProjects();
    final rows = <List<dynamic>>[
      [
        'Project',
        'ID',
        'DateTime',
        'Vendor',
        'Amount',
        'Claimed',
        'Description',
      ],
    ];

    for (var pjt in projects) {
      final exps = await _db.getExpenses(projectId: pjt.id);
      for (var e in exps) {
        rows.add([
          pjt.name,
          e.id,
          e.dateTime.toIso8601String(),
          e.vendor,
          e.amount,
          e.isClaimed ? 1 : 0,
          e.description,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await _getExportDirectory();
    final filePath = p.join(
      dir.path,
      'by_project_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await File(filePath).writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported grouped CSV to:\n$filePath')),
    );
  }

  Future<void> _showAddEditDialog([Project? project]) async {
    final isEdit = project != null;
    final nameCtl = TextEditingController(text: project?.name ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isEdit ? 'Edit Project' : 'New Project'),
            content: TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Project Name'),
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

    if (confirmed == true && nameCtl.text.trim().isNotEmpty) {
      final name = nameCtl.text.trim();
      if (isEdit) {
        await _db.updateProject(Project(id: project!.id, name: name));
      } else {
        await _db.insertProject(Project(name: name));
      }
      _reload();
    }
  }

  Future<void> _confirmDelete(Project p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Project'),
            content: Text('Delete "${p.name}" and all its expenses?'),
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
    if (ok == true) {
      await _db.deleteProject(p.id!);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export all by project to CSV',
            onPressed: _exportGroupedCsv,
          ),
        ],
      ),
      body:
          _projects.isEmpty
              ? const Center(child: Text('No projects yet.'))
              : ListView.builder(
                itemCount: _projects.length,
                itemBuilder: (ctx, i) {
                  final pjt = _projects[i];
                  return ListTile(
                    title: Text(
                      pjt.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.tealAccent,
                          ),
                          onPressed: () => _showAddEditDialog(pjt),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(pjt),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(project: pjt),
                        ),
                      );
                      if (changed == true) _reload();
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
