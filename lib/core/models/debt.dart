enum DebtType { owedToMe, iOwe }

class Debt {
  final String id;
  final String personName;
  final String? description;
  final double amount;
  final DebtType type;
  final DateTime startDate;
  final DateTime? dueDate;
  final int totalInstallments;
  final String? accountId; // If initially funded/received from an account
  final double currentAmount; // Derived from repayments and initial amount

  Debt({
    required this.id,
    required this.personName,
    this.description,
    required this.amount,
    required this.type,
    required this.startDate,
    this.dueDate,
    this.totalInstallments = 0,
    this.accountId,
    this.currentAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'description': description,
      'amount': amount,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'totalInstallments': totalInstallments,
      'accountId': accountId,
      'currentAmount': currentAmount,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      personName: map['personName'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      type: DebtType.values.byName(map['type']),
      startDate: DateTime.parse(map['startDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      totalInstallments: map['totalInstallments'] ?? 0,
      accountId: map['accountId'],
      currentAmount: map['currentAmount'] != null
          ? (map['currentAmount'] as num).toDouble()
          : 0.0,
    );
  }
}
