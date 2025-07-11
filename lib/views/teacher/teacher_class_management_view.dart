import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/teacher.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/services/auth/auth_service.dart';
import 'package:tuition_app/views/teacher/mark_attendance_view.dart';
import 'package:tuition_app/views/teacher/view_attendance_reports_view.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: UIUtils.createGradientAppBar(title: 'My Classes'),
      body: _isLoading
          ? Center(
              child: UIUtils.createLoadingIndicator(
                message: 'Loading your classes...',
              ),
            )
          : Column(
              children: [
                // Modern Teacher Welcome Header
                if (_currentTeacher != null)
                  UIUtils.createGradientContainer(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    gradient: UIUtils.primaryGradient,
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _currentTeacher!.name.isNotEmpty
                                  ? _currentTeacher!.name[0].toUpperCase()
                                  : 'T',
                              style: UIUtils.whiteTextStyle.copyWith(
                                fontSize: 24,
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
                                'Welcome back,',
                                style: UIUtils.bodyStyle.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _currentTeacher!.name,
                                style: UIUtils.subheadingStyle.copyWith(
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              UIUtils.smallVerticalSpacing,
                              Row(
                                children: [
                                  const Icon(
                                    Icons.class_,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  UIUtils.smallHorizontalSpacing,
                                  Flexible(
                                    child: Text(
                                      '${_assignedClasses.length} Classes Assigned',
                                      style: UIUtils.bodyStyle.copyWith(
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Classes list
                Expanded(
                  child: _assignedClasses.isEmpty
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
                                          decoration:
                                              UIUtils.gradientDecoration(
                                                gradient:
                                                    UIUtils.primaryGradient,
                                                borderRadius:
                                                    const BorderRadius.all(
                                                      Radius.circular(25),
                                                    ),
                                              ),
                                          child: Center(
                                            child: Text(
                                              '${classModel.grade}${classModel.section}',
                                              style: UIUtils.whiteTextStyle
                                                  .copyWith(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                        UIUtils.mediumHorizontalSpacing,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${classModel.grade} ${classModel.section}',
                                                style: UIUtils.subheadingStyle,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              UIUtils.smallVerticalSpacing,
                                              Text(
                                                'Academic Year ${classModel.year}',
                                                style: UIUtils.bodyStyle
                                                    .copyWith(
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
                                            color: UIUtils.primaryGreen
                                                .withOpacity(0.1),
                                            borderRadius: UIUtils.largeRadius,
                                          ),
                                          child: Text(
                                            'Assigned',
                                            style: UIUtils.captionStyle
                                                .copyWith(
                                                  color: UIUtils.primaryGreen,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    UIUtils.mediumVerticalSpacing,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  UIUtils.mediumRadius,
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
                                                    style: UIUtils.bodyStyle
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        UIUtils.mediumHorizontalSpacing,
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  UIUtils.mediumRadius,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.currency_rupee,
                                                  size: 16,
                                                  color: UIUtils.primaryGreen,
                                                ),
                                                UIUtils.smallHorizontalSpacing,
                                                Expanded(
                                                  child: Text(
                                                    '₹${classModel.monthlyFee.toStringAsFixed(0)}/month',
                                                    style: UIUtils.bodyStyle
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    UIUtils.largeVerticalSpacing,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: UIUtils.createPrimaryButton(
                                            text: 'Mark Attendance',
                                            icon: Icons.check_circle,
                                            onPressed: () =>
                                                _navigateToMarkAttendance(
                                                  classModel,
                                                ),
                                          ),
                                        ),
                                        UIUtils.mediumHorizontalSpacing,
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _navigateToAttendanceReports(
                                                  classModel,
                                                ),
                                            icon: const Icon(
                                              Icons.analytics,
                                              color: Colors.white,
                                            ),
                                            label: const Text(
                                              'View Reports',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    UIUtils.mediumRadius,
                                              ),
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
                ),
              ],
            ),
    );
  }
}
