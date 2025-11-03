import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardRepository {
  Stream<DashboardStats> watchStats();
  Stream<List<Map<String, dynamic>>> watchRecentActivities({
    int limit = 10,
    bool tasksOnly = false,
  });
}

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _db;
  DashboardRepositoryImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<DashboardStats> watchStats() {
    final controller = StreamController<DashboardStats>.broadcast();

    StreamSubscription? s1, s2, s3;
    int? leads, projects, tasks;

    void emit() {
      if (leads != null && projects != null && tasks != null) {
        controller.add(
          DashboardStats(
            leads: leads!,
            projects: projects!,
            tasks: tasks!,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    controller.onListen = () {
      s1 = _db.collection('leads').snapshots().listen((snap) {
        leads = snap.size;
        emit();
      }, onError: controller.addError);
      s2 = _db.collection('projects').snapshots().listen((snap) {
        projects = snap.size;
        emit();
      }, onError: controller.addError);
      s3 = _db.collection('tasks').snapshots().listen((snap) {
        tasks = snap.size;
        emit();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await s1?.cancel();
      await s2?.cancel();
      await s3?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchRecentActivities({
    int limit = 10,
    bool tasksOnly = false,
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    StreamSubscription? sub1, sub2, sub3;
    List<Map<String, dynamic>> leads = [];
    List<Map<String, dynamic>> projects = [];
    List<Map<String, dynamic>> tasks = [];

    void emit() {
      final list = <Map<String, dynamic>>[
        if (!tasksOnly) ...leads,
        if (!tasksOnly) ...projects,
        ...tasks,
      ];
      list.sort((a, b) {
        final da =
            (a['createdAt'] as DateTime?) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            (b['createdAt'] as DateTime?) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      controller.add(list.take(limit).toList());
    }

    controller.onListen = () {
      // Tasks (always included)
      sub3 = _db
          .collection('tasks')
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (s) => s.docs.map((d) {
              final data = d.data();
              final assignee = (() {
                final a =
                    data['assignedToName'] ??
                    data['assigneeName'] ??
                    data['assignee'];
                if (a is Map && a['name'] != null) return a['name'].toString();
                if (a is String) return a;
                return '';
              })().toString().trim();

              final project = (() {
                final p = data['project'] ?? data['projectName'];
                if (p is Map && p['name'] != null) return p['name'].toString();
                if (p is String) return p;
                return '';
              })().toString().trim();

              final due = _toDate(data['dueDate']);
              final priority = (data['priority'] ?? '').toString().trim();

              final parts = <String>[];
              if (assignee.isNotEmpty) parts.add('Assignee: $assignee');
              if (project.isNotEmpty) parts.add('Project: $project');
              if (due != null) parts.add('Due: ${_shortDate(due)}');
              if (priority.isNotEmpty) parts.add('Priority: $priority');
              final subtitle = parts.join(' • ');

              return {
                'type': 'task',
                'title': (data['title'] ?? 'Task').toString(),
                'subtitle': subtitle,
                'status': (data['status'] ?? 'In Progress').toString(),
                'createdAt': _toDate(data['updatedAt'] ?? data['createdAt']),
              };
            }).toList(),
          )
          .listen((v) {
            tasks = v;
            emit();
          }, onError: controller.addError);

      if (!tasksOnly) {
        // Leads
        sub1 = _db
            .collection('leads')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map(
              (s) => s.docs.map((d) {
                final data = d.data();
                return {
                  'type': 'lead',
                  'title': (data['name'] ?? data['title'] ?? 'Lead').toString(),
                  'subtitle': (data['company'] ?? data['email'] ?? '')
                      .toString(),
                  'status': (data['status'] ?? 'Pending').toString(),
                  'createdAt': _toDate(data['createdAt']),
                };
              }).toList(),
            )
            .listen((v) {
              leads = v;
              emit();
            }, onError: controller.addError);

        // Projects
        sub2 = _db
            .collection('projects')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map(
              (s) => s.docs.map((d) {
                final data = d.data();

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
                })().toString().trim();

                final code = (data['code'] ?? '').toString().trim();
                final subtitle = [
                  clientName,
                  code,
                ].where((e) => e.isNotEmpty).join(' • ');

                return {
                  'type': 'project',
                  'title': (data['name'] ?? data['title'] ?? 'Project')
                      .toString(),
                  'subtitle': subtitle,
                  'status': (data['status'] ?? 'Active').toString(),
                  'createdAt': _toDate(data['updatedAt'] ?? data['createdAt']),
                };
              }).toList(),
            )
            .listen((v) {
              projects = v;
              emit();
            }, onError: controller.addError);
      }
    };

    controller.onCancel = () async {
      await sub1?.cancel();
      await sub2?.cancel();
      await sub3?.cancel();
    };

    return controller.stream;
  }

  // Helpers
  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static String _shortDate(DateTime dt) {
    const m = [
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
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}
