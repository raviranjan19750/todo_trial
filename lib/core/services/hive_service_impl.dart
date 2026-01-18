import 'package:hive_flutter/hive_flutter.dart';

import '../../features/todo/data/models/todo_model.dart';
import 'hive_service.dart';

/// HiveService implementation
class HiveServiceImpl implements HiveService {
  static const String _todosBoxName = 'todos_box';
  static const String _todosKey = 'todos_list';

  Box<List<dynamic>>? _box;

  @override
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TodoModelAdapter());
    }

    // Open box
    _box = await Hive.openBox<List<dynamic>>(_todosBoxName);
  }

  Box<List<dynamic>> get _todosBox {
    if (_box == null) {
      throw Exception('HiveService not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  List<TodoModel> getAllTodos() {
    final List<dynamic>? data = _todosBox.get(_todosKey);
    if (data == null) return [];
    return data.cast<TodoModel>().toList();
  }

  @override
  Future<void> saveAllTodos(List<TodoModel> todos) async {
    await _todosBox.put(_todosKey, todos);
  }

  @override
  Future<void> clearAllTodos() async {
    await _todosBox.delete(_todosKey);
  }
}
