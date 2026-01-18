# Product Requirements Document (PRD)
## Nested Todo List - Flutter Live Coding Round

---

## 1. Problem Statement

Create a single-page Flutter application that displays a **nested (hierarchical) todo list** with offline-first persistence.

---

## 2. Key Requirements

| # | Requirement | Description | Status |
|---|-------------|-------------|--------|
| 1 | Nested Structure | Todos can have any number of sub-todos (unlimited nesting depth) | ✅ Implemented |
| 2 | Todo Display | Each todo item displays a checkbox and title | ✅ Implemented |
| 3 | Collapsible Parents | Parent todos must be collapsible/expandable to show/hide sub-todos | ✅ Implemented |
| 4 | Add Todo | Users can add new top-level todos | ✅ Implemented |
| 5 | Add Sub-Todo | Users can add sub-todos to any existing todo | ✅ Implemented |
| 6 | Edit Todo | Users can edit the title of any existing todo | ❌ Not Implemented |
| 7 | Delete Todo | Users can delete any todo | ✅ Implemented |
| 8 | Cascading Delete Rule | When a todo is deleted, if parent ends up with no sub-todos, parent should also be auto-deleted (recursive upward) | ❌ Not Implemented |
| 9 | Check/Uncheck Todos | Users can mark todos as complete/incomplete | ✅ Implemented |
| 10 | Offline-First | All data stored locally and persisted across app restarts | ✅ Implemented |

---

## 3. Functional Requirements

| # | Requirement | Description | Status | Notes |
|---|-------------|-------------|--------|-------|
| F1 | Hierarchical Display | Display todos in a tree structure with visual hierarchy | ✅ Implemented | Indentation based on depth |
| F2 | Expand/Collapse Icons | Visual indication of expand/collapse state (arrow icons) | ✅ Implemented | expand_less/expand_more icons |
| F3 | Add Dialog | Add todo/sub-todo via dialog or bottomsheet | ✅ Implemented | AlertDialog with TextField |
| F4 | Edit Functionality | Edit todo title via pencil icon, long-press, or similar | ❌ Not Implemented | - |
| F5 | Delete Functionality | Delete todo via trash icon, swipe, or similar | ✅ Implemented | Delete icon with confirmation |
| F6 | Auto-Remove Empty Parents | Recursive cleanup of parents when they become empty | ❌ Not Implemented | Simple delete only |
| F7 | Full Persistence | Persist structure, titles, completion state | ✅ Implemented | Using Hive |
| F8 | Persist Expand/Collapse | Persist expand/collapse states across restarts | ✅ Implemented | Stored in TodoModel |
| F9 | Smooth Interaction | Intuitive and responsive UI | ✅ Implemented | - |

---

## 4. Non-Functional Requirements

| # | Requirement | Description | Status | Notes |
|---|-------------|-------------|--------|-------|
| NF1 | Clean Architecture | Clean, maintainable code with good architecture | ✅ Implemented | Following HunchFlutterDemo pattern |
| NF2 | State Management | Effective state management solution | ✅ Implemented | Riverpod with StateNotifier |
| NF3 | Edge Case Handling | Handle edge cases gracefully (empty list, rapid operations) | ✅ Implemented | Empty state UI, error handling |

---

## 5. Bonus Features

| # | Feature | Description | Status | Notes |
|---|---------|-------------|--------|-------|
| B1 | Checkbox Propagation (Down) | Checking parent checks all children | ❌ Not Implemented | - |
| B2 | Checkbox Propagation (Up) | Parent auto-completes if all children complete | ❌ Not Implemented | - |
| B3 | Persist Expand/Collapse | Remember expand/collapse states | ✅ Implemented | Part of TodoModel |
| B4 | Swipe-to-Delete | Swipe gesture to delete todos | ❌ Not Implemented | - |
| B5 | Undo Snackbar | Undo option after deletion | ❌ Not Implemented | - |
| B6 | Delete Confirmation | Confirmation dialog before deletion | ✅ Implemented | AlertDialog confirmation |
| B7 | Animations | Smooth animations for expand/collapse, list transitions | ❌ Not Implemented | - |
| B8 | Unit Tests | Unit tests for models and business logic | ❌ Not Implemented | - |
| B9 | Widget Tests | Widget tests for UI components | ❌ Not Implemented | - |

---

## 6. Implementation Summary

### Overall Status

| Category | Total | Implemented | Not Implemented | Percentage |
|----------|-------|-------------|-----------------|------------|
| Key Requirements | 10 | 8 | 2 | 80% |
| Functional Requirements | 9 | 7 | 2 | 78% |
| Non-Functional Requirements | 3 | 3 | 0 | 100% |
| Bonus Features | 9 | 3 | 6 | 33% |
| **TOTAL** | **31** | **21** | **10** | **68%** |

### What Was Implemented ✅

1. **Core Todo Features**
   - Add top-level todos and sub-todos
   - Delete todos with confirmation dialog
   - Mark todos as complete/incomplete
   - Nested hierarchical display with indentation

2. **UI/UX Features**
   - Expand/collapse parent todos with icons
   - Visual strikethrough for completed todos
   - Empty state display when no todos exist
   - Loading and error state widgets

3. **Architecture & Persistence**
   - Clean architecture following HunchFlutterDemo pattern
   - Riverpod state management with StateNotifier
   - Hive local storage for offline-first persistence
   - Error handling with ErrorStateAdapter pattern

