import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/database.dart';
import '../services/share_service.dart';
import '../services/pdf_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'receipt_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _searchField = 'すべて'; // すべて、領収書番号、受取人名、但書き
  String _filterPaymentMethod = 'すべて';
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _filterTaxRate = 'すべて'; // すべて、10%、8%、0%
  bool _showAdvancedFilters = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedReceiptIds = {};
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text(
                '${_selectedReceiptIds.length}件選択中',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              )
            : const Text(
                'Receipt Maker',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
        actions: _isSelectionMode
            ? [
                // Selection mode actions
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'すべて選択',
                  onPressed: () async {
                    final receipts = await database.getAllReceipts();
                    setState(() {
                      _selectedReceiptIds.clear();
                      _selectedReceiptIds.addAll(receipts.map((r) => r.id));
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: '選択した領収書を送信',
                  onPressed: _selectedReceiptIds.isEmpty
                      ? null
                      : () => _shareSelectedReceipts(database),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'キャンセル',
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedReceiptIds.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: '複数選択モード',
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'export_csv') {
                      await _exportData(database, 'csv');
                    } else if (value == 'export_json') {
                      await _exportData(database, 'json');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export_csv',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart, size: 20),
                          SizedBox(width: 8),
                          Text('CSVエクスポート'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export_json',
                      child: Row(
                        children: [
                          Icon(Icons.code, size: 20),
                          SizedBox(width: 8),
                          Text('JSONエクスポート'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search field selector dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _searchField,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'すべて',
                            child: Text('すべて'),
                          ),
                          DropdownMenuItem(
                            value: '領収書番号',
                            child: Text('領収書番号'),
                          ),
                          DropdownMenuItem(
                            value: '受取人名',
                            child: Text('受取人名'),
                          ),
                          DropdownMenuItem(
                            value: '但書き',
                            child: Text('但書き'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _searchField = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search text field
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: _searchField == 'すべて'
                              ? '領収書を検索...'
                              : '${_searchField}で検索...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'すべて',
                        selected: _filterPaymentMethod == 'すべて',
                        onSelected: () {
                          setState(() {
                            _filterPaymentMethod = 'すべて';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '現金',
                        selected: _filterPaymentMethod == '現金',
                        onSelected: () {
                          setState(() {
                            _filterPaymentMethod = '現金';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '銀行振込',
                        selected: _filterPaymentMethod == '銀行振込',
                        onSelected: () {
                          setState(() {
                            _filterPaymentMethod = '銀行振込';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'クレジットカード',
                        selected: _filterPaymentMethod == 'クレジットカード',
                        onSelected: () {
                          setState(() {
                            _filterPaymentMethod = 'クレジットカード';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Advanced Filters Toggle
                      IconButton(
                        icon: Icon(
                          _showAdvancedFilters
                              ? Icons.filter_list
                              : Icons.filter_list_outlined,
                          color: _showAdvancedFilters
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _showAdvancedFilters = !_showAdvancedFilters;
                          });
                        },
                        tooltip: '詳細フィルター',
                      ),
                    ],
                  ),
                ),
                // Advanced Filters Panel
                if (_showAdvancedFilters) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Date Range Filter
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _startDate == null
                                      ? '開始日'
                                      : DateFormat('yyyy/MM/dd').format(_startDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _startDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                                if (_startDate != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _startDate = null;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('〜'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _endDate == null
                                      ? '終了日'
                                      : DateFormat('yyyy/MM/dd').format(_endDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _endDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                                if (_endDate != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _endDate = null;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Amount Range Filter
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: '最小金額',
                            prefixText: '¥',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            setState(() {
                              _minAmount = double.tryParse(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('〜'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: '最大金額',
                            prefixText: '¥',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            setState(() {
                              _maxAmount = double.tryParse(value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tax Rate Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          '税率:',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'すべて',
                          selected: _filterTaxRate == 'すべて',
                          onSelected: () {
                            setState(() {
                              _filterTaxRate = 'すべて';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '10%',
                          selected: _filterTaxRate == '10%',
                          onSelected: () {
                            setState(() {
                              _filterTaxRate = '10%';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '8%',
                          selected: _filterTaxRate == '8%',
                          onSelected: () {
                            setState(() {
                              _filterTaxRate = '8%';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '0% (非課税)',
                          selected: _filterTaxRate == '0%',
                          onSelected: () {
                            setState(() {
                              _filterTaxRate = '0%';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Clear Filters Button
                  if (_startDate != null ||
                      _endDate != null ||
                      _minAmount != null ||
                      _maxAmount != null ||
                      _filterTaxRate != 'すべて')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                            _minAmount = null;
                            _maxAmount = null;
                            _filterTaxRate = 'すべて';
                          });
                        },
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text(
                          '詳細フィルターをクリア',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Receipt List
          Expanded(
            child: StreamBuilder<List<Receipt>>(
              stream: database.watchAllReceipts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var receipts = snapshot.data ?? [];

                // Apply search filter with field selection
                if (_searchQuery.isNotEmpty) {
                  receipts = receipts.where((r) {
                    switch (_searchField) {
                      case '領収書番号':
                        return r.receiptNumber.toLowerCase().contains(_searchQuery);
                      case '受取人名':
                        return r.recipientName.toLowerCase().contains(_searchQuery);
                      case '但書き':
                        return r.description.toLowerCase().contains(_searchQuery);
                      case 'すべて':
                      default:
                        return r.receiptNumber.toLowerCase().contains(_searchQuery) ||
                            r.recipientName.toLowerCase().contains(_searchQuery) ||
                            r.description.toLowerCase().contains(_searchQuery);
                    }
                  }).toList();
                }

                // Apply payment method filter
                if (_filterPaymentMethod != 'すべて') {
                  receipts = receipts
                      .where((r) => r.paymentMethod == _filterPaymentMethod)
                      .toList();
                }

                // Apply date range filter
                if (_startDate != null) {
                  receipts = receipts.where((r) {
                    return r.issueDate.isAfter(_startDate!) ||
                        r.issueDate.isAtSameMomentAs(_startDate!);
                  }).toList();
                }
                if (_endDate != null) {
                  receipts = receipts.where((r) {
                    return r.issueDate.isBefore(_endDate!.add(const Duration(days: 1)));
                  }).toList();
                }

                // Apply amount range filter
                if (_minAmount != null) {
                  receipts = receipts.where((r) => r.amount >= _minAmount!).toList();
                }
                if (_maxAmount != null) {
                  receipts = receipts.where((r) => r.amount <= _maxAmount!).toList();
                }

                // Apply tax rate filter
                if (_filterTaxRate != 'すべて') {
                  receipts = receipts.where((r) {
                    if (r.taxItems == null || r.taxItems!.isEmpty) {
                      return false;
                    }
                    if (_filterTaxRate == '10%') {
                      return r.taxItems!.any((item) => item.taxRate == 0.10);
                    } else if (_filterTaxRate == '8%') {
                      return r.taxItems!.any((item) => item.taxRate == 0.08);
                    } else if (_filterTaxRate == '0%') {
                      return r.taxItems!.any((item) => item.taxRate == 0.0);
                    }
                    return true;
                  }).toList();
                }

                if (receipts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _searchField != 'すべて' ||
                                  _filterPaymentMethod != 'すべて' ||
                                  _startDate != null ||
                                  _endDate != null ||
                                  _minAmount != null ||
                                  _maxAmount != null ||
                                  _filterTaxRate != 'すべて'
                              ? '領収書が見つかりません'
                              : 'まだ領収書がありません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _searchField != 'すべて' ||
                                  _filterPaymentMethod != 'すべて' ||
                                  _startDate != null ||
                                  _endDate != null ||
                                  _minAmount != null ||
                                  _maxAmount != null ||
                                  _filterTaxRate != 'すべて'
                              ? _searchField != 'すべて'
                                  ? '${_searchField}で検索中: "$_searchQuery"\nフィルターを調整してみてください'
                                  : 'フィルターを調整してみてください'
                              : '+ ボタンをタップして最初の領収書を作成',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Result count display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${receipts.length}件の領収書',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _searchField != 'すべて' ||
                              _filterPaymentMethod != 'すべて' ||
                              _startDate != null ||
                              _endDate != null ||
                              _minAmount != null ||
                              _maxAmount != null ||
                              _filterTaxRate != 'すべて')
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchField = 'すべて';
                                  _filterPaymentMethod = 'すべて';
                                  _startDate = null;
                                  _endDate = null;
                                  _minAmount = null;
                                  _maxAmount = null;
                                  _filterTaxRate = 'すべて';
                                });
                              },
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text(
                                'すべてクリア',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = receipts[index];
                          final isSelected = _selectedReceiptIds.contains(receipt.id);
                          return _ReceiptCard(
                            receipt: receipt,
                            isSelectionMode: _isSelectionMode,
                            isSelected: isSelected,
                            onSelectionChanged: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedReceiptIds.add(receipt.id);
                                } else {
                                  _selectedReceiptIds.remove(receipt.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReceiptFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  Future<void> _exportData(AppDatabase database, String format) async {
    try {
      final receipts = await database.getAllReceipts();
      
      // 発行者情報を取得
      final receiptMaps = <Map<String, dynamic>>[];
      for (final receipt in receipts) {
        IssuerProfile? issuer;
        if (receipt.issuerId != null) {
          issuer = await database.getIssuerById(receipt.issuerId!);
        }
        
        receiptMaps.add({
          'receiptNumber': receipt.receiptNumber,
          'issueDate': DateFormat('yyyy-MM-dd').format(receipt.issueDate),
          'recipientName': receipt.recipientName,
          'recipientAddress': receipt.recipientAddress ?? '',
          'amount': receipt.amount,
          'description': receipt.description,
          'paymentMethod': receipt.paymentMethod,
          'taxItems': receipt.taxItems?.map((item) => {
            'description': item.description,
            'amount': item.amount,
            'taxRate': item.taxRate,
          }).toList() ?? [],
          'issuerName': issuer?.companyName ?? '',
          'issuerAddress': issuer?.companyAddress ?? '',
          'issuerPhone': issuer?.phoneNumber ?? '',
          'issuerEmail': issuer?.email ?? '',
          'issuerRegistrationNumber': issuer?.registrationNumber ?? '',
          'createdAt': DateFormat('yyyy-MM-dd HH:mm').format(receipt.createdAt),
          'updatedAt': DateFormat('yyyy-MM-dd HH:mm').format(receipt.updatedAt),
        });
      }

      if (format == 'csv') {
        await ShareService.exportReceiptsAsCsv(receiptMaps);
        // Log CSV export
        await AnalyticsService.logCsvExported(receiptCount: receipts.length);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSVファイルをダウンロードしました')),
          );
        }
      } else if (format == 'json') {
        await ShareService.exportReceiptsAsJson(receiptMaps);
        // Log JSON export
        await AnalyticsService.logJsonExported(receiptCount: receipts.length);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('JSONファイルをダウンロードしました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
      // Log error
      await AnalyticsService.logError(
        errorType: 'export_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _shareSelectedReceipts(AppDatabase database) async {
    if (_selectedReceiptIds.isEmpty) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get selected receipts
      final allReceipts = await database.getAllReceipts();
      final selectedReceipts = allReceipts
          .where((r) => _selectedReceiptIds.contains(r.id))
          .toList();

      // Generate PDFs for all selected receipts
      final pdfDocuments = <String, pw.Document>{};
      
      for (final receipt in selectedReceipts) {
        // Get issuer info
        IssuerProfile? issuer;
        if (receipt.issuerId != null) {
          issuer = await database.getIssuerById(receipt.issuerId!);
        }
        issuer ??= await database.getDefaultIssuer();

        // Build receipt data
        final taxItems = receipt.taxItems?.map((item) => {
          'description': item.description,
          'amount': item.amount,
          'taxRate': item.taxRate,
        }).toList();

        final receiptData = {
          'receiptNumber': receipt.receiptNumber,
          'issueDate': DateFormat('yyyy年MM月dd日').format(receipt.issueDate),
          'recipientName': receipt.recipientName,
          'recipientAddress': receipt.recipientAddress,
          'amount': receipt.amount,
          'description': receipt.description,
          'paymentMethod': receipt.paymentMethod,
          'taxItems': taxItems,
        };

        // Generate PDF
        final pdf = await PdfService.generateReceiptPdf(receiptData, issuer);
        pdfDocuments[receipt.receiptNumber] = pdf;
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show sharing options dialog
      if (!mounted) return;
      final shareOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${selectedReceipts.length}件の領収書を送信'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('通常の共有'),
                subtitle: const Text('他のアプリで送信'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
              ListTile(
                leading: Icon(Icons.chat, color: Colors.green.shade700),
                title: const Text('LINEで送信'),
                subtitle: const Text('LINE経由で送信'),
                onTap: () => Navigator.pop(context, 'line'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      );

      if (shareOption == null) return;

      // Share all PDFs
      if (shareOption == 'share') {
        await ShareService.shareMultiplePdfs(pdfDocuments);
        await AnalyticsService.logEvent(
          name: 'share_multiple_receipts',
          parameters: {'count': selectedReceipts.length},
        );
      } else if (shareOption == 'line') {
        await ShareService.shareMultiplePdfsToLine(pdfDocuments);
        await AnalyticsService.logLineSent(
          receiptCount: selectedReceipts.length,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedReceipts.length}件の領収書を送信しました'),
          ),
        );

        // Exit selection mode
        setState(() {
          _isSelectionMode = false;
          _selectedReceiptIds.clear();
        });
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信に失敗しました: $e')),
        );
      }
      
      await AnalyticsService.logError(
        errorType: 'share_multiple_error',
        errorMessage: e.toString(),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.black87,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  const _ReceiptCard({
    required this.receipt,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            onSelectionChanged(!isSelected);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptFormScreen(receipt: receipt),
              ),
            );
          }
        },
        onLongPress: !isSelectionMode
            ? () {
                onSelectionChanged(true);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              if (value != null) {
                                onSelectionChanged(value);
                              }
                            },
                          ),
                        ),
                      Text(
                        receipt.receiptNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  if (receipt.isSynced)
                    Icon(
                      Icons.cloud_done,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                receipt.recipientName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¥${NumberFormat('#,###').format(receipt.amount)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('yyyy/MM/dd').format(receipt.issueDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.payment_outlined,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    receipt.paymentMethod,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble, size: 18),
                    color: const Color(0xFF00B900),
                    tooltip: 'LINEで送信',
                    onPressed: () => _shareReceiptToLine(context, receipt),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareReceiptToLine(BuildContext context, Receipt receipt) async {
    try {
      // 送信形式を選択
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

      final database = Provider.of<AppDatabase>(context, listen: false);
      IssuerProfile? issuer;
      if (receipt.issuerId != null) {
        issuer = await database.getIssuerById(receipt.issuerId!);
      }
      issuer ??= await database.getDefaultIssuer();

      if (format == 'pdf') {
        // PDF形式で送信
        final receiptData = {
          'receiptNumber': receipt.receiptNumber,
          'issueDate': receipt.issueDate,
          'recipientName': receipt.recipientName,
          'recipientAddress': receipt.recipientAddress,
          'amount': receipt.amount,
          'description': receipt.description,
          'paymentMethod': receipt.paymentMethod,
          'taxItems': receipt.taxItems,
        };

        final pdf = await PdfService.generateReceiptPdf(receiptData, issuer);
        final filename = 'receipt_${receipt.receiptNumber}.pdf';
        
        await ShareService.sharePdfToLine(pdf, filename);
        
        if (context.mounted) {
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
          receiptNumber: receipt.receiptNumber,
          issueDate: receipt.issueDate,
          recipientName: receipt.recipientName,
          amount: receipt.amount,
          description: receipt.description,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LINEで送信します。共有先でLINEを選択してください。'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('LINE送信エラー: $e')),
        );
      }
    }
  }
}
