// lib/pages/all_expenses_page.dart

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import '../models/project.dart';
import '../db/database_helper.dart';
import '../utils/date_utils.dart';
import 'add_edit_expense_page.dart';

class AllExpensesPage extends StatefulWidget {
  const AllExpensesPage({Key? key}) : super(key: key);

  @override
  _AllExpensesPageState createState() => _AllExpensesPageState();
}

class _AllExpensesPageState extends State<AllExpensesPage> {
  List<Expense> _list = [];
  final _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() =>
      _db.getExpenses().then((l) => setState(() => _list = l));

  Future<Directory> _getExportDirectory() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      // Public downloads folder on Android
      baseDir = Directory('/storage/emulated/0/Download');
    } else {
      // Fallback for other platforms
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

  Future<void> _exportAllCsv() async {
    final all = await _db.getExpenses();
    final projects = await _db.getProjects();
    final projMap = {for (var p in projects) p.id!: p.name};

    final rows = <List<dynamic>>[
      [
        'ID',
        'DateTime',
        'Vendor',
        'Amount',
        'Claimed',
        'Project',
        'Description',
      ],
    ];
    for (var e in all) {
      rows.add([
        e.id,
        e.dateTime.toIso8601String(),
        e.vendor,
        e.amount,
        e.isClaimed ? 1 : 0,
        projMap[e.projectId] ?? '',
        e.description,
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);

    final dir = await _getExportDirectory();
    final filePath = p.join(
      dir.path,
      'all_expenses_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await File(filePath).writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported all expenses to:\n$filePath')),
    );
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
        title: const Text('All Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export All to CSV',
            onPressed: _exportAllCsv,
          ),
        ],
      ),
      body:
          _list.isEmpty
              ? const Center(child: Text('No expenses yet.'))
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            e.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(e.dateTime),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: e.isClaimed,
                            activeColor: Colors.teal,
                            onChanged: (v) async {
                              e.isClaimed = v ?? false;
                              await _db.updateExpense(e);
                              _reload();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              await _db.deleteExpense(e.id!);
                              _reload();
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        final did = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditExpensePage(expense: e),
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
            MaterialPageRoute(builder: (_) => const AddEditExpensePage()),
          );
          if (did == true) _reload();
        },
      ),
    );
  }
}
