class Expense {
  int? id;
  double amount;
  String vendor;
  String description;
  String? imagePath;
  DateTime dateTime;
  bool isClaimed;

  Expense({
    this.id,
    required this.amount,
    required this.vendor,
    required this.description,
    this.imagePath,
    required this.dateTime,
    this.isClaimed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'vendor': vendor,
      'description': description,
      'imagePath': imagePath,
      'dateTime': dateTime.toIso8601String(),
      'isClaimed': isClaimed ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      vendor: map['vendor'],
      description: map['description'],
      imagePath: map['imagePath'],
      dateTime: DateTime.parse(map['dateTime']),
      isClaimed: map['isClaimed'] == 1,
    );
  }
}
