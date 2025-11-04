import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leads_entity.dart';
import '../providers/lead_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// A full-screen adder form. It uses the leadsProvider to save the lead.
class CreateLeadScreen extends ConsumerStatefulWidget {
  final LeadEntity? editLead; // use LeadEntity across screens

  const CreateLeadScreen({super.key, this.editLead});

  @override
  ConsumerState<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends ConsumerState<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _positionCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _leadValueCtrl = TextEditingController();
  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _zipCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();

  String _status = 'Open';
  String? _source;
  UserEntity? _assigned;
  List<String> _tags = [];
  String? _country;
  String _defaultLanguage = 'System Default';
  bool _isPublic = false;
  bool _contactedToday = true;
  DateTime _createdAt = DateTime.now();

  final List<String> _statusOptions = [
    'Open',
    'Contacted',
    'Qualified',
    'Lost',
  ];
  final List<String> _sourceOptions = ['Call', 'Mail', 'Walk-in', 'Website'];
  final List<String> _countryOptions = [
    'United Arab Emirates',
    'India',
    'United Kingdom',
  ];
  final List<String> _languageOptions = [
    'System Default',
    'English',
    'Arabic',
    'Hindi',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editLead;
    if (e != null) {
      // prefill from LeadEntity
      _status = e.status;
      _source = e.source ?? _source;
      _tags = List<String>.from(e.tags);
      _nameCtrl.text = e.name;
      _positionCtrl.text = e.position ?? '';
      _emailCtrl.text = e.email ?? '';
      _websiteCtrl.text = e.website ?? '';
      _phoneCtrl.text = e.phone ?? '';
      _leadValueCtrl.text = e.leadValue ?? '';
      _companyCtrl.text = e.company ?? '';
      _addressCtrl.text = e.address ?? '';
      _cityCtrl.text = e.city ?? '';
      _stateCtrl.text = e.state ?? '';
      _country = e.country ?? _country;
      _zipCtrl.text = e.zip ?? '';
      _defaultLanguage = e.defaultLanguage ?? _defaultLanguage;
      _descriptionCtrl.text = e.description ?? '';
      _isPublic = e.isPublic;
      _contactedToday = e.contactedToday;
      _createdAt = e.createdAt;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _positionCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    _leadValueCtrl.dispose();
    _companyCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _tags = [..._tags, t];
      _tagCtrl.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((x) => x != tag).toList();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix errors in the form')),
      );
      return;
    }

    final id =
        widget.editLead?.id ?? 'lead_${DateTime.now().millisecondsSinceEpoch}';

    // Build the domain entity used by providers
    final currentUser = ref.read(currentUserProvider);

    // Build the domain entity used by providers
    final entity = LeadEntity(
      id: id,
      status: _status,
      source: _source,
      assignedTo: _assigned?.name,
      tags: _tags,
      name: _nameCtrl.text.trim(),
      position: _positionCtrl.text.trim().isEmpty
          ? null
          : _positionCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      leadValue: _leadValueCtrl.text.trim().isEmpty
          ? null
          : _leadValueCtrl.text.trim(),
      company: _companyCtrl.text.trim().isEmpty
          ? null
          : _companyCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      country: _country,
      zip: _zipCtrl.text.trim().isEmpty ? null : _zipCtrl.text.trim(),
      defaultLanguage: _defaultLanguage,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      isPublic: _isPublic,
      contactedToday: _contactedToday,
      createdAt:
          widget.editLead?.createdAt ??
          _createdAt, // use the field to fix warning
      createdBy: widget.editLead?.createdBy ?? currentUser?.id,
    );

    final notifier = ref.read(leadsProvider.notifier);
    if (widget.editLead != null) {
      notifier.updateLeadAsync(entity);
    } else {
      notifier.addLeadAsync(entity);
    }

