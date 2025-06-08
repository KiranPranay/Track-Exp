// lib/models/expense.dart

class Expense {
  int? id;
  double amount;
  String vendor;
  String description;
  String? imagePath;
  DateTime dateTime;
  bool isClaimed;
  int? projectId; // ← new foreign key

  Expense({
    this.id,
    required this.amount,
    required this.vendor,
    required this.description,
    this.imagePath,
    required this.dateTime,
    this.isClaimed = false,
    this.projectId,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'amount': amount,
    'vendor': vendor,
    'description': description,
    'imagePath': imagePath,
    'dateTime': dateTime.toIso8601String(),
    'isClaimed': isClaimed ? 1 : 0,
    'projectId': projectId,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'],
    amount: m['amount'],
    vendor: m['vendor'],
    description: m['description'],
    imagePath: m['imagePath'],
    dateTime: DateTime.parse(m['dateTime']),
    isClaimed: m['isClaimed'] == 1,
    projectId: m['projectId'],
  );
}
