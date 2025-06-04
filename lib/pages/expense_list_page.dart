import 'dart:io';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import '../utils/date_utils.dart';
import 'add_edit_expense_page.dart';
import 'settings_page.dart';

class ExpenseListPage extends StatefulWidget {
  @override
  _ExpenseListPageState createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  List<Expense> _allExpenses = [];
  bool _showClaimed = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _dbHelper.getExpenses();
    setState(() {
      _allExpenses = expenses;
    });
  }

  void _navigateToAddOrEdit([Expense? existing]) async {
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditExpensePage(expense: existing)),
    );
    if (shouldReload == true) {
      _loadExpenses();
    }
  }

  void _toggleClaimed(Expense expense) async {
    expense.isClaimed = !expense.isClaimed;
    await _dbHelper.updateExpense(expense);
    _loadExpenses();
  }

  void _deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    _loadExpenses();
  }

  List<Expense> get _filteredSortedExpenses {
    List<Expense> filtered =
        _showClaimed
            ? List.from(_allExpenses)
            : _allExpenses.where((e) => !e.isClaimed).toList();

    filtered.sort((a, b) {
      if (a.isClaimed != b.isClaimed) {
        return a.isClaimed ? 1 : -1;
      }
      return b.dateTime.compareTo(a.dateTime);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredSortedExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // Wait for SettingsPage to return a boolean
              final didRestore = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
              // If true, reload expenses
              if (didRestore == true) {
                _loadExpenses();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          displayList.isEmpty
              ? const Center(
                child: Text(
                  'No expenses to display.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final e = displayList[index];
                  return GestureDetector(
                    onTap: () => _navigateToAddOrEdit(e),
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
                        leading:
                            e.imagePath != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(e.imagePath!),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(
                                  Icons.receipt,
                                  color: Colors.tealAccent,
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
                              onChanged: (_) => _toggleClaimed(e),
                              activeColor: Colors.teal,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteExpense(e.id!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddOrEdit(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
