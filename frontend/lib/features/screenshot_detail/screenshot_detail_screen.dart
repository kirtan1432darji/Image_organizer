import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/color_constants.dart';
import '../../core/widgets/confidence_badge.dart';
import '../../core/widgets/modern_card.dart';
import '../../core/widgets/screenshot_image_thumbnail.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/tag_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/screenshot_provider.dart';
import 'widgets/category_picker_dialog.dart';
import 'widgets/metadata_panel.dart';
import 'widgets/ocr_text_view.dart';
import 'widgets/tag_management_dialog.dart';

class ScreenshotDetailScreen extends ConsumerStatefulWidget {
  final String screenshotId;

  const ScreenshotDetailScreen({
    super.key,
    required this.screenshotId,
  });

  @override
  ConsumerState<ScreenshotDetailScreen> createState() =>
      _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState
    extends ConsumerState<ScreenshotDetailScreen> {
  bool _isAnalyzing = false;

  Future<void> _runAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      await ref
          .read(screenshotListProvider.notifier)
          .runAiClassification(widget.screenshotId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Analysis updated successfully!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showCategoryPicker() {
    final categoriesAsync = ref.read(categoryListProvider);
    final screenshots = ref.read(screenshotListProvider).value ?? [];
    final item = screenshots.firstWhere((s) => s.id == widget.screenshotId);

    categoriesAsync.whenData((categories) {
      showDialog(
        context: context,
        builder: (ctx) => CategoryPickerDialog(
          categories: categories,
          currentCategoryId: item.categoryId,
          onSelect: (selectedCat) {
            ref.read(screenshotListProvider.notifier).updateCategory(
                  item.id,
                  selectedCat.id,
                  selectedCat.name,
                );
          },
        ),
      );
    });
  }

  void _showTagDialog() {
    final screenshots = ref.read(screenshotListProvider).value ?? [];
    final item = screenshots.firstWhere((s) => s.id == widget.screenshotId);

    showDialog(
      context: context,
      builder: (ctx) => TagManagementDialog(
        currentTags: item.tags,
        onAddTag: (tagName) {
          final newTag = TagModel(
            id: 'tag_${DateTime.now().millisecondsSinceEpoch}',
            name: tagName,
          );
          ref.read(screenshotListProvider.notifier).addTag(item.id, newTag);
        },
        onRemoveTag: (tagId) {
          ref.read(screenshotListProvider.notifier).removeTag(item.id, tagId);
        },
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from App Library?'),
        content: const Text(
          'This will remove the screenshot and its AI tags from this organizer. Note: Your original photo in your phone gallery will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(screenshotListProvider.notifier)
                  .deleteScreenshot(widget.screenshotId);
              if (mounted) context.pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenshotsAsync = ref.watch(screenshotListProvider);
    final theme = Theme.of(context);

    return screenshotsAsync.when(
      data: (screenshots) {
        final itemIndex =
            screenshots.indexWhere((s) => s.id == widget.screenshotId);
        if (itemIndex == -1) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Screenshot not found.')),
          );
        }

        final item = screenshots[itemIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              item.fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  item.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      item.isFavorite ? ColorConstants.tertiary : null,
                ),
                onPressed: () {
                  ref
                      .read(screenshotListProvider.notifier)
                      .toggleFavorite(item.id, item.isFavorite);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _confirmDelete,
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Interactive Zoomable Image Preview
                Container(
                  height: 320,
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Center(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: ScreenshotImageThumbnail(
                            screenshot: item,
                            fit: BoxFit.contain,
                            isOriginal: true,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pinch to zoom',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Classification Overview Card
                      ModernCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Classification',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.categoryName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.subcategory.isNotEmpty)
                                      Text(
                                        'Sub: ${item.subcategory}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: ColorConstants.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                                ConfidenceBadge(
                                  confidence: item.confidence,
                                  size: 11,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showCategoryPicker,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Change Category'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isAnalyzing ? null : _runAnalysis,
                                    icon: _isAnalyzing
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 16,
                                          ),
                                    label: const Text('Re-Analyze'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tags Cloud Card
                      ModernCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tags & Labels',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showTagDialog,
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Edit Tags',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (item.tags.isEmpty)
                              Text(
                                'No tags assigned. Tap "Edit Tags" to add custom tags.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: item.tags
                                    .map(
                                      (tag) => TagChip(
                                        tag: tag,
                                        onDelete: () {
                                          ref
                                              .read(screenshotListProvider
                                                  .notifier)
                                              .removeTag(item.id, tag.id);
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Extracted OCR text view
                      OcrTextView(
                        ocrText: item.ocrText,
                        ocrStatus: item.ocrStatus,
                        onReRunOcr: _runAnalysis,
                      ),

                      const SizedBox(height: 16),

                      // Metadata Panel
                      MetadataPanel(screenshot: item),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}
