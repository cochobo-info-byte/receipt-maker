import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../database/database.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/auto_backup_service.dart';
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
  late TextEditingController _issuerNameController;
  late TextEditingController _issuerAddressController;
  late TextEditingController _issuerPhoneController;
  late TextEditingController _issuerRegistrationNumberController;
  
  // 税率別金額コントローラー
  late TextEditingController _amount10Controller;  // 10%対象
  late TextEditingController _amount8Controller;   // 8%対象
  late TextEditingController _amount0Controller;   // 非課税
  
  late DateTime _issueDate;
  late String _paymentMethod;
  
  List<RecipientTemplate> _recipients = [];
  List<DescriptionTemplate> _descriptions = [];
  List<IssuerProfile> _issuers = [];
  IssuerProfile? _selectedIssuer;
  
  // バナー広告
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    
    // 領収書番号の初期化（非同期）
    if (widget.receipt?.receiptNumber != null) {
      _receiptNumberController = TextEditingController(
        text: widget.receipt!.receiptNumber,
      );
    } else {
      _receiptNumberController = TextEditingController(text: '読み込み中...');
      _initializeReceiptNumber();
    }
    
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
    _issuerNameController = TextEditingController(text: '');
    _issuerAddressController = TextEditingController(text: '');
    _issuerPhoneController = TextEditingController(text: '');
    _issuerRegistrationNumberController = TextEditingController(text: '');
    
    // 税率別金額コントローラーの初期化
    _amount10Controller = TextEditingController(text: '');
    _amount8Controller = TextEditingController(text: '');
    _amount0Controller = TextEditingController(text: '');
    
    // 編集モードの場合、税率別に金額を振り分け
    if (widget.receipt?.taxItems != null) {
      for (final item in widget.receipt!.taxItems!) {
        if (item.taxRate == 0.10) {
          _amount10Controller.text = item.amount.toStringAsFixed(0);
        } else if (item.taxRate == 0.08) {
          _amount8Controller.text = item.amount.toStringAsFixed(0);
        } else if (item.taxRate == 0.00) {
          _amount0Controller.text = item.amount.toStringAsFixed(0);
        }
      }
    }
    
    _issueDate = widget.receipt?.issueDate ?? DateTime.now();
    _paymentMethod = widget.receipt?.paymentMethod ?? '現金';
    
    _loadTemplates();
    _loadDefaultIssuer();
  }

  Future<void> _loadDefaultIssuer() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final issuer = await database.getDefaultIssuer();
    if (issuer != null && mounted) {
      setState(() {
        _issuerNameController.text = issuer.companyName;
        _issuerAddressController.text = issuer.companyAddress;
        _issuerPhoneController.text = issuer.phoneNumber ?? '';
        _issuerRegistrationNumberController.text = issuer.registrationNumber ?? '';
      });
    }
  }

  Future<void> _loadTemplates() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final recipients = await database.getAllRecipients();
    final descriptions = await database.getAllDescriptions();
    final issuers = await database.getAllIssuers();
    setState(() {
      _recipients = recipients;
      _descriptions = descriptions;
      _issuers = issuers;
      if (issuers.isNotEmpty) {
        _selectedIssuer = issuers.firstWhere(
          (issuer) => issuer.isDefault,
          orElse: () => issuers.first,
        );
      }
    });
  }

  Future<void> _loadBannerAd() async {
    final bannerAd = await AdService.createBannerAd();
    if (bannerAd != null && mounted) {
      setState(() {
        _bannerAd = bannerAd;
        _isBannerAdLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _receiptNumberController.dispose();
    _recipientNameController.dispose();
    _recipientAddressController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _issuerNameController.dispose();
    _issuerAddressController.dispose();
    _issuerPhoneController.dispose();
    _issuerRegistrationNumberController.dispose();
    _amount10Controller.dispose();
    _amount8Controller.dispose();
    _amount0Controller.dispose();
    super.dispose();
  }

  Future<String> _generateReceiptNumber() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final receipts = await database.getAllReceipts();
    
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    
    // 今日の領収書の最大番号を取得
    int maxNumber = 0;
    for (final receipt in receipts) {
      if (receipt.receiptNumber.startsWith('RCP-$dateStr-')) {
        final parts = receipt.receiptNumber.split('-');
        if (parts.length >= 3) {
          final numberPart = parts[2];
          final number = int.tryParse(numberPart) ?? 0;
          if (number > maxNumber) {
            maxNumber = number;
          }
        }
      }
    }
    
    // 新しい番号を生成（+1して3桁でゼロ埋め）
    final newNumber = (maxNumber + 1).toString().padLeft(3, '0');
    return 'RCP-$dateStr-$newNumber';
  }
  
  Future<void> _initializeReceiptNumber() async {
    final receiptNumber = await _generateReceiptNumber();
    if (mounted) {
      setState(() {
        _receiptNumberController.text = receiptNumber;
      });
    }
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
                  return '領収書番号を入力してください';
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
            // Recipient name with dropdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: '受取人名',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '受取人名を入力してください';
                      }
                      return null;
                    },
                  ),
                ),
                if (_recipients.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<RecipientTemplate>(
                    icon: const Icon(Icons.person_search),
                    tooltip: '登録済み宛名から選択',
                    onSelected: (recipient) {
                      setState(() {
                        _recipientNameController.text = recipient.name;
                        if (recipient.address != null) {
                          _recipientAddressController.text = recipient.address!;
                        }
                      });
                    },
                    itemBuilder: (context) => _recipients
                        .map(
                          (r) => PopupMenuItem(
                            value: r,
                            child: Text(r.name),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
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
            const Text(
              '金額（税込）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '該当する税率の金額を入力してください',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount10Controller,
              decoration: const InputDecoration(
                labelText: '標準税率 10%',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
                helperText: '標準税率10%対象の商品・サービス',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                // 少なくとも1つの金額は入力必須
                final amount10 = double.tryParse(_amount10Controller.text) ?? 0;
                final amount8 = double.tryParse(_amount8Controller.text) ?? 0;
                final amount0 = double.tryParse(_amount0Controller.text) ?? 0;
                
                if (amount10 == 0 && amount8 == 0 && amount0 == 0) {
                  return 'いずれかの税率で金額を入力してください';
                }
                
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return '有効な金額を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount8Controller,
              decoration: const InputDecoration(
                labelText: '軽減税率 8%',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
                helperText: '軽減税率8%対象（食品・新聞等）',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return '有効な金額を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount0Controller,
              decoration: const InputDecoration(
                labelText: '非課税',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
                helperText: '非課税取引（郵便切手・印紙等）',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return '有効な金額を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
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
            // Description with dropdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '但し書き',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '但し書きを入力してください';
                      }
                      return null;
                    },
                  ),
                ),
                if (_descriptions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<DescriptionTemplate>(
                    icon: const Icon(Icons.article_outlined),
                    tooltip: '登録済み但書きから選択',
                    onSelected: (description) {
                      setState(() {
                        _descriptionController.text = description.text;
                      });
                    },
                    itemBuilder: (context) => _descriptions
                        .map(
                          (d) => PopupMenuItem(
                            value: d,
                            child: Text(d.text),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              '発行者情報',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '領収書に記載される発行者を選択してください',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_issuers.isNotEmpty) ...[
              DropdownButtonFormField<IssuerProfile>(
                value: _selectedIssuer,
                decoration: const InputDecoration(
                  labelText: '発行者を選択',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                  helperText: '※ 設定タブの発行者プロファイルから選択',
                ),
                items: _issuers.map((issuer) {
                  return DropdownMenuItem(
                    value: issuer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          issuer.companyName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (issuer.registrationNumber != null)
                          Text(
                            '登録番号: ${issuer.registrationNumber}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIssuer = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '発行者を選択してください';
                  }
                  return null;
                },
              ),
              if (_selectedIssuer != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '選択中: ${_selectedIssuer!.companyName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '所在地: ${_selectedIssuer!.companyAddress}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        if (_selectedIssuer!.phoneNumber != null)
                          Text(
                            '電話: ${_selectedIssuer!.phoneNumber}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        if (_selectedIssuer!.email != null)
                          Text(
                            'メール: ${_selectedIssuer!.email}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        if (_selectedIssuer!.registrationNumber != null)
                          Text(
                            '適格請求書発行事業者登録番号: ${_selectedIssuer!.registrationNumber}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            '発行者プロファイルが未登録です',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('設定タブ → 発行者プロファイルから事業者情報を登録してください。'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('設定タブへ移動'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _shareToLine(context, database);
                  }
                },
                icon: const Icon(Icons.chat_bubble, color: Color(0xFF00B900)),
                label: const Text(
                  'LINEで送信',
                  style: TextStyle(color: Color(0xFF00B900)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF00B900)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  Future<void> _saveReceipt(BuildContext context, AppDatabase database) async {
    // 税率別の金額から税率別アイテムを生成
    List<TaxItem> taxItems = [];
    double totalAmount = 0.0;
    
    final amount10 = double.tryParse(_amount10Controller.text) ?? 0;
    final amount8 = double.tryParse(_amount8Controller.text) ?? 0;
    final amount0 = double.tryParse(_amount0Controller.text) ?? 0;
    
    if (amount10 > 0) {
      taxItems.add(TaxItem(
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : '標準税率10%対象',
        amount: amount10,
        taxRate: 0.10,
      ));
      totalAmount += amount10;
    }
    
    if (amount8 > 0) {
      taxItems.add(TaxItem(
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : '軽減税率8%対象',
        amount: amount8,
        taxRate: 0.08,
      ));
      totalAmount += amount8;
    }
    
    if (amount0 > 0) {
      taxItems.add(TaxItem(
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : '非課税',
        amount: amount0,
        taxRate: 0.00,
      ));
      totalAmount += amount0;
    }
    
    final receipt = Receipt(
      id: widget.receipt?.id ?? const Uuid().v4(),
      receiptNumber: _receiptNumberController.text,
      issueDate: _issueDate,
      recipientName: _recipientNameController.text,
      recipientAddress: _recipientAddressController.text.isEmpty
          ? null
          : _recipientAddressController.text,
      amount: totalAmount,
      description: _descriptionController.text,
      paymentMethod: _paymentMethod,
      issuerId: _selectedIssuer != null ? int.tryParse(_selectedIssuer!.id) : null,
      taxItems: taxItems.isNotEmpty ? taxItems : null,
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
          const SnackBar(content: Text('領収書を保存しました')),
        );
        
        // Log analytics event
        await AnalyticsService.logReceiptSaved(
          amount: totalAmount,
          paymentMethod: _paymentMethod,
          hasTaxItems: taxItems.isNotEmpty,
        );
        
        // 🔄 Google Drive自動バックアップ（新規作成時のみ）
        if (widget.receipt == null) {
          final issuer = _selectedIssuer ?? await database.getDefaultIssuer();
          final backupFileId = await AutoBackupService.autoBackupReceipt(
            receipt: receipt,
            issuer: issuer,
          );
          
          if (backupFileId != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('☁️ Google Driveにバックアップしました'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        
        // Show interstitial ad after saving (for free users)
        await AdService.showInterstitialAd();
        await AnalyticsService.logInterstitialAdShown();
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e')),
        );
        // Log error
        await AnalyticsService.logError(
          errorType: 'receipt_save',
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> _previewPDF(BuildContext context, AppDatabase database) async {
    try {
      // 選択された発行者または、なければデフォルトを取得
      final issuer = _selectedIssuer ?? await database.getDefaultIssuer();
      
      // 税率別の金額から税率別アイテムを生成
      List<TaxItem> taxItems = [];
      double totalAmount = 0.0;
      
      final amount10 = double.tryParse(_amount10Controller.text) ?? 0;
      final amount8 = double.tryParse(_amount8Controller.text) ?? 0;
      final amount0 = double.tryParse(_amount0Controller.text) ?? 0;
      
      if (amount10 > 0) {
        taxItems.add(TaxItem(
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : '標準税率10%対象',
          amount: amount10,
          taxRate: 0.10,
        ));
        totalAmount += amount10;
      }
      
      if (amount8 > 0) {
        taxItems.add(TaxItem(
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : '軽減税率8%対象',
          amount: amount8,
          taxRate: 0.08,
        ));
        totalAmount += amount8;
      }
      
      if (amount0 > 0) {
        taxItems.add(TaxItem(
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : '非課税',
          amount: amount0,
          taxRate: 0.00,
        ));
        totalAmount += amount0;
      }
      
      final receiptData = {
        'receiptNumber': _receiptNumberController.text,
        'issueDate': _issueDate,
        'recipientName': _recipientNameController.text,
        'recipientAddress': _recipientAddressController.text,
        'amount': totalAmount,
        'description': _descriptionController.text,
        'paymentMethod': _paymentMethod,
        'taxItems': taxItems.isNotEmpty ? taxItems : null,
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
            const SnackBar(content: Text('PDFをダウンロードしました')),
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
          SnackBar(content: Text('PDF生成エラー: $e')),
        );
      }
    }
  }

  Future<void> _sharePDF(BuildContext context, AppDatabase database) async {
    try {
      final issuer = await database.getDefaultIssuer();
      
      // 税率別の金額から税率別アイテムを生成
      List<TaxItem> taxItems = [];
      double totalAmount = 0.0;
      
      final amount10 = double.tryParse(_amount10Controller.text) ?? 0;
      final amount8 = double.tryParse(_amount8Controller.text) ?? 0;
      final amount0 = double.tryParse(_amount0Controller.text) ?? 0;
      
      if (amount10 > 0) {
        taxItems.add(TaxItem(
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : '標準税率10%対象',
          amount: amount10,
          taxRate: 0.10,
        ));
        totalAmount += amount10;
      }
      
      if (amount8 > 0) {
        taxItems.add(TaxItem(
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : '軽減税率8%対象',
          amount: amount8,
          taxRate: 0.08,
        ));
        totalAmount += amount8;
      }
      
      if (amount0 > 0) {
        taxItems.add(TaxItem(
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : '非課税',
          amount: amount0,
          taxRate: 0.0,
        ));
        totalAmount += amount0;
      }
      
      final receiptData = {
        'receiptNumber': _receiptNumberController.text,
        'issueDate': _issueDate,
        'recipientName': _recipientNameController.text,
        'recipientAddress': _recipientAddressController.text,
        'amount': totalAmount,
        'description': _descriptionController.text,
        'paymentMethod': _paymentMethod,
        'taxItems': taxItems.isNotEmpty ? taxItems : null,
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
          SnackBar(content: Text('PDF共有エラー: $e')),
        );
      }
    }
  }

  Future<void> _shareToLine(BuildContext context, AppDatabase database) async {
    try {
      // 送信形式を選択するダイアログを表示
      final format = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('送信形式を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF形式'),
                subtitle: const Text('領収書をPDFファイルで送信'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('テキスト形式'),
                subtitle: const Text('領収書の内容をテキストで送信'),
                onTap: () => Navigator.pop(context, 'text'),
              ),
            ],
          ),
        ),
      );

      if (format == null) return;

      final issuer = _selectedIssuer ?? await database.getDefaultIssuer();
      
      // 税率別金額の計算
      double totalAmount = 0.0;
      final amount10 = double.tryParse(_amount10Controller.text) ?? 0;
      final amount8 = double.tryParse(_amount8Controller.text) ?? 0;
      final amount0 = double.tryParse(_amount0Controller.text) ?? 0;
      totalAmount = amount10 + amount8 + amount0;

      if (format == 'pdf') {
        // PDF形式で送信
        List<TaxItem> taxItems = [];
        
        if (amount10 > 0) {
          taxItems.add(TaxItem(
            description: '標準税率10%対象',
            amount: amount10,
            taxRate: 0.10,
          ));
        }
        if (amount8 > 0) {
          taxItems.add(TaxItem(
            description: '軽減税率8%対象',
            amount: amount8,
            taxRate: 0.08,
          ));
        }
        if (amount0 > 0) {
          taxItems.add(TaxItem(
            description: '非課税',
            amount: amount0,
            taxRate: 0.00,
          ));
        }

        final receiptData = {
          'receiptNumber': _receiptNumberController.text,
          'issueDate': _issueDate,
          'recipientName': _recipientNameController.text,
          'recipientAddress': _recipientAddressController.text.isEmpty 
              ? null 
              : _recipientAddressController.text,
          'amount': totalAmount,
          'description': _descriptionController.text,
          'paymentMethod': _paymentMethod,
          'taxItems': taxItems.isNotEmpty ? taxItems : null,
        };

        final pdf = await PdfService.generateReceiptPdf(receiptData, issuer);
        final filename = 'receipt_${_receiptNumberController.text}.pdf';
        
        await ShareService.sharePdfToLine(pdf, filename);
        
        // Log LINE send event
        await AnalyticsService.logLineSent(
          format: 'pdf',
          receiptNumber: _receiptNumberController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LINEで送信します。共有先でLINEを選択してください。'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // テキスト形式で送信
        await ShareService.shareReceiptTextToLine(
          receiptNumber: _receiptNumberController.text,
          issueDate: _issueDate,
          recipientName: _recipientNameController.text,
          amount: totalAmount,
          description: _descriptionController.text,
        );
        
        // Log LINE send event
        await AnalyticsService.logLineSent(
          format: 'text',
          receiptNumber: _receiptNumberController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LINEで送信します。共有先でLINEを選択してください。'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('LINE送信エラー: $e')),
        );
      }
    }
  }
}

// 税率別入力アイテムのヘルパークラス


