import 'database_models.dart';

/// Stub implementation (should never be used)
class AppDatabase {
  Future<List<Receipt>> getAllReceipts() async => throw UnimplementedError();
  Future<List<Receipt>> getRecentReceipts({int limit = 20}) async => throw UnimplementedError();
  Stream<List<Receipt>> watchAllReceipts() => throw UnimplementedError();
  Future<Receipt?> getReceipt(String id) async => throw UnimplementedError();
  Future<void> insertReceipt(Receipt receipt) async => throw UnimplementedError();
  Future<void> updateReceipt(Receipt receipt) async => throw UnimplementedError();
  Future<void> deleteReceipt(String id) async => throw UnimplementedError();
  Future<void> markAsSynced(String id, String cloudFileId) async => throw UnimplementedError();
  Future<List<Receipt>> searchReceipts(String query) async => throw UnimplementedError();
  Future<List<Receipt>> filterByPaymentMethod(String paymentMethod) async => throw UnimplementedError();
  Future<List<IssuerProfile>> getAllIssuers() async => throw UnimplementedError();
  Future<IssuerProfile?> getDefaultIssuer() async => throw UnimplementedError();
  Future<void> insertIssuer(IssuerProfile issuer) async => throw UnimplementedError();
  Future<void> updateIssuer(IssuerProfile issuer) async => throw UnimplementedError();
  Future<IssuerProfile?> getIssuerById(int id) async => throw UnimplementedError();
  Future<void> deleteIssuer(String id) async => throw UnimplementedError();
  Stream<List<IssuerProfile>> watchAllIssuers() => throw UnimplementedError();
  Future<void> setDefaultIssuer(String id) async => throw UnimplementedError();
  Future<List<RecipientTemplate>> getAllRecipients() async => throw UnimplementedError();
  Future<void> insertRecipient(RecipientTemplate recipient) async => throw UnimplementedError();
  Future<void> updateRecipient(RecipientTemplate recipient) async => throw UnimplementedError();
  Future<void> deleteRecipient(String id) async => throw UnimplementedError();
  Future<List<IssuerTemplate>> getAllIssuerTemplates() async => throw UnimplementedError();
  Future<void> insertIssuerTemplate(IssuerTemplate template) async => throw UnimplementedError();
  Future<void> updateIssuerTemplate(IssuerTemplate template) async => throw UnimplementedError();
  Future<void> deleteIssuerTemplate(String id) async => throw UnimplementedError();
  Future<List<DescriptionTemplate>> getAllDescriptions() async => throw UnimplementedError();
  Future<void> insertDescription(DescriptionTemplate description) async => throw UnimplementedError();
  Future<void> updateDescription(DescriptionTemplate description) async => throw UnimplementedError();
  Future<void> deleteDescription(String id) async => throw UnimplementedError();
  Future<void> close() async {}
}

// Type alias for compatibility
typedef AppDatabaseWeb = AppDatabase;
