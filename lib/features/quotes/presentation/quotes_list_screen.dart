import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/api_models.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/quotes_provider.dart';
import 'quote_form_screen.dart';

class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  String? _selectedCategory;
  bool? _selectedActiveStatus;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quotesAsync = ref.watch(quotesListProvider(
      page: _currentPage,
      size: _pageSize,
      category: _selectedCategory,
      isActive: _selectedActiveStatus,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Divine Quotes Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(quotesListProvider(
              page: _currentPage,
              size: _pageSize,
              category: _selectedCategory,
              isActive: _selectedActiveStatus,
            )),
            tooltip: 'Refresh',
          ),
        ],
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
                  // Category filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: 'BHAKTI', child: Text('Bhakti')),
                        DropdownMenuItem(value: 'GYAAN', child: Text('Gyaan')),
                        DropdownMenuItem(value: 'VAIRAGYA', child: Text('Vairagya')),
                        DropdownMenuItem(value: 'KARMA', child: Text('Karma')),
                        DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Active status filter
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      value: _selectedActiveStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: true, child: Text('Active')),
                        DropdownMenuItem(value: false, child: Text('Inactive')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedActiveStatus = value;
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Quotes list
          Expanded(
            child: quotesAsync.when(
              data: (quotes) => quotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quotes found',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first quote using the + button',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Text (English)')),
                            DataColumn(label: Text('Source')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Priority')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: quotes.map((quote) {
                            return DataRow(
                              cells: [
                                DataCell(Text(quote.id.toString())),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 300),
                                    child: Text(
                                      quote.textEnglishMeaning,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                DataCell(Text(quote.sourceBook ?? 'N/A')),
                                DataCell(Chip(
                                  label: Text(quote.category.toString().split('.').last),
                                  backgroundColor: _getCategoryColor(quote.category),
                                )),
                                DataCell(
                                  Switch(
                                    value: quote.isActive,
                                    onChanged: (_) => _toggleActive(quote.id),
                                  ),
                                ),
                                DataCell(Text(quote.displayPriority.toString())),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editQuote(quote),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteQuote(quote.id),
                                        tooltip: 'Delete',
                                        color: theme.colorScheme.error,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading quotes',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(quotesListProvider(
                        page: _currentPage,
                        size: _pageSize,
                        category: _selectedCategory,
                        isActive: _selectedActiveStatus,
                      )),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Pagination controls
          if (quotesAsync.hasValue && quotesAsync.value!.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'Page ${_currentPage + 1}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: quotesAsync.value!.length == _pageSize
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQuote,
        icon: const Icon(Icons.add),
        label: const Text('Create Quote'),
      ),
    );
  }

  Color _getCategoryColor(QuoteCategory category) {
    switch (category) {
      case QuoteCategory.BHAKTI:
        return Colors.pink.withValues(alpha: 0.3);
      case QuoteCategory.GYAAN:
        return Colors.blue.withValues(alpha: 0.3);
      case QuoteCategory.VAIRAGYA:
        return Colors.orange.withValues(alpha: 0.3);
      case QuoteCategory.KARMA:
        return Colors.green.withValues(alpha: 0.3);
      case QuoteCategory.GENERAL:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }

  void _createQuote() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QuoteFormScreen(),
      ),
    );
  }

  void _editQuote(DivineQuote quote) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuoteFormScreen(quote: quote),
      ),
    );
  }

  Future<void> _toggleActive(int quoteId) async {
    try {
      await ref.read(quoteActionsProvider.notifier).toggleActive(quoteId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Quote status updated');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to update status: $e');
    }
  }

  Future<void> _deleteQuote(int quoteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: const Text('Are you sure you want to delete this quote?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(quoteActionsProvider.notifier).deleteQuote(quoteId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Quote deleted');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to delete quote: $e');
    }
  }
}
