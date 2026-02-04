import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/data/document_repository.dart';
import '../domain/annotation_provider.dart';
import 'widgets/bookmark_panel.dart';
import 'widgets/sticky_note_widget.dart';
import 'widgets/theme_selector.dart';

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
  PdfControllerPinch? _pdfController;
  PdfDocument? _pdfDocument;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _showControls = true;
  bool _showThumbnails = false;
  
  // Reading theme
  ReadingTheme _readingTheme = ReadingTheme.light;
  
  // Thumbnail cache
  final Map<int, Uint8List> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _loadDocument();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _pdfDocument?.close();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(documentRepositoryProvider);
      final document = repository.getDocument(widget.documentId);

      if (document == null) {
        throw Exception('Document not found');
      }

      final startPage = document.currentPage > 0 ? document.currentPage : 1;

      if (kIsWeb) {
        final bytes = await repository.getDocumentBytes(widget.documentId);
        if (bytes == null) {
          throw Exception('Document data not found');
        }

        final controllerBytes = Uint8List.fromList(bytes.toList());
        _pdfDocument = await PdfDocument.openData(controllerBytes);
        
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(Uint8List.fromList(bytes.toList())),
          initialPage: startPage,
        );
      } else {
        final file = await repository.getDocumentFile(widget.documentId);
        if (file == null) {
          throw Exception('Document file not found');
        }

        _pdfDocument = await PdfDocument.openFile(file.path);
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(file.path),
          initialPage: startPage,
        );
      }

      final pageCount = _pdfDocument!.pagesCount;

      if (document.pageCount != pageCount) {
        await repository.updatePageCount(widget.documentId, pageCount);
      }

      await repository.markAsOpened(widget.documentId);

      setState(() {
        _currentPage = startPage;
        _totalPages = pageCount;
        _isLoading = false;
      });
      
      _preloadThumbnails();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
  
  Future<void> _preloadThumbnails() async {
    if (_pdfDocument == null) return;
    
    for (int i = 1; i <= _totalPages.clamp(0, 5); i++) {
      await _loadThumbnail(i);
    }
  }
  
  Future<Uint8List?> _loadThumbnail(int pageNumber) async {
    if (_thumbnailCache.containsKey(pageNumber)) {
      return _thumbnailCache[pageNumber];
    }
    
    if (_pdfDocument == null) return null;
    
    try {
      final page = await _pdfDocument!.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 0.2,
        height: page.height * 0.2,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();
      
      if (pageImage != null) {
        final bytes = Uint8List.fromList(pageImage.bytes);
        _thumbnailCache[pageNumber] = bytes;
        if (mounted) setState(() {});
        return bytes;
      }
    } catch (e) {
      print('Error loading thumbnail for page $pageNumber: $e');
    }
    return null;
  }

  void _onPageChanged(int page) {
    if (_currentPage == page) return;
    
    setState(() {
      _currentPage = page;
    });

    final repository = ref.read(documentRepositoryProvider);
    repository.updateProgress(
      documentId: widget.documentId,
      currentPage: page,
    );

    ref.read(annotationProvider(widget.documentId).notifier)
        .setCurrentPage(page);
        
    _loadNearbyThumbnails(page);
  }
  
  Future<void> _loadNearbyThumbnails(int currentPage) async {
    for (int i = currentPage - 2; i <= currentPage + 2; i++) {
      if (i >= 1 && i <= _totalPages) {
        _loadThumbnail(i);
      }
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    if (_pdfController == null) return;
    
    _pdfController!.jumpToPage(page - 1);
    
    setState(() {
      _currentPage = page;
    });
  }
  
  void _nextPage() {
    if (_currentPage < _totalPages) {
      _goToPage(_currentPage + 1);
    }
  }
  
  void _previousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleThumbnails() {
    setState(() {
      _showThumbnails = !_showThumbnails;
    });
  }
  
  void _setReadingTheme(ReadingTheme theme) {
    setState(() {
      _readingTheme = theme;
    });
  }
  
  /// Get color filter for reading theme
  ColorFilter _getColorFilter() {
    switch (_readingTheme) {
      case ReadingTheme.light:
        // No filter for light mode
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
      case ReadingTheme.sepia:
        // Sepia tone filter
        return const ColorFilter.matrix(<double>[
          0.94, 0.14, 0.05, 0, 0,
          0.10, 0.86, 0.05, 0, 0,
          0.07, 0.10, 0.79, 0, 0,
          0,    0,    0,    1, 0,
        ]);
      case ReadingTheme.dark:
        // Invert colors for dark mode (white text on black)
        return const ColorFilter.matrix(<double>[
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final annotationState = ref.watch(annotationProvider(widget.documentId));

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _readingTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _readingTheme.surfaceColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _readingTheme.textColor),
            onPressed: () => context.go('/'),
          ),
          title: Text(
            'Loading...',
            style: TextStyle(color: _readingTheme.textColor),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: _readingTheme.textColor,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _readingTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _readingTheme.surfaceColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _readingTheme.textColor),
            onPressed: () => context.go('/'),
          ),
          title: Text('Error', style: TextStyle(color: _readingTheme.textColor)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(_error!, textAlign: TextAlign.center),
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

    if (_pdfController == null) {
      return Scaffold(
        backgroundColor: _readingTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _readingTheme.backgroundColor,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Background color layer
            Container(
              color: _readingTheme.backgroundColor,
            ),
            
            // PDF Viewer with color filters for themes
            ColorFiltered(
              colorFilter: _getColorFilter(),
              child: PdfViewPinch(
                controller: _pdfController!,
                onPageChanged: _onPageChanged,
                padding: 0,
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => Center(
                    child: CircularProgressIndicator(
                      color: _readingTheme.textColor,
                    ),
                  ),
                  pageLoaderBuilder: (_) => Center(
                    child: CircularProgressIndicator(
                      color: _readingTheme.textColor,
                    ),
                  ),
                  errorBuilder: (_, error) => Center(
                    child: Text(
                      'Error loading page: $error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),

            // Top app bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildAppBar(),
              ),

            // Bottom navigation bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(annotationState),
              ),

            // Thumbnail strip
            if (_showThumbnails && _showControls)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: _buildThumbnailStrip(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final repository = ref.read(documentRepositoryProvider);
    final document = repository.getDocument(widget.documentId);

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
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
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
                        document.formattedFileSize,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Theme button
              IconButton(
                icon: Icon(_readingTheme.icon, color: Colors.white),
                onPressed: () => _showThemeSelector(),
                tooltip: 'Reading Theme',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showMoreOptions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(AnnotationState annotationState) {
    final isBookmarked = annotationState.isCurrentPageBookmarked(_currentPage);

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
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left, 
                      color: _currentPage > 1 ? Colors.white : Colors.white38,
                    ),
                    onPressed: _currentPage > 1 ? _previousPage : null,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _currentPage.toDouble().clamp(1, _totalPages.toDouble()),
                        min: 1,
                        max: _totalPages > 0 ? _totalPages.toDouble() : 1,
                        divisions: _totalPages > 1 ? _totalPages - 1 : null,
                        onChanged: (value) => _goToPage(value.round()),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right, 
                      color: _currentPage < _totalPages ? Colors.white : Colors.white38,
                    ),
                    onPressed: _currentPage < _totalPages ? _nextPage : null,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.view_comfy,
                      color: _showThumbnails ? AppColors.primary : Colors.white,
                    ),
                    onPressed: _toggleThumbnails,
                    tooltip: 'Thumbnails',
                  ),
                  IconButton(
                    icon: const Icon(Icons.sticky_note_2_outlined, color: Colors.white),
                    onPressed: () => _showNotesPanel(),
                    tooltip: 'Notes',
                  ),
                  GestureDetector(
                    onTap: () => _showGoToPageDialog(),
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
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.collections_bookmark_outlined, color: Colors.white),
                    onPressed: () => _showBookmarksPanel(),
                    tooltip: 'Bookmarks',
                  ),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppColors.warning : Colors.white,
                    ),
                    onPressed: () {
                      ref.read(annotationProvider(widget.documentId).notifier)
                          .toggleBookmark(_currentPage);
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

  Widget _buildThumbnailStrip() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: _totalPages,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          final isCurrentPage = pageNumber == _currentPage;

          return GestureDetector(
            onTap: () => _goToPage(pageNumber),
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrentPage ? AppColors.primary : Colors.grey.shade300,
                  width: isCurrentPage ? 2.5 : 1,
                ),
                boxShadow: isCurrentPage
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _thumbnailCache.containsKey(pageNumber)
                        ? Image.memory(
                            _thumbnailCache[pageNumber]!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : FutureBuilder<Uint8List?>(
                            future: _loadThumbnail(pageNumber),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                );
                              }
                              return _buildPlaceholder();
                            },
                          ),
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentPage
                                ? AppColors.primary
                                : Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
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
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(height: 4),
          Container(
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 25,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSelectorSheet(
        currentTheme: _readingTheme,
        onThemeChanged: _setReadingTheme,
      ),
    );
  }

  void _showGoToPageDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.find_in_page, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Go to Page'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Page number',
                hintText: '1 - $_totalPages',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page >= 1 && page <= _totalPages) {
                  Navigator.pop(context);
                  _goToPage(page);
                }
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickJumpButton('First', 1),
                if (_totalPages > 10) _buildQuickJumpButton('25%', (_totalPages * 0.25).round()),
                _buildQuickJumpButton('Middle', (_totalPages / 2).round()),
                if (_totalPages > 10) _buildQuickJumpButton('75%', (_totalPages * 0.75).round()),
                _buildQuickJumpButton('Last', _totalPages),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                Navigator.pop(context);
                _goToPage(page);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickJumpButton(String label, int page) {
    final isCurrentPage = page == _currentPage;
    return ActionChip(
      label: Text(label),
      backgroundColor: isCurrentPage ? AppColors.primary.withOpacity(0.2) : null,
      side: BorderSide(
        color: isCurrentPage ? AppColors.primary : Colors.grey.shade300,
      ),
      onPressed: () {
        Navigator.pop(context);
        _goToPage(page);
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(_readingTheme.icon),
              title: const Text('Reading Theme'),
              subtitle: Text(_readingTheme.name),
              onTap: () {
                Navigator.pop(context);
                _showThemeSelector();
              },
            ),
            ListTile(
              leading: const Icon(Icons.find_in_page),
              title: const Text('Go to Page'),
              onTap: () {
                Navigator.pop(context);
                _showGoToPageDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.first_page),
              title: const Text('Go to First Page'),
              onTap: () {
                Navigator.pop(context);
                _goToPage(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.last_page),
              title: const Text('Go to Last Page'),
              onTap: () {
                Navigator.pop(context);
                _goToPage(_totalPages);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Document Info'),
              onTap: () {
                Navigator.pop(context);
                _showDocumentInfo();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDocumentInfo() {
    final repository = ref.read(documentRepositoryProvider);
    final document = repository.getDocument(widget.documentId);
    
    if (document == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Document Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(Icons.description, 'Name', document.name),
            _buildInfoRow(Icons.insert_drive_file, 'Type', document.fileExtension.toUpperCase()),
            _buildInfoRow(Icons.data_usage, 'Size', document.formattedFileSize),
            _buildInfoRow(Icons.layers, 'Pages', '$_totalPages'),
            _buildInfoRow(Icons.bookmark, 'Current Page', '$_currentPage'),
            _buildInfoRow(Icons.percent, 'Progress', '${document.readingProgress.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookmarksPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookmarkPanel(
        documentId: widget.documentId,
        currentPage: _currentPage,
        totalPages: _totalPages,
        onPageSelected: (page) => _goToPage(page),
      ),
    );
  }

  void _showNotesPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotesPanel(
        documentId: widget.documentId,
        currentPage: _currentPage,
        onPageSelected: (page) => _goToPage(page),
      ),
    );
  }
}