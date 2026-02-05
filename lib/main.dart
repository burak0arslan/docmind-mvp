import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'shared/models/document_model.dart';
import 'shared/models/annotation_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation (mobile only)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(DocumentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AnnotationTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(HighlightColorAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AnnotationModelAdapter());
  }
  
  // Open boxes
  await Hive.openBox<DocumentModel>('documents');
  await Hive.openBox<AnnotationModel>('annotations');

  runApp(
    const ProviderScope(
      child: DocMindApp(),
    ),
  );
}