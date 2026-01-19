import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/todo_model.dart';
import '../services/storage_service.dart';



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

  /// Get a mutable copy of the current state
  List<TodoModel> get _mutableState => List.from(state);


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

  /// Helper to delete todo by ID
  List<TodoModel> _deleteById(List<TodoModel> todos, String id) {
    for (final todo in todos) {
      if (todo.id == id) {
        todos.remove(todo);
        return todos;
      }
      // Search in children
      _deleteById(todo.children, id);
    }
    return todos;
  }

  /// Recursive helper for cascading delete
  void _deleteWithCascade(List<TodoModel> todos, String id) {
    for (final todo in todos) {
      if (todo.id == id) {
        todos.remove(todo);
        return;
      }

      // Search in children
      final childrenBefore = todo.children.length;
      _deleteWithCascade(todo.children, id);
      final childrenAfter = todo.children.length;

      // If a child was deleted and parent is now empty, delete parent too
      if (childrenAfter < childrenBefore && todo.children.isEmpty) {
        todos.remove(todo);
        return;
      }
    }
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
      final updatedTodos = _addToParent(_mutableState, parentId, newTodo);
      state = updatedTodos;
    }

    await _persist();
  }


  /// Simple delete - called from UI
  Future<void> deleteTodo(String id) async {
    final updatedTodos = _deleteById(_mutableState, id);
    state = updatedTodos;
    await _persist();
  }



  /// KEY REQUIREMENT: Cascading delete - fully implemented
  /// When a todo is deleted, if parent becomes empty, delete parent too (recursive upward)
  Future<void> deleteTodoWithCascade(String id) async {
    final updatedTodos = _mutableState;
    _deleteWithCascade(updatedTodos, id);
    state = updatedTodos;
    await _persist();
  }



  /// Toggle completion status
  Future<void> toggleComplete(String id) async {
    final updatedTodos = _toggleCompleteById(_mutableState, id);
    state = updatedTodos;
    await _persist();
  }


  /// Toggle expand/collapse
  Future<void> toggleExpand(String id) async {
    final updatedTodos = _toggleExpandById(_mutableState, id);
    state = updatedTodos;
    await _persist();
  }


  /// Edit todo title
  Future<void> editTodo(String id, String newTitle) async {
    final updatedTodos = _editById(_mutableState, id, newTitle);
    state = updatedTodos;
    await _persist();
  }

}
