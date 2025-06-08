// lib/main.dart

import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/all_expenses_page.dart';
import 'pages/projects_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme:
          AppTheme
              .darkTheme, // or ThemeData.dark() if you don’t have a theme.dart
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({Key? key}) : super(key: key);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  // The three pages: All Expenses, Projects, Settings
  static const List<Widget> _pages = [
    AllExpensesPage(),
    ProjectsPage(),
    SettingsPage(),
  ];

  // Bottom nav items: add Settings at the end
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long),
      label: 'All Expenses',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Projects'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  void _onTap(int idx) {
    setState(() {
      _currentIndex = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: _navItems,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.white70,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
