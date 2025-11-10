import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_bar/custom_app_bar.dart';
import '../../../../shared/widgets/navigation/custom_drawer.dart';
import '../../../../shared/widgets/status/status_badge.dart';
import '../../../../shared/widgets/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/glassmorphic_card.dart';
import '../../../../shared/widgets/cards/horizontal_card_scroller.dart';
import '../../../../shared/widgets/cards/card_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final filteredCountsProvider = StreamProvider.family<int, Map<String, String>>((ref, args) {
  final collection = args['collection']!;
  final role = args['role']!;
  final uid = args['uid']!;

  Query query = FirebaseFirestore.instance.collection(collection);

  // Role-based filtering:
  // - Sales executives see only items assigned to them
  // - Sales managers see items they created
  // - Admins see everything
  if (role.toLowerCase() == 'sales executive') {
    query = query.where('assignedTo', isEqualTo: uid);
  } else if (role.toLowerCase() == 'sales manager') {
    query = query.where('createdBy', isEqualTo: uid);
  }
  // Admin sees all (no filter)

  return query.snapshots().map((s) => s.size);
});

String _formatDate(DateTime dt) {
  const months = [
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
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
// ...existing code...

// Helper to safely parse Firestore dates
DateTime? _toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

final recentActivityProvider =
    StreamProvider.family<List<Map<String, dynamic>>, Map<String, String>>(
        (ref, args) {
  final role = args['role']!;
  final uid = args['uid']!;

  Query<Map<String, dynamic>> leadsQuery = FirebaseFirestore.instance
      .collection('leads')
      .orderBy('createdAt', descending: true)
      .limit(10);

  Query<Map<String, dynamic>> projectsQuery = FirebaseFirestore.instance
      .collection('projects')
      .orderBy('startDate', descending: true)
      .limit(10);

  Query<Map<String, dynamic>> tasksQuery = FirebaseFirestore.instance
      .collection('tasks')
      .orderBy('createdAt', descending: true)
      .limit(10);

  // Role-based filtering:
  // - Sales executives see only items assigned to them
  // - Sales managers see items they created
  // - Admins see everything
  if (role.toLowerCase() == 'sales executive') {
    leadsQuery = leadsQuery.where('assignedTo', isEqualTo: uid);
    projectsQuery = projectsQuery.where('assignedTo', isEqualTo: uid);
    tasksQuery = tasksQuery.where('assignedTo', isEqualTo: uid);
  } else if (role.toLowerCase() == 'sales manager') {
    leadsQuery = leadsQuery.where('createdBy', isEqualTo: uid);
    projectsQuery = projectsQuery.where('createdBy', isEqualTo: uid);
    tasksQuery = tasksQuery.where('createdBy', isEqualTo: uid);
  }
  // Admin sees all (no filter)

  final leads$ = leadsQuery.snapshots().map(
        (s) => s.docs.map((d) {
          final data = d.data();
          return {
            'type': 'lead',
            'title': (data['name'] ?? data['title'] ?? 'Lead').toString(),
            'subtitle': (data['company'] ?? data['email'] ?? '').toString(),
            'status': (data['status'] ?? 'Pending').toString(),
            'createdAt': _toDate(data['createdAt']),
          };
        }).toList(),
      );

  // Projects
  final projects$ = projectsQuery.snapshots().map(
        (s) => s.docs.map((d) {
          final data = d.data();
          // Support clientName or nested client.name, and optional code
          final clientName = (() {
            final c = data['client'];
            if (c is Map && c['name'] != null) {
              return c['name'].toString();
            }
            if (c is String) {
              return c;
            }
            if (data['clientName'] != null) {
              return data['clientName'].toString();
            }
            return '';
          })().trim();

          final code = (data['code'] ?? '').toString().trim();
          final subtitle = [
            clientName,
            code,
          ].where((e) => e.isNotEmpty).join(' • ');

          return {
            'type': 'project',
            'title': (data['name'] ?? data['title'] ?? 'Project').toString(),
            'subtitle': subtitle,
            'status': (data['status'] ?? 'Active').toString(),
            'createdAt': _toDate(data['startDate']),
          };
        }).toList(),
      );

  // Tasks
  final tasks$ = tasksQuery.snapshots().map(
        (s) => s.docs.map((d) {
          final data = d.data();
          final isSubtask = data['parentId'] != null;

          // Assignee from various shapes: assignedToName | assigneeName | assignee:{name} | assignee
          final assignee = (() {
            final a =
                data['assignedToName'] ??
                data['assigneeName'] ??
                data['assignee'];
            if (a is Map && a['name'] != null) {
              return a['name'].toString();
            }
            if (a is String) {
              return a;
            }
            return '';
          })().trim();

          // Project from various shapes: project:{name} | project | projectName
          final project = (() {
            final p = data['project'] ?? data['projectName'];
            if (p is Map && p['name'] != null) {
              return p['name'].toString();
            }
            if (p is String) {
              return p;
            }
            return '';
          })().trim();

          final due = _toDate(data['dueDate']);

          // Build subtitle parts
          final parts = <String>[];
          if (assignee.isNotEmpty) parts.add('Assignee: $assignee');
          if (project.isNotEmpty) parts.add('Project: $project');
          if (due != null) parts.add('Due: ${_formatDate(due)}');
          final subtitle = parts.join(' • ');

          return {
            'type': 'task',
            'title':
                (isSubtask ? '[Subtask] ' : '') +
                (data['title'] ?? 'Task').toString(),
            'subtitle': subtitle,
            'status': (data['status'] ?? 'In Progress').toString(),
            'createdAt': _toDate(data['createdAt']),
          };
        }).toList(),
      );

  final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
  List<Map<String, dynamic>> leads = [];
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> tasks = [];

  void emit() {
    final combined = <Map<String, dynamic>>[...leads, ...projects, ...tasks];
    combined.sort((a, b) {
      final da =
          (a['createdAt'] as DateTime?) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db =
          (b['createdAt'] as DateTime?) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    controller.add(combined.take(10).toList());
  }

  final sub1 = leads$.listen((v) {
    leads = v;
    emit();
  });
  final sub2 = projects$.listen((v) {
    projects = v;
    emit();
  });
  final sub3 = tasks$.listen((v) {
    tasks = v;
    emit();
  });

  ref.onDispose(() async {
    await sub1.cancel();
    await sub2.cancel();
    await sub3.cancel();
    await controller.close();
  });

  return controller.stream;
});

class UnifiedDashboardScreen extends ConsumerWidget {
  const UnifiedDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? 'admin';
    final uid = user?.id ?? '';

    final leadsCount = ref.watch(filteredCountsProvider({
      'collection': 'leads',
      'role': role,
      'uid': uid,
    })).maybeWhen(data: (v) => v, orElse: () => null);

    final projectsCount = ref.watch(filteredCountsProvider({
      'collection': 'projects',
      'role': role,
      'uid': uid,
    })).maybeWhen(data: (v) => v, orElse: () => null);

    final tasksCount = ref.watch(filteredCountsProvider({
      'collection': 'tasks',
      'role': role,
      'uid': uid,
    })).maybeWhen(data: (v) => v, orElse: () => null);

    final recentActivities = ref.watch(recentActivityProvider({
      'role': role,
      'uid': uid,
    })).maybeWhen(
          data: (items) => items.map((m) {
            final type = (m['type'] as String?) ?? 'lead';

            // Decide icon/color/prefix based on type
            IconData icon;
            Color color;
            String prefix;
            switch (type) {
              case 'project':
                icon = Icons.folder_outlined;
                color = AppColors.primary;
                prefix = 'Project: ';
                break;
              case 'task':
                icon = Icons.task_outlined;
                color = AppColors.warning;
                prefix = 'Task: ';
                break;
              default:
                icon = Icons.person_add;
                color = AppColors.sales;
                prefix = 'Lead: ';
            }

            return _ActivityItem(
              title: '$prefix${(m['title'] as String?) ?? '—'}',
              subtitle: ((m['subtitle'] as String?)?.isNotEmpty ?? false)
                  ? m['subtitle'] as String
                  : '—',
              time: _formatAgo(m['createdAt'] as DateTime?),
              status:
                  (m['status'] as String?) ??
                  (type == 'task'
                      ? 'In Progress'
                      : type == 'project'
                      ? 'Active'
                      : 'Pending'),
              icon: icon,
              color: color,
            );
          }).toList(),
          orElse: () => <_ActivityItem>[],
        );

    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard'),
      drawer: const CustomDrawer(),
      body: ResponsiveBuilder(
        mobile: _buildMobileLayout(
          context,
          role,
          leadsCount: leadsCount,
          projectsCount: projectsCount,
          tasksCount: tasksCount,
          activities: recentActivities,
        ),
        tablet: _buildTabletLayout(
          context,
          role,
          leadsCount: leadsCount,
          projectsCount: projectsCount,
          tasksCount: tasksCount,
          activities: recentActivities,
        ),
        desktop: _buildDesktopLayout(
          context,
          role,
          leadsCount: leadsCount,
          projectsCount: projectsCount,
          tasksCount: tasksCount,
          activities: recentActivities,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    String role, {
    required int? leadsCount,
    required int? projectsCount,
    required int? tasksCount,
    required List<_ActivityItem> activities,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, role),
          const SizedBox(height: 24),
          _buildStatsCarousel(
            context,
            leadsCount: leadsCount,
            projectsCount: projectsCount,
            tasksCount: tasksCount,
          ),
          const SizedBox(height: 24),
          _buildQuickActions(context, role),
          const SizedBox(height: 24),
          _buildRecentActivity(context, role, activities: activities),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    String role, {
    required int? leadsCount,
    required int? projectsCount,
    required int? tasksCount,
    required List<_ActivityItem> activities,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, role),
          const SizedBox(height: 24),
          _buildStatsCarousel(
            context,
            leadsCount: leadsCount,
            projectsCount: projectsCount,
            tasksCount: tasksCount,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildQuickActions(context, role)),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildRecentActivity(
                  context,
                  role,
                  activities: activities,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    String role, {
    required int? leadsCount,
    required int? projectsCount,
    required int? tasksCount,
    required List<_ActivityItem> activities,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, role),
          const SizedBox(height: 32),
          _buildStatsCarousel(
            context,
            leadsCount: leadsCount,
            projectsCount: projectsCount,
            tasksCount: tasksCount,
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildQuickActions(context, role),
                    if (role == 'admin') ...[const SizedBox(height: 24)],
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildRecentActivity(
                  context,
                  role,
                  activities: activities,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String role) {
    final roleTitle = _getRoleTitle(role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $roleTitle',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _getWelcomeMessage(role),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsCarousel(
    BuildContext context, {
    required int? leadsCount,
    required int? projectsCount,
    required int? tasksCount,
  }) {
    final cardWidth = ResponsiveCardSize.getCardWidth(context);
    final cardHeight = ResponsiveCardSize.getCardHeight(context);

    // Create glassmorphic cards for each stat
    final cards = [
      GlassmorphicCard(
        title: 'Leads',
        count: leadsCount?.toString() ?? '—',
        icon: Icons.person_add_outlined,
        color: AppColors.sales,
        width: cardWidth,
        height: cardHeight,
        onTap: () => GoRouter.of(context).go('/leads'),
      ),
      GlassmorphicCard(
        title: 'Projects',
        count: projectsCount?.toString() ?? '—',
        icon: Icons.folder_outlined,
        color: AppColors.primary,
        width: cardWidth,
        height: cardHeight,
        onTap: () => GoRouter.of(context).go('/projects'),
      ),
      GlassmorphicCard(
        title: 'Tasks',
        count: tasksCount?.toString() ?? '—',
        icon: Icons.task_outlined,
        color: AppColors.warning,
        width: cardWidth,
        height: cardHeight,
        onTap: () => GoRouter.of(context).go('/tasks'),
      ),
    ];

    return HorizontalCardList(
      cards: cards,
      cardHeight: cardHeight + 30, // Add extra height to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    String role, {
    required List<_ActivityItem> activities,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6),
            isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (context, index) => Divider(
                  height: 24,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            activity.color.withValues(alpha: 0.2),
                            activity.color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: activity.color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        activity.icon,
                        color: activity.color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          activity.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(
                              status: StatusTypeExtension.fromString(
                                activity.status,
                              ),
                              showIcon: false,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              activity.time,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String role) {
    final actions = _getActionsForRole(context, role);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6),
            isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final action = actions[index];
                return InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.7),
                          isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.white.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                action.color.withValues(alpha: 0.2),
                                action.color.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: action.color.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            action.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'estimation':
        return 'Estimator';
      case 'accounts':
        return 'Accountant';
      case 'store':
        return 'Store Manager';
      case 'production':
        return 'Production Manager';
      case 'delivery':
        return 'Delivery Manager';
      case 'marketing':
        return 'Marketing Manager';
      case 'sales':
        return 'Sales Person';
      default:
        return 'User';
    }
  }

  String _getWelcomeMessage(String role) {
    switch (role) {
      case 'admin':
        return 'Complete system overview and management';
      case 'estimation':
        return 'Here\'s your enquiries and quotations';
      case 'accounts':
        return 'Review your pending invoices and payments';
      case 'store':
        return 'Manage materials and inventory';
      case 'production':
        return 'Track your production tasks';
      case 'delivery':
        return 'View scheduled deliveries';
      case 'marketing':
        return 'Your campaigns and creative tasks';
      case 'sales':
        return 'Your leads and customer interactions';
      default:
        return 'Welcome to your dashboard';
    }
  }

  List<_QuickAction> _getActionsForRole(BuildContext context, String role) {
    final allActions = [
      _QuickAction(
        title: 'View Leads',
        icon: Icons.people_outline,
        color: AppColors.sales,
        onTap: () => GoRouter.of(context).go('/leads'),
      ),
      _QuickAction(
        title: 'View Projects',
        icon: Icons.folder_outlined,
        color: AppColors.primary,
        onTap: () => GoRouter.of(context).go('/projects'),
      ),
      _QuickAction(
        title: 'View Tasks',
        icon: Icons.task_outlined,
        color: AppColors.warning,
        onTap: () => GoRouter.of(context).go('/tasks'),
      ),
    ];

    if (role == 'admin') {
      return [
        ...allActions,
        _QuickAction(
          title: 'User Management',
          icon: Icons.verified_user_outlined,
          color: AppColors.admin,
          onTap: () => GoRouter.of(context).go('/user-management'),
        ),
        // _QuickAction(
        //   title: 'Settings',
        //   icon: Icons.settings_outlined,
        //   color: AppColors.textSecondary,
        //   onTap: () => GoRouter.of(context).go('/settings'),
        // ),
      ];
    }
    return allActions;
  }

  String _formatAgo(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// Helper Classes
class _ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final IconData icon;
  final Color color;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.icon,
    required this.color,
  });
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

