import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuition_app/models/attendance.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'attendance';

  // Mark attendance for a student
  static Future<String> markAttendance(Attendance attendance) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final attendanceWithId = attendance.copyWith(id: docRef.id);
      await docRef.set(attendanceWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // Get attendance for a specific class on a specific date
  static Future<List<Attendance>> getClassAttendanceByDate(
    String classId,
    DateTime date,
  ) async {
    try {
      // Use a simpler query and filter in memory to avoid index issues
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId)
          .get();

      final targetDate = DateTime(date.year, date.month, date.day);

      return querySnapshot.docs
          .map((doc) => Attendance.fromMap(doc.data()))
          .where((attendance) {
            final attendanceDate = DateTime(
              attendance.date.year,
              attendance.date.month,
              attendance.date.day,
            );
            return attendanceDate.isAtSameMomentAs(targetDate);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get class attendance: $e');
    }
  }

  // Get attendance for a specific student
  static Future<List<Attendance>> getStudentAttendance(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use simpler query without date range ordering
      Query query = _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId);

      final querySnapshot = await query.get();
      var attendanceRecords = querySnapshot.docs
          .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by date range in memory
      if (startDate != null || endDate != null) {
        attendanceRecords = attendanceRecords.where((record) {
          if (startDate != null && record.date.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && record.date.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Sort by date descending in memory
      attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

      return attendanceRecords;
    } catch (e) {
      throw Exception('Failed to get student attendance: $e');
    }
  }

  // Get attendance statistics for a student in a class
  static Future<Map<String, dynamic>> getStudentAttendanceStats(
    String studentId,
    String classId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use simpler query without date range
      Query query = _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId);

      final querySnapshot = await query.get();
      var attendanceRecords = querySnapshot.docs
          .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by date range in memory to avoid index requirements
      if (startDate != null || endDate != null) {
        attendanceRecords = attendanceRecords.where((record) {
          if (startDate != null && record.date.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && record.date.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      final totalDays = attendanceRecords.length;
      final presentDays = attendanceRecords
          .where((attendance) => attendance.isPresent)
          .length;
      final absentDays = totalDays - presentDays;
      final attendancePercentage = totalDays > 0
          ? (presentDays / totalDays) * 100
          : 0.0;

      return {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'attendancePercentage': attendancePercentage,
      };
    } catch (e) {
      throw Exception('Failed to get student attendance stats: $e');
    }
  }

  // Get class attendance statistics for a date range
  static Future<Map<String, dynamic>> getClassAttendanceStats(
    String classId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use simpler query without date range initially
      Query query = _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId);

      final querySnapshot = await query.get();
      var attendanceRecords = querySnapshot.docs
          .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by date range in memory to avoid index requirements
      if (startDate != null || endDate != null) {
        attendanceRecords = attendanceRecords.where((record) {
          if (startDate != null && record.date.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && record.date.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Group by date to get daily stats
      final Map<String, List<Attendance>> dailyAttendance = {};
      for (final record in attendanceRecords) {
        final dateKey =
            '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
        dailyAttendance.putIfAbsent(dateKey, () => []).add(record);
      }

      final dailyStats = <Map<String, dynamic>>[];
      for (final entry in dailyAttendance.entries) {
        final totalStudents = entry.value.length;
        final presentStudents = entry.value
            .where((record) => record.isPresent)
            .length;
        final absentStudents = totalStudents - presentStudents;
        final attendancePercentage = totalStudents > 0
            ? (presentStudents / totalStudents) * 100
            : 0.0;

        dailyStats.add({
          'date': entry.key,
          'totalStudents': totalStudents,
          'presentStudents': presentStudents,
          'absentStudents': absentStudents,
          'attendancePercentage': attendancePercentage,
        });
      }

      return {
        'dailyStats': dailyStats,
        'totalRecords': attendanceRecords.length,
      };
    } catch (e) {
      throw Exception('Failed to get class attendance stats: $e');
    }
  }

  // Check if attendance is already marked for a class on a specific date
  static Future<bool> isAttendanceMarked(String classId, DateTime date) async {
    try {
      // Use a simpler query and filter in memory
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId)
          .get();

      final targetDate = DateTime(date.year, date.month, date.day);

      return querySnapshot.docs
          .map((doc) => Attendance.fromMap(doc.data()))
          .any((attendance) {
            final attendanceDate = DateTime(
              attendance.date.year,
              attendance.date.month,
              attendance.date.day,
            );
            return attendanceDate.isAtSameMomentAs(targetDate);
          });
    } catch (e) {
      throw Exception('Failed to check attendance status: $e');
    }
  }

  // Update attendance record
  static Future<void> updateAttendance(Attendance attendance) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(attendance.id)
          .update(attendance.toMap());
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // Delete ALL attendance records for a class (used when deleting a class)
  static Future<void> deleteAllClassAttendance(String classId) async {
    try {
      // Get all attendance records for this class
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to delete all class attendance: $e');
    }
  }

  // Mark attendance with duplicate prevention

  // Get attendance records for a class within a date range
  static Future<List<Attendance>> getClassAttendanceRange(
    String classId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId)
          .get();

      final attendanceRecords = querySnapshot.docs
          .map((doc) => Attendance.fromMap(doc.data()))
          .where((record) {
            final recordDate = DateTime(
              record.date.year,
              record.date.month,
              record.date.day,
            );
            final normalizedStartDate = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            );
            final normalizedEndDate = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            );

            return recordDate.isAtSameMomentAs(normalizedStartDate) ||
                recordDate.isAtSameMomentAs(normalizedEndDate) ||
                (recordDate.isAfter(normalizedStartDate) &&
                    recordDate.isBefore(normalizedEndDate));
          })
          .toList();

      // Sort by date
      attendanceRecords.sort((a, b) => a.date.compareTo(b.date));

      return attendanceRecords;
    } catch (e) {
      throw Exception('Failed to get class attendance range: $e');
    }
  }
}
