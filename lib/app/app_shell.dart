import 'package:flutter/material.dart';
import '../core/auth/auth_controller.dart';
import '../features/dashboard/dashboard_tab.dart';
import '../features/inventory/inventory_tab.dart';
import '../features/profile/profile_tab.dart';
import '../features/requests/requests_tab.dart';

class AppShell extends StatefulWidget {
  final AuthController authController;

  const AppShell({super.key, required this.authController});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Dashboard',
    'Requests',
    'Inventory',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(authController: widget.authController),
      const RequestsTab(),
      const InventoryTab(),
      ProfileTab(authController: widget.authController),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
