import 'dart:io';

import 'package:flutter/material.dart';
import '../models/expense.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Expenses')),
      body:
          _list.isEmpty
              ? const Center(child: Text('No expenses yet.'))
              : ListView.builder(
                itemCount: _list.length,
                itemBuilder: (context, index) {
                  final e = _list[index];
                  return GestureDetector(
                    onTap: () async {
                      final did = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditExpensePage(expense: e),
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
            MaterialPageRoute(builder: (_) => const AddEditExpensePage()),
          );
          if (did == true) _reload();
        },
      ),
    );
  }

  /// Returns either the cached image (if it exists) or a receipt icon.
  Widget _buildLeading(String? path) {
    if (path == null) {
      return const Icon(Icons.receipt, color: Colors.tealAccent);
    }
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
