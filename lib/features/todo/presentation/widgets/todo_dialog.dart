import 'package:flutter/material.dart';

/// Unified dialog for both adding and editing todos
class TodoDialog extends StatefulWidget {
  const TodoDialog({
    super.key,
    this.currentTitle,
    this.parentId,
    required this.onSubmit,
  });

  /// If provided, dialog is in edit mode. If null, it's add mode.
  final String? currentTitle;

  /// If provided, indicates this is a sub-todo
  final String? parentId;

  /// Callback with the title (for both add and edit)
  final void Function(String title) onSubmit;

  @override
  State<TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends State<TodoDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.currentTitle != null;
  bool get isSubTodo => widget.parentId != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle ?? '');
    
    // If edit mode, select all text for easy editing
    if (isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.currentTitle!.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getTitle()),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Todo Title',
            hintText: _getHintText(),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditMode ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  String _getTitle() {
    if (isEditMode) return 'Edit Todo';
    if (isSubTodo) return 'Add Sub-Todo';
    return 'Add Todo';
  }

  String _getHintText() {
    if (isEditMode) return 'Enter new title';
    if (isSubTodo) return 'Enter sub-todo title';
    return 'Enter todo title';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final title = _controller.text.trim();
      
      // In edit mode, only call callback if title actually changed
      if (isEditMode && title == widget.currentTitle) {
        Navigator.pop(context);
        return;
      }
      
      widget.onSubmit(title);
      Navigator.pop(context);
    }
  }
}
