import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_models.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/playlists_provider.dart';
import 'playlist_form_screen.dart';

class PlaylistsListScreen extends ConsumerStatefulWidget {
  const PlaylistsListScreen({super.key});

  @override
  ConsumerState<PlaylistsListScreen> createState() => _PlaylistsListScreenState();
}

class _PlaylistsListScreenState extends ConsumerState<PlaylistsListScreen> {
  String? _selectedType;
  String? _selectedContentType;
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(
      playlistsListProvider(
        page: _currentPage,
        size: _pageSize,
        playlistType: _selectedType,
        contentType: _selectedContentType,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Playlist Type Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(labelText: 'Playlist Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Types')),
                        DropdownMenuItem(value: 'USER', child: Text('User')),
                        DropdownMenuItem(value: 'PUBLIC', child: Text('Public')),
                        DropdownMenuItem(value: 'SYSTEM', child: Text('System')),
                        DropdownMenuItem(value: 'SERIES', child: Text('Lecture Series')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content Type Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedContentType,
                      decoration: const InputDecoration(labelText: 'Content Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Content')),
                        DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                        DropdownMenuItem(value: 'AUDIO', child: Text('Audio')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedContentType = value;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Playlists List
          Expanded(
            child: playlistsAsync.when(
              data: (pagedResponse) {
                if (pagedResponse.content.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.playlist_play, size: 64, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(height: 16),
                        const Text('No playlists found', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text('Create a new playlist to get started'),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Content Type')),
                        DataColumn(label: Text('Items')),
                        DataColumn(label: Text('Public')),
                        DataColumn(label: Text('Created')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: pagedResponse.content.map((playlist) {
                        return DataRow(
                          cells: [
                            DataCell(Text(playlist.id.toString())),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      playlist.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (playlist.description != null)
                                      Text(
                                        playlist.description!,
                                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(_buildTypeChip(playlist.contentType)),
                            DataCell(Text(playlist.contentType)),
                            DataCell(Text(playlist.contentCount.toString())),
                            DataCell(
                              Icon(
                                playlist.isPublic ? Icons.public : Icons.lock,
                                color: playlist.isPublic ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                            ),
                            DataCell(
                              Text('${playlist.createdAt.day}/${playlist.createdAt.month}/${playlist.createdAt.year}'),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editPlaylist(playlist),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deletePlaylist(playlist.id, playlist.name),
                                    tooltip: 'Delete',
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => ref.invalidate(playlistsListProvider), child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),

          // Pagination
          playlistsAsync.whenData((pagedResponse) {
                if (pagedResponse.totalPages <= 1) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          'Page ${_currentPage + 1} of ${pagedResponse.totalPages}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _currentPage < pagedResponse.totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                );
              }).value ??
              const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPlaylist,
        icon: const Icon(Icons.add),
        label: const Text('New Playlist'),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    switch (type.toUpperCase()) {
      case 'SYSTEM':
        color = Colors.purple;
      case 'SERIES':
        color = Colors.blue;
      case 'PUBLIC':
        color = Colors.green;
      case 'USER':
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(type, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _createPlaylist() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PlaylistFormScreen()));
  }

  void _editPlaylist(Playlist playlist) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistFormScreen(playlist: playlist)));
  }

  Future<void> _deletePlaylist(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await ref.read(playlistActionsProvider.notifier).deletePlaylist(id);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Playlist deleted successfully');
      ref.invalidate(playlistsListProvider);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to delete playlist: $e');
    }
  }
}
