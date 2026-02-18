import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String? _error;
  String? get error => _error;

  AuthController(this._authService);

  Future<void> bootstrap() async {
    _setBusy(true);
    _error = null;

    try {
      final loggedIn = await _authService.isLoggedIn();
      if (!loggedIn) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Optional safety: attempt refresh on app start so token is valid
      final refreshed = await _authService.refreshAccessToken();
      if (refreshed == null) {
        // Could still be valid access token; if you want strict mode, force logout.
        // For now, we allow session if access token exists.
        final stillLoggedIn = await _authService.isLoggedIn();
        _status = stillLoggedIn
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.authenticated;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setBusy(true);
    _error = null;

    try {
      await _authService.login(username: username, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    _error = null;

    try {
      await _authService.logout();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