    Navigator.of(context).pop(entity); // return LeadEntity
  }

  Widget _buildTextField(
    TextEditingController ctrl, {
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  // Fix for DropdownButtonFormField value when null or empty string (to avoid exception)
  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? hint,
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value != null && value.isNotEmpty && items.contains(value)
          ? value
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      hint: hint != null ? Text(hint) : null,
      items: items
          .map((it) => DropdownMenuItem(value: it, child: Text(it)))
          .toList(),
      onChanged: onChanged,
      validator: (v) {
        if (required && (v == null || v.isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildLeadValueField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _leadValueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Lead value',
              border: OutlineInputBorder(),
              isDense: true,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'AED',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editLead != null ? 'Edit Lead' : 'Add new lead'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Status row with add button
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Status',
                                items: _statusOptions,
                                value: _status,
                                onChanged: (v) =>
                                    setState(() => _status = v ?? _status),
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 50,
                              width: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () async {
                                  final newStatus = await showDialog<String>(
                                    context: context,
                                    builder: (_) => _AddStatusDialog(),
                                  );
                                  if (newStatus != null &&
                                      newStatus.trim().isNotEmpty) {
                                    setState(() {
                                      _statusOptions.add(newStatus.trim());
                                      _status = newStatus.trim();
                                    });
                                  }
                                },
                                child: const Center(
                                  child: Icon(Icons.add, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Source dropdown without add button (removed duplicate)
                        _buildDropdownField(
                          label: 'Source',
                          items: _sourceOptions,
                          value: _source,
                          onChanged: (v) => setState(() => _source = v),
                          hint: 'Nothing selected',
                          required: true,
                        ),
                        const SizedBox(height: 12),
                        users.when(
                          data: (data) {
                            return DropdownButtonFormField<UserEntity>(
                              initialValue: _assigned,
                              decoration: const InputDecoration(
                                labelText: 'Assigned',
                                border: OutlineInputBorder(),
                                isDense: true,
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              hint: const Text('Nothing selected'),
                              items: data.map((user) {
                                return DropdownMenuItem<UserEntity>(
                                  value: user,
                                  child: Text(user.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _assigned = value;
                                });
                              },
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stackTrace) => const Text('Error loading users'),
                        ),
                        const SizedBox(height: 12),
                        // Tags section...
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.label_outline, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Tags',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final t in _tags)
                                  Chip(
                                    label: Text(t),
                                    onDeleted: () => _removeTag(t),
                                  ),
                                SizedBox(
                                  width: 180,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _tagCtrl,
                                          decoration: const InputDecoration(
                                            hintText: 'Tag',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 10,
                                                ),
                                          ),
                                          onSubmitted: (_) => _addTag(),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed: _addTag,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _nameCtrl,
                          label: 'Name',
                          required: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(_positionCtrl, label: 'Position'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _emailCtrl,
                          label: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(_websiteCtrl, label: 'Website'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _phoneCtrl,
                          label: 'Phone',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildLeadValueField(),
                        const SizedBox(height: 12),
                        _buildTextField(_companyCtrl, label: 'Company'),
                        const SizedBox(height: 12),
                        _buildTextField(_addressCtrl, label: 'Address'),
                        const SizedBox(height: 12),
                        _buildTextField(_cityCtrl, label: 'City'),
                        const SizedBox(height: 12),
                        _buildTextField(_stateCtrl, label: 'State'),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          label: 'Country',
                          items: _countryOptions,
                          value: _country,
                          onChanged: (v) => setState(() => _country = v),
                          hint: 'Nothing selected',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(_zipCtrl, label: 'Zip Code'),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          label: 'Default Language',
                          items: _languageOptions,
                          value: _defaultLanguage,
                          onChanged: (v) => setState(
                            () => _defaultLanguage = v ?? _defaultLanguage,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _isPublic,
                                  onChanged: (v) =>
                                      setState(() => _isPublic = v ?? false),
                                ),
                                const SizedBox(width: 2),
                                const Text('Public'),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _contactedToday,
                                  onChanged: (v) => setState(
                                    () => _contactedToday = v ?? false,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Text('Contacted Today'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              // footer
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Close'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddStatusDialog extends StatefulWidget {
  @override
  State<_AddStatusDialog> createState() => _AddStatusDialogState();
}

class _AddStatusDialogState extends State<_AddStatusDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Status'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Enter new status'),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }
}
