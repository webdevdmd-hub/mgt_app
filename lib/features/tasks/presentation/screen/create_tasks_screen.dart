import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart'; // use domain entity
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../presentation/providers/tasks_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final TaskEntity? editTask; // was: Task? editTask
  final String? linkedId;
  final String? linkedType;
  const CreateTaskScreen({
    super.key,
    this.editTask,
    this.linkedId,
    this.linkedType,
  });

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _tags = TextEditingController();

  UserEntity? _assignee;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.pending;
  DateTime? _due;

  // NEW: timer
  int _timeSpentSec = 0;
  Timer? _timer;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    if (widget.editTask != null) {
      final t = widget.editTask!;
      _title.text = t.title;
      _desc.text = t.description ?? '';
      _tags.text = t.tags.join(', ');
      _priority = t.priority;
      _status = t.status;
      _due = t.dueDate;

      _timeSpentSec = t.timeSpentSec;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _tags.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _due ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple.shade400,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _startTimer() {
    if (_timerRunning) return;
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _timeSpentSec += 1);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _timerRunning = false;
    setState(() {});
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() => _timeSpentSec = 0);
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Get current user for 'createdBy' field
    final currentUser = ref.read(currentUserProvider);

    final id =
        widget.editTask?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}';
    final task = TaskEntity(
      // was: Task(...)
      id: id,
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      assigneeName: _assignee?.name,
      dueDate: _due,
      createdAt: widget.editTask?.createdAt ?? DateTime.now(),
      // Link to module if provided
      linkedId: widget.editTask?.linkedId ?? widget.linkedId,
      linkedType: widget.editTask?.linkedType ?? widget.linkedType,
      createdBy: widget.editTask?.createdBy ?? currentUser?.id,

      timeSpentSec: _timeSpentSec,
      priority: _priority,
      status: _status,
      tags: _tags.text.trim().isEmpty
          ? const []
          : _tags.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
      // linkedId, linkedType, department, attachments, createdBy, notes can be added later if needed
    );

    final notifier = ref.read(tasksProvider.notifier);
    if (widget.editTask != null) {
      notifier.updateTask(task.id, task);
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Task updated successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      notifier.addTask(task);
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Task created successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    navigator.pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.editTask != null ? 'Edit Task' : 'Create New Task',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      _buildSectionLabel('Task Title', true),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _title,
                        hint: 'Enter task title',
                        icon: Icons.title,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),

                      const SizedBox(height: 20),

                      // Description Field
                      _buildSectionLabel('Description', false),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _desc,
                        hint: 'Add task description',
                        icon: Icons.description_outlined,
                        maxLines: 5,
                      ),

                      const SizedBox(height: 20),

                      // Assignee Field
                      _buildSectionLabel('Assignee', false),
                      const SizedBox(height: 8),
                      _buildAssigneeDropdown(),

                      const SizedBox(height: 20),

                      // Priority & Status Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Priority', false),
                                const SizedBox(height: 8),
                                _buildPriorityDropdown(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Status', false),
                                const SizedBox(height: 8),
                                _buildStatusDropdown(),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Due Date
                      _buildSectionLabel('Due Date', false),
                      const SizedBox(height: 8),
                      _buildDueDatePicker(),

                      const SizedBox(height: 16),

                      // Schedule for Tomorrow
                      CheckboxListTile(
                        value: _due != null && _isTomorrow(_due!),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              final now = DateTime.now();
                              _due = DateTime(now.year, now.month, now.day + 1);
                            } else {
                              // If it was set to tomorrow, clear it.
                              // Otherwise, leave it as it was.
                              if (_due != null && _isTomorrow(_due!)) {
                                _due = null;
                              }
                            }
                          });
                        },
                        title: const Text('Schedule for Tomorrow'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 16),

                      // Tags Field
                      _buildSectionLabel('Tags', false),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _tags,
                        hint: 'e.g., urgent, design, backend',
                        icon: Icons.local_offer_outlined,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Separate tags with commas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // NEW: Timer section
                      _buildTimerSection(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.2 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.editTask != null ? Icons.check : Icons.add,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.editTask != null
                                ? 'Update Task'
                                : 'Create Task',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets ---------------------------------------------------------

  Widget _buildSectionLabel(String text, bool required) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade300, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildAssigneeDropdown() {
    final users = ref.watch(usersProvider);
    return users.when(
      data: (data) {
        return DropdownButtonFormField<UserEntity>(
          initialValue: _assignee,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person_outline, color: Colors.deepPurple.shade300, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          hint: const Text('Assign to team member'),
          items: data.map((user) {
            return DropdownMenuItem<UserEntity>(
              value: user,
              child: Text(user.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _assignee = value;
            });
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => const Text('Error loading users'),
    );
  }

  Widget _buildPriorityDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<TaskPriority>(
        initialValue: _priority,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.flag_outlined,
            color: _getPriorityColor(_priority),
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
        dropdownColor: Colors.white,
        items: TaskPriority.values.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(p),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  p.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() => _priority = v ?? _priority),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<TaskStatus>(
        initialValue: _status,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.radio_button_checked,
            color: _getStatusColor(_status),
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
        dropdownColor: Colors.white,
        items: TaskStatus.values.map((s) {
          return DropdownMenuItem(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(s),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(_formatStatus(s), style: const TextStyle(fontSize: 15)),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() => _status = v ?? _status),
      ),
    );
  }

  Widget _buildDueDatePicker() {
    return InkWell(
      onTap: _pickDue,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Colors.deepPurple.shade300,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _due == null ? 'Select due date' : _formatDate(_due!),
                style: TextStyle(
                  fontSize: 15,
                  color: _due == null ? Colors.grey.shade400 : Colors.black87,
                ),
              ),
            ),
            if (_due != null)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                onPressed: () => setState(() => _due = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green.shade400;
      case TaskPriority.medium:
        return Colors.orange.shade400;
      case TaskPriority.high:
        return Colors.red.shade400;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey.shade400;
      case TaskStatus.inProgress:
        return Colors.blue.shade400;
      case TaskStatus.completed:
        return Colors.green.shade400;
    }
  }

  String _formatStatus(TaskStatus status) {
    final str = status.toString().split('.').last;
    if (str == 'inProgress') return 'In Progress';
    return str[0].toUpperCase() + str.substring(1);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isTomorrow(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // NEW: timer UI
  Widget _buildTimerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Timer (time spent)', false),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.black54),
              const SizedBox(width: 12),
              Text(
                _formatDuration(_timeSpentSec),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (!_timerRunning)
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: _startTimer,
                )
              else
                IconButton(
                  icon: const Icon(Icons.pause, color: Colors.orange),
                  onPressed: _pauseTimer,
                ),
              IconButton(
                icon: const Icon(Icons.restart_alt, color: Colors.red),
                onPressed: _resetTimer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
