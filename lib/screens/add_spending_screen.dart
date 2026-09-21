import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../models/transaction.dart' as txmodel;
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
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

  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  int? _selectedCategoryId;
  late DateTime _selectedDate;
  late bool _includeInSpendingAnalysis;
  bool _showCategoryError = false;

  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction?.title);
    _amountController = TextEditingController(
      text: widget.transaction != null
          ? widget.transaction!.amount.toString()
          : '',
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

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryRepository.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    }
  }

  void _onCategorySelected(Category category) {
    if (_selectedCategoryId == category.id) return;

    if (widget.transaction == null) {
      setState(() {
        _selectedCategoryId = category.id;
        _showCategoryError = false;
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
                  _showCategoryError = false;
                });
              },
              child: const Text('Keep Current'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _selectedCategoryId = category.id;
                  _showCategoryError = false;
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
    final isFormValid = _formKey.currentState!.validate();

    if (_selectedCategoryId == null) {
      setState(() {
        _showCategoryError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please explicitly select a category before saving.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (isFormValid) {
      final tx = txmodel.Transaction(
        id: widget.transaction?.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isEditing = widget.transaction != null;

    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Spending' : 'Add Spending',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: colorScheme.error,
                  onPressed: () => _confirmDelete(widget.transaction!),
                ),
              ]
            : null,
      ),
      body: Theme(
        data: theme.copyWith(inputDecorationTheme: inputDecorationTheme),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Amount Card
                Card(
                  elevation: 0,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Amount',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          autofocus: widget.transaction == null,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          textAlign: TextAlign.center,
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: textTheme.displayMedium?.copyWith(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              fontWeight: FontWeight.bold,
                            ),
                            prefixIcon: Icon(
                              Icons.currency_rupee,
                              size: 36,
                              color: colorScheme.primary,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null ||
                                double.parse(value) <= 0) {
                              return 'Please enter a valid number greater than 0';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_titleFocusNode),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Title
                Text(
                  'Title',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'What did you spend on?',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a title'
                      : null,
                  onFieldSubmitted: (_) => FocusScope.of(
                    context,
                  ).requestFocus(_descriptionFocusNode),
                ),
                const SizedBox(height: 20),

                // 3. Description (Optional)
                Row(
                  children: [
                    Text(
                      'Description',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(Optional)',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Add extra details...',
                    prefixIcon: Icon(Icons.description),
                  ),
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 20),

                // Date Picker field (Preserved existing behavior)
                Text(
                  'Date',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _presentDatePicker,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, MMM dd, yyyy',
                          ).format(_selectedDate),
                          style: textTheme.bodyLarge,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Category
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Category',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No categories available. Please add via Manage.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategoryId == category.id;
                          final catColor = ColorUtils.fromInt(category.color);
                          final iconData = IconUtils.fromString(category.icon);

                          return InkWell(
                            onTap: () => _onCategorySelected(category),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? catColor.withValues(alpha: 0.15)
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? catColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    iconData,
                                    color: isSelected
                                        ? catColor
                                        : colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    if (_showCategoryError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          'Please explicitly select a category',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Spending Analysis choice
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spending Analysis',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCategoryId != null &&
                        _categories.any(
                          (c) => c.id == _selectedCategoryId,
                        )) ...[
                      Builder(
                        builder: (context) {
                          final currentCat = _categories.firstWhere(
                            (c) => c.id == _selectedCategoryId,
                          );
                          if (_includeInSpendingAnalysis !=
                              currentCat.includeInSpendingAnalysis) {
                            return TextButton(
                              onPressed: () {
                                setState(() {
                                  _includeInSpendingAnalysis =
                                      currentCat.includeInSpendingAnalysis;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Reset to Default'),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Should this spending affect normal summary totals?',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Include'),
                          icon: Icon(Icons.analytics),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Exclude'),
                          icon: Icon(Icons.block),
                        ),
                      ],
                      selected: {_includeInSpendingAnalysis},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _includeInSpendingAnalysis = newSelection.first;
                        });
                      },
                      style: const ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // 6. Save Button
                FilledButton.icon(
                  onPressed: _saveSpending,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(isEditing ? Icons.check : Icons.save),
                  label: Text(
                    isEditing ? 'Update Spending' : 'Save Spending',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
