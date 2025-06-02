import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: ExpenseListPage(),
    );
  }
}

// Model class for Expense
class Expense {
  int? id;
  double amount;
  String vendor;
  String description;
  String? imagePath;
  DateTime dateTime;
  bool isClaimed;

  Expense({
    this.id,
    required this.amount,
    required this.vendor,
    required this.description,
    this.imagePath,
    required this.dateTime,
    this.isClaimed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'vendor': vendor,
      'description': description,
      'imagePath': imagePath,
      'dateTime': dateTime.toIso8601String(),
      'isClaimed': isClaimed ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      vendor: map['vendor'],
      description: map['description'],
      imagePath: map['imagePath'],
      dateTime: DateTime.parse(map['dateTime']),
      isClaimed: map['isClaimed'] == 1,
    );
  }
}

// Database helper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, 'expenses.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        vendor TEXT NOT NULL,
        description TEXT NOT NULL,
        imagePath TEXT,
        dateTime TEXT NOT NULL,
        isClaimed INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }
}

// Page to display list of expenses
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
    if (shouldReload ?? false) {
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
    // First, filter out claimed if needed
    List<Expense> filtered =
        _showClaimed
            ? List.from(_allExpenses)
            : _allExpenses.where((e) => !e.isClaimed).toList();

    // Then sort: unclaimed first (descending date), then claimed (descending date)
    filtered.sort((a, b) {
      if (a.isClaimed != b.isClaimed) {
        return a.isClaimed ? 1 : -1; // unclaimed come first
      }
      return b.dateTime.compareTo(a.dateTime); // newest first
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
                '${_formatDateTime(expense.dateTime)}',
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
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
                    setState(() {
                      _showClaimed = val;
                    });
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

// Page to add or edit a new expense
class AddEditExpensePage extends StatefulWidget {
  final Expense? expense;
  AddEditExpensePage({this.expense});

  @override
  _AddEditExpensePageState createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late double _amount;
  late String _vendor;
  late String _description;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isClaimed = false;
  String? _imagePath;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _amount = e.amount;
      _vendor = e.vendor;
      _description = e.description;
      _selectedDate = e.dateTime;
      _selectedTime = TimeOfDay(
        hour: e.dateTime.hour,
        minute: e.dateTime.minute,
      );
      _isClaimed = e.isClaimed;
      _imagePath = e.imagePath;
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF121212),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              hourMinuteColor: Color(0xFF1E1E1E),
              dayPeriodTextColor: Colors.tealAccent,
              dialHandColor: Colors.tealAccent,
            ),
            colorScheme: ColorScheme.dark(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      DateTime fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (widget.expense == null) {
        // New expense
        Expense newExpense = Expense(
          amount: _amount,
          vendor: _vendor,
          description: _description,
          imagePath: _imagePath,
          dateTime: fullDateTime,
          isClaimed: _isClaimed,
        );
        await _dbHelper.insertExpense(newExpense);
      } else {
        // Update existing
        Expense e = widget.expense!;
        e.amount = _amount;
        e.vendor = _vendor;
        e.description = _description;
        e.imagePath = _imagePath;
        e.dateTime = fullDateTime;
        e.isClaimed = _isClaimed;
        await _dbHelper.updateExpense(e);
      }
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Expense' : 'Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: isEditing ? _amount.toString() : null,
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter amount';
                    if (double.tryParse(value) == null)
                      return 'Enter valid number';
                    return null;
                  },
                  onSaved: (value) => _amount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: isEditing ? _vendor : null,
                  decoration: const InputDecoration(labelText: 'Vendor'),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter vendor name';
                    return null;
                  },
                  onSaved: (value) => _vendor = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: isEditing ? _description : null,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter description';
                    return null;
                  },
                  onSaved: (value) => _description = value!,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date'),
                          child: Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}-'
                            '${_selectedDate.month.toString().padLeft(2, '0')}-'
                            '${_selectedDate.year}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Time'),
                          child: Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:'
                            '${_selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Claimed',
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: _isClaimed,
                      onChanged: (val) {
                        setState(() {
                          _isClaimed = val;
                        });
                      },
                      activeColor: Colors.tealAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _imagePath == null
                    ? ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Attach Bill Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    )
                    : Column(
                      children: [
                        Image.file(File(_imagePath!), height: 150),
                        TextButton.icon(
                          onPressed: () => setState(() => _imagePath = null),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Remove Image',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveExpense,
                  child: Text(isEditing ? 'Update' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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
      ),
    );
  }
}
