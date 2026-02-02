import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/document_model.dart';
import '../../domain/reader_provider.dart';

/// App bar for the reader screen
class ReaderAppBar extends StatelessWidget {
  final DocumentModel? document;
  final ValueChanged<ReadingTheme> onThemeChange;
  final VoidCallback onModeToggle;
  final ReadingMode readingMode;
  final ReadingTheme readingTheme;

  const ReaderAppBar({
    super.key,
    required this.document,
    required this.onThemeChange,
    required this.onModeToggle,
    required this.readingMode,
    required this.readingTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = readingTheme == ReadingTheme.dark;
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),

              // Document title
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document?.name ?? 'Document',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (document != null)
                      Text(
                        document!.formattedFileSize,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Reading mode toggle
              IconButton(
                icon: Icon(
                  readingMode == ReadingMode.continuous
                      ? Icons.view_day
                      : Icons.view_carousel,
                  color: Colors.white,
                ),
                tooltip: readingMode == ReadingMode.continuous
                    ? 'Continuous scroll'
                    : 'Page by page',
                onPressed: onModeToggle,
              ),

              // Theme selector
              IconButton(
                icon: const Icon(Icons.brightness_6, color: Colors.white),
                onPressed: () => _showThemeSelector(context),
              ),

              // More options
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showMoreOptions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading Theme',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ThemeOption(
                    label: 'Light',
                    color: Colors.white,
                    isSelected: readingTheme == ReadingTheme.light,
                    onTap: () {
                      onThemeChange(ReadingTheme.light);
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeOption(
                    label: 'Sepia',
                    color: const Color(0xFFF5E6D3),
                    isSelected: readingTheme == ReadingTheme.sepia,
                    onTap: () {
                      onThemeChange(ReadingTheme.sepia);
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeOption(
                    label: 'Dark',
                    color: const Color(0xFF1A1A1A),
                    isSelected: readingTheme == ReadingTheme.dark,
                    onTap: () {
                      onThemeChange(ReadingTheme.dark);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement bookmark
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search in Document'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: const Text('AI Assistant'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement AI assistant
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Document Info'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show document info
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme option button
class _ThemeOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
