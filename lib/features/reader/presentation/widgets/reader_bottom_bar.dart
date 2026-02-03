import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/annotation_provider.dart';

/// Bottom bar for the reader screen with page navigation
class ReaderBottomBar extends ConsumerWidget {
  final String documentId;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onThumbnailToggle;
  final VoidCallback onBookmarkTap;
  final VoidCallback onNoteTap;

  const ReaderBottomBar({
    super.key,
    required this.documentId,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onThumbnailToggle,
    required this.onBookmarkTap,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationState = ref.watch(annotationProvider(documentId));
    final isBookmarked = annotationState.isCurrentPageBookmarked(currentPage);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page slider
              Row(
                children: [
                  // Previous button
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: currentPage > 1 ? onPrevious : null,
                  ),

                  // Slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: currentPage.toDouble().clamp(1, totalPages > 0 ? totalPages.toDouble() : 1),
                        min: 1,
                        max: totalPages > 0 ? totalPages.toDouble() : 1,
                        divisions: totalPages > 1 ? totalPages - 1 : null,
                        onChanged: totalPages > 1 ? (value) => onPageChanged(value.round()) : null,
                      ),
                    ),
                  ),

                  // Next button
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: currentPage < totalPages ? onNext : null,
                  ),
                ],
              ),

              // Page indicator and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Thumbnail toggle
                  IconButton(
                    icon: const Icon(Icons.view_comfy, color: Colors.white),
                    onPressed: onThumbnailToggle,
                    tooltip: 'Page thumbnails',
                  ),

                  // Notes button
                  IconButton(
                    icon: const Icon(Icons.sticky_note_2_outlined, color: Colors.white),
                    onPressed: onNoteTap,
                    tooltip: 'Notes',
                  ),

                  // Page indicator
                  GestureDetector(
                    onTap: () => _showPagePicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                      ),
                      child: Text(
                        '$currentPage / $totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Bookmarks list button
                  IconButton(
                    icon: const Icon(Icons.collections_bookmark_outlined, color: Colors.white),
                    onPressed: onBookmarkTap,
                    tooltip: 'Bookmarks',
                  ),

                  // Bookmark toggle for current page
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppColors.warning : Colors.white,
                    ),
                    onPressed: () {
                      ref.read(annotationProvider(documentId).notifier)
                          .toggleBookmark(currentPage);
                    },
                    tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPagePicker(BuildContext context) {
    final controller = TextEditingController(text: currentPage.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page number',
            hintText: '1 - $totalPages',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= totalPages) {
                Navigator.pop(context);
                onPageChanged(page);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
