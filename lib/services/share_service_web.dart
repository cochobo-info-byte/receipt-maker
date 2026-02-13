import 'dart:typed_data';
import 'dart:html' as html;

// Web-specific implementation
Future<void> sharePdfWeb(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = filename
    ..click();
  
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadFileWeb(List<int> bytes, String filename, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = filename
    ..click();
  
  html.Url.revokeObjectUrl(url);
}
