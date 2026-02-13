// Data models for Receipt Maker app

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

