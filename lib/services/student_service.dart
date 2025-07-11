import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuition_app/models/student.dart';

class StudentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'students';

  // Create a new student
  static Future<String> createStudent(Student student) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final studentWithId = student.copyWith(id: docRef.id);
      await docRef.set(studentWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  // Get all students
  static Stream<List<Student>> getAllStudents() {
    return _firestore.collection(_collection).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
    });
  }

  // Get a specific student by ID

  // Get multiple students by IDs
  static Future<List<Student>> getStudentsByIds(List<String> studentIds) async {
    if (studentIds.isEmpty) return [];

    try {
      final List<Student> students = [];

      // Firestore 'in' queries are limited to 10 items, so we need to batch them
      for (int i = 0; i < studentIds.length; i += 10) {
        final batch = studentIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('id', whereIn: batch)
            .get();

        students.addAll(
          querySnapshot.docs.map((doc) => Student.fromMap(doc.data())).toList(),
        );
      }

      return students;
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  // Update a student
  static Future<void> updateStudent(Student student) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(student.id)
          .update(student.toMap());
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Delete a student
  static Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection(_collection).doc(studentId).delete();
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}
