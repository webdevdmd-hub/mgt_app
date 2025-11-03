import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_entity.dart';
import '../providers/project_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  final ProjectEntity? editProject;

  const CreateProjectScreen({super.key, this.editProject});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _clientCtrl = TextEditingController();
  final TextEditingController _leadIdCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController();
  final TextEditingController _assignedTeamCtrl = TextEditingController();
  final TextEditingController _projectManagerCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  String _status = 'Ongoing';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  bool _isSaving = false;

  final List<String> _statusOptions = [
    'Ongoing',
    'Completed',
    'On Hold',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.editProject;
    if (p != null) {
      _nameCtrl.text = p.name;
      _clientCtrl.text = p.clientName;
      _leadIdCtrl.text = p.leadId;
      _descriptionCtrl.text = p.description;
      _status = p.status;
      _startDate = p.startDate;
      _endDate = p.endDate;
      _budgetCtrl.text = p.budget?.toString() ?? '';
      _assignedTeamCtrl.text = p.assignedTeam ?? '';
      _projectManagerCtrl.text = p.projectManager ?? '';
      _remarksCtrl.text = p.remarks ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _leadIdCtrl.dispose();
    _descriptionCtrl.dispose();
    _budgetCtrl.dispose();
    _assignedTeamCtrl.dispose();
    _projectManagerCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix errors before submitting')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final budget = double.tryParse(_budgetCtrl.text.trim());
    final project = ProjectEntity(
      id: widget.editProject?.id ?? '',
      name: _nameCtrl.text.trim(),
      clientName: _clientCtrl.text.trim(),
      leadId: _leadIdCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      budget: budget,
      assignedTeam: _assignedTeamCtrl.text.trim().isEmpty
          ? null
          : _assignedTeamCtrl.text.trim(),
      projectManager: _projectManagerCtrl.text.trim().isEmpty
          ? null
          : _projectManagerCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
    );

    final notifier = ref.read(projectsProvider.notifier);

    try {
      if (widget.editProject != null) {
        await notifier.updateProjectAsync(project);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
      } else {
        await notifier.addProjectAsync(project);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully')),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(project);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save project: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editProject != null ? 'Edit Project' : 'Create Project',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildStyledTextField(
                  _nameCtrl,
                  'Project Name',
                  true,
                  Icons.business,
                ),
                const SizedBox(height: 20),
                _buildStyledTextField(
                  _clientCtrl,
                  'Client Name',
                  true,
                  Icons.person,
                ),
                const SizedBox(height: 20),
                _buildStyledTextField(
                  _leadIdCtrl,
                  'Lead ID (Optional)',
                  false,
                  Icons.link,
                ),
                const SizedBox(height: 20),
                _buildStyledTextField(
                  _descriptionCtrl,
                  'Description',
                  false,
                  Icons.description,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                _buildDropdown(
                  'Status',
                  _status,
                  _statusOptions,
                  (v) => setState(() => _status = v ?? _status),
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 20),
                _buildDatePickerTile('Start Date', _startDate, _pickStartDate),
                const SizedBox(height: 12),
                _buildDatePickerTile('End Date', _endDate, _pickEndDate),
                const SizedBox(height: 20),
                _buildStyledTextField(
                  _budgetCtrl,
                  'Budget',
                  false,
                  Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                _buildStyledTextField(
                  _assignedTeamCtrl,
                  'Assigned Team',
                  false,
                  Icons.group,
                ),
                const SizedBox(height: 20),
                _buildStyledTextField(
                  _projectManagerCtrl,
                  'Project Manager',
                  false,
                  Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildStyledTextField(
                  _remarksCtrl,
                  'Remarks',
                  false,
                  Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    widget.editProject != null
                        ? 'Update Project'
                        : 'Create Project',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for styled textfield
  Widget _buildStyledTextField(
    TextEditingController controller,
    String label,
    bool required,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator:
          validator ??
          (v) => required && (v == null || v.trim().isEmpty)
              ? '$label is required'
              : null,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade300),
        filled: true,
        // Material 3 tonal container look
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }

  // Helper for dropdown with icon
  Widget _buildDropdown(
    String label,
    String selected,
    List<String> options,
    ValueChanged<String?> onChanged, {
    IconData? icon,
  }) {
    // Material 3: use DropdownButtonFormField with rounded/tonal field
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      items: options
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(growable: false),
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.deepPurple.shade300)
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.deepPurple.shade300, width: 2),
        ),
      ),
    );
  }

  // Helper for date picker tile
  Widget _buildDatePickerTile(
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            date != null
                ? date.toLocal().toString().split(' ')[0]
                : 'Select Date',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        trailing: const Icon(Icons.calendar_today, color: Colors.deepPurple),
        onTap: onTap,
      ),
    );
  }
}
