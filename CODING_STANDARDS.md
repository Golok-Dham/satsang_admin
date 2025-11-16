# Satsang Admin - Flutter Coding Standards

> **Project**: Satsang Admin Panel (Flutter Web)  
> **Purpose**: Administrative dashboard for Satsang OTT Platform  
> **Last Updated**: November 10, 2025

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [State Management](#state-management)
- [UI Components](#ui-components)
- [Data Grid Standards](#data-grid-standards)
- [Naming Conventions](#naming-conventions)
- [Code Organization](#code-organization)
- [API Integration](#api-integration)
- [Error Handling](#error-handling)
- [Performance Guidelines](#performance-guidelines)

---

## 🏗️ Architecture Overview

### Feature-First Architecture

```
lib/
├── app/                    # App-level configurations
│   ├── router.dart        # GoRouter configuration
│   └── theme.dart         # Theme configuration
├── core/                   # Shared utilities
│   ├── models/            # Shared models
│   ├── providers/         # Shared providers (auth, API)
│   ├── services/          # API service, auth service
│   └── utils/             # Helper utilities (SnackBarHelper)
└── features/              # Feature modules
    ├── authentication/    # Login, auth
    ├── content/          # Content management
    ├── quotes/           # Quotes management
    ├── users/            # User management
    └── dashboard/        # Dashboard home
```

### Key Architectural Decisions

1. **Feature-First Organization**: Each feature is self-contained with its own models, providers, and presentation layers
2. **Clean Separation**: Business logic in providers, UI in presentation layer
3. **Shared Core**: Common utilities and services in `core/` directory
4. **Minimal Dependencies**: Features should not depend on each other directly

---

## 🔄 State Management

### Riverpod 3.0 with Code Generation

**Always use `@riverpod` annotation** with code generation instead of manual providers.

#### ✅ Correct Pattern

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.g.dart';

@riverpod
class UsersList extends _$UsersList {
  @override
  Future<PaginatedUsers> build() async {
    return _fetchUsers();
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }
}
```

#### ❌ Incorrect Pattern

```dart
// DON'T use manual providers
final usersProvider = StateNotifierProvider<UsersNotifier, AsyncValue<List<User>>>((ref) {
  return UsersNotifier();
});
```

### Provider Patterns

- **Data Fetching**: Use `@riverpod` with `Future<T>` return type
- **Actions**: Create separate action providers (e.g., `UserActions`)
- **Invalidation**: Use `ref.invalidate()` to trigger refreshes
- **Lifecycle**: Use `ref.onDispose()` for cleanup

### Widget Patterns

```dart
// ✅ Use ConsumerWidget for stateless reactive widgets
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(myDataProvider);
    return dataAsync.when(...);
  }
}

// ✅ Use ConsumerStatefulWidget for stateful reactive widgets
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}
```

---

## 🎨 UI Components

### Material Design 3

- **Always use theme colors**: `Theme.of(context).colorScheme.primary`
- **Never hardcode colors**: Avoid `Colors.blue` or `Color(0xFF123456)`
- **Use `withValues(alpha:)`**: NOT deprecated `withOpacity()`

```dart
// ✅ Correct
color: theme.colorScheme.primary.withValues(alpha: 0.5)

// ❌ Wrong
color: Colors.blue.withOpacity(0.5)
```

### User Feedback - SnackBarHelper

**Always use `SnackBarHelper`** for user notifications, never direct `ScaffoldMessenger`.

```dart
// ✅ Correct
SnackBarHelper.showSuccess(context, 'Operation completed');
SnackBarHelper.showError(context, 'Failed: ${e.toString()}');
SnackBarHelper.showInfo(context, 'Loading...');
SnackBarHelper.showWarning(context, 'Please review');

// ❌ Wrong
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi')));
```

### Context Safety

Always check `context.mounted` after async operations:

```dart
// ✅ Correct
await someAsyncOperation();
if (!context.mounted) return;
Navigator.pop(context);

// ❌ Wrong - Context might be unmounted
await someAsyncOperation();
Navigator.pop(context); // ❌ Unsafe
```

---

## 📊 Data Grid Standards

### When to Use TrinaGrid vs DataTable

| Scenario | Use | Reason |
|----------|-----|--------|
| **List screens** (Users, Quotes, Content) | **TrinaGrid** | Server-side pagination, sorting, filtering, export, consistent UX |
| **Embedded editors** (Karaoke Visual Editor) | **DataTable** | Small dataset, inline editing, custom interactions, simpler |

### TrinaGrid - Standard Pattern

Use TrinaGrid for **all list/management screens** with server-side data.

#### Required Setup

```dart
import 'package:trina_grid/trina_grid.dart';

class MyListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends ConsumerState<MyListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  TrinaGridStateManager? _stateManager;
  List<TrinaRow> _rows = [];
  
  @override
  void dispose() {
    _searchController.dispose();
    _stateManager?.dispose();  // ✅ Always dispose StateManager
    super.dispose();
  }
  
  // Convert model to TrinaRow
  TrinaRow _itemToRow(MyItem item) {
    return TrinaRow(
      cells: {
        'id': TrinaCell(value: item.id),
        'name': TrinaCell(value: item.name),
        'status': TrinaCell(value: item.status.name),
        'createdAt': TrinaCell(value: _formatDateTime(item.createdAt)),  // ✅ Store as string
        'actions': TrinaCell(value: item.id),
      },
    );
  }
}
```

#### Column Patterns

```dart
TrinaColumn(
  title: 'ID',
  field: 'id',
  type: TrinaColumnType.number(),
  width: 80,
  frozen: TrinaColumnFrozen.start,  // ✅ Freeze ID column
  enableEditingMode: false,
),
TrinaColumn(
  title: 'Status',
  field: 'status',
  type: TrinaColumnType.text(),
  width: 120,
  enableEditingMode: false,
  renderer: (rendererContext) => _buildStatusChip(status),  // ✅ Custom renderer for chips
),
TrinaColumn(
  title: 'Actions',
  field: 'actions',
  type: TrinaColumnType.text(),
  width: 100,
  frozen: TrinaColumnFrozen.end,  // ✅ Freeze actions column
  enableEditingMode: false,
  renderer: (rendererContext) {
    final id = rendererContext.cell.value as int;
    final item = items.firstWhere((i) => i.id == id);
    return _buildActionsMenu(item);
  },
),
```

#### Date Handling in TrinaGrid

**Always store dates as formatted strings**, not DateTime objects:

```dart
// ✅ Correct - Store formatted string
TrinaRow(
  cells: {
    'createdAt': TrinaCell(value: _formatDateTime(item.createdAt)),
  },
);

TrinaColumn(
  title: 'Created',
  field: 'createdAt',
  type: TrinaColumnType.text(),  // ✅ Use text type
  width: 160,
  enableEditingMode: false,
  // No renderer needed - displays string directly
),

// Helper method
String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
}

// ❌ Wrong - Don't store DateTime objects
TrinaCell(value: item.createdAt)  // ❌ Will cause errors
```

#### Pagination Footer

**Standard pagination pattern** with page size selector:

```dart
createFooter: (stateManager) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: theme.dividerColor)),
    ),
    child: Row(
      children: [
        Text('Showing X-Y of Z items'),
        const Spacer(),
        DropdownButton<int>(
          value: paginatedData.size,
          items: const [
            DropdownMenuItem(value: 20, child: Text('20 per page')),
            DropdownMenuItem(value: 50, child: Text('50 per page')),
            DropdownMenuItem(value: 100, child: Text('100 per page')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(myListProvider.notifier).changePageSize(value);
            }
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: paginatedData.first ? null : () => loadPrevPage(),
        ),
        Text('Page ${paginatedData.number + 1} of ${paginatedData.totalPages}'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: paginatedData.last ? null : () => loadNextPage(),
        ),
      ],
    ),
  );
},
```

#### TrinaGrid Configuration

```dart
configuration: TrinaGridConfiguration(
  style: TrinaGridStyleConfig(
    gridBorderColor: theme.dividerColor,
    activatedBorderColor: theme.colorScheme.primary,
    gridBackgroundColor: theme.colorScheme.surface,
    rowColor: theme.colorScheme.surface,
    oddRowColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),  // ✅ Alternating rows
    cellTextStyle: theme.textTheme.bodyMedium!,
    columnTextStyle: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
  ),
),
```

### DataTable - When to Use

Use DataTable for **embedded editors** with small datasets and complex inline editing:

#### Use Cases

- ✅ Karaoke Visual Editor (Tab 4 in lyrics screen)
- ✅ Small form-like tables with inline editing
- ✅ Master-detail editing interfaces
- ❌ **NOT** for list screens with pagination
- ❌ **NOT** for server-side data

#### DataTable Pattern

```dart
// ✅ Good use case: Karaoke editor with click-to-edit cells
DataTable(
  columnSpacing: 16,
  headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest),
  columns: const [
    DataColumn(label: Text('#')),
    DataColumn(label: Text('Start (s)')),
    DataColumn(label: Text('Hindi')),
    DataColumn(label: Text('Actions')),
  ],
  rows: items.map((item) {
    return DataRow(
      cells: [
        DataCell(Text('${item.index}')),
        DataCell(
          InkWell(
            onTap: () => _editStartTime(item),  // ✅ Inline editing
            child: Text(item.startTime.toStringAsFixed(2)),
          ),
        ),
        // ... more editable cells
      ],
    );
  }).toList(),
)
```

### Summary: Grid Decision Tree

```
Do you need server-side pagination?
├── YES → Use TrinaGrid
│   └── Examples: Users, Quotes, Content, Playlists
└── NO → Is it a list of 100+ items?
    ├── YES → Use TrinaGrid with client-side filtering
    └── NO → Does it need complex inline editing?
        ├── YES → Use DataTable
        │   └── Example: Karaoke Visual Editor
        └── NO → Use TrinaGrid for consistency
