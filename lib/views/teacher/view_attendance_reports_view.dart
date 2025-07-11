import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/services/student_service.dart';
import 'package:tuition_app/services/attendance_service.dart';
import 'package:tuition_app/utils/ui_utils.dart';
import 'package:tuition_app/utils/service_utils.dart';

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
                          ElevatedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range),
                            label: const Text('Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UIUtils.primaryGreen,
                              foregroundColor: Colors.white,
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
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: UIUtils.smallRadius,
                                          ),
                                          child: Text(
                                            'Present: $presentDays',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        UIUtils.smallHorizontalSpacing,
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius: UIUtils.smallRadius,
                                          ),
                                          child: Text(
                                            'Absent: $absentDays',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
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
    );
  }
}
