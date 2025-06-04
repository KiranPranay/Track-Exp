import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/expense_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // defined in theme.dart
      home: ExpenseListPage(),
    );
  }
}
