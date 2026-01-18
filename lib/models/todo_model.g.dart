// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoModel _$TodoModelFromJson(Map<String, dynamic> json) => TodoModel(
  id: json['id'] as String,
  title: json['title'] as String,
  isCompleted: json['isCompleted'] as bool? ?? false,
  isExpanded: json['isExpanded'] as bool? ?? true,
  children: (json['children'] as List<dynamic>?)
      ?.map((e) => TodoModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TodoModelToJson(TodoModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'isCompleted': instance.isCompleted,
  'isExpanded': instance.isExpanded,
  'children': instance.children,
};
