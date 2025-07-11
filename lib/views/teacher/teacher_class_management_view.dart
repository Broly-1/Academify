// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/teacher.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/services/auth/auth_service.dart';
import 'package:tuition_app/views/teacher/mark_attendance_view.dart';
import 'package:tuition_app/views/teacher/class_reports_view.dart';
import 'package:tuition_app/utils/ui_utils.dart';
import 'package:tuition_app/utils/service_utils.dart';

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
        ServiceUtils.handleServiceError(
          error: e,
          context: context,
          customMessage: 'Error loading classes: $e',
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

  void _navigateToViewReports(ClassModel classModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassReportsView(classModel: classModel),
      ),
    );
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'My Classes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentTeacher != null)
                          Text(
                            'Welcome back, ${_currentTeacher!.name}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
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
                    child: Text(
                      _assignedClasses.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                message: 'Loading your classes...',
              ),
            )
          : _assignedClasses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No classes assigned yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Contact the administrator to get assigned to classes',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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

                  return UIUtils.createCardContainer(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: UIUtils.gradientDecoration(
                                gradient: UIUtils.primaryGradient,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(25),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${classModel.grade}${classModel.section}',
                                  style: UIUtils.whiteTextStyle.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            UIUtils.mediumHorizontalSpacing,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${classModel.grade} ${classModel.section}',
                                    style: UIUtils.subheadingStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  UIUtils.smallVerticalSpacing,
                                  Text(
                                    'Academic Year ${classModel.year}',
                                    style: UIUtils.bodyStyle.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                                color: UIUtils.primaryGreen.withOpacity(0.1),
                                borderRadius: UIUtils.largeRadius,
                              ),
                              child: Text(
                                'Assigned',
                                style: UIUtils.captionStyle.copyWith(
                                  color: UIUtils.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        UIUtils.mediumVerticalSpacing,
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: UIUtils.mediumRadius,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: UIUtils.primaryGreen,
                              ),
                              UIUtils.smallHorizontalSpacing,
                              Expanded(
                                child: Text(
                                  '${classModel.studentIds.length} Students',
                                  style: UIUtils.bodyStyle.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        UIUtils.largeVerticalSpacing,
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _navigateToMarkAttendance(classModel),
                                icon: const Icon(
                                  Icons.edit_note,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Mark Attendance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: UIUtils.primaryGreen,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: UIUtils.mediumRadius,
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _navigateToViewReports(classModel),
                                icon: const Icon(
                                  Icons.analytics,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'View Reports',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: UIUtils.mediumRadius,
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
