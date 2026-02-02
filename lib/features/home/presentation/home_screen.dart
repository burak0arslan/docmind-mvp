import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
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
    final theme = Theme.of(context);

    // Show error snackbar if there's an error
    ref.listen<HomeState>(homeProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
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
        title: const Text('DocMind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // TODO: Implement sorting options
              _showSortOptions(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (query) {
                ref.read(homeProvider.notifier).searchDocuments(query);
              },
            ),
          ),

          // Document list
          Expanded(
            child: homeState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : homeState.documents.isEmpty
                    ? EmptyStateWidget(
                        searchQuery: homeState.searchQuery,
                        onImport: () => _importDocument(),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(homeProvider.notifier).loadDocuments();
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: homeState.documents.length,
                          itemBuilder: (context, index) {
                            final doc = homeState.documents[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () => context.goToReader(doc.id),
                              onFavorite: () {
                                ref
                                    .read(homeProvider.notifier)
                                    .toggleFavorite(doc.id);
                              },
                              onDelete: () => _confirmDelete(context, doc.id),
                              onRename: () => _showRenameDialog(context, doc),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importDocument,
        icon: const Icon(Icons.add),
        label: const Text('Import'),
      ),
    );
  }

  Future<void> _importDocument() async {
    final document = await ref.read(homeProvider.notifier).importDocument();
    
    if (document != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported: ${document.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(homeProvider.notifier).deleteDocument(documentId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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
