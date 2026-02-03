import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/annotation_model.dart';
import '../../domain/annotation_provider.dart';

/// Floating toolbar for annotation tools
class AnnotationToolbar extends ConsumerWidget {
  final String documentId;
  final VoidCallback onClose;
  final VoidCallback? onAddNote;

  const AnnotationToolbar({
    super.key,
    required this.documentId,
    required this.onClose,
    this.onAddNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationState = ref.watch(annotationProvider(documentId));
    final notifier = ref.read(annotationProvider(documentId).notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Highlight colors
          ...HighlightColor.values.map((color) => _ColorButton(
            color: color,
            isSelected: annotationState.selectedColor == color,
            onTap: () => notifier.setHighlightColor(color),
          )),
          
          const SizedBox(width: AppSpacing.sm),
          
          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          // Add note button
          _ToolButton(
            icon: Icons.note_add_outlined,
            tooltip: 'Add Note',
            onTap: onAddNote,
          ),
          
          // Close button
          _ToolButton(
            icon: Icons.close,
            tooltip: 'Close',
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

/// Color selection button
class _ColorButton extends StatelessWidget {
  final HighlightColor color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: color.name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? color.darkColor : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.darkColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(Icons.check, size: 16, color: color.darkColor)
              : null,
        ),
      ),
    );
  }
}

/// Tool button
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

/// Compact highlight color picker for quick selection
class HighlightColorPicker extends ConsumerWidget {
  final String documentId;
  final ValueChanged<HighlightColor>? onColorSelected;

  const HighlightColorPicker({
    super.key,
    required this.documentId,
    this.onColorSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationState = ref.watch(annotationProvider(documentId));
    final notifier = ref.read(annotationProvider(documentId).notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: HighlightColor.values.map((color) {
        final isSelected = annotationState.selectedColor == color;
        return GestureDetector(
          onTap: () {
            notifier.setHighlightColor(color);
            onColorSelected?.call(color);
          },
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color.darkColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
