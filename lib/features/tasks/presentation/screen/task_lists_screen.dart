import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/tasks_providers.dart';
import 'create_tasks_screen.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/task_card_widget.dart';
import 'package:go_router/go_router.dart';
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _query = '';
  String _filter = 'All'; // All, Today, Upcoming, Completed
  String? _moduleFilter;
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<TaskEntity> _listItems = [];

  @override
  void initState() {
    super.initState();
    _listItems = _applyFilters(ref.read(tasksProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onRemove(TaskEntity task) {
    final index = _listItems.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      // Remove the item from the local list and capture it.
      final removedItem = _listItems.removeAt(index);
      // Tell the AnimatedList to animate the removal, providing a builder
      // that uses the captured 'removedItem'.
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => AnimatedListItem(
          animation: animation,
          child: TaskCardWidget(
            task: removedItem,
          ), // No onRemove needed for the animating widget
        ),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    final task = _listItems[index];
    return AnimatedListItem(
      animation: animation,
      child: TaskCardWidget(task: task, onRemove: _onRemove),
    );
  }

  // Update type to TaskEntity
  List<TaskEntity> _applyFilters(List<TaskEntity> tasks) {
    var list = tasks;

    if (_moduleFilter != null) {
      list = list.where((t) => t.linkedType == _moduleFilter).toList();
    }

    final q = _query.toLowerCase();
    list = list.where((t) {
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          (t.assigneeName?.toLowerCase().contains(q) ?? false) ||
          (t.tags.join(' ').toLowerCase().contains(q));
    }).toList();

    final now = DateTime.now();
    if (_filter == 'Today') {
      list = list
          .where(
            (t) =>
                t.dueDate != null &&
                t.dueDate!.year == now.year &&
                t.dueDate!.month == now.month &&
                t.dueDate!.day == now.day,
          )
          .toList();
    } else if (_filter == 'Upcoming') {
      list = list
          .where(
            (t) =>
                t.dueDate != null &&
                t.dueDate!.isAfter(now) &&
                t.status != TaskStatus.completed,
          )
          .toList();
    } else if (_filter == 'Completed') {
      list = list.where((t) => t.status == TaskStatus.completed).toList();
    }

    // IMPORTANT: Only show top-level tasks in the final list. Subtasks are handled by the TaskCardWidget.
    list = list.where((t) => t.parentId == null).toList();

    list.sort((a, b) {
      final da = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<TaskEntity>>(tasksProvider, (previous, current) {
      final oldFiltered = _applyFilters(previous ?? []);
      final newFiltered = _applyFilters(current);

      // Find items to remove
      final toRemove = oldFiltered.where((task) => !newFiltered.any((t) => t.id == task.id)).toList();
      for (final task in toRemove) {
        final index = _listItems.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final removedItem = _listItems.removeAt(index);
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => AnimatedListItem(
              animation: animation,
              child: TaskCardWidget(task: removedItem, onRemove: _onRemove),
            ),
          );
        }
      }

      // Find items to add
      final toAdd = newFiltered.where((task) => !_listItems.any((t) => t.id == task.id)).toList();
      for (final task in toAdd) {
        final index = newFiltered.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _listItems.insert(index, task);
          _listKey.currentState?.insertItem(index);
        }
      }
    });

    // This watch is just to trigger a rebuild when filters change.
    ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to dashboard",
          onPressed: () {
            context.go('/dashboard');
          },
        ),
        title: const Text('Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _query = '';
                                      _listItems = _applyFilters(ref.read(tasksProvider));
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() {
                          _query = v.trim();
                          _listItems = _applyFilters(ref.read(tasksProvider));
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['All', 'Today', 'Upcoming', 'Completed'].map((
                    label,
                  ) {
                    final active = _filter == label;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: active
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardColor,
                            foregroundColor: active ? Colors.white : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => setState(() {
                            _filter = label;
                            _listItems = _applyFilters(ref.read(tasksProvider));
                          }),
                          child: Text(label),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['All', 'lead', 'project'].map((label) {
                    final isSelected = (_moduleFilter ?? 'All') == label;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(label[0].toUpperCase() + label.substring(1)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _moduleFilter = selected ? label : null;
                            if (_moduleFilter == 'All') _moduleFilter = null;
                             _listItems = _applyFilters(ref.read(tasksProvider));
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tasksProvider.notifier).fetchTasks(),
        child: _listItems.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const Center(child: Text('No tasks found')),
                ],
              )
            : AnimatedList(
                key: _listKey,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                initialItemCount: _listItems.length,
                itemBuilder: (ctx, idx, animation) =>
                    _buildAnimatedItem(context, idx, animation),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
    );
  }
}
