import 'dart:math' show Random;

import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';

class EditCategoryScreen extends StatefulWidget {
  final Category? category;
  const EditCategoryScreen({super.key, this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  late bool _isPinned;
  late bool _includeInSpendingAnalysis;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _nameController.addListener(() => setState(() {}));

    if (widget.category == null) {
      final random = Random();
      final icons = IconUtils.getAvailableIcons();
      final colors = ColorUtils.getAvailableColors();
      _selectedIcon = icons[random.nextInt(icons.length)];
      _selectedColor = colors[random.nextInt(colors.length)];
    } else {
      _selectedIcon = IconUtils.fromString(widget.category?.icon);
      _selectedColor = ColorUtils.fromInt(widget.category?.color);
    }

    _isPinned = widget.category?.isPinned ?? false;
    _includeInSpendingAnalysis =
        widget.category?.includeInSpendingAnalysis ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();

      final isTaken = await CategoryRepository.isNameTaken(
        name,
        excludeId: widget.category?.id,
      );

      if (isTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('A category named "$name" already exists.')),
          );
        }
        return;
      }

      final category = Category(
        id: widget.category?.id,
        name: name,
        icon: IconUtils.iconToString(_selectedIcon),
        color: ColorUtils.colorToInt(_selectedColor),
        isPinned: _isPinned,
        isArchived: widget.category?.isArchived ?? false,
        includeInSpendingAnalysis: _includeInSpendingAnalysis,
        createdAt: widget.category?.createdAt,
      );

      if (widget.category == null) {
        await CategoryRepository.createCategory(category);
      } else {
        await CategoryRepository.updateCategory(category);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isEditing = widget.category != null;

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
        borderSide: BorderSide(color: _selectedColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Category' : 'New Category',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: Theme(
        data: theme.copyWith(
          colorScheme: colorScheme.copyWith(primary: _selectedColor),
          inputDecorationTheme: inputDecorationTheme,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Preview Card
                Card(
                  elevation: 0,
                  color: _selectedColor.withValues(alpha: 0.15),
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
                        Icon(_selectedIcon, size: 48, color: _selectedColor),
                        const SizedBox(height: 12),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Category Name'
                              : _nameController.text,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _selectedColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Name
                Text(
                  'Name',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter category name...',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 3. Icon
                Text(
                  'Icon',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: IconUtils.getAvailableIcons().map((icon) {
                    final isSelected = _selectedIcon == icon;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = icon),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withValues(alpha: 0.2)
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.3,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _selectedColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? _selectedColor
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 4. Color
                Text(
                  'Color',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ColorUtils.getAvailableColors().map((color) {
                    final isSelected = _selectedColor == color;
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = color),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // 5. Switches
                SwitchListTile(
                  title: const Text('Pin category'),
                  subtitle: const Text(
                    'Pinned categories appear first in lists',
                  ),
                  value: _isPinned,
                  onChanged: (value) => setState(() => _isPinned = value),
                  secondary: Icon(_isPinned ? Icons.push_pin : Icons.push_pin),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Include in spending analysis by default'),
                  subtitle: const Text(
                    'New transactions in this category will default to this setting',
                  ),
                  value: _includeInSpendingAnalysis,
                  onChanged: (value) =>
                      setState(() => _includeInSpendingAnalysis = value),
                  secondary: Icon(Icons.analytics),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 40),

                // 6. Save Button
                FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    isEditing ? Icons.check : Icons.save,
                    fontWeight: FontWeight.bold,
                  ),
                  label: Text(
                    isEditing ? 'Update Category' : 'Save Category',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
