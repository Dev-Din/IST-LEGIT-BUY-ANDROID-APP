// Stub file for web platform - File operations not available
class File {
  File(String path);
  Future<void> writeAsString(String contents, {required FileMode mode}) async {}
}

enum FileMode { append }
