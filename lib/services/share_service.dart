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

  /// Share PDF to LINE
  /// モバイル: LINEアプリで直接共有
  /// Web: ダウンロード後、ユーザーが手動でLINEにアップロード
  static Future<void> sharePdfToLine(pw.Document pdf, String filename) async {
    try {
      final bytes = await pdf.save();
      
      if (kIsWeb) {
        // Web版: PDFをダウンロードしてユーザーにLINE送信を促す
        await downloadFileWeb(
          bytes,
          filename,
          'application/pdf',
        );
        // Web版では自動的なLINE連携は不可能なため、ダウンロードのみ
      } else {
        // モバイル版: share_plusを使用してLINEアプリへ共有
        // ユーザーがLINEを選択できる共有シートを表示
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'application/pdf', name: filename)],
          subject: '領収書 - $filename',
          text: '領収書を送付します',
        );
      }
    } catch (e) {
      throw Exception('LINEへの共有に失敗しました: $e');
    }
  }

  /// Share receipt text to LINE
  /// テキスト形式で領収書をLINEに送信
  static Future<void> shareReceiptTextToLine({
    required String receiptNumber,
    required DateTime issueDate,
    required String recipientName,
    required double amount,
    required String description,
  }) async {
    final text = '''
📋 領収書

領収書番号: $receiptNumber
発行日: ${issueDate.year}年${issueDate.month}月${issueDate.day}日
受取人: $recipientName
金額: ¥${amount.toStringAsFixed(0)}
但し書き: $description

※ この領収書はReceipt Makerアプリで作成されました。
''';

    if (kIsWeb) {
      // Web版: 標準の共有機能を使用（LINEアプリがあれば選択可能）
      await Share.share(text, subject: '領収書 - $receiptNumber');
    } else {
      // モバイル版: 共有シートでLINEを選択可能
      await Share.share(text, subject: '領収書 - $receiptNumber');
    }
  }

  /// Export receipts as CSV
  static Future<void> exportReceiptsAsCsv(List<Map<String, dynamic>> receipts) async {
    final csvRows = <String>[];
    
    // Header - 新規領収書画面の全入力項目を含む
    csvRows.add('"領収書番号","発行日","受取人名","受取人住所","金額（合計）","標準税率10%","軽減税率8%","非課税","但し書き","支払方法","発行者名","発行者住所","発行者電話番号","発行者メールアドレス","適格請求書発行事業者登録番号","作成日時","更新日時"');
    
    // Data rows
    for (final receipt in receipts) {
      // 税率別金額を計算
      String amount10 = '0';
      String amount8 = '0';
      String amount0 = '0';
      
      if (receipt['taxItems'] != null && receipt['taxItems'] is List) {
        for (var item in receipt['taxItems']) {
          if (item['taxRate'] == 0.10) {
            amount10 = item['amount'].toString();
          } else if (item['taxRate'] == 0.08) {
            amount8 = item['amount'].toString();
          } else if (item['taxRate'] == 0.00) {
            amount0 = item['amount'].toString();
          }
        }
      }
      
      final row = [
        receipt['receiptNumber'] ?? '',
        receipt['issueDate'] ?? '',
        receipt['recipientName'] ?? '',
        receipt['recipientAddress'] ?? '',
        receipt['amount']?.toString() ?? '0',
        amount10,
        amount8,
        amount0,
        receipt['description'] ?? '',
        receipt['paymentMethod'] ?? '',
        receipt['issuerName'] ?? '',
        receipt['issuerAddress'] ?? '',
        receipt['issuerPhone'] ?? '',
        receipt['issuerEmail'] ?? '',
        receipt['issuerRegistrationNumber'] ?? '',
        receipt['createdAt'] ?? '',
        receipt['updatedAt'] ?? '',
      ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(',');
      csvRows.add(row);
    }
    
    final csvContent = csvRows.join('\n');
    
    // UTF-8 BOMを追加して文字化けを防止
    final bom = [0xEF, 0xBB, 0xBF];
    final contentBytes = utf8.encode(csvContent);
    final bytes = Uint8List.fromList([...bom, ...contentBytes]);
    
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

  /// Share multiple PDFs
  static Future<void> shareMultiplePdfs(Map<String, pw.Document> pdfDocuments) async {
    try {
      final xFiles = <XFile>[];
      
      for (final entry in pdfDocuments.entries) {
        final filename = entry.key;
        final pdf = entry.value;
        final bytes = await pdf.save();
        
        xFiles.add(XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: '$filename.pdf',
        ));
      }
      
      if (kIsWeb) {
        // For web, download as ZIP or show one by one
        for (var i = 0; i < xFiles.length; i++) {
          final xFile = xFiles[i];
          final bytes = await xFile.readAsBytes();
          await downloadFileWeb(
            bytes.toList(),
            xFile.name,
            'application/pdf',
          );
          // Small delay between downloads
          if (i < xFiles.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      } else {
        // Mobile - share all files at once
        await Share.shareXFiles(
          xFiles,
          subject: '領収書 (${xFiles.length}件)',
        );
      }
    } catch (e) {
      throw Exception('Failed to share multiple PDFs: $e');
    }
  }

  /// Share multiple PDFs to LINE
  static Future<void> shareMultiplePdfsToLine(Map<String, pw.Document> pdfDocuments) async {
    try {
      final xFiles = <XFile>[];
      
      for (final entry in pdfDocuments.entries) {
        final filename = entry.key;
        final pdf = entry.value;
        final bytes = await pdf.save();
        
        xFiles.add(XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: '$filename.pdf',
        ));
      }
      
      if (kIsWeb) {
        // For web, fallback to regular share
        await shareMultiplePdfs(pdfDocuments);
      } else {
        // Mobile - share to LINE
        // Note: LINE may not support multiple files in one share
        // So we share them individually
        for (var i = 0; i < xFiles.length; i++) {
          await Share.shareXFiles(
            [xFiles[i]],
            subject: '領収書: ${xFiles[i].name}',
          );
          // Give user time to complete LINE sharing
          if (i < xFiles.length - 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to share multiple PDFs to LINE: $e');
    }
  }
}
