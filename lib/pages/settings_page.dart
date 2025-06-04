// lib/pages/settings_page.dart

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

  /// Attempts to pick a .db file. If any exception occurs (e.g. “Unsupported filter”),
  /// falls back to picking any file.
  Future<FilePickerResult?> _pickDatabaseFile() async {
    FilePickerResult? result;
    try {
      // 1) Try filtering to “.db” only
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
    } catch (_) {
      // 2) If that fails for any reason, pick ANY file
      result = await FilePicker.platform.pickFiles(type: FileType.any);
    }
    return result;
  }

  Future<void> _importDatabase() async {
    setState(() => _isProcessing = true);

    try {
      // Let user pick (with fallback logic inside)
      final result = await _pickDatabaseFile();
      if (result == null) {
        // User cancelled
        setState(() => _isProcessing = false);
        return;
      }

      final pickedPath = result.files.single.path!;
      // 3) Manually verify extension
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

      // 4) Overwrite local database:
      await _dbHelper.close();
      final originalDbPath = await _dbHelper.getDatabasePath();
      final destFile = File(originalDbPath);
      if (await destFile.exists()) {
        await destFile.delete();
      }
      await File(pickedPath).copy(originalDbPath);

      // 5) Re-open database (re-initializes)
      await _dbHelper.getExpenses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database imported successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Any other error
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

      // Pick a directory (usually supported on Android/iOS)
      final targetDir = await FilePicker.platform.getDirectoryPath();
      if (targetDir == null) {
        // User canceled
        setState(() => _isProcessing = false);
        return;
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
