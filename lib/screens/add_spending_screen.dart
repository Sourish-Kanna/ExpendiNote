import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/spending.dart';
import '../services/database_service.dart';

class AddSpendingScreen extends StatefulWidget {
  final Spending? spending;
  const AddSpendingScreen({super.key, this.spending});

  @override
  State<AddSpendingScreen> createState() => _AddSpendingScreenState();
}

class _AddSpendingScreenState extends State<AddSpendingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.spending?.title);
    _amountController = TextEditingController(
      text: widget.spending?.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.spending?.description,
    );
    _selectedCategory = widget.spending?.category ?? 'General';
    _selectedDate = widget.spending?.date ?? DateTime.now();
  }

  final Map<String, IconData> _categories = {
    'General': Icons.receipt,
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Entertainment': Icons.movie,
    'Shopping': Icons.shopping_bag,
    'Health': Icons.medical_services,
    'Other': Icons.more_horiz,
  };

  void _saveSpending() async {
    if (_formKey.currentState!.validate()) {
      final spending = Spending(
        id: widget.spending?.id,
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (widget.spending == null) {
        await DatabaseService().insertSpending(spending);
      } else {
        await DatabaseService().updateSpending(spending);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.spending != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Spending' : 'Add Spending')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'What did you spend on?',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _presentDatePicker,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return ChoiceChip(
                    avatar: Icon(
                      entry.value,
                      size: 18,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                    label: Text(entry.key),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = entry.key;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveSpending,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  isEditing ? 'Update Spending' : 'Save Spending',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
