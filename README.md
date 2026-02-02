# DocMind

AI-powered PDF and eBook reader application built with Flutter.

## 🚀 Features (MVP)

- **PDF Viewing** - Fast, smooth PDF rendering with zoom and scroll
- **Document Library** - Import and organize your documents
- **Reading Modes** - Continuous scroll or page-by-page
- **Themes** - Light, dark, and sepia reading modes
- **Progress Tracking** - Automatically saves your reading position
- **Offline First** - All documents stored locally

## 📋 Prerequisites

- Flutter SDK (>=3.2.0)
- Dart SDK (>=3.2.0)
- Android Studio / Xcode
- iOS Simulator or Android Emulator

## 🛠️ Setup

### 1. Clone and navigate
```bash
cd docmind
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Generate Hive adapters (if modified)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Create asset directories
```bash
mkdir -p assets/icons assets/images assets/fonts
```

### 5. Add placeholder files (optional)
Create empty `.gitkeep` files in asset directories for version control.

## 🏃 Running the App

### Development
```bash
# Check devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run with verbose logging
flutter run -v
```

### Build for Release

#### Android
```bash
flutter build apk --release
# or for bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── app/
│   ├── app.dart           # Main app widget
│   └── router.dart        # Navigation routes
├── core/
│   ├── constants/         # App-wide constants
│   ├── theme/             # Theme configuration
│   └── utils/             # Utility functions
├── features/
│   ├── home/              # Document library
│   │   ├── data/          # Repositories
│   │   ├── domain/        # State management
│   │   └── presentation/  # UI components
│   └── reader/            # PDF viewer
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
    ├── models/            # Data models
    └── widgets/           # Shared UI components
```

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| flutter_riverpod | State management |
| go_router | Navigation |
| pdfx | PDF rendering |
| hive_flutter | Local storage |
| file_picker | File import |
| path_provider | File paths |

## 🎯 Roadmap

### Phase 1 (Current): Core Viewer ✅
- [x] Project setup
- [x] PDF viewing
- [x] Document management
- [x] Basic navigation

### Phase 2: Annotations
- [ ] Highlight support
- [ ] Sticky notes
- [ ] Freehand drawing
- [ ] Bookmark system

### Phase 3: AI Features
- [ ] Document summarization
- [ ] Chat with PDF
- [ ] Semantic search
- [ ] Flashcard generation

### Phase 4: Collaboration
- [ ] Share documents
- [ ] Real-time annotations
- [ ] Version history

## 🐛 Known Issues

1. **Large PDFs**: Documents over 500 pages may have initial load delay
2. **Thumbnails**: Page thumbnails are placeholders (will add actual rendering)

## 📝 License

Proprietary - All rights reserved

## 👥 Contributing

This is a private project. Contact the team for contribution guidelines.
