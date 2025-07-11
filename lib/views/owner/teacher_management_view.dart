import 'package:flutter/material.dart';
import 'package:tuition_app/models/teacher.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/views/owner/create_teacher_view.dart';
import 'package:tuition_app/views/owner/edit_teacher_view.dart';
import 'package:tuition_app/utils/ui_utils.dart';
import 'package:tuition_app/utils/service_utils.dart';

class TeacherManagementView extends StatefulWidget {
  const TeacherManagementView({super.key});

  @override
  State<TeacherManagementView> createState() => _TeacherManagementViewState();
}

class _TeacherManagementViewState extends State<TeacherManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: UIUtils.gradientDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.zero,
          ),
        ),
        title: const Text('Teacher Management', style: UIUtils.whiteTextStyle),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: UIUtils.extraLargeRadius,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: StreamBuilder<List<Teacher>>(
              stream: TeacherService.getAllTeachers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allTeachers = snapshot.data ?? [];
                final filteredTeachers = allTeachers
                    .where(
                      (teacher) =>
                          _searchQuery.isEmpty ||
                          teacher.name.toLowerCase().contains(_searchQuery) ||
                          teacher.email.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                if (filteredTeachers.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No teachers found matching "$_searchQuery"'
                                : 'No teachers yet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add your first teacher to get started',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final teacher = filteredTeachers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: UIUtils.mediumRadius,
                        ),
                        child: InkWell(
                          borderRadius: UIUtils.mediumRadius,
                          onTap: () => _showTeacherDetails(context, teacher),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: UIUtils.gradientDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF9C27B0),
                                        Color(0xFF7B1FA2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(30),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      teacher.name.isNotEmpty
                                          ? teacher.name[0].toUpperCase()
                                          : 'T',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teacher.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.email,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              teacher.email,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF9C27B0,
                                          ).withOpacity(0.1),
                                          borderRadius: UIUtils.smallRadius,
                                        ),
                                        child: const Text(
                                          'Staff Member',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9C27B0),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) => _handleTeacherAction(
                                    context,
                                    value,
                                    teacher,
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: filteredTeachers.length),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateTeacherView()),
        ),
        backgroundColor: const Color(0xFF9C27B0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Teacher',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showTeacherDetails(BuildContext context, Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(teacher.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', teacher.email, Icons.email),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Staff Member',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9C27B0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editTeacher(teacher);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
            ),
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _handleTeacherAction(
    BuildContext context,
    String action,
    Teacher teacher,
  ) {
    switch (action) {
      case 'edit':
        _editTeacher(teacher);
        break;
      case 'delete':
        _deleteTeacher(teacher);
        break;
    }
  }

  void _editTeacher(Teacher teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTeacherView(teacher: teacher),
      ),
    );
  }

  void _deleteTeacher(Teacher teacher) async {
    final shouldDelete = await ServiceUtils.showDeleteConfirmation(
      context: context,
      itemName: teacher.name,
    );

    if (shouldDelete) {
      try {
        await TeacherService.deleteTeacher(teacher.id);
        if (mounted) {
          ServiceUtils.showSuccessMessage(
            context: context,
            message: '${teacher.name} deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          ServiceUtils.handleServiceError(
            error: e,
            context: context,
            customMessage: 'Error deleting teacher: $e',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
