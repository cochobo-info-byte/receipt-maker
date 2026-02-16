import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../services/subscription_service.dart';

class IssuerTemplatesScreen extends StatefulWidget {
  const IssuerTemplatesScreen({super.key});

  @override
  State<IssuerTemplatesScreen> createState() => _IssuerTemplatesScreenState();
}

class _IssuerTemplatesScreenState extends State<IssuerTemplatesScreen> {
  final _database = AppDatabase();
  List<IssuerTemplate> _issuers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIssuers();
  }

  Future<void> _loadIssuers() async {
    setState(() => _isLoading = true);
    final issuers = await _database.getAllIssuerTemplates();
    setState(() {
      _issuers = issuers;
      _isLoading = false;
    });
  }

  Future<void> _addIssuer() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    
    // Check limit for free users
    if (!isPremium && _issuers.length >= 5) {
      _showPremiumDialog();
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<IssuerTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => const IssuerTemplateEditorScreen(),
      ),
    );

    if (result != null) {
      await _database.insertIssuerTemplate(result);
      await _loadIssuers();
    }
  }

  Future<void> _editIssuer(IssuerTemplate issuer) async {
    final result = await Navigator.push<IssuerTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => IssuerTemplateEditorScreen(issuer: issuer),
      ),
    );

    if (result != null) {
      await _database.updateIssuerTemplate(result);
      await _loadIssuers();
    }
  }

  Future<void> _deleteIssuer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この発行者を削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _database.deleteIssuerTemplate(id);
      await _loadIssuers();
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアム機能'),
        content: const Text(
          '無料プランでは5件まで登録できます。\n無制限に登録するには、プレミアムプランにアップグレードしてください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
            },
            child: const Text('プレミアムにアップグレード'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('発行者リスト'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIssuer,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _issuers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '発行者が登録されていません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<bool>(
                        future: SubscriptionService.isPremiumUser(),
                        builder: (context, snapshot) {
                          final isPremium = snapshot.data ?? false;
                          return Text(
                            isPremium ? '無制限に登録できます' : '無料プランは5件まで登録可能',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    FutureBuilder<bool>(
                      future: SubscriptionService.isPremiumUser(),
                      builder: (context, snapshot) {
                        final isPremium = snapshot.data ?? false;
                        if (isPremium) return const SizedBox.shrink();
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_issuers.length}/5 件登録中（無料プラン）',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _issuers.length,
                        itemBuilder: (context, index) {
                          final issuer = _issuers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(issuer.name[0]),
                            ),
                            title: Text(issuer.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editIssuer(issuer),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _deleteIssuer(issuer.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class IssuerTemplateEditorScreen extends StatefulWidget {
  final IssuerTemplate? issuer;

  const IssuerTemplateEditorScreen({super.key, this.issuer});

  @override
  State<IssuerTemplateEditorScreen> createState() =>
      _IssuerTemplateEditorScreenState();
}

class _IssuerTemplateEditorScreenState
    extends State<IssuerTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.issuer?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final issuer = IssuerTemplate(
      id: widget.issuer?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      createdAt: widget.issuer?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, issuer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issuer == null ? '発行者を追加' : '発行者を編集'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '発行者名',
                hintText: '山田太郎',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '発行者名を入力してください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
