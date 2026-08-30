import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class RecentSearchesBar extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onSelectQuery;
  final VoidCallback onClearAll;

  const RecentSearchesBar({
    super.key,
    required this.recentSearches,
    required this.onSelectQuery,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onClearAll,
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((query) {
              return ActionChip(
                avatar: const Icon(Icons.history_rounded, size: 14),
                label: Text(query),
                labelStyle: const TextStyle(fontSize: 12),
                onPressed: () => onSelectQuery(query),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
