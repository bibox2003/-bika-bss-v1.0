import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const int _port = 8000;

  // Put your Mac's current LAN IP here (changes if Wi-Fi/network changes)
  static const String _lanIp = '172.16.18.63';

  /// Main base URL used by the app
  ///
  /// Rules:
  /// - Web (Chrome): use localhost (because browser runs on your Mac)
  /// - Android emulator: use 10.0.2.2 (special alias to host machine)
  /// - iOS simulator/macOS/windows/linux desktop: use localhost
  /// - Physical phone/tablet: use your Mac LAN IP
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$_port';
    }

    // Mobile / desktop platforms
    try {
      if (Platform.isAndroid) {
        // Android emulator -> host machine (your Mac)
        return 'http://10.0.2.2:$_port';
      }

      if (Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isLinux ||
          Platform.isWindows) {
        // iOS simulator + desktop apps run on same machine
        return 'http://127.0.0.1:$_port';
      }
    } catch (_) {
      // Fallback if Platform checks fail for any reason
    }

    // Fallback (rare)
    return 'http://$_lanIp:$_port';
  }

  /// Use this ONLY when testing on a real phone (Android/iPhone) on same Wi-Fi
  static String get physicalDeviceBaseUrl => 'http://$_lanIp:$_port';

  /// Helpful debug print
  static void printDebugBaseUrl() {
    // ignore: avoid_print
    print('AppConfig.baseUrl => $baseUrl');
  }
}
