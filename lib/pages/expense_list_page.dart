import 'dart:io';

import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import '../utils/date_utils.dart';
import 'add_edit_expense_page.dart';

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
    bool? shouldReload = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditExpensePage(expense: existing)),
    );
    if (shouldReload ?? false) _loadExpenses();
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
    // Filter out claimed if needed
    List<Expense> filtered =
        _showClaimed
            ? List.from(_allExpenses)
            : _allExpenses.where((e) => !e.isClaimed).toList();

    // Sort: unclaimed first (desc date), then claimed (desc date)
    filtered.sort((a, b) {
      if (a.isClaimed != b.isClaimed) {
        return a.isClaimed ? 1 : -1; // unclaimed come first
      }
      return b.dateTime.compareTo(a.dateTime);
    });
    return filtered;
  }

  Widget _buildExpenseItem(Expense expense) {
    return GestureDetector(
      onTap: () => _navigateToAddOrEdit(expense),
      child: Card(
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading:
              expense.imagePath != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(expense.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                  : const Icon(Icons.receipt, color: Colors.tealAccent),
          title: Text(
            '${expense.vendor} - ₹${expense.amount.toStringAsFixed(2)}',
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
                expense.description,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                formatDateTime(expense.dateTime),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: expense.isClaimed,
                onChanged: (_) => _toggleClaimed(expense),
                activeColor: Colors.teal,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteExpense(expense.id!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredSortedExpenses;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text('Show Claimed', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _showClaimed,
                  onChanged: (val) {
                    setState(() => _showClaimed = val);
                  },
                  activeColor: Colors.tealAccent,
                ),
              ],
            ),
          ),
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
                  return _buildExpenseItem(displayList[index]);
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
