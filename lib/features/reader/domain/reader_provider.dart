import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../../shared/models/document_model.dart';
import '../../home/data/document_repository.dart';

/// Reading mode options
enum ReadingMode {
  continuous,
  paginated,
}

/// Theme options for reading
enum ReadingTheme {
  light,
  dark,
  sepia,
}

/// State for the reader screen
class ReaderState {
  final DocumentModel? document;
  final int currentPage;
  final int totalPages;
  final double zoomLevel;
  final bool isLoading;
  final String? error;
  final ReadingMode readingMode;
  final ReadingTheme readingTheme;
  final bool showControls;
  final bool showThumbnails;

  const ReaderState({
    this.document,
    this.currentPage = 1,
    this.totalPages = 0,
    this.zoomLevel = 1.0,
    this.isLoading = true,
    this.error,
    this.readingMode = ReadingMode.continuous,
    this.readingTheme = ReadingTheme.light,
    this.showControls = true,
    this.showThumbnails = false,
  });

  ReaderState copyWith({
    DocumentModel? document,
    int? currentPage,
    int? totalPages,
    double? zoomLevel,
    bool? isLoading,
    String? error,
    ReadingMode? readingMode,
    ReadingTheme? readingTheme,
    bool? showControls,
    bool? showThumbnails,
  }) {
    return ReaderState(
      document: document ?? this.document,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      readingMode: readingMode ?? this.readingMode,
      readingTheme: readingTheme ?? this.readingTheme,
      showControls: showControls ?? this.showControls,
      showThumbnails: showThumbnails ?? this.showThumbnails,
    );
  }

  /// Get progress percentage
  double get progress {
    if (totalPages == 0) return 0;
    return (currentPage / totalPages) * 100;
  }
}

/// Reader screen state notifier
class ReaderNotifier extends StateNotifier<ReaderState> {
  final DocumentRepository _repository;
  final String documentId;
  PdfControllerPinch? _pdfController;

  ReaderNotifier(this._repository, this.documentId) : super(const ReaderState()) {
    loadDocument();
  }

  /// Get the PDF controller
  PdfControllerPinch? get pdfController => _pdfController;

  /// Load the document
  Future<void> loadDocument() async {
    // Dispose any existing controller first
    _pdfController?.dispose();
    _pdfController = null;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get document from repository
      final document = _repository.getDocument(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }

      int pageCount;
      final startPage = document.currentPage > 0 ? document.currentPage : 1;
      
      if (kIsWeb) {
        // On web, load from bytes stored in Hive
        // Get fresh bytes each time
        final bytes = await _repository.getDocumentBytes(documentId);
        if (bytes == null) {
          throw Exception('Document data not found');
        }
        
        // Get page count with a fresh copy
        final countBytes = Uint8List.fromList(bytes.toList());
        final tempDoc = await PdfDocument.openData(countBytes);
        pageCount = tempDoc.pagesCount;
        await tempDoc.close();
        
        // Create controller with another fresh copy
        final controllerBytes = Uint8List.fromList(bytes.toList());
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(controllerBytes),
          initialPage: startPage,
        );
      } else {
        // On mobile/desktop, load from file
        final file = File(document.filePath);
        if (!await file.exists()) {
          throw Exception('Document file not found');
        }
        
        // Get page count
        final tempDoc = await PdfDocument.openFile(document.filePath);
        pageCount = tempDoc.pagesCount;
        await tempDoc.close();
        
        // Create controller
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(document.filePath),
          initialPage: startPage,
        );
      }

      // Update page count in repository if needed
      if (document.pageCount != pageCount) {
        await _repository.updatePageCount(documentId, pageCount);
      }

      // Mark as opened
      await _repository.markAsOpened(documentId);

      state = state.copyWith(
        document: document.copyWith(pageCount: pageCount),
        currentPage: startPage,
        totalPages: pageCount,
        zoomLevel: document.lastZoomLevel,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Go to a specific page
  void goToPage(int page) {
    if (page < 1 || page > state.totalPages) return;
    
    _pdfController?.jumpToPage(page);
    state = state.copyWith(currentPage: page);
    _saveProgress();
  }

  /// Go to next page
  void nextPage() {
    if (state.currentPage < state.totalPages) {
      goToPage(state.currentPage + 1);
    }
  }

  /// Go to previous page
  void previousPage() {
    if (state.currentPage > 1) {
      goToPage(state.currentPage - 1);
    }
  }

  /// Update current page (called by PDF viewer)
  void onPageChanged(int page) {
    state = state.copyWith(currentPage: page);
    _saveProgress();
  }

  /// Update zoom level
  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom);
  }

  /// Toggle reading mode
  void toggleReadingMode() {
    state = state.copyWith(
      readingMode: state.readingMode == ReadingMode.continuous
          ? ReadingMode.paginated
          : ReadingMode.continuous,
    );
  }

  /// Set reading theme
  void setReadingTheme(ReadingTheme theme) {
    state = state.copyWith(readingTheme: theme);
  }

  /// Toggle controls visibility
  void toggleControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  /// Toggle thumbnail view
  void toggleThumbnails() {
    state = state.copyWith(showThumbnails: !state.showThumbnails);
  }

  /// Save reading progress
  Future<void> _saveProgress() async {
    await _repository.updateProgress(
      documentId: documentId,
      currentPage: state.currentPage,
      zoomLevel: state.zoomLevel,
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }
}

/// Provider family for reader state (one per document)
/// Using autoDispose to ensure fresh state each time document is opened
final readerProvider = StateNotifierProvider.autoDispose.family<ReaderNotifier, ReaderState, String>(
  (ref, documentId) {
    final repository = ref.watch(documentRepositoryProvider);
    return ReaderNotifier(repository, documentId);
  },
);
