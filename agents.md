# AI Agent Instructions for Satsang Admin Panel

> **Note**: This file provides guidance for all AI coding assistants (GitHub Copilot, Cursor, Windsurf, Cody, Claude, ChatGPT, etc.) working on this Flutter web admin panel.

## 🎯 Project Context

This is the **Satsang Admin Panel** - a web-based administrative interface for managing the Satsang OTT platform, including content management, user administration, quotes, playlists, and analytics.

## 📚 Primary References

### Architecture Overview

This admin panel follows Flutter web best practices with:
- **Flutter Web**: Latest Flutter 3.24+ targeting web platform
- **State Management**: Riverpod 3.0 with `@riverpod` code generation
- **UI Framework**: Material Design 3 with responsive layouts
- **Data Grids**: TrinaGrid for list views, DataTable for inline editors
- **Backend Integration**: Spring Boot API with JWT authentication
- **Theme**: FlexColorScheme v8.3.0 for Material 3 theming

## 🔧 Key Technologies

- **Flutter**: 3.24+ with Material Design 3
- **State Management**: Riverpod 3.0.0-dev.17 (with `@riverpod` code generation)
- **Data Grid**: trina_grid ^2.1.0 for list screens
- **Theme**: FlexColorScheme v8.3.0
- **Routing**: GoRouter v16.2+
- **HTTP Client**: Dio with interceptors for API calls
- **Backend**: Spring Boot 3.5.5 + JWT authentication

## 📋 Code Generation Requirements

When suggesting code changes involving:
- **Providers**: Always use `@riverpod` annotation (not manual StateNotifierProvider)
- **Models**: Use proper constructors with named parameters
- **Widgets**: Prefer `ConsumerWidget` or `ConsumerStatefulWidget`

## 🎨 UI Guidelines

### Always Use:
- `SnackBarHelper` for user feedback (see Data Grid Standards → User Feedback with SnackBars)
  - `SnackBarHelper.showInfo()` - General notifications
  - `SnackBarHelper.showSuccess()` - Positive actions
  - `SnackBarHelper.showError()` - Failures
  - `SnackBarHelper.showWarning()` - Cautions
- Theme colors via `Theme.of(context).colorScheme` (never hardcode colors)
- `withValues(alpha:)` instead of deprecated `withOpacity()`
- Proper `context.mounted` checks before using BuildContext after async operations

### Never Use:
- Direct `ScaffoldMessenger.of(context).showSnackBar()` calls
- Hardcoded colors like `Colors.blue` or `Color(0xFF123456)` in widgets
- `withOpacity()` (deprecated in Flutter 3.24+)
- BuildContext across async gaps without checking `mounted`

## 🏗️ Project Structure

```
lib/
├── app/                    # Theme, routing, constants
├── core/                   # Utilities, providers, models
│   └── utils/             # ← SnackBarHelper lives here
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── content/           # Content management (videos/audio)
│   ├── users/             # User management
│   ├── quotes/            # Quotes management
│   ├── categories/        # Categories management
│   └── playlists/         # Playlists management
└── shared/                # Shared widgets and utilities
```

## 🔄 State Management Pattern

```dart
// ✅ CORRECT: Use @riverpod with code generation
@riverpod
class UsersList extends _$UsersList {
  @override
  Future<List<UserItem>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return apiService.getUsers();
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => 
      ref.read(apiServiceProvider).getUsers()
    );
  }
}

// ❌ INCORRECT: Manual provider (old pattern)
final usersProvider = StateNotifierProvider<UsersNotifier, AsyncValue<List<User>>>((ref) {
  return UsersNotifier();
});
```

## 📱 Widget Patterns

```dart
// ✅ CORRECT: ConsumerWidget with proper error handling
class UsersListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersAsync = ref.watch(usersListProvider);
    
    return usersAsync.when(
      data: (users) => TrinaGrid(...),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}

// ✅ CORRECT: Async operation with snackbar feedback
Future<void> _handleDelete(String userId) async {
  try {
    await ref.read(apiServiceProvider).deleteUser(userId);
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(context, 'User deleted');
    ref.refresh(usersListProvider);
  } catch (e) {
    if (!context.mounted) return;
    SnackBarHelper.showError(context, 'Failed: ${e.toString()}');
  }
}
```

## 🚫 Common Anti-Patterns to Avoid

