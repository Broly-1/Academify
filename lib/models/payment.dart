class Payment {
  final String id;
  final String studentId;
  final String classId;
  final String month;
  final int year;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;
  final String? receiptNumber;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.month,
    required this.year,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
    this.receiptNumber,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'classId': classId,
      'month': month,
      'year': year,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'isPaid': isPaid,
      'receiptNumber': receiptNumber,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      month: map['month'] ?? '',
      year: map['year'] ?? 0,
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate: DateTime.parse(
        map['dueDate'] ?? DateTime.now().toIso8601String(),
      ),
      paidDate: map['paidDate'] != null
          ? DateTime.parse(map['paidDate'])
          : null,
      isPaid: map['isPaid'] ?? false,
      receiptNumber: map['receiptNumber'],
      paymentMethod: map['paymentMethod'],
      notes: map['notes'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? studentId,
    String? classId,
    String? month,
    int? year,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    bool? isPaid,
    String? receiptNumber,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      isPaid: isPaid ?? this.isPaid,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if payment is overdue
  bool get isOverdue {
    if (isPaid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  @override
  String toString() {
    return 'Payment(id: $id, studentId: $studentId, amount: $amount, isPaid: $isPaid, receiptNumber: $receiptNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
