import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'debug_logger_io.dart' if (dart.library.html) 'debug_logger_stub.dart' as impl;

class DebugLogger {
  static String? _resolvedPath;

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      _resolvedPath = await impl.resolveDebugLogPath();
    } catch (e) {
      // Init failed; log() will only print to console
    }
  }

  static void log({
    required String location,
    required String message,
    Map<String, dynamic>? data,
    String? hypothesisId,
    String runId = 'run1',
  }) {
    try {
      final logEntry = {
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'location': location,
        'message': message,
        'data': data ?? {},
        'sessionId': 'debug-session',
        'runId': runId,
        if (hypothesisId != null) 'hypothesisId': hypothesisId,
      };

      // Always print to console for web compatibility
      final logString = '[DEBUG] $location: $message${data != null ? ' | Data: $data' : ''}${hypothesisId != null ? ' | Hypothesis: $hypothesisId' : ''}';
      print(logString);
      debugPrint(logString);

      // Try to write to file (works on mobile/desktop, no-op on web)
      if (!kIsWeb && _resolvedPath != null) {
        try {
          impl.appendLogLine(_resolvedPath!, jsonEncode(logEntry));
        } catch (e) {
          // File I/O failed, but console logging succeeded
        }
      }
    } catch (e) {
      // Fallback: at least print the error
      print('[DEBUG LOGGER ERROR] $e');
    }
  }
}
