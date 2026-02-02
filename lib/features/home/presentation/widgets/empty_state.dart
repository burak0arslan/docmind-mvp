import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

/// Empty state widget shown when no documents exist
class EmptyStateWidget extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onImport;

  const EmptyStateWidget({
    super.key,
    required this.searchQuery,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.folder_open,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Title
            Text(
              isSearching ? 'No results found' : 'No documents yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Description
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Import your first PDF or eBook to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Import button (only show when not searching)
            if (!isSearching)
              ElevatedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.add),
                label: const Text('Import Document'),
              ),
          ],
        ),
      ),
    );
  }
}
