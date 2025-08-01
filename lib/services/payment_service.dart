import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:academify/models/payment.dart';
import 'package:academify/models/student.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'payments';

  // Generate receipt number
  static String _generateReceiptNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'REC${now.year}${now.month.toString().padLeft(2, '0')}$timestamp';
  }

  // Create payment records for all students in a class
  static Future<List<String>> createClassPayments({
    required String classId,
    required List<Student> students,
    required double amount,
    required String month,
    required int year,
    DateTime? dueDate,
  }) async {
    try {
      final batch = _firestore.batch();
      final List<String> paymentIds = [];
      final now = DateTime.now();
      final defaultDueDate =
          dueDate ?? DateTime(year, _getMonthNumber(month) + 1, 5);

      // First, check for existing unpaid payments and mark them as overdue
      final existingPayments = await getClassPayments(
        classId: classId,
        month: month,
        year: year,
      );

      for (final student in students) {
        // Check if student has existing unpaid payment
        final existingPayment = existingPayments
            .where((p) => p.studentId == student.id && !p.isPaid)
            .firstOrNull;

        if (existingPayment != null) {
          // Mark existing unpaid payment as overdue by updating its notes
          final overduePayment = existingPayment.copyWith(
            notes:
                (existingPayment.notes ?? '') +
                (existingPayment.notes?.isNotEmpty == true ? '\n' : '') +
                'OVERDUE: New challan created on ${now.day}/${now.month}/${now.year}',
            updatedAt: now,
          );

          batch.update(
            _firestore.collection(_collection).doc(existingPayment.id),
            overduePayment.toMap(),
          );
        }

        // Create new payment record
        final docRef = _firestore.collection(_collection).doc();
        final payment = Payment(
          id: docRef.id,
          studentId: student.id,
          classId: classId,
          month: month,
          year: year,
          amount: amount,
          dueDate: defaultDueDate,
          createdAt: now,
          updatedAt: now,
        );

        batch.set(docRef, payment.toMap());
        paymentIds.add(docRef.id);
      }

      await batch.commit();
      return paymentIds;
    } catch (e) {
      throw Exception('Failed to create class payments: $e');
    }
  }

  // Mark payment as paid
  static Future<void> markPaymentAsPaid({
    required String paymentId,
    required String paymentMethod,
    DateTime? paidDate,
    String? notes,
  }) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      final receiptNumber = payment.receiptNumber ?? _generateReceiptNumber();
      final updatedPayment = payment.copyWith(
        isPaid: true,
        paidDate: paidDate ?? DateTime.now(),
        receiptNumber: receiptNumber,
        paymentMethod: paymentMethod,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(paymentId)
          .update(updatedPayment.toMap());
    } catch (e) {
      throw Exception('Failed to mark payment as paid: $e');
    }
  }

  // Mark payment as unpaid
  static Future<void> markPaymentAsUnpaid({
    required String paymentId,
    String? notes,
  }) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      final updatedPayment = payment.copyWith(
        isPaid: false,
        paidDate: null,
        receiptNumber: null,
        paymentMethod: null,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(paymentId)
          .update(updatedPayment.toMap());
    } catch (e) {
      throw Exception('Failed to mark payment as unpaid: $e');
    }
  }

  // Get payment by ID
  static Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(paymentId).get();
      if (doc.exists) {
        return Payment.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  // Get payments for a class for a specific month/year
  static Future<List<Payment>> getClassPayments({
    required String classId,
    required String month,
    required int year,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      return querySnapshot.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get class payments: $e');
    }
  }

  // Get payments for a specific student

  // Get payment statistics for a class
  static Future<Map<String, dynamic>> getClassPaymentStats({
    required String classId,
    required String month,
    required int year,
  }) async {
    try {
      final payments = await getClassPayments(
        classId: classId,
        month: month,
        year: year,
      );

      final totalPayments = payments.length;
      final paidPayments = payments.where((p) => p.isPaid).length;
      final unpaidPayments = totalPayments - paidPayments;

      final totalRevenue = payments
          .where((p) => p.isPaid)
          .map((p) => p.amount)
          // ignore: avoid_types_as_parameter_names
          .fold<double>(0, (sum, amount) => sum + amount);

      final pendingRevenue = payments
          .where((p) => !p.isPaid)
          .map((p) => p.amount)
          // ignore: avoid_types_as_parameter_names
          .fold<double>(0, (sum, amount) => sum + amount);

      return {
        'totalPayments': totalPayments,
        'paidPayments': paidPayments,
        'unpaidPayments': unpaidPayments,
        'totalRevenue': totalRevenue,
        'pendingRevenue': pendingRevenue,
      };
    } catch (e) {
      throw Exception('Failed to get payment statistics: $e');
    }
  }

  // Get overdue payments
  static Future<List<Payment>> getOverduePayments() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isPaid', isEqualTo: false)
          .get();

      // Filter overdue payments in code since Firestore might have issues with date string comparisons
      final allUnpaidPayments = querySnapshot.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList();

      final overduePayments = allUnpaidPayments
          .where((payment) => payment.dueDate.isBefore(now))
          .toList();

      return overduePayments;
    } catch (e) {
      // Return empty list instead of throwing exception to prevent UI crashes
      // Error getting overdue payments: $e (logged silently)
      return [];
    }
  }

  // Get overdue payments for a specific class
  static Future<List<Payment>> getClassOverduePayments({
    required String classId,
    required String month,
    required int year,
  }) async {
    try {
      final payments = await getClassPayments(
        classId: classId,
        month: month,
        year: year,
      );

      // Return payments that are overdue (unpaid and past due date)
      return payments.where((payment) => payment.isOverdue).toList();
    } catch (e) {
      throw Exception('Failed to get overdue payments: $e');
    }
  }

  // Get all overdue payments across all classes
  static Future<List<Payment>> getAllOverduePayments() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isPaid', isEqualTo: false)
          .get();

      final payments = querySnapshot.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList();

      // Filter to only include overdue payments
      return payments
          .where((payment) => payment.dueDate.isBefore(now))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all overdue payments: $e');
    }
  }

  // Mark overdue payment as paid (special handling)
  static Future<void> markOverduePaymentAsPaid({
    required String paymentId,
    required String paymentMethod,
    DateTime? paidDate,
    String? notes,
  }) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      final receiptNumber = payment.receiptNumber ?? _generateReceiptNumber();
      final overdueNotes =
          (payment.notes ?? '') +
          (payment.notes?.isNotEmpty == true ? '\n' : '') +
          'OVERDUE PAYMENT: Paid on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

      final updatedPayment = payment.copyWith(
        isPaid: true,
        paidDate: paidDate ?? DateTime.now(),
        receiptNumber: receiptNumber,
        paymentMethod: paymentMethod,
        notes: notes ?? overdueNotes,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(paymentId)
          .update(updatedPayment.toMap());
    } catch (e) {
      throw Exception('Failed to mark overdue payment as paid: $e');
    }
  }

  // Update payment
  static Future<void> updatePayment(Payment payment) async {
    try {
      final updatedPayment = payment.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(payment.id)
          .update(updatedPayment.toMap());
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  // Delete payment
  static Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection(_collection).doc(paymentId).delete();
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }

  // Helper method to convert month name to number
  static int _getMonthNumber(String monthName) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return months[monthName] ?? 1;
  }

  // Get all payments stream (for real-time updates)
  static Stream<List<Payment>> getAllPaymentsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList(),
        );
  }

  // Get class payments stream
}
