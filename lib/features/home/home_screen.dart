import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  final AuthController authController;

  const HomeScreen({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await authController.logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _WelcomeCard(),
          SizedBox(height: 12),
          _QuickActions(),
          SizedBox(height: 12),
          _TodaySnapshot(),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.mobile_friendly, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome back.\nThis mobile app is optimized for quick field operations.',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  icon: Icons.add_task,
                  label: 'New Request',
                  onTap: () {},
                ),
                _ActionChip(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Card',
                  onTap: () {},
                ),
                _ActionChip(
                  icon: Icons.inventory_2,
                  label: 'Stock Check',
                  onTap: () {},
                ),
                _ActionChip(
                  icon: Icons.history,
                  label: 'Recent Activity',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySnapshot extends StatelessWidget {
  const _TodaySnapshot();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Today Snapshot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.pending_actions),
              title: Text('Pending approvals'),
              trailing: Text('—'),
            ),
            ListTile(
              leading: Icon(Icons.local_shipping),
              title: Text('Items issued'),
              trailing: Text('—'),
            ),
            ListTile(
              leading: Icon(Icons.warning_amber),
              title: Text('Low stock alerts'),
              trailing: Text('—'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
