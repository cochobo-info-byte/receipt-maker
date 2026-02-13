import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../services/share_service.dart';
import 'receipt_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _filterPaymentMethod = 'すべて';

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receipt Maker',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
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
                TextField(
                  decoration: InputDecoration(
                    hintText: '領収書を検索...',
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
                    ],
                  ),
                ),
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

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  receipts = receipts.where((r) {
                    return r.receiptNumber.toLowerCase().contains(_searchQuery) ||
                        r.recipientName.toLowerCase().contains(_searchQuery) ||
                        r.description.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // Apply payment method filter
                if (_filterPaymentMethod != 'すべて') {
                  receipts = receipts
                      .where((r) => r.paymentMethod == _filterPaymentMethod)
                      .toList();
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
                          _searchQuery.isNotEmpty || _filterPaymentMethod != 'すべて'
                              ? '領収書が見つかりません'
                              : 'No receipts yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _filterPaymentMethod != 'すべて'
                              ? 'Try adjusting your filters'
                              : 'Tap + to create your first receipt',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    return _ReceiptCard(receipt: receipt);
                  },
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
    );
  }

  Future<void> _exportData(AppDatabase database, String format) async {
    try {
      final receipts = await database.getAllReceipts();
      final receiptMaps = receipts.map((r) => {
            'receiptNumber': r.receiptNumber,
            'issueDate': DateFormat('yyyy-MM-dd').format(r.issueDate),
            'recipientName': r.recipientName,
            'amount': r.amount,
            'description': r.description,
            'paymentMethod': r.paymentMethod,
          }).toList();

      if (format == 'csv') {
        await ShareService.exportReceiptsAsCsv(receiptMaps);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV file downloaded')),
          );
        }
      } else if (format == 'json') {
        await ShareService.exportReceiptsAsJson(receiptMaps);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('JSON file downloaded')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
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

  const _ReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptFormScreen(receipt: receipt),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    receipt.receiptNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
