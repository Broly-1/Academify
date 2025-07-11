import 'package:flutter/material.dart';
import 'package:tuition_app/services/auth/auth_service.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/attendance_service.dart';
import 'package:tuition_app/models/teacher.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/enums/menu_action.dart';
import 'package:tuition_app/views/teacher/teacher_class_management_view.dart';
import 'package:tuition_app/utils/ui_utils.dart';
import 'package:tuition_app/utils/service_utils.dart';

class TeacherView extends StatefulWidget {
  const TeacherView({super.key});

  @override
  State<TeacherView> createState() => _TeacherViewState();
}

class _TeacherViewState extends State<TeacherView> {
  Teacher? _currentTeacher;
  List<ClassModel> _assignedClasses = [];
  Map<String, dynamic> _todayStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
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

          // Calculate today's stats
          final todayStats = await _calculateTodayStats(assignedClasses);

          if (mounted) {
            setState(() {
              _currentTeacher = teacher;
              _assignedClasses = assignedClasses;
              _todayStats = todayStats;
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
      }
    }
  }

  Future<Map<String, dynamic>> _calculateTodayStats(
    List<ClassModel> classes,
  ) async {
    int totalStudents = 0;
    int presentToday = 0;
    final today = DateTime.now();

    // Normalize today's date for comparison
    final normalizedToday = DateTime(today.year, today.month, today.day);

    for (final classModel in classes) {
      totalStudents += classModel.studentIds.length;

      // Check attendance for today for this class
      final todayAttendance = await AttendanceService.getClassAttendanceByDate(
        classModel.id,
        normalizedToday,
      );

      // Count present students for today
      presentToday += todayAttendance
          .where((attendance) => attendance.isPresent)
          .length;
    }

    return {
      'totalClasses': classes.length,
      'totalStudents': totalStudents,
      'presentToday': presentToday,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF4CAF50),
          child: CustomScrollView(
            slivers: [
              // Modern App Bar with consistent green theme
              UIUtils.createSliverAppBar(
                title: 'Teacher Dashboard',
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: UIUtils.mediumRadius,
                    ),
                    child: PopupMenuButton<MenuAction>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        switch (value) {
                          case MenuAction.logout:
                            final shouldLogout = await showLogoutDialog(
                              context,
                            );
                            if (shouldLogout) {
                              await AuthService.firebase().logOut();
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem<MenuAction>(
                            value: MenuAction.logout,
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ],
              ),

              // Welcome Section with real teacher info
              SliverToBoxAdapter(
                child: UIUtils.createGradientContainer(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  gradient: UIUtils.lightGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: UIUtils.primaryGreen.withOpacity(0.1),
                              borderRadius: UIUtils.mediumRadius,
                            ),
                            child: const Icon(
                              Icons.school,
                              color: UIUtils.primaryGreen,
                              size: 24,
                            ),
                          ),
                          UIUtils.mediumHorizontalSpacing,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentTeacher != null
                                      ? 'Welcome back, ${_currentTeacher!.name}!'
                                      : 'Welcome Back!',
                                  style: UIUtils.subheadingStyle,
                                ),
                                Text(
                                  _isLoading
                                      ? 'Loading your dashboard...'
                                      : 'Ready to manage your classes?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Cards Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Action Cards List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildModernActionCard(
                      context,
                      title: 'Manage Classes',
                      subtitle:
                          'View classes, mark attendance, and manage students',
                      icon: Icons.school,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TeacherClassManagementView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildModernActionCard(
                      context,
                      title: 'Attendance Reports',
                      subtitle:
                          'View detailed attendance reports and analytics',
                      icon: Icons.analytics_outlined,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TeacherClassManagementView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildModernActionCard(
                      context,
                      title: 'Profile Settings',
                      subtitle: 'Update your profile and preferences',
                      icon: Icons.person_outline,
                      color: Colors.orange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile management coming soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ]),
                ),
              ),

              // Today's Summary Section with real data
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? _buildLoadingStats()
                          : _assignedClasses.isEmpty
                          ? _buildNoClassesMessage()
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Classes',
                                    '${_todayStats['totalClasses'] ?? 0}',
                                    Icons.school,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Students',
                                    '${_todayStats['totalStudents'] ?? 0}',
                                    Icons.people,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Present',
                                    '${_todayStats['presentToday'] ?? 0}',
                                    Icons.check_circle,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: UIUtils.largeRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: UIUtils.largeRadius,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: UIUtils.gradientDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withOpacity(0.03)],
            ),
            borderRadius: UIUtils.largeRadius,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: UIUtils.mediumRadius,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              UIUtils.mediumHorizontalSpacing,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UIUtils.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    UIUtils.smallVerticalSpacing,
                    Text(subtitle, style: UIUtils.captionStyle),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoClassesMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No Classes Assigned',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact the administrator to get assigned to classes',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: [
        Expanded(
          child: _buildLoadingSummaryCard('Classes', Icons.school, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLoadingSummaryCard(
            'Students',
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLoadingSummaryCard(
            'Present',
            Icons.check_circle,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSummaryCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Container(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: color, strokeWidth: 2),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

Future<bool> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Logout'),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
