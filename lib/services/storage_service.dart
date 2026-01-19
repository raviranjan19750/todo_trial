import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_model.dart';

/// Storage service using SharedPreferences for JSON persistence
class StorageService {
  static const String _todosKey = 'todos_list';

  /// Load all todos from storage
  Future<List<TodoModel>> loadTodos() async {
    try {
      print('[StorageService] Loading todos from storage...');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_todosKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => TodoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Save all todos to storage
  Future<void> saveTodos(List<TodoModel> todos) async {
    try {
      print('[StorageService] Saving todos to storage...');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        todos.map((todo) => todo.toJson()).toList(),
      );
      await prefs.setString(_todosKey, jsonString);
    } catch (e) {
      // Silently fail - in production you might want to log this
    }
  }

  /// Clear all todos
  Future<void> clearTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_todosKey);
    } catch (e) {
      // Silently fail
    }
  }
}
