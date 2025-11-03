import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/tasks_providers.dart';

class SubtaskItemWidget extends ConsumerStatefulWidget {
  final TaskEntity subtask;

  const SubtaskItemWidget({super.key, required this.subtask});

  @override
  ConsumerState<SubtaskItemWidget> createState() => _SubtaskItemWidgetState();
}

class _SubtaskItemWidgetState extends ConsumerState<SubtaskItemWidget> {
  bool _isEditing = false;
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.subtask.title);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) return;

    final newTitle = _textController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.subtask.title) {
      final updatedSubtask = widget.subtask.copyWith(title: newTitle);
      await ref
          .read(tasksProvider.notifier)
          .updateTask(widget.subtask.id, updatedSubtask);
    }
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _deleteSubtask() async {
    await ref.read(tasksProvider.notifier).removeTask(widget.subtask.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subtask deleted'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.subtask.status == TaskStatus.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: isDone,
            onChanged: (v) {
              final newStatus = (v == true) ? TaskStatus.completed : TaskStatus.pending;
              final updatedSubtask = widget.subtask.copyWith(
                status: newStatus,
                completedAt: v == true ? DateTime.now() : null,
              );
              ref.read(tasksProvider.notifier).updateTask(widget.subtask.id, updatedSubtask);
            },
          ),
          title: _isEditing
              ? TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveChanges(),
                  onTapOutside: (_) => _saveChanges(),
                )
              : Text(
                  widget.subtask.title,
                  style: TextStyle(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
          trailing: _isEditing
              ? IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveChanges,
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _startEditing();
                    } else if (value == 'delete') {
                      _deleteSubtask();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class InlineAddSubtaskWidget extends ConsumerStatefulWidget {
  final TaskEntity parentTask;
  final VoidCallback onCancel;

  const InlineAddSubtaskWidget({super.key, required this.parentTask, required this.onCancel});

  @override
  ConsumerState<InlineAddSubtaskWidget> createState() => _InlineAddSubtaskWidgetState();
}

class _InlineAddSubtaskWidgetState extends ConsumerState<InlineAddSubtaskWidget> {
  final _controller = TextEditingController();

  Future<void> _createSubtask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final newSubtask = TaskEntity(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      parentId: widget.parentTask.id,
      linkedId: widget.parentTask.linkedId,
      linkedType: widget.parentTask.linkedType,
      createdAt: DateTime.now(),
    );

    await ref.read(tasksProvider.notifier).addTask(newSubtask);
    _controller.clear();
    widget.onCancel(); // Close the input field after creation
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Add a subtask...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _createSubtask(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _createSubtask,
            tooltip: 'Save Subtask',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: widget.onCancel,
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}
