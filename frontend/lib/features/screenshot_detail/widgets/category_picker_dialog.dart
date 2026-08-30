import 'package:flutter/material.dart';
import '../../../models/category_model.dart';

class CategoryPickerDialog extends StatelessWidget {
  final List<CategoryModel> categories;
  final String currentCategoryId;
  final ValueChanged<CategoryModel> onSelect;

  const CategoryPickerDialog({
    super.key,
    required this.categories,
    required this.currentCategoryId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Category'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat.id == currentCategoryId;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              title: Text(
                cat.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: cat.color)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                onSelect(cat);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
