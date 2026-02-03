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
      
      // Pre-load first few thumbnails
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
    
    // Load thumbnails for first 5 pages
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
        
    // Load nearby thumbnails
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
    
    print('Going to page: $page');
    _pdfController!.jumpToPage(page - 1);
    
    // Update state immediately for responsive UI
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

  @override
  Widget build(BuildContext context) {
    final annotationState = ref.watch(annotationProvider(widget.documentId));

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // PDF Viewer
            PdfViewPinch(
              controller: _pdfController!,
              onPageChanged: _onPageChanged,
              padding: 0,
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
                    onTap: () => _showPagePicker(),
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
            onTap: () {
              print('Thumbnail tapped: page $pageNumber');
              _goToPage(pageNumber);
            },
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
                    // Thumbnail image
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
                    
                    // Page number badge
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
      ),
    );
  }

  void _showPagePicker() {
    final controller = TextEditingController(text: _currentPage.toString());
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
            hintText: '1 - $_totalPages',
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
