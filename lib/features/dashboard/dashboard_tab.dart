import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';

class DashboardTab extends StatefulWidget {
  final AuthController authController;

  const DashboardTab({super.key, required this.authController});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _loading = false;

  // Placeholder values until we connect Django dashboard endpoint in next step
  int pendingApprovals = 0;
  int issuedToday = 0;
  int lowStockAlerts = 0;

  Future<void> _refresh() async {
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 500));
    // Keep placeholders for now; next step we'll call API
    setState(() {
      pendingApprovals = pendingApprovals; // unchanged intentionally
      issuedToday = issuedToday;
      lowStockAlerts = lowStockAlerts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _welcomeBanner(context),
          const SizedBox(height: 12),
          _quickActions(context),
          const SizedBox(height: 12),
          _statsGrid(context),
          const SizedBox(height: 12),
          _recentActivity(context),
          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _welcomeBanner(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            CircleAvatar(
              radius: 22,
              child: Icon(Icons.security),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ready for operations.\nUse quick actions below for faster field workflows.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickActionButton(
              icon: Icons.add_task,
              label: 'New Request',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('New Request: coming next step')),
                );
              },
            ),
            _quickActionButton(
              icon: Icons.qr_code_scanner,
              label: 'Scan Card',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan Card: coming next step')),
                );
              },
            ),
            _quickActionButton(
              icon: Icons.search,
              label: 'Lookup Item',
              onTap: () {},
            ),
            _quickActionButton(
              icon: Icons.notifications_active,
              label: 'Alerts',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _statsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _statCard('Pending approvals', pendingApprovals, Icons.pending_actions),
        _statCard('Issued today', issuedToday, Icons.local_shipping),
        _statCard('Low stock alerts', lowStockAlerts, Icons.warning_amber),
        _statCard('Online status', 1, Icons.wifi),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          children: const [
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Recent Activity'),
              subtitle: Text('Latest operational events appear here'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('No recent activity yet'),
              subtitle: Text('Pull to refresh after backend integration'),
            ),
          ],
        ),
      ),
    );
  }
}
