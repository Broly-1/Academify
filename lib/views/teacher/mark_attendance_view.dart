// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:academify/models/class_model.dart';
import 'package:academify/models/student.dart';
import 'package:academify/models/attendance.dart';
import 'package:academify/services/student_service.dart';
import 'package:academify/services/attendance_service.dart';
import 'package:academify/services/auth/auth_service.dart';
import 'package:academify/utils/ui_utils.dart';

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
      final normalizedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final isMarked = await AttendanceService.isAttendanceMarked(
        widget.classModel.id,
        normalizedDate,
      );

      if (isMarked) {
        final existingAttendance =
            await AttendanceService.getClassAttendanceByDate(
              widget.classModel.id,
              normalizedDate,
            );

        if (mounted) {
          setState(() {
            _attendanceAlreadyMarked = isMarked;
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
      print('Error checking attendance status: $e');
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
        _attendanceAlreadyMarked = false;
      });
      await _checkAttendanceStatus();
    }
  }

  Future<void> _saveAttendance() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final teacherEmail = AuthService.firebase().currentUser?.email;
      if (teacherEmail == null) {
        throw Exception('Teacher not authenticated');
      }

      final normalizedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final now = DateTime.now();

      if (_attendanceAlreadyMarked) {
        // Update existing records
        final existingAttendance =
            await AttendanceService.getClassAttendanceByDate(
              widget.classModel.id,
              normalizedDate,
            );

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
            await AttendanceService.updateAttendance(updatedRecord);
          } else {
            await AttendanceService.markAttendance(updatedRecord);
          }
        }
      } else {
        // Create new attendance records
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

          await AttendanceService.markAttendance(attendance);
        }
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _attendanceAlreadyMarked = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UIUtils.createGradientAppBar(
        title:
            'Mark Attendance - ${widget.classModel.grade} ${widget.classModel.section}',
        actions: [
          if (_attendanceAlreadyMarked)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: UIUtils.extraLargeRadius,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Editing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading students...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Modern Date Selector Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.today,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attendance Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: _selectDate,
                              icon: const Icon(
                                Icons.edit_calendar,
                                color: Colors.white,
                              ),
                              tooltip: 'Change Date',
                            ),
                          ),
                        ],
                      ),
                      if (_attendanceAlreadyMarked) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Attendance already marked for this date. You can edit existing records.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Students list
                Expanded(
                  child: _students.isEmpty
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
                                  Icons.people,
                                  size: 60,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No students assigned',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Add students to this class to mark attendance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final isPresent =
                                _attendanceStatus[student.id] ?? true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isPresent
                                                    ? [
                                                        Colors.green,
                                                        Colors.green.shade700,
                                                      ]
                                                    : [
                                                        Colors.red,
                                                        Colors.red.shade700,
                                                      ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                student.name.isNotEmpty
                                                    ? student.name[0]
                                                          .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
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
                                                  student.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.phone,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      student.parentContact,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isPresent
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Switch(
                                              value: isPresent,
                                              activeColor: Colors.green,
                                              inactiveTrackColor: Colors.red
                                                  .withOpacity(0.3),
                                              onChanged: (value) {
                                                setState(() {
                                                  _attendanceStatus[student
                                                          .id] =
                                                      value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: TextEditingController(
                                            text: _remarks[student.id] ?? '',
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Add remarks (optional)',
                                            prefixIcon: const Icon(
                                              Icons.note_add,
                                              color: Color(0xFF4CAF50),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          onChanged: (value) {
                                            _remarks[student.id] = value;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Save button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: UIUtils.createPrimaryButton(
                      text: _attendanceAlreadyMarked
                          ? 'Update Attendance'
                          : 'Save Attendance',
                      onPressed: _isSaving ? () {} : _saveAttendance,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
