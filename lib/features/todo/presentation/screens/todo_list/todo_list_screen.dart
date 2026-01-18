import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/presentation/widgets/loading_widget.dart';
import '../../../data/models/todo_model.dart';
import '../../widgets/todo_dialog.dart';
import '../../widgets/todo_item_widget.dart';
import 'parts/todo_list_statenotifier.dart';

/// Todo List Screen
class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todoListStateProvider.notifier).loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoListStateProvider);
    // Extract notifier once and reuse
    final notifier = ref.read(todoListStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested Todo List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadTodos(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodoDialog(notifier),
        child: const Icon(Icons.add),
      ),
      body: todoState.when(
        loading: () => const LoadingWidget(message: 'Loading todos...'),
        error: (error, stackTrace) => _buildErrorState(error, notifier),
        data: (todos) => _buildTodoList(todos, notifier),
      ),
    );
  }

  Widget _buildErrorState(Object error, TodoListStateNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => notifier.loadTodos(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList(List<TodoModel> todos, TodoListStateNotifier notifier) {
    if (todos.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: todos.length,
      itemBuilder: (context, index) => _buildTodoTree(todos[index], 0, notifier),
    );
  }

  Widget _buildTodoTree(TodoModel todo, int depth, TodoListStateNotifier notifier) {
    return Column(
      children: [
        TodoItemWidget(
          todo: todo,
          depth: depth,
          onAddSubTodo: () => _showTodoDialog(notifier, parentId: todo.id),
          onEdit: () => _showTodoDialog(notifier, todoId: todo.id, currentTitle: todo.title),
        ),
        if (todo.isExpanded)
          ...todo.children.map((child) => _buildTodoTree(child, depth + 1, notifier)),
      ],
    );
  }

  void _showTodoDialog(
    TodoListStateNotifier notifier, {
    String? parentId,
    String? todoId,
    String? currentTitle,
  }) {
    showDialog(
      context: context,
      builder: (context) => TodoDialog(
        currentTitle: currentTitle,
        parentId: parentId,
        onSubmit: (title) {
          if (todoId != null) {
            // Edit mode
            notifier.editTodo(todoId, title);
          } else {
            // Add mode
            notifier.addTodo(title, parentId: parentId);
          }
        },
      ),
    );
  }
}