```dart
// ❌ DON'T: Hardcode colors
Container(color: Colors.blue)

// ✅ DO: Use theme colors
Container(color: Theme.of(context).colorScheme.primary)

// ❌ DON'T: Use deprecated withOpacity
color.withOpacity(0.5)

// ✅ DO: Use withValues
color.withValues(alpha: 0.5)

// ❌ DON'T: Direct snackbar
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi')))

// ✅ DO: Use SnackBarHelper
SnackBarHelper.showInfo(context, 'Hi')

// ❌ DON'T: Context after async without check
await operation();
Navigator.pop(context); // ❌ Context might be unmounted

// ✅ DO: Check mounted first
await operation();
if (!context.mounted) return;
Navigator.pop(context);
```

## 📝 File Naming Conventions

- Screens: `*_screen.dart` (e.g., `users_list_screen.dart`)
- Widgets: `*_widget.dart` or descriptive (e.g., `user_card.dart`)
- Providers: `*_provider.dart` (e.g., `users_provider.dart`)
- Models: `*_model.dart` (e.g., `user_model.dart`)
- Services: `*_service.dart` (e.g., `api_service.dart`)
- All files: `snake_case`

## 🧪 Testing Requirements

When generating code:
- Include proper error handling (try-catch blocks)
- Check `context.mounted` before using BuildContext after async operations
- Use `const` constructors where possible for performance
- Provide meaningful variable names (not `a`, `b`, `temp`)

## 🔍 Code Quality Checklist

Before suggesting code:
- [ ] Uses Riverpod 3.0 with `@riverpod` annotation
- [ ] Uses `SnackBarHelper` for user feedback
- [ ] Uses theme colors (no hardcoded colors)
- [ ] Checks `context.mounted` after async operations
- [ ] Uses `withValues()` instead of `withOpacity()`
- [ ] Proper error handling with try-catch
- [ ] Meaningful variable names
- [ ] Includes documentation comments for public APIs

## 📊 Data Grid Standards

### When to Use TrinaGrid vs DataTable

**Use TrinaGrid for:**
- ✅ List screens with large datasets (>100 rows)
- ✅ Server-side pagination required
- ✅ Complex filtering, sorting, export features
- ✅ Read-only or view-heavy screens
- ✅ Examples: Users list, Quotes list, Content list

**Use DataTable for:**
- ✅ Embedded editors with inline editing
- ✅ Small datasets (<100 rows)
- ✅ Complex interactions (move up/down, reorder)
- ✅ Custom rendering requirements
- ✅ Examples: Karaoke lyrics editor

### TrinaGrid Implementation Pattern

```dart
// ✅ CORRECT: TrinaGrid with server-side pagination
class UsersListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  late final TrinaStateManager _stateManager;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  int _pageSize = 50;
  int _totalElements = 0;
  List<TrinaRow> _rows = [];
  
  @override
  void initState() {
    super.initState();
    _stateManager = TrinaStateManager(
      columns: _buildColumns(),
      rows: [],
    );
    _loadUsers();
  }
  
  List<TrinaColumn> _buildColumns() {
    return [
      TrinaColumn(
        field: 'id',
        headerName: 'ID',
        frozen: TrinaColumnFrozen.start, // ✅ Freeze left
        type: TrinaColumnType.number(),
        width: 80,
      ),
      TrinaColumn(
        field: 'name',
        headerName: 'Name',
        type: TrinaColumnType.text(),
        width: 200,
      ),
      TrinaColumn(
        field: 'email',
        headerName: 'Email',
        type: TrinaColumnType.text(),
        width: 250,
      ),
      // ✅ Date columns: Store formatted strings, not DateTime objects
      TrinaColumn(
        field: 'createdAt',
        headerName: 'Created',
        type: TrinaColumnType.text(), // ✅ Text type, not date
        width: 160,
      ),
      TrinaColumn(
        field: 'actions',
        headerName: 'Actions',
        frozen: TrinaColumnFrozen.end, // ✅ Freeze right
        type: TrinaColumnType.text(),
        width: 100,
        renderer: (cell) => _buildActionsCell(cell),
      ),
    ];
  }
  
  TrinaRow _userToRow(UserItem user) {
    return TrinaRow(cells: {
      'id': TrinaCell(value: user.id),
      'name': TrinaCell(value: user.name ?? '-'),
      'email': TrinaCell(value: user.email ?? '-'),
      // ✅ Format dates to strings before storing in cells
      'createdAt': TrinaCell(value: _formatDateTime(user.createdAt)),
      'actions': TrinaCell(value: user.id),
    });
  }
  
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }
  
  Future<void> _loadUsers() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.dio.get(
        '/admin/users',
        queryParameters: {
          'page': _currentPage,
          'size': _pageSize,
          'search': _searchQuery.isEmpty ? null : _searchQuery,
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      final users = (data['content'] as List)
          .map((json) => UserItem.fromJson(json))
          .toList();
      
      setState(() {
        _totalElements = data['totalElements'] ?? 0;
        _rows = users.map(_userToRow).toList();
        _stateManager.setRows(_rows);
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to load users');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _currentPage = 0;
                _loadUsers();
              },
            ),
          ),
          
          // ✅ TrinaGrid
          Expanded(
            child: TrinaGrid(
              stateManager: _stateManager,
              configuration: TrinaConfiguration(
                style: TrinaGridStyleConfig(
                  // ✅ Use theme colors
                  gridBackgroundColor: theme.colorScheme.surface,
                  rowColor: theme.colorScheme.surface,
                  oddRowColor: theme.colorScheme.surfaceContainerHighest,
                  cellTextStyle: theme.textTheme.bodyMedium,
                  columnTextStyle: theme.textTheme.titleSmall,
                ),
              ),
            ),
          ),
          
          // ✅ Pagination footer with page size selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                // ✅ Page size dropdown
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
                      _loadUsers();
                    }
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  'Showing ${_currentPage * _pageSize + 1}-'
                  '${min((_currentPage + 1) * _pageSize, _totalElements)} '
                  'of $_totalElements',
                ),
                const Spacer(),
                // ✅ Pagination buttons
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: _currentPage == 0 ? null : () {
                    setState(() => _currentPage = 0);
                    _loadUsers();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage == 0 ? null : () {
                    setState(() => _currentPage--);
                    _loadUsers();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: (_currentPage + 1) * _pageSize >= _totalElements
                      ? null
                      : () {
                    setState(() => _currentPage++);
                    _loadUsers();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: (_currentPage + 1) * _pageSize >= _totalElements
                      ? null
                      : () {
                    setState(() => _currentPage = (_totalElements / _pageSize).floor());
                    _loadUsers();
                  },
                ),
              ],
            ),
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
```

