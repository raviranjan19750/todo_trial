import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/todo/data/models/todo_model.dart';
import 'hive_service_impl.dart';

/// Provider for HiveService (SAME PATTERN as networkServiceProvider)
final hiveServiceProvider = Provider<HiveService>(
  (ref) => HiveServiceImpl(),
);

/// Abstract HiveService interface
abstract class HiveService {
  Future<void> init();
  List<TodoModel> getAllTodos();
  Future<void> saveAllTodos(List<TodoModel> todos);
  Future<void> clearAllTodos();
}
