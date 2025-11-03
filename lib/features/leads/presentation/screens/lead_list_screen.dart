import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/lead_provider.dart';
import 'create_lead_screen.dart';
import '../../domain/entities/leads_entity.dart';
import '../../../tasks/presentation/screen/create_tasks_screen.dart';
import 'package:go_router/go_router.dart';
class LeadListScreen extends ConsumerStatefulWidget {
  const LeadListScreen({super.key});

  @override
  ConsumerState<LeadListScreen> createState() => _LeadListScreenState();
}

class _LeadListScreenState extends ConsumerState<LeadListScreen> {
  String _search = '';
  String? _statusFilter;
  final TextEditingController _searchCtrl = TextEditingController();
  final List<String> _statusOptions = [
    'All',
    'Open',
    'Contacted',
    'Qualified',
    'Lost',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LeadEntity> _applyFilters(List<LeadEntity> leads) {
    var filtered = leads.toList(growable: true);

    if (_statusFilter != null && _statusFilter != 'All') {
      filtered = filtered
          .where((l) => l.status == _statusFilter)
          .toList(growable: true);
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where((l) {
            return l.name.toLowerCase().contains(q) ||
                (l.company?.toLowerCase().contains(q) ?? false) ||
                (l.email?.toLowerCase().contains(q) ?? false);
          })
          .toList(growable: true);
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> _openCreateLead() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateLeadScreen()));
  }

  void _confirmDelete(LeadEntity lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lead?'),
        content: Text('Are you sure you want to delete "${lead.name}"?'),
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

    if (confirmed == true) {
      await ref.read(leadsProvider.notifier).removeLeadAsync(lead.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lead deleted')));
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(leadsProvider);
    final filtered = _applyFilters(leads);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to dashboard",
          onPressed: () {
            context.go('/dashboard');
          },
        ),
        title: const Text('Leads'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search name, company or email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter ?? 'All',
                      items: _statusOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _statusFilter = (v == 'All') ? null : v;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(leadsProvider.notifier).fetchLeads(),
        child: filtered.isEmpty
            ? _emptyState()
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final lead = filtered[idx]; // LeadEntity
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      onTap: () => _showLeadDetails(
                        context,
                        lead,
                        onEdit: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateLeadScreen(editLead: lead),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(lead),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      leading: _statusDot(lead.status),
                      title: Text(
                        lead.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lead.company != null && lead.company!.isNotEmpty)
                            Text(lead.company!),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (lead.assignedTo != null)
                                Text(
                                  'Assigned: ${lead.assignedTo!}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(lead.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'delete') {
                            _confirmDelete(lead);
                          }
                          if (val == 'view') {
                            _showLeadDetails(
                              context,
                              lead,
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreateLeadScreen(editLead: lead),
                                  ),
                                );
                              },
                              onDelete: () => _confirmDelete(lead),
                            );
                          }
                          if (val == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateLeadScreen(editLead: lead),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'view', child: Text('View')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateLead,
        icon: const Icon(Icons.add),
        label: const Text('Add Lead'),
      ),
    );
  }

  void _showLeadDetails(
    BuildContext context,
    LeadEntity lead, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          final Color statusColor;
          switch (lead.status.toLowerCase()) {
            case 'contacted':
              statusColor = const Color(0xFFF59E0B);
              break;
            case 'qualified':
              statusColor = const Color(0xFF10B981);
              break;
            case 'lost':
              statusColor = const Color(0xFFEF4444);
              break;
            default:
              statusColor = const Color(0xFF3B82F6);
          }

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).toInt()),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Header with status
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.name,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(
                                      (0.1 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.label_important_outline,
                                        size: 18,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        lead.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 28),
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Info cards
                      if (lead.company?.isNotEmpty == true) ...[
                        _buildInfoCard(
                          'Company',
                          lead.company!,
                          Icons.business,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              'Email',
                              (lead.email?.trim().isNotEmpty ?? false)
                                  ? lead.email!
                                  : '—',
                              Icons.email_outlined,
                              Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              'Phone',
                              (lead.phone?.trim().isNotEmpty ?? false)
                                  ? lead.phone!
                                  : '—',
                              Icons.phone_outlined,
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),

                      if ((lead.website?.isNotEmpty ?? false) ||
                          (lead.assignedTo?.isNotEmpty ?? false) ||
                          (lead.source?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (lead.website?.isNotEmpty == true)
                              Expanded(
                                child: _buildInfoCard(
                                  'Website',
                                  lead.website!,
                                  Icons.public,
                                  Colors.purple,
                                ),
                              ),
                            if (lead.website?.isNotEmpty == true &&
                                (lead.assignedTo?.isNotEmpty == true ||
                                    lead.source?.isNotEmpty == true))
                              const SizedBox(width: 12),
                            if (lead.assignedTo?.isNotEmpty == true)
                              Expanded(
                                child: _buildInfoCard(
                                  'Assigned',
                                  lead.assignedTo!,
                                  Icons.person,
                                  Colors.cyan,
                                ),
                              ),
                            if (lead.assignedTo?.isNotEmpty == true &&
                                (lead.source?.isNotEmpty == true))
                              const SizedBox(width: 12),
                            if (lead.source?.isNotEmpty == true)
                              Expanded(
                                child: _buildInfoCard(
                                  'Source',
                                  lead.source!,
                                  Icons.source_outlined,
                                  Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      _buildInfoCard(
                        'Created',
                        _formatDate(lead.createdAt),
                        Icons.calendar_today,
                        Colors.green,
                      ),

                      if (lead.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            lead.description!,
                            style: TextStyle(
                              height: 1.6,
                              fontSize: 15,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],

                      if (lead.tags.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: lead.tags
                              .map(
                                (t) => Chip(
                                  label: Text(t),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                elevation: 0,
                              ),
                              onPressed: onEdit,
                              icon: Icon(
                                Icons.edit,
                                size: 20,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              label: Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: Colors.red.shade600,
                                  width: 2,
                                ),
                              ),
                              onPressed: onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red.shade600,
                              ),
                              label: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateTaskScreen(
                                linkedId: lead.id,
                                linkedType: 'lead',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_task, size: 20),
                        label: const Text(
                          'Create Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withAlpha((0.8 * 255).toInt()),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        const Icon(Icons.people_alt_outlined, size: 72, color: Colors.grey),
        const SizedBox(height: 12),
        const Center(
          child: Text('No leads found', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add new lead'),
            onPressed: _openCreateLead,
          ),
        ),
      ],
    );
  }

  Widget _statusDot(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'contacted':
        color = Colors.orange;
        break;
      case 'qualified':
        color = Colors.green;
        break;
      case 'lost':
        color = Colors.red;
        break;
      default:
        color = Colors.blueGrey;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
