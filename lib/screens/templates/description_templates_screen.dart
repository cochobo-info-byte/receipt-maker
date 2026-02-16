import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../services/subscription_service.dart';

class DescriptionTemplatesScreen extends StatefulWidget {
  const DescriptionTemplatesScreen({super.key});

  @override
  State<DescriptionTemplatesScreen> createState() =>
      _DescriptionTemplatesScreenState();
}

class _DescriptionTemplatesScreenState
    extends State<DescriptionTemplatesScreen> {
  final _database = AppDatabase();
  List<DescriptionTemplate> _descriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDescriptions();
  }

  Future<void> _loadDescriptions() async {
    setState(() => _isLoading = true);
    final descriptions = await _database.getAllDescriptions();
    setState(() {
      _descriptions = descriptions;
      _isLoading = false;
    });
  }

  Future<void> _addDescription() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    
    // Check limit for free users
    if (!isPremium && _descriptions.length >= 5) {
      _showPremiumDialog();
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<DescriptionTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => const DescriptionTemplateEditorScreen(),
      ),
    );

    if (result != null) {
      await _database.insertDescription(result);
      await _loadDescriptions();
    }
  }

  Future<void> _editDescription(DescriptionTemplate description) async {
    final result = await Navigator.push<DescriptionTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DescriptionTemplateEditorScreen(description: description),
      ),
    );

    if (result != null) {
      await _database.updateDescription(result);
      await _loadDescriptions();
    }
  }

  Future<void> _deleteDescription(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この但書きを削除してもよろしいですか?'),
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
      await _database.deleteDescription(id);
      await _loadDescriptions();
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
        title: const Text('但書きリスト'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDescription,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _descriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '但書きが登録されていません',
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
                                  '${_descriptions.length}/5 件登録中（無料プラン）',
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
                        itemCount: _descriptions.length,
                        itemBuilder: (context, index) {
                          final description = _descriptions[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(description.text[0]),
                            ),
                            title: Text(description.text),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _editDescription(description),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteDescription(description.id),
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

class DescriptionTemplateEditorScreen extends StatefulWidget {
  final DescriptionTemplate? description;

  const DescriptionTemplateEditorScreen({super.key, this.description});

  @override
  State<DescriptionTemplateEditorScreen> createState() =>
      _DescriptionTemplateEditorScreenState();
}

class _DescriptionTemplateEditorScreenState
    extends State<DescriptionTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.description?.text ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final description = DescriptionTemplate(
      id: widget.description?.id ?? const Uuid().v4(),
      text: _textController.text.trim(),
      createdAt: widget.description?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, description);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.description == null ? '但書きを追加' : '但書きを編集'),
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
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '但書き',
                hintText: 'お品代として',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '但書きを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 20, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'よく使われる但書きの例',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ExampleChip(
                      label: 'お品代として',
                      onTap: () => _textController.text = 'お品代として',
                    ),
                    _ExampleChip(
                      label: 'サービス料として',
                      onTap: () =>
                          _textController.text = 'サービス料として',
                    ),
                    _ExampleChip(
                      label: '交通費として',
                      onTap: () => _textController.text = '交通費として',
                    ),
                    _ExampleChip(
                      label: '宿泊費として',
                      onTap: () => _textController.text = '宿泊費として',
                    ),
                    _ExampleChip(
                      label: '会議費として',
                      onTap: () => _textController.text = '会議費として',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
