import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Resolves the debug log file path for mobile/desktop (not web).
/// Returns null on failure.
Future<String?> resolveDebugLogPath() async {
  try {
    if (Platform.isWindows || Platform.isLinux) {
      final dir = Directory(path.join(Directory.current.path, '.cursor'));
      dir.createSync(recursive: true);
      return path.join(Directory.current.path, '.cursor', 'debug.log');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return path.join(dir.path, 'debug.log');
    }
  } catch (e) {
    return null;
  }
}

/// Appends a line to the log file.
void appendLogLine(String filePath, String line) {
  final file = File(filePath);
  final sink = file.openWrite(mode: FileMode.append);
  sink.writeln(line);
  sink.close();
}
