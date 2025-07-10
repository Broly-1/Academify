class Student {
  final String id;
  final String name;
  final String parentContact;

  const Student({
    required this.id,
    required this.name,
    required this.parentContact,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'parentContact': parentContact};
  }

  // Create from Firestore document
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      parentContact: map['parentContact'] ?? '',
    );
  }

  // Create a copy with updated fields
  Student copyWith({String? id, String? name, String? parentContact}) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      parentContact: parentContact ?? this.parentContact,
    );
  }

  @override
  String toString() {
    return 'Student(id: $id, name: $name, parentContact: $parentContact)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
