import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web
import 'share_service_stub.dart'
    if (dart.library.html) 'share_service_web.dart';

class ShareService {
  /// Share PDF (platform-specific implementation)
  static Future<void> sharePdf(pw.Document pdf, String filename) async {
    try {
      final bytes = await pdf.save();
      
      if (kIsWeb) {
        // Use web-specific implementation
        await sharePdfWeb(bytes, filename);
      } else {
        // For mobile platforms - save to temporary file and share
        // This is handled by share_plus package
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'application/pdf', name: filename)],
          subject: filename,
        );
      }
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Share receipt as text
  static Future<void> shareReceiptText({
    required String receiptNumber,
    required DateTime issueDate,
    required String recipientName,
    required double amount,
    required String description,
  }) async {
    final text = '''
領収書

領収書番号: $receiptNumber
発行日: ${issueDate.year}年${issueDate.month}月${issueDate.day}日
受取人: $recipientName
金額: ¥${amount.toStringAsFixed(0)}
但し書き: $description

※ この領収書はReceipt Makerアプリで作成されました。
''';

    await Share.share(text, subject: '領収書 - $receiptNumber');
  }

  /// Export receipts as CSV
  static Future<void> exportReceiptsAsCsv(List<Map<String, dynamic>> receipts) async {
    final csvRows = <String>[];
    
    // Header
    csvRows.add('"領収書番号","発行日","受取人","金額","説明","支払方法"');
    
    // Data rows
    for (final receipt in receipts) {
      final row = [
        receipt['receiptNumber'],
        receipt['issueDate'],
        receipt['recipientName'],
        receipt['amount'].toString(),
        receipt['description'],
        receipt['paymentMethod'],
      ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(',');
      csvRows.add(row);
    }
    
    final csvContent = csvRows.join('\n');
    final bytes = utf8.encode(csvContent);
    
    if (kIsWeb) {
      // Web-specific download
      await downloadFileWeb(
        bytes,
        'receipts_${DateTime.now().millisecondsSinceEpoch}.csv',
        'text/csv;charset=utf-8',
      );
    } else {
      // Mobile - use share_plus
      await Share.shareXFiles(
        [XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'text/csv',
          name: 'receipts_${DateTime.now().millisecondsSinceEpoch}.csv',
        )],
      );
    }
  }

  /// Export receipts as JSON
  static Future<void> exportReceiptsAsJson(List<Map<String, dynamic>> receipts) async {
    final jsonContent = jsonEncode(receipts);
    final bytes = utf8.encode(jsonContent);
    
    if (kIsWeb) {
      // Web-specific download
      await downloadFileWeb(
        bytes,
        'receipts_${DateTime.now().millisecondsSinceEpoch}.json',
        'application/json',
      );
    } else {
      // Mobile - use share_plus
      await Share.shareXFiles(
        [XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'application/json',
          name: 'receipts_${DateTime.now().millisecondsSinceEpoch}.json',
        )],
      );
    }
  }
}
