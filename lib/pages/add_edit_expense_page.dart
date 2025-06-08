// lib/pages/add_edit_expense_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/expense.dart';
import '../models/project.dart';
import '../db/database_helper.dart';
import '../utils/date_utils.dart';

class AddEditExpensePage extends StatefulWidget {
  final Expense? expense;
  final Project? project; // ← new

  const AddEditExpensePage({this.expense, this.project, Key? key})
    : super(key: key);

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

  // Projects dropdown state
  List<Project> _projects = [];
  Project? _selectedProject;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadProjects();

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
      // project will be set in _loadProjects()
    }
  }

  Future<void> _loadProjects() async {
    final projects = await _dbHelper.getProjects();
    setState(() {
      _projects = projects;

      if (widget.expense?.projectId != null) {
        // If editing, select the expense's project
        final pid = widget.expense!.projectId!;
        final idx = _projects.indexWhere((p) => p.id == pid);
        if (idx != -1) _selectedProject = _projects[idx];
      } else if (widget.project != null) {
        // If creating under a specific project, preselect it
        final idx = _projects.indexWhere((p) => p.id == widget.project!.id);
        if (idx != -1) _selectedProject = _projects[idx];
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
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
          ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              timePickerTheme: const TimePickerThemeData(
                hourMinuteColor: Color(0xFF1E1E1E),
                dayPeriodTextColor: Colors.tealAccent,
                dialHandColor: Colors.tealAccent,
              ),
              colorScheme: ColorScheme.dark(primary: Colors.teal),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (widget.expense == null) {
      // New
      final newExpense = Expense(
        amount: _amount,
        vendor: _vendor,
        description: _description,
        imagePath: _imagePath,
        dateTime: dt,
        isClaimed: _isClaimed,
        projectId: _selectedProject?.id,
      );
      await _dbHelper.insertExpense(newExpense);
    } else {
      // Update
      final e = widget.expense!;
      e
        ..amount = _amount
        ..vendor = _vendor
        ..description = _description
        ..imagePath = _imagePath
        ..dateTime = dt
        ..isClaimed = _isClaimed
        ..projectId = _selectedProject?.id;
      await _dbHelper.updateExpense(e);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Expense' : 'Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _projects.isEmpty && widget.project != null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<Project>(
                          decoration: const InputDecoration(
                            labelText: 'Project',
                          ),
                          items:
                              _projects
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.name),
                                    ),
                                  )
                                  .toList(),
                          value: _selectedProject,
                          onChanged:
                              (p) => setState(() => _selectedProject = p),
                          validator:
                              (v) =>
                                  v == null ? 'Please select a project' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: isEditing ? _amount.toString() : null,
                          decoration: const InputDecoration(
                            labelText: 'Amount (₹)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return 'Enter amount';
                            if (double.tryParse(val) == null)
                              return 'Enter valid number';
                            return null;
                          },
                          onSaved: (val) => _amount = double.parse(val!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: isEditing ? _vendor : null,
                          decoration: const InputDecoration(
                            labelText: 'Vendor',
                          ),
                          validator:
                              (val) =>
                                  (val == null || val.isEmpty)
                                      ? 'Enter vendor'
                                      : null,
                          onSaved: (val) => _vendor = val!,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: isEditing ? _description : null,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 2,
                          validator:
                              (val) =>
                                  (val == null || val.isEmpty)
                                      ? 'Enter description'
                                      : null,
                          onSaved: (val) => _description = val!,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date',
                                  ),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Time',
                                  ),
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
                              onChanged: (v) => setState(() => _isClaimed = v),
                              activeColor: Colors.tealAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _imagePath == null
                            ? ElevatedButton.icon(
                              icon: const Icon(Icons.photo),
                              label: const Text('Attach Bill Photo'),
                              onPressed: _pickImage,
                            )
                            : Column(
                              children: [
                                Image.file(File(_imagePath!), height: 150),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  label: const Text(
                                    'Remove Image',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                  onPressed:
                                      () => setState(() => _imagePath = null),
                                ),
                              ],
                            ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveExpense,
                          child: Text(isEditing ? 'Update' : 'Save'),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
