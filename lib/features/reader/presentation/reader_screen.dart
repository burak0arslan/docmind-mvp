import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/reader_provider.dart';
import 'widgets/reader_app_bar.dart';
import 'widgets/reader_bottom_bar.dart';
import 'widgets/page_thumbnail_strip.dart';

/// Reader screen for viewing PDF documents
class ReaderScreen extends ConsumerStatefulWidget {
  final String documentId;

  const ReaderScreen({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    // Enable immersive mode for reading (mobile only)
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    // Restore system UI (mobile only)
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider(widget.documentId));
    final readerNotifier = ref.read(readerProvider(widget.documentId).notifier);

    // Handle loading state
    if (readerState.isLoading) {
      return Scaffold(
        backgroundColor: _getBackgroundColor(readerState.readingTheme),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle error state
    if (readerState.error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  readerState.error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = readerNotifier.pdfController;
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(readerState.readingTheme),
      body: GestureDetector(
        onTap: () => readerNotifier.toggleControls(),
        child: Stack(
          children: [
            // PDF Viewer
            PdfViewPinch(
              controller: controller,
              onPageChanged: (page) => readerNotifier.onPageChanged(page),
              padding: 0,
              scrollDirection: readerState.readingMode == ReadingMode.continuous
                  ? Axis.vertical
                  : Axis.horizontal,
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
                pageLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorBuilder: (_, error) => Center(
                  child: Text(
                    'Error loading page: $error',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),

            // Top bar with controls
            if (readerState.showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ReaderAppBar(
                  document: readerState.document,
                  onThemeChange: (theme) => readerNotifier.setReadingTheme(theme),
                  onModeToggle: () => readerNotifier.toggleReadingMode(),
                  readingMode: readerState.readingMode,
                  readingTheme: readerState.readingTheme,
                ),
              ),

            // Bottom bar with navigation
            if (readerState.showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ReaderBottomBar(
                  currentPage: readerState.currentPage,
                  totalPages: readerState.totalPages,
                  onPageChanged: (page) => readerNotifier.goToPage(page),
                  onPrevious: () => readerNotifier.previousPage(),
                  onNext: () => readerNotifier.nextPage(),
                  onThumbnailToggle: () => readerNotifier.toggleThumbnails(),
                ),
              ),

            // Thumbnail strip
            if (readerState.showThumbnails && readerState.showControls)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: PageThumbnailStrip(
                  document: readerState.document,
                  currentPage: readerState.currentPage,
                  totalPages: readerState.totalPages,
                  onPageSelected: (page) => readerNotifier.goToPage(page),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(ReadingTheme theme) {
    switch (theme) {
      case ReadingTheme.light:
        return Colors.white;
      case ReadingTheme.dark:
        return const Color(0xFF1A1A1A);
      case ReadingTheme.sepia:
        return const Color(0xFFF5E6D3);
    }
  }
}
