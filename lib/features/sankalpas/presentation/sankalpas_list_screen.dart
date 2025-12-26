import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/utils/admin_grid_config.dart';
import '../../../core/utils/role_guard.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../models/sankalp_template_model.dart';
import '../providers/sankalpas_provider.dart';
import 'sankalp_form_screen.dart';

class SankalpasListScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const SankalpasListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SankalpasListScreen> createState() => _SankalpasListScreenState();
}

class _SankalpasListScreenState extends ConsumerState<SankalpasListScreen> {
  String? _selectedType;
  bool? _selectedSystemTemplate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _pageSize = 50;
  TrinaGridStateManager? _stateManager;
  List<TrinaRow> _rows = [];

  @override
  void dispose() {
    _searchController.dispose();
    _stateManager?.dispose();
    super.dispose();
  }

  /// Convert SankalpTemplate to TrinaRow
  TrinaRow _templateToRow(SankalpTemplate template) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: template.id),
        'title': TrinaCell(value: template.title),
        'titleHindi': TrinaCell(value: template.titleHindi ?? ''),
        'sankalpType': TrinaCell(value: template.sankalpType.displayName),
        'defaultTarget': TrinaCell(
          value: template.defaultTargetValue != null
              ? '${template.defaultTargetValue} ${template.defaultTargetUnit ?? ''}'.trim()
              : '-',
        ),
        'icon': TrinaCell(value: template.icon ?? ''),
        'displayOrder': TrinaCell(value: template.displayOrder),
        'isSystemTemplate': TrinaCell(value: template.isSystemTemplate),
        'actions': TrinaCell(value: template.id),
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
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(
      sankalpTemplatesListProvider(
        page: _currentPage,
        size: _pageSize,
        sankalpType: _selectedType,
        isSystemTemplate: _selectedSystemTemplate,
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
                    labelText: 'Search templates',
                    hintText: 'Search by title, description...',
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
                // Type and System filters
                Row(
                  children: [
                    // Sankalp type filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(labelText: 'Sankalp Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Types')),
                          DropdownMenuItem(value: 'TIME_BASED', child: Text('Time Based')),
                          DropdownMenuItem(value: 'COUNT_BASED', child: Text('Count Based')),
                          DropdownMenuItem(value: 'BOOLEAN', child: Text('Yes/No')),
                          DropdownMenuItem(value: 'ROOPDHYAN_SPECIAL', child: Text('Roopdhyan Special')),
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
                    // System template filter
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _selectedSystemTemplate,
                        decoration: const InputDecoration(labelText: 'Template Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: true, child: Text('System Templates')),
                          DropdownMenuItem(value: false, child: Text('Custom Templates')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSystemTemplate = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Templates list with TrinaGrid
        Expanded(
          child: templatesAsync.when(
            data: (pagedData) {
              final templates = pagedData.content;
              if (templates.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.self_improvement, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No sankalp templates found', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first sankalp template using the + button',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Convert templates to rows
              _rows = templates.map(_templateToRow).toList();

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
                    title: 'Title',
                    field: 'title',
                    type: TrinaColumnType.text(),
                    width: 200,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Title (Hindi)',
                    field: 'titleHindi',
                    type: TrinaColumnType.text(),
                    width: 180,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Type',
                    field: 'sankalpType',
                    type: TrinaColumnType.text(),
                    width: 140,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final type = rendererContext.cell.value?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _getTypeColor(type), borderRadius: BorderRadius.circular(12)),
                        child: Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Target',
                    field: 'defaultTarget',
                    type: TrinaColumnType.text(),
                    width: 120,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Icon',
                    field: 'icon',
                    type: TrinaColumnType.text(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final iconName = rendererContext.cell.value?.toString() ?? '';
                      if (iconName.isEmpty) return const SizedBox();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getIconData(iconName), size: 20),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              iconName,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Order',
                    field: 'displayOrder',
                    type: TrinaColumnType.number(),
                    width: 80,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'System',
                    field: 'isSystemTemplate',
                    type: TrinaColumnType.boolean(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final templateId = rendererContext.row.cells['id']?.value as int?;
                      final isSystem = rendererContext.cell.value as bool? ?? false;
                      return Switch(
                        value: isSystem,
                        onChanged: templateId != null ? (_) => _toggleSystem(templateId) : null,
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Actions',
                    field: 'actions',
                    type: TrinaColumnType.text(),
                    width: 120,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final templateId = rendererContext.cell.value as int?;
                      if (templateId == null) return const SizedBox();
                      final template = templates.firstWhere((t) => t.id == templateId);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editTemplate(template),
                            tooltip: 'Edit',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // Delete button - ADMIN only
                          RoleGuard(
                            requiredPermission: Permission.delete,
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteTemplate(templateId),
                              tooltip: 'Delete',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
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
                  final templateId = event.row.cells['id']?.value as int?;
                  if (templateId != null) {
                    final template = templates.firstWhere((t) => t.id == templateId);
                    _editTemplate(template);
                  }
                },
                configuration: AdminGridConfig.getConfiguration(context),
                createFooter: (stateManager) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: theme.dividerColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${pagedData.number * pagedData.size + 1}-${pagedData.number * pagedData.size + templates.length} of ${pagedData.totalElements} templates',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Row(
                          children: [
                            DropdownButton<int>(
                              value: _pageSize,
                              items: const [
                                DropdownMenuItem(value: 20, child: Text('20 per page')),
                                DropdownMenuItem(value: 50, child: Text('50 per page')),
                                DropdownMenuItem(value: 100, child: Text('100 per page')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _pageSize = value;
                                    _currentPage = 0;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 16),
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
                                style: theme.textTheme.bodyMedium,
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
                  Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading templates', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(
                      sankalpTemplatesListProvider(
                        page: _currentPage,
                        size: _pageSize,
                        sankalpType: _selectedType,
                        isSystemTemplate: _selectedSystemTemplate,
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
      return Column(
        children: [
          Expanded(child: body),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton.extended(
              onPressed: _createTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sankalp Templates Management'),
        actions: [
          TextButton.icon(
            onPressed: _createTemplate,
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(
              sankalpTemplatesListProvider(
                page: _currentPage,
                size: _pageSize,
                sankalpType: _selectedType,
                isSystemTemplate: _selectedSystemTemplate,
              ),
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Time Based':
        return Colors.blue.withValues(alpha: 0.3);
      case 'Count Based':
        return Colors.green.withValues(alpha: 0.3);
      case 'Yes/No':
        return Colors.orange.withValues(alpha: 0.3);
      case 'Roopdhyan Special':
        return Colors.purple.withValues(alpha: 0.3);
      default:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }

  IconData _getIconData(String iconName) {
    // Map common icon names to IconData
    switch (iconName) {
      case 'self_improvement':
        return Icons.self_improvement;
      case 'spa':
        return Icons.spa;
      case 'favorite':
        return Icons.favorite;
      case 'psychology':
        return Icons.psychology;
      case 'emoji_objects':
        return Icons.emoji_objects;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'brightness_7':
        return Icons.brightness_7;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'nights_stay':
        return Icons.nights_stay;
      case 'timer':
        return Icons.timer;
      case 'schedule':
        return Icons.schedule;
      case 'event':
        return Icons.event;
      case 'flag':
        return Icons.flag;
      case 'star':
        return Icons.star;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'bookmark':
        return Icons.bookmark;
      case 'check_circle':
        return Icons.check_circle;
      case 'celebration':
        return Icons.celebration;
      case 'music_note':
        return Icons.music_note;
      case 'headphones':
        return Icons.headphones;
      case 'menu_book':
        return Icons.menu_book;
      case 'library_books':
        return Icons.library_books;
      case 'edit_note':
        return Icons.edit_note;
      case 'draw':
        return Icons.draw;
      default:
        return Icons.circle;
    }
  }

  void _createTemplate() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SankalpFormScreen()));
  }

  void _editTemplate(SankalpTemplate template) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SankalpFormScreen(template: template)));
  }

  Future<void> _toggleSystem(int templateId) async {
    try {
      await ref.read(sankalpTemplateActionsProvider.notifier).toggleSystemTemplate(templateId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Template status updated');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to update status: $e');
    }
  }

  Future<void> _deleteTemplate(int templateId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this sankalp template?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(sankalpTemplateActionsProvider.notifier).deleteTemplate(templateId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Template deleted');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to delete template: $e');
    }
  }
}