### Date Handling in TrinaGrid (CRITICAL)

```dart
// ✅ CORRECT: Store formatted date strings in TrinaCell
TrinaRow _userToRow(UserItem user) {
  return TrinaRow(cells: {
    'createdAt': TrinaCell(value: _formatDateTime(user.createdAt)), // ✅ Formatted string
  });
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
}

TrinaColumn(
  field: 'createdAt',
  type: TrinaColumnType.text(), // ✅ Text type, not date
  // No renderer needed - displays string directly
)

// ❌ INCORRECT: Storing DateTime objects
TrinaCell(value: user.createdAt) // ❌ Will cause type errors
TrinaColumnType.date() // ❌ Expects formatted strings, not DateTime
```

### User Feedback with SnackBars

**Location**: `lib/core/utils/snackbar_helper.dart`

Always use the centralized `SnackBarHelper` for consistent styling across the application.

#### SnackBar Types

| Type | Use Case | Example |
|------|----------|---------|
| **Info** | General notifications | "User blocked" |
| **Success** | Positive actions | "User created successfully" |
| **Error** | Failures | "Failed to delete user" |
| **Warning** | Cautions | "User has active sessions" |

#### Usage Examples

```dart
import 'package:satsang_admin/core/utils/snackbar_helper.dart';

// ✅ CORRECT: Info - General notifications
SnackBarHelper.showInfo(context, 'User blocked');

// ✅ CORRECT: Success - Positive feedback
SnackBarHelper.showSuccess(context, 'User created successfully');

// ✅ CORRECT: Error - Failures
SnackBarHelper.showError(context, 'Failed to delete user');

// ✅ CORRECT: Warning - Important notices
SnackBarHelper.showWarning(context, 'User has active sessions');

// ❌ INCORRECT: Direct ScaffoldMessenger usage
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Message')), // ❌ Inconsistent styling
);

// ✅ CORRECT: Always check context.mounted for async operations
Future<void> _deleteUser(String userId) async {
  await apiService.deleteUser(userId);
  if (!context.mounted) return;
  SnackBarHelper.showSuccess(context, 'User deleted');
}
```

#### Best Practices

1. **Keep messages concise**: 2-5 words ideal, max 10 words
2. **Use action-oriented language**: "User created" not "Creation successful"
3. **Always check `context.mounted`** before showing snackbars in async operations
4. **Be specific in errors**: Include error details when helpful
5. **Don't overuse**: Only for important user feedback, not every action

## 🔧 Code Organization

### Import Organization

```dart
// ✅ CORRECT: Import order
// 1. Dart core libraries
import 'dart:async';
import 'dart:convert';

// 2. Flutter libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages (alphabetical)
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trina_grid/trina_grid.dart';

// 4. Local imports (relative paths)
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../../core/utils/snackbar_helper.dart';
```

### Class Organization

