import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'issuer_profiles_screen.dart';
import 'statistics_screen.dart';
import 'subscription_screen.dart';
import 'templates/recipient_templates_screen.dart';
import 'templates/description_templates_screen.dart';
import '../services/subscription_service.dart';
import '../services/consent_service.dart';
import '../services/auto_backup_service.dart';
import '../services/cloud_service.dart';
import '../services/pdf_templates.dart';
import '../services/ad_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            title: 'テンプレート管理',
            items: [
              FutureBuilder<String>(
                future: AutoBackupService.getSelectedTemplate(),
                builder: (context, snapshot) {
                  final selectedTemplateId = snapshot.data ?? 'standard';
                  final selectedTemplate = PdfTemplates.templates.firstWhere(
                    (t) => t.id == selectedTemplateId,
                    orElse: () => PdfTemplates.templates.first,
                  );
                  
                  return _SettingsItem(
                    icon: Icons.article_outlined,
                    title: '領収書様式',
                    subtitle: '現在: ${selectedTemplate.name}',
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => _TemplateSelectionDialog(
                          currentTemplateId: selectedTemplateId,
                        ),
                      );
                      
                      if (result != null && result != selectedTemplateId) {
                        await AutoBackupService.setSelectedTemplate(result);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('領収書様式を変更しました')),
                          );
                          // 画面を再構築
                          (context as Element).markNeedsBuild();
                        }
                      }
                    },
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.person_outline,
                title: '宛名リスト',
                subtitle: 'よく使う宛名を登録',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecipientTemplatesScreen(),
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                title: '但書きリスト',
                subtitle: 'よく使う但書きを登録',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DescriptionTemplatesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: '領収書管理',
            items: [
              _SettingsItem(
                icon: Icons.analytics_outlined,
                title: '統計',
                subtitle: '領収書の統計情報を表示',
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
                subtitle: '事業者情報を管理',
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
                        ? 'サブスクリプションを管理'
                        : '¥150/月 - 広告なし・無制限同期',
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
            title: 'クラウドバックアップ',
            items: [
              FutureBuilder<bool>(
                future: CloudService.isSignedInToGoogleDrive(),
                builder: (context, snapshot) {
                  final isSignedIn = snapshot.data ?? false;
                  return _SettingsItem(
                    icon: isSignedIn ? Icons.cloud_done : Icons.cloud_outlined,
                    title: 'Google Drive連携',
                    subtitle: isSignedIn
                        ? '接続済み: ${CloudService.getGoogleDriveUserEmail()}'
                        : '未接続',
                    onTap: () async {
                      if (isSignedIn) {
                        // サインアウト
                        await CloudService.signOutFromGoogleDrive();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Google Driveから切断しました')),
                          );
                          // 画面を再構築
                          (context as Element).markNeedsBuild();
                        }
                      } else {
                        // サインイン
                        try {
                          final success = await CloudService.signInToGoogleDrive();
                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Google Driveに接続しました'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // 画面を再構築
                              (context as Element).markNeedsBuild();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ 接続がキャンセルされました'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ エラー: $e'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
              FutureBuilder<bool>(
                future: AutoBackupService.isAutoBackupEnabled(),
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? false;
                  return _SettingsSwitchItem(
                    icon: Icons.backup,
                    title: '自動バックアップ',
                    subtitle: '領収書保存時にGoogle Driveへ自動保存',
                    value: isEnabled,
                    onChanged: (value) async {
                      // Google Driveにサインインしているか確認
                      final isSignedIn = await CloudService.isSignedInToGoogleDrive();
                      if (!isSignedIn && value) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('先にGoogle Driveに接続してください')),
                          );
                        }
                        return;
                      }
                      
                      await AutoBackupService.setAutoBackupEnabled(value);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(value
                                ? '✅ 自動バックアップを有効にしました'
                                : '自動バックアップを無効にしました'),
                          ),
                        );
                        // 画面を再構築
                        (context as Element).markNeedsBuild();
                      }
                    },
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'プライバシー',
            items: [
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'プライバシー設定',
                subtitle: '広告のパーソナライズを管理',
                onTap: () async {
                  await ConsentService.showConsentForm();
                },
              ),
              _SettingsItem(
                icon: Icons.shield_outlined,
                title: '同意ステータス',
                subtitle: '現在のプライバシー同意を表示',
                onTap: () async {
                  final status = await ConsentService.getConsentStatusString();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('同意ステータス'),
                        content: Text('現在のステータス: $status'),
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
                    applicationVersion: '1.3.0',
                    applicationLegalese: '© 2026 Receipt Maker',
                  );
                },
              ),
            ],
          ),
        ],
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

class _SettingsSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TemplateSelectionDialog extends StatelessWidget {
  final String currentTemplateId;

  const _TemplateSelectionDialog({
    required this.currentTemplateId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('領収書様式を選択'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: PdfTemplates.templates.length,
          itemBuilder: (context, index) {
            final template = PdfTemplates.templates[index];
            final isSelected = template.id == currentTemplateId;
            
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.black87 : Colors.grey,
              ),
              title: Text(
                template.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(template.description),
              selected: isSelected,
              onTap: () {
                Navigator.pop(context, template.id);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
