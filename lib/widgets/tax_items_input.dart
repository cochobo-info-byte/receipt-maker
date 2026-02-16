import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_models.dart';

/// 税率別品目入力ウィジェット
class TaxItemsInput extends StatefulWidget {
  final List<TaxItem> initialItems;
  final ValueChanged<List<TaxItem>> onChanged;

  const TaxItemsInput({
    super.key,
    required this.initialItems,
    required this.onChanged,
  });

  @override
  State<TaxItemsInput> createState() => _TaxItemsInputState();
}

class _TaxItemsInputState extends State<TaxItemsInput> {
  late List<TaxItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  void _addItem() {
    setState(() {
      _items.add(TaxItem(
        description: '',
        amount: 0,
        taxRate: 0.10,
      ));
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onChanged(_items);
  }

  void _updateItem(int index, TaxItem item) {
    setState(() {
      _items[index] = item;
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '税率別明細（インボイス対応）',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('品目追加'),
              ),
            ],
          ),
        ),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '品目を追加してください',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return _TaxItemCard(
                item: _items[index],
                index: index,
                onUpdate: (item) => _updateItem(index, item),
                onRemove: () => _removeItem(index),
              );
            },
          ),
        if (_items.isNotEmpty) _buildSummary(),
      ],
    );
  }

  Widget _buildSummary() {
    // 税率別集計
    final tax8Items = _items.where((item) => item.taxRate == 0.08).toList();
    final tax10Items = _items.where((item) => item.taxRate == 0.10).toList();

    final subtotal8 = tax8Items.fold(0.0, (sum, item) => sum + item.subtotal);
    final tax8 = tax8Items.fold(0.0, (sum, item) => sum + item.taxAmount);

    final subtotal10 = tax10Items.fold(0.0, (sum, item) => sum + item.subtotal);
    final tax10 = tax10Items.fold(0.0, (sum, item) => sum + item.taxAmount);

    final totalAmount = _items.fold(0.0, (sum, item) => sum + item.amount);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '税率別集計',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (tax8Items.isNotEmpty) ...[
            _summaryRow('8% 対象 小計', subtotal8),
            _summaryRow('消費税（8%）', tax8),
            const Divider(),
          ],
          if (tax10Items.isNotEmpty) ...[
            _summaryRow('10% 対象 小計', subtotal10),
            _summaryRow('消費税（10%）', tax10),
            const Divider(),
          ],
          _summaryRow('合計金額', totalAmount, isBold: true, fontSize: 18),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value,
      {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '¥${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// 品目カードウィジェット
class _TaxItemCard extends StatefulWidget {
  final TaxItem item;
  final int index;
  final ValueChanged<TaxItem> onUpdate;
  final VoidCallback onRemove;

  const _TaxItemCard({
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_TaxItemCard> createState() => _TaxItemCardState();
}

class _TaxItemCardState extends State<_TaxItemCard> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late double _taxRate;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _amountController =
        TextEditingController(text: widget.item.amount > 0 ? widget.item.amount.toStringAsFixed(0) : '');
    _taxRate = widget.item.taxRate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _notifyUpdate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    widget.onUpdate(TaxItem(
      description: _descriptionController.text,
      amount: amount,
      taxRate: _taxRate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '品目 ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: widget.onRemove,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '品目名',
                hintText: '例: お品代、コンサルティング料',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => _notifyUpdate(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: '金額（税込）',
                      prefixText: '¥',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _notifyUpdate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<double>(
                    value: _taxRate,
                    decoration: const InputDecoration(
                      labelText: '税率',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0.08, child: Text('8%')),
                      DropdownMenuItem(value: 0.10, child: Text('10%')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _taxRate = value!;
                      });
                      _notifyUpdate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_amountController.text.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '税抜: ¥${widget.item.subtotal.toStringAsFixed(0)} + 税: ¥${widget.item.taxAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
