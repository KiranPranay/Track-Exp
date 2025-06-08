import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/project.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  static Database? _db;
  DatabaseHelper._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final docDir = await getApplicationDocumentsDirectory();
    final path = p.join(docDir.path, 'expenses.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects(
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE expenses(
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        amount     REAL    NOT NULL,
        vendor     TEXT    NOT NULL,
        description TEXT   NOT NULL,
        imagePath  TEXT,
        dateTime   TEXT    NOT NULL,
        isClaimed  INTEGER NOT NULL,
        projectId  INTEGER,
        FOREIGN KEY(projectId) REFERENCES projects(id)
      );
    ''');
  }

  Future _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE projects(
          id   INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        );
      ''');
      await db.execute('''
        ALTER TABLE expenses ADD COLUMN projectId INTEGER;
      ''');
    }
  }

  /// Returns the full path to the SQLite file.
  Future<String> getDatabasePath() async {
    final docDir = await getApplicationDocumentsDirectory();
    return p.join(docDir.path, 'expenses.db');
  }

  // --- Project CRUD ---
  Future<int> insertProject(Project p) async {
    final db = await database;
    return db.insert('projects', p.toMap());
  }

  Future<List<Project>> getProjects() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'name');
    return rows.map((m) => Project.fromMap(m)).toList();
  }

  Future<int> updateProject(Project p) async {
    final db = await database;
    return db.update('projects', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // --- Expense CRUD ---
  Future<int> insertExpense(Expense e) async {
    final db = await database;
    return db.insert('expenses', e.toMap());
  }

  Future<int> updateExpense(Expense e) async {
    final db = await database;
    return db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpenses({int? projectId}) async {
    final db = await database;
    String sql = 'SELECT * FROM expenses';
    List<dynamic> args = [];
    if (projectId != null) {
      sql += ' WHERE projectId = ?';
      args.add(projectId);
    }
    sql += ' ORDER BY dateTime DESC';
    final rows = await db.rawQuery(sql, args);
    return rows.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
