import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/models/attendance.dart';
import 'package:tuition_app/services/student_service.dart';
import 'package:tuition_app/services/attendance_service.dart';
import 'package:tuition_app/services/auth/auth_service.dart';

class MarkAttendanceView extends StatefulWidget {
  final ClassModel classModel;

  const MarkAttendanceView({super.key, required this.classModel});

  @override
  State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends State<MarkAttendanceView> {
  List<Student> _students = [];
  Map<String, bool> _attendanceStatus = {}; // studentId -> isPresent
  Map<String, String> _remarks = {}; // studentId -> remarks
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  bool _attendanceAlreadyMarked = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _checkAttendanceStatus();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await StudentService.getStudentsByIds(
        widget.classModel.studentIds,
      );
      if (mounted) {
        setState(() {
          _students = students;
          // Initialize attendance status to all present by default
          for (final student in students) {
            _attendanceStatus[student.id] = true;
            _remarks[student.id] = '';
          }
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
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAttendanceStatus() async {
    try {
      // Normalize the selected date to remove time component
      final normalizedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final isMarked = await AttendanceService.isAttendanceMarked(
        widget.classModel.id,
        normalizedDate,
      );

      // If attendance is already marked, load the existing attendance data
      if (isMarked) {
        final existingAttendance =
            await AttendanceService.getClassAttendanceByDate(
              widget.classModel.id,
              normalizedDate,
            );

        if (mounted) {
          setState(() {
            _attendanceAlreadyMarked = isMarked;

            // Update attendance status with existing data
            for (final attendance in existingAttendance) {
              _attendanceStatus[attendance.studentId] = attendance.isPresent;
              _remarks[attendance.studentId] = attendance.remarks ?? '';
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _attendanceAlreadyMarked = false;
          });
        }
      }
    } catch (e) {
      // If there's an error checking status, assume it's not marked
      if (mounted) {
        setState(() {
          _attendanceAlreadyMarked = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _checkAttendanceStatus();
    }
  }

  Future<void> _markAttendance() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = AuthService.firebase().currentUser;
      final teacherEmail = currentUser?.email ?? '';
      final now = DateTime.now();

      // Normalize the selected date to remove time component
      final normalizedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      if (_attendanceAlreadyMarked) {
        // Update existing attendance records
        final existingAttendance =
            await AttendanceService.getClassAttendanceByDate(
              widget.classModel.id,
              normalizedDate,
            );

        // Update each existing record
        for (final student in _students) {
          final existingRecord = existingAttendance.firstWhere(
            (record) => record.studentId == student.id,
            orElse: () => Attendance(
              id: '',
              classId: widget.classModel.id,
              studentId: student.id,
              date: normalizedDate,
              isPresent: true,
              createdAt: now,
              createdBy: teacherEmail,
            ),
          );

          final updatedRecord = existingRecord.copyWith(
            isPresent: _attendanceStatus[student.id] ?? true,
            remarks: _remarks[student.id]?.isNotEmpty == true
                ? _remarks[student.id]
                : null,
            createdBy: teacherEmail,
          );

          if (existingRecord.id.isNotEmpty) {
            // Update existing record
            await AttendanceService.updateAttendance(updatedRecord);
          } else {
            // Create new record if it doesn't exist for this student
            await AttendanceService.markAttendance(updatedRecord);
          }
        }
      } else {
        // Create new attendance records
        final attendanceList = <Attendance>[];

        for (final student in _students) {
          final attendance = Attendance(
            id: '',
            classId: widget.classModel.id,
            studentId: student.id,
            date: normalizedDate,
            isPresent: _attendanceStatus[student.id] ?? true,
            remarks: _remarks[student.id]?.isNotEmpty == true
                ? _remarks[student.id]
                : null,
            createdAt: now,
            createdBy: teacherEmail,
          );
          attendanceList.add(attendance);
        }

        await AttendanceService.markBulkAttendanceWithDuplicatePrevention(
          attendanceList,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _attendanceAlreadyMarked
                  ? 'Attendance updated successfully!'
                  : 'Attendance marked successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${_attendanceAlreadyMarked ? "updating" : "marking"} attendance: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mark Attendance - ${widget.classModel.grade} ${widget.classModel.section}',
        ),
        backgroundColor: const Color.fromARGB(255, 73, 226, 31),
        actions: [
          if (_attendanceAlreadyMarked)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.warning, color: Colors.orange),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date selector and info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Change Date'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                73,
                                226,
                                31,
                              ),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_attendanceAlreadyMarked)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Attendance already marked for this date. The form shows current values. You can update them and save.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Students list
                Expanded(
                  child: _students.isEmpty
                      ? const Center(
                          child: Text(
                            'No students assigned to this class',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final isPresent =
                                _attendanceStatus[student.id] ?? true;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isPresent
                                      ? Colors.green
                                      : Colors.red,
                                  child: Text(
                                    student.name.isNotEmpty
                                        ? student.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Contact: ${student.parentContact}'),
                                    const SizedBox(height: 4),
                                    TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Add remarks (optional)',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        _remarks[student.id] = value;
                                      },
                                    ),
                                  ],
                                ),
                                trailing: Switch(
                                  value: isPresent,
                                  activeColor: Colors.green,
                                  onChanged: (value) {
                                    setState(() {
                                      _attendanceStatus[student.id] = value;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Submit button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _markAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 73, 226, 31),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _attendanceAlreadyMarked
                                  ? 'Update Attendance'
                                  : 'Mark Attendance',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
