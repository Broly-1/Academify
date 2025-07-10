class Attendance {
  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final bool isPresent;
  final String? remarks;
  final DateTime createdAt;
  final String createdBy; // Teacher who marked attendance

  const Attendance({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.isPresent,
    this.remarks,
    required this.createdAt,
    required this.createdBy,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // Create from Firestore document
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      isPresent: map['isPresent'] ?? false,
      remarks: map['remarks'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Create a copy with updated fields
  Attendance copyWith({
    String? id,
    String? classId,
    String? studentId,
    DateTime? date,
    bool? isPresent,
    String? remarks,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Attendance(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'Attendance(id: $id, classId: $classId, studentId: $studentId, date: $date, isPresent: $isPresent, remarks: $remarks, createdBy: $createdBy)';
  }
}
