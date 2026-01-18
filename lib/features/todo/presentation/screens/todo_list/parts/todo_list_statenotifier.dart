import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../../core/logger/logger.dart';
import '../../../../data/models/todo_model.dart';
import '../../../../data/sources/todo_datasource.dart';

/// StateNotifierProvider for todo list
final todoListStateProvider =
    StateNotifierProvider<TodoListStateNotifier, AsyncValue<List<TodoModel>>>(
  (ref) => TodoListStateNotifier(
    datasource: ref.read(todoDatasourceProvider),
    logger: ref.read(loggerProvider),
  ),
);

/// StateNotifier for managing todo list state
class TodoListStateNotifier extends StateNotifier<AsyncValue<List<TodoModel>>> {
  final TodoDatasource _datasource;
  final Logger _logger;
  final _uuid = const Uuid();

  TodoListStateNotifier({
    required TodoDatasource datasource,
    required Logger logger,
  })  : _datasource = datasource,
        _logger = logger,
        super(const AsyncValue.loading());

  /// Load todos from datasource
  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = _datasource.getAllTodos();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      _logger.error('Failed to load todos', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a new todo
  Future<void> addTodo(String title, {String? parentId}) async {
    try {
      final newTodo = TodoModel(
        id: _uuid.v4(),
        title: title,
        isCompleted: false,
        isExpanded: true,
      );

      await _datasource.createTodo(newTodo, parentId: parentId);
      await _refreshState();
    } catch (e, st) {
      _logger.error('Failed to add todo', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a todo with cascading parent removal
  Future<void> deleteTodo(String id) async {
    try {
      await _datasource.deleteTodoWithCascade(id);
      await _refreshState();
    } catch (e, st) {
      _logger.error('Failed to delete todo', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle completion status (simple toggle, no propagation)
  Future<void> toggleComplete(String id) async {
    try {
      await _datasource.toggleComplete(id);
      await _refreshState();
    } catch (e, st) {
      _logger.error('Failed to toggle complete', e, st);
      state = AsyncValue.error(e, st);
    }
  }


  // Bonus
  // <<--------------------------------------->>
  /// Toggle completion status with propagation
  /// - Downward: Checking parent checks all children
  /// - Upward: If all children are complete, parent auto-completes
  Future<void> toggleCompleteWithPropagation(String id) async {
    try {
      await _datasource.toggleCompleteWithPropagation(id);
      await _refreshState();
    } catch (e, st) {
      _logger.error('Failed to toggle complete with propagation', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle expand/collapse
  Future<void> toggleExpand(String id) async {
    try {
      await _datasource.toggleExpand(id);
      await _refreshState();
    } catch (e, st) {
      _logger.error('Failed to toggle expand', e, st);
      state = AsyncValue.error(e, st);
    }
  }


  /// Edit a todo's title
  Future<void> editTodo(String id, String newTitle) async {
    try {
      await _datasource.updateTodo(id, title: newTitle);
      await _refreshState();
    } catch (e, st) {
      _logger.error('Failed to edit todo', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh state from datasource
  Future<void> _refreshState() async {
    final todos = _datasource.getAllTodos();
    state = AsyncValue.data(todos);
  }
}
