import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/todo_model.dart';
import '../services/storage_service.dart';

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Todo list state provider
final todoProvider = StateNotifierProvider<TodoNotifier, List<TodoModel>>((ref) {
  return TodoNotifier(ref.read(storageServiceProvider));
});

/// StateNotifier for managing todo list
class TodoNotifier extends StateNotifier<List<TodoModel>> {
  final StorageService _storage;
  final _uuid = const Uuid();

  TodoNotifier(this._storage) : super([]) {
    _loadTodos();
  }

  /// Load todos from storage
  Future<void> _loadTodos() async {
    final todos = await _storage.loadTodos();
    state = todos;
  }

  /// Persist current state
  Future<void> _persist() async {
    await _storage.saveTodos(state);
  }

  /// Add a new todo
  Future<void> addTodo(String title, {String? parentId}) async {
    final newTodo = TodoModel(
      id: _uuid.v4(),
      title: title,
      isCompleted: false,
      isExpanded: true,
    );

    if (parentId == null) {
      // Add as top-level todo
      state = [...state, newTodo];
    } else {
      // Add as sub-todo
      final updatedTodos = _addToParent(List.from(state), parentId, newTodo);
      state = updatedTodos;
    }

    await _persist();
  }

  /// Helper to add todo to parent
  List<TodoModel> _addToParent(List<TodoModel> todos, String parentId, TodoModel newTodo) {
    for (final todo in todos) {
      if (todo.id == parentId) {
        todo.children.add(newTodo);
        return todos;
      }
      // Search in children
      _addToParent(todo.children, parentId, newTodo);
    }
    return todos;
  }

  /// Simple delete - called from UI
  Future<void> deleteTodo(String id) async {
    final updatedTodos = _deleteById(List.from(state), id);
    state = updatedTodos;
    await _persist();
  }

  /// Helper to delete todo by ID
  List<TodoModel> _deleteById(List<TodoModel> todos, String id) {
    for (int i = 0; i < todos.length; i++) {
      if (todos[i].id == id) {
        todos.removeAt(i);
        return todos;
      }
      // Search in children
      _deleteById(todos[i].children, id);
    }
    return todos;
  }

  /// KEY REQUIREMENT: Cascading delete - fully implemented
  /// When a todo is deleted, if parent becomes empty, delete parent too (recursive upward)
  Future<void> deleteTodoWithCascade(String id) async {
    final updatedTodos = List<TodoModel>.from(state);
    _deleteWithCascade(updatedTodos, id);
    state = updatedTodos;
    await _persist();
  }

  /// Recursive helper for cascading delete
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

  /// Toggle completion status
  Future<void> toggleComplete(String id) async {
    final updatedTodos = _toggleCompleteById(List.from(state), id);
    state = updatedTodos;
    await _persist();
  }

  /// Helper to toggle completion
  List<TodoModel> _toggleCompleteById(List<TodoModel> todos, String id) {
    for (final todo in todos) {
      if (todo.id == id) {
        todo.isCompleted = !todo.isCompleted;
        return todos;
      }
      // Search in children
      _toggleCompleteById(todo.children, id);
    }
    return todos;
  }

  /// Toggle expand/collapse
  Future<void> toggleExpand(String id) async {
    final updatedTodos = _toggleExpandById(List.from(state), id);
    state = updatedTodos;
    await _persist();
  }

  /// Helper to toggle expand
  List<TodoModel> _toggleExpandById(List<TodoModel> todos, String id) {
    for (final todo in todos) {
      if (todo.id == id) {
        todo.isExpanded = !todo.isExpanded;
        return todos;
      }
      // Search in children
      _toggleExpandById(todo.children, id);
    }
    return todos;
  }

  /// Edit todo title
  Future<void> editTodo(String id, String newTitle) async {
    final updatedTodos = _editById(List.from(state), id, newTitle);
    state = updatedTodos;
    await _persist();
  }

  /// Helper to edit todo
  List<TodoModel> _editById(List<TodoModel> todos, String id, String newTitle) {
    for (final todo in todos) {
      if (todo.id == id) {
        todo.title = newTitle;
        return todos;
      }
      // Search in children
      _editById(todo.children, id, newTitle);
    }
    return todos;
  }
}
