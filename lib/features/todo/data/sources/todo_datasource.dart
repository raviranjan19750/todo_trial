import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_model.dart';
import 'todo_datasource_impl.dart';

/// Provider for TodoDatasource (SAME PATTERN as usersDatasourceProvider)
final Provider<TodoDatasource> todoDatasourceProvider = Provider(
  (ref) => TodoDatasourceImpl(ref),
);

/// Abstract TodoDatasource with full CRUD operations
abstract class TodoDatasource {
  /// Get all root-level todos (with their nested children)
  List<TodoModel> getAllTodos();

  /// Find a specific todo by ID (traverses tree)
  TodoModel? getTodoById(String id);

  /// Create a new todo (at root or as child of parentId)
  Future<void> createTodo(TodoModel todo, {String? parentId});

  /// Update an existing todo's properties
  Future<void> updateTodo(
    String id, {
    String? title,
    bool? isCompleted,
    bool? isExpanded,
  });

  /// Delete a todo by ID (simple delete, no cascade)
  Future<void> deleteTodo(String id);

  /// Toggle completion state (simple toggle, no propagation)
  Future<void> toggleComplete(String id);

  /// Delete a todo with cascading parent removal
  /// When a todo is deleted, if its parent ends up with no sub-todos,
  /// the parent is also deleted. This cascades recursively upward.
  Future<void> deleteTodoWithCascade(String id);

  ///////////// bonus
  // <<--------------------------------------->>


  /// Toggle completion state with propagation
  /// - Downward: Checking parent checks all children
  /// - Upward: If all children are complete, parent auto-completes
  Future<void> toggleCompleteWithPropagation(String id);

  /// Toggle expand/collapse state
  Future<void> toggleExpand(String id);
}