```

---

## 📝 Naming Conventions

### Files

- **snake_case**: `user_list_screen.dart`, `auth_provider.dart`
- **Screens**: `*_screen.dart` (e.g., `quotes_list_screen.dart`)
- **Widgets**: `*_widget.dart` or descriptive (e.g., `favorite_button.dart`)
- **Providers**: `*_provider.dart` (e.g., `users_provider.dart`)
- **Models**: `*_model.dart` (e.g., `user_model.dart`)
- **Services**: `*_service.dart` (e.g., `api_service.dart`)

### Classes & Variables

```dart
// Classes: PascalCase
class UserListScreen {}
class ApiService {}

// Variables/Parameters: camelCase
final userName = 'John';
void fetchData(int userId) {}

// Constants: camelCase or SCREAMING_SNAKE_CASE
const maxRetries = 3;
const API_BASE_URL = 'https://api.example.com';

// Private: prefix with underscore
final _privateField = '';
void _privateMethod() {}
```

---

## 📁 Code Organization

### Feature Structure

```
features/users/
├── models/
│   └── user_model.dart          # Data models
├── providers/
│   ├── user_provider.dart       # State management
│   └── user_provider.g.dart     # Generated code
└── presentation/
    └── users_list_screen.dart   # UI layer
```

### Import Order

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter packages
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:intl/intl.dart';

// 4. Project imports (relative)
import '../../../core/utils/snackbar_helper.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
```

