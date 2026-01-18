import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  bool isExpanded;

  @HiveField(4)
  List<TodoModel> children;

  TodoModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isExpanded = true,
    List<TodoModel>? children,
  }) : children = children ?? [];

  @override
  String toString() {
    return 'TodoModel(id: $id, title: $title, isCompleted: $isCompleted, isExpanded: $isExpanded, children: ${children.length})';
  }
}
