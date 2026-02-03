import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/annotation_model.dart';
import '../../../core/constants/app_constants.dart';

/// Provider for annotation repository
final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return AnnotationRepository();
});

/// Repository for annotation CRUD operations
class AnnotationRepository {
  static const _uuid = Uuid();
  
  /// Get the Hive box for annotations
  Box<AnnotationModel> get _box => Hive.box<AnnotationModel>(AppConfig.annotationsBoxName);
  
  /// Get all annotations for a document
  List<AnnotationModel> getAnnotationsForDocument(String documentId) {
    return _box.values
        .where((a) => a.documentId == documentId)
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }
  
  /// Get annotations for a specific page
  List<AnnotationModel> getAnnotationsForPage(String documentId, int pageNumber) {
    return _box.values
        .where((a) => a.documentId == documentId && a.pageNumber == pageNumber)
        .toList();
  }
  
  /// Get all bookmarks for a document
  List<AnnotationModel> getBookmarksForDocument(String documentId) {
    return _box.values
        .where((a) => a.documentId == documentId && a.type == AnnotationType.bookmark)
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }
  
  /// Get all highlights for a document
  List<AnnotationModel> getHighlightsForDocument(String documentId) {
    return _box.values
        .where((a) => a.documentId == documentId && a.isHighlight)
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }
  
  /// Get all sticky notes for a document
  List<AnnotationModel> getNotesForDocument(String documentId) {
    return _box.values
        .where((a) => a.documentId == documentId && a.type == AnnotationType.stickyNote)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  
  /// Get annotation by ID
  AnnotationModel? getAnnotation(String id) {
    return _box.get(id);
  }
  
  /// Add a highlight annotation
  Future<AnnotationModel> addHighlight({
    required String documentId,
    required int pageNumber,
    required String selectedText,
    required HighlightColor color,
    int? startIndex,
    int? endIndex,
  }) async {
    final now = DateTime.now();
    final annotation = AnnotationModel(
      id: _uuid.v4(),
      documentId: documentId,
      type: AnnotationType.highlight,
      pageNumber: pageNumber,
      selectedText: selectedText,
      colorIndex: color.index,
      createdAt: now,
      updatedAt: now,
      startIndex: startIndex,
      endIndex: endIndex,
    );
    
    await _box.put(annotation.id, annotation);
    return annotation;
  }
  
  /// Add a bookmark
  Future<AnnotationModel> addBookmark({
    required String documentId,
    required int pageNumber,
    String? title,
  }) async {
    // Check if bookmark already exists for this page
    final existing = _box.values.firstWhere(
      (a) => a.documentId == documentId && 
             a.pageNumber == pageNumber && 
             a.type == AnnotationType.bookmark,
      orElse: () => AnnotationModel(
        id: '',
        documentId: '',
        type: AnnotationType.bookmark,
        pageNumber: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (existing.id.isNotEmpty) {
      // Update existing bookmark
      final updated = existing.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      await _box.put(existing.id, updated);
      return updated;
    }
    
    final now = DateTime.now();
    final annotation = AnnotationModel(
      id: _uuid.v4(),
      documentId: documentId,
      type: AnnotationType.bookmark,
      pageNumber: pageNumber,
      title: title ?? 'Page $pageNumber',
      createdAt: now,
      updatedAt: now,
    );
    
    await _box.put(annotation.id, annotation);
    return annotation;
  }
  
  /// Add a sticky note
  Future<AnnotationModel> addStickyNote({
    required String documentId,
    required int pageNumber,
    required String content,
    double? positionX,
    double? positionY,
  }) async {
    final now = DateTime.now();
    final annotation = AnnotationModel(
      id: _uuid.v4(),
      documentId: documentId,
      type: AnnotationType.stickyNote,
      pageNumber: pageNumber,
      noteContent: content,
      positionX: positionX ?? 50,
      positionY: positionY ?? 50,
      createdAt: now,
      updatedAt: now,
    );
    
    await _box.put(annotation.id, annotation);
    return annotation;
  }
  
  /// Update annotation
  Future<void> updateAnnotation(AnnotationModel annotation) async {
    final updated = annotation.copyWith(updatedAt: DateTime.now());
    await _box.put(annotation.id, updated);
  }
  
  /// Update sticky note content
  Future<void> updateNoteContent(String annotationId, String content) async {
    final annotation = getAnnotation(annotationId);
    if (annotation != null) {
      final updated = annotation.copyWith(
        noteContent: content,
        updatedAt: DateTime.now(),
      );
      await _box.put(annotationId, updated);
    }
  }
  
  /// Update highlight color
  Future<void> updateHighlightColor(String annotationId, HighlightColor color) async {
    final annotation = getAnnotation(annotationId);
    if (annotation != null) {
      final updated = annotation.copyWith(
        colorIndex: color.index,
        updatedAt: DateTime.now(),
      );
      await _box.put(annotationId, updated);
    }
  }
  
  /// Delete annotation
  Future<void> deleteAnnotation(String annotationId) async {
    await _box.delete(annotationId);
  }
  
  /// Delete all annotations for a document
  Future<void> deleteAllAnnotationsForDocument(String documentId) async {
    final toDelete = _box.values
        .where((a) => a.documentId == documentId)
        .map((a) => a.id)
        .toList();
    
    for (final id in toDelete) {
      await _box.delete(id);
    }
  }
  
  /// Check if a page is bookmarked
  bool isPageBookmarked(String documentId, int pageNumber) {
    return _box.values.any(
      (a) => a.documentId == documentId && 
             a.pageNumber == pageNumber && 
             a.type == AnnotationType.bookmark,
    );
  }
  
  /// Toggle bookmark for a page
  Future<bool> toggleBookmark(String documentId, int pageNumber) async {
    final existing = _box.values.firstWhere(
      (a) => a.documentId == documentId && 
             a.pageNumber == pageNumber && 
             a.type == AnnotationType.bookmark,
      orElse: () => AnnotationModel(
        id: '',
        documentId: '',
        type: AnnotationType.bookmark,
        pageNumber: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (existing.id.isNotEmpty) {
      await deleteAnnotation(existing.id);
      return false; // Bookmark removed
    } else {
      await addBookmark(documentId: documentId, pageNumber: pageNumber);
      return true; // Bookmark added
    }
  }
  
  /// Get annotation count for a document
  int getAnnotationCount(String documentId) {
    return _box.values.where((a) => a.documentId == documentId).length;
  }
}
