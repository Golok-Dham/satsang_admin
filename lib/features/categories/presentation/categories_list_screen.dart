import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:satsang_admin/core/utils/snackbar_helper.dart';
import 'package:satsang_admin/features/categories/models/category_metadata_model.dart';
import 'package:satsang_admin/features/categories/models/category_model.dart';
import 'package:satsang_admin/features/categories/providers/categories_provider.dart';
import 'package:trina_grid/trina_grid.dart';

class CategoriesListScreen extends ConsumerStatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  ConsumerState<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends ConsumerState<CategoriesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<TrinaRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  List<TrinaColumn> _buildColumns() {
    return [
      TrinaColumn(
        field: 'id',
        title: 'ID',
        frozen: TrinaColumnFrozen.start,
        type: TrinaColumnType.number(),
        width: 80,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'nameEn',
        title: 'Name (English)',
        type: TrinaColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'nameHi',
        title: 'Name (Hindi)',
        type: TrinaColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'descriptionEn',
        title: 'Description (English)',
        type: TrinaColumnType.text(),
        width: 250,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'descriptionHi',
        title: 'Description (Hindi)',
        type: TrinaColumnType.text(),
        width: 250,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'sortOrder',
        title: 'Sort Order',
        type: TrinaColumnType.number(),
        width: 120,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'parentId',
        title: 'Parent ID',
        type: TrinaColumnType.text(),
        width: 100,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'createdAt',
        title: 'Created',
        type: TrinaColumnType.text(),
        width: 160,
        enableEditingMode: false,
      ),
      TrinaColumn(
        field: 'isActive',
        title: 'Active',
        type: TrinaColumnType.boolean(),
        width: 100,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final categoryId = rendererContext.row.cells['id']?.value as int?;
          final isActive = rendererContext.cell.value as bool? ?? false;
          return Switch(
            value: isActive,
            onChanged: categoryId != null ? (_) => _toggleCategoryStatus(categoryId) : null,
          );
        },
      ),
      TrinaColumn(
        field: 'actions',
        title: 'Actions',
        frozen: TrinaColumnFrozen.end,
        type: TrinaColumnType.text(),
        width: 120,
        enableEditingMode: false,
        renderer: (rendererContext) => _buildActionsCell(rendererContext),
      ),
    ];
  }

  Widget _buildActionsCell(TrinaColumnRendererContext rendererContext) {
    final categoryId = rendererContext.cell.value as int?;
    if (categoryId == null) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _openCategoryDialog(categoryId: categoryId),
          tooltip: 'Edit',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => _deleteCategory(categoryId),
          tooltip: 'Delete',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  TrinaRow _categoryToRow(CategoryItem category) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: category.id),
        'nameEn': TrinaCell(value: category.nameEn.isEmpty ? '-' : category.nameEn),
        'nameHi': TrinaCell(value: category.nameHi.isEmpty ? '-' : category.nameHi),
        'descriptionEn': TrinaCell(value: category.descriptionEn?.isEmpty ?? true ? '-' : category.descriptionEn),
        'descriptionHi': TrinaCell(value: category.descriptionHi?.isEmpty ?? true ? '-' : category.descriptionHi),
        'sortOrder': TrinaCell(value: category.sortOrder),
        'isActive': TrinaCell(value: category.isActive),
        'parentId': TrinaCell(value: category.parentId?.toString() ?? '-'),
        'createdAt': TrinaCell(value: _formatDateTime(category.createdAt)),
        'actions': TrinaCell(value: category.id),
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  Future<void> _loadCategories() async {
    try {
      final result = await ref.read(
        categoriesProvider(
          page: 0,
          size: 1000, // Load all categories
          search: _searchQuery.isEmpty ? null : _searchQuery,
        ).future,
      );

      final categoriesList = result['content'] as List;
      final categories = categoriesList.cast<CategoryItem>();

      setState(() {
        _rows = categories.map(_categoryToRow).toList();
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to load categories: ${e.toString()}');
      }
    }
  }

  Future<void> _toggleCategoryStatus(int categoryId) async {
    try {
      final repository = ref.read(categoryRepositoryProvider);
      final category = await repository.getCategoryById(categoryId);
      await repository.toggleActive(categoryId, !category.isActive);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, category.isActive ? 'Category deactivated' : 'Category activated');

      // Refresh the list
      ref.invalidate(categoriesProvider);
      await _loadCategories();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to toggle status: ${e.toString()}');
    }
  }

  Future<void> _deleteCategory(int categoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(categoryRepositoryProvider);
      await repository.deleteCategory(categoryId);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Category deleted');

      // Refresh the list
      ref.invalidate(categoriesProvider);
      await _loadCategories();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Failed to delete category: ${e.toString()}');
    }
  }

  Future<void> _openCategoryDialog({int? categoryId}) async {
    final repository = ref.read(categoryRepositoryProvider);
    CategoryItem? category;

    if (categoryId != null) {
      try {
        category = await repository.getCategoryById(categoryId);
      } catch (e) {
        if (!mounted) return;
        SnackBarHelper.showError(context, 'Failed to load category: ${e.toString()}');
        return;
      }
    }

    if (!mounted) return;

    final formResult = await _showCategoryDialogForm(category: category);
    if (formResult == null || !mounted) {
      return;
    }

    try {
      if (category == null) {
        final newCategory = CategoryItem(
          id: 0,
          nameEn: formResult.nameEn,
          nameHi: formResult.nameHi,
          descriptionEn: formResult.descriptionEn,
          descriptionHi: formResult.descriptionHi,
          sortOrder: formResult.sortOrder,
          isActive: formResult.isActive,
          parentId: formResult.parentId,
          categoryMetadata: formResult.metadataJson,
          createdAt: null,
        );

        await repository.createCategory(newCategory);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Category created successfully');
      } else {
        final updatedCategory = category.copyWith(
          nameEn: formResult.nameEn,
          nameHi: formResult.nameHi,
          descriptionEn: formResult.descriptionEn,
          descriptionHi: formResult.descriptionHi,
          sortOrder: formResult.sortOrder,
          parentId: formResult.parentId,
          isActive: formResult.isActive,
          categoryMetadata: formResult.metadataJson,
        );

        await repository.updateCategory(category.id, updatedCategory);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Category updated successfully');
      }

      ref.invalidate(categoriesProvider);
      await _loadCategories();
    } catch (e) {
      if (!mounted) return;
      final action = category == null ? 'create' : 'update';
      SnackBarHelper.showError(context, 'Failed to $action category: ${e.toString()}');
    }
  }

  Future<_CategoryDialogResult?> _showCategoryDialogForm({CategoryItem? category}) async {
    final baseMetadata = category?.metadata ?? CategoryMetadata.empty();
    final editingId = category?.id;

    final nameEnController = TextEditingController(text: category?.nameEn ?? '');
    final nameHiController = TextEditingController(text: category?.nameHi ?? '');
    final descriptionEnController = TextEditingController(text: category?.descriptionEn ?? '');
    final descriptionHiController = TextEditingController(text: category?.descriptionHi ?? '');
    final sortOrderController = TextEditingController(text: (category?.sortOrder ?? 0).toString());
    final pillBackgroundController = TextEditingController(text: baseMetadata.pillBackgroundHex ?? '');
    final pillTextController = TextEditingController(text: baseMetadata.pillTextHex ?? '');
    final iconNameController = TextEditingController(text: baseMetadata.iconName ?? '');
    final bannerImageController = TextEditingController(text: baseMetadata.bannerImageUrl ?? '');
    final thumbnailImageController = TextEditingController(text: baseMetadata.thumbnailImageUrl ?? '');
    final taglineEnController = TextEditingController(text: baseMetadata.taglineEn ?? '');
    final taglineHiController = TextEditingController(text: baseMetadata.taglineHi ?? '');

    final controllers = <TextEditingController>[
      nameEnController,
      nameHiController,
      descriptionEnController,
      descriptionHiController,
      sortOrderController,
      pillBackgroundController,
      pillTextController,
      iconNameController,
      bannerImageController,
      thumbnailImageController,
      taglineEnController,
      taglineHiController,
    ];

    final formKey = GlobalKey<FormState>();
    int? selectedParentId = category?.parentId;
    bool isActive = category?.isActive ?? true;

    final result = await showDialog<_CategoryDialogResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text(editingId == null ? 'Create Category' : 'Edit Category #$editingId'),
            content: SizedBox(
              width: 640,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('English', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameEnController,
                        decoration: const InputDecoration(labelText: 'Name (English)', border: OutlineInputBorder()),
                        autofocus: true,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionEnController,
                        decoration: const InputDecoration(
                          labelText: 'Description (English)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Text('Hindi', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameHiController,
                        decoration: const InputDecoration(labelText: 'Name (Hindi)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionHiController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Hindi)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Text('Other Settings', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: sortOrderController,
                        decoration: const InputDecoration(labelText: 'Sort Order', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Sort order is required';
                          }
                          return int.tryParse(value.trim()) == null ? 'Enter a valid number' : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedParentId,
                        decoration: const InputDecoration(labelText: 'Parent Category', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('None (Top Level)')),
                          ..._rows
                              .where((row) => row.cells['id']?.value != editingId)
                              .map(
                                (row) => DropdownMenuItem<int?>(
                                  value: row.cells['id']?.value as int?,
                                  child: Text(
                                    '${row.cells['nameEn']?.value ?? row.cells['nameHi']?.value ?? 'Unknown'}',
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedParentId = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        value: isActive,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        subtitle: const Text('Inactive categories stay hidden in the app'),
                        onChanged: (value) => setState(() => isActive = value),
                      ),
                      const SizedBox(height: 24),
                      Text('Metadata', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: pillBackgroundController,
                        decoration: const InputDecoration(
                          labelText: 'Pill Background Color (#RRGGBB)',
                          helperText: 'Leave blank to use theme default',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateOptionalHex,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pillTextController,
                        decoration: const InputDecoration(
                          labelText: 'Pill Text Color (#RRGGBB)',
                          helperText: 'Optional override for text contrast',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateOptionalHex,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: iconNameController,
                        decoration: const InputDecoration(
                          labelText: 'Icon Name',
                          helperText: 'Material icon name, e.g. category, temple_buddhist',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bannerImageController,
                        decoration: const InputDecoration(labelText: 'Banner Image URL', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: thumbnailImageController,
                        decoration: const InputDecoration(
                          labelText: 'Thumbnail Image URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: taglineEnController,
                        decoration: const InputDecoration(labelText: 'Tagline (English)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: taglineHiController,
                        decoration: const InputDecoration(labelText: 'Tagline (Hindi)', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) {
                    return;
                  }

                  final metadata = CategoryMetadata(
                    pillBackgroundHex: _sanitizeHexInput(pillBackgroundController.text),
                    pillTextHex: _sanitizeHexInput(pillTextController.text),
                    iconName: iconNameController.text.trim().isEmpty ? null : iconNameController.text.trim(),
                    bannerImageUrl: bannerImageController.text.trim().isEmpty
                        ? null
                        : bannerImageController.text.trim(),
                    thumbnailImageUrl: thumbnailImageController.text.trim().isEmpty
                        ? null
                        : thumbnailImageController.text.trim(),
                    taglineEn: taglineEnController.text.trim().isEmpty ? null : taglineEnController.text.trim(),
                    taglineHi: taglineHiController.text.trim().isEmpty ? null : taglineHiController.text.trim(),
                    additionalFields: baseMetadata.additionalFields,
                  );

                  Navigator.pop(
                    context,
                    _CategoryDialogResult(
                      nameEn: nameEnController.text.trim(),
                      nameHi: nameHiController.text.trim(),
                      descriptionEn: descriptionEnController.text.trim().isEmpty
                          ? null
                          : descriptionEnController.text.trim(),
                      descriptionHi: descriptionHiController.text.trim().isEmpty
                          ? null
                          : descriptionHiController.text.trim(),
                      sortOrder: int.parse(sortOrderController.text.trim()),
                      parentId: selectedParentId,
                      isActive: isActive,
                      metadata: metadata,
                    ),
                  );
                },
                child: Text(category == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    for (final controller in controllers) {
      controller.dispose();
    }

    return result;
  }

  String? _validateOptionalHex(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final candidate = value.trim();
    return CategoryMetadata.isValidHex(candidate) ? null : 'Use a hex value such as #FFAABB';
  }

  String? _sanitizeHexInput(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    return normalized.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(categoriesProvider);
              _loadCategories();
            },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search categories',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _loadCategories();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _openCategoryDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Category'),
                ),
              ],
            ),
          ),

          // TrinaGrid
          Expanded(
            child: TrinaGrid(
              key: ValueKey('categories_grid_${_rows.length}_${_searchQuery.hashCode}'),
              columns: _buildColumns(),
              rows: _rows,
            ),
          ),

          // Pagination footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Text('Total: ${_rows.length} categories', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _CategoryDialogResult {
  _CategoryDialogResult({
    required this.nameEn,
    required this.nameHi,
    required this.descriptionEn,
    required this.descriptionHi,
    required this.sortOrder,
    required this.parentId,
    required this.isActive,
    required this.metadata,
  });

  final String nameEn;
  final String nameHi;
  final String? descriptionEn;
  final String? descriptionHi;
  final int sortOrder;
  final int? parentId;
  final bool isActive;
  final CategoryMetadata metadata;

  String? get metadataJson => metadata.isEmpty ? null : metadata.toJsonString();
}
