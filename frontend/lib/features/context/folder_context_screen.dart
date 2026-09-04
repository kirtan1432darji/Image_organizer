import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/color_constants.dart';
import '../../core/widgets/confidence_badge.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../models/folder_context_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/folder_context_provider.dart';

class FolderContextScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const FolderContextScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<FolderContextScreen> createState() => _FolderContextScreenState();
}

class _FolderContextScreenState extends ConsumerState<FolderContextScreen> {
  bool _isGenerating = false;

  Future<void> _handleGenerateOrRefresh() async {
    setState(() => _isGenerating = true);
    try {
      await ref
          .read(folderContextActionProvider(widget.categoryId).notifier)
          .generateContext(categoryName: widget.categoryName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Context successfully generated!'),
            backgroundColor: ColorConstants.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate context: $e'),
            backgroundColor: ColorConstants.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showAskAiModal(BuildContext context, FolderContextModel contextModel) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: ColorConstants.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ask Context AI (${widget.categoryName})',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ask anything about the screenshots, receipts, tasks, or extracted entities in this folder.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. How much did I spend? What are the due dates?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: ColorConstants.primary),
                    onPressed: () {
                      final query = textController.text.trim();
                      if (query.isEmpty) return;
                      Navigator.pop(ctx);
                      _answerQuery(query, contextModel);
                    },
                  ),
                ),
                onSubmitted: (query) {
                  if (query.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  _answerQuery(query.trim(), contextModel);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _answerQuery(String query, FolderContextModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: ColorConstants.primary, size: 20),
            SizedBox(width: 8),
            Text('Context AI Answer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Query: "$query"', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            const Divider(height: 20),
            Text(
              model.summary.isNotEmpty
                  ? 'Based on the ${model.screenshotCount} screenshots in ${widget.categoryName}:\n\n${model.summary}'
                  : 'Based on the screenshots in ${widget.categoryName}, no specific answer could be found.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final contextAsync = ref.watch(folderContextProvider(widget.categoryId));
    final categoriesAsync = ref.watch(categoryListProvider);

    // Look up category metadata for icon & color
    final category = categoriesAsync.valueOrNull?.firstWhere(
      (c) => c.id.toLowerCase() == widget.categoryId.toLowerCase(),
      orElse: () => categoriesAsync.valueOrNull?.firstWhere(
        (c) => c.name.toLowerCase() == widget.categoryName.toLowerCase(),
        orElse: () => categoriesAsync.valueOrNull?.first ??
            (throw Exception('Category not found')),
      ) ?? (throw Exception('Category not found')),
    );

    final folderIcon = category?.icon ?? Icons.folder_outlined;
    final folderColor = category?.color ?? ColorConstants.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Context'),
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Context',
            onPressed: _isGenerating ? null : _handleGenerateOrRefresh,
          ),
        ],
      ),
      body: contextAsync.when(
        data: (contextModel) {
          // If completely empty and has no timeline items or summary
          if (contextModel.isEmpty && contextModel.timeline.isEmpty) {
            return EmptyStateView(
              icon: Icons.auto_awesome_outlined,
              title: 'No Context Generated Yet',
              description:
                  'ContextVault can analyze all screenshots in "${widget.categoryName}" to extract AI summaries, pending tasks, links, dates, and people.',
              actionLabel: _isGenerating ? 'Generating...' : 'Generate Context',
              onAction: _isGenerating ? null : _handleGenerateOrRefresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _handleGenerateOrRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Card
                  _buildHeaderCard(theme, isDark, folderIcon, folderColor, contextModel),

                  const SizedBox(height: 16),

                  // 2. Context Summary Card
                  _buildSummaryCard(theme, isDark, contextModel),

                  const SizedBox(height: 16),

                  // 3. Extracted Information (Expandable Cards)
                  _buildExtractedInformationSection(theme, isDark, contextModel),

                  const SizedBox(height: 20),

                  // 4. Screenshot Timeline
                  _buildTimelineSection(theme, isDark, contextModel),

                  const SizedBox(height: 24),

                  // 5. Quick Action Buttons
                  _buildQuickActionButtons(theme, contextModel),
                ],
              ),
            ),
          );
        },
        loading: () => _buildLoadingSkeleton(theme),
        error: (err, _) => ErrorStateView(
          message: 'Failed to load folder context: $err',
          onRetry: () => ref.refresh(folderContextProvider(widget.categoryId)),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    bool isDark,
    IconData folderIcon,
    Color folderColor,
    FolderContextModel model,
  ) {
    final updatedText = model.lastUpdatedAt != null
        ? DateFormat('MMM d, y • h:mm a').format(model.lastUpdatedAt!.toLocal())
        : 'Not generated yet';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: folderColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(folderIcon, color: folderColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: folderColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${model.screenshotCount} Screenshots',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: folderColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Updated $updatedText',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGenerating ? null : _handleGenerateOrRefresh,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_isGenerating ? 'Generating Context...' : 'Generate / Refresh Context'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: ColorConstants.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark, FolderContextModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_alt_rounded, color: ColorConstants.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI Context Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primary,
                    ),
                  ),
                ],
              ),
              if (model.confidence > 0)
                ConfidenceBadge(confidence: model.confidence, size: 11),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            model.summary.isNotEmpty
                ? model.summary
                : 'No AI summary generated yet. Tap "Generate Context" above to distill screenshots into structured knowledge.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: model.summary.isNotEmpty
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (model.keywords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: model.keywords.map((kw) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ColorConstants.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '#$kw',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ColorConstants.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedInformationSection(
    ThemeData theme,
    bool isDark,
    FolderContextModel model,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Extracted Information',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // 1. Pending Tasks
        _buildExpandableCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.checklist_rounded,
          iconColor: Colors.amber.shade700,
          title: 'Pending Tasks',
          count: model.tasks.length,
          initiallyExpanded: model.tasks.isNotEmpty,
          child: model.tasks.isEmpty
              ? _buildEmptySectionText('No tasks identified in this folder.')
              : Column(
                  children: model.tasks.map((task) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: task.isCompleted,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: ColorConstants.success,
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: task.dueDate != null
                          ? Text(
                              'Due: ${task.dueDate}',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                            )
                          : null,
                      onChanged: (_) {
                        ref
                            .read(folderContextActionProvider(widget.categoryId).notifier)
                            .toggleTask(task.id);
                      },
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 8),

        // 2. People Mentioned
        _buildExpandableCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.people_outline_rounded,
          iconColor: Colors.blue.shade600,
          title: 'People Mentioned',
          count: model.people.length,
          child: model.people.isEmpty
              ? _buildEmptySectionText('No people or contacts identified.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: model.people.map((person) {
                    final initial = person.trim().isNotEmpty ? person.trim()[0].toUpperCase() : '?';
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(initial, style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                      ),
                      label: Text(person),
                      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 8),

        // 3. Important Links
        _buildExpandableCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.link_rounded,
          iconColor: Colors.teal,
          title: 'Important Links',
          count: model.links.length,
          child: model.links.isEmpty
              ? _buildEmptySectionText('No URLs or links extracted.')
              : Column(
                  children: model.links.map((link) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language_rounded, size: 20, color: Colors.teal),
                      title: Text(
                        link,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copy link',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard!')),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 8),

        // 4. Important Dates
        _buildExpandableCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.calendar_today_rounded,
          iconColor: Colors.deepPurple,
          title: 'Important Dates',
          count: model.dates.length,
          child: model.dates.isEmpty
              ? _buildEmptySectionText('No dates or scheduled events identified.')
              : Column(
                  children: model.dates.map((d) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              d.date,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              d.event,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 8),

        // 5. Apps Used
        _buildExpandableCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.apps_rounded,
          iconColor: Colors.indigo,
          title: 'Apps Used',
          count: model.apps.length,
          child: model.apps.isEmpty
              ? _buildEmptySectionText('No specific source apps detected.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: model.apps.map((app) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 14, color: Colors.indigo),
                          const SizedBox(width: 6),
                          Text(
                            app,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 8),

        // 6. Topics & Entities
        _buildExpandableCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.label_important_outline_rounded,
          iconColor: Colors.pink.shade600,
          title: 'Topics & Entities',
          count: model.topics.length + model.entities.length,
          child: (model.topics.isEmpty && model.entities.isEmpty)
              ? _buildEmptySectionText('No topics or entity tags extracted.')
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...model.topics.map((t) => Chip(
                          label: Text(t),
                          backgroundColor: Colors.pink.withValues(alpha: 0.08),
                          labelStyle: TextStyle(color: Colors.pink.shade700, fontSize: 12),
                          side: BorderSide.none,
                        )),
                    ...model.entities.map((e) => Chip(
                          avatar: Icon(Icons.tag, size: 14, color: Colors.purple.shade600),
                          label: Text('${e.name} (${e.type})'),
                          backgroundColor: Colors.purple.withValues(alpha: 0.08),
                          labelStyle: TextStyle(color: Colors.purple.shade700, fontSize: 12),
                          side: BorderSide.none,
                        )),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildExpandableCard({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required Widget child,
    bool? initiallyExpanded,
  }) {
    final shouldExpand = initiallyExpanded ?? (count > 0);
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: shouldExpand,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildEmptySectionText(String message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme, bool isDark, FolderContextModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded, color: ColorConstants.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Screenshot Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '${model.timeline.length} Events',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (model.timeline.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No timeline entries available for this folder.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: model.timeline.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = model.timeline[index];
              final dateStr = DateFormat('MMM d, y • h:mm a').format(item.capturedAt.toLocal());

              return Material(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    if (item.screenshotId.isNotEmpty) {
                      context.push('/screenshots/${item.screenshotId}');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 54,
                            height: 54,
                            color: Colors.grey.shade300,
                            child: item.imagePath != null && File(item.imagePath!).existsSync()
                                ? Image.file(
                                    File(item.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstants.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuickActionButtons(ThemeData theme, FolderContextModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAskAiModal(context, model),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Ask Context AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/folders/${widget.categoryId}', extra: widget.categoryName);
                },
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: const Text('All Screenshots'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go('/search');
            },
            icon: const Icon(Icons.search_rounded, size: 16),
            label: Text('Search Inside ${widget.categoryName}'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          LoadingShimmer(width: double.infinity, height: 110, borderRadius: 16),
          SizedBox(height: 16),
          LoadingShimmer(width: double.infinity, height: 140, borderRadius: 16),
          SizedBox(height: 16),
          LoadingShimmer(width: double.infinity, height: 60, borderRadius: 12),
          SizedBox(height: 10),
          LoadingShimmer(width: double.infinity, height: 60, borderRadius: 12),
          SizedBox(height: 10),
          LoadingShimmer(width: double.infinity, height: 60, borderRadius: 12),
        ],
      ),
    );
  }
}
