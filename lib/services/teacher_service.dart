import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuition_app/models/teacher.dart';

class TeacherService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'teachers';

  // Create a new teacher with Firebase Auth account
  static Future<String> createTeacherWithAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // First create the teacher profile
      final teacher = Teacher(id: '', name: name, email: email);

      final teacherId = await createTeacher(teacher);

      // Note: We'll handle Firebase Auth account creation in the UI
      // to avoid session conflicts

      return teacherId;
    } catch (e) {
      throw Exception('Failed to create teacher with account: $e');
    }
  }

  // Create a new teacher profile
  static Future<String> createTeacher(Teacher teacher) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final teacherWithId = teacher.copyWith(id: docRef.id);
      await docRef.set(teacherWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create teacher: $e');
    }
  }

  // Get all teachers
  static Stream<List<Teacher>> getAllTeachers() {
    return _firestore.collection(_collection).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Teacher.fromMap(doc.data())).toList();
    });
  }

  // Get a specific teacher by ID
  static Future<Teacher?> getTeacher(String teacherId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(teacherId).get();
      if (doc.exists) {
        return Teacher.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get teacher: $e');
    }
  }

  // Get teacher by email
  static Future<Teacher?> getTeacherByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Teacher.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get teacher by email: $e');
    }
  }

  // Update a teacher
  static Future<void> updateTeacher(Teacher teacher) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(teacher.id)
          .update(teacher.toMap());
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  // Delete a teacher
  static Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(teacherId).delete();
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }

  // Create or update teacher profile (for when teacher logs in)
  static Future<void> createOrUpdateTeacherProfile(
    String email,
    String name,
  ) async {
    try {
      final existingTeacher = await getTeacherByEmail(email);

      if (existingTeacher != null) {
        // Update existing teacher
        final updatedTeacher = existingTeacher.copyWith(name: name);
        await updateTeacher(updatedTeacher);
      } else {
        // Create new teacher
        final newTeacher = Teacher(id: '', name: name, email: email);
        await createTeacher(newTeacher);
      }
    } catch (e) {
      throw Exception('Failed to create or update teacher profile: $e');
    }
  }

  // Search teachers by name
  static Stream<List<Teacher>> searchTeachers(String searchTerm) {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .startAt([searchTerm])
        .endAt([searchTerm + '\uf8ff'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Teacher.fromMap(doc.data()))
              .toList();
        });
  }
}
