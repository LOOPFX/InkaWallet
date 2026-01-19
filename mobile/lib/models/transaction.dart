enum TransactionType {
  send,
  receive,
  deposit,
  withdrawal,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class Transaction {
  final String id;
  final String walletId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String? recipientName;
  final String? recipientPhone;
  final String? recipientWalletProvider;
  final String? senderName;
  final String? senderPhone;
  final String? description;
  final TransactionStatus status;
  final String? referenceNumber;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isSynced;

  Transaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.currency,
    this.recipientName,
    this.recipientPhone,
    this.recipientWalletProvider,
    this.senderName,
    this.senderPhone,
    this.description,
    required this.status,
    this.referenceNumber,
    required this.createdAt,
    this.completedAt,
    this.isSynced = true,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? json['transaction_id'] ?? '',
      walletId: json['wallet_id'] ?? json['walletId'] ?? '',
      type: _parseTransactionType(json['type'] ?? json['transaction_type']),
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'MWK',
      recipientName: json['recipient_name'] ?? json['recipientName'],
      recipientPhone: json['recipient_phone'] ?? json['recipientPhone'],
      recipientWalletProvider: json['recipient_wallet_provider'] ?? 
          json['recipientWalletProvider'],
      senderName: json['sender_name'] ?? json['senderName'],
      senderPhone: json['sender_phone'] ?? json['senderPhone'],
      description: json['description'] ?? json['notes'],
      status: _parseTransactionStatus(json['status']),
      referenceNumber: json['reference_number'] ?? json['referenceNumber'],
      createdAt: DateTime.parse(
        json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: json['completed_at'] != null || json['completedAt'] != null
          ? DateTime.parse(json['completed_at'] ?? json['completedAt'])
          : null,
      isSynced: json['is_synced'] ?? json['isSynced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'recipient_wallet_provider': recipientWalletProvider,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'description': description,
      'status': status.name,
      'reference_number': referenceNumber,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  static TransactionType _parseTransactionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'send':
        return TransactionType.send;
      case 'receive':
        return TransactionType.receive;
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      default:
        return TransactionType.send;
    }
  }

  static TransactionStatus _parseTransactionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
      case 'success':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  String get formattedAmount {
    final prefix = type == TransactionType.receive || 
                   type == TransactionType.deposit ? '+' : '-';
    return '$prefix$currency ${amount.toStringAsFixed(2)}';
  }

  String get displayName {
    if (type == TransactionType.send || type == TransactionType.withdrawal) {
      return recipientName ?? recipientPhone ?? 'Unknown Recipient';
    } else {
      return senderName ?? senderPhone ?? 'Unknown Sender';
    }
  }

  Transaction copyWith({
    String? id,
    String? walletId,
    TransactionType? type,
    double? amount,
    String? currency,
    String? recipientName,
    String? recipientPhone,
    String? recipientWalletProvider,
    String? senderName,
    String? senderPhone,
    String? description,
    TransactionStatus? status,
    String? referenceNumber,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientWalletProvider: recipientWalletProvider ?? this.recipientWalletProvider,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      description: description ?? this.description,
      status: status ?? this.status,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
