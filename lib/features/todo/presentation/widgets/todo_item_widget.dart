import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/todo_model.dart';
import '../screens/todo_list/parts/todo_list_statenotifier.dart';

/// Widget for displaying a todo item
class TodoItemWidget extends ConsumerWidget {
  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.depth,
    this.onAddSubTodo,
    this.onEdit,
  });

  final TodoModel todo;
  final int depth;
  final VoidCallback? onAddSubTodo;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChildren = todo.children.isNotEmpty;
    final notifier = ref.read(todoListStateProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expand/collapse icon
              if (hasChildren)
                IconButton(
                  icon: Icon(
                    todo.isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => notifier.toggleExpand(todo.id),
                )
              else
                const SizedBox(width: 48),
              // Checkbox - using propagation version for parent/child sync
              // TODO: Use toggleComplete() for simple toggle without propagation if needed
              Checkbox(
                value: todo.isCompleted,
                onChanged: (_) => notifier.toggleCompleteWithPropagation(todo.id),
              ),
            ],
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted ? Colors.grey : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              // Add sub-todo button
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: onAddSubTodo,
                tooltip: 'Add sub-todo',
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(context, notifier),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TodoListStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text(
          'Are you sure you want to delete "${todo.title}"?'
          '${todo.children.isNotEmpty ? '\n\nThis will also delete ${todo.children.length} sub-todo(s).' : ''}'
          '\n\n⚠️ Note: If this leaves the parent with no sub-todos, the parent will also be deleted (cascading upward).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.deleteTodo(todo.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