```dart
class UsersListScreen extends ConsumerStatefulWidget {
  // 1. Static constants
  static const double defaultPadding = 16.0;
  
  // 2. Constructor
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  // 3. Private fields
  final _searchController = TextEditingController();
  late final TrinaStateManager _stateManager;
  int _currentPage = 0;
  
  // 4. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // 5. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(/* ... */);
  }
  
  // 6. Private methods
  void _initializeData() {
    // Implementation
  }
  
  Future<void> _loadUsers() async {
    // Implementation
  }
}
```

## 🛡️ Memory Leak Prevention (CRITICAL)

### Riverpod Lifecycle Management

```dart
// ✅ CORRECT: Always use ref.onDispose for cleanup
@Riverpod(keepAlive: true)
ApiService apiService(Ref ref) {
  final service = ApiService();
  ref.onDispose(() => service.dispose()); // ✅ Automatic cleanup
  return service;
}

// ❌ INCORRECT: Manual disposal without Riverpod
final service = ApiService();
// ... no cleanup mechanism
```

### Widget Controllers Cleanup

```dart
// ✅ CORRECT: Dispose controllers in StatefulWidget
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _controller.dispose();          // ✅ Always dispose
    _scrollController.dispose();    // ✅ Always dispose
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) => /* ... */;
}
```

### Memory Leak Checklist

When creating a new class or widget, verify:

- [ ] StreamController has `dispose()` method that calls `.close()`
- [ ] Riverpod providers use `ref.onDispose()` for cleanup
- [ ] StatefulWidget `dispose()` method disposes all controllers
- [ ] Stream subscriptions are canceled in `dispose()`
- [ ] Timers are canceled in `dispose()`
- [ ] Animation controllers are disposed
- [ ] Listeners are removed before disposing controllers
- [ ] No `ref.read()` calls in `dispose()` (use cached references)
- [ ] No BuildContext usage after async operations without `mounted` check

## ⚠️ Error Handling

### Exception Handling Pattern

```dart
// ✅ CORRECT: Comprehensive error handling
Future<void> deleteUser(String userId) async {
  try {
    await apiService.deleteUser(userId);
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(context, 'User deleted');
    ref.refresh(usersListProvider);
  } on DioException catch (e) {
    // ✅ Handle specific exceptions
    if (!context.mounted) return;
    final errorMessage = e.response?.data['message'] ?? 'Failed to delete user';
    SnackBarHelper.showError(context, errorMessage);
  } catch (e) {
    // ✅ Catch-all for unexpected errors
    if (!context.mounted) return;
    SnackBarHelper.showError(context, 'An unexpected error occurred');
    debugPrint('Unexpected error in deleteUser: $e');
  }
}
```

## 💡 When in Doubt

1. Look for similar patterns in existing code (Users, Quotes screens)
2. Follow Material Design 3 guidelines
3. Prioritize code readability over cleverness
4. Always implement proper cleanup (dispose, close, cancel)
5. Ask for clarification rather than guessing

## 🎯 Special Considerations

### Admin Panel Specifics
- Uses JWT authentication with Spring Boot backend
- Server-side pagination for all list screens
- Export to CSV functionality for data grids
- Inline editing for specific use cases (karaoke editor)
- Responsive design for desktop-first experience

### Authentication
- JWT token stored in Dio interceptor
- Auto-refresh token on 401 responses
- Logout clears token and navigates to login

### Routing
- GoRouter for declarative routing
- Auth guards for protected routes
- Deep linking support for admin functions

---

**Remember**: This is an administrative interface for managing a spiritual content platform. Code quality, security, and user experience are paramount. Always follow established patterns and maintain consistency with existing code.

## 📋 Code Review Checklist

### Before Committing Code

- [ ] All lint warnings resolved (`flutter analyze`)
- [ ] No hardcoded colors (use theme)
- [ ] Proper error handling implemented
- [ ] `context.mounted` checked before async context usage
- [ ] Uses `SnackBarHelper` for user feedback
- [ ] Uses `@riverpod` for state management
- [ ] Date columns store formatted strings in TrinaGrid
- [ ] All controllers disposed properly
- [ ] Meaningful variable names
- [ ] Documentation comments for public APIs

### Data Grid Specific

- [ ] TrinaGrid used for list screens with pagination
- [ ] DataTable used only for inline editors
- [ ] Date columns use `TrinaColumnType.text()` with formatted strings
- [ ] Frozen columns: ID (left), Actions (right)
- [ ] Page size dropdown with [20, 50, 100] options
- [ ] Pagination footer with proper navigation buttons
- [ ] Theme colors used throughout (no hardcoded colors)
- [ ] Custom renderers for chips, badges, complex widgets

---

**Last Updated**: November 10, 2025  
**Project**: Satsang Admin Panel  
**Status**: ✅ Active Development
