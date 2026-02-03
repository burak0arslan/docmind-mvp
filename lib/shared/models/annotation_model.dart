import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'annotation_model.g.dart';

/// Type of annotation
@HiveType(typeId: 1)
enum AnnotationType {
  @HiveField(0)
  highlight,
  
  @HiveField(1)
  bookmark,
  
  @HiveField(2)
  stickyNote,
  
  @HiveField(3)
  underline,
  
  @HiveField(4)
  strikethrough,
}

/// Highlight color options
@HiveType(typeId: 2)
enum HighlightColor {
  @HiveField(0)
  yellow,
  
  @HiveField(1)
  green,
  
  @HiveField(2)
  blue,
  
  @HiveField(3)
  pink,
  
  @HiveField(4)
  orange,
}

/// Extension to get actual colors
extension HighlightColorExtension on HighlightColor {
  Color get color {
    switch (this) {
      case HighlightColor.yellow:
        return const Color(0xFFFEF08A);
      case HighlightColor.green:
        return const Color(0xFFBBF7D0);
      case HighlightColor.blue:
        return const Color(0xFFBFDBFE);
      case HighlightColor.pink:
        return const Color(0xFFFBCFE8);
      case HighlightColor.orange:
        return const Color(0xFFFED7AA);
    }
  }
  
  Color get darkColor {
    switch (this) {
      case HighlightColor.yellow:
        return const Color(0xFFCA8A04);
      case HighlightColor.green:
        return const Color(0xFF16A34A);
      case HighlightColor.blue:
        return const Color(0xFF2563EB);
      case HighlightColor.pink:
        return const Color(0xFFDB2777);
      case HighlightColor.orange:
        return const Color(0xFFEA580C);
    }
  }
  
  String get name {
    switch (this) {
      case HighlightColor.yellow:
        return 'Yellow';
      case HighlightColor.green:
        return 'Green';
      case HighlightColor.blue:
        return 'Blue';
      case HighlightColor.pink:
        return 'Pink';
      case HighlightColor.orange:
        return 'Orange';
    }
  }
}

/// Annotation model for storing all types of annotations
@HiveType(typeId: 3)
class AnnotationModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String documentId;
  
  @HiveField(2)
  final AnnotationType type;
  
  @HiveField(3)
  final int pageNumber;
  
  @HiveField(4)
  final String? selectedText;
  
  @HiveField(5)
  final String? noteContent;
  
  @HiveField(6)
  final int colorIndex; // Index of HighlightColor enum
  
  @HiveField(7)
  final double? positionX; // For sticky notes positioning
  
  @HiveField(8)
  final double? positionY;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final DateTime updatedAt;
  
  @HiveField(11)
  final String? title; // For bookmarks
  
  // Text selection bounds (for highlights)
  @HiveField(12)
  final int? startIndex;
  
  @HiveField(13)
  final int? endIndex;
  
  AnnotationModel({
    required this.id,
    required this.documentId,
    required this.type,
    required this.pageNumber,
    this.selectedText,
    this.noteContent,
    this.colorIndex = 0,
    this.positionX,
    this.positionY,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.startIndex,
    this.endIndex,
  });
  
  /// Get highlight color from index
  HighlightColor get highlightColor => HighlightColor.values[colorIndex];
  
  /// Create a copy with updated fields
  AnnotationModel copyWith({
    String? id,
    String? documentId,
    AnnotationType? type,
    int? pageNumber,
    String? selectedText,
    String? noteContent,
    int? colorIndex,
    double? positionX,
    double? positionY,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    int? startIndex,
    int? endIndex,
  }) {
    return AnnotationModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      type: type ?? this.type,
      pageNumber: pageNumber ?? this.pageNumber,
      selectedText: selectedText ?? this.selectedText,
      noteContent: noteContent ?? this.noteContent,
      colorIndex: colorIndex ?? this.colorIndex,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
    );
  }
  
  /// Check if this is a highlight type annotation
  bool get isHighlight => type == AnnotationType.highlight || 
                          type == AnnotationType.underline || 
                          type == AnnotationType.strikethrough;
  
  /// Check if this is a bookmark
  bool get isBookmark => type == AnnotationType.bookmark;
  
  /// Check if this is a sticky note
  bool get isStickyNote => type == AnnotationType.stickyNote;
  
  @override
  String toString() {
    return 'AnnotationModel(id: $id, type: $type, page: $pageNumber)';
  }
}
