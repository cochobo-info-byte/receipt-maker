import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPremium = false;
  DateTime? _subscriptionDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    final info = await SubscriptionService.getSubscriptionInfo();
    setState(() {
      _isPremium = info['isPremium'];
      if (info['subscriptionDate'] != null) {
        _subscriptionDate = DateTime.parse(info['subscriptionDate']);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isPremium) {
      return _buildPremiumView();
    } else {
      return _buildSubscriptionOfferView();
    }
  }

  Widget _buildPremiumView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'プレミアムサブスクリプション',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.amber.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.stars,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'プレミアム会員',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '登録日: ${_subscriptionDate != null ? DateFormat('yyyy/MM/dd').format(_subscriptionDate!) : '不明'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'プレミアム機能',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.block,
            title: '広告なし',
            description: '広告なしで快適に使用',
            isActive: true,
          ),
          _FeatureCard(
            icon: Icons.cloud_sync,
            title: '無制限クラウド同期',
            description: 'Google DriveやOneDriveに同期',
            isActive: true,
          ),
          _FeatureCard(
            icon: Icons.support_agent,
            title: '優先サポート',
            description: 'より迅速なサポートを受けられます',
            isActive: true,
          ),
          _FeatureCard(
            icon: Icons.file_download,
            title: '高度なエクスポート',
            description: '複数形式でエクスポート可能',
            isActive: true,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              // Google Play ではアプリ内でキャンセルできないため
              // Play Store のサブスクリプション管理ページへ誘導
              final uri = Uri.parse(
                'https://play.google.com/store/account/subscriptions'
                '?sku=premium_monthly'
                '&package=com.receiptmaker.receipt',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google Playのサブスクリプション管理ページを開けませんでした'),
                    ),
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.red.shade300),
            ),
            child: Text(
              'サブスクリプションを管理（Google Play）',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOfferView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'プレミアムにアップグレード',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.stars,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                const Text(
                  'プレミアム',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¥150 / 月',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'すべてのプレミアム機能を解除',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'プレミアム特典',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.block,
            title: '広告なしの体験',
            description: 'すべての広告を削除',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.cloud_sync,
            title: '無制限クラウド同期',
            description: 'Google DriveとOneDriveに自動バックアップ',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.support_agent,
            title: '優先サポート',
            description: '24/7専用顧客サポート',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.file_download,
            title: '高度なエクスポート',
            description: 'CSV、JSON、Excel形式でエクスポート',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.dashboard_customize,
            title: 'カスタムテンプレート',
            description: 'パーソナライズされた領収書テンプレートを作成',
            isActive: false,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final success = await SubscriptionService.purchaseSubscription();
              
              if (success && mounted) {
                setState(() {
                  _isPremium = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('プレミアムへようこそ！ 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('今すぐ登録'),
          ),
          const SizedBox(height: 12),
          Text(
            'いつでもキャンセル可能。縛りなし。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isActive;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.green.shade50 : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Icon(
              Icons.check_circle,
              color: Colors.green.shade700,
              size: 24,
            ),
        ],
      ),
    );
  }
}
