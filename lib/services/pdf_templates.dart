import 'package:pdf/widgets.dart' as pw;
import '../database/database_models.dart';

/// 領収書PDFテンプレート集
/// 複数の様式から選択可能
class PdfTemplates {
  /// テンプレート一覧
  static const List<ReceiptTemplate> templates = [
    ReceiptTemplate(
      id: 'standard',
      name: '標準様式',
      description: 'シンプルで分かりやすい標準レイアウト',
    ),
    ReceiptTemplate(
      id: 'business',
      name: 'ビジネス様式',
      description: '会社情報を右側に配置したビジネス向けレイアウト',
    ),
    ReceiptTemplate(
      id: 'compact',
      name: 'コンパクト様式',
      description: '情報を詰めた省スペースレイアウト',
    ),
  ];

  /// 標準様式（現在の実装）
  static pw.Widget buildStandardTemplate({
    required pw.Font font,
    required String receiptNumber,
    required DateTime issueDate,
    required String recipientName,
    String? recipientAddress,
    required double amount,
    required String description,
    required String paymentMethod,
    IssuerProfile? issuer,
    List<TaxItem>? taxItems,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // タイトル
          pw.Center(
            child: pw.Text(
              '領収書',
              style: pw.TextStyle(font: font, fontSize: 32, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 30),

          // 受取人名と金額
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$recipientName 様',
                    style: pw.TextStyle(font: font, fontSize: 16),
                  ),
                  if (recipientAddress != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      recipientAddress,
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'No. $receiptNumber',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${issueDate.year}年${issueDate.month}月${issueDate.day}日',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // 金額枠
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2),
            ),
            child: pw.Center(
              child: pw.Text(
                '¥${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: pw.TextStyle(font: font, fontSize: 28, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // 但し書き
          pw.Row(
            children: [
              pw.Text('但し、', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Container(
                width: 300,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide()),
                ),
                child: pw.Text(
                  description,
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ),
              pw.Text(' として', style: pw.TextStyle(font: font, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text('上記正に領収いたしました', style: pw.TextStyle(font: font, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 30),

          // 税率別明細
          if (taxItems != null && taxItems.isNotEmpty) ...[
            pw.Text('内訳', style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: null,
              data: [
                ['項目', '金額', '税率'],
                ...taxItems.map((item) => [
                      item.description,
                      '¥${item.amount.toStringAsFixed(0)}',
                      '${(item.taxRate * 100).toInt()}%',
                    ]),
              ],
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              headerStyle: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
              border: pw.TableBorder.all(),
            ),
            pw.SizedBox(height: 20),
          ],

          pw.Spacer(),

          // 発行者情報
          if (issuer != null) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(issuer.companyName, style: pw.TextStyle(font: font, fontSize: 12)),
                    pw.Text(issuer.companyAddress, style: pw.TextStyle(font: font, fontSize: 10)),
                    if (issuer.phoneNumber != null)
                      pw.Text('TEL: ${issuer.phoneNumber}', style: pw.TextStyle(font: font, fontSize: 10)),
                    if (issuer.email != null)
                      pw.Text('Email: ${issuer.email}', style: pw.TextStyle(font: font, fontSize: 10)),
                    if (issuer.registrationNumber != null)
                      pw.Text('登録番号: ${issuer.registrationNumber}', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// ビジネス様式（画像参考のレイアウト）
  static pw.Widget buildBusinessTemplate({
    required pw.Font font,
    required String receiptNumber,
    required DateTime issueDate,
    required String recipientName,
    String? recipientAddress,
    required double amount,
    required String description,
    required String paymentMethod,
    IssuerProfile? issuer,
    List<TaxItem>? taxItems,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 上部：タイトルと受取人
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 左側：タイトルと受取人
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '領収書',
                      style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide()),
                      ),
                      child: pw.Text(
                        '$recipientName',
                        style: pw.TextStyle(font: font, fontSize: 16),
                      ),
                    ),
                    pw.Text(
                      '様',
                      style: pw.TextStyle(font: font, fontSize: 16),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              // 右側：発行者情報（縦書き風）
              if (issuer != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(issuer.companyName, style: pw.TextStyle(font: font, fontSize: 11)),
                      pw.SizedBox(height: 4),
                      pw.Text(issuer.companyAddress, style: pw.TextStyle(font: font, fontSize: 8)),
                      if (issuer.phoneNumber != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('TEL: ${issuer.phoneNumber}', style: pw.TextStyle(font: font, fontSize: 8)),
                      ],
                      if (issuer.registrationNumber != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('FAX: 00-0000-0000', style: pw.TextStyle(font: font, fontSize: 8)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 30),

          // 金額枠（大きく）
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2),
            ),
            child: pw.Center(
              child: pw.Text(
                '¥${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: pw.TextStyle(font: font, fontSize: 32, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // 但し書き
          pw.Row(
            children: [
              pw.Text('但し、', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Expanded(
                child: pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide()),
                  ),
                  child: pw.Text(
                    description,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ),
              ),
              pw.Text(' として', style: pw.TextStyle(font: font, fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '上記、正に領収いたしました',
            style: pw.TextStyle(font: font, fontSize: 11),
          ),
          pw.SizedBox(height: 30),

          // 印鑑欄（左下）
          pw.Row(
            children: [
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Center(
                  child: pw.Text('印鑑', style: pw.TextStyle(font: font, fontSize: 10)),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('内　訳', style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('税抜金額', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide()),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('消費税等', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide()),
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.Spacer(),

          // 下部：領収書番号と日付
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'No. $receiptNumber',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                '${issueDate.year}年${issueDate.month}月${issueDate.day}日',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// コンパクト様式
  static pw.Widget buildCompactTemplate({
    required pw.Font font,
    required String receiptNumber,
    required DateTime issueDate,
    required String recipientName,
    String? recipientAddress,
    required double amount,
    required String description,
    required String paymentMethod,
    IssuerProfile? issuer,
    List<TaxItem>? taxItems,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ヘッダー
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '領収書',
                style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('No. $receiptNumber', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text(
                    '${issueDate.year}/${issueDate.month}/${issueDate.day}',
                    style: pw.TextStyle(font: font, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // 受取人と金額
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  '$recipientName 様',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Text(
                  '¥${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),

          // 但し書き
          pw.Text('但し：$description', style: pw.TextStyle(font: font, fontSize: 11)),
          pw.Text('支払方法：$paymentMethod', style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 15),

          // 税率別明細（コンパクト表示）
          if (taxItems != null && taxItems.isNotEmpty) ...[
            pw.Text('内訳', style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            ...taxItems.map((item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${item.description} (${(item.taxRate * 100).toInt()}%)',
                        style: pw.TextStyle(font: font, fontSize: 9)),
                    pw.Text('¥${item.amount.toStringAsFixed(0)}', style: pw.TextStyle(font: font, fontSize: 9)),
                  ],
                )),
            pw.SizedBox(height: 10),
          ],

          pw.Spacer(),

          // 発行者情報（コンパクト）
          if (issuer != null) ...[
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(issuer.companyName, style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text(issuer.companyAddress, style: pw.TextStyle(font: font, fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (issuer.phoneNumber != null)
                      pw.Text('TEL: ${issuer.phoneNumber}', style: pw.TextStyle(font: font, fontSize: 8)),
                    if (issuer.registrationNumber != null)
                      pw.Text('登録番号: ${issuer.registrationNumber}', style: pw.TextStyle(font: font, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 領収書テンプレート情報
class ReceiptTemplate {
  final String id;
  final String name;
  final String description;

  const ReceiptTemplate({
    required this.id,
    required this.name,
    required this.description,
  });
}
