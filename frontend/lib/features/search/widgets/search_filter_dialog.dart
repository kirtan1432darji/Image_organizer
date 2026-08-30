import 'package:flutter/material.dart';
import '../../../providers/search_provider.dart';

class SearchFilterDialog extends StatefulWidget {
  final SearchFilterState currentState;
  final ValueChanged<SearchFilterState> onApply;

  const SearchFilterDialog({
    super.key,
    required this.currentState,
    required this.onApply,
  });

  @override
  State<SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<SearchFilterDialog> {
  late bool _searchOcr;
  late bool _searchTags;

  @override
  void initState() {
    super.initState();
    _searchOcr = widget.currentState.searchOcr;
    _searchTags = widget.currentState.searchTags;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Filters'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Search within OCR Text'),
            subtitle: const Text('Matches text detected inside images'),
            value: _searchOcr,
            onChanged: (val) => setState(() => _searchOcr = val),
          ),
          SwitchListTile(
            title: const Text('Search Tags & Labels'),
            subtitle: const Text('Matches assigned metadata tags'),
            value: _searchTags,
            onChanged: (val) => setState(() => _searchTags = val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onApply(
              widget.currentState.copyWith(
                searchOcr: _searchOcr,
                searchTags: _searchTags,
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
