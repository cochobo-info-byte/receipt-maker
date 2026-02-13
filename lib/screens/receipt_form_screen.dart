import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import '../services/ad_service.dart';
import 'package:printing/printing.dart';

class ReceiptFormScreen extends StatefulWidget {
  final Receipt? receipt;

  const ReceiptFormScreen({super.key, this.receipt});

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _receiptNumberController;
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientAddressController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _issueDate;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _receiptNumberController = TextEditingController(
      text: widget.receipt?.receiptNumber ?? _generateReceiptNumber(),
    );
    _recipientNameController = TextEditingController(
      text: widget.receipt?.recipientName ?? '',
    );
    _recipientAddressController = TextEditingController(
      text: widget.receipt?.recipientAddress ?? '',
    );
    _amountController = TextEditingController(
      text: widget.receipt?.amount.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.receipt?.description ?? '',
    );
    _issueDate = widget.receipt?.issueDate ?? DateTime.now();
    _paymentMethod = widget.receipt?.paymentMethod ?? '現金';
  }

  @override
  void dispose() {
    _receiptNumberController.dispose();
    _recipientNameController.dispose();
    _recipientAddressController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateReceiptNumber() {
    final now = DateTime.now();
    return 'R${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receipt == null ? '新規領収書' : '領収書編集',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (widget.receipt != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('領収書を削除'),
                    content:
                        const Text('この領収書を削除してもよろしいですか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await database.deleteReceipt(widget.receipt!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _receiptNumberController,
              decoration: const InputDecoration(
                labelText: '領収書番号',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter receipt number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('発行日'),
              subtitle: Text(DateFormat('yyyy/MM/dd').format(_issueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _issueDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _issueDate = date;
                  });
                }
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextFormField(
              controller: _recipientNameController,
              decoration: const InputDecoration(
                labelText: '受取人名',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter recipient name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientAddressController,
              decoration: const InputDecoration(
                labelText: '受取人住所（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '金額',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: '支払方法',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '現金', child: Text('現金')),
                DropdownMenuItem(value: '銀行振込', child: Text('銀行振込')),
                DropdownMenuItem(value: 'クレジットカード', child: Text('クレジットカード')),
                DropdownMenuItem(value: 'その他', child: Text('その他')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paymentMethod = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '但し書き',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _previewPDF(context, database);
                      }
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('プレビュー'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _saveReceipt(context, database);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('保存'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _sharePDF(context, database);
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('PDF共有'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReceipt(BuildContext context, AppDatabase database) async {
    final receipt = Receipt(
      id: widget.receipt?.id ?? const Uuid().v4(),
      receiptNumber: _receiptNumberController.text,
      issueDate: _issueDate,
      recipientName: _recipientNameController.text,
      recipientAddress: _recipientAddressController.text.isEmpty
          ? null
          : _recipientAddressController.text,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text,
      paymentMethod: _paymentMethod,
      createdAt: widget.receipt?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.receipt == null) {
        await database.insertReceipt(receipt);
      } else {
        await database.updateReceipt(receipt);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved successfully')),
        );
        
        // Show interstitial ad after saving (for free users)
        if (widget.receipt == null) {
          await AdService.showInterstitialAd();
        }
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving receipt: $e')),
        );
      }
    }
  }

  Future<void> _previewPDF(BuildContext context, AppDatabase database) async {
    try {
      final issuer = await database.getDefaultIssuer();
      
      final receiptData = {
        'receiptNumber': _receiptNumberController.text,
        'issueDate': _issueDate,
        'recipientName': _recipientNameController.text,
        'recipientAddress': _recipientAddressController.text,
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'paymentMethod': _paymentMethod,
      };

      final pdf = await PdfService.generateReceiptPdf(receiptData, issuer);

      if (kIsWeb) {
        // Web: Direct download instead of preview
        await ShareService.sharePdf(
          pdf,
          'receipt_${_receiptNumberController.text}.pdf',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF downloaded successfully')),
          );
        }
      } else {
        // Mobile: Show preview
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('PDFプレビュー')),
                body: PdfPreview(
                  build: (format) => pdf.save(),
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _sharePDF(BuildContext context, AppDatabase database) async {
    try {
      final issuer = await database.getDefaultIssuer();
      
      final receiptData = {
        'receiptNumber': _receiptNumberController.text,
        'issueDate': _issueDate,
        'recipientName': _recipientNameController.text,
        'recipientAddress': _recipientAddressController.text,
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'paymentMethod': _paymentMethod,
      };

      final pdf = await PdfService.generateReceiptPdf(receiptData, issuer);
      final filename = 'receipt_${_receiptNumberController.text}.pdf';
      
      await ShareService.sharePdf(pdf, filename);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e')),
        );
      }
    }
  }
}
