import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../services/subscription_service.dart';

class RecipientTemplatesScreen extends StatefulWidget {
  const RecipientTemplatesScreen({super.key});

  @override
  State<RecipientTemplatesScreen> createState() =>
      _RecipientTemplatesScreenState();
}

class _RecipientTemplatesScreenState extends State<RecipientTemplatesScreen> {
  final _database = AppDatabase();
  List<RecipientTemplate> _recipients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    setState(() => _isLoading = true);
    final recipients = await _database.getAllRecipients();
    setState(() {
      _recipients = recipients;
      _isLoading = false;
    });
  }

  Future<void> _addRecipient() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    
    // Check limit for free users
    if (!isPremium && _recipients.length >= 5) {
      _showPremiumDialog();
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<RecipientTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipientTemplateEditorScreen(),
      ),
    );

    if (result != null) {
      await _database.insertRecipient(result);
      await _loadRecipients();
    }
  }

  Future<void> _editRecipient(RecipientTemplate recipient) async {
    final result = await Navigator.push<RecipientTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecipientTemplateEditorScreen(recipient: recipient),
      ),
    );

    if (result != null) {
      await _database.updateRecipient(result);
      await _loadRecipients();
    }
  }

  Future<void> _deleteRecipient(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この宛名を削除してもよろしいですか?'),
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
      await _database.deleteRecipient(id);
      await _loadRecipients();
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
        title: const Text('宛名リスト'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecipient,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '宛名が登録されていません',
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
                                  '${_recipients.length}/5 件登録中（無料プラン）',
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
                        itemCount: _recipients.length,
                        itemBuilder: (context, index) {
                          final recipient = _recipients[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(recipient.name[0]),
                            ),
                            title: Text(recipient.name),
                            subtitle: recipient.address != null
                                ? Text(recipient.address!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editRecipient(recipient),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteRecipient(recipient.id),
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

class RecipientTemplateEditorScreen extends StatefulWidget {
  final RecipientTemplate? recipient;

  const RecipientTemplateEditorScreen({super.key, this.recipient});

  @override
  State<RecipientTemplateEditorScreen> createState() =>
      _RecipientTemplateEditorScreenState();
}

class _RecipientTemplateEditorScreenState
    extends State<RecipientTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipient?.name ?? '');
    _addressController =
        TextEditingController(text: widget.recipient?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final recipient = RecipientTemplate(
      id: widget.recipient?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      createdAt: widget.recipient?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, recipient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipient == null ? '宛名を追加' : '宛名を編集'),
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
                labelText: '宛名',
                hintText: '株式会社〇〇',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '宛名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '住所（任意）',
                hintText: '東京都渋谷区〇〇',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
