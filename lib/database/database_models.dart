// Data models for Receipt Maker app

// Tax item model for invoice compliance
class TaxItem {
  final String description;  // 品目
  final double amount;        // 金額（税込み）
  final double taxRate;       // 税率（0.08 or 0.10）

  TaxItem({
    required this.description,
    required this.amount,
    required this.taxRate,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'taxRate': taxRate,
      };

  factory TaxItem.fromJson(Map<String, dynamic> json) => TaxItem(
        description: json['description'],
        amount: json['amount'].toDouble(),
        taxRate: json['taxRate'].toDouble(),
      );

  // 税抜き金額を計算
  double get subtotal => amount / (1 + taxRate);

  // 消費税額を計算
  double get taxAmount => amount - subtotal;
}

// Receipt model
class Receipt {
  final String id;
  final String receiptNumber;
  final DateTime issueDate;
  final String recipientName;
  final String? recipientAddress;
  final double amount;
  final String description;
  final String paymentMethod;
  final int? issuerId;
  final bool isSynced;
  final String? cloudFileId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double taxRate; // 消費税率（0.10 = 10%）
  final bool includeTax; // 税込み価格かどうか
  final List<TaxItem>? taxItems; // 税率別明細（インボイス対応）

  Receipt({
    required this.id,
    required this.receiptNumber,
    required this.issueDate,
    required this.recipientName,
    this.recipientAddress,
    required this.amount,
    required this.description,
    this.paymentMethod = '現金',
    this.issuerId,
    this.isSynced = false,
    this.cloudFileId,
    required this.createdAt,
    required this.updatedAt,
    this.taxRate = 0.10, // デフォルト10%
    this.includeTax = true, // デフォルト税込み
    this.taxItems, // 税率別明細（オプション）
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNumber': receiptNumber,
        'issueDate': issueDate.toIso8601String(),
        'recipientName': recipientName,
        'recipientAddress': recipientAddress,
        'amount': amount,
        'description': description,
        'paymentMethod': paymentMethod,
        'issuerId': issuerId,
        'isSynced': isSynced,
        'cloudFileId': cloudFileId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'taxRate': taxRate,
        'includeTax': includeTax,
        'taxItems': taxItems?.map((item) => item.toJson()).toList(),
      };

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'],
        receiptNumber: json['receiptNumber'],
        issueDate: DateTime.parse(json['issueDate']),
        recipientName: json['recipientName'],
        recipientAddress: json['recipientAddress'],
        amount: json['amount'].toDouble(),
        description: json['description'],
        paymentMethod: json['paymentMethod'] ?? '現金',
        issuerId: json['issuerId'],
        isSynced: json['isSynced'] ?? false,
        cloudFileId: json['cloudFileId'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        taxRate: json['taxRate']?.toDouble() ?? 0.10,
        includeTax: json['includeTax'] ?? true,
        taxItems: json['taxItems'] != null 
            ? (json['taxItems'] as List).map((item) => TaxItem.fromJson(item)).toList()
            : null,
      );

  Receipt copyWith({
    String? id,
    String? receiptNumber,
    DateTime? issueDate,
    String? recipientName,
    String? recipientAddress,
    double? amount,
    String? description,
    String? paymentMethod,
    int? issuerId,
    bool? isSynced,
    String? cloudFileId,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? taxRate,
    bool? includeTax,
    List<TaxItem>? taxItems,
  }) {
    return Receipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      issueDate: issueDate ?? this.issueDate,
      recipientName: recipientName ?? this.recipientName,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      issuerId: issuerId ?? this.issuerId,
      isSynced: isSynced ?? this.isSynced,
      cloudFileId: cloudFileId ?? this.cloudFileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taxRate: taxRate ?? this.taxRate,
      includeTax: includeTax ?? this.includeTax,
      taxItems: taxItems ?? this.taxItems,
    );
  }
}

// Issuer Profile model
class IssuerProfile {
  final String id;
  final String companyName;
  final String companyAddress;
  final String? phoneNumber;
  final String? email;
  final String? registrationNumber;
  final bool isDefault;
  final DateTime createdAt;

  IssuerProfile({
    required this.id,
    required this.companyName,
    required this.companyAddress,
    this.phoneNumber,
    this.email,
    this.registrationNumber,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyName': companyName,
        'companyAddress': companyAddress,
        'phoneNumber': phoneNumber,
        'email': email,
        'registrationNumber': registrationNumber,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
      };

  factory IssuerProfile.fromJson(Map<String, dynamic> json) => IssuerProfile(
        id: json['id'],
        companyName: json['companyName'],
        companyAddress: json['companyAddress'],
        phoneNumber: json['phoneNumber'],
        email: json['email'],
        registrationNumber: json['registrationNumber'],
        isDefault: json['isDefault'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Recipient (宛名) model
class RecipientTemplate {
  final String id;
  final String name;
  final String? address;
  final DateTime createdAt;

  RecipientTemplate({
    required this.id,
    required this.name,
    this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecipientTemplate.fromJson(Map<String, dynamic> json) =>
      RecipientTemplate(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Issuer (発行者) template model
class IssuerTemplate {
  final String id;
  final String name;
  final DateTime createdAt;

  IssuerTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory IssuerTemplate.fromJson(Map<String, dynamic> json) => IssuerTemplate(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Description (但書き) template model
class DescriptionTemplate {
  final String id;
  final String text;
  final DateTime createdAt;

  DescriptionTemplate({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DescriptionTemplate.fromJson(Map<String, dynamic> json) =>
      DescriptionTemplate(
        id: json['id'],
        text: json['text'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