---

## 🌐 API Integration

### Dio Service Pattern

```dart
// ✅ Always use apiServiceProvider
final dio = ref.read(apiServiceProvider).dio;

final response = await dio.get<Map<String, dynamic>>(
  '/api/admin/users',
  queryParameters: {'page': 0, 'size': 20},
);

if (response.data != null && response.data!['success'] == true) {
  return MyModel.fromJson(response.data!['data']);
}
```

### API Response Structure

Expected backend response format:

```json
{
  "success": true,
  "data": {
    "content": [...],
    "totalElements": 100,
    "totalPages": 5,
    "number": 0,
    "size": 20,
    "first": true,
    "last": false
  }
}
```

---

## 🚨 Error Handling

### Provider Error Handling

```dart
// ✅ Use AsyncValue.guard
state = await AsyncValue.guard(() async {
  final data = await fetchData();
  return data;
});

// UI handles errors automatically
dataAsync.when(
  data: (data) => SuccessWidget(data),
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(error),
);
```

### User-Facing Errors

```dart
try {
  await someOperation();
  if (!mounted) return;
  SnackBarHelper.showSuccess(context, 'Success!');
} catch (e) {
  if (!mounted) return;
  SnackBarHelper.showError(context, 'Failed: ${e.toString()}');
}
```

