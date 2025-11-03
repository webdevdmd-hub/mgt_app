import 'package:flutter/material.dart';
import 'package:mgt_app/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Center(
                child: Text(
                  'DMD APP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/dashboard',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.folder_open_outlined,
                    label: 'Projects',
                    route: '/projects',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    label: 'Leads',
                    route: '/leads',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.task_outlined,
                    label: 'Tasks',
                    route: '/tasks',
                  ),
                  // _buildNavItem(
                  //   context,
                  //   icon: Icons.receipt_long_outlined,
                  //   label: 'Invoices',
                  //   route: '/invoices',
                  // ),
                  // _buildNavItem(
                  //   context,
                  //   icon: Icons.settings_outlined,
                  //   label: 'Settings',
                  //   route: '/settings',
                  // ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text('Admin Panel'),
                    onTap: () => GoRouter.of(context).go('/admin'),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                // Close drawer and sign out (avoid using BuildContext after await)
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                try {
                  await fb.FirebaseAuth.instance.signOut();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Signed out')),
                  );
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIX: Update _buildNavItem to use GoRouter for navigation
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    // Check if the current route matches the item's route
    // Using GoRouter's route state to check the current location
    final bool isSelected =
        GoRouter.of(context).routeInformationProvider.value.uri.path == route;
    final textColor = isSelected ? AppColors.primary : Colors.black87;
    final iconColor = isSelected ? AppColors.primary : Colors.black54;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: textColor)),
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }
}
