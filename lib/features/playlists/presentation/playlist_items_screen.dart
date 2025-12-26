import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/playlist_item_model.dart';
import '../providers/playlists_provider.dart';

/// Screen for managing items within a playlist
class PlaylistItemsScreen extends ConsumerStatefulWidget {
  final int playlistId;
  final String playlistName;
  final String contentType;
  final bool embedded;

  const PlaylistItemsScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required this.contentType,
    this.embedded = false,
  });

  @override
  ConsumerState<PlaylistItemsScreen> createState() => _PlaylistItemsScreenState();
}

class _PlaylistItemsScreenState extends ConsumerState<PlaylistItemsScreen> {
  TrinaGridStateManager? _stateManager;
  List<TrinaRow> _rows = [];

  @override
  void dispose() {
    _stateManager?.dispose();
    super.dispose();
  }

  TrinaRow _itemToRow(PlaylistItemModel item) {
    return TrinaRow(
      cells: {
        'sortOrder': TrinaCell(value: item.sortOrder + 1),
        'contentId': TrinaCell(value: item.contentId),
        'thumbnail': TrinaCell(value: item.contentThumbnail ?? ''),
        'contentTitle': TrinaCell(value: item.contentTitle),
        'contentType': TrinaCell(value: item.contentType ?? ''),
        'duration': TrinaCell(value: item.formattedDuration),
        'addedAt': TrinaCell(value: _formatDateTime(item.addedAt)),
        'actions': TrinaCell(value: item.id),
        '_item': TrinaCell(value: item),
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  Future<void> _moveItem(PlaylistItemModel item, int newPosition) async {
    try {
      await ref
          .read(playlistItemsActionsProvider.notifier)
          .reorderItem(playlistId: widget.playlistId, itemId: item.id, newPosition: newPosition);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Item reordered');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to reorder: $e');
    }
  }

  Future<void> _confirmRemoveItem(PlaylistItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.contentTitle}" from this playlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(playlistItemsActionsProvider.notifier)
            .removeItem(playlistId: widget.playlistId, itemId: item.id);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Item removed');
      } catch (e) {
        if (!mounted) return;
        SnackBarHelper.showError(context, 'Failed to remove: $e');
      }
    }
  }

  Future<void> _showAddContentDialog() async {
    final contentIdController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the Content ID to add to this playlist.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: contentIdController,
              decoration: const InputDecoration(
                labelText: 'Content ID',
                border: OutlineInputBorder(),
                hintText: 'e.g., 123',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final id = int.tryParse(contentIdController.text);
              if (id != null) {
                Navigator.of(context).pop(id);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ref.read(playlistItemsActionsProvider.notifier).addItem(playlistId: widget.playlistId, contentId: result);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Content added');
      } catch (e) {
        if (!mounted) return;
        SnackBarHelper.showError(context, 'Failed to add: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(playlistItemsProvider(widget.playlistId));

    final body = Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                widget.embedded ? '${widget.playlistName} - Items' : 'Playlist Items',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(playlistItemsProvider(widget.playlistId)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showAddContentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Content'),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_add, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No items in this playlist',
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Add Content" to add items',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _showAddContentDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Content'),
                      ),
                    ],
                  ),
                );
              }

              _rows = items.map(_itemToRow).toList();

              return TrinaGrid(
                columns: [
                  TrinaColumn(
                    title: '#',
                    field: 'sortOrder',
                    type: TrinaColumnType.number(),
                    width: 60,
                    frozen: TrinaColumnFrozen.start,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Content ID',
                    field: 'contentId',
                    type: TrinaColumnType.number(),
                    width: 100,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Thumbnail',
                    field: 'thumbnail',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final url = rendererContext.cell.value as String?;
                      if (url == null || url.isEmpty) {
                        return Container(
                          width: 80,
                          height: 45,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.image_not_supported, color: theme.colorScheme.outline),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          url,
                          width: 80,
                          height: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 45,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.broken_image, color: theme.colorScheme.outline),
                          ),
                        ),
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Title',
                    field: 'contentTitle',
                    type: TrinaColumnType.text(),
                    width: 300,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Type',
                    field: 'contentType',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final type = rendererContext.cell.value as String?;
                      return Chip(
                        label: Text(type ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                        backgroundColor: type == 'VIDEO'
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.secondaryContainer,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Duration',
                    field: 'duration',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Added',
                    field: 'addedAt',
                    type: TrinaColumnType.text(),
                    width: 160,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Actions',
                    field: 'actions',
                    type: TrinaColumnType.text(),
                    width: 180,
                    frozen: TrinaColumnFrozen.end,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final item = rendererContext.row.cells['_item']?.value as PlaylistItemModel?;
                      if (item == null) return const SizedBox.shrink();

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 20),
                            tooltip: 'Move up',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: item.sortOrder > 0 ? () => _moveItem(item, item.sortOrder - 1) : null,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 20),
                            tooltip: 'Move down',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: item.sortOrder < _rows.length - 1
                                ? () => _moveItem(item, item.sortOrder + 1)
                                : null,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                            tooltip: 'Remove',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmRemoveItem(item),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                rows: _rows,
                onLoaded: (TrinaGridOnLoadedEvent event) {
                  _stateManager = event.stateManager;
                },
                configuration: TrinaGridConfiguration(
                  style: const TrinaGridStyleConfig(
                    rowHeight: 60,
                    columnHeight: 45,
                    enableCellBorderHorizontal: false,
                    enableCellBorderVertical: true,
                  ),
                  scrollbar: const TrinaGridScrollbarConfig(isAlwaysShown: false, thumbVisible: true),
                  columnSize: const TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.none),
                ),
                createFooter: (stateManager) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: theme.dividerColor)),
                    ),
                    child: Row(
                      children: [
                        Text('${items.length} items'),
                        const Spacer(),
                        Text(
                          'Use arrow buttons to reorder items',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading items: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(playlistItemsProvider(widget.playlistId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(playlistItemsProvider(widget.playlistId)),
          ),
        ],
      ),
      body: body,
    );
  }
}
