class Teacher {
  final String id;
  final String name;
  final String email;

  const Teacher({required this.id, required this.name, required this.email});

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email};
  }

  // Create from Firestore document
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
    );
  }

  // Create a copy with updated fields
  Teacher copyWith({String? id, String? name, String? email}) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  @override
  String toString() {
    return 'Teacher(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Teacher && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
