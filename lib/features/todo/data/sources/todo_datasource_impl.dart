import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/hive_service.dart';
import '../models/todo_model.dart';
import 'todo_datasource.dart';

/// TodoDatasource implementation - SIMPLIFIED VERSION
/// Direct, readable tree traversal without transform patterns
class TodoDatasourceImpl implements TodoDatasource {
  final HiveService _hiveService;

  /// In-memory cache of todos
  List<TodoModel> _todos = [];

  TodoDatasourceImpl(Ref ref) : _hiveService = ref.read(hiveServiceProvider);

  /// Persist current state to Hive
  Future<void> _persist() async {
    await _hiveService.saveAllTodos(_todos);
  }

  @override
  List<TodoModel> getAllTodos() {
    _todos = _hiveService.getAllTodos();
    return List.from(_todos);
  }

  @override
  TodoModel? getTodoById(String id) {
    return _findById(_todos, id);
  }

  @override
  Future<void> createTodo(TodoModel todo, {String? parentId}) async {
    if (parentId == null) {
      _todos.add(todo);
    } else {
      final parent = _findById(_todos, parentId);
      if (parent == null) {
        throw Exception('Parent todo not found: $parentId');
      }
      parent.children.add(todo);
    }
    await _persist();
  }

  @override
  Future<void> updateTodo(
    String id, {
    String? title,
    bool? isCompleted,
    bool? isExpanded,
  }) async {
    // Simple: find the todo and update its fields directly
    final todo = _findById(_todos, id);
    if (todo == null) {
      throw Exception('Todo not found: $id');
    }

    // Update only the fields that were provided
    if (title != null) todo.title = title;
    if (isCompleted != null) todo.isCompleted = isCompleted;
    if (isExpanded != null) todo.isExpanded = isExpanded;

    await _persist();
  }

  @override
  Future<void> deleteTodo(String id) async {
    final deleted = _deleteById(_todos, id);
    if (!deleted) {
      throw Exception('Todo not found: $id');
    }
    await _persist();
  }

  /// Find a todo by ID - simple recursive search
  TodoModel? _findById(List<TodoModel> todos, String id) {
    for (final todo in todos) {
      if (todo.id == id) return todo;

      // Search in children
      final found = _findById(todo.children, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Delete a todo by ID - returns true if found and deleted
  bool _deleteById(List<TodoModel> todos, String id) {
    for (int i = 0; i < todos.length; i++) {
      if (todos[i].id == id) {
        todos.removeAt(i);
        return true;
      }

      // Search in children
      if (_deleteById(todos[i].children, id)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> toggleComplete(String id) async {
    final todo = _findById(_todos, id);
    if (todo == null) {
      throw Exception('Todo not found: $id');
    }
    todo.isCompleted = !todo.isCompleted;
    await _persist();
  }

  @override
  Future<void> deleteTodoWithCascade(String id) async {
    _deleteWithCascade(_todos, id);
    await _persist();
  }

  /// Delete with cascade - if parent becomes empty, delete parent too
  void _deleteWithCascade(List<TodoModel> todos, String id) {
    for (int i = 0; i < todos.length; i++) {
      if (todos[i].id == id) {
        // Found it - delete
        todos.removeAt(i);
        return;
      }

      // Search in children
      final childrenBefore = todos[i].children.length;
      _deleteWithCascade(todos[i].children, id);
      final childrenAfter = todos[i].children.length;

      // If a child was deleted and parent is now empty, delete parent too
      if (childrenAfter < childrenBefore && todos[i].children.isEmpty) {
        todos.removeAt(i);
        return;
      }
    }
  }

  // bonus methods impl
  // <<--------------------------------------->>

  @override
  Future<void> toggleCompleteWithPropagation(String id) async {
    final todo = _findById(_todos, id);
    if (todo == null) {
      throw Exception('Todo not found: $id');
    }

    final newState = !todo.isCompleted;
    todo.isCompleted = newState;

    // Downward propagation: if checking parent, check all children
    if (newState) {
      _setAllChildrenCompleted(todo, true);
    } else {
      // If unchecking, uncheck all children too
      _setAllChildrenCompleted(todo, false);
    }

    // Upward propagation: check if parent should be auto-completed
    if (newState) {
      _propagateCompletionUpward(_todos, id);
    } else {
      // If unchecking, uncheck all ancestors
      _uncheckAncestors(_todos, id);
    }

    await _persist();
  }

  @override
  Future<void> toggleExpand(String id) async {
    final todo = _findById(_todos, id);
    if (todo == null) {
      throw Exception('Todo not found: $id');
    }
    todo.isExpanded = !todo.isExpanded;
    await _persist();
  }

  // ============================================
  // Checkbox Propagation Helpers
  // ============================================

  /// Set completion state for a todo and all its descendants (downward)
  void _setAllChildrenCompleted(TodoModel todo, bool isCompleted) {
    for (final child in todo.children) {
      child.isCompleted = isCompleted;
      // Recurse into grandchildren
      _setAllChildrenCompleted(child, isCompleted);
    }
  }

  /// Propagate completion upward - if all children are complete, mark parent complete
  void _propagateCompletionUpward(List<TodoModel> todos, String childId) {
    for (final todo in todos) {
      // Check if this todo contains the child
      if (_containsChild(todo, childId)) {
        // Check if all children of this parent are now complete
        if (todo.children.isNotEmpty &&
            todo.children.every((c) => c.isCompleted)) {
          todo.isCompleted = true;
          // Continue upward - check this todo's parent
          _propagateCompletionUpward(_todos, todo.id);
        }
        return;
      }
      // Recurse into children
      _propagateCompletionUpward(todo.children, childId);
    }
  }

  /// Uncheck all ancestors when a todo is unchecked
  void _uncheckAncestors(List<TodoModel> todos, String childId) {
    for (final todo in todos) {
      if (_containsChild(todo, childId)) {
        // This todo is an ancestor - uncheck it
        if (todo.isCompleted) {
          todo.isCompleted = false;
        }
        // Continue checking children
        _uncheckAncestors(todo.children, childId);
        return;
      }
    }
  }

  /// Check if a todo contains a child with given ID
  bool _containsChild(TodoModel todo, String childId) {
    for (final child in todo.children) {
      if (child.id == childId) return true;
      if (_containsChild(child, childId)) return true;
    }
    return false;
  }
}
