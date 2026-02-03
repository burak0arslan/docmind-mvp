import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/annotation_provider.dart';

/// Panel for displaying and managing bookmarks
class BookmarkPanel extends ConsumerWidget {
  final String documentId;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  const BookmarkPanel({
    super.key,
    required this.documentId,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationState = ref.watch(annotationProvider(documentId));
    final bookmarks = annotationState.bookmarks;

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bookmarks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${bookmarks.length} bookmarks',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Bookmark list
          if (bookmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No bookmarks yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap the bookmark icon to add one',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  final isCurrentPage = bookmark.pageNumber == currentPage;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrentPage 
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${bookmark.pageNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentPage ? AppColors.primary : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      bookmark.title ?? 'Page ${bookmark.pageNumber}',
                      style: TextStyle(
                        fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentPage ? AppColors.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(bookmark.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () {
                        ref.read(annotationProvider(documentId).notifier)
                            .deleteAnnotation(bookmark.id);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onPageSelected(bookmark.pageNumber);
                    },
                  );
                },
              ),
            ),
          
          // Add bookmark button for current page
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(annotationProvider(documentId).notifier)
                      .toggleBookmark(currentPage);
                },
                icon: Icon(
                  annotationState.isCurrentPageBookmarked(currentPage)
                      ? Icons.bookmark
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(
                  annotationState.isCurrentPageBookmarked(currentPage)
                      ? 'Remove Bookmark from Page $currentPage'
                      : 'Bookmark Page $currentPage',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
