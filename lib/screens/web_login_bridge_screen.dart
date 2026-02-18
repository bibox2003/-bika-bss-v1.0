import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class WebLoginBridgeScreen extends StatefulWidget {
  const WebLoginBridgeScreen({super.key});

  @override
  State<WebLoginBridgeScreen> createState() => _WebLoginBridgeScreenState();
}

class _WebLoginBridgeScreenState extends State<WebLoginBridgeScreen> {
  late final WebViewController _controller;
  final AuthService _authService = AuthService();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // User logs in in web UI, then we send them to /mobile-bridge/
    final loginUrl = '${AppConfig.baseUrl}/accounts/login/';
    final bridgeUrl = '${AppConfig.baseUrl}/mobile-bridge/';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AuthBridge',
        onMessageReceived: (JavaScriptMessage message) async {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            if (data['type'] == 'AUTH_TOKENS') {
              final access = (data['access'] ?? '').toString();
              final refresh = (data['refresh'] ?? '').toString();

              if (access.isNotEmpty && refresh.isNotEmpty) {
                await _authService.saveTokens(access: access, refresh: refresh);

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              }
            }
          } catch (e) {
            if (!mounted) return;
            setState(() => _error = 'Bridge parse error: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            setState(() => _loading = false);

            // After login succeeds, Django usually redirects away from login page.
            // We force navigation to bridge endpoint to issue tokens.
            if (!url.contains('/mobile-bridge/')) {
              // Heuristic: if user left login page, try bridge
              final leftLoginPage = !url.contains('/accounts/login/');
              if (leftLoginPage) {
                await _controller.loadRequest(Uri.parse(bridgeUrl));
              }
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = 'WebView error: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in (Web)'),
        actions: [
          IconButton(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }
}
