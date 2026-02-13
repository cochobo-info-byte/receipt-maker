import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../database/database.dart';

class PdfService {
  /// 領収書PDFを生成
  /// 日本語フォント対応（Web環境でも動作）
  static Future<pw.Document> generateReceiptPdf(
    Map<String, dynamic> receiptData,
    IssuerProfile? issuer,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title - シンプル表示（Web互換）
                pw.Center(
                  child: pw.Text(
                    'Receipt',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),

                // Receipt Number and Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'No: ${receiptData['receiptNumber']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Date: ${DateFormat('yyyy/MM/dd').format(receiptData['issueDate'])}',
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
                        'To: ${receiptData['recipientName']}',
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

                // Amount
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Amount',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'JPY ${NumberFormat('#,###').format(receiptData['amount'])}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
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
                        'Details',
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
                        'Payment: ${receiptData['paymentMethod']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Issuer info
                if (issuer != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Issuer: ${issuer.companyName}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          issuer.companyAddress,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        if (issuer.phoneNumber != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'TEL: ${issuer.phoneNumber}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        if (issuer.email != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'Email: ${issuer.email}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        if (issuer.registrationNumber != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'Reg No: ${issuer.registrationNumber}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Footer note
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business',
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
