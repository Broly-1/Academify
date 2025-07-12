import 'package:flutter/material.dart';
import 'package:academify/models/class_model.dart';
import 'package:academify/models/student.dart';
import 'package:academify/services/class_service.dart';
import 'package:academify/services/student_service.dart';

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
  List<Student> filteredStudents = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        filteredStudents = available; // Initialize filtered list
        _isLoading = false;
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
        filteredStudents.remove(student); // Also remove from filtered list
        _searchController.clear(); // Clear search
        _showDropdown = false; // Hide dropdown
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
        // Refresh the filtered list based on current search
        _filterStudents(_searchController.text);
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

  void _filterStudents(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        filteredStudents = List.from(availableStudents);
      } else {
        // Create a set to avoid duplicates, then convert back to list
        final uniqueStudents = <String, Student>{};

        for (final student in availableStudents) {
          final studentName = student.name.toLowerCase();
          final parentContact = student.parentContact.toLowerCase();
          final search = searchTerm.toLowerCase();

          if (studentName.contains(search) || parentContact.contains(search)) {
            // Use student ID as key to ensure uniqueness
            uniqueStudents[student.id] = student;
          }
        }

        filteredStudents = uniqueStudents.values.toList();
      }
    });
  }

  Widget _buildSearchableDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Students',
            hintText: 'Type student name or contact...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterStudents('');
                      setState(() {
                        _showDropdown = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _filterStudents(value);
            setState(() {
              _showDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showDropdown = _searchController.text.isNotEmpty;
            });
          },
        ),
        if (_showDropdown && filteredStudents.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              maxHeight: 150,
            ), // Reduced height to prevent overflow
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return Container(
                  decoration: BoxDecoration(
                    border: index < filteredStudents.length - 1
                        ? const Border(
                            bottom: BorderSide(color: Colors.grey, width: 0.5),
                          )
                        : null,
                  ),
                  child: ListTile(
                    dense: true, // Make tiles more compact
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    title: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Contact: ${student.parentContact}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    onTap: () {
                      _addStudent(student);
                      setState(() {
                        _showDropdown = false;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        if (_showDropdown &&
            filteredStudents.isEmpty &&
            _searchController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: const Text(
              'No students found matching your search',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
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
                            _buildSearchableDropdown(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ), // Reduced spacing to prevent overflow
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
