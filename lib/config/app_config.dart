import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const int _port = 8000;
  static const String _lanIp = '172.16.18.18'; // your Mac LAN IP

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$_port';
    }

    if (Platform.isAndroid) {
      // Android emulator
      return 'http://10.0.2.2:$_port';
    }

    if (Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isWindows) {
      return 'http://127.0.0.1:$_port';
    }

    return 'http://$_lanIp:$_port';
  }

  // Use this for real phone testing
  static String get physicalDeviceBaseUrl => 'http://$_lanIp:$_port';
}
