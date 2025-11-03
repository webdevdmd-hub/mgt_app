import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/tasks_providers.dart';
import '../../presentation/screen/create_tasks_screen.dart';
import 'subtask_item_widget.dart';

Future<void> showTaskDetailsBottomSheet(
  BuildContext context,
  String taskId,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Consumer(
            builder: (context, ref, _) => TaskDetailsBottomSheet(
              taskId: taskId,
              scrollController: controller,
            ),
          ),
        ),
      );
    },
  );
}

class TaskDetailsBottomSheet extends ConsumerStatefulWidget {
  final String taskId;
  final ScrollController? scrollController;
  const TaskDetailsBottomSheet({
    super.key,
    required this.taskId,
    this.scrollController,
  });

  @override
  ConsumerState<TaskDetailsBottomSheet> createState() =>
      _TaskDetailsBottomSheetState();
}

class _TaskDetailsBottomSheetState
    extends ConsumerState<TaskDetailsBottomSheet> {
  bool _isAddingSubtask = false;

  @override
  Widget build(BuildContext context) {
    final taskId = widget.taskId;
    final scrollController = widget.scrollController;

    // Rebuild on any task state changes (including timer ticks)
    ref.watch(tasksProvider);

    // Safe lookup via notifier
    final task = ref.read(tasksProvider.notifier).getById(taskId);
    if (task == null) {
      return _NotFound(scrollController: scrollController);
    }

    final running = ref.read(tasksProvider.notifier).isTimerRunning(task.id);

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          task.status,
                        ).withAlpha((0.12 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(task.status),
                        style: TextStyle(
                          color: _statusColor(task.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateTaskScreen(editTask: task),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  Text(
                    task.description!,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                ],

                // Assignee / Priority / Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (task.assigneeName != null)
                      _chip(
                        icon: Icons.person_outline,
                        label: task.assigneeName!,
                        color: Colors.purple,
                      ),
                    _chip(
                      icon: Icons.flag_outlined,
                      label: task.priority
                          .toString()
                          .split('.')
                          .last
                          .toUpperCase(),
                      color: _priorityColor(task.priority),
                    ),
                    if (task.tags.isNotEmpty)
                      _chip(
                        icon: Icons.local_offer_outlined,
                        label: task.tags.join(', '),
                        color: Colors.blueGrey,
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dates row
                Wrap(
                  spacing: 8,
                  children: [
                    if (task.dueDate != null)
                      _dateBadge(
                        icon: Icons.calendar_today,
                        color: Colors.orange,
                        label: _fmtDate(task.dueDate!),
                      ),
                    if (task.completedAt != null)
                      _dateBadge(
                        icon: Icons.stop,
                        color: Colors.indigo,
                        label: _fmtDate(task.completedAt!),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Subtasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _sectionTitle('Subtasks'),
                    if (!_isAddingSubtask)
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _isAddingSubtask = true),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSubtaskList(task.id, ref),

                const SizedBox(height: 18),

                if (_isAddingSubtask) ...[
                  InlineAddSubtaskWidget(
                    parentTask: task,
                    onCancel: () => setState(() => _isAddingSubtask = false),
                  ),
                  const SizedBox(height: 18),
                ],

                // Timer section
                _sectionTitle('Time Spent'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.black54),
                      const SizedBox(width: 12),
                      Text(
                        _formatDuration(task.timeSpentSec),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (!running)
                        IconButton(
                          tooltip: 'Start timer',
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.green,
                          ),
                          onPressed: () => ref
                              .read(tasksProvider.notifier)
                              .startTimer(task.id),
                        )
                      else ...[
                        IconButton(
                          tooltip: 'Pause timer',
                          icon: const Icon(Icons.pause, color: Colors.orange),
                          onPressed: () => ref
                              .read(tasksProvider.notifier)
                              .pauseTimer(task.id),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Stop and edit',
                          icon: const Icon(Icons.stop, color: Colors.red),
                          onPressed: () {
                            ref
                                .read(tasksProvider.notifier)
                                .pauseTimer(task.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateTaskScreen(editTask: task),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateTaskScreen(editTask: task),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                        ),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete task'),
                              content: const Text(
                                'Are you sure you want to delete this task?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            ref.read(tasksProvider.notifier).removeTask(task.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task deleted')),
                              );
                              Navigator.of(context).pop(); // close bottom sheet
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _effectiveShade(color),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBadge({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskList(String parentId, WidgetRef ref) {
    final subtasks = ref.watch(subtasksProvider(parentId));

    if (subtasks.isEmpty) {
      return const Text('No subtasks', style: TextStyle(color: Colors.black54));
    }

    return Column(
      children: subtasks
          .map((subtask) => SubtaskItemWidget(subtask: subtask))
          .toList(),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return Colors.grey.shade700;
      case TaskStatus.inProgress:
        return Colors.blue.shade700;
      case TaskStatus.completed:
        return Colors.green.shade700;
    }
  }

  String _statusLabel(TaskStatus s) {
    final label = s.toString().split('.').last;
    if (label == 'inProgress') return 'In Progress';
    return label[0].toUpperCase() + label.substring(1);
  }

  // Use shade700 for MaterialColor, else return color itself.
  Color _effectiveShade(Color c) {
    if (c is MaterialColor) {
      return c.shade700;
    }
    return c;
  }
}

class _NotFound extends StatelessWidget {
  final ScrollController? scrollController;
  const _NotFound({this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: const [SizedBox(height: 8), Text('Task not found')],
        ),
      ),
    );
  }
}
