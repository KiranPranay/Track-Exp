// lib/db/database_helper.dart

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  static String? _dbPath; // caches the path once initialized

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Returns the file path of 'expenses.db' on disk.
  Future<String> getDatabasePath() async {
    if (_dbPath != null) return _dbPath!;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    _dbPath = p.join(documentsDirectory.path, 'expenses.db');
    return _dbPath!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasePath();
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

  /// Close the database. Useful before importing/overwriting the file.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
