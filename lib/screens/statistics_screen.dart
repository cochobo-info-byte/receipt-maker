import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../database/database.dart';
import '../services/ad_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
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
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: FutureBuilder<List<Receipt>>(
        future: database.getAllReceipts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final receipts = snapshot.data ?? [];

          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create some receipts to see statistics',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          final totalAmount = receipts.fold<double>(
            0,
            (sum, receipt) => sum + receipt.amount,
          );

          final averageAmount = totalAmount / receipts.length;

          final paymentMethodCounts = <String, int>{};
          for (final receipt in receipts) {
            paymentMethodCounts[receipt.paymentMethod] =
                (paymentMethodCounts[receipt.paymentMethod] ?? 0) + 1;
          }

          final thisMonthReceipts = receipts.where((r) {
            final now = DateTime.now();
            return r.issueDate.year == now.year &&
                r.issueDate.month == now.month;
          }).toList();

          final thisMonthTotal = thisMonthReceipts.fold<double>(
            0,
            (sum, receipt) => sum + receipt.amount,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                title: '総領収書数',
                value: receipts.length.toString(),
                icon: Icons.receipt_outlined,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: '総金額',
                value: '¥${NumberFormat('#,###').format(totalAmount)}',
                icon: Icons.payments_outlined,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: '平均金額',
                value: '¥${NumberFormat('#,###').format(averageAmount)}',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: '今月',
                value: '¥${NumberFormat('#,###').format(thisMonthTotal)}',
                subtitle: '${thisMonthReceipts.length} 件',
                icon: Icons.calendar_today,
                color: Colors.purple,
              ),
              const SizedBox(height: 24),
              Text(
                '支払方法',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              ...paymentMethodCounts.entries.map((entry) {
                final percentage =
                    (entry.value / receipts.length * 100).toStringAsFixed(1);
                return _PaymentMethodRow(
                  method: entry.key,
                  count: entry.value,
                  total: receipts.length,
                  percentage: percentage,
                );
              }),
            ],
          );
        },
      ),
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String method;
  final int count;
  final int total;
  final String percentage;

  const _PaymentMethodRow({
    required this.method,
    required this.count,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                method,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count receipts ($percentage%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black87),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
