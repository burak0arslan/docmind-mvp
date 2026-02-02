import 'package:hive/hive.dart';

part 'document_model.g.dart';

/// Document model for storing document metadata
@HiveType(typeId: 0)
class DocumentModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String filePath;
  
  @HiveField(3)
  final String? thumbnailPath;
  
  @HiveField(4)
  final int fileSize;
  
  @HiveField(5)
  final String fileExtension;
  
  @HiveField(6)
  final int pageCount;
  
  @HiveField(7)
  final int currentPage;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final DateTime lastOpenedAt;
  
  @HiveField(10)
  final List<String> tags;
  
  @HiveField(11)
  final String? folderId;
  
  @HiveField(12)
  final bool isFavorite;
  
  @HiveField(13)
  final double lastZoomLevel;
  
  @HiveField(14)
  final double lastScrollPosition;
  
  DocumentModel({
    required this.id,
    required this.name,
    required this.filePath,
    this.thumbnailPath,
    required this.fileSize,
    required this.fileExtension,
    this.pageCount = 0,
    this.currentPage = 0,
    required this.createdAt,
    required this.lastOpenedAt,
    this.tags = const [],
    this.folderId,
    this.isFavorite = false,
    this.lastZoomLevel = 1.0,
    this.lastScrollPosition = 0.0,
  });
  
  /// Create a copy with updated fields
  DocumentModel copyWith({
    String? id,
    String? name,
    String? filePath,
    String? thumbnailPath,
    int? fileSize,
    String? fileExtension,
    int? pageCount,
    int? currentPage,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    List<String>? tags,
    String? folderId,
    bool? isFavorite,
    double? lastZoomLevel,
    double? lastScrollPosition,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      pageCount: pageCount ?? this.pageCount,
      currentPage: currentPage ?? this.currentPage,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      isFavorite: isFavorite ?? this.isFavorite,
      lastZoomLevel: lastZoomLevel ?? this.lastZoomLevel,
      lastScrollPosition: lastScrollPosition ?? this.lastScrollPosition,
    );
  }
  
  /// Get formatted file size string
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Get reading progress percentage
  double get readingProgress {
    if (pageCount == 0) return 0;
    return (currentPage / pageCount) * 100;
  }
  
  /// Check if document is PDF
  bool get isPdf => fileExtension.toLowerCase() == 'pdf';
  
  /// Check if document is eBook
  bool get isEbook => ['epub', 'mobi', 'azw3'].contains(fileExtension.toLowerCase());
  
  @override
  String toString() {
    return 'DocumentModel(id: $id, name: $name, pages: $pageCount)';
  }
}
