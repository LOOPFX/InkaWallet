class Wallet {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final String accountNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Getter alias for accountNumber
  String get walletNumber => accountNumber;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.accountNumber,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? json['wallet_id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'MWK',
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'account_number': accountNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    String? currency,
    String? accountNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      accountNumber: accountNumber ?? this.accountNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedBalance {
    return '$currency ${balance.toStringAsFixed(2)}';
  }
}
