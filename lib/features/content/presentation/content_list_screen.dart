import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/content_model.dart';
import '../providers/content_provider.dart';
import 'content_form_screen.dart';

class ContentListScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const ContentListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends ConsumerState<ContentListScreen> {
  String? _selectedContentType;
  String? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 50;
  TrinaGridStateManager? _stateManager;
  List<TrinaRow> _rows = [];

  @override
  void dispose() {
    _searchController.dispose();
    _stateManager?.dispose();
    super.dispose();
  }

  /// Convert ContentItem to TrinaRow
  TrinaRow _contentToRow(ContentItem content) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: content.id),
        'type': TrinaCell(value: content.contentType.name),
        'title': TrinaCell(value: content.title ?? 'Untitled'),
        'duration': TrinaCell(value: content.formattedDuration),
        'status': TrinaCell(value: content.status.name),
        'isPremium': TrinaCell(value: content.isPremium),
        'views': TrinaCell(value: content.viewCount),
        'rating': TrinaCell(value: content.averageRating?.toStringAsFixed(2) ?? '-'),
        'artist': TrinaCell(value: content.artist ?? '-'),
        'recordingDate': TrinaCell(value: content.recordingDate?.toString().split(' ')[0] ?? '-'),
        'actions': TrinaCell(value: content.id),
      },
    );
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(
      contentListProvider(
        page: _currentPage,
        size: _pageSize,
        contentType: _selectedContentType,
        status: _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );

    final body = Column(
      children: [
        // Search and Filters
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search content',
                    hintText: 'Search by title, artist, description...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _currentPage = 0;
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filters + Export buttons
                Row(
                  children: [
                    // Content Type filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedContentType,
                        decoration: const InputDecoration(labelText: 'Content Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
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
                    const SizedBox(width: 16),
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                          DropdownMenuItem(value: 'PROCESSING', child: Text('Processing')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Export buttons
                    TextButton.icon(
                      onPressed: _stateManager != null ? () => _exportToCSV() : null,
                      icon: const Icon(Icons.download),
                      label: const Text('CSV'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _stateManager != null ? () => _exportToPDF() : null,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Content list with TrinaGrid
        Expanded(
          child: contentAsync.when(
            data: (pagedData) {
              final contentList = pagedData.content;
              if (contentList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text('No content found', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your first video or audio content',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Convert content to rows
              _rows = contentList.map(_contentToRow).toList();

              return TrinaGrid(
                columns: [
                  TrinaColumn(
                    title: 'ID',
                    field: 'id',
                    type: TrinaColumnType.number(),
                    width: 80,
                    frozen: TrinaColumnFrozen.start,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Type',
                    field: 'type',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final type = rendererContext.cell.value?.toString() ?? '';
                      final isVideo = type.toUpperCase() == 'VIDEO';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isVideo ? Colors.purple.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVideo ? Icons.videocam : Icons.music_note,
                              size: 16,
                              color: isVideo ? Colors.purple : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(type, style: TextStyle(fontSize: 12, color: isVideo ? Colors.purple : Colors.orange)),
                          ],
                        ),
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Title',
                    field: 'title',
                    type: TrinaColumnType.text(),
                    width: 300,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Duration',
                    field: 'duration',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Status',
                    field: 'status',
                    type: TrinaColumnType.text(),
                    width: 120,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final status = rendererContext.cell.value?.toString() ?? '';
                      Color color;
                      switch (status.toUpperCase()) {
                        case 'ACTIVE':
                          color = Colors.green;
                          break;
                        case 'INACTIVE':
                          color = Colors.grey;
                          break;
                        case 'PROCESSING':
                          color = Colors.orange;
                          break;
                        default:
                          color = Colors.grey;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status, style: TextStyle(fontSize: 12, color: color)),
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Premium',
                    field: 'isPremium',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final isPremium = rendererContext.cell.value as bool? ?? false;
                      return Icon(
                        isPremium ? Icons.star : Icons.star_border,
                        color: isPremium ? Colors.amber : Colors.grey,
                        size: 20,
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Views',
                    field: 'views',
                    type: TrinaColumnType.number(),
                    width: 100,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Rating',
                    field: 'rating',
                    type: TrinaColumnType.text(),
                    width: 80,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Artist',
                    field: 'artist',
                    type: TrinaColumnType.text(),
                    width: 150,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Recording Date',
                    field: 'recordingDate',
                    type: TrinaColumnType.text(),
                    width: 130,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Actions',
                    field: 'actions',
                    type: TrinaColumnType.text(),
                    width: 200,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final contentId = rendererContext.cell.value as int?;
                      if (contentId == null) return const SizedBox();
                      final content = contentList.firstWhere((c) => c.id == contentId);
                      final isAudio = content.contentType == ContentType.AUDIO;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.translate, size: 18),
                            onPressed: () => _manageTranslations(content),
                            tooltip: 'Manage Translations',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          if (isAudio)
                            IconButton(
                              icon: const Icon(Icons.lyrics, size: 18),
                              onPressed: () => _manageLyrics(content),
                              tooltip: 'Manage Lyrics',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (isAudio) const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editContent(content),
                            tooltip: 'Edit',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _deleteContent(contentId),
                            tooltip: 'Delete',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                onRowDoubleTap: (event) {
                  final contentId = event.row.cells['id']?.value as int?;
                  if (contentId != null) {
                    final content = contentList.firstWhere((c) => c.id == contentId);
                    _editContent(content);
                  }
                },
                configuration: TrinaGridConfiguration(
                  style: const TrinaGridStyleConfig(
                    rowHeight: 50,
                    columnHeight: 45,
                    enableCellBorderHorizontal: false,
                    enableCellBorderVertical: true,
                  ),
                  scrollbar: const TrinaGridScrollbarConfig(isAlwaysShown: false, thumbVisible: true),
                  columnSize: const TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.none),
                ),
                createFooter: (stateManager) {
                  // Server-side pagination controls
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${pagedData.number * pagedData.size + 1}-${pagedData.number * pagedData.size + contentList.length} of ${pagedData.totalElements} items',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _currentPage > 0 ? () => _onPageChanged(0) : null,
                              icon: const Icon(Icons.first_page),
                              tooltip: 'First page',
                            ),
                            IconButton(
                              onPressed: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
                              icon: const Icon(Icons.chevron_left),
                              tooltip: 'Previous page',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Page ${_currentPage + 1} of ${pagedData.totalPages}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: _currentPage < pagedData.totalPages - 1
                                  ? () => _onPageChanged(_currentPage + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              tooltip: 'Next page',
                            ),
                            IconButton(
                              onPressed: _currentPage < pagedData.totalPages - 1
                                  ? () => _onPageChanged(pagedData.totalPages - 1)
                                  : null,
                              icon: const Icon(Icons.last_page),
                              tooltip: 'Last page',
                            ),
                          ],
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
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading content', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(
                      contentListProvider(
                        page: _currentPage,
                        size: _pageSize,
                        contentType: _selectedContentType,
                        status: _selectedStatus,
                      ),
                    ),
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
        title: const Text('Content Management'),
        actions: [
          TextButton.icon(onPressed: _createContent, icon: const Icon(Icons.add), label: const Text('Upload Content')),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(
              contentListProvider(
                page: _currentPage,
                size: _pageSize,
                contentType: _selectedContentType,
                status: _selectedStatus,
              ),
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
    );
  }

  Future<void> _exportToCSV() async {
    if (_stateManager == null) return;

    try {
      final csvExport = TrinaGridExportCsv();
      final csvData = await csvExport.export(stateManager: _stateManager!, includeHeaders: true);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'CSV export ready (${csvData.length} bytes)');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Export failed: $e');
    }
  }

  Future<void> _exportToPDF() async {
    if (_stateManager == null) return;

    try {
      final pdfExport = TrinaGridExportPdf();
      final pdfData = await pdfExport.export(
        stateManager: _stateManager!,
        title: 'Content Export',
        creator: 'Satsang Admin',
        includeHeaders: true,
      );

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'PDF export ready (${pdfData.length} bytes)');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Export failed: $e');
    }
  }

  void _createContent() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentFormScreen())).then((result) {
      if (result == true) {
        // ignore: unused_result
        ref.refresh(
          contentListProvider(
            page: _currentPage,
            size: _pageSize,
            contentType: _selectedContentType,
            status: _selectedStatus,
          ),
        );
      }
    });
  }

  void _editContent(ContentItem content) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ContentFormScreen(content: content))).then((result) {
      if (result == true) {
        // ignore: unused_result
        ref.refresh(
          contentListProvider(
            page: _currentPage,
            size: _pageSize,
            contentType: _selectedContentType,
            status: _selectedStatus,
          ),
        );
      }
    });
  }

  void _manageTranslations(ContentItem content) {
    // Use deep linking for translations
    context.go('/content/${content.id}/translations');
  }

  void _manageLyrics(ContentItem content) {
    // Use deep linking for lyrics
    context.go('/content/${content.id}/lyrics');
  }

  Future<void> _deleteContent(int contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Are you sure you want to delete this content? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(contentActionsProvider.notifier).deleteContent(contentId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Content deleted successfully');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to delete content: $e');
    }
  }
}
