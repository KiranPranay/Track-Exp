// lib/pages/add_edit_expense_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import '../utils/date_utils.dart';

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
      setState(() => _selectedDate = picked);
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
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
        // Insert new
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
                    if (value == null || value.isEmpty) {
                      return 'Enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => _amount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: isEditing ? _vendor : null,
                  decoration: const InputDecoration(labelText: 'Vendor'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter vendor name';
                    }
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
                    if (value == null || value.isEmpty) {
                      return 'Enter description';
                    }
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
                        setState(() => _isClaimed = val);
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
