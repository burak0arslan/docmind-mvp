/// App-wide spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// App-wide sizing constants
class AppSizing {
  // Border radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 999;
  
  // Icon sizes
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  
  // Document thumbnails
  static const double thumbnailWidth = 120;
  static const double thumbnailHeight = 160;
  
  // Bottom navigation
  static const double bottomNavHeight = 80;
}

/// App-wide animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// App configuration constants
class AppConfig {
  // File limits
  static const int maxFileSizeMB = 500;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
  
  // Supported file types
  static const List<String> supportedExtensions = [
    'pdf',
    'epub',
    'mobi',
    'azw3',
  ];
  
  // PDF rendering
  static const int pdfPageCacheCount = 10;
  static const double pdfMinZoom = 0.5;
  static const double pdfMaxZoom = 5.0;
  static const double pdfDefaultZoom = 1.0;
  
  // Storage keys
  static const String documentsBoxName = 'documents';
  static const String settingsBoxName = 'settings';
  static const String annotationsBoxName = 'annotations';
}

/// File type helpers
enum DocumentType {
  pdf,
  epub,
  mobi,
  azw3,
  unknown;
  
  static DocumentType fromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return DocumentType.pdf;
      case 'epub':
        return DocumentType.epub;
      case 'mobi':
        return DocumentType.mobi;
      case 'azw3':
        return DocumentType.azw3;
      default:
        return DocumentType.unknown;
    }
  }
  
  String get displayName {
    switch (this) {
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.epub:
        return 'ePub';
      case DocumentType.mobi:
        return 'MOBI';
      case DocumentType.azw3:
        return 'AZW3';
      case DocumentType.unknown:
        return 'Unknown';
    }
  }
  
  bool get isSupported => this != DocumentType.unknown;
}
