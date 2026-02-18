import 'package:flutter/material.dart';
import '../core/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import 'app_shell.dart';

class SplashGate extends StatefulWidget {
  final AuthController authController;

  const SplashGate({super.key, required this.authController});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    widget.authController.bootstrap();
    widget.authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.authController.status;

    if (status == AuthStatus.unknown) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (status == AuthStatus.authenticated) {
      return AppShell(authController: widget.authController);
    }

    return LoginScreen(authController: widget.authController);
  }
}
