import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';

class IssuerProfilesScreen extends StatelessWidget {
  const IssuerProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Issuer Profiles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: StreamBuilder<List<IssuerProfile>>(
        stream: database.watchAllIssuers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final issuers = snapshot.data ?? [];

          if (issuers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No issuer profiles',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '会社情報を含めるためにプロファイルを追加',
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
            itemCount: issuers.length,
            itemBuilder: (context, index) {
              final issuer = issuers[index];
              return _IssuerCard(issuer: issuer);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showIssuerDialog(context, database);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showIssuerDialog(BuildContext context, AppDatabase database,
      [IssuerProfile? issuer]) {
    final nameController =
        TextEditingController(text: issuer?.companyName ?? '');
    final addressController =
        TextEditingController(text: issuer?.companyAddress ?? '');
    final phoneController =
        TextEditingController(text: issuer?.phoneNumber ?? '');
    final emailController = TextEditingController(text: issuer?.email ?? '');
    final regNumberController =
        TextEditingController(text: issuer?.registrationNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(issuer == null ? '発行者を追加' : '発行者を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '会社名 *'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: '住所 *'),
                maxLines: 2,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: '電話番号'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
              ),
              TextField(
                controller: regNumberController,
                decoration:
                    const InputDecoration(labelText: '登録番号 (T+13桁)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('必須項目を入力してください')),
                );
                return;
              }

              final profile = IssuerProfile(
                id: issuer?.id ?? const Uuid().v4(),
                companyName: nameController.text,
                companyAddress: addressController.text,
                phoneNumber: phoneController.text.isEmpty
                    ? null
                    : phoneController.text,
                email:
                    emailController.text.isEmpty ? null : emailController.text,
                registrationNumber: regNumberController.text.isEmpty
                    ? null
                    : regNumberController.text,
                isDefault: issuer?.isDefault ?? false,
                createdAt: issuer?.createdAt ?? DateTime.now(),
              );

              if (issuer == null) {
                await database.insertIssuer(profile);
              } else {
                await database.updateIssuer(profile);
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _IssuerCard extends StatelessWidget {
  final IssuerProfile issuer;

  const _IssuerCard({required this.issuer});

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issuer.companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (issuer.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issuer.companyAddress,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (issuer.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                issuer.phoneNumber!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!issuer.isDefault)
                  TextButton(
                    onPressed: () async {
                      await database.setDefaultIssuer(issuer.id);
                    },
                    child: const Text('Set Default'),
                  ),
                TextButton(
                  onPressed: () async {
                    await database.deleteIssuer(issuer.id);
                  },
                  child: const Text('削除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
