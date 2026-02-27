import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'services/api_client.dart';

import 'features/dashboard/dashboard_models.dart';
import 'features/dashboard/dashboard_service.dart';
import 'features/inventory/inventory_tab.dart';
import 'features/cart/cart_tab.dart';
import 'features/checkout/checkout_tab.dart';
import 'features/orders/orders_tab.dart';

// ✅ NEW
import 'features/scanner/scanner_tab.dart';
import 'features/iot/iot_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DjangoWrapperApp());
}

class DjangoWrapperApp extends StatelessWidget {
  const DjangoWrapperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIKA Smart Space',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final ok = await _authService.isLoggedIn();
      if (!mounted) return;
      setState(() {
        _loggedIn = ok;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedIn = false;
        _checking = false;
      });
    }
  }

  Future<void> _onLoginSuccess() async {
    if (!mounted) return;
    setState(() => _loggedIn = true);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loggedIn) {
      return MainShell(onLogout: _logout);
    }

    return LoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}

class MainShell extends StatefulWidget {
  final Future<void> Function() onLogout;

  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<_ShellPage> _pages = const [
    _ShellPage(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      widget: DashboardTab(),
    ),
    _ShellPage(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      widget: InventoryTab(),
    ),
    // ✅ NEW TAB
    _ShellPage(
      label: 'Scan',
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      widget: ScannerTab(),
    ),
    _ShellPage(
      label: 'Cart',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      widget: CartTab(),
    ),
    _ShellPage(
      label: 'Checkout',
      icon: Icons.payment_outlined,
      selectedIcon: Icons.payment,
      widget: CheckoutTab(),
    ),
  ];

  Future<void> _openOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrdersTab()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(onLogout: widget.onLogout),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.label),
        actions: [
          // Instagram-like top-right actions
          IconButton(
            tooltip: 'Orders',
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'orders') {
                await _openOrders();
              } else if (value == 'profile') {
                await _openProfile();
              } else if (value == 'logout') {
                await widget.onLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'orders', child: Text('Orders')),
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.map((p) => p.widget).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _pages
            .map(
              (p) => NavigationDestination(
                icon: Icon(p.icon),
                selectedIcon: Icon(p.selectedIcon),
                label: p.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShellPage {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget widget;

  const _ShellPage({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.widget,
  });
}

/// ✅ FIXED LOGIN (typing works)
class LoginScreen extends StatefulWidget {
  final Future<void> Function() onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_usernameFocus);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _login() async {
    _dismissKeyboard();

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter username and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.login(username: username, password: password);
      await widget.onLoginSuccess();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 14),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ UPDATED DashboardTab: now includes IoT preview cards/charts (mock now, dynamic later)
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late final DashboardService _service;

  bool _loading = true;
  String? _error;
  DashboardSummary? _summary;

  // ✅ NEW: IoT mock snapshot for “future dynamic” UI
  IotSnapshot _iot = IotSnapshot.mock();

  @override
  void initState() {
    super.initState();
    _service = DashboardService(ApiClient(AuthService()));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchSummary();
      setState(() => _summary = data);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refreshIotMock() {
    setState(() {
      _iot = IotSnapshot.mock();
    });
  }

  String _money(String value) {
    final n = double.tryParse(value) ?? 0.0;
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        _refreshIotMock();
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(
                      radius: 20, child: Icon(Icons.insights_outlined)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overview',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Live summary of inventory + cart'),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Could not load overview'),
                subtitle: Text(_error!),
              ),
            )
          else if (summary != null) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statCard('Total Products', '${summary.products.total}',
                    Icons.inventory_2_outlined),
                _statCard('Active', '${summary.products.active}',
                    Icons.check_circle_outline),
                _statCard('Out of Stock', '${summary.products.outOfStock}',
                    Icons.remove_shopping_cart_outlined),
                _statCard('Low Stock', '${summary.products.lowStock}',
                    Icons.warning_amber_outlined),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cart Snapshot',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _miniTile(
                                icon: Icons.shopping_cart_outlined,
                                label: 'Items',
                                value: '${summary.cart.itemsCount}')),
                        Expanded(
                            child: _miniTile(
                                icon: Icons.format_list_numbered,
                                label: 'Total Qty',
                                value: '${summary.cart.totalQuantity}')),
                        Expanded(
                            child: _miniTile(
                                icon: Icons.payments_outlined,
                                label: 'Value',
                                value: _money(summary.cart.totalValue))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ✅ ALWAYS show IoT preview section (even if API fails)
          const SizedBox(height: 10),
          IotPreviewSection(
            snapshot: _iot,
            onRefresh: _refreshIotMock,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 165,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Profile screen (opened from top-right)
class ProfileScreen extends StatelessWidget {
  final Future<void> Function() onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Account'),
              subtitle: Text('Profile & settings'),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              await onLogout();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
