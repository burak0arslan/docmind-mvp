import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/annotation_model.dart';
import '../../domain/annotation_provider.dart';

/// Simple highlight storage model
class PageHighlight {
  final String id;
  final int pageNumber;
  final double left;   // 0-1 normalized
  final double top;    // 0-1 normalized  
  final double width;  // 0-1 normalized
  final double height; // 0-1 normalized
  final int colorIndex;

  PageHighlight({
    required this.id,
    required this.pageNumber,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.colorIndex,
  });

  HighlightColor get color => HighlightColor.values[colorIndex];

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageNumber': pageNumber,
    'left': left,
    'top': top,
    'width': width,
    'height': height,
    'colorIndex': colorIndex,
  };

  factory PageHighlight.fromJson(Map<String, dynamic> json) => PageHighlight(
    id: json['id'],
    pageNumber: json['pageNumber'],
    left: json['left'],
    top: json['top'],
    width: json['width'],
    height: json['height'],
    colorIndex: json['colorIndex'],
  );
}

/// Provider for highlights per document
final highlightsProvider = StateNotifierProvider.family<HighlightsNotifier, List<PageHighlight>, String>(
  (ref, documentId) => HighlightsNotifier(documentId),
);

class HighlightsNotifier extends StateNotifier<List<PageHighlight>> {
  final String documentId;
  static const _uuid = Uuid();

  HighlightsNotifier(this.documentId) : super([]) {
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    try {
      final box = await Hive.openBox('highlights_$documentId');
      final List<PageHighlight> loaded = [];
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          loaded.add(PageHighlight.fromJson(Map<String, dynamic>.from(data)));
        }
      }
      state = loaded;
    } catch (e) {
      print('Error loading highlights: $e');
    }
  }

  Future<void> addHighlight({
    required int pageNumber,
    required double left,
    required double top,
    required double width,
    required double height,
    required int colorIndex,
  }) async {
    final highlight = PageHighlight(
      id: _uuid.v4(),
      pageNumber: pageNumber,
      left: left,
      top: top,
      width: width,
      height: height,
      colorIndex: colorIndex,
    );

    try {
      final box = await Hive.openBox('highlights_$documentId');
      await box.put(highlight.id, highlight.toJson());
      state = [...state, highlight];
    } catch (e) {
      print('Error saving highlight: $e');
    }
  }

  Future<void> updateColor(String id, int colorIndex) async {
    final index = state.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final old = state[index];
    final updated = PageHighlight(
      id: old.id,
      pageNumber: old.pageNumber,
      left: old.left,
      top: old.top,
      width: old.width,
      height: old.height,
      colorIndex: colorIndex,
    );

    try {
      final box = await Hive.openBox('highlights_$documentId');
      await box.put(id, updated.toJson());
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
    } catch (e) {
      print('Error updating highlight: $e');
    }
  }

  Future<void> deleteHighlight(String id) async {
    try {
      final box = await Hive.openBox('highlights_$documentId');
      await box.delete(id);
      state = state.where((h) => h.id != id).toList();
    } catch (e) {
      print('Error deleting highlight: $e');
    }
  }

  List<PageHighlight> getHighlightsForPage(int pageNumber) {
    return state.where((h) => h.pageNumber == pageNumber).toList();
  }
}

/// Overlay for drawing highlights
class HighlightDrawingOverlay extends ConsumerStatefulWidget {
  final String documentId;
  final int currentPage;
  final bool isEnabled;
  final int selectedColorIndex;
  final VoidCallback? onHighlightDrawn;

  const HighlightDrawingOverlay({
    super.key,
    required this.documentId,
    required this.currentPage,
    required this.isEnabled,
    required this.selectedColorIndex,
    this.onHighlightDrawn,
  });

  @override
  ConsumerState<HighlightDrawingOverlay> createState() => _HighlightDrawingOverlayState();
}

class _HighlightDrawingOverlayState extends ConsumerState<HighlightDrawingOverlay> {
  Offset? _startPoint;
  Offset? _endPoint;

  @override
  Widget build(BuildContext context) {
    final highlights = ref.watch(highlightsProvider(widget.documentId));
    final pageHighlights = highlights.where((h) => h.pageNumber == widget.currentPage).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return GestureDetector(
          behavior: widget.isEnabled ? HitTestBehavior.opaque : HitTestBehavior.translucent,
          onPanStart: widget.isEnabled ? (details) {
            setState(() {
              _startPoint = details.localPosition;
              _endPoint = details.localPosition;
            });
          } : null,
          onPanUpdate: widget.isEnabled ? (details) {
            setState(() {
              _endPoint = details.localPosition;
            });
          } : null,
          onPanEnd: widget.isEnabled ? (details) {
            if (_startPoint != null && _endPoint != null) {
              _saveHighlight(size);
            }
            setState(() {
              _startPoint = null;
              _endPoint = null;
            });
          } : null,
          child: Stack(
            children: [
              // Existing highlights
              ...pageHighlights.map((h) => Positioned(
                left: h.left * size.width,
                top: h.top * size.height,
                width: h.width * size.width,
                height: h.height * size.height,
                child: GestureDetector(
                  onTap: () => _showHighlightMenu(h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: h.color.color.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              )),

              // Currently drawing highlight
              if (_startPoint != null && _endPoint != null)
                Positioned(
                  left: _startPoint!.dx < _endPoint!.dx ? _startPoint!.dx : _endPoint!.dx,
                  top: _startPoint!.dy < _endPoint!.dy ? _startPoint!.dy : _endPoint!.dy,
                  width: (_endPoint!.dx - _startPoint!.dx).abs(),
                  height: (_endPoint!.dy - _startPoint!.dy).abs(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: HighlightColor.values[widget.selectedColorIndex].color.withOpacity(0.4),
                      border: Border.all(
                        color: HighlightColor.values[widget.selectedColorIndex].darkColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _saveHighlight(Size size) {
    if (_startPoint == null || _endPoint == null) return;

    final left = (_startPoint!.dx < _endPoint!.dx ? _startPoint!.dx : _endPoint!.dx) / size.width;
    final top = (_startPoint!.dy < _endPoint!.dy ? _startPoint!.dy : _endPoint!.dy) / size.height;
    final width = (_endPoint!.dx - _startPoint!.dx).abs() / size.width;
    final height = (_endPoint!.dy - _startPoint!.dy).abs() / size.height;

    // Min size check
    if (width < 0.02 || height < 0.01) return;

    ref.read(highlightsProvider(widget.documentId).notifier).addHighlight(
      pageNumber: widget.currentPage,
      left: left,
      top: top,
      width: width,
      height: height,
      colorIndex: widget.selectedColorIndex,
    );

    widget.onHighlightDrawn?.call();
  }

  void _showHighlightMenu(PageHighlight highlight) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Highlight Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Color options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: HighlightColor.values.asMap().entries.map((entry) {
                  final index = entry.key;
                  final color = entry.value;
                  final isSelected = highlight.colorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      ref.read(highlightsProvider(widget.documentId).notifier)
                          .updateColor(highlight.id, index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color.darkColor : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected ? Icon(Icons.check, color: color.darkColor, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete Highlight', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  ref.read(highlightsProvider(widget.documentId).notifier)
                      .deleteHighlight(highlight.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}