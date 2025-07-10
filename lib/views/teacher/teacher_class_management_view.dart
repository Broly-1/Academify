import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/teacher.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/services/auth/auth_service.dart';
import 'package:tuition_app/views/teacher/mark_attendance_view.dart';
import 'package:tuition_app/views/teacher/view_attendance_reports_view.dart';

class TeacherClassManagementView extends StatefulWidget {
  const TeacherClassManagementView({super.key});

  @override
  State<TeacherClassManagementView> createState() =>
      _TeacherClassManagementViewState();
}

class _TeacherClassManagementViewState
    extends State<TeacherClassManagementView> {
  List<ClassModel> _assignedClasses = [];
  bool _isLoading = true;
  Teacher? _currentTeacher;

  @override
  void initState() {
    super.initState();
    _loadTeacherAndClasses();
  }

  Future<void> _loadTeacherAndClasses() async {
    try {
      final currentUser = AuthService.firebase().currentUser;
      final email = currentUser?.email;

      if (email != null) {
        // Get current teacher profile
        final teacher = await TeacherService.getTeacherByEmail(email);

        if (teacher != null) {
          // Get classes assigned to this teacher
          final allClasses = await ClassService.getAllClasses().first;
          final assignedClasses = allClasses
              .where((classModel) => classModel.teacherId == teacher.id)
              .toList();

          if (mounted) {
            setState(() {
              _currentTeacher = teacher;
              _assignedClasses = assignedClasses;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToMarkAttendance(ClassModel classModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendanceView(classModel: classModel),
      ),
    ).then((_) {
      // Refresh the view when returning from attendance marking
      _loadTeacherAndClasses();
    });
  }

  void _navigateToAttendanceReports(ClassModel classModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAttendanceReportsView(classModel: classModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        backgroundColor: const Color.fromARGB(255, 73, 226, 31),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Teacher info
                if (_currentTeacher != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${_currentTeacher!.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Email: ${_currentTeacher!.email}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          'Assigned Classes: ${_assignedClasses.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Classes list
                Expanded(
                  child: _assignedClasses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No classes assigned yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Contact the administrator to get assigned to classes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTeacherAndClasses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _assignedClasses.length,
                            itemBuilder: (context, index) {
                              final classModel = _assignedClasses[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${classModel.grade} ${classModel.section}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                      255,
                                                      73,
                                                      226,
                                                      31,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Year: ${classModel.year}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  'Monthly Fee: ₹${classModel.monthlyFee}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  'Students: ${classModel.studentIds.length}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Text(
                                              'Assigned',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _navigateToMarkAttendance(
                                                    classModel,
                                                  ),
                                              icon: const Icon(
                                                Icons.check_circle,
                                              ),
                                              label: const Text(
                                                'Mark Attendance',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      73,
                                                      226,
                                                      31,
                                                    ),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _navigateToAttendanceReports(
                                                    classModel,
                                                  ),
                                              icon: const Icon(Icons.analytics),
                                              label: const Text('View Reports'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
