import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DebugLogger {
  static final String logPath = '/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log';
  
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
      
      // Try to write to file (works on mobile/desktop, fails silently on web)
      if (!kIsWeb) {
        try {
          final file = File(logPath);
          final sink = file.openWrite(mode: FileMode.append);
          sink.writeln(jsonEncode(logEntry));
          sink.close();
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
