import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/models/document_model.dart';
import '../../../core/constants/app_constants.dart';

/// Provider for document repository
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});

/// Repository for document CRUD operations
class DocumentRepository {
  static const _uuid = Uuid();
  
  /// Get the Hive box for documents
  Box<DocumentModel> get _box => Hive.box<DocumentModel>(AppConfig.documentsBoxName);
  
  /// Get all documents sorted by last opened
  List<DocumentModel> getAllDocuments() {
    final docs = _box.values.toList();
    docs.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return docs;
  }
  
  /// Get document by ID
  DocumentModel? getDocument(String id) {
    return _box.get(id);
  }
  
  /// Get documents in a folder
  List<DocumentModel> getDocumentsInFolder(String? folderId) {
    return _box.values
        .where((doc) => doc.folderId == folderId)
        .toList();
  }
  
  /// Get favorite documents
  List<DocumentModel> getFavoriteDocuments() {
    return _box.values
        .where((doc) => doc.isFavorite)
        .toList();
  }
  
  /// Get recent documents (last 10)
  List<DocumentModel> getRecentDocuments({int limit = 10}) {
    final docs = getAllDocuments();
    return docs.take(limit).toList();
  }
  
  /// Search documents by name
  List<DocumentModel> searchDocuments(String query) {
    if (query.isEmpty) return getAllDocuments();
    
    final lowerQuery = query.toLowerCase();
    return _box.values
        .where((doc) => doc.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
  
  /// Import a document from file path (mobile/desktop)
  Future<DocumentModel> importDocument(String sourcePath) async {
    final sourceFile = File(sourcePath);
    
    if (!await sourceFile.exists()) {
      throw Exception('File does not exist: $sourcePath');
    }
    
    // Get file info
    final fileName = path.basename(sourcePath);
    final extension = path.extension(sourcePath).replaceFirst('.', '');
    final fileSize = await sourceFile.length();
    
    // Validate file type
    if (!AppConfig.supportedExtensions.contains(extension.toLowerCase())) {
      throw Exception('Unsupported file type: $extension');
    }
    
    // Validate file size
    if (fileSize > AppConfig.maxFileSizeBytes) {
      throw Exception('File too large. Maximum size is ${AppConfig.maxFileSizeMB}MB');
    }
    
    // Copy file to app's document directory
    final appDir = await getApplicationDocumentsDirectory();
    final documentsDir = Directory('${appDir.path}/documents');
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    
    final id = _uuid.v4();
    final newFileName = '${id}_$fileName';
    final newPath = '${documentsDir.path}/$newFileName';
    
    await sourceFile.copy(newPath);
    
    // Create document model
    final now = DateTime.now();
    final document = DocumentModel(
      id: id,
      name: fileName,
      filePath: newPath,
      fileSize: fileSize,
      fileExtension: extension,
      createdAt: now,
      lastOpenedAt: now,
    );
    
    // Save to Hive
    await _box.put(id, document);
    
    return document;
  }
  
  /// Import a document from bytes (web)
  Future<DocumentModel> importDocumentFromBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = path.extension(fileName).replaceFirst('.', '');
    final fileSize = bytes.length;
    
    // Validate file type
    if (!AppConfig.supportedExtensions.contains(extension.toLowerCase())) {
      throw Exception('Unsupported file type: $extension');
    }
    
    // Validate file size
    if (fileSize > AppConfig.maxFileSizeBytes) {
      throw Exception('File too large. Maximum size is ${AppConfig.maxFileSizeMB}MB');
    }
    
    final id = _uuid.v4();
    
    // On web, we store the bytes in memory (via a special path convention)
    // For this MVP, we'll use a data URL approach or store in IndexedDB via Hive
    String filePath;
    
    if (kIsWeb) {
      // On web, store bytes as a List<int> in a separate Hive box
      // This avoids the detached ArrayBuffer issue
      final bytesBox = await Hive.openBox<List<int>>('document_bytes');
      await bytesBox.put(id, bytes.toList()); // Convert to regular List<int>
      filePath = 'hive://$id'; // Special marker for web storage
    } else {
      // On mobile/desktop, save to file system
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${appDir.path}/documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      
      final newFileName = '${id}_$fileName';
      filePath = '${documentsDir.path}/$newFileName';
      
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    }
    
    // Create document model
    final now = DateTime.now();
    final document = DocumentModel(
      id: id,
      name: fileName,
      filePath: filePath,
      fileSize: fileSize,
      fileExtension: extension,
      createdAt: now,
      lastOpenedAt: now,
    );
    
    // Save to Hive
    await _box.put(id, document);
    
    return document;
  }
  
  /// Get document bytes (for web)
  Future<Uint8List?> getDocumentBytes(String documentId) async {
    final bytesBox = await Hive.openBox<List<int>>('document_bytes');
    final bytes = bytesBox.get(documentId);
    if (bytes == null) return null;
    // Create a fresh Uint8List from the stored List<int>
    return Uint8List.fromList(bytes);
  }
  
  /// Update document
  Future<void> updateDocument(DocumentModel document) async {
    await _box.put(document.id, document);
  }
  
  /// Update last opened time
  Future<void> markAsOpened(String documentId) async {
    final doc = getDocument(documentId);
    if (doc != null) {
      final updated = doc.copyWith(lastOpenedAt: DateTime.now());
      await updateDocument(updated);
    }
  }
  
  /// Update reading progress
  Future<void> updateProgress({
    required String documentId,
    required int currentPage,
    double? zoomLevel,
    double? scrollPosition,
  }) async {
    final doc = getDocument(documentId);
    if (doc != null) {
      final updated = doc.copyWith(
        currentPage: currentPage,
        lastZoomLevel: zoomLevel ?? doc.lastZoomLevel,
        lastScrollPosition: scrollPosition ?? doc.lastScrollPosition,
        lastOpenedAt: DateTime.now(),
      );
      await updateDocument(updated);
    }
  }
  
  /// Update page count (called after loading PDF)
  Future<void> updatePageCount(String documentId, int pageCount) async {
    final doc = getDocument(documentId);
    if (doc != null) {
      final updated = doc.copyWith(pageCount: pageCount);
      await updateDocument(updated);
    }
  }
  
  /// Toggle favorite status
  Future<void> toggleFavorite(String documentId) async {
    final doc = getDocument(documentId);
    if (doc != null) {
      final updated = doc.copyWith(isFavorite: !doc.isFavorite);
      await updateDocument(updated);
    }
  }
  
  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    final doc = getDocument(documentId);
    if (doc != null) {
      if (kIsWeb) {
        // Delete from bytes storage
        final bytesBox = await Hive.openBox<List<int>>('document_bytes');
        await bytesBox.delete(documentId);
      } else {
        // Delete file from disk
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Delete thumbnail if exists
      if (doc.thumbnailPath != null && !kIsWeb) {
        final thumbnail = File(doc.thumbnailPath!);
        if (await thumbnail.exists()) {
          await thumbnail.delete();
        }
      }
      
      // Remove from Hive
      await _box.delete(documentId);
    }
  }
  
  /// Rename document
  Future<void> renameDocument(String documentId, String newName) async {
    final doc = getDocument(documentId);
    if (doc != null) {
      final updated = doc.copyWith(name: newName);
      await updateDocument(updated);
    }
  }
  
  /// Add tag to document
  Future<void> addTag(String documentId, String tag) async {
    final doc = getDocument(documentId);
    if (doc != null && !doc.tags.contains(tag)) {
      final updated = doc.copyWith(tags: [...doc.tags, tag]);
      await updateDocument(updated);
    }
  }
  
  /// Remove tag from document
  Future<void> removeTag(String documentId, String tag) async {
    final doc = getDocument(documentId);
    if (doc != null) {
      final updated = doc.copyWith(
        tags: doc.tags.where((t) => t != tag).toList(),
      );
      await updateDocument(updated);
    }
  }
}
