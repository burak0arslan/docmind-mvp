import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/animated_fade_in.dart';
import '../domain/home_provider.dart';
import 'widgets/document_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/search_bar_widget.dart';

/// Home screen showing document library
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    // Show error snackbar if there's an error
    ref.listen<HomeState>(homeProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ref.read(homeProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_stories,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('DocMind'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with animation
          AnimatedFadeIn(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SearchBarWidget(
                controller: _searchController,
                onChanged: (query) {
                  ref.read(homeProvider.notifier).searchDocuments(query);
                },
              ),
            ),
          ),

          // Document list
          Expanded(
            child: _buildDocumentList(homeState),
          ),
        ],
      ),
      floatingActionButton: AnimatedFadeIn(
        delay: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: _importDocument,
          icon: const Icon(Icons.add),
          label: const Text('Import'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildDocumentList(HomeState homeState) {
    // Show shimmer while loading
    if (homeState.isLoading && homeState.documents.isEmpty) {
      return const DocumentGridShimmer(itemCount: 6);
    }

    // Show empty state
    if (homeState.documents.isEmpty) {
      return AnimatedFadeIn(
        child: EmptyStateWidget(
          searchQuery: homeState.searchQuery,
          onImport: _importDocument,
        ),
      );
    }

    // Show document grid with staggered animations
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(homeProvider.notifier).loadDocuments();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.7,
        ),
        itemCount: homeState.documents.length,
        itemBuilder: (context, index) {
          final doc = homeState.documents[index];
          return StaggeredFadeIn(
            index: index,
            child: AnimatedScaleButton(
              onTap: () => context.goToReader(doc.id),
              onLongPress: () => _showDocumentOptions(context, doc),
              child: DocumentCard(
                document: doc,
                onTap: () => context.goToReader(doc.id),
                onFavorite: () {
                  ref.read(homeProvider.notifier).toggleFavorite(doc.id);
                },
                onDelete: () => _confirmDelete(context, doc.id),
                onRename: () => _showRenameDialog(context, doc),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _importDocument() async {
    final document = await ref.read(homeProvider.notifier).importDocument();

    if (document != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Imported: ${document.name}')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Recent'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Favorites'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDocumentOptions(BuildContext context, document) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(context);
                context.goToReader(document.id);
              },
            ),
            ListTile(
              leading: Icon(
                document.isFavorite ? Icons.star : Icons.star_border,
                color: document.isFavorite ? AppColors.warning : null,
              ),
              title: Text(
                document.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(homeProvider.notifier).toggleFavorite(document.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, document);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, document.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('Delete Document'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(homeProvider.notifier).deleteDocument(documentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, document) {
    final controller = TextEditingController(text: document.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Rename Document'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Document name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.trim().isNotEmpty) {
                ref.read(homeProvider.notifier).renameDocument(
                      document.id,
                      controller.text.trim(),
                    );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
