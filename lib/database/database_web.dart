import 'dart:html' as html;
import 'dart:convert';
import 'database_models.dart';

/// Web専用のデータベース実装
/// LocalStorageを直接使用してshared_preferencesプラグインの問題を回避
class AppDatabaseWeb {
  static const String _receiptsKey = 'receipts';
  static const String _issuersKey = 'issuers';

  final html.Storage _localStorage = html.window.localStorage;

  // Receipt operations
  Future<List<Receipt>> getAllReceipts() async {
    final receiptsJson = _localStorage[_receiptsKey];
    if (receiptsJson == null || receiptsJson.isEmpty) return [];
    
    final List<dynamic> list = jsonDecode(receiptsJson);
    return list
        .map((json) => Receipt.fromJson(json))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Receipt>> getRecentReceipts({int limit = 20}) async {
    final receipts = await getAllReceipts();
    return receipts.take(limit).toList();
  }

  Stream<List<Receipt>> watchAllReceipts() async* {
    while (true) {
      yield await getAllReceipts();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<Receipt?> getReceipt(String id) async {
    final receipts = await getAllReceipts();
    try {
      return receipts.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> insertReceipt(Receipt receipt) async {
    final receipts = await getAllReceipts();
    receipts.insert(0, receipt);
    await _saveReceipts(receipts);
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final receipts = await getAllReceipts();
    final index = receipts.indexWhere((r) => r.id == receipt.id);
    if (index != -1) {
      receipts[index] = receipt;
      await _saveReceipts(receipts);
    }
  }

  Future<void> deleteReceipt(String id) async {
    final receipts = await getAllReceipts();
    receipts.removeWhere((r) => r.id == id);
    await _saveReceipts(receipts);
  }

  Future<void> _saveReceipts(List<Receipt> receipts) async {
    final jsonList = receipts.map((r) => r.toJson()).toList();
    _localStorage[_receiptsKey] = jsonEncode(jsonList);
  }

  Future<void> markAsSynced(String id, String cloudFileId) async {
    final receipts = await getAllReceipts();
    final index = receipts.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updated = Receipt(
        id: receipts[index].id,
        receiptNumber: receipts[index].receiptNumber,
        issueDate: receipts[index].issueDate,
        recipientName: receipts[index].recipientName,
        recipientAddress: receipts[index].recipientAddress,
        amount: receipts[index].amount,
        description: receipts[index].description,
        paymentMethod: receipts[index].paymentMethod,
        issuerId: receipts[index].issuerId,
        isSynced: true,
        cloudFileId: cloudFileId,
        createdAt: receipts[index].createdAt,
        updatedAt: DateTime.now(),
      );
      receipts[index] = updated;
      await _saveReceipts(receipts);
    }
  }

  Future<List<Receipt>> searchReceipts(String query) async {
    final receipts = await getAllReceipts();
    return receipts.where((r) {
      final lowerQuery = query.toLowerCase();
      return r.receiptNumber.toLowerCase().contains(lowerQuery) ||
          r.recipientName.toLowerCase().contains(lowerQuery) ||
          r.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<List<Receipt>> filterByPaymentMethod(String paymentMethod) async {
    final receipts = await getAllReceipts();
    return receipts
        .where((r) => r.paymentMethod == paymentMethod)
        .toList();
  }

  // Issuer Profile operations
  Future<List<IssuerProfile>> getAllIssuers() async {
    final issuersJson = _localStorage[_issuersKey];
    if (issuersJson == null || issuersJson.isEmpty) return [];
    
    final List<dynamic> list = jsonDecode(issuersJson);
    return list
        .map((json) => IssuerProfile.fromJson(json))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<IssuerProfile?> getDefaultIssuer() async {
    final issuers = await getAllIssuers();
    try {
      return issuers.firstWhere((i) => i.isDefault);
    } catch (e) {
      return issuers.isNotEmpty ? issuers.first : null;
    }
  }

  Future<void> insertIssuer(IssuerProfile issuer) async {
    final issuers = await getAllIssuers();
    
    if (issuer.isDefault) {
      for (var i = 0; i < issuers.length; i++) {
        issuers[i] = IssuerProfile(
          id: issuers[i].id,
          companyName: issuers[i].companyName,
          companyAddress: issuers[i].companyAddress,
          phoneNumber: issuers[i].phoneNumber,
          email: issuers[i].email,
          registrationNumber: issuers[i].registrationNumber,
          isDefault: false,
          createdAt: issuers[i].createdAt,
        );
      }
    }
    
    issuers.insert(0, issuer);
    await _saveIssuers(issuers);
  }

  Future<void> updateIssuer(IssuerProfile issuer) async {
    final issuers = await getAllIssuers();
    final index = issuers.indexWhere((i) => i.id == issuer.id);
    
    if (index != -1) {
      if (issuer.isDefault) {
        for (var i = 0; i < issuers.length; i++) {
          if (i != index) {
            issuers[i] = IssuerProfile(
              id: issuers[i].id,
              companyName: issuers[i].companyName,
              companyAddress: issuers[i].companyAddress,
              phoneNumber: issuers[i].phoneNumber,
              email: issuers[i].email,
              registrationNumber: issuers[i].registrationNumber,
              isDefault: false,
              createdAt: issuers[i].createdAt,
            );
          }
        }
      }
      
      issuers[index] = issuer;
      await _saveIssuers(issuers);
    }
  }

  Future<void> deleteIssuer(String id) async {
    final issuers = await getAllIssuers();
    issuers.removeWhere((i) => i.id == id);
    await _saveIssuers(issuers);
  }

  Future<void> _saveIssuers(List<IssuerProfile> issuers) async {
    final jsonList = issuers.map((i) => i.toJson()).toList();
    _localStorage[_issuersKey] = jsonEncode(jsonList);
  }

  Stream<List<IssuerProfile>> watchAllIssuers() async* {
    while (true) {
      yield await getAllIssuers();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> setDefaultIssuer(String id) async {
    final issuers = await getAllIssuers();
    final index = issuers.indexWhere((i) => i.id == id);
    
    if (index != -1) {
      // Clear all defaults
      for (var i = 0; i < issuers.length; i++) {
        issuers[i] = IssuerProfile(
          id: issuers[i].id,
          companyName: issuers[i].companyName,
          companyAddress: issuers[i].companyAddress,
          phoneNumber: issuers[i].phoneNumber,
          email: issuers[i].email,
          registrationNumber: issuers[i].registrationNumber,
          isDefault: i == index,
          createdAt: issuers[i].createdAt,
        );
      }
      await _saveIssuers(issuers);
    }
  }

  Future<void> close() async {
    // No-op for web
  }
}

// Type alias for compatibility with main.dart
typedef AppDatabase = AppDatabaseWeb;
