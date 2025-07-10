class ClassModel {
  final String id;
  final String grade;
  final String section;
  final String year;
  final double monthlyFee;
  final String? teacherId;
  final List<String> studentIds;

  const ClassModel({
    required this.id,
    required this.grade,
    required this.section,
    required this.year,
    required this.monthlyFee,
    this.teacherId,
    this.studentIds = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'section': section,
      'year': year,
      'monthlyFee': monthlyFee,
      'teacherId': teacherId,
      'studentIds': studentIds,
    };
  }

  // Create from Firestore document
  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] ?? '',
      grade: map['grade'] ?? '',
      section: map['section'] ?? '',
      year: map['year'] ?? '',
      monthlyFee: (map['monthlyFee'] ?? 0.0).toDouble(),
      teacherId: map['teacherId'],
      studentIds: List<String>.from(map['studentIds'] ?? []),
    );
  }

  // Create a copy with updated fields
  ClassModel copyWith({
    String? id,
    String? grade,
    String? section,
    String? year,
    double? monthlyFee,
    String? teacherId,
    List<String>? studentIds,
  }) {
    return ClassModel(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      year: year ?? this.year,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      teacherId: teacherId ?? this.teacherId,
      studentIds: studentIds ?? this.studentIds,
    );
  }

  // Helper method to get class display name
  String get displayName => 'Grade $grade - Section $section';

  @override
  String toString() {
    return 'ClassModel(id: $id, grade: $grade, section: $section, year: $year, monthlyFee: $monthlyFee)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
