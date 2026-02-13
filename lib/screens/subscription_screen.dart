import 'package:flutter/material.dart';
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
                  'Premium Member',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribed: ${_subscriptionDate != null ? DateFormat('yyyy/MM/dd').format(_subscriptionDate!) : 'Unknown'}',
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
            'Premium Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.block,
            title: 'No Ads',
            description: 'Enjoy ad-free experience',
            isActive: true,
          ),
          _FeatureCard(
            icon: Icons.cloud_sync,
            title: 'Unlimited Cloud Sync',
            description: 'Sync receipts to Google Drive & OneDrive',
            isActive: true,
          ),
          _FeatureCard(
            icon: Icons.support_agent,
            title: 'Priority Support',
            description: 'Get help faster from our team',
            isActive: true,
          ),
          _FeatureCard(
            icon: Icons.file_download,
            title: 'Advanced Export',
            description: 'Export in multiple formats',
            isActive: true,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('サブスクリプションをキャンセル'),
                  content: const Text(
                    'Are you sure you want to cancel your premium subscription? '
                    'You will lose access to all premium features.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep Premium'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await SubscriptionService.cancelSubscription();
                setState(() {
                  _isPremium = false;
                  _subscriptionDate = null;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription cancelled'),
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
              'サブスクリプションをキャンセル',
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
          'Upgrade to Premium',
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
                  'Premium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¥150 / month',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock all premium features',
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
            'Premium Benefits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.block,
            title: 'Ad-Free Experience',
            description: 'Remove all advertisements',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.cloud_sync,
            title: 'Unlimited Cloud Sync',
            description: 'Automatic backup to Google Drive & OneDrive',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.support_agent,
            title: 'Priority Support',
            description: '24/7 dedicated customer support',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.file_download,
            title: 'Advanced Export',
            description: 'Export receipts in CSV, JSON, and Excel',
            isActive: false,
          ),
          _FeatureCard(
            icon: Icons.dashboard_customize,
            title: 'Custom Templates',
            description: 'Create personalized receipt templates',
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
                    content: Text('Welcome to Premium! 🎉'),
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
            child: const Text('Subscribe Now'),
          ),
          const SizedBox(height: 12),
          Text(
            'Cancel anytime. No commitment required.',
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
