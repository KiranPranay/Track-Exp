import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../db/database_helper.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isProcessing = false;

  Future<FilePickerResult?> _pickDatabaseFile() async {
    FilePickerResult? result;
    try {
      // First try filtering to `.db`
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
    } catch (_) {
      // If that fails, fall back to “any file”
      result = await FilePicker.platform.pickFiles(type: FileType.any);
    }
    return result;
  }

  Future<void> _importDatabase() async {
    setState(() => _isProcessing = true);

    try {
      final result = await _pickDatabaseFile();
      if (result == null) {
        setState(() => _isProcessing = false);
        return; // user canceled
      }

      final pickedPath = result.files.single.path!;
      if (!pickedPath.toLowerCase().endsWith('.db')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid “.db” file.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Overwrite local DB
      await _dbHelper.close();
      final originalDbPath = await _dbHelper.getDatabasePath();
      final destFile = File(originalDbPath);
      if (await destFile.exists()) {
        await destFile.delete();
      }
      await File(pickedPath).copy(originalDbPath);

      // Re-open DB
      await _dbHelper.getExpenses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database imported successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Notify ExpenseListPage to reload
      Navigator.pop(context, true);
      return;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _backupDatabase() async {
    setState(() => _isProcessing = true);

    try {
      final originalDbPath = await _dbHelper.getDatabasePath();
      final targetDir = await FilePicker.platform.getDirectoryPath();
      if (targetDir == null) {
        setState(() => _isProcessing = false);
        return; // user canceled
      }

      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final backupFileName = 'expenses_backup_$timestamp.db';
      final targetPath = '$targetDir/$backupFileName';

      await File(originalDbPath).copy(targetPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to:\n$targetPath'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Backup Database'),
              onPressed: _isProcessing ? null : _backupDatabase,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Import Database'),
              onPressed: _isProcessing ? null : _importDatabase,
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 32),
              Center(child: CircularProgressIndicator(color: primary)),
            ],
          ],
        ),
      ),
    );
  }
}
