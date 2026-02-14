import 'package:flutter/material.dart';
import 'super_admin_dashboard.dart';
import 'admin_shell.dart';

/// Shell for Super Admin: bottom navigation (Role Admins, Admin Dashboard).
/// Default on login is Admin Dashboard (Pic 1), not the two-card screen (Pic 2).
class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  /// 0 = Role Admins / two-card screen (Pic 2), 1 = Admin Dashboard (Pic 1).
  /// Start at 1 so Admin Dashboard is default on login.
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _selectedIndex == 1) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            SuperAdminDashboard(),
            AdminShell(),
          ],
        ),
        bottomNavigationBar: _selectedIndex == 1
            ? null
            : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (int index) {
                  setState(() => _selectedIndex = index);
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings),
                    label: 'Role Admins',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Admin Dashboard',
                  ),
                ],
              ),
      ),
    );
  }
}
