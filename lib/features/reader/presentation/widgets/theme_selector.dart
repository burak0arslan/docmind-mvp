import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

/// Reading theme options
enum ReadingTheme {
  light,
  sepia,
  dark,
}

extension ReadingThemeExtension on ReadingTheme {
  String get name {
    switch (this) {
      case ReadingTheme.light:
        return 'Light';
      case ReadingTheme.sepia:
        return 'Sepia';
      case ReadingTheme.dark:
        return 'Dark';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReadingTheme.light:
        return Colors.white;
      case ReadingTheme.sepia:
        return const Color(0xFFF5E6D3);
      case ReadingTheme.dark:
        return const Color(0xFF1A1A1A);
    }
  }

  Color get surfaceColor {
    switch (this) {
      case ReadingTheme.light:
        return Colors.grey.shade100;
      case ReadingTheme.sepia:
        return const Color(0xFFEDD9C0);
      case ReadingTheme.dark:
        return const Color(0xFF2D2D2D);
    }
  }

  Color get textColor {
    switch (this) {
      case ReadingTheme.light:
        return Colors.black87;
      case ReadingTheme.sepia:
        return const Color(0xFF5D4037);
      case ReadingTheme.dark:
        return Colors.white70;
    }
  }

  IconData get icon {
    switch (this) {
      case ReadingTheme.light:
        return Icons.wb_sunny_outlined;
      case ReadingTheme.sepia:
        return Icons.wb_twilight;
      case ReadingTheme.dark:
        return Icons.nights_stay_outlined;
    }
  }
}

/// Theme selector bottom sheet
class ThemeSelectorSheet extends StatelessWidget {
  final ReadingTheme currentTheme;
  final ValueChanged<ReadingTheme> onThemeChanged;

  const ThemeSelectorSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Reading Theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Theme options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ReadingTheme.values.map((theme) {
                final isSelected = theme == currentTheme;
                return _ThemeOption(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () {
                    onThemeChanged(theme);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: TextStyle(
                    color: currentTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how your document will look with the ${currentTheme.name} theme. The background and text colors are optimized for comfortable reading.',
                  style: TextStyle(
                    color: currentTheme.textColor.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ReadingTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    theme.icon,
                    color: theme.textColor,
                    size: 28,
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}