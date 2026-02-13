import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_models.dart';

// Database service using SharedPreferences
class AppDatabase {
  static const String _receiptsKey = 'receipts';
  static const String _issuersKey = 'issuers';

  Future<SharedPreferences> get _prefs async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('❌ Error getting SharedPreferences: $e');
      rethrow;
    }
  }

  // Receipt operations
  Future<List<Receipt>> getAllReceipts() async {
    try {
      final prefs = await _prefs;
      final receiptsJson = prefs.getStringList(_receiptsKey) ?? [];
      return receiptsJson
          .map((json) => Receipt.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ Error getting receipts: $e');
      return []; // Return empty list instead of crashing
    }
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

  Future<String> insertReceipt(Receipt receipt) async {
    final receipts = await getAllReceipts();
    receipts.add(receipt);
    await _saveReceipts(receipts);
    return receipt.id;
  }

  Future<bool> updateReceipt(Receipt receipt) async {
    final receipts = await getAllReceipts();
    final index = receipts.indexWhere((r) => r.id == receipt.id);
    if (index == -1) return false;
    receipts[index] = receipt;
    await _saveReceipts(receipts);
    return true;
  }

  Future<int> deleteReceipt(String id) async {
    final receipts = await getAllReceipts();
    receipts.removeWhere((r) => r.id == id);
    await _saveReceipts(receipts);
    return 1;
  }

  Future<void> markAsSynced(String id, String cloudFileId) async {
    final receipt = await getReceipt(id);
    if (receipt != null) {
      await updateReceipt(receipt.copyWith(
        isSynced: true,
        cloudFileId: cloudFileId,
        updatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> _saveReceipts(List<Receipt> receipts) async {
    final prefs = await _prefs;
    final receiptsJson = receipts.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_receiptsKey, receiptsJson);
  }

  // Issuer profile operations
  Future<List<IssuerProfile>> getAllIssuers() async {
    try {
      final prefs = await _prefs;
      final issuersJson = prefs.getStringList(_issuersKey) ?? [];
      return issuersJson
          .map((json) => IssuerProfile.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting issuers: $e');
      return []; // Return empty list instead of crashing
    }
  }

  Stream<List<IssuerProfile>> watchAllIssuers() async* {
    while (true) {
      yield await getAllIssuers();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<IssuerProfile?> getDefaultIssuer() async {
    final issuers = await getAllIssuers();
    try {
      return issuers.firstWhere((i) => i.isDefault);
    } catch (e) {
      return null;
    }
  }

  Future<String> insertIssuer(IssuerProfile issuer) async {
    final issuers = await getAllIssuers();
    issuers.add(issuer);
    await _saveIssuers(issuers);
    return issuer.id;
  }

  Future<bool> updateIssuer(IssuerProfile issuer) async {
    final issuers = await getAllIssuers();
    final index = issuers.indexWhere((i) => i.id == issuer.id);
    if (index == -1) return false;
    issuers[index] = issuer;
    await _saveIssuers(issuers);
    return true;
  }

  Future<int> deleteIssuer(String id) async {
    final issuers = await getAllIssuers();
    issuers.removeWhere((i) => i.id == id);
    await _saveIssuers(issuers);
    return 1;
  }

  Future<void> setDefaultIssuer(String id) async {
    final issuers = await getAllIssuers();
    for (int i = 0; i < issuers.length; i++) {
      if (issuers[i].id == id) {
        issuers[i] = IssuerProfile(
          id: issuers[i].id,
          companyName: issuers[i].companyName,
          companyAddress: issuers[i].companyAddress,
          phoneNumber: issuers[i].phoneNumber,
          email: issuers[i].email,
          registrationNumber: issuers[i].registrationNumber,
          isDefault: true,
          createdAt: issuers[i].createdAt,
        );
      } else if (issuers[i].isDefault) {
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
    await _saveIssuers(issuers);
  }

  Future<void> _saveIssuers(List<IssuerProfile> issuers) async {
    final prefs = await _prefs;
    final issuersJson = issuers.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_issuersKey, issuersJson);
  }

  Future<void> close() async {
    // No cleanup needed for SharedPreferences
  }
}
