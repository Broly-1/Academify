// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:academify/models/student.dart';
import 'package:academify/models/teacher.dart';
import 'package:academify/models/class_model.dart';
import 'package:academify/models/payment.dart';
import 'package:academify/services/student_service.dart';
import 'package:academify/services/teacher_service.dart';
import 'package:academify/services/class_service.dart';
import 'package:academify/services/payment_service.dart';

class AcademyStatsView extends StatefulWidget {
  const AcademyStatsView({super.key});

  @override
  State<AcademyStatsView> createState() => _AcademyStatsViewState();
}

class _AcademyStatsViewState extends State<AcademyStatsView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Academy Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 73, 226, 31),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.attach_money), text: 'Financial'),
            Tab(icon: Icon(Icons.event_note), text: 'Attendance'),
            Tab(icon: Icon(Icons.school), text: 'Academic'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildFinancialTab(),
          _buildAttendanceTab(),
          _buildAcademicTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<List<Student>>(
      stream: StudentService.getAllStudents(),
      builder: (context, studentSnapshot) {
        return StreamBuilder<List<Teacher>>(
          stream: TeacherService.getAllTeachers(),
          builder: (context, teacherSnapshot) {
            return StreamBuilder<List<ClassModel>>(
              stream: ClassService.getAllClasses(),
              builder: (context, classSnapshot) {
                return StreamBuilder<List<Payment>>(
                  stream: PaymentService.getAllPaymentsStream(),
                  builder: (context, paymentSnapshot) {
                    if (studentSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        teacherSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        classSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        paymentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color.fromARGB(255, 73, 226, 31),
                            ),
                            SizedBox(height: 16),
                            Text('Loading academy statistics...'),
                          ],
                        ),
                      );
                    }

                    if (studentSnapshot.hasError ||
                        teacherSnapshot.hasError ||
                        classSnapshot.hasError ||
                        paymentSnapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text('Error loading data'),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final students = studentSnapshot.data ?? [];
                    final teachers = teacherSnapshot.data ?? [];
                    final classes = classSnapshot.data ?? [];
                    final payments = paymentSnapshot.data ?? [];

                    // Calculate active students (those with payments in last 30 days)
                    final now = DateTime.now();
                    final oneMonthAgo = now.subtract(const Duration(days: 30));
                    final activeStudents = students.where((student) {
                      return payments.any(
                        (payment) =>
                            payment.studentId == student.id &&
                            payment.createdAt.isAfter(oneMonthAgo),
                      );
                    }).length;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Academy Overview',
                            Icons.dashboard,
                          ),
                          const SizedBox(height: 16),

                          // Quick stats grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio:
                                1.4, // Increased from 1.2 to give more height
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildStatCard(
                                'Total Students',
                                '${students.length}',
                                Icons.people,
                                const Color(0xFF4285F4),
                              ),
                              _buildStatCard(
                                'Active Students',
                                '$activeStudents',
                                Icons.person_add,
                                const Color.fromARGB(255, 73, 226, 31),
                              ),
                              _buildStatCard(
                                'Total Teachers',
                                '${teachers.length}',
                                Icons.school,
                                const Color(0xFF9C27B0),
                              ),
                              _buildStatCard(
                                'Total Classes',
                                '${classes.length}',
                                Icons.class_,
                                const Color(0xFFFF9800),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Quick actions
                          _buildQuickActions(),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFinancialTab() {
    return StreamBuilder<List<Payment>>(
      stream: PaymentService.getAllPaymentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 73, 226, 31),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final payments = snapshot.data ?? [];
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month, 1);
        final lastMonth = DateTime(now.year, now.month - 1, 1);

        // Calculate financial stats
        final currentMonthPayments = payments
            .where(
              (payment) =>
                  payment.paidDate != null &&
                  payment.paidDate!.year == currentMonth.year &&
                  payment.paidDate!.month == currentMonth.month,
            )
            .toList();

        final lastMonthPayments = payments
            .where(
              (payment) =>
                  payment.paidDate != null &&
                  payment.paidDate!.year == lastMonth.year &&
                  payment.paidDate!.month == lastMonth.month,
            )
            .toList();

        final currentMonthRevenue = currentMonthPayments.fold<double>(
          0.0,
          (sum, payment) => sum + payment.amount,
        );

        final lastMonthRevenue = lastMonthPayments.fold<double>(
          0.0,
          (sum, payment) => sum + payment.amount,
        );

        final outstandingPayments = payments
            .where(
              (payment) => !payment.isPaid && payment.dueDate.isBefore(now),
            )
            .toList();

        final outstandingAmount = outstandingPayments.fold<double>(
          0.0,
          (sum, payment) => sum + payment.amount,
        );

        final totalRevenue = payments
            .where((payment) => payment.isPaid)
            .fold<double>(0.0, (sum, payment) => sum + payment.amount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSectionHeader(
                      'Financial Overview',
                      Icons.attach_money,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Live Data',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Revenue cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3, // Increased from 1.1 to give more height
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildRevenueCard(
                    'This Month',
                    'Rs. ${currentMonthRevenue.toStringAsFixed(2)}',
                    Icons.calendar_today,
                    const Color(0xFF4CAF50),
                  ),
                  _buildRevenueCard(
                    'Last Month',
                    'Rs. ${lastMonthRevenue.toStringAsFixed(2)}',
                    Icons.history,
                    const Color(0xFF2196F3),
                  ),
                  _buildRevenueCard(
                    'Outstanding',
                    'Rs. ${outstandingAmount.toStringAsFixed(2)}',
                    Icons.warning,
                    const Color(0xFFFF5722),
                  ),
                  _buildRevenueCard(
                    'Total Revenue',
                    'Rs. ${totalRevenue.toStringAsFixed(2)}',
                    Icons.trending_up,
                    const Color(0xFF9C27B0),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Show informative message if no payment data
              if (payments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Real-Time Financial Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All financial statistics above are calculated from actual payment records in your database. Currently showing Rs. 0.00 because no payment records exist yet. Add student fee payments to see real revenue data.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storage,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Connected to PaymentService',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Outstanding details
              if (outstandingPayments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outstanding Payments',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${outstandingPayments.length} payments overdue',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Show positive message when no outstanding payments and there is payment data
              if (payments.isNotEmpty && outstandingPayments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'All Payments Up to Date!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Great job! There are no outstanding payments at this time. All student fees are current.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Payment Records Management Section
              if (payments.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSectionHeader(
                  'Payment Records Management',
                  Icons.receipt_long,
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.receipt, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recent Payment Records (${payments.length} total)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (payments.length > 5) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () =>
                                    _showAllPaymentsDialog(context, payments),
                                child: const Text('View All'),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Payment list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length > 5 ? 5 : payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return _buildPaymentListItem(payment, context);
                        },
                      ),

                      // Delete all button
                      if (payments.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Danger Zone: Delete payment records',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _confirmDeleteAllPayments(
                                  context,
                                  payments,
                                ),
                                icon: const Icon(
                                  Icons.delete_forever,
                                  size: 18,
                                ),
                                label: const Text('Delete All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return StreamBuilder<List<ClassModel>>(
      stream: ClassService.getAllClasses(),
      builder: (context, classSnapshot) {
        if (classSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 73, 226, 31),
            ),
          );
        }

        if (classSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${classSnapshot.error}'),
              ],
            ),
          );
        }

        final classes = classSnapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Attendance Statistics', Icons.event_note),
              const SizedBox(height: 16),

              // Basic attendance info
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceCard(
                      'Total Classes',
                      '${classes.length}',
                      Icons.school,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAttendanceCard(
                      'Active Classes',
                      '${classes.length}',
                      Icons.today,
                      const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Note about attendance tracking
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Attendance tracking is available for individual classes. Visit the Attendance Management section to view detailed reports.',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAcademicTab() {
    return StreamBuilder<List<ClassModel>>(
      stream: ClassService.getAllClasses(),
      builder: (context, classSnapshot) {
        return StreamBuilder<List<Teacher>>(
          stream: TeacherService.getAllTeachers(),
          builder: (context, teacherSnapshot) {
            return StreamBuilder<List<Student>>(
              stream: StudentService.getAllStudents(),
              builder: (context, studentSnapshot) {
                if (classSnapshot.connectionState == ConnectionState.waiting ||
                    teacherSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    studentSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 73, 226, 31),
                    ),
                  );
                }

                if (classSnapshot.hasError ||
                    teacherSnapshot.hasError ||
                    studentSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text('Error loading academic data'),
                      ],
                    ),
                  );
                }

                final classes = classSnapshot.data ?? [];
                final teachers = teacherSnapshot.data ?? [];
                final students = studentSnapshot.data ?? [];

                // Calculate academic stats
                final Map<String, int> gradeDistribution = {};
                for (final classModel in classes) {
                  gradeDistribution[classModel.grade] =
                      (gradeDistribution[classModel.grade] ?? 0) + 1;
                }

                final Map<String, int> teacherWorkload = {};
                for (final teacher in teachers) {
                  final classCount = classes
                      .where(
                        (classModel) =>
                            classModel.teacherId != null &&
                            classModel.teacherId == teacher.id,
                      )
                      .length;
                  if (classCount > 0) {
                    teacherWorkload[teacher.name] = classCount;
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Academic Statistics', Icons.school),
                      const SizedBox(height: 16),

                      // Academic overview
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Classes',
                              '${classes.length}',
                              Icons.class_,
                              const Color(0xFF9C27B0),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Total Students',
                              '${students.length}',
                              Icons.group,
                              const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Grade distribution
                      _buildGradeDistributionCard(gradeDistribution),

                      const SizedBox(height: 24),

                      // Teacher workload
                      _buildTeacherWorkloadCard(teacherWorkload),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 73, 226, 31).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 73, 226, 31),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Container(
            padding: const EdgeInsets.all(8), // Reduced from 12
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20), // Reduced from 24
          ),
          const SizedBox(height: 8), // Reduced from 12
          Flexible(
            // Wrapped in Flexible to prevent overflow
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20, // Reduced from 24
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4
          Flexible(
            // Wrapped in Flexible to prevent overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11, // Reduced from 12
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow text to wrap to 2 lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Icon(icon, color: color, size: 24), // Reduced from 28
          const SizedBox(height: 6), // Reduced from 8
          Flexible(
            // Wrapped in Flexible to prevent overflow
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16, // Reduced from 18
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4
          Flexible(
            // Wrapped in Flexible to prevent overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11, // Reduced from 12
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow text to wrap to 2 lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Icon(icon, color: color, size: 24), // Reduced from 32
          const SizedBox(height: 6), // Reduced from 12
          Flexible(
            // Wrapped in Flexible to prevent overflow
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16, // Reduced from 20
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4
          Flexible(
            // Wrapped in Flexible to prevent overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11, // Reduced from 12
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow text to wrap to 2 lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add Student',
                Icons.person_add,
                const Color(0xFF4285F4),
                () {
                  // Navigate to add student
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'View Reports',
                Icons.analytics,
                const Color(0xFF9C27B0),
                () {
                  // Navigate to reports
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistributionCard(Map<String, int> gradeDistribution) {
    if (gradeDistribution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No grade data available')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grade Distribution',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...gradeDistribution.entries.map((entry) {
            final color = Color(0xFF4285F4).withOpacity(0.8);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Grade ${entry.key}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${entry.value} ${entry.value == 1 ? 'class' : 'classes'}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeacherWorkloadCard(Map<String, int> teacherWorkload) {
    if (teacherWorkload.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No teacher data available')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Workload',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...teacherWorkload.entries.map((entry) {
            final classCount = entry.value;
            final color = classCount > 3
                ? const Color(0xFFFF5722)
                : classCount > 1
                ? const Color(0xFFFF9800)
                : const Color(0xFF4CAF50);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$classCount ${classCount == 1 ? 'class' : 'classes'}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Payment management methods
  Widget _buildPaymentListItem(Payment payment, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Payment status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: payment.isPaid ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Payment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rs. ${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payment.month} ${payment.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (payment.paidDate != null)
                  Text(
                    'Paid: ${payment.paidDate!.day}/${payment.paidDate!.month}/${payment.paidDate!.year}',
                    style: TextStyle(color: Colors.green[600], fontSize: 12),
                  ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: payment.isPaid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              payment.isPaid ? 'Paid' : 'Pending',
              style: TextStyle(
                color: payment.isPaid ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Delete button
          IconButton(
            onPressed: () => _confirmDeletePayment(context, payment),
            icon: Icon(Icons.delete, color: Colors.red[400]),
            tooltip: 'Delete this payment',
          ),
        ],
      ),
    );
  }

  void _showAllPaymentsDialog(BuildContext context, List<Payment> payments) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'All Payment Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Payment list
              Expanded(
                child: ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildPaymentListItem(payment, context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this payment record?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: Rs. ${payment.amount.toStringAsFixed(2)}'),
                  Text('Period: ${payment.month} ${payment.year}'),
                  Text('Status: ${payment.isPaid ? "Paid" : "Pending"}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePayment(payment);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllPayments(BuildContext context, List<Payment> payments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Payments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete ALL payment records?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total records: ${payments.length}'),
                  Text(
                    'Total amount: Rs. ${payments.fold<double>(0.0, (sum, payment) => sum + payment.amount).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ WARNING: This will permanently delete all payment records and reset your financial statistics to zero. This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllPayments(payments);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(Payment payment) async {
    try {
      await PaymentService.deletePayment(payment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment record deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting payment: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllPayments(List<Payment> payments) async {
    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting payment records...'),
            ],
          ),
        ),
      );

      // Delete all payments
      for (final payment in payments) {
        await PaymentService.deletePayment(payment.id);
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All payment records deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting payments: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
