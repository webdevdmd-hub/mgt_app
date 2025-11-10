import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
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
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtasks = ref.watch(subtasksProvider(task.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9),
            isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: subtasks.isNotEmpty
              ? () => setState(() => _isExpanded = !_isExpanded)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Priority, Title, Status, Menu
                Row(
                  children: [
                    // Priority Indicator
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _priorityColor(task.priority),
                            _priorityColor(task.priority).withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: task.status == TaskStatus.completed
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5))
                                  : null,
                              decoration: task.status == TaskStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (task.description != null && task.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                task.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: task.status == TaskStatus.completed
                              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
                              : [
                                  Colors.grey.withValues(alpha: 0.2),
                                  Colors.grey.withValues(alpha: 0.1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: task.status == TaskStatus.completed
                            ? Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        _statusText(task.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task.status == TaskStatus.completed
                              ? Colors.white
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.black.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    // Menu
                    _buildMenu(context, task, ref),
                  ],
                ),

                // Meta Info Row
                if (task.assignedToName != null || task.dueDate != null || subtasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Assignee
                        if (task.assignedToName != null)
                          _buildInfoChip(
                            icon: Icons.person_outline,
                            label: task.assignedToName!,
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                        // Due Date
                        if (task.dueDate != null)
                          _buildInfoChip(
                            icon: Icons.calendar_today,
                            label: _formatDate(task.dueDate!),
                            color: _isOverdue(task.dueDate!)
                                ? AppColors.error
                                : AppColors.warning,
                            isDark: isDark,
                          ),
                        // Subtasks Count
                        if (subtasks.isNotEmpty)
                          _buildInfoChip(
                            icon: Icons.checklist,
                            label: '${subtasks.where((s) => s.status == TaskStatus.completed).length}/${subtasks.length}',
                            color: AppColors.success,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),

                // Linked Entity
                if (task.linkedType != null && task.linkedId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16),
                    child: LinkedEntityWidget(
                      linkedId: task.linkedId!,
                      linkedType: task.linkedType!,
                    ),
                  ),

                // Tags
                if (task.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: task.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Subtasks
                if (subtasks.isNotEmpty && _isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16),
                    child: Column(
                      children: subtasks.map((subtask) {
                        return SubtaskItemWidget(subtask: subtask);
                      }).toList(),
                    ),
                  ),

                // Expand/Collapse Indicator
                if (subtasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, TaskEntity task, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.6),
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.3),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
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
          await ref.read(tasksProvider.notifier).updateTask(task.id, updated);
        }
        if (v == 'mark_pending') {
          final updated = task.copyWith(
            status: TaskStatus.pending,
            completedAt: null,
          );
          await ref.read(tasksProvider.notifier).updateTask(task.id, updated);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        if (task.status != TaskStatus.completed)
          PopupMenuItem(
            value: 'mark_done',
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.2),
                        AppColors.success.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Mark Completed'),
              ],
            ),
          ),
        if (task.status == TaskStatus.completed)
          PopupMenuItem(
            value: 'mark_pending',
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning.withValues(alpha: 0.2),
                        AppColors.warning.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.replay,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Mark Pending'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withValues(alpha: 0.2),
                      AppColors.error.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  String _statusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays == -1) {
      return 'Yesterday';
    } else if (diff.inDays > 1 && diff.inDays <= 7) {
      return 'In ${diff.inDays} days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now()) &&
        widget.task.status != TaskStatus.completed;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskEntity task,
    void Function(TaskEntity)? onRemove,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onRemove?.call(task);
      await ref.read(tasksProvider.notifier).removeTask(task.id);
    }
  }
}
