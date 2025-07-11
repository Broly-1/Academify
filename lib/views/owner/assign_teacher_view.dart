import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/teacher.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/teacher_service.dart';

class AssignTeacherView extends StatefulWidget {
  final ClassModel classModel;

  const AssignTeacherView({super.key, required this.classModel});

  @override
  State<AssignTeacherView> createState() => _AssignTeacherViewState();
}

class _AssignTeacherViewState extends State<AssignTeacherView> {
  Teacher? _selectedTeacher;
  Teacher? _currentTeacher;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentTeacher();
  }

  void _loadCurrentTeacher() async {
    if (widget.classModel.teacherId != null) {
      try {
        final teacher = await TeacherService.getTeacher(
          widget.classModel.teacherId!,
        );
        if (mounted) {
          setState(() {
            _currentTeacher = teacher;
            _selectedTeacher = teacher;
          });
        }
      } catch (e) {
        // Handle error if needed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 73, 226, 31),
        title: Text('Assign Teacher - ${widget.classModel.displayName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Grade: ${widget.classModel.grade}'),
                    Text('Section: ${widget.classModel.section}'),
                    Text('Year: ${widget.classModel.year}'),
                    Text(
                      'Monthly Fee: Rs. ${widget.classModel.monthlyFee.toStringAsFixed(0)}',
                    ),
                    if (_currentTeacher != null)
                      Text('Current Teacher: ${_currentTeacher!.name}')
                    else
                      const Text('Current Teacher: Not assigned'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Teacher',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_currentTeacher != null)
              Card(
                color: Colors.yellow[50],
                child: ListTile(
                  leading: const Icon(Icons.info, color: Colors.orange),
                  title: const Text('Currently Assigned'),
                  subtitle: Text(_currentTeacher!.name),
                  trailing: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTeacher = null;
                      });
                    },
                    child: const Text('Remove'),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Teacher>>(
                stream: TeacherService.getAllTeachers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final teachers = snapshot.data ?? [];

                  if (teachers.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No teachers available',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Add teachers first to assign them to classes',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      final isSelected = _selectedTeacher?.id == teacher.id;

                      return Card(
                        color: isSelected ? Colors.green[50] : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.orange,
                            child: Text(
                              teacher.name.isNotEmpty
                                  ? teacher.name[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            teacher.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(teacher.email),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedTeacher = teacher;
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _assignTeacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 73, 226, 31),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedTeacher == null
                            ? 'Remove Teacher Assignment'
                            : 'Assign Selected Teacher',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _assignTeacher() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedClass = widget.classModel.copyWith(
        teacherId: _selectedTeacher?.id,
      );

      await ClassService.updateClass(updatedClass);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedTeacher != null
                  ? '${_selectedTeacher!.name} assigned to ${widget.classModel.displayName}'
                  : 'Teacher assignment removed from ${widget.classModel.displayName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning teacher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
