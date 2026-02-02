import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/document_model.dart';

/// Horizontal strip of page thumbnails for quick navigation
class PageThumbnailStrip extends StatefulWidget {
  final DocumentModel? document;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  const PageThumbnailStrip({
    super.key,
    required this.document,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  State<PageThumbnailStrip> createState() => _PageThumbnailStripState();
}

class _PageThumbnailStripState extends State<PageThumbnailStrip> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPage();
    });
  }

  @override
  void didUpdateWidget(PageThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _scrollToCurrentPage();
    }
  }

  void _scrollToCurrentPage() {
    if (!_scrollController.hasClients) return;
    
    const itemWidth = 60.0 + AppSpacing.sm;
    final targetOffset = (widget.currentPage - 1) * itemWidth - 
        (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: AppDurations.normal,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: widget.totalPages,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final isCurrentPage = pageNumber == widget.currentPage;

          return GestureDetector(
            onTap: () => widget.onPageSelected(pageNumber),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                border: Border.all(
                  color: isCurrentPage ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isCurrentPage
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Page placeholder
                  Center(
                    child: Icon(
                      Icons.description_outlined,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ),

                  // Page number
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentPage
                              ? AppColors.primary
                              : Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                        ),
                        child: Text(
                          '$pageNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
