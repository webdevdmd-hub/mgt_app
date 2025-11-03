import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/tasks_providers.dart';
import '../screen/create_tasks_screen.dart';
import 'subtask_item_widget.dart';
import 'linked_entity_widget.dart';

class TaskCardWidget extends ConsumerStatefulWidget {
  final TaskEntity task;
  final void Function(TaskEntity)? onRemove;

  const TaskCardWidget({super.key, required this.task, this.onRemove});

  @override
  ConsumerState<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends ConsumerState<TaskCardWidget> {
  bool _isAddingSubtask = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          final subtasks = ref.read(subtasksProvider(task.id));
          if (subtasks.isNotEmpty) setState(() => _isExpanded = !_isExpanded);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              _buildHeader(context, ref, task),

              // New: Start/End, Time Spent and Subtasks summary
              const SizedBox(height: 12),
              _buildMetaRow(ref, task),

              // Linked Info
              if (task.linkedType != null && task.linkedId != null) ...[
                const SizedBox(height: 12),
                LinkedEntityWidget(linkedId: task.linkedId!, linkedType: task.linkedType!),
              ],

              // Details Row
              if (task.assigneeName != null || task.dueDate != null) ...[
                const SizedBox(height: 12),
                _buildDetailsRow(task),
              ],

              // Tags
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTags(task),
              ],



              // Subtasks
              AnimatedCrossFade(
                firstChild: _buildSubtaskList(task.id, ref, task),
                secondChild: Container(),
                crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
              ),

              // Add Subtask Button or Inline Input
              if (task.parentId == null) // Only show on parent tasks
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _isAddingSubtask
                      ? InlineAddSubtaskWidget(
                          parentTask: task,
                          onCancel: () =>
                              setState(() => _isAddingSubtask = false),
                        )
                      : TextButton.icon(
                          onPressed: () =>
                              setState(() => _isAddingSubtask = true),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Subtask'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Private Helper Methods for Building UI Sections ---

  Widget _buildHeader(BuildContext context, WidgetRef ref, TaskEntity task) {
    return Row(
      children: [
        // Priority Indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _priorityColor(task.priority),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _priorityColor(
                  task.priority,
                ).withAlpha((0.3 * 255).round()),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Title
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: task.status == TaskStatus.completed
                  ? Colors.grey.shade600
                  : Colors.black87,
              decoration: task.status == TaskStatus.completed
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: task.status == TaskStatus.completed
                ? LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade200],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: task.status == TaskStatus.completed
                ? [
                    BoxShadow(
                      color: _priorityColor(
                        task.priority,
                      ).withAlpha((0.3 * 255).round()),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            _statusText(task.status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: task.status == TaskStatus.completed
                  ? Colors.white
                  : Colors.grey.shade700,
            ),
          ),
        ),
        // Menu Button
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 40),
          onSelected: (v) async {
            final navigator = Navigator.of(context);
            if (v == 'edit') {
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => CreateTaskScreen(editTask: task),
                ),
              );
            }
            if (v == 'delete') {
              await _confirmDelete(context, ref, task, widget.onRemove);
            }
            if (v == 'mark_done') {
              final updated = task.copyWith(
                status: TaskStatus.completed,
                completedAt: DateTime.now(),
              );
              await ref
                  .read(tasksProvider.notifier)
                  .updateTask(task.id, updated);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mark_done',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18),
                  SizedBox(width: 12),
                  Text('Mark Completed'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaRow(WidgetRef ref, TaskEntity task) {
    final subtasks = ref.watch(subtasksProvider(task.id));
    final completedSubtasks = subtasks
        .where((s) => s.status == TaskStatus.completed)
        .length;

    return Row(
      children: [
        _buildDateChip(task.createdAt, Icons.play_arrow, Colors.blue),
        const SizedBox(width: 8),
        if (task.completedAt != null) ...[
          _buildDateChip(task.completedAt!, Icons.stop, Colors.indigo),
          const SizedBox(width: 8),
        ],
        _buildTimeSpentChip(task),
        const Spacer(),
        if (subtasks.isNotEmpty)
          _buildSubtaskProgressChip(completedSubtasks, subtasks.length),
      ],
    );
  }

  Widget _buildDetailsRow(TaskEntity task) {
    return Row(
      children: [
        if (task.assigneeName != null) ...[
          _buildAssigneeChip(task),
          const SizedBox(width: 8),
        ],
        if (task.dueDate != null) _buildDueDateChip(task),
      ],
    );
  }

  Widget _buildTags(TaskEntity task) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: task.tags.map((tg) {
        final colors = _getTagColor(tg);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors['bg'],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors['dot'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                tg,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors['text'],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubtaskList(String parentId, WidgetRef ref, TaskEntity task) {
    final subtasks = ref.watch(subtasksProvider(parentId));
    if (subtasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...subtasks.map((subtask) => SubtaskItemWidget(subtask: subtask)),
        ],
      ),
    );
  }

  // --- Chip and Badge Widgets ---

  Widget _buildDateChip(DateTime date, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              fontSize: 12,
              // FIX: Use the primary color directly or a predefined dark color
              color: color,
              // OR use a very dark/black color for good contrast:
              // color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSpentChip(TaskEntity task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            _formatDuration(task.timeSpentSec),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskProgressChip(int completed, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checklist, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          Text(
            '$completed/$total',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeChip(TaskEntity task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 14, color: Colors.purple.shade700),
          const SizedBox(width: 6),
          Text(
            task.assigneeName!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip(TaskEntity task) {
    final isOverdue = _isOverdue(task.dueDate!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: isOverdue ? Colors.red.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
            style: TextStyle(
              fontSize: 12,
              color: isOverdue ? Colors.red.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Functions ---

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red.shade600;
      case TaskPriority.medium:
        return Colors.orange.shade700;
      case TaskPriority.low:
        return Colors.green.shade600;
    }
  }

  String _statusText(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskEntity t,
    void Function(TaskEntity)? onRemove,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${t.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      // First, trigger the UI animation if the callback is provided.
      onRemove?.call(t);
      // Then, update the backend and the global state.
      await ref.read(tasksProvider.notifier).removeTask(t.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task deleted')));
      }
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$secs';
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now()) &&
        !_isSameDay(dueDate, DateTime.now());
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, Color> _getTagColor(String tag) {
    final colors = [
      {
        'bg': Colors.teal.shade50,
        'text': Colors.teal.shade700,
        'dot': Colors.teal.shade400,
      },
      {
        'bg': Colors.indigo.shade50,
        'text': Colors.indigo.shade700,
        'dot': Colors.indigo.shade400,
      },
      {
        'bg': Colors.pink.shade50,
        'text': Colors.pink.shade700,
        'dot': Colors.pink.shade400,
      },
      {
        'bg': Colors.amber.shade50,
        'text': Colors.amber.shade700,
        'dot': Colors.amber.shade400,
      },
      {
        'bg': Colors.cyan.shade50,
        'text': Colors.cyan.shade700,
        'dot': Colors.cyan.shade400,
      },
    ];
    final index = tag.hashCode.abs() % colors.length;
    return colors[index];
  }
}
