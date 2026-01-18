# Enhancement Pseudo Implementation Guide
## Interview Reference - Remaining Features

This document explains how to implement all remaining features from the PRD that were not completed in the 60-minute scope. Each section includes:
- Approach explanation
- Code examples
- Class/file modifications
- Data flow diagrams

---

## Table of Contents

1. [Edit Todo Functionality](#1-edit-todo-functionality)
2. [Cascading Delete (Auto-Remove Empty Parents)](#2-cascading-delete-auto-remove-empty-parents)
3. [Checkbox Propagation (Bidirectional)](#3-checkbox-propagation-bidirectional)
4. [Swipe-to-Delete with Undo](#4-swipe-to-delete-with-undo)
5. [Animations](#5-animations)
6. [Unit & Widget Tests](#6-unit--widget-tests)

---

## 1. Edit Todo Functionality

### Approach

Add an edit button to each todo item that opens a dialog pre-filled with the current title. On save, update the todo in the tree and persist to Hive.

### Files to Modify

| File | Change |
|------|--------|
| `todo_list_statenotifier.dart` | Add `editTodo()` method |
| `todo_item_widget.dart` | Add edit icon button |
| `edit_todo_dialog.dart` | **NEW FILE** - Edit dialog widget |

### Data Flow

```
User taps edit icon
       ↓
EditTodoDialog opens (pre-filled with current title)
       ↓
User modifies title and taps Save
       ↓
TodoListStateNotifier.editTodo(id, newTitle)
       ↓
_updateTodo() finds and updates the todo in tree
       ↓
_datasource.saveTodos() persists to Hive
       ↓
state = AsyncValue.data(updatedList)
       ↓
UI rebuilds with new title
```

### Code Implementation

#### 1.1 Add `editTodo()` to StateNotifier

```dart
// File: lib/features/todo/presentation/screens/todo_list/parts/todo_list_statenotifier.dart

/// Edit a todo's title
Future<void> editTodo(String id, String newTitle) async {
  try {
    _updateTodo(_todos, id, (todo) {
      return todo.copyWith(title: newTitle);
    });

    await _datasource.saveTodos(_todos);
    state = AsyncValue.data(List.from(_todos));
  } catch (e, st) {
    lastError = _errorAdapter.getErrorState(e, stackTrace: st);
    state = AsyncValue.error(e, st);
  }
}
```

#### 1.2 Create Edit Dialog

```dart
// File: lib/features/todo/presentation/widgets/edit_todo_dialog.dart

import 'package:flutter/material.dart';

class EditTodoDialog extends StatefulWidget {
  const EditTodoDialog({
    super.key,
    required this.currentTitle,
    required this.onSave,
  });

  final String currentTitle;
  final void Function(String newTitle) onSave;

  @override
  State<EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<EditTodoDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Todo'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Todo Title',
            border: OutlineInputBorder(),
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
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_controller.text.trim());
      Navigator.pop(context);
    }
  }
}
```

#### 1.3 Add Edit Button to TodoItemWidget

```dart
// File: lib/features/todo/presentation/widgets/todo_item_widget.dart

// Add to trailing Row:
IconButton(
  icon: const Icon(Icons.edit_outlined, size: 20),
  onPressed: () => _showEditDialog(context, ref),
  tooltip: 'Edit',
),

// Add method:
void _showEditDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => EditTodoDialog(
      currentTitle: todo.title,
      onSave: (newTitle) {
        ref.read(todoListStateProvider.notifier).editTodo(todo.id, newTitle);
      },
    ),
  );
}
```

---

## 2. Cascading Delete (Auto-Remove Empty Parents)

### Approach

When deleting a todo, after removal, traverse upward to check if the parent now has zero children. If so, delete the parent and continue checking upward recursively.

**Key Insight**: We need to track parent-child relationships. Two approaches:
1. **Approach A**: Add `parentId` field to TodoModel
2. **Approach B**: Pass parent reference during deletion traversal

We'll use **Approach B** (no model change needed).

### Data Flow

```
User deletes todo "C" (child of "B", which is child of "A")

Step 1: Delete "C" from B's children
        B.children = [] (now empty)
        
Step 2: Check if B has children → NO
        Delete "B" from A's children
        A.children = [] (now empty)
        
Step 3: Check if A has children → NO
        Delete "A" from root list
        
Step 4: Persist and update state
```

### Code Implementation

#### 2.1 Modified Delete Logic in StateNotifier

```dart
// File: lib/features/todo/presentation/screens/todo_list/parts/todo_list_statenotifier.dart

/// Delete a todo with cascading parent removal
Future<void> deleteTodoWithCascade(String id) async {
  try {
    _deleteTodoWithCascade(_todos, id, null);

    await _datasource.saveTodos(_todos);
    state = AsyncValue.data(List.from(_todos));
  } catch (e, st) {
    lastError = _errorAdapter.getErrorState(e, stackTrace: st);
    state = AsyncValue.error(e, st);
  }
}

/// Recursive delete with cascade - returns true if parent should also be deleted
bool _deleteTodoWithCascade(
  List<TodoModel> todos,
  String id,
  List<TodoModel>? parentList,
) {
  for (int i = 0; i < todos.length; i++) {
    if (todos[i].id == id) {
      // Found the todo to delete
      todos.removeAt(i);
      
      // Check if this list (parent's children) is now empty
      // If so, signal that parent should be deleted too
      return todos.isEmpty && parentList != null;
    }
    
    // Recurse into children
    bool shouldDeleteCurrent = _deleteTodoWithCascade(
      todos[i].children,
      id,
      todos, // Pass current list as parent
    );
    
    if (shouldDeleteCurrent) {
      // A child was deleted and left this todo with no children
      // Delete this todo and check if ITS parent should also be deleted
      todos.removeAt(i);
      return todos.isEmpty && parentList != null;
    }
  }
  return false;
}
```

#### 2.2 Alternative: Cleaner Implementation with Parent Tracking

```dart
// More readable approach using a helper class

class _DeleteResult {
  final bool found;
  final bool parentShouldBeDeleted;
  
  _DeleteResult({this.found = false, this.parentShouldBeDeleted = false});
}

/// Delete todo and cascade upward if parent becomes empty
void _cascadeDelete(List<TodoModel> todos, String targetId) {
  _cascadeDeleteRecursive(todos, targetId);
}

_DeleteResult _cascadeDeleteRecursive(List<TodoModel> todos, String targetId) {
  for (int i = 0; i < todos.length; i++) {
    final todo = todos[i];
    
    // Check if this is the target
    if (todo.id == targetId) {
      todos.removeAt(i);
      // Signal parent: "I was deleted, check if you're now empty"
      return _DeleteResult(found: true, parentShouldBeDeleted: todos.isEmpty);
    }
    
    // Check children
    final result = _cascadeDeleteRecursive(todo.children, targetId);
    
    if (result.found) {
      // Target was found in subtree
      if (result.parentShouldBeDeleted) {
        // Child list is empty, remove this parent too
        todos.removeAt(i);
        // Continue cascade: tell OUR parent to check
        return _DeleteResult(found: true, parentShouldBeDeleted: todos.isEmpty);
      }
      return _DeleteResult(found: true, parentShouldBeDeleted: false);
    }
  }
  
  return _DeleteResult(found: false);
}
```

### Visual Example

```
Before delete "Task 3":

Root
└── Task 1
    └── Task 2
        └── Task 3  ← DELETE THIS

After cascading delete:

Root (empty - all deleted!)

Step by step:
1. Delete "Task 3" → Task 2.children = []
2. Task 2 is now empty → Delete Task 2 → Task 1.children = []
3. Task 1 is now empty → Delete Task 1 → Root = []
```

---

## 3. Checkbox Propagation (Bidirectional)

### Approach

Two propagation directions:
1. **Downward**: When parent is checked, all descendants are checked
2. **Upward**: When all siblings are checked, parent auto-completes

### Data Flow

```
DOWNWARD PROPAGATION:
User checks parent "A"
       ↓
Set A.isCompleted = true
       ↓
Recursively set all children.isCompleted = true
       ↓
Persist and update UI


UPWARD PROPAGATION:
User checks child "C" (last unchecked sibling)
       ↓
Check if all siblings of C are completed
       ↓
YES → Set parent B.isCompleted = true
       ↓
Check if all siblings of B are completed
       ↓
Continue upward until root or incomplete sibling found
```

### Code Implementation

#### 3.1 Downward Propagation

```dart
// File: lib/features/todo/presentation/screens/todo_list/parts/todo_list_statenotifier.dart

/// Toggle completion with downward propagation
Future<void> toggleCompleteWithPropagation(String id) async {
  try {
    // Find the todo and get its new state
    TodoModel? targetTodo;
    _findTodo(_todos, id, (todo) => targetTodo = todo);
    
    if (targetTodo == null) return;
    
    final newCompletedState = !targetTodo!.isCompleted;
    
    // Update the todo and all its descendants
    _setCompletedRecursive(_todos, id, newCompletedState);
    
    // Check upward propagation
    if (newCompletedState) {
      _propagateCompletionUpward(_todos, id);
    } else {
      // If unchecking, uncheck all ancestors
      _uncheckAncestors(_todos, id);
    }

    await _datasource.saveTodos(_todos);
    state = AsyncValue.data(List.from(_todos));
  } catch (e, st) {
    lastError = _errorAdapter.getErrorState(e, stackTrace: st);
    state = AsyncValue.error(e, st);
  }
}

/// Set completed state for a todo and all its descendants
bool _setCompletedRecursive(List<TodoModel> todos, String id, bool isCompleted) {
  for (int i = 0; i < todos.length; i++) {
    if (todos[i].id == id) {
      // Found the target - update it and ALL descendants
      todos[i] = _setAllDescendantsCompleted(todos[i], isCompleted);
      return true;
    }
    if (_setCompletedRecursive(todos[i].children, id, isCompleted)) {
      return true;
    }
  }
  return false;
}

/// Recursively set completion state for a todo and all children
TodoModel _setAllDescendantsCompleted(TodoModel todo, bool isCompleted) {
  return todo.copyWith(
    isCompleted: isCompleted,
    children: todo.children
        .map((child) => _setAllDescendantsCompleted(child, isCompleted))
        .toList(),
  );
}
```

#### 3.2 Upward Propagation

```dart
/// Propagate completion status upward
/// If all children of a parent are complete, mark parent complete
void _propagateCompletionUpward(List<TodoModel> todos, String childId) {
  // Find parent of the given child and check if all siblings are complete
  _checkAndUpdateParent(todos, childId, null);
}

/// Returns the ID of parent if found and updated, null otherwise
String? _checkAndUpdateParent(
  List<TodoModel> todos,
  String childId,
  String? currentParentId,
) {
  for (int i = 0; i < todos.length; i++) {
    final todo = todos[i];
    
    // Check if childId is in this todo's children
    final childIndex = todo.children.indexWhere((c) => c.id == childId);
    
    if (childIndex != -1) {
      // Found the parent! Check if all children are completed
      final allChildrenCompleted = todo.children.every((c) => c.isCompleted);
      
      if (allChildrenCompleted && !todo.isCompleted) {
        // Update parent to completed
        todos[i] = todo.copyWith(isCompleted: true);
        
        // Continue upward - check this todo's parent
        _checkAndUpdateParent(todos, todo.id, null);
      }
      return todo.id;
    }
    
    // Recurse into children
    final result = _checkAndUpdateParent(todo.children, childId, todo.id);
    if (result != null) {
      // Child was found in subtree, now check if this level needs updating
      final allChildrenCompleted = todo.children.every((c) => c.isCompleted);
      if (allChildrenCompleted && !todo.isCompleted) {
        todos[i] = todo.copyWith(isCompleted: true);
        // Continue upward
        if (currentParentId != null) {
          _checkAndUpdateParent(todos, todo.id, null);
        }
      }
      return result;
    }
  }
  return null;
}

/// Uncheck all ancestors when a todo is unchecked
void _uncheckAncestors(List<TodoModel> todos, String childId) {
  for (int i = 0; i < todos.length; i++) {
    final todo = todos[i];
    
    // Check if childId is a descendant of this todo
    if (_containsDescendant(todo, childId)) {
      if (todo.isCompleted) {
        todos[i] = todo.copyWith(isCompleted: false);
      }
      // Continue checking children
      _uncheckAncestors(todo.children, childId);
      return;
    }
  }
}

/// Check if a todo contains a descendant with given ID
bool _containsDescendant(TodoModel todo, String descendantId) {
  for (final child in todo.children) {
    if (child.id == descendantId) return true;
    if (_containsDescendant(child, descendantId)) return true;
  }
  return false;
}
```

### Visual Example

```
DOWNWARD:
Before: Check "A"          After:
[ ] A                      [x] A
├── [ ] B                  ├── [x] B
│   └── [ ] C              │   └── [x] C
└── [ ] D                  └── [x] D


UPWARD:
Before: Check "C"          After:
[ ] A                      [x] A  ← auto-completed!
├── [x] B                  ├── [x] B  ← auto-completed!
│   └── [ ] C  ← CHECK     │   └── [x] C
└── [x] D                  └── [x] D
```

---

## 4. Swipe-to-Delete with Undo

### Approach

Use Flutter's `Dismissible` widget for swipe gesture. On dismiss:
1. Remove item from UI immediately
2. Show SnackBar with "Undo" action
3. If Undo pressed: restore item
4. If SnackBar dismissed: persist deletion

### Files to Modify

| File | Change |
|------|--------|
| `todo_list_statenotifier.dart` | Add `temporaryDelete()` and `undoDelete()` methods |
| `todo_item_widget.dart` | Wrap with `Dismissible` widget |
| `todo_list_screen.dart` | Handle SnackBar display |

### Code Implementation

#### 4.1 StateNotifier Methods for Undo Support

```dart
// File: lib/features/todo/presentation/screens/todo_list/parts/todo_list_statenotifier.dart

/// Temporarily deleted todo for undo functionality
TodoModel? _deletedTodo;
String? _deletedFromParentId;
int? _deletedAtIndex;

/// Delete todo temporarily (can be undone)
Future<bool> temporaryDelete(String id) async {
  try {
    // Find and store the todo before deletion
    _deletedTodo = null;
    _deletedFromParentId = null;
    _deletedAtIndex = null;
    
    _findAndStoreTodo(_todos, id, null);
    
    if (_deletedTodo == null) return false;
    
    // Remove from tree (but don't persist yet)
    _deleteTodoById(_todos, id);
    
    // Update UI immediately
    state = AsyncValue.data(List.from(_todos));
    return true;
  } catch (e, st) {
    lastError = _errorAdapter.getErrorState(e, stackTrace: st);
    return false;
  }
}

/// Find todo and store its position for potential undo
void _findAndStoreTodo(List<TodoModel> todos, String id, String? parentId) {
  for (int i = 0; i < todos.length; i++) {
    if (todos[i].id == id) {
      _deletedTodo = todos[i].copyWith(
        children: List.from(todos[i].children),
      );
      _deletedFromParentId = parentId;
      _deletedAtIndex = i;
      return;
    }
    _findAndStoreTodo(todos[i].children, id, todos[i].id);
  }
}

/// Undo the last deletion
Future<void> undoDelete() async {
  if (_deletedTodo == null) return;
  
  try {
    if (_deletedFromParentId == null) {
      // Was a root-level todo
      if (_deletedAtIndex != null && _deletedAtIndex! <= _todos.length) {
        _todos.insert(_deletedAtIndex!, _deletedTodo!);
      } else {
        _todos.add(_deletedTodo!);
      }
    } else {
      // Was a child todo - find parent and restore
      _restoreToParent(_todos, _deletedFromParentId!, _deletedTodo!, _deletedAtIndex);
    }
    
    // Clear undo state
    _deletedTodo = null;
    _deletedFromParentId = null;
    _deletedAtIndex = null;
    
    // Persist and update
    await _datasource.saveTodos(_todos);
    state = AsyncValue.data(List.from(_todos));
  } catch (e, st) {
    lastError = _errorAdapter.getErrorState(e, stackTrace: st);
  }
}

/// Restore todo to its parent
bool _restoreToParent(List<TodoModel> todos, String parentId, TodoModel todo, int? index) {
  for (int i = 0; i < todos.length; i++) {
    if (todos[i].id == parentId) {
      if (index != null && index <= todos[i].children.length) {
        todos[i].children.insert(index, todo);
      } else {
        todos[i].children.add(todo);
      }
      return true;
    }
    if (_restoreToParent(todos[i].children, parentId, todo, index)) {
      return true;
    }
  }
  return false;
}

/// Confirm deletion (persist to storage)
Future<void> confirmDelete() async {
  _deletedTodo = null;
  _deletedFromParentId = null;
  _deletedAtIndex = null;
  
  await _datasource.saveTodos(_todos);
}
```

#### 4.2 Dismissible Widget in TodoItemWidget

```dart
// File: lib/features/todo/presentation/widgets/todo_item_widget.dart

@override
Widget build(BuildContext context, WidgetRef ref) {
  final hasChildren = todo.children.isNotEmpty;

  return Dismissible(
    key: Key(todo.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (direction) async {
      // Show confirmation or just proceed
      return true;
    },
    onDismissed: (direction) {
      // Trigger temporary delete and show snackbar
      ref.read(todoListStateProvider.notifier).temporaryDelete(todo.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${todo.title}"'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(todoListStateProvider.notifier).undoDelete();
            },
          ),
        ),
      ).closed.then((reason) {
        // If not dismissed by action (undo), confirm deletion
        if (reason != SnackBarClosedReason.action) {
          ref.read(todoListStateProvider.notifier).confirmDelete();
        }
      });
    },
    child: Padding(
      padding: EdgeInsets.only(left: depth * 24.0),
      child: Card(
        // ... rest of the card content
      ),
    ),
  );
}
```

---

## 5. Animations

### Approach

Add animations for:
1. **Expand/Collapse**: Smooth height animation for children
2. **List Items**: Fade/slide when adding/removing
3. **Checkbox**: Scale animation on toggle

### Code Implementation

#### 5.1 Animated Expand/Collapse

```dart
// File: lib/features/todo/presentation/widgets/animated_todo_children.dart

import 'package:flutter/material.dart';
import '../../data/models/todo_model.dart';
import 'todo_item_widget.dart';

class AnimatedTodoChildren extends StatefulWidget {
  const AnimatedTodoChildren({
    super.key,
    required this.todo,
    required this.depth,
    required this.buildChild,
  });

  final TodoModel todo;
  final int depth;
  final Widget Function(TodoModel child, int depth) buildChild;

  @override
  State<AnimatedTodoChildren> createState() => _AnimatedTodoChildrenState();
}

class _AnimatedTodoChildrenState extends State<AnimatedTodoChildren>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));

    if (widget.todo.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedTodoChildren oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todo.isExpanded != oldWidget.todo.isExpanded) {
      if (widget.todo.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightFactor.value,
            child: child,
          ),
        );
      },
      child: Column(
        children: widget.todo.children
            .map((child) => widget.buildChild(child, widget.depth + 1))
            .toList(),
      ),
    );
  }
}
```

#### 5.2 Using AnimatedList for Add/Remove

```dart
// File: lib/features/todo/presentation/screens/todo_list/todo_list_screen.dart

// Replace ListView.builder with AnimatedList for root todos

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<TodoModel> _previousTodos = [];

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoListStateProvider);

    return Scaffold(
      // ...
      body: todoState.when(
        // ...
        data: (todos) {
          // Detect additions/removals and animate
          _handleListChanges(todos);
          return _buildAnimatedList(todos);
        },
      ),
    );
  }

  void _handleListChanges(List<TodoModel> newTodos) {
    // Compare with previous and trigger animations
    // This is simplified - real implementation needs diffing
    if (newTodos.length > _previousTodos.length) {
      // Item added
      final index = newTodos.length - 1;
      _listKey.currentState?.insertItem(index);
    }
    _previousTodos = List.from(newTodos);
  }

  Widget _buildAnimatedList(List<TodoModel> todos) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: todos.length,
      itemBuilder: (context, index, animation) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: _buildTodoTree(todos[index], 0),
          ),
        );
      },
    );
  }
}
```

#### 5.3 Animated Checkbox

```dart
// File: lib/features/todo/presentation/widgets/animated_checkbox.dart

import 'package:flutter/material.dart';

class AnimatedCheckbox extends StatelessWidget {
  const AnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value ? 1 : 0),
      duration: const Duration(milliseconds: 200),
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 1.0 + (animValue * 0.1), // Slight bounce effect
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}
```

---

## 6. Unit & Widget Tests

### Test Structure

```
test/
├── unit/
│   ├── models/
│   │   └── todo_model_test.dart
│   ├── datasources/
│   │   └── todo_datasource_test.dart
│   └── notifiers/
│       └── todo_list_statenotifier_test.dart
└── widget/
    ├── todo_item_widget_test.dart
    └── todo_list_screen_test.dart
```

### Code Implementation

#### 6.1 TodoModel Unit Tests

```dart
// File: test/unit/models/todo_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nested_todo_app/features/todo/data/models/todo_model.dart';

void main() {
  group('TodoModel', () {
    test('should create with default values', () {
      final todo = TodoModel(id: '1', title: 'Test');
      
      expect(todo.id, '1');
      expect(todo.title, 'Test');
      expect(todo.isCompleted, false);
      expect(todo.isExpanded, true);
      expect(todo.children, isEmpty);
    });

    test('should create with children', () {
      final child = TodoModel(id: '2', title: 'Child');
      final parent = TodoModel(
        id: '1',
        title: 'Parent',
        children: [child],
      );
      
      expect(parent.children.length, 1);
      expect(parent.children.first.title, 'Child');
    });

    test('copyWith should preserve unchanged fields', () {
      final original = TodoModel(
        id: '1',
        title: 'Original',
        isCompleted: true,
        isExpanded: false,
      );
      
      final copied = original.copyWith(title: 'Modified');
      
      expect(copied.id, '1');
      expect(copied.title, 'Modified');
      expect(copied.isCompleted, true);
      expect(copied.isExpanded, false);
    });

    test('copyWith should update specified fields', () {
      final original = TodoModel(id: '1', title: 'Test');
      
      final copied = original.copyWith(
        isCompleted: true,
        isExpanded: false,
      );
      
      expect(copied.isCompleted, true);
      expect(copied.isExpanded, false);
    });
  });
}
```

#### 6.2 StateNotifier Unit Tests

```dart
// File: test/unit/notifiers/todo_list_statenotifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nested_todo_app/features/todo/data/models/todo_model.dart';
import 'package:nested_todo_app/features/todo/data/sources/todo_datasource.dart';
import 'package:nested_todo_app/features/todo/presentation/screens/todo_list/parts/todo_list_statenotifier.dart';
import 'package:nested_todo_app/core/errors/error_state_adapter.dart';

// Mocks
class MockTodoDatasource extends Mock implements TodoDatasource {}
class MockErrorStateAdapter extends Mock implements ErrorStateAdapter {}

void main() {
  late MockTodoDatasource mockDatasource;
  late MockErrorStateAdapter mockErrorAdapter;
  late TodoListStateNotifier notifier;

  setUp(() {
    mockDatasource = MockTodoDatasource();
    mockErrorAdapter = MockErrorStateAdapter();
    notifier = TodoListStateNotifier(
      datasource: mockDatasource,
      errorAdapter: mockErrorAdapter,
    );
  });

  group('TodoListStateNotifier', () {
    test('initial state should be loading', () {
      expect(notifier.state, const AsyncValue<List<TodoModel>>.loading());
    });

    test('loadTodos should update state with data', () async {
      final todos = [TodoModel(id: '1', title: 'Test')];
      when(() => mockDatasource.getTodos()).thenReturn(todos);

      await notifier.loadTodos();

      expect(notifier.state.value, todos);
    });

    test('loadTodos should handle errors', () async {
      when(() => mockDatasource.getTodos()).thenThrow(Exception('Error'));
      when(() => mockErrorAdapter.getErrorState(any(), stackTrace: any(named: 'stackTrace')))
          .thenReturn(ErrorState.unknown());

      await notifier.loadTodos();

      expect(notifier.state.hasError, true);
      expect(notifier.lastError, isNotNull);
    });

    test('addTodo should add to root list', () async {
      when(() => mockDatasource.getTodos()).thenReturn([]);
      when(() => mockDatasource.saveTodos(any())).thenAnswer((_) async {});

      await notifier.loadTodos();
      await notifier.addTodo('New Todo');

      expect(notifier.state.value!.length, 1);
      expect(notifier.state.value!.first.title, 'New Todo');
    });

    test('addTodo should add as child when parentId provided', () async {
      final parent = TodoModel(id: 'parent', title: 'Parent');
      when(() => mockDatasource.getTodos()).thenReturn([parent]);
      when(() => mockDatasource.saveTodos(any())).thenAnswer((_) async {});

      await notifier.loadTodos();
      await notifier.addTodo('Child', parentId: 'parent');

      expect(notifier.state.value!.first.children.length, 1);
      expect(notifier.state.value!.first.children.first.title, 'Child');
    });

    test('toggleComplete should flip completion state', () async {
      final todo = TodoModel(id: '1', title: 'Test', isCompleted: false);
      when(() => mockDatasource.getTodos()).thenReturn([todo]);
      when(() => mockDatasource.saveTodos(any())).thenAnswer((_) async {});

      await notifier.loadTodos();
      await notifier.toggleComplete('1');

      expect(notifier.state.value!.first.isCompleted, true);
    });

    test('deleteTodo should remove from list', () async {
      final todo = TodoModel(id: '1', title: 'Test');
      when(() => mockDatasource.getTodos()).thenReturn([todo]);
      when(() => mockDatasource.saveTodos(any())).thenAnswer((_) async {});

      await notifier.loadTodos();
      await notifier.deleteTodo('1');

      expect(notifier.state.value, isEmpty);
    });
  });
}
```

#### 6.3 Widget Tests

```dart
// File: test/widget/todo_item_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested_todo_app/features/todo/data/models/todo_model.dart';
import 'package:nested_todo_app/features/todo/presentation/widgets/todo_item_widget.dart';

void main() {
  group('TodoItemWidget', () {
    testWidgets('should display todo title', (tester) async {
      final todo = TodoModel(id: '1', title: 'Test Todo');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodoItemWidget(todo: todo, depth: 0),
            ),
          ),
        ),
      );

      expect(find.text('Test Todo'), findsOneWidget);
    });

    testWidgets('should show strikethrough when completed', (tester) async {
      final todo = TodoModel(id: '1', title: 'Completed', isCompleted: true);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodoItemWidget(todo: todo, depth: 0),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Completed'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('should show expand icon when has children', (tester) async {
      final todo = TodoModel(
        id: '1',
        title: 'Parent',
        children: [TodoModel(id: '2', title: 'Child')],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodoItemWidget(todo: todo, depth: 0),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('should show checkbox', (tester) async {
      final todo = TodoModel(id: '1', title: 'Test');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodoItemWidget(todo: todo, depth: 0),
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('should indent based on depth', (tester) async {
      final todo = TodoModel(id: '1', title: 'Deep');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodoItemWidget(todo: todo, depth: 2),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(Card),
          matching: find.byType(Padding),
        ).first,
      );
      
      expect(padding.padding, EdgeInsets.only(left: 2 * 24.0));
    });
  });
}
```

#### 6.4 Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Summary

| Feature | Complexity | Time Estimate | Key Challenge |
|---------|------------|---------------|---------------|
| Edit Todo | Low | 15 min | UI dialog |
| Cascading Delete | Medium | 25 min | Recursive upward traversal |
| Checkbox Propagation | Medium | 30 min | Bidirectional tree traversal |
| Swipe-to-Delete + Undo | Medium | 20 min | Temporary state management |
| Animations | Low-Medium | 25 min | AnimatedList integration |
| Unit Tests | Medium | 30 min | Mocking dependencies |
| Widget Tests | Medium | 25 min | ProviderScope setup |

**Total Estimated Time for All Enhancements: ~3 hours**

---

*Document Version: 1.0*  
*Purpose: Interview Reference for Pseudo-Implementation*
