import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuition_app/models/class_model.dart';

class ClassService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'classes';

  // Create a new class
  static Future<String> createClass(ClassModel classModel) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final classWithId = classModel.copyWith(id: docRef.id);
      await docRef.set(classWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  // Get all classes
  static Stream<List<ClassModel>> getAllClasses() {
    return _firestore.collection(_collection).orderBy('grade').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ClassModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get a specific class by ID
  static Future<ClassModel?> getClass(String classId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(classId).get();
      if (doc.exists) {
        return ClassModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get class: $e');
    }
  }

  // Update a class
  static Future<void> updateClass(ClassModel classModel) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(classModel.id)
          .update(classModel.toMap());
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  // Delete a class
  static Future<void> deleteClass(String classId) async {
    try {
      await _firestore.collection(_collection).doc(classId).delete();
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

  // Get classes assigned to a specific teacher
  static Stream<List<ClassModel>> getClassesByTeacher(String teacherId) {
    return _firestore
        .collection(_collection)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('grade')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ClassModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Assign teacher to class
  static Future<void> assignTeacher(String classId, String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'teacherId': teacherId,
      });
    } catch (e) {
      throw Exception('Failed to assign teacher: $e');
    }
  }

  // Remove teacher from class
  static Future<void> removeTeacher(String classId) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'teacherId': null,
      });
    } catch (e) {
      throw Exception('Failed to remove teacher: $e');
    }
  }

  // Add student to class
  static Future<void> addStudentToClass(
    String classId,
    String studentId,
  ) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'studentIds': FieldValue.arrayUnion([studentId]),
      });
    } catch (e) {
      throw Exception('Failed to add student to class: $e');
    }
  }

  // Remove student from class
  static Future<void> removeStudentFromClass(
    String classId,
    String studentId,
  ) async {
    try {
      await _firestore.collection(_collection).doc(classId).update({
        'studentIds': FieldValue.arrayRemove([studentId]),
      });
    } catch (e) {
      throw Exception('Failed to remove student from class: $e');
    }
  }
}
