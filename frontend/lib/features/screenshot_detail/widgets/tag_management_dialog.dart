import 'package:flutter/material.dart';
import '../../../models/tag_model.dart';

class TagManagementDialog extends StatefulWidget {
  final List<TagModel> currentTags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  const TagManagementDialog({
    super.key,
    required this.currentTags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  State<TagManagementDialog> createState() => _TagManagementDialogState();
}

class _TagManagementDialogState extends State<TagManagementDialog> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAddTag(text);
      _controller.clear();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Tags'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'New tag (e.g. Tax 2026)',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Assigned Tags',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (widget.currentTags.isEmpty)
              const Text(
                'No tags assigned yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.currentTags.map((tag) {
                  return Chip(
                    label: Text('#${tag.name}'),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      widget.onRemoveTag(tag.id);
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
