import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_model.dart';

/// Storage service using SharedPreferences for JSON persistence
class StorageService {
  static const String _todosKey = 'todos_list';

  /// Load all todos from storage
  Future<List<TodoModel>> loadTodos() async {
    try {
      print('[StorageService] 📥 Loading todos from local storage...');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_todosKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('[StorageService] ✅ No todos found in storage, returning empty list');
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final todos = jsonList
          .map((json) => TodoModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('[StorageService] ✅ Successfully loaded ${todos.length} todo(s) from storage');
      _logTodoStructure(todos);
      return todos;
    } catch (e, stackTrace) {
      print('[StorageService] ❌ Error loading todos: $e');
      print('[StorageService] Stack trace: $stackTrace');
      // Return empty list on error
      return [];
    }
  }

  /// Save all todos to storage
  Future<void> saveTodos(List<TodoModel> todos) async {
    try {
      print('[StorageService] 💾 Saving ${todos.length} todo(s) to local storage...');
      _logTodoStructure(todos);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        todos.map((todo) => todo.toJson()).toList(),
      );
      
      final saved = await prefs.setString(_todosKey, jsonString);
      if (saved) {
        print('[StorageService] ✅ Successfully saved todos to storage (${jsonString.length} bytes)');
    } else {
      print('[StorageService] ⚠️ Failed to save todos to storage');
    }
    } catch (e, stackTrace) {
      print('[StorageService] ❌ Error saving todos: $e');
      print('[StorageService] Stack trace: $stackTrace');
    }
  }

  /// Clear all todos
  Future<void> clearTodos() async {
    try {
      print('[StorageService] 🗑️ Clearing all todos from storage...');
      final prefs = await SharedPreferences.getInstance();
      final removed = await prefs.remove(_todosKey);
      if (removed) {
        print('[StorageService] ✅ Successfully cleared todos from storage');
      } else {
        print('[StorageService] ⚠️ No todos found to clear');
      }
    } catch (e, stackTrace) {
      print('[StorageService] ❌ Error clearing todos: $e');
      print('[StorageService] Stack trace: $stackTrace');
    }
  }

  /// Helper method to log todo structure for debugging
  void _logTodoStructure(List<TodoModel> todos) {
    if (todos.isEmpty) {
      print('[StorageService] 📋 Todo structure: Empty');
      return;
    }
    
    int totalCount = 0;
    int countWithChildren = 0;
    
    void countTodos(List<TodoModel> todoList, int depth) {
      for (final todo in todoList) {
        totalCount++;
        if (todo.children.isNotEmpty) {
          countWithChildren++;
          print('[StorageService] 📋 ${'  ' * depth}├─ ${todo.title} (${todo.children.length} children) [${todo.isCompleted ? '✓' : '○'}]');
          countTodos(todo.children, depth + 1);
        } else {
          print('[StorageService] 📋 ${'  ' * depth}├─ ${todo.title} [${todo.isCompleted ? '✓' : '○'}]');
        }
      }
    }
    
    print('[StorageService] 📋 Todo structure (${todos.length} top-level):');
    countTodos(todos, 0);
    print('[StorageService] 📊 Total: $totalCount todo(s), $countWithChildren parent(s) with children');
  }
}
