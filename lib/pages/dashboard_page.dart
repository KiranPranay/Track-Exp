// lib/pages/dashboard_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import '../utils/date_utils.dart';
import 'add_edit_expense_page.dart';
import 'all_expenses_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _db = DatabaseHelper();

  double _total = 0;
  double _claimed = 0;
  double _unclaimed = 0;
  List<Expense> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final all = await _db.getExpenses();

    double tot = 0, cl = 0;
    for (var e in all) {
      tot += e.amount;
      if (e.isClaimed) cl += e.amount;
    }

    setState(() {
      _total = tot;
      _claimed = cl;
      _unclaimed = tot - cl;
      _recent = all.take(5).toList();
    });
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTile(Expense e) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        onChanged: (_) async {
          e.isClaimed = !e.isClaimed;
          await _db.updateExpense(e);
          _loadStats();
        },
      ),
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => AddEditExpensePage(expense: e)),
        );
        if (updated == true) _loadStats();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- All‐Time Summary Card ---
              Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'All Time',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // --- Claimed / Unclaimed Row ---
              Row(
                children: [
                  _buildStatCard(
                    'Claimed',
                    '₹${_claimed.toStringAsFixed(2)}',
                    Colors.greenAccent,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Unclaimed',
                    '₹${_unclaimed.toStringAsFixed(2)}',
                    Colors.redAccent,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // --- Recent 5 Expenses ---
              const Text(
                'Recent Expenses',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 8),
              for (var e in _recent) ...[
                _buildRecentTile(e),
                const Divider(color: Colors.white12),
              ],

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllExpensesPage()),
                  );
                },
                child: const Text('View All Expenses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
