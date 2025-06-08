import 'dart:io';

import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      body:
          _list.isEmpty
              ? const Center(child: Text('No expenses for this project.'))
              : ListView.builder(
                itemCount: _list.length,
                itemBuilder: (context, index) {
                  final e = _list[index];
                  return GestureDetector(
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
                    child: Card(
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
                              onChanged: (val) async {
                                e.isClaimed = val ?? false;
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
                      ),
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

  Widget _buildLeading(String? path) {
    if (path == null)
      return const Icon(Icons.receipt, color: Colors.tealAccent);
    final file = File(path);
    if (!file.existsSync()) {
      return const Icon(Icons.receipt, color: Colors.tealAccent);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        errorBuilder:
            (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.redAccent),
      ),
    );
  }
}
