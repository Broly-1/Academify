import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/student_service.dart';
import 'package:tuition_app/services/attendance_service.dart';
import 'package:tuition_app/views/owner/individual_student_attendance_view.dart';

class OwnerAttendanceManagementView extends StatefulWidget {
  const OwnerAttendanceManagementView({super.key});

  @override
  State<OwnerAttendanceManagementView> createState() =>
      _OwnerAttendanceManagementViewState();
}

class _OwnerAttendanceManagementViewState
    extends State<OwnerAttendanceManagementView> {
  List<ClassModel> _classes = [];
  Map<String, List<Student>> _classStudents = {}; // classId -> students
  Map<String, Map<String, dynamic>> _classStats = {}; // classId -> stats
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all classes
      final classes = await ClassService.getAllClasses().first;

      // Load students for each class and attendance stats
      final Map<String, List<Student>> classStudents = {};
      final Map<String, Map<String, dynamic>> classStats = {};

      for (final classModel in classes) {
        // Load students
        final students = await StudentService.getStudentsByIds(
          classModel.studentIds,
        );
        classStudents[classModel.id] = students;

        // Load class attendance stats
        final stats = await AttendanceService.getClassAttendanceStats(
          classModel.id,
          startDate: _startDate,
          endDate: _endDate,
        );
        classStats[classModel.id] = stats;
      }

      if (mounted) {
        setState(() {
          _classes = classes;
          _classStudents = classStudents;
          _classStats = classStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
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
      _loadData();
    }
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  void _viewStudentDetails(Student student, ClassModel classModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualStudentAttendanceView(
          student: student,
          classModel: classModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Attendance Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range, color: Colors.white),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading attendance data...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header Section with Date Range
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attendance Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _selectDateRange,
                          icon: const Icon(
                            Icons.edit_calendar,
                            color: Colors.white,
                          ),
                          tooltip: 'Change Date Range',
                        ),
                      ),
                    ],
                  ),
                ),

                // Classes list
                Expanded(
                  child: _classes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 60,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No classes found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Create classes to start tracking attendance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            final classModel = _classes[index];
                            final students =
                                _classStudents[classModel.id] ?? [];
                            final classStats = _classStats[classModel.id] ?? {};
                            final dailyStats =
                                classStats['dailyStats'] as List<dynamic>? ??
                                [];

                            // Calculate overall class attendance percentage
                            double overallPercentage = 0.0;
                            if (dailyStats.isNotEmpty) {
                              final totalPercentages = dailyStats
                                  .map(
                                    (stat) =>
                                        stat['attendancePercentage']
                                            as double? ??
                                        0.0,
                                  )
                                  .where((p) => p > 0);
                              if (totalPercentages.isNotEmpty) {
                                overallPercentage =
                                    totalPercentages.reduce((a, b) => a + b) /
                                    totalPercentages.length;
                              }
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ExpansionTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getAttendanceColor(
                                            overallPercentage,
                                          ),
                                          _getAttendanceColor(
                                            overallPercentage,
                                          ).withOpacity(0.7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${classModel.grade}${classModel.section}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    '${classModel.grade} ${classModel.section} (${classModel.year})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Students: ${students.length}'),
                                      Text(
                                        'Days with attendance: ${dailyStats.length}',
                                      ),
                                      if (overallPercentage > 0)
                                        Text(
                                          'Average attendance: ${overallPercentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: _getAttendanceColor(
                                              overallPercentage,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  children: [
                                    if (students.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'No students assigned to this class',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    else
                                      ...students.map((student) {
                                        return FutureBuilder<
                                          Map<String, dynamic>
                                        >(
                                          future:
                                              AttendanceService.getStudentAttendanceStats(
                                                student.id,
                                                classModel.id,
                                                startDate: _startDate,
                                                endDate: _endDate,
                                              ),
                                          builder: (context, snapshot) {
                                            final stats = snapshot.data ?? {};
                                            final percentage =
                                                stats['attendancePercentage'] ??
                                                0.0;
                                            final presentDays =
                                                stats['presentDays'] ?? 0;
                                            final totalDays =
                                                stats['totalDays'] ?? 0;

                                            return ListTile(
                                              leading: CircleAvatar(
                                                radius: 16,
                                                backgroundColor:
                                                    _getAttendanceColor(
                                                      percentage,
                                                    ),
                                                child: Text(
                                                  student.name.isNotEmpty
                                                      ? student.name[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              title: Text(student.name),
                                              subtitle: Text(
                                                'Contact: ${student.parentContact}',
                                              ),
                                              trailing: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${percentage.toStringAsFixed(1)}%',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          _getAttendanceColor(
                                                            percentage,
                                                          ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '$presentDays/$totalDays',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              onTap: () => _viewStudentDetails(
                                                student,
                                                classModel,
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
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
