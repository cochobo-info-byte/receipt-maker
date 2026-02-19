import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../database/database.dart';
import 'pdf_templates.dart';
import 'auto_backup_service.dart';

class PdfService {
  // 日本語フォントのキャッシュ
  static pw.Font? _cachedFont;

  /// 小計を計算（税抜き価格）
  static double _calculateSubtotal(double amount, double taxRate, bool includeTax) {
    if (includeTax) {
      // 税込み価格から税抜き価格を計算
      return amount / (1 + taxRate);
    } else {
      // 既に税抜き価格
      return amount;
    }
  }

  /// 消費税額を計算
  static double _calculateTax(double amount, double taxRate, bool includeTax) {
    if (includeTax) {
      // 税込み価格から消費税を計算
      return amount - (amount / (1 + taxRate));
    } else {
      // 税抜き価格から消費税を計算
      return amount * taxRate;
    }
  }

  /// アセットから日本語フォントをロード
  static Future<pw.Font> _loadJapaneseFont() async {
    if (_cachedFont != null) return _cachedFont!;

    try {
      // アセットからNoto Sans JPを読み込み
      final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
      _cachedFont = pw.Font.ttf(fontData);
      return _cachedFont!;
    } catch (e) {
      // フォント読み込み失敗時はデフォルトフォント
      return pw.Font.courier();
    }
  }

  /// 税率別集計を表示
  static List<pw.Widget> _buildTaxSummary(List taxItems) {
    final widgets = <pw.Widget>[];
    
    // 税率ごとにグループ化
    final Map<double, List<Map<String, dynamic>>> taxGroups = {};
    for (final item in taxItems) {
      final taxRate = (item['taxRate'] as double);
      if (!taxGroups.containsKey(taxRate)) {
        taxGroups[taxRate] = [];
      }
      taxGroups[taxRate]!.add(item as Map<String, dynamic>);
    }
    
    // 税率ごとの集計を表示
    taxGroups.forEach((taxRate, items) {
      double totalSubtotal = 0;
      double totalTax = 0;
      
      for (final item in items) {
        final amount = (item['amount'] as double);
        final subtotal = amount / (1 + taxRate);
        final tax = amount - subtotal;
        totalSubtotal += subtotal;
        totalTax += tax;
      }
      
      // 税率別小計
      widgets.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${(taxRate * 100).toInt()}% 対象 小計',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              '¥${NumberFormat('#,###').format(totalSubtotal)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      );
      
      widgets.add(pw.SizedBox(height: 4));
      
      // 税額
      widgets.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '消費税（${(taxRate * 100).toInt()}%）',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              '¥${NumberFormat('#,###').format(totalTax)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      );
      
      widgets.add(pw.SizedBox(height: 8));
    });
    
    return widgets;
  }

  /// 領収書PDFをテンプレートで生成
  /// templateIdを指定してカスタムレイアウトを使用
  static Future<pw.Document> generateReceiptPdfWithTemplate(
    Map<String, dynamic> receiptData,
    IssuerProfile? issuer, {
    String? templateId,
  }) async {
    // 日本語フォントをロード
    final font = await _loadJapaneseFont();
    
    // テンプレートIDが指定されていない場合は設定から取得
    final selectedTemplate = templateId ?? await AutoBackupService.getSelectedTemplate();
    
    final pdf = pw.Document();

    // 領収書データを展開
    final receiptNumber = receiptData['receiptNumber'] as String;
    final issueDate = receiptData['issueDate'] as DateTime;
    final recipientName = receiptData['recipientName'] as String;
    final recipientAddress = receiptData['recipientAddress'] as String?;
    final amount = receiptData['amount'] as double;
    final description = receiptData['description'] as String;
    final paymentMethod = receiptData['paymentMethod'] as String? ?? '現金';
    final taxItems = receiptData['taxItems'] as List<TaxItem>?;

    // テンプレートに応じてレイアウトを選択
    pw.Widget content;
    switch (selectedTemplate) {
      case 'business':
        content = PdfTemplates.buildBusinessTemplate(
          font: font,
          receiptNumber: receiptNumber,
          issueDate: issueDate,
          recipientName: recipientName,
          recipientAddress: recipientAddress,
          amount: amount,
          description: description,
          paymentMethod: paymentMethod,
          issuer: issuer,
          taxItems: taxItems,
        );
        break;
      case 'compact':
        content = PdfTemplates.buildCompactTemplate(
          font: font,
          receiptNumber: receiptNumber,
          issueDate: issueDate,
          recipientName: recipientName,
          recipientAddress: recipientAddress,
          amount: amount,
          description: description,
          paymentMethod: paymentMethod,
          issuer: issuer,
          taxItems: taxItems,
        );
        break;
      case 'standard':
      default:
        content = PdfTemplates.buildStandardTemplate(
          font: font,
          receiptNumber: receiptNumber,
          issueDate: issueDate,
          recipientName: recipientName,
          recipientAddress: recipientAddress,
          amount: amount,
          description: description,
          paymentMethod: paymentMethod,
          issuer: issuer,
          taxItems: taxItems,
        );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
        ),
        build: (pw.Context context) => content,
      ),
    );

    return pdf;
  }

  /// 領収書PDFを生成（既存のメソッド - 後方互換性のため残す）
  /// 日本語フォント対応（Web環境でも動作）
  static Future<pw.Document> generateReceiptPdf(
    Map<String, dynamic> receiptData,
    IssuerProfile? issuer,
  ) async {
    // 新しいメソッドを呼び出す
    return generateReceiptPdfWithTemplate(receiptData, issuer);
  }

  /// 領収書PDFを生成（旧実装 - 互換性のため残す）
}
