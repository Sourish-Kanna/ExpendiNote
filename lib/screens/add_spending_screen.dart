import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/transaction.dart' as txmodel;
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../theme/app_shapes.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import 'category_management_screen.dart';

class AddSpendingScreen extends StatefulWidget {
  final txmodel.Transaction? transaction;
  const AddSpendingScreen({super.key, this.transaction});

  @override
  State<AddSpendingScreen> createState() => _AddSpendingScreenState();
}

class _AddSpendingScreenState extends State<AddSpendingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  late DateTime _selectedDate;
  late bool _includeInSpendingAnalysis;

  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction?.title);
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction?.description,
    );
    _selectedCategoryId = widget.transaction?.categoryId;
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _includeInSpendingAnalysis =
        widget.transaction?.includeInSpendingAnalysis ?? true;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryRepository.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
        // If editing and has category, ensure it's selected.
        // If adding new, select first category if available.
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
          if (widget.transaction == null) {
            _includeInSpendingAnalysis =
                _categories.first.includeInSpendingAnalysis;
          }
        }
      });
    }
  }

  void _onCategorySelected(Category category) {
    if (_selectedCategoryId == category.id) return;

    if (widget.transaction == null) {
      setState(() {
        _selectedCategoryId = category.id;
        _includeInSpendingAnalysis = category.includeInSpendingAnalysis;
      });
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Update Spending Analysis Setting?'),
          content: Text(
            'Would you like to apply the default spending analysis setting for "${category.name}" (${category.includeInSpendingAnalysis ? 'Included' : 'Excluded'}), or keep the current setting (${_includeInSpendingAnalysis ? 'Included' : 'Excluded'})?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _selectedCategoryId = category.id;
                });
              },
              child: const Text('Keep Current'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _selectedCategoryId = category.id;
                  _includeInSpendingAnalysis =
                      category.includeInSpendingAnalysis;
                });
              },
              child: const Text('Apply Default'),
            ),
          ],
        ),
      );
    }
  }

  void _saveSpending() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final tx = txmodel.Transaction(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        includeInSpendingAnalysis: _includeInSpendingAnalysis,
      );

      if (widget.transaction == null) {
        await TransactionRepository.insertTransaction(tx);
      } else {
        await TransactionRepository.updateTransaction(tx);
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
    final isEditing = widget.transaction != null;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Spending' : 'Add Spending'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  onPressed: () => _confirmDelete(widget.transaction!),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'What did you spend on?',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
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
                borderRadius: AppShapes.mediumRadius,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CategoryManagementScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadCategories();
                      }
                    },
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._categories.map((category) {
                      final isSelected = _selectedCategoryId == category.id;
                      final catColor = ColorUtils.fromInt(category.color);
                      return ChoiceChip(
                        showCheckmark: false,
                        avatar: Icon(
                          IconUtils.fromString(category.icon),
                          size: 18,
                          color: isSelected ? colorScheme.onPrimary : catColor,
                        ),
                        label: Text(category.name),
                        selected: isSelected,
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppShapes.smallRadius,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _onCategorySelected(category);
                          }
                        },
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Include in spending analysis'),
                subtitle: const Text(
                  'Controls whether this transaction affects normal spending totals',
                ),
                value: _includeInSpendingAnalysis,
                onChanged: (value) =>
                    setState(() => _includeInSpendingAnalysis = value),
                secondary: Icon(
                  Icons.analytics_outlined,
                  color: _includeInSpendingAnalysis
                      ? colorScheme.primary
                      : null,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveSpending,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(isEditing ? Icons.edit : Icons.save),
                label: Text(
                  isEditing ? 'Update Spending' : 'Save Spending',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(txmodel.Transaction spending) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Spending?'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await TransactionRepository.deleteTransaction(spending.id!);

              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
