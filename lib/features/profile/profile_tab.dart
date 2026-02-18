import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';

class ProfileTab extends StatelessWidget {
  final AuthController authController;

  const ProfileTab({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Signed-in User'),
            subtitle: Text('Role and unit info from backend profile endpoint'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Security'),
            subtitle: const Text('Manage session and account safety'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async => authController.logout(),
          ),
        ),
      ],
    );
  }
}