---

## ⚡ Performance Guidelines

### Memory Leak Prevention

```dart
class _MyWidgetState extends State<MyWidget> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _timer;
  
  @override
  void dispose() {
    _controller.dispose();          // ✅ Always dispose controllers
    _scrollController.dispose();    // ✅ Always dispose controllers
    _timer?.cancel();               // ✅ Cancel timers
    super.dispose();
  }
}

// ✅ Riverpod cleanup
@Riverpod(keepAlive: true)
MyService myService(Ref ref) {
  final service = MyService();
  ref.onDispose(() => service.dispose());  // ✅ Cleanup
  return service;
}
```

### StreamController Cleanup

```dart
class MyService {
  final _controller = StreamController<Event>.broadcast();
  
  Stream<Event> get eventStream => _controller.stream;
  
  void dispose() {
    _controller.close();  // ✅ MUST close to prevent leak
  }
}
```

### Use `const` Constructors

```dart
// ✅ Use const whenever possible
const SizedBox(height: 16)
const Text('Hello')
const EdgeInsets.all(16)

// ❌ Avoid unnecessary rebuilds
SizedBox(height: 16)  // Missing const
```

---

## 🧪 Code Quality Checklist

Before committing code, verify:

- [ ] `flutter analyze` shows **0 issues**
- [ ] All providers use `@riverpod` annotation
- [ ] All `SnackBar` calls use `SnackBarHelper`
- [ ] All theme colors use `Theme.of(context).colorScheme`
- [ ] All async operations check `context.mounted`
- [ ] All controllers/timers are disposed
- [ ] TrinaGrid used for list screens with pagination
- [ ] DataTable only used for inline editors
- [ ] Dates formatted as strings in TrinaGrid cells
- [ ] Page size selector added to all TrinaGrid footers
- [ ] All files follow naming conventions
- [ ] Imports ordered correctly
- [ ] No hardcoded colors
- [ ] `const` constructors used where possible

---

## 🎯 Quick Reference

### Common Patterns

```dart
// Provider with pagination
@riverpod
class ItemsList extends _$ItemsList {
  int _currentPage = 0;
  int _pageSize = 20;
  
  @override
  Future<PaginatedItems> build() => _fetchItems();
  
  Future<void> loadPage(int page) async {
    _currentPage = page;
    state = await AsyncValue.guard(() => _fetchItems());
  }
  
  Future<void> changePageSize(int size) async {
    _pageSize = size;
    _currentPage = 0;
    state = await AsyncValue.guard(() => _fetchItems());
  }
}

// TrinaRow conversion
TrinaRow _itemToRow(MyItem item) {
  return TrinaRow(
    cells: {
      'id': TrinaCell(value: item.id),
      'name': TrinaCell(value: item.name),
      'date': TrinaCell(value: _formatDateTime(item.date)),  // ✅ String
      'actions': TrinaCell(value: item.id),
    },
  );
}

// Date formatting
String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
}
```

---

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Material Design 3](https://m3.material.io/)
- [TrinaGrid Package](https://pub.dev/packages/trina_grid)

---

**Remember**: Consistency is key. When in doubt, follow existing patterns in the codebase.
