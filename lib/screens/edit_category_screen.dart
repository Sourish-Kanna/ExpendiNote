import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../theme/app_shapes.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedIcon = IconUtils.fromString(widget.category?.icon);
    _selectedColor = ColorUtils.fromInt(widget.category?.color);
    _isPinned = widget.category?.isPinned ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();

      // Validation: Check if name is taken (case-insensitive)
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'New Category'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: AppShapes.smallRadius,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Icon',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: IconUtils.getAvailableIcons().length,
                  itemBuilder: (context, index) {
                    final icon = IconUtils.getAvailableIcons()[index];
                    final isSelected = _selectedIcon == icon;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedIcon = icon),
                        borderRadius: AppShapes.smallRadius,
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerLow,
                            borderRadius: AppShapes.smallRadius,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Color',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: ColorUtils.getAvailableColors().length,
                  itemBuilder: (context, index) {
                    final color = ColorUtils.getAvailableColors()[index];
                    final isSelected = _selectedColor == color;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2,
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SwitchListTile(
                title: const Text('Pin category'),
                subtitle: const Text('Pinned categories appear first in lists'),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
                secondary: Icon(
                  _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: _isPinned ? colorScheme.primary : null,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(isEditing ? Icons.update : Icons.save),
                label: Text(
                  isEditing ? 'Update Category' : 'Save Category',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                Text(
                  'Categories cannot be deleted because they may be used by existing transactions. You can rename or merge a category instead.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
