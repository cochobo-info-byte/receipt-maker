import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_models.dart';

// Database service using SharedPreferences
class AppDatabase {
  static const String _receiptsKey = 'receipts';
  static const String _issuersKey = 'issuers';
  static const String _recipientsKey = 'recipients';
  static const String _issuerTemplatesKey = 'issuer_templates';
  static const String _descriptionsKey = 'descriptions';

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

  Future<IssuerProfile?> getIssuerById(int id) async {
    final issuers = await getAllIssuers();
    try {
      return issuers.firstWhere((i) => i.id == id.toString());
    } catch (e) {
      return null;
    }
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

  // Recipient template operations
  Future<List<RecipientTemplate>> getAllRecipients() async {
    try {
      final prefs = await _prefs;
      final recipientsJson = prefs.getStringList(_recipientsKey) ?? [];
      return recipientsJson
          .map((json) => RecipientTemplate.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ Error getting recipients: $e');
      return [];
    }
  }

  Future<String> insertRecipient(RecipientTemplate recipient) async {
    final recipients = await getAllRecipients();
    recipients.add(recipient);
    await _saveRecipients(recipients);
    return recipient.id;
  }

  Future<bool> updateRecipient(RecipientTemplate recipient) async {
    final recipients = await getAllRecipients();
    final index = recipients.indexWhere((r) => r.id == recipient.id);
    if (index == -1) return false;
    recipients[index] = recipient;
    await _saveRecipients(recipients);
    return true;
  }

  Future<int> deleteRecipient(String id) async {
    final recipients = await getAllRecipients();
    recipients.removeWhere((r) => r.id == id);
    await _saveRecipients(recipients);
    return 1;
  }

  Future<void> _saveRecipients(List<RecipientTemplate> recipients) async {
    final prefs = await _prefs;
    final recipientsJson =
        recipients.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_recipientsKey, recipientsJson);
  }

  // Issuer template operations
  Future<List<IssuerTemplate>> getAllIssuerTemplates() async {
    try {
      final prefs = await _prefs;
      final templatesJson = prefs.getStringList(_issuerTemplatesKey) ?? [];
      return templatesJson
          .map((json) => IssuerTemplate.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ Error getting issuer templates: $e');
      return [];
    }
  }

  Future<String> insertIssuerTemplate(IssuerTemplate template) async {
    final templates = await getAllIssuerTemplates();
    templates.add(template);
    await _saveIssuerTemplates(templates);
    return template.id;
  }

  Future<bool> updateIssuerTemplate(IssuerTemplate template) async {
    final templates = await getAllIssuerTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index == -1) return false;
    templates[index] = template;
    await _saveIssuerTemplates(templates);
    return true;
  }

  Future<int> deleteIssuerTemplate(String id) async {
    final templates = await getAllIssuerTemplates();
    templates.removeWhere((t) => t.id == id);
    await _saveIssuerTemplates(templates);
    return 1;
  }

  Future<void> _saveIssuerTemplates(List<IssuerTemplate> templates) async {
    final prefs = await _prefs;
    final templatesJson =
        templates.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_issuerTemplatesKey, templatesJson);
  }

  // Description template operations
  Future<List<DescriptionTemplate>> getAllDescriptions() async {
    try {
      final prefs = await _prefs;
      final descriptionsJson = prefs.getStringList(_descriptionsKey) ?? [];
      return descriptionsJson
          .map((json) => DescriptionTemplate.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ Error getting descriptions: $e');
      return [];
    }
  }

  Future<String> insertDescription(DescriptionTemplate description) async {
    final descriptions = await getAllDescriptions();
    descriptions.add(description);
    await _saveDescriptions(descriptions);
    return description.id;
  }

  Future<bool> updateDescription(DescriptionTemplate description) async {
    final descriptions = await getAllDescriptions();
    final index = descriptions.indexWhere((d) => d.id == description.id);
    if (index == -1) return false;
    descriptions[index] = description;
    await _saveDescriptions(descriptions);
    return true;
  }

  Future<int> deleteDescription(String id) async {
    final descriptions = await getAllDescriptions();
    descriptions.removeWhere((d) => d.id == id);
    await _saveDescriptions(descriptions);
    return 1;
  }

  Future<void> _saveDescriptions(List<DescriptionTemplate> descriptions) async {
    final prefs = await _prefs;
    final descriptionsJson =
        descriptions.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_descriptionsKey, descriptionsJson);
  }

  Future<void> close() async {
    // No cleanup needed for SharedPreferences
  }
}
