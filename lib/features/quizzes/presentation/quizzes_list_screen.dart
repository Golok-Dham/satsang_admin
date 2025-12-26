import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/utils/admin_grid_config.dart';
import '../../../core/utils/role_guard.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../models/quiz_model.dart';
import '../providers/quizzes_provider.dart';
import 'quiz_form_screen.dart';

class QuizzesListScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const QuizzesListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<QuizzesListScreen> createState() => _QuizzesListScreenState();
}

class _QuizzesListScreenState extends ConsumerState<QuizzesListScreen> {
  bool? _selectedActive;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _pageSize = 20;
  TrinaGridStateManager? _stateManager;
  List<TrinaRow> _rows = [];

  @override
  void dispose() {
    _searchController.dispose();
    _stateManager?.dispose();
    super.dispose();
  }

  /// Convert QuizListItem to TrinaRow
  TrinaRow _quizToRow(QuizListItem quiz) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: quiz.id),
        'contentId': TrinaCell(value: quiz.contentId),
        'contentTitle': TrinaCell(value: quiz.contentTitle ?? 'Content #${quiz.contentId}'),
        'titleEn': TrinaCell(value: quiz.titleEn ?? '-'),
        'titleHi': TrinaCell(value: quiz.titleHi ?? '-'),
        'questionCount': TrinaCell(value: quiz.questionCount),
        'version': TrinaCell(value: quiz.version),
        'isActive': TrinaCell(value: quiz.isActive),
        'createdAt': TrinaCell(value: _formatDateTime(quiz.createdAt)),
        'actions': TrinaCell(value: quiz.id),
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizzesAsync = ref.watch(
      quizzesListProvider(
        page: _currentPage,
        size: _pageSize,
        isActive: _selectedActive,
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
                    labelText: 'Search quizzes',
                    hintText: 'Search by title...',
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
                // Active status filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _selectedActive,
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: true, child: Text('Active')),
                          DropdownMenuItem(value: false, child: Text('Inactive')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedActive = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const Expanded(flex: 2, child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Quizzes list with TrinaGrid
        Expanded(
          child: quizzesAsync.when(
            data: (pagedData) {
              final quizzes = pagedData.content;
              if (quizzes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No quizzes found', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first quiz using the + button',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Convert quizzes to rows
              _rows = quizzes.map(_quizToRow).toList();

              return TrinaGrid(
                columns: [
                  TrinaColumn(
                    title: 'ID',
                    field: 'id',
                    type: TrinaColumnType.number(),
                    width: 70,
                    frozen: TrinaColumnFrozen.start,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Content ID',
                    field: 'contentId',
                    type: TrinaColumnType.number(),
                    width: 90,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Content Title',
                    field: 'contentTitle',
                    type: TrinaColumnType.text(),
                    width: 250,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Quiz Title (EN)',
                    field: 'titleEn',
                    type: TrinaColumnType.text(),
                    width: 180,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Quiz Title (HI)',
                    field: 'titleHi',
                    type: TrinaColumnType.text(),
                    width: 180,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Questions',
                    field: 'questionCount',
                    type: TrinaColumnType.number(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final count = rendererContext.cell.value as int? ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                        ),
                      );
                    },
                  ),
                  TrinaColumn(
                    title: 'Version',
                    field: 'version',
                    type: TrinaColumnType.number(),
                    width: 80,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Active',
                    field: 'isActive',
                    type: TrinaColumnType.boolean(),
                    width: 100,
                    enableEditingMode: false,
                    renderer: (rendererContext) {
                      final quizId = rendererContext.row.cells['id']?.value as int?;
                      final isActive = rendererContext.cell.value as bool? ?? false;
                      return Switch(value: isActive, onChanged: quizId != null ? (_) => _toggleActive(quizId) : null);
                    },
                  ),
                  TrinaColumn(
                    title: 'Created',
                    field: 'createdAt',
                    type: TrinaColumnType.text(),
                    width: 160,
                    enableEditingMode: false,
                  ),
                  TrinaColumn(
                    title: 'Actions',
                    field: 'actions',
                    type: TrinaColumnType.text(),
                    width: 120,
                    enableEditingMode: false,
                    frozen: TrinaColumnFrozen.end,
                    renderer: (rendererContext) {
                      final quizId = rendererContext.cell.value as int?;
                      if (quizId == null) return const SizedBox();
                      final quiz = quizzes.firstWhere((q) => q.id == quizId);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editQuiz(quiz),
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
                              onPressed: () => _deleteQuiz(quizId),
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
                  final quizId = event.row.cells['id']?.value as int?;
                  if (quizId != null) {
                    final quiz = quizzes.firstWhere((q) => q.id == quizId);
                    _editQuiz(quiz);
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
                          'Showing ${pagedData.number * pagedData.size + 1}-${pagedData.number * pagedData.size + quizzes.length} of ${pagedData.totalElements} quizzes',
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
                  Text('Error loading quizzes', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(
                      quizzesListProvider(page: _currentPage, size: _pageSize, isActive: _selectedActive),
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
              onPressed: _createQuiz,
              icon: const Icon(Icons.add),
              label: const Text('Create Quiz'),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Management'),
        actions: [
          TextButton.icon(onPressed: _createQuiz, icon: const Icon(Icons.add), label: const Text('Create Quiz')),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.refresh(quizzesListProvider(page: _currentPage, size: _pageSize, isActive: _selectedActive)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
    );
  }

  void _createQuiz() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuizFormScreen()));
  }

  void _editQuiz(QuizListItem quiz) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizFormScreen(quizId: quiz.id)));
  }

  Future<void> _toggleActive(int quizId) async {
    try {
      await ref.read(quizActionsProvider.notifier).toggleActive(quizId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Quiz status updated');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to update status: $e');
    }
  }

  Future<void> _deleteQuiz(int quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text(
          'Are you sure you want to delete this quiz? This will also delete all associated questions and user responses.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(quizActionsProvider.notifier).deleteQuiz(quizId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Quiz deleted');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to delete quiz: $e');
    }
  }
}
