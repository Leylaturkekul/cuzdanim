enum TransactionType { income, expense }

class WalletUser {
  const WalletUser({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory WalletUser.fromJson(Map<String, dynamic> json) => WalletUser(
    id: _asInt(json['id']),
    name: (json['name'] ?? 'Kullanıcı').toString(),
    email: (json['email'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.pendingSync = false,
  });

  final int id;
  final int userId;
  final double amount;
  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;
  final bool pendingSync;

  bool get isIncome => type == TransactionType.income;

  WalletTransaction copyWith({
    int? id,
    int? userId,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    bool? pendingSync,
  }) => WalletTransaction(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    category: category ?? this.category,
    description: description ?? this.description,
    date: date ?? this.date,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  factory WalletTransaction.fromJson(
    Map<String, dynamic> json,
  ) => WalletTransaction(
    id: _asInt(json['id']),
    userId: _asInt(json['userId'] ?? json['user_id']),
    amount: _asDouble(json['amount']),
    type: (json['type'] ?? '').toString().toLowerCase() == 'income'
        ? TransactionType.income
        : TransactionType.expense,
    category: (json['category'] ?? 'Diğer').toString(),
    description: (json['description'] ?? '').toString(),
    date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
    pendingSync: json['pendingSync'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'amount': amount,
    'type': isIncome ? 'income' : 'expense',
    'category': category,
    'description': description,
    'date': date.toIso8601String().split('T').first,
    'pendingSync': pendingSync,
  };
}

class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.month,
    this.pendingSync = false,
  });

  final int id;
  final int userId;
  final String category;
  final double amount;
  final DateTime month;
  final bool pendingSync;

  Budget copyWith({
    int? id,
    String? category,
    double? amount,
    DateTime? month,
    bool? pendingSync,
  }) => Budget(
    id: id ?? this.id,
    userId: userId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    month: month ?? this.month,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: _asInt(json['id']),
    userId: _asInt(json['userId'] ?? json['user_id']),
    category: (json['category'] ?? 'Genel').toString(),
    amount: _asDouble(json['amount']),
    month:
        DateTime.tryParse((json['month'] ?? '').toString()) ??
        DateTime(DateTime.now().year, DateTime.now().month),
    pendingSync: json['pendingSync'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'category': category,
    'amount': amount,
    'month': '${month.year}-${month.month.toString().padLeft(2, '0')}-01',
    'pendingSync': pendingSync,
  };
}

int _asInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

double _asDouble(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
