import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/student_service.dart';
import 'package:tuition_app/services/attendance_service.dart';
import 'package:tuition_app/views/owner/individual_student_attendance_view.dart';
import 'package:tuition_app/utils/ui_utils.dart';
import 'package:tuition_app/utils/service_utils.dart';

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
  Set<String> _expandedClasses = {}; // Track expanded classes

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
        ServiceUtils.handleServiceError(
          error: e,
          context: context,
          customMessage: 'Error loading data: $e',
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
      appBar: UIUtils.createGradientAppBar(
        title: 'Attendance Management',
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
              child: UIUtils.createLoadingIndicator(
                message: 'Loading attendance data...',
              ),
            )
          : Column(
              children: [
                // Header Section with Date Range
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: UIUtils.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: UIUtils.primaryGreen.withOpacity(0.3),
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
                          borderRadius: UIUtils.mediumRadius,
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      UIUtils.mediumHorizontalSpacing,
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
                            UIUtils.smallVerticalSpacing,
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
                          borderRadius: UIUtils.mediumRadius,
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
                                  color: UIUtils.primaryGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 60,
                                  color: UIUtils.primaryGreen,
                                ),
                              ),
                              UIUtils.largeVerticalSpacing,
                              const Text(
                                'No classes found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              UIUtils.mediumVerticalSpacing,
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
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 24,
                          ),
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
                                horizontal: 8,
                                vertical: 6,
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  children: [
                                    // Main class header with Pakistani flag design
                                    Container(
                                      height: 80,
                                      child: Row(
                                        children: [
                                          // Vertical bar on the left (Pakistani flag design)
                                          Container(
                                            width: 60,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getAttendanceColor(
                                                    overallPercentage,
                                                  ),
                                                  _getAttendanceColor(
                                                    overallPercentage,
                                                  ).withOpacity(0.8),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                            child: Center(
                                              child: RotatedBox(
                                                quarterTurns: 3,
                                                child: Text(
                                                  '${classModel.grade}${classModel.section}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Main content area
                                          Expanded(
                                            child: Container(
                                              height: 80,
                                              color: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          '${classModel.grade} ${classModel.section} (${classModel.year})',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'Students: ${students.length} || Days: ${dailyStats.length}${overallPercentage > 0 ? ' || ${overallPercentage.toStringAsFixed(1)}%' : ''}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                overallPercentage >
                                                                    0
                                                                ? _getAttendanceColor(
                                                                    overallPercentage,
                                                                  )
                                                                : Colors
                                                                      .grey[600],
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Expand/Collapse button
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                      onTap: () {
                                                        setState(() {
                                                          if (_expandedClasses
                                                              .contains(
                                                                classModel.id,
                                                              )) {
                                                            _expandedClasses
                                                                .remove(
                                                                  classModel.id,
                                                                );
                                                          } else {
                                                            _expandedClasses
                                                                .add(
                                                                  classModel.id,
                                                                );
                                                          }
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        child: AnimatedRotation(
                                                          turns:
                                                              _expandedClasses
                                                                  .contains(
                                                                    classModel
                                                                        .id,
                                                                  )
                                                              ? 0.5
                                                              : 0.0,
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    200,
                                                              ),
                                                          child: Icon(
                                                            Icons
                                                                .keyboard_arrow_down,
                                                            color: _getAttendanceColor(
                                                              overallPercentage,
                                                            ),
                                                            size: 24,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Expandable students list
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                      height:
                                          _expandedClasses.contains(
                                            classModel.id,
                                          )
                                          ? (students.isEmpty
                                                ? 60.0
                                                : students.length * 72.0 + 16)
                                          : 0,
                                      child: Container(
                                        color: Colors.grey[50],
                                        child: students.isEmpty
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Text(
                                                    'No students assigned to this class',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: students.length,
                                                itemBuilder: (context, studentIndex) {
                                                  final student =
                                                      students[studentIndex];
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
                                                      final stats =
                                                          snapshot.data ?? {};
                                                      final percentage =
                                                          stats['attendancePercentage'] ??
                                                          0.0;
                                                      final presentDays =
                                                          stats['presentDays'] ??
                                                          0;
                                                      final totalDays =
                                                          stats['totalDays'] ??
                                                          0;

                                                      return Container(
                                                        height: 72,
                                                        margin:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: UIUtils
                                                              .mediumRadius,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.02,
                                                                  ),
                                                              blurRadius: 4,
                                                              spreadRadius: 1,
                                                            ),
                                                          ],
                                                        ),
                                                        child: ListTile(
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 8,
                                                              ),
                                                          leading: CircleAvatar(
                                                            radius: 20,
                                                            backgroundColor:
                                                                _getAttendanceColor(
                                                                  percentage,
                                                                ),
                                                            child: Text(
                                                              student
                                                                      .name
                                                                      .isNotEmpty
                                                                  ? student
                                                                        .name[0]
                                                                        .toUpperCase()
                                                                  : '?',
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          title: Text(
                                                            student.name,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          subtitle: Text(
                                                            'Contact: ${student.parentContact}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          trailing: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  _getAttendanceColor(
                                                                    percentage,
                                                                  ).withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius: UIUtils
                                                                  .mediumRadius,
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  '${percentage.toStringAsFixed(1)}%',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: _getAttendanceColor(
                                                                      percentage,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '$presentDays/$totalDays',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .grey[600],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          onTap: () =>
                                                              _viewStudentDetails(
                                                                student,
                                                                classModel,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
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
