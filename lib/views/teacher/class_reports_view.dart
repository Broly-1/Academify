// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/models/attendance.dart';
import 'package:tuition_app/models/teacher.dart';
import 'package:tuition_app/services/student_service.dart';
import 'package:tuition_app/services/attendance_service.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/services/pdf_service.dart';
import 'package:tuition_app/utils/ui_utils.dart';
import 'package:tuition_app/utils/service_utils.dart';

class ClassReportsView extends StatefulWidget {
  final ClassModel classModel;

  const ClassReportsView({super.key, required this.classModel});

  @override
  State<ClassReportsView> createState() => _ClassReportsViewState();
}

class _ClassReportsViewState extends State<ClassReportsView> {
  List<Student> _students = [];
  List<Attendance> _attendanceRecords = [];
  Teacher? _teacher;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load students
      final students = await StudentService.getStudentsByIds(
        widget.classModel.studentIds,
      );

      // Load teacher info
      Teacher? teacher;
      if (widget.classModel.teacherId?.isNotEmpty == true) {
        teacher = await TeacherService.getTeacher(widget.classModel.teacherId!);
      }

      // Load attendance records
      final attendanceRecords = await AttendanceService.getClassAttendanceRange(
        widget.classModel.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _students = students;
          _teacher = teacher;
          _attendanceRecords = attendanceRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ServiceUtils.handleServiceError(
          error: e,
          context: context,
          customMessage: 'Error loading reports data: $e',
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: UIUtils.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  double _calculateAttendancePercentage(String studentId) {
    final studentAttendance = _attendanceRecords
        .where((record) => record.studentId == studentId)
        .toList();

    if (studentAttendance.isEmpty) return 0.0;

    final presentDays = studentAttendance
        .where((record) => record.isPresent)
        .length;
    return (presentDays / studentAttendance.length) * 100;
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) return UIUtils.primaryGreen;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getAttendanceStatus(double percentage) {
    if (percentage >= 75) return 'Excellent';
    if (percentage >= 50) return 'Average';
    return 'Poor';
  }

  Future<void> _generatePDFReport() async {
    try {
      await PDFService.previewAttendanceReportForTeacher(
        widget.classModel,
        _students,
        _attendanceRecords,
        _startDate,
        _endDate,
        teacher: _teacher,
      );
    } catch (e) {
      if (mounted) {
        ServiceUtils.handleServiceError(
          error: e,
          context: context,
          customMessage: 'Error generating PDF report: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: UIUtils.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.classModel.grade} ${widget.classModel.section} Reports',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Attendance Analytics',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: UIUtils.createLoadingIndicator(
                message: 'Loading reports...',
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Selection Card
                    UIUtils.createCardContainer(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                color: UIUtils.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Report Period',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _selectDateRange,
                                icon: const Icon(Icons.edit_calendar),
                                label: const Text('Change'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: UIUtils.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Class Overview Card
                    UIUtils.createCardContainer(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: UIUtils.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Class Overview',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildOverviewItem(
                                  'Total Students',
                                  _students.length.toString(),
                                  Icons.people,
                                  UIUtils.primaryGreen,
                                ),
                              ),
                              Expanded(
                                child: _buildOverviewItem(
                                  'Total Days',
                                  _attendanceRecords
                                      .map((r) => r.date)
                                      .toSet()
                                      .length
                                      .toString(),
                                  Icons.calendar_today,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildOverviewItem(
                                  'Avg Attendance',
                                  '${_calculateOverallAverage().toStringAsFixed(1)}%',
                                  Icons.trending_up,
                                  _getAttendanceColor(
                                    _calculateOverallAverage(),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildOverviewItem(
                                  'Records',
                                  _attendanceRecords.length.toString(),
                                  Icons.assignment,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generatePDFReport,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UIUtils.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Student Attendance List
                    const Text(
                      'Student Attendance Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ..._students.map((student) {
                      final percentage = _calculateAttendancePercentage(
                        student.id,
                      );
                      final color = _getAttendanceColor(percentage);
                      final status = _getAttendanceStatus(percentage);

                      final studentAttendance = _attendanceRecords
                          .where((record) => record.studentId == student.id)
                          .toList();
                      final presentDays = studentAttendance
                          .where((record) => record.isPresent)
                          .length;
                      final totalDays = studentAttendance.length;

                      return UIUtils.createCardContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '$presentDays/$totalDays days present',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateOverallAverage() {
    if (_students.isEmpty) return 0.0;

    double totalPercentage = 0.0;
    for (final student in _students) {
      totalPercentage += _calculateAttendancePercentage(student.id);
    }

    return totalPercentage / _students.length;
  }
}
