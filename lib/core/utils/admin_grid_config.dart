import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

/// Centralized TrinaGrid configuration for consistent styling across the admin panel.
///
/// Provides:
/// - Row borders (Categories style) for clear row separation
/// - Alternating row colors for better readability
/// - Theme-aware colors that adapt to light/dark mode
/// - Consistent column and scrollbar configuration
class AdminGridConfig {
  AdminGridConfig._();

  /// Standard row height for data grids
  static const double rowHeight = 48.0;

  /// Standard column header height
  static const double columnHeight = 44.0;

  /// Creates a consistent TrinaGrid configuration for all list screens.
  ///
  /// Features:
  /// - Horizontal borders between rows (like Categories)
  /// - No vertical cell borders for a cleaner look
  /// - Alternating row colors for better row tracking
  /// - Theme-aware colors
  static TrinaGridConfiguration getConfiguration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TrinaGridConfiguration(
      style: TrinaGridStyleConfig(
        // Row dimensions
        rowHeight: rowHeight,
        columnHeight: columnHeight,

        // Border configuration - horizontal only (Categories style)
        enableCellBorderHorizontal: true,
        enableCellBorderVertical: false,
        gridBorderColor: colorScheme.outlineVariant,
        activatedBorderColor: colorScheme.primary,

        // Background colors
        gridBackgroundColor: colorScheme.surface,
        rowColor: colorScheme.surface,
        // Alternating row colors for better readability
        oddRowColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),

        // Text styles
        cellTextStyle: theme.textTheme.bodyMedium!,
        columnTextStyle: theme.textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      scrollbar: const TrinaGridScrollbarConfig(isAlwaysShown: false, thumbVisible: true),
      columnSize: const TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.none),
    );
  }

  /// Creates a compact configuration with smaller row heights.
  /// Useful for grids with many rows or limited vertical space.
  static TrinaGridConfiguration getCompactConfiguration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TrinaGridConfiguration(
      style: TrinaGridStyleConfig(
        // Compact row dimensions
        rowHeight: 40.0,
        columnHeight: 40.0,

        // Border configuration
        enableCellBorderHorizontal: true,
        enableCellBorderVertical: false,
        gridBorderColor: colorScheme.outlineVariant,
        activatedBorderColor: colorScheme.primary,

        // Background colors
        gridBackgroundColor: colorScheme.surface,
        rowColor: colorScheme.surface,
        oddRowColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),

        // Text styles - slightly smaller
        cellTextStyle: theme.textTheme.bodySmall!,
        columnTextStyle: theme.textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      scrollbar: const TrinaGridScrollbarConfig(isAlwaysShown: false, thumbVisible: true),
      columnSize: const TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.none),
    );
  }

  /// Creates a dense configuration with Excel-like cell borders.
  /// Useful for data-heavy screens that need clear cell boundaries.
  static TrinaGridConfiguration getDenseConfiguration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TrinaGridConfiguration(
      style: TrinaGridStyleConfig(
        // Standard row dimensions
        rowHeight: rowHeight,
        columnHeight: columnHeight,

        // Full border configuration (Excel-like)
        enableCellBorderHorizontal: true,
        enableCellBorderVertical: true,
        gridBorderColor: colorScheme.outlineVariant,
        activatedBorderColor: colorScheme.primary,

        // Background colors
        gridBackgroundColor: colorScheme.surface,
        rowColor: colorScheme.surface,
        oddRowColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),

        // Text styles
        cellTextStyle: theme.textTheme.bodyMedium!,
        columnTextStyle: theme.textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      scrollbar: const TrinaGridScrollbarConfig(isAlwaysShown: false, thumbVisible: true),
      columnSize: const TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.none),
    );
  }

  /// Builds a standard pagination footer widget.
  static Widget buildPaginationFooter({
    required BuildContext context,
    required int currentPage,
    required int pageSize,
    required int totalElements,
    required int totalPages,
    required int currentItemCount,
    required ValueChanged<int> onPageChanged,
    ValueChanged<int>? onPageSizeChanged,
    List<int> pageSizeOptions = const [20, 50, 100],
  }) {
    final theme = Theme.of(context);
    final startItem = currentPage * pageSize + 1;
    final endItem = currentPage * pageSize + currentItemCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing $startItem-$endItem of $totalElements items', style: theme.textTheme.bodyMedium),
          Row(
            children: [
              // Page size selector
              if (onPageSizeChanged != null) ...[
                DropdownButton<int>(
                  value: pageSize,
                  underline: const SizedBox(),
                  items: pageSizeOptions.map((size) {
                    return DropdownMenuItem<int>(value: size, child: Text('$size per page'));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onPageSizeChanged(value);
                  },
                ),
                const SizedBox(width: 16),
              ],
              // Pagination controls
              IconButton(
                onPressed: currentPage > 0 ? () => onPageChanged(0) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'First page',
              ),
              IconButton(
                onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Page ${currentPage + 1} of $totalPages', style: theme.textTheme.bodyMedium),
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1 ? () => onPageChanged(totalPages - 1) : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Last page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
