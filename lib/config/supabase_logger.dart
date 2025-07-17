// lib/core/network/supabase_logger.dart
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLogger {
  static void logRequest(String method, String url, [dynamic body]) {
    log('''
📤 Supabase Request:
  Method: $method
  URL: $url
  Body: ${body?.toString() ?? 'None'}
''');
  }

  static void logResponse(String method, String url, dynamic response) {
    log('''
📥 Supabase Response:
  Method: $method
  URL: $url
  Response: ${response?.toString() ?? 'Empty'}
''');
  }

  static void logError(String method, String url, dynamic error) {
    log('''
❌ Supabase Error:
  Method: $method
  URL: $url
  Error: ${error?.toString() ?? 'Unknown error'}
''');
  }

  static void logAuthChange(AuthState state) {
    log('''
🔑 Auth State Changed:
  Event: ${state.event}
  Session: ${state.session}
  User: ${state.session?.user}
''');
  }
}
