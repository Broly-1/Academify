import 'package:flutter/material.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/services/class_service.dart';

class EditClassView extends StatefulWidget {
  final ClassModel classModel;

  const EditClassView({super.key, required this.classModel});

  @override
  State<EditClassView> createState() => _EditClassViewState();
}

class _EditClassViewState extends State<EditClassView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _gradeController;
  late final TextEditingController _sectionController;
  late final TextEditingController _yearController;
  late final TextEditingController _monthlyFeeController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(text: widget.classModel.grade);
    _sectionController = TextEditingController(text: widget.classModel.section);
    _yearController = TextEditingController(text: widget.classModel.year);
    _monthlyFeeController = TextEditingController(
      text: widget.classModel.monthlyFee.toString(),
    );
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _sectionController.dispose();
    _yearController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Class'),
        backgroundColor: const Color.fromARGB(255, 73, 226, 31),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gradeController,
                              decoration: const InputDecoration(
                                labelText: 'Grade',
                                hintText: 'e.g., 9, 10, 11, 12',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter grade';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sectionController,
                              decoration: const InputDecoration(
                                labelText: 'Section',
                                hintText: 'e.g., A, B, C',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter section';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          hintText: 'e.g., 2024-2025',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter academic year';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _monthlyFeeController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Fee',
                          hintText: 'e.g., 1500, 2000',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter monthly fee';
                          }
                          final fee = double.tryParse(value.trim());
                          if (fee == null || fee <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 73, 226, 31),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Class',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedClass = widget.classModel.copyWith(
        grade: _gradeController.text.trim(),
        section: _sectionController.text.trim().toUpperCase(),
        year: _yearController.text.trim(),
        monthlyFee: double.parse(_monthlyFeeController.text.trim()),
      );

      await ClassService.updateClass(updatedClass);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating class: $e'),
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
