import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/services/class_service.dart';
import 'package:tuition_app/services/student_service.dart';

class AssignStudentsView extends StatefulWidget {
  final ClassModel classModel;

  const AssignStudentsView({super.key, required this.classModel});

  @override
  State<AssignStudentsView> createState() => _AssignStudentsViewState();
}

class _AssignStudentsViewState extends State<AssignStudentsView> {
  List<Student> allStudents = [];
  List<Student> assignedStudents = [];
  List<Student> availableStudents = [];
  bool _isLoading = true;
  Student? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      // Get all students
      final students = await StudentService.getAllStudents().first;

      // Get assigned students
      final assigned = await StudentService.getStudentsByIds(
        widget.classModel.studentIds,
      );

      // Calculate available students
      final available = students
          .where(
            (student) => !widget.classModel.studentIds.contains(student.id),
          )
          .toList();

      setState(() {
        allStudents = students;
        assignedStudents = assigned;
        availableStudents = available;
        _isLoading = false;
        _selectedStudent = null; // Reset selection
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    }
  }

  Future<void> _addStudent(Student student) async {
    try {
      await ClassService.addStudentToClass(widget.classModel.id, student.id);

      setState(() {
        assignedStudents.add(student);
        availableStudents.remove(student);
        _selectedStudent = null; // Reset dropdown selection
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.name} added to class')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding student: $e')));
      }
    }
  }

  Future<void> _removeStudent(Student student) async {
    try {
      await ClassService.removeStudentFromClass(
        widget.classModel.id,
        student.id,
      );

      setState(() {
        assignedStudents.remove(student);
        availableStudents.add(student);
        _selectedStudent = null; // Reset dropdown selection
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.name} removed from class')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing student: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Students - ${widget.classModel.displayName}'),
        backgroundColor: const Color.fromARGB(255, 73, 226, 31),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Add student section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Student to Class',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (availableStudents.isEmpty)
                            const Text(
                              'All students are already assigned to this class',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            DropdownButtonFormField<Student>(
                              decoration: const InputDecoration(
                                labelText: 'Select Student',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedStudent,
                              items: availableStudents.map((student) {
                                return DropdownMenuItem<Student>(
                                  value: student,
                                  child: Text(student.name),
                                );
                              }).toList(),
                              onChanged: (student) {
                                setState(() {
                                  _selectedStudent = student;
                                });
                                if (student != null) {
                                  _addStudent(student);
                                }
                              },
                              hint: const Text('Choose a student to add'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assigned students section
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Students (${assignedStudents.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (assignedStudents.isEmpty)
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'No students assigned to this class yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  itemCount: assignedStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = assignedStudents[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Text(
                                          student.name.isNotEmpty
                                              ? student.name[0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(student.name),
                                      subtitle: Text(
                                        'Parent: ${student.parentContact}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removeStudent(student),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
