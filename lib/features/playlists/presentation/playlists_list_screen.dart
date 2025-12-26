import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/models/api_models.dart';
import '../../../core/utils/admin_grid_config.dart';
import '../../../core/utils/role_guard.dart';
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
  int _pageSize = 20;

  List<TrinaColumn> _buildColumns(BuildContext context) {
    final theme = Theme.of(context);

    return [
      TrinaColumn(
        field: 'id',
        title: 'ID',
        frozen: TrinaColumnFrozen.start,
        type: TrinaColumnType.number(),
        width: 70,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'name',
        title: 'Name',
        type: TrinaColumnType.text(),
        width: 250,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final name = rendererContext.row.cells['name']?.value as String? ?? '-';
          final description = rendererContext.row.cells['description']?.value as String?;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          );
        },
      ),
      TrinaColumn(
        field: 'playlistType',
        title: 'Type',
        type: TrinaColumnType.text(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final type = rendererContext.cell.value as String? ?? 'USER';
          return Center(child: _buildTypeChip(type));
        },
      ),
      TrinaColumn(
        field: 'contentType',
        title: 'Content Type',
        type: TrinaColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final contentType = rendererContext.cell.value as String? ?? '-';
          return Center(child: _buildContentTypeChip(contentType));
        },
      ),
      TrinaColumn(
        field: 'contentCount',
        title: 'Items',
        type: TrinaColumnType.number(),
        width: 80,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final count = rendererContext.cell.value as int? ?? 0;
          return Center(child: Text(count.toString(), style: theme.textTheme.bodyMedium));
        },
      ),
      TrinaColumn(
        field: 'isPublic',
        title: 'Public',
        type: TrinaColumnType.boolean(),
        width: 80,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final isPublic = rendererContext.cell.value as bool? ?? false;
          return Center(
            child: Icon(isPublic ? Icons.public : Icons.lock, color: isPublic ? Colors.green : Colors.grey, size: 20),
          );
        },
      ),
      TrinaColumn(
        field: 'createdAt',
        title: 'Created',
        type: TrinaColumnType.text(),
        width: 120,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'actions',
        title: 'Actions',
        frozen: TrinaColumnFrozen.end,
        type: TrinaColumnType.text(),
        width: 130,
        enableEditingMode: false,
        renderer: (rendererContext) => _buildActionsCell(rendererContext),
      ),
    ];
  }

  Widget _buildActionsCell(TrinaColumnRendererContext rendererContext) {
    final playlistId = rendererContext.row.cells['id']?.value as int?;
    final playlistName = rendererContext.row.cells['name']?.value as String? ?? '';
    final contentType = rendererContext.row.cells['contentType']?.value as String? ?? 'VIDEO';

    if (playlistId == null) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.playlist_add, size: 20, color: Theme.of(context).colorScheme.primary),
          onPressed: () => _manageItems(playlistId, playlistName, contentType),
          tooltip: 'Manage Items',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editPlaylistById(playlistId),
          tooltip: 'Edit',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        RoleGuard(
          requiredPermission: Permission.delete,
          child: IconButton(
            icon: Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
            onPressed: () => _deletePlaylist(playlistId, playlistName),
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  TrinaRow _playlistToRow(Playlist playlist) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: playlist.id),
        'name': TrinaCell(value: playlist.name),
        'description': TrinaCell(value: playlist.description ?? ''),
        'playlistType': TrinaCell(value: playlist.isPublic ? 'PUBLIC' : 'USER'),
        'contentType': TrinaCell(value: playlist.contentType),
        'contentCount': TrinaCell(value: playlist.contentCount),
        'isPublic': TrinaCell(value: playlist.isPublic),
        'createdAt': TrinaCell(value: _formatDate(playlist.createdAt)),
        'actions': TrinaCell(value: playlist.id),
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        type,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildContentTypeChip(String contentType) {
    final isVideo = contentType.toUpperCase() == 'VIDEO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isVideo ? Colors.red.shade400 : Colors.teal.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        contentType,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _onPageChanged(int newPage) {
    setState(() => _currentPage = newPage);
  }

  void _onPageSizeChanged(int newSize) {
    setState(() {
      _pageSize = newSize;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(playlistsListProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
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

          // Playlists Grid
          Expanded(
            child: playlistsAsync.when(
              data: (pagedResponse) {
                if (pagedResponse.content.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.playlist_play, size: 64, color: theme.colorScheme.secondary),
                        const SizedBox(height: 16),
                        const Text('No playlists found', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text('Create a new playlist to get started'),
                      ],
                    ),
                  );
                }

                final rows = pagedResponse.content.map(_playlistToRow).toList();

                return TrinaGrid(
                  key: ValueKey('playlists_grid_${_currentPage}_${_selectedType}_$_selectedContentType'),
                  columns: _buildColumns(context),
                  rows: rows,

                  configuration: AdminGridConfig.getConfiguration(context),
                  createFooter: (stateManager) {
                    return AdminGridConfig.buildPaginationFooter(
                      context: context,
                      currentPage: _currentPage,
                      pageSize: _pageSize,
                      totalElements: pagedResponse.totalElements,
                      totalPages: pagedResponse.totalPages,
                      currentItemCount: pagedResponse.content.length,
                      onPageChanged: _onPageChanged,
                      onPageSizeChanged: _onPageSizeChanged,
                    );
                  },
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
                    FilledButton(onPressed: () => ref.invalidate(playlistsListProvider), child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPlaylist,
        icon: const Icon(Icons.add),
        label: const Text('New Playlist'),
      ),
    );
  }

  void _createPlaylist() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PlaylistFormScreen()));
  }

  Future<void> _editPlaylistById(int playlistId) async {
    // Fetch the playlist data first
    try {
      final playlistsAsync = ref.read(
        playlistsListProvider(
          page: _currentPage,
          size: _pageSize,
          playlistType: _selectedType,
          contentType: _selectedContentType,
        ),
      );

      final pagedResponse = playlistsAsync.value;
      if (pagedResponse == null) return;

      final playlist = pagedResponse.content.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => throw Exception('Playlist not found'),
      );

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistFormScreen(playlist: playlist)));
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to load playlist: $e');
    }
  }

  void _manageItems(int playlistId, String name, String contentType) {
    context.push('/playlists/$playlistId/items?name=${Uri.encodeComponent(name)}&contentType=$contentType');
  }

  Future<void> _deletePlaylist(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
