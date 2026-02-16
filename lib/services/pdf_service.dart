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
  static Future<pw.Document> _generateReceiptPdfOld(
    Map<String, dynamic> receiptData,
    IssuerProfile? issuer,
  ) async {
    // 日本語フォントをロード
    final font = await _loadJapaneseFont();
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title - Invoice compliant
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '適格請求書',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '領収書',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Receipt Number and Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '番号: ${receiptData['receiptNumber']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '発行日: ${DateFormat('yyyy年MM月dd日').format(receiptData['issueDate'])}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Recipient
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${receiptData['recipientName']} 様',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (receiptData['recipientAddress'] != null &&
                          receiptData['recipientAddress'].toString().isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 8),
                          child: pw.Text(
                            receiptData['recipientAddress'],
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Amount breakdown (Invoice compatible with tax items)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    children: [
                      // 税率別明細がある場合は明細を表示
                      if (receiptData['taxItems'] != null && (receiptData['taxItems'] as List).isNotEmpty) ...[
                        // 明細ヘッダー
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
                            ),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  '品目',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  '金額（税込）',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  '税率',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        // 各明細
                        ...(receiptData['taxItems'] as List).map((item) {
                          final taxRate = (item['taxRate'] as double);
                          final amount = (item['amount'] as double);
                          final subtotal = amount / (1 + taxRate);
                          final taxAmount = amount - subtotal;
                          
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    item['description'],
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(
                                    '¥${NumberFormat('#,###').format(amount)}',
                                    style: const pw.TextStyle(fontSize: 10),
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ),
                                pw.Expanded(
                                  flex: 1,
                                  child: pw.Text(
                                    taxRate == 0 ? '非課税' : '${(taxRate * 100).toInt()}%',
                                    style: const pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 8),
                        pw.Divider(height: 8, thickness: 1),
                        pw.SizedBox(height: 8),
                        // 税率別集計
                        ..._buildTaxSummary(receiptData['taxItems'] as List),
                        pw.Divider(height: 16, thickness: 1),
                      ] else ...[
                        // 明細がない場合は従来の表示
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('小計', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text(
                              '¥${NumberFormat('#,###').format(_calculateSubtotal(receiptData['amount'], receiptData['taxRate'] ?? 0.10, receiptData['includeTax'] ?? true))}',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '消費税（${((receiptData['taxRate'] ?? 0.10) * 100).toInt()}%）',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                            pw.Text(
                              '¥${NumberFormat('#,###').format(_calculateTax(receiptData['amount'], receiptData['taxRate'] ?? 0.10, receiptData['includeTax'] ?? true))}',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        pw.Divider(height: 16, thickness: 1),
                      ],
                      // 合計
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '合計金額',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '¥${NumberFormat('#,###').format(receiptData['amount'])}',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '但し書き',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        receiptData['description'],
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        '支払方法: ${receiptData['paymentMethod']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Issuer info (Invoice compliant)
                if (issuer != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '発行者情報',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Divider(height: 12, thickness: 1),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(
                              width: 100,
                              child: pw.Text(
                                '事業者名',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                issuer.companyName,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (issuer.registrationNumber != null) ...[
                          pw.SizedBox(height: 6),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 100,
                                child: pw.Text(
                                  '登録番号',
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  issuer.registrationNumber!,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(
                              width: 100,
                              child: pw.Text(
                                '所在地',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                issuer.companyAddress,
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        if (issuer.phoneNumber != null) ...[
                          pw.SizedBox(height: 6),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 100,
                                child: pw.Text(
                                  '電話番号',
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  issuer.phoneNumber!,
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (issuer.email != null) ...[
                          pw.SizedBox(height: 6),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 100,
                                child: pw.Text(
                                  'メールアドレス',
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  issuer.email!,
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                
                // Footer note
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'ありがとうございました',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }
}
