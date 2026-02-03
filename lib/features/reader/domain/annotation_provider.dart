import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/annotation_model.dart';
import '../data/annotation_repository.dart';

/// State for annotations in the reader
class AnnotationState {
  final List<AnnotationModel> annotations;
  final List<AnnotationModel> bookmarks;
  final List<AnnotationModel> currentPageAnnotations;
  final bool isLoading;
  final String? error;
  final HighlightColor selectedColor;
  final bool isAnnotationMode;
  final AnnotationType? activeAnnotationType;

  const AnnotationState({
    this.annotations = const [],
    this.bookmarks = const [],
    this.currentPageAnnotations = const [],
    this.isLoading = false,
    this.error,
    this.selectedColor = HighlightColor.yellow,
    this.isAnnotationMode = false,
    this.activeAnnotationType,
  });

  AnnotationState copyWith({
    List<AnnotationModel>? annotations,
    List<AnnotationModel>? bookmarks,
    List<AnnotationModel>? currentPageAnnotations,
    bool? isLoading,
    String? error,
    HighlightColor? selectedColor,
    bool? isAnnotationMode,
    AnnotationType? activeAnnotationType,
    bool clearActiveType = false,
  }) {
    return AnnotationState(
      annotations: annotations ?? this.annotations,
      bookmarks: bookmarks ?? this.bookmarks,
      currentPageAnnotations: currentPageAnnotations ?? this.currentPageAnnotations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedColor: selectedColor ?? this.selectedColor,
      isAnnotationMode: isAnnotationMode ?? this.isAnnotationMode,
      activeAnnotationType: clearActiveType ? null : (activeAnnotationType ?? this.activeAnnotationType),
    );
  }
  
  /// Check if current page is bookmarked
  bool isCurrentPageBookmarked(int pageNumber) {
    return bookmarks.any((b) => b.pageNumber == pageNumber);
  }
  
  /// Get highlights for a specific page
  List<AnnotationModel> getHighlightsForPage(int pageNumber) {
    return annotations.where((a) => a.pageNumber == pageNumber && a.isHighlight).toList();
  }
  
  /// Get notes for a specific page
  List<AnnotationModel> getNotesForPage(int pageNumber) {
    return annotations.where((a) => a.pageNumber == pageNumber && a.isStickyNote).toList();
  }
}

/// Annotation notifier for managing annotation state
class AnnotationNotifier extends StateNotifier<AnnotationState> {
  final AnnotationRepository _repository;
  final String documentId;
  int _currentPage = 1;

  AnnotationNotifier(this._repository, this.documentId) : super(const AnnotationState()) {
    loadAnnotations();
  }

  /// Load all annotations for the document
  Future<void> loadAnnotations() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final annotations = _repository.getAnnotationsForDocument(documentId);
      final bookmarks = _repository.getBookmarksForDocument(documentId);
      final currentPageAnnotations = _repository.getAnnotationsForPage(documentId, _currentPage);
      
      state = state.copyWith(
        annotations: annotations,
        bookmarks: bookmarks,
        currentPageAnnotations: currentPageAnnotations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update current page and load its annotations
  void setCurrentPage(int pageNumber) {
    _currentPage = pageNumber;
    final currentPageAnnotations = _repository.getAnnotationsForPage(documentId, pageNumber);
    state = state.copyWith(currentPageAnnotations: currentPageAnnotations);
  }

  /// Toggle annotation mode
  void toggleAnnotationMode() {
    state = state.copyWith(
      isAnnotationMode: !state.isAnnotationMode,
      clearActiveType: !state.isAnnotationMode ? false : true,
    );
  }

  /// Set active annotation type
  void setActiveAnnotationType(AnnotationType? type) {
    state = state.copyWith(
      activeAnnotationType: type,
      isAnnotationMode: type != null,
      clearActiveType: type == null,
    );
  }

  /// Set highlight color
  void setHighlightColor(HighlightColor color) {
    state = state.copyWith(selectedColor: color);
  }

  /// Add a highlight
  Future<void> addHighlight({
    required int pageNumber,
    required String selectedText,
    int? startIndex,
    int? endIndex,
  }) async {
    try {
      await _repository.addHighlight(
        documentId: documentId,
        pageNumber: pageNumber,
        selectedText: selectedText,
        color: state.selectedColor,
        startIndex: startIndex,
        endIndex: endIndex,
      );
      await loadAnnotations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add a bookmark for current page
  Future<void> addBookmark({
    required int pageNumber,
    String? title,
  }) async {
    try {
      await _repository.addBookmark(
        documentId: documentId,
        pageNumber: pageNumber,
        title: title,
      );
      await loadAnnotations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Toggle bookmark for current page
  Future<bool> toggleBookmark(int pageNumber) async {
    try {
      final result = await _repository.toggleBookmark(documentId, pageNumber);
      await loadAnnotations();
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add a sticky note
  Future<void> addStickyNote({
    required int pageNumber,
    required String content,
    double? positionX,
    double? positionY,
  }) async {
    try {
      await _repository.addStickyNote(
        documentId: documentId,
        pageNumber: pageNumber,
        content: content,
        positionX: positionX,
        positionY: positionY,
      );
      await loadAnnotations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update a sticky note
  Future<void> updateStickyNote(String annotationId, String content) async {
    try {
      await _repository.updateNoteContent(annotationId, content);
      await loadAnnotations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update highlight color
  Future<void> updateHighlightColor(String annotationId, HighlightColor color) async {
    try {
      await _repository.updateHighlightColor(annotationId, color);
      await loadAnnotations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete an annotation
  Future<void> deleteAnnotation(String annotationId) async {
    try {
      await _repository.deleteAnnotation(annotationId);
      await loadAnnotations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Check if page is bookmarked
  bool isPageBookmarked(int pageNumber) {
    return _repository.isPageBookmarked(documentId, pageNumber);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider family for annotation state (one per document)
final annotationProvider = StateNotifierProvider.family<AnnotationNotifier, AnnotationState, String>(
  (ref, documentId) {
    final repository = ref.watch(annotationRepositoryProvider);
    return AnnotationNotifier(repository, documentId);
  },
);
