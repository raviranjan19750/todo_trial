import 'package:json_annotation/json_annotation.dart';

part 'todo_model.g.dart';

/// Todo model with nested children support
@JsonSerializable()
class TodoModel {
  final String id;
  String title;
  bool isCompleted;
  bool isExpanded;
  List<TodoModel> children;

  TodoModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isExpanded = true,
    List<TodoModel>? children,
  }) : children = children ?? [];

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TodoModelToJson(this);

  /// Create from JSON
  factory TodoModel.fromJson(Map<String, dynamic> json) => _$TodoModelFromJson(json);

  @override
  String toString() {
    return 'TodoModel(id: $id, title: $title, isCompleted: $isCompleted, isExpanded: $isExpanded, children: ${children.length})';
  }
}
