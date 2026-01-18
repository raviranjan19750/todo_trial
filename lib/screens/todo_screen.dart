import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_model.dart';
import '../providers/todo_provider.dart';

/// Todo list screen with inline TodoItem widget
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoProvider);
    final notifier = ref.read(todoProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested Todo List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodoDialog(notifier),
        child: const Icon(Icons.add),
      ),
      body: todos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: todos.length,
              itemBuilder: (context, index) => _buildTodoTree(todos[index], 0, notifier),
            ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No todos yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first todo!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Build todo tree recursively
  Widget _buildTodoTree(TodoModel todo, int depth, TodoNotifier notifier) {
    return Column(
      children: [
        _buildTodoItem(todo, depth, notifier),
        if (todo.isExpanded)
          ...todo.children.map((child) => _buildTodoTree(child, depth + 1, notifier)),
      ],
    );
  }

  /// Build single todo item (inline widget)
  Widget _buildTodoItem(TodoModel todo, int depth, TodoNotifier notifier) {
    final hasChildren = todo.children.isNotEmpty;

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
              // Checkbox
              Checkbox(
                value: todo.isCompleted,
                onChanged: (_) => notifier.toggleComplete(todo.id),
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
                onPressed: () => _showTodoDialog(notifier, todoId: todo.id, currentTitle: todo.title),
                tooltip: 'Edit',
              ),
              // Add sub-todo button
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _showTodoDialog(notifier, parentId: todo.id),
                tooltip: 'Add sub-todo',
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(context, todo, notifier),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show todo dialog (unified for add/edit)
  void _showTodoDialog(
    TodoNotifier notifier, {
    String? todoId,
    String? currentTitle,
    String? parentId,
  }) {
    final isEditMode = todoId != null;
    final controller = TextEditingController(text: currentTitle ?? '');

    // Determine dialog title
    String dialogTitle;
    if (isEditMode) {
      dialogTitle = 'Edit Todo';
    } else if (parentId != null) {
      dialogTitle = 'Add Sub-Todo';
    } else {
      dialogTitle = 'Add Todo';
    }

    // Determine button text
    final buttonText = isEditMode ? 'Save' : 'Add';

    showDialog(
      context: context,
      builder: (context) {
        // Capture todoId in closure for flow analysis
        final editTodoId = todoId;
        return AlertDialog(
          title: Text(dialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter todo title',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  if (isEditMode && editTodoId != null) {
                    notifier.editTodo(editTodoId, controller.text.trim());
                  } else {
                    notifier.addTodo(controller.text.trim(), parentId: parentId);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  /// Confirm delete dialog
  void _confirmDelete(BuildContext context, TodoModel todo, TodoNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text(
          'Are you sure you want to delete "${todo.title}"?'
          '${todo.children.isNotEmpty ? '\n\nThis will also delete ${todo.children.length} sub-todo(s).' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Using simple delete for demo
              notifier.deleteTodo(todo.id);

              // KEY REQUIREMENT: Cascading delete available - uncomment to enable:
              // notifier.deleteTodoWithCascade(todo.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
