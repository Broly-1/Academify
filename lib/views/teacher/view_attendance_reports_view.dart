import 'package:flutter/material.dart';
import 'package:academify/models/class_model.dart';
import 'package:academify/models/student.dart';
import 'package:academify/models/teacher.dart';
import 'package:academify/services/student_service.dart';
import 'package:academify/services/attendance_service.dart';
import 'package:academify/services/teacher_service.dart';
import 'package:academify/services/pdf_service.dart';
import 'package:academify/utils/ui_utils.dart';
import 'package:academify/utils/service_utils.dart';

class ViewAttendanceReportsView extends StatefulWidget {
  final ClassModel classModel;

  const ViewAttendanceReportsView({super.key, required this.classModel});

  @override
  State<ViewAttendanceReportsView> createState() =>
      _ViewAttendanceReportsViewState();
}

class _ViewAttendanceReportsViewState extends State<ViewAttendanceReportsView> {
  List<Student> _students = [];
  Map<String, Map<String, dynamic>> _studentStats = {}; // studentId -> stats
  Map<String, dynamic> _classStats = {};
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load students
      final students = await StudentService.getStudentsByIds(
        widget.classModel.studentIds,
      );

      // Load individual student stats
      final Map<String, Map<String, dynamic>> studentStats = {};
      for (final student in students) {
        final stats = await AttendanceService.getStudentAttendanceStats(
          student.id,
          widget.classModel.id,
          startDate: _startDate,
          endDate: _endDate,
        );
        studentStats[student.id] = stats;
      }

      // Load class stats
      final classStats = await AttendanceService.getClassAttendanceStats(
        widget.classModel.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _students = students;
          _studentStats = studentStats;
          _classStats = classStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ServiceUtils.handleServiceError(
          error: e,
          context: context,
          customMessage: 'Error loading reports: $e',
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Future<void> _generateAttendanceReport() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No student data available to generate report'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show report type selection dialog
    String? reportType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Report Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose the type of attendance report to generate:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.blue),
              title: const Text('Student Copy'),
              subtitle: const Text('Basic attendance information for students'),
              onTap: () => Navigator.of(context).pop('student'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Teacher Copy'),
              subtitle: const Text(
                'Detailed report with summary and analytics',
              ),
              onTap: () => Navigator.of(context).pop('teacher'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (reportType == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get attendance records for the date range
      final attendanceRecords = await AttendanceService.getClassAttendanceRange(
        widget.classModel.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Get teacher information if assigned to class
      Teacher? teacher;
      if (widget.classModel.teacherId != null) {
        try {
          teacher = await TeacherService.getTeacher(
            widget.classModel.teacherId!,
          );
        } catch (e) {
          // If teacher fetch fails, continue without teacher info
          teacher = null;
        }
      }

      // Generate appropriate report type
      if (reportType == 'student') {
        await PDFService.previewAttendanceReportForStudent(
          widget.classModel,
          _students,
          attendanceRecords,
          _startDate,
          _endDate,
          teacher: teacher,
        );
      } else {
        await PDFService.previewAttendanceReportForTeacher(
          widget.classModel,
          _students,
          attendanceRecords,
          _startDate,
          _endDate,
          teacher: teacher,
        );
      }

      Navigator.of(context).pop(); // Close loading dialog

      final copyType = reportType == 'student'
          ? 'Student Copy'
          : 'Teacher Copy';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Professional attendance report ($copyType) generated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UIUtils.createGradientAppBar(
        title:
            'Attendance Reports - ${widget.classModel.grade} ${widget.classModel.section}',
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range, color: Colors.white),
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: UIUtils.createLoadingIndicator(
                message: 'Loading attendance reports...',
              ),
            )
          : Column(
              children: [
                // Date range and class stats
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Period: ${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ElevatedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.date_range, size: 16),
                              label: const Text(
                                'Change',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: UIUtils.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_classStats.isNotEmpty &&
                          _classStats['dailyStats'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: UIUtils.mediumRadius,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Class Overview',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: UIUtils.primaryGreen,
                                ),
                              ),
                              UIUtils.smallVerticalSpacing,
                              Text(
                                'Total Days with Attendance: ${(_classStats['dailyStats'] as List).length}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Total Students: ${_students.length}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Students attendance list
                Expanded(
                  child: _students.isEmpty
                      ? const Center(
                          child: Text(
                            'No students in this class',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final stats = _studentStats[student.id] ?? {};
                            final totalDays = stats['totalDays'] ?? 0;
                            final presentDays = stats['presentDays'] ?? 0;
                            final absentDays = stats['absentDays'] ?? 0;
                            final percentage =
                                stats['attendancePercentage'] ?? 0.0;

                            return UIUtils.createCardContainer(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getAttendanceColor(
                                    percentage,
                                  ),
                                  child: Text(
                                    student.name.isNotEmpty
                                        ? student.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Contact: ${student.parentContact}'),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            border: Border.all(
                                              color: Colors.green[300]!,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: Colors.green[700],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$presentDays',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            border: Border.all(
                                              color: Colors.red[300]!,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.cancel,
                                                size: 14,
                                                color: Colors.red[700],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$absentDays',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _getAttendanceColor(percentage),
                                      ),
                                    ),
                                    Text(
                                      '$totalDays days',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateAttendanceReport,
        backgroundColor: UIUtils.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate PDF'),
      ),
    );
  }
}
