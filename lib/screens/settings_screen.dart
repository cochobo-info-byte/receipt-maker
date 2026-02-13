import 'package:flutter/material.dart';
import 'issuer_profiles_screen.dart';
import 'statistics_screen.dart';
import 'subscription_screen.dart';
import '../services/subscription_service.dart';
import '../services/consent_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: '領収書管理',
            items: [
              _SettingsItem(
                icon: Icons.analytics_outlined,
                title: '統計',
                subtitle: 'View receipt analytics',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.business_outlined,
                title: '発行者プロファイル',
                subtitle: 'Manage company information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IssuerProfilesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          FutureBuilder<bool>(
            future: SubscriptionService.isPremiumUser(),
            builder: (context, snapshot) {
              final isPremium = snapshot.data ?? false;
              
              return _SettingsSection(
                title: 'サブスクリプション',
                items: [
                  _SettingsItem(
                    icon: isPremium ? Icons.stars : Icons.stars_outlined,
                    title: isPremium ? 'プレミアム会員' : 'プレミアムにアップグレード',
                    subtitle: isPremium
                        ? 'Manage your subscription'
                        : '¥150/month - Remove ads & unlimited sync',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          _SettingsSection(
            title: 'Privacy',
            items: [
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Settings',
                subtitle: 'Manage ad personalization',
                onTap: () async {
                  await ConsentService.showConsentForm();
                },
              ),
              _SettingsItem(
                icon: Icons.shield_outlined,
                title: 'Consent Status',
                subtitle: 'View current privacy consent',
                onTap: () async {
                  final status = await ConsentService.getConsentStatusString();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Consent Status'),
                        content: Text('Current status: $status'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'サポート',
            items: [
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'ヘルプ・FAQ',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'アプリについて',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Receipt Maker',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 Receipt Maker',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
