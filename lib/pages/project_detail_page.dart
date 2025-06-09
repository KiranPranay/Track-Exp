// lib/pages/project_detail_page.dart

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/project.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import '../utils/date_utils.dart';
import 'add_edit_expense_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  const ProjectDetailPage({required this.project, Key? key}) : super(key: key);

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  List<Expense> _list = [];
  final _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() => _db
      .getExpenses(projectId: widget.project.id)
      .then((l) => setState(() => _list = l));

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

  Future<void> _exportProjectCsv() async {
    final exps = await _db.getExpenses(projectId: widget.project.id);

    final rows = <List<dynamic>>[
      ['ID', 'DateTime', 'Vendor', 'Amount', 'Claimed', 'Description'],
    ];
    for (var e in exps) {
      rows.add([
        e.id,
        e.dateTime.toIso8601String(),
        e.vendor,
        e.amount,
        e.isClaimed ? 1 : 0,
        e.description,
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);

    final dir = await _getExportDirectory();
    final filePath = p.join(
      dir.path,
      '${widget.project.name}_expenses_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await File(filePath).writeAsString(csv);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exported project to:\n$filePath')));
  }

  Widget _buildLeading(String? path) {
    if (path == null)
      return const Icon(Icons.receipt, color: Colors.tealAccent);
    final file = File(path);
    if (!file.existsSync())
      return const Icon(Icons.receipt, color: Colors.tealAccent);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export This Project to CSV',
            onPressed: _exportProjectCsv,
          ),
        ],
      ),
      body:
          _list.isEmpty
              ? const Center(child: Text('No expenses for this project.'))
              : ListView.builder(
                itemCount: _list.length,
                itemBuilder: (ctx, i) {
                  final e = _list[i];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: _buildLeading(e.imagePath),
                      ),
                      title: Text(
                        '${e.vendor} - ₹${e.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        formatDateTime(e.dateTime),
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: Checkbox(
                        value: e.isClaimed,
                        activeColor: Colors.teal,
                        onChanged: (v) async {
                          e.isClaimed = v ?? false;
                          await _db.updateExpense(e);
                          _reload();
                        },
                      ),
                      onTap: () async {
                        final did = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AddEditExpensePage(
                                  expense: e,
                                  project: widget.project,
                                ),
                          ),
                        );
                        if (did == true) _reload();
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () async {
          final did = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditExpensePage(project: widget.project),
            ),
          );
          if (did == true) _reload();
        },
      ),
    );
  }
}
