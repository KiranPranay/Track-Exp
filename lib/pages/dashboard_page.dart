// lib/pages/dashboard_page.dart

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

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(Expense e) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        '${e.vendor} − ₹${e.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        formatDateTime(e.dateTime),
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      trailing: Checkbox(
        value: e.isClaimed,
        activeColor: Colors.tealAccent,
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
              // ─── Unified Summary Card ─────────────────────────
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      // header row
                      Row(
                        children: const [
                          Icon(
                            Icons.pie_chart_outline,
                            color: Colors.tealAccent,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'All-Time Summary',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // total amount (now with rupee icon!)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 4),
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
                      const SizedBox(height: 24),
                      // claimed / unclaimed chips
                      Row(
                        children: [
                          _statChip(
                            Icons.check_circle_outline,
                            'Claimed',
                            '₹${_claimed.toStringAsFixed(2)}',
                            Colors.greenAccent,
                          ),
                          _statChip(
                            Icons.hourglass_empty,
                            'Unclaimed',
                            '₹${_unclaimed.toStringAsFixed(2)}',
                            Colors.redAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              // ─── Recent 5 Expenses ────────────────────────────
              const Text(
                'Recent Expenses',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 8),
              for (var e in _recent) ...[
                _buildRecentItem(e),
                const Divider(color: Colors.white12, height: 1),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllExpensesPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View All Expenses'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
