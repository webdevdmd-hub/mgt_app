import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/unified_dashboard_screen.dart';
import '../../features/leads/presentation/screens/lead_list_screen.dart';
import '../../features/tasks/presentation/screen/task_lists_screen.dart';
import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/admin/presentation/screen/admin_panel_screen.dart';
import '../../features/admin/presentation/screen/user_management_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth to rebuild router on changes
  final authState = ref.watch(authProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authState.status == AuthStatus.loading; // now used
      if (isLoading) return null; // avoid redirects during bootstrap

      final isLoggedIn = currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';

      // Redirect to login if not authenticated
      if (!isLoggedIn &&
          !isLoginRoute &&
          state.matchedLocation != '/forgot-password') {
        return '/login';
      }

      // Redirect to dashboard if already logged in and trying to access login
      if (isLoggedIn && isLoginRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Unified Dashboard - Shows role-based content
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const UnifiedDashboardScreen(),
      ),

      // Leads
      GoRoute(
        path: '/leads',
        builder: (context, state) => const LeadListScreen(),
      ),

      // Tasks
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListScreen(),
      ),
      // Projects
      GoRoute(
        path: "/projects",
        builder: (context, state) => const ProjectListScreen(),
      ),

      //admin
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminPanelScreen(),
        redirect: (context, state) {
          // currentUser is captured above via ref.watch(currentUserProvider)
          // avoid using ?. after a null-check / short-circuit; compute safely:
          final isAdmin =
              currentUser != null && currentUser.role.toLowerCase() == 'admin';
          return isAdmin ? null : '/dashboard';
        },
      ),
      // User Management
      GoRoute(
        path: '/user-management',
        name: 'user-management',
        builder: (ctx, state) => const UserManagementScreen(),
      ),

      // // Invoices
      // GoRoute(
      //   path: '/invoices',
      //   builder: (context, state) => const InvoiceListScreen(),
      // ),

      // Settings
      // GoRoute(
      //   path: '/settings',
      //   builder: (context, state) => const SettingsScreen(),
      // ),

      // // Enquiry Routes
      // GoRoute(
      //   path: '/enquiries',
      //   name: 'enquiries',
      //   builder: (context, state) => const EnquiryListScreen(),
      // ),
      // GoRoute(
      //   path: '/enquiries/create',
      //   name: 'create-enquiry',
      //   builder: (context, state) => const CreateEnquiryScreen(),
      // ),
      // GoRoute(
      //   path: '/enquiries/:id',
      //   name: 'enquiry-details',
      //   builder: (context, state) {
      //     final id = state.pathParameters['id']!;
      //     return EnquiryDetailsScreen(enquiryId: id);
      //   },
      // ),

      // // Task Routes
      // GoRoute(
      //   path: '/tasks',
      //   name: 'tasks',
      //   builder: (context, state) => const TaskBoardScreen(),
      // ),
      // GoRoute(
      //   path: '/tasks/:id',
      //   name: 'task-details',
      //   builder: (context, state) {
      //     final id = state.pathParameters['id']!;
      //     return TaskDetailsScreen(taskId: id);
      //   },
      // ),

      // // Project Routes
      // GoRoute(
      //   path: '/projects',
      //   name: 'projects',
      //   builder: (context, state) => const ProjectListScreen(),
      // ),
      // GoRoute(
      //   path: '/projects/:id',
      //   name: 'project-details',
      //   builder: (context, state) {
      //     final id = state.pathParameters['id']!;
      //     return ProjectDetailsScreen(projectId: id);
      //   },
      // ),

      // // Estimation Routes
      // GoRoute(
      //   path: '/quotation/:enquiryId',
      //   name: 'quotation-preparation',
      //   builder: (context, state) {
      //     final enquiryId = state.pathParameters['enquiryId']!;
      //     return QuotationPreparationScreen(enquiryId: enquiryId);
      //   },
      // ),

      // // Accounts Routes
      // GoRoute(
      //   path: '/accounts/review/:projectId',
      //   name: 'accounts-review',
      //   builder: (context, state) {
      //     final projectId = state.pathParameters['projectId']!;
      //     return AccountsReviewScreen(projectId: projectId);
      //   },
      // ),

      // // Store Routes
      // GoRoute(
      //   path: '/store/materials/:projectId',
      //   name: 'material-management',
      //   builder: (context, state) {
      //     final projectId = state.pathParameters['projectId']!;
      //     return MaterialManagementScreen(projectId: projectId);
      //   },
      // ),

      // // Production Routes
      // GoRoute(
      //   path: '/production/manage/:projectId',
      //   name: 'production-management',
      //   builder: (context, state) {
      //     final projectId = state.pathParameters['projectId']!;
      //     return ProductionManagementScreen(projectId: projectId);
      //   },
      // ),

      // // Delivery Routes
      // GoRoute(
      //   path: '/delivery/manage/:projectId',
      //   name: 'delivery-management',
      //   builder: (context, state) {
      //     final projectId = state.pathParameters['projectId']!;
      //     return DeliveryManagementScreen(projectId: projectId);
      //   },
      // ),

      // // Marketing Routes
      // GoRoute(
      //   path: '/marketing/campaigns',
      //   name: 'campaign-management',
      //   builder: (context, state) => const CampaignManagementScreen(),
      // ),

      // // Notifications
      // GoRoute(
      //   path: '/notifications',
      //   name: 'notifications',
      //   builder: (context, state) => const NotificationsScreen(),
      // ),

      // // Documents
      // GoRoute(
      //   path: '/documents',
      //   name: 'documents',
      //   builder: (context, state) => const DocumentsScreen(),
      // ),

      // // Admin Routes (Only accessible by admin role)
      // GoRoute(
      //   path: '/admin',
      //   name: 'admin-panel',
      //   builder: (context, state) => const AdminPanelScreen(),
      // ),
      // GoRoute(
      //   path: '/admin/users',
      //   name: 'user-management',
      //   builder: (context, state) => const UserManagementScreen(),
      // ),

      // // Reports
      // GoRoute(
      //   path: '/reports',
      //   name: 'reports',
      //   builder: (context, state) => const ReportsScreen(),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
          ],
        ),
      ),
    ),
  );
});
