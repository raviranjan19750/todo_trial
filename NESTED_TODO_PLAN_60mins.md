# Nested Todo List - 60 Minute Achievable Plan

## Scope Definition

### IN SCOPE (Delivered)

- ✅ Nested todo display with expand/collapse
- ✅ Add top-level todo and sub-todo
- ✅ Delete todo with confirmation dialog
- ✅ Toggle checkbox
- ✅ Hive persistence
- ✅ Clean architecture (following HunchFlutterDemo pattern EXACTLY)

### OUT OF SCOPE (Can be mentioned verbally)

- Cascading parent deletion
- Bidirectional checkbox propagation  
- Swipe-to-delete with undo
- Edit functionality
- Animations
- Tests

---

## Time Breakdown (60 minutes)

| Phase | Time | Deliverable | Status |
|-------|------|-------------|--------|
| 1. Setup | 5 min | Project + dependencies | ✅ |
| 2. Core Layer | 8 min | Copy core from HunchFlutterDemo + add Hive service | ✅ |
| 3. Data Model | 7 min | TodoModel with Hive adapter | ✅ |
| 4. Datasource | 10 min | Interface + Impl (following exact pattern) | ✅ |
| 5. State Management | 8 min | StateNotifier in parts/ folder | ✅ |
| 6. Basic UI | 15 min | List screen + recursive item widget | ✅ |
| 7. Add Dialog | 5 min | Simple add todo dialog | ✅ |
| 8. Polish | 2 min | Empty state, delete confirmation | ✅ |

---

## Project Directory Structure (Matching HunchFlutterDemo)

```
nested_todo_app/
├── lib/
│   ├── main.dart                              # App entry point with ProviderScope & Hive init
│   │
│   ├── app/                                   # App-specific implementations
│   │   └── errors/
│   │       └── error_state_adapter_impl.dart  # App-specific error handling + provider
│   │
│   ├── core/                                  # COPIED from HunchFlutterDemo
│   │   ├── errors/
│   │   │   ├── error_state.dart               # ErrorState model with factories
│   │   │   ├── error_state_type.dart          # ErrorStateType enum
│   │   │   └── error_state_adapter.dart       # Base adapter + provider
│   │   │
│   │   ├── logger/
│   │   │   ├── logger.dart                    # Abstract Logger + loggerProvider
│   │   │   └── logger_impl.dart               # LoggerImpl console implementation
│   │   │
│   │   ├── services/                          # NEW: Replaces network/ for offline-first
│   │   │   ├── hive_service.dart              # Abstract HiveService + hiveServiceProvider
│   │   │   └── hive_service_impl.dart         # Hive init, register adapters, open box
│   │   │
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── error_state_widget.dart    # COPIED from HunchFlutterDemo
│   │           └── loading_widget.dart        # COPIED from HunchFlutterDemo
│   │
│   ├── features/
│   │   └── todo/
│   │       ├── data/
│   │       │   ├── models/
│   │       │   │   ├── todo_model.dart        # TodoModel with @HiveType
│   │       │   │   └── todo_model.g.dart      # Generated Hive TypeAdapter
│   │       │   │
│   │       │   └── sources/                   # SAME naming as HunchFlutterDemo
│   │       │       ├── todo_datasource.dart       # Abstract + todoDatasourceProvider
│   │       │       └── todo_datasource_impl.dart  # TodoDatasourceImpl
│   │       │
│   │       └── presentation/
│   │           ├── screens/
│   │           │   └── todo_list/             # Folder per screen (like users_list/)
│   │           │       ├── todo_list_screen.dart  # ConsumerStatefulWidget
│   │           │       └── parts/                 # Screen-specific state
│   │           │           └── todo_list_statenotifier.dart  # StateNotifier + provider
│   │           │
│   │           └── widgets/
│   │               ├── todo_item_widget.dart      # Single todo row (recursive)
│   │               └── add_todo_dialog.dart       # Dialog for adding todo
│   │
│   └── screens/
│       └── home_screen.dart                   # Home/navigation screen
│
├── pubspec.yaml
└── NESTED_TODO_PLAN_60mins.md
```

---

## Architecture Patterns Used

### Pattern 1: Datasource Interface with Provider (from users_datasource.dart)

```dart
// Provider defined in interface file
final Provider<TodoDatasource> todoDatasourceProvider = Provider(
  (ref) => TodoDatasourceImpl(ref),
);

abstract class TodoDatasource {
  List<TodoModel> getTodos();
  Future<void> saveTodos(List<TodoModel> todos);
}
```

### Pattern 2: StateNotifier in parts/ folder (from users_list_statenotifier.dart)

```dart
// Provider defined in statenotifier file
final todoListStateProvider =
    StateNotifierProvider<TodoListStateNotifier, AsyncValue<List<TodoModel>>>(
  (ref) => TodoListStateNotifier(
    datasource: ref.read(todoDatasourceProvider),
    errorAdapter: ref.read(errorStateAdapterImplProvider) as ErrorStateAdapterImpl,
  ),
);

class TodoListStateNotifier extends StateNotifier<AsyncValue<List<TodoModel>>> {
  ErrorState? lastError;  // For UI display
  
  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      _todos = _datasource.getTodos();
      state = AsyncValue.data(List.from(_todos));
      lastError = null;
    } catch (e, st) {
      lastError = _errorAdapter.getErrorState(e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }
}
```

### Pattern 3: Screen with .when() (from users_list_screen.dart)

```dart
class TodoListScreen extends ConsumerStatefulWidget { ... }

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todoListStateProvider.notifier).loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoListStateProvider);

    return Scaffold(
      body: todoState.when(
        loading: () => const LoadingWidget(message: 'Loading todos...'),
        error: (error, stackTrace) => ErrorStateWidget(...),
        data: (todos) => _buildTodoList(todos),
      ),
    );
  }
}
```

---

## Features Implemented

1. **Hierarchical Display**: Todos can have nested sub-todos displayed with indentation
2. **Expand/Collapse**: Parent todos can be expanded or collapsed to show/hide children
3. **Add Todo**: Add top-level todos or sub-todos via dialog
4. **Delete Todo**: Delete with confirmation dialog (warns if has children)
5. **Complete Toggle**: Mark todos as complete with strikethrough styling
6. **Persistence**: All data stored in Hive and persists across app restarts
7. **Error Handling**: Consistent error handling with ErrorStateWidget
8. **Loading States**: LoadingWidget shown during data operations

---

## Running the App

```bash
cd nested_todo_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## What to Say About Missing Features

**When asked about cascading delete:**
> "I'd implement a recursive function that after deleting a todo, walks up to the parent and checks `children.isEmpty`. If true, delete parent and recurse upward."

**When asked about checkbox propagation:**
> "Downward is straightforward - recursively set all children. Upward requires checking if all siblings are complete, then updating parent and recursing up."

---

## Success Criteria

- [x] App launches without errors
- [x] Architecture matches HunchFlutterDemo pattern exactly
- [x] Can add a top-level todo
- [x] Can add a sub-todo to existing todo
- [x] Can expand/collapse parent todos
- [x] Can check/uncheck todos
- [x] Can delete todos with confirmation
- [x] Data persists after app restart
