import 'package:flutter/foundation.dart';

/// Resolves the API base URL for the current runtime.
///
/// On the Android emulator the host loopback is `10.0.2.2` instead of
/// `127.0.0.1`/`localhost`; other platforms (Windows desktop, web, iOS
/// simulator) reach the host directly.
String resolveApiBaseUrl(String configured) {
  if (configured.isEmpty) return 'http://127.0.0.1:8000';
  if (kIsWeb) return configured;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return configured.replaceFirst('127.0.0.1', '10.0.2.2');
  }
  return configured;
}
