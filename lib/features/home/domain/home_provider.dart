import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../shared/models/document_model.dart';
import '../data/document_repository.dart';

/// State for the home screen
class HomeState {
  final List<DocumentModel> documents;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const HomeState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  HomeState copyWith({
    List<DocumentModel>? documents,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return HomeState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Home screen state notifier
class HomeNotifier extends StateNotifier<HomeState> {
  final DocumentRepository _repository;

  HomeNotifier(this._repository) : super(const HomeState()) {
    loadDocuments();
  }

  /// Load all documents
  Future<void> loadDocuments() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final documents = _repository.getAllDocuments();
      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search documents
  void searchDocuments(String query) {
    state = state.copyWith(searchQuery: query);
    
    if (query.isEmpty) {
      final documents = _repository.getAllDocuments();
      state = state.copyWith(documents: documents);
    } else {
      final documents = _repository.searchDocuments(query);
      state = state.copyWith(documents: documents);
    }
  }

  /// Import document from file picker
  Future<DocumentModel?> importDocument() async {
    try {
      // Open file picker - request bytes for web compatibility
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'mobi', 'azw3'],
        allowMultiple: false,
        withData: true, // Important: get bytes for web
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      state = state.copyWith(isLoading: true);

      DocumentModel document;
      
      if (kIsWeb) {
        // On web, use bytes
        if (file.bytes == null) {
          throw Exception('Could not read file data');
        }
        document = await _repository.importDocumentFromBytes(
          bytes: file.bytes!,
          fileName: file.name,
        );
      } else {
        // On mobile/desktop, use path
        if (file.path == null) {
          throw Exception('Could not get file path');
        }
        document = await _repository.importDocument(file.path!);
      }
      
      // Refresh document list
      await loadDocuments();
      
      return document;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _repository.deleteDocument(documentId);
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(String documentId) async {
    try {
      await _repository.toggleFavorite(documentId);
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Rename document
  Future<void> renameDocument(String documentId, String newName) async {
    try {
      await _repository.renameDocument(documentId, newName);
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for home state
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return HomeNotifier(repository);
});