4. **Persistence**
   - Todo structure persists across app restarts
   - Completion state persists
   - Expand/collapse state persists

### What Was NOT Implemented ❌

1. **Edit Functionality**
   - Cannot edit todo titles after creation
   - *Rationale: Time constraint (60-min scope)*

2. **Cascading Delete**
   - Parent is not auto-deleted when all children are removed
   - *Rationale: Complex recursive logic, time constraint*

3. **Checkbox Propagation**
   - Checking parent doesn't check children
   - Children completion doesn't auto-complete parent
   - *Rationale: Bonus feature, time constraint*

4. **Swipe-to-Delete with Undo**
   - No swipe gesture for deletion
   - No undo snackbar functionality
   - *Rationale: Bonus feature, time constraint*

5. **Animations**
   - No animated transitions for expand/collapse
   - No list item animations
   - *Rationale: Bonus feature, time constraint*

6. **Tests**
   - No unit tests
   - No widget tests
   - *Rationale: Bonus feature, time constraint*

---

## 7. Technical Specifications

### Data Model

```dart
@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String title;
  @HiveField(2) bool isCompleted;
  @HiveField(3) bool isExpanded;
  @HiveField(4) List<TodoModel> children;
}
```

### Storage Solution

| Aspect | Choice |
|--------|--------|
| Database | Hive (NoSQL) |
| Storage Type | Local/Offline |
| Data Structure | Nested objects |
| Persistence | Automatic on every change |

### Architecture Pattern

| Layer | Implementation |
|-------|----------------|
| Presentation | ConsumerStatefulWidget, ConsumerWidget |
| State Management | Riverpod StateNotifier + AsyncValue |
| Data | Datasource interface + implementation |
| Storage | HiveService abstraction |
| Error Handling | ErrorStateAdapter pattern |

---

## 8. User Stories

| # | As a... | I want to... | So that... | Status |
|---|---------|--------------|------------|--------|
| US1 | User | See all my todos in a hierarchical list | I can organize tasks by category/parent | ✅ |
| US2 | User | Add a new top-level todo | I can track new tasks | ✅ |
| US3 | User | Add a sub-todo to an existing todo | I can break down tasks into subtasks | ✅ |
| US4 | User | Mark a todo as complete | I can track my progress | ✅ |
| US5 | User | Delete a todo I no longer need | I can keep my list clean | ✅ |
| US6 | User | Expand/collapse parent todos | I can focus on relevant tasks | ✅ |
| US7 | User | Edit a todo's title | I can fix typos or update descriptions | ❌ |
| US8 | User | Have my data persist after closing the app | I don't lose my todos | ✅ |
| US9 | User | See empty parents auto-deleted | My list stays organized automatically | ❌ |
| US10 | User | Check a parent to check all children | I can quickly complete related tasks | ❌ |

---

## 9. Sample UI Reference

```
┌─────────────────────────────────────────┐
│  Nested Todo List                    ⟳  │
├─────────────────────────────────────────┤
│                                         │
│  ▼ ☐ Buy Groceries              [+] [🗑] │
│      ☐ Milk                     [+] [🗑] │
│      ☑ Eggs                     [+] [🗑] │
│      ☐ Bread                    [+] [🗑] │
│                                         │
│  ▶ ☑ Clean House                [+] [🗑] │
│                                         │
│  ☐ Call Mom                     [+] [🗑] │
│                                         │
│                                     [+] │
└─────────────────────────────────────────┘

Legend:
▼ = Expanded (can collapse)
▶ = Collapsed (can expand)
☐ = Unchecked
☑ = Checked (completed)
[+] = Add sub-todo
[🗑] = Delete
```

---

## 10. API Endpoints (If Mock API Needed)

*Not applicable - This is an offline-first application with no network calls.*

---

## 11. Future Enhancements (Out of 60-min Scope)

| Priority | Enhancement | Complexity |
|----------|-------------|------------|
| High | Edit todo functionality | Low |
| High | Cascading delete logic | Medium |
| Medium | Checkbox propagation (bidirectional) | Medium |
| Medium | Swipe-to-delete with undo | Medium |
| Low | Animations and transitions | Low |
| Low | Unit and widget tests | Medium |
| Low | Search/filter functionality | Medium |
| Low | Due dates and reminders | High |
| Low | Multiple todo lists | High |

---

## 12. Acceptance Criteria

### Must Pass (Core Requirements)

- [x] App launches without errors
- [x] Can add a top-level todo
- [x] Can add a sub-todo to any todo
- [x] Can mark todos as complete/incomplete
- [x] Can delete todos
- [x] Can expand/collapse parent todos
- [x] Data persists after app restart
- [x] Clean architecture is followed

### Should Pass (Functional Requirements)

- [x] Hierarchical display with visual indentation
- [x] Expand/collapse icons visible
- [x] Empty state shown when no todos
- [x] Error states handled gracefully
- [ ] Edit functionality available
- [ ] Cascading delete works

### Nice to Have (Bonus Features)

- [ ] Checkbox propagation works
- [ ] Swipe-to-delete available
- [ ] Undo snackbar shown
- [x] Delete confirmation dialog shown
- [x] Expand/collapse state persisted
- [ ] Smooth animations present
- [ ] Tests written

---

*Document Version: 1.0*  
*Created: January 2026*  
*Project: nested_todo_app*
