import 'dart:typed_data';

/// Stub implementation for share service
/// This file is used when neither dart:html nor dart:io is available
Future<void> sharePdfWeb(Uint8List bytes, String filename) async {
  throw UnsupportedError('Web sharing is not supported on this platform');
}

Future<void> downloadFileWeb(List<int> bytes, String filename, String mimeType) async {
  throw UnsupportedError('Web download is not supported on this platform');
}
