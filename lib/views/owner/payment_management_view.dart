import 'package:flutter/material.dart';
import 'package:academify/models/class_model.dart';
import 'package:academify/models/student.dart';
import 'package:academify/models/payment.dart';
import 'package:academify/services/payment_service.dart';
import 'package:academify/services/pdf_service.dart';
import 'package:academify/services/class_service.dart';
import 'package:academify/services/student_service.dart';

class PaymentManagementView extends StatefulWidget {
  const PaymentManagementView({super.key});

  @override
  State<PaymentManagementView> createState() => _PaymentManagementViewState();
}

class _PaymentManagementViewState extends State<PaymentManagementView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  List<Student> _students = [];
  List<Payment> _payments = [];
  List<Payment> _overduePayments = [];

  String _selectedMonth = _getMonthName(DateTime.now().month);
  int _selectedYear = DateTime.now().year;

  bool _isLoading = false;

  // Payment statistics
  int _totalPayments = 0;
  int _paidPayments = 0;
  int _unpaidPayments = 0;
  int _overduePaymentsCount = 0;
  double _totalRevenue = 0.0;
  double _pendingRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    ); // Changed from 3 to 4
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final classesStream = ClassService.getAllClasses();
      final classes = await classesStream.first;
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty) {
          _selectedClass = classes.first;
          _loadClassData();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load classes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClassData() async {
    if (_selectedClass == null) return;

    setState(() => _isLoading = true);
    try {
      final students = await StudentService.getStudentsByIds(
        _selectedClass!.studentIds,
      );
      final payments = await PaymentService.getClassPayments(
        classId: _selectedClass!.id,
        month: _selectedMonth,
        year: _selectedYear,
      );

      // Get overdue payments for this class
      final overduePayments = await PaymentService.getClassOverduePayments(
        classId: _selectedClass!.id,
        month: _selectedMonth,
        year: _selectedYear,
      );

      // Calculate statistics
      final stats = await PaymentService.getClassPaymentStats(
        classId: _selectedClass!.id,
        month: _selectedMonth,
        year: _selectedYear,
      );

      setState(() {
        _students = students;
        _payments = payments;
        _overduePayments = overduePayments;
        _totalPayments = stats['totalPayments'] ?? 0;
        _paidPayments = stats['paidPayments'] ?? 0;
        _unpaidPayments = stats['unpaidPayments'] ?? 0;
        _overduePaymentsCount = overduePayments.length;
        _totalRevenue = stats['totalRevenue'] ?? 0.0;
        _pendingRevenue = stats['pendingRevenue'] ?? 0.0;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load class data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPaymentsAndChallans() async {
    if (_selectedClass == null || _students.isEmpty) return;

    // Show dialog to get extra dues and due date
    final paymentDetails = await _showPaymentCreationDialog();
    if (paymentDetails == null) return;

    setState(() => _isLoading = true);
    try {
      final totalAmount =
          _selectedClass!.monthlyFee + (paymentDetails['extraDues'] ?? 0.0);

      // Create payment records
      await PaymentService.createClassPayments(
        classId: _selectedClass!.id,
        students: _students,
        amount: totalAmount,
        month: _selectedMonth,
        year: _selectedYear,
      );

      // Generate fee challans
      await PDFService.generateBatchFeeChallans(
        classModel: _selectedClass!,
        students: _students,
        month: _selectedMonth,
        year: _selectedYear,
        feeAmount: totalAmount,
        dueDate: paymentDetails['dueDate'],
        extraDues: paymentDetails['extraDues'] ?? 0.0,
      );

      _showSuccessSnackBar(
        'Payment records created and fee challans generated successfully',
      );
      _loadClassData();
    } catch (e) {
      _showErrorSnackBar('Failed to create payments and challans: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _showPaymentCreationDialog() async {
    double extraDues = 0.0;
    DateTime? dueDate;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Payments & Fee Challans'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display class fee (non-editable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Monthly Fee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Rs. ${_selectedClass!.monthlyFee}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Extra dues input
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Extra Dues (Rs.)',
                  prefixText: 'Rs. ',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    extraDues = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Total amount display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Rs. ${(_selectedClass!.monthlyFee + extraDues).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Due date selection
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dueDate == null
                          ? 'Due Date: Not selected'
                          : 'Due Date: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 15),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final dueDateStr = dueDate != null
                    ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                    : null;
                Navigator.pop(context, {
                  'extraDues': extraDues,
                  'dueDate': dueDateStr,
                });
              },
              child: const Text('Create & Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaymentAsPaid(Payment payment) async {
    try {
      await PaymentService.markPaymentAsPaid(
        paymentId: payment.id,
        paymentMethod: 'Cash', // Default payment method
      );
      _showSuccessSnackBar('Payment marked as paid');
      _loadClassData();
    } catch (e) {
      _showErrorSnackBar('Failed to mark payment as paid: $e');
    }
  }

  Future<void> _markPaymentAsUnpaid(Payment payment) async {
    try {
      await PaymentService.markPaymentAsUnpaid(paymentId: payment.id);
      _showSuccessSnackBar('Payment marked as unpaid');
      _loadClassData();
    } catch (e) {
      _showErrorSnackBar('Failed to mark payment as unpaid: $e');
    }
  }

  Future<void> _generatePaymentReceipts() async {
    if (_selectedClass == null || _students.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Use fee amount from first payment or class monthly fee
      double feeAmount = _selectedClass!.monthlyFee;
      if (_payments.isNotEmpty) {
        feeAmount = _payments.first.amount;
      }

      await PDFService.generatePaymentReceiptsPDF(
        classModel: _selectedClass!,
        students: _students,
        feeAmount: feeAmount,
        month: _selectedMonth,
        year: _selectedYear,
      );

      _showSuccessSnackBar('Payment receipts generated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to generate receipts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Students'),
            Tab(text: 'Overdue'),
            Tab(text: 'Receipts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildFilterSection(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildStudentsTab(),
                        _buildOverdueTab(),
                        _buildReceiptsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // First row - Class selection
          DropdownButtonFormField<ClassModel>(
            value: _selectedClass,
            decoration: const InputDecoration(
              labelText: 'Select Class',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _classes.map((classModel) {
              return DropdownMenuItem(
                value: classModel,
                child: Text('${classModel.grade} ${classModel.section}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedClass = value);
              _loadClassData();
            },
          ),
          const SizedBox(height: 8),
          // Second row - Month and Year
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(12, (index) {
                    final month = _getMonthName(index + 1);
                    return DropdownMenuItem(value: month, child: Text(month));
                  }),
                  onChanged: (value) {
                    setState(() => _selectedMonth = value!);
                    _loadClassData();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem(value: year, child: Text('$year'));
                  }),
                  onChanged: (value) {
                    setState(() => _selectedYear = value!);
                    _loadClassData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Statistics Cards - Use a responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 600 ? 4 : 2;
              final childAspectRatio = width > 600 ? 2.2 : 2.0;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildStatCard(
                    'Total Payments',
                    '$_totalPayments',
                    Icons.receipt,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Paid',
                    '$_paidPayments',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Unpaid',
                    '$_unpaidPayments',
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Overdue',
                    '$_overduePaymentsCount',
                    Icons.warning,
                    Colors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Revenue Cards - Stack vertically on small screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildRevenueCard(
                        'Total Revenue',
                        'Rs. ${_totalRevenue.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRevenueCard(
                        'Pending Revenue',
                        'Rs. ${_pendingRevenue.toStringAsFixed(2)}',
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRevenueCard(
                      'Total Revenue',
                      'Rs. ${_totalRevenue.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildRevenueCard(
                      'Pending Revenue',
                      'Rs. ${_pendingRevenue.toStringAsFixed(2)}',
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // Actions - More compact layout
          if (_selectedClass != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createPaymentsAndChallans,
                          icon: const Icon(Icons.add_box, size: 20),
                          label: const Text('Create Payments & Challans'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generatePaymentReceipts,
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text('Generate Receipts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _createPaymentsAndChallans,
                          icon: const Icon(Icons.add_box, size: 20),
                          label: const Text('Create Payments & Challans'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generatePaymentReceipts,
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text('Generate Payment Receipts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    // Filter to only show students who have actual payment records
    final studentsWithPayments = _students.where((student) {
      return _payments.any((payment) => payment.studentId == student.id);
    }).toList();

    if (studentsWithPayments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No payment records found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create payments first to see student payment status',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: studentsWithPayments.length,
      itemBuilder: (context, index) {
        final student = studentsWithPayments[index];
        final payment = _payments.firstWhere((p) => p.studentId == student.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: payment.isPaid ? Colors.green : Colors.orange,
              child: Icon(
                payment.isPaid ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text(student.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: Rs. ${payment.amount}'),
                if (payment.receiptNumber != null)
                  Text('Receipt: ${payment.receiptNumber}'),
                if (payment.isOverdue)
                  const Text(
                    'OVERDUE',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    payment.isPaid ? 'Mark as Unpaid' : 'Mark as Paid',
                  ),
                ),
                if (payment.isPaid)
                  const PopupMenuItem(
                    value: 'receipt',
                    child: Text('Generate Receipt'),
                  ),
              ],
              onSelected: (value) async {
                if (value == 'toggle') {
                  if (payment.isPaid) {
                    await _markPaymentAsUnpaid(payment);
                  } else {
                    await _markPaymentAsPaid(payment);
                  }
                } else if (value == 'receipt') {
                  try {
                    await PDFService.generateIndividualPaymentReceipt(
                      payment: payment,
                      student: student,
                      classModel: _selectedClass!,
                    );
                    _showSuccessSnackBar('Receipt generated');
                  } catch (e) {
                    _showErrorSnackBar('Failed to generate receipt: $e');
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptsTab() {
    final paidPayments = _payments.where((p) => p.isPaid).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generatePaymentReceipts,
                  icon: const Icon(Icons.print),
                  label: const Text('Generate All Receipts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: paidPayments.length,
            itemBuilder: (context, index) {
              final payment = paidPayments[index];
              final student = _students.firstWhere(
                (s) => s.id == payment.studentId,
                orElse: () => Student(
                  id: payment.studentId,
                  name: 'Unknown Student',
                  parentContact: '',
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text(student.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt: ${payment.receiptNumber ?? 'N/A'}'),
                      Text('Amount: Rs. ${payment.amount}'),
                      if (payment.paidDate != null)
                        Text(
                          'Paid: ${payment.paidDate!.day}/${payment.paidDate!.month}/${payment.paidDate!.year}',
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () async {
                      try {
                        await PDFService.generateIndividualPaymentReceipt(
                          payment: payment,
                          student: student,
                          classModel: _selectedClass!,
                        );
                        _showSuccessSnackBar('Receipt generated');
                      } catch (e) {
                        _showErrorSnackBar('Failed to generate receipt: $e');
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueTab() {
    if (_overduePayments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No overdue payments',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'All payments are up to date!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Warning header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overdue Payments Alert',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_overduePayments.length} payment(s) are overdue and require immediate attention.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Overdue payments list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _overduePayments.length,
            itemBuilder: (context, index) {
              final payment = _overduePayments[index];
              final student = _students.firstWhere(
                (s) => s.id == payment.studentId,
                orElse: () => Student(
                  id: payment.studentId,
                  name: 'Unknown Student',
                  parentContact: '',
                ),
              );

              final daysPastDue = DateTime.now()
                  .difference(payment.dueDate)
                  .inDays;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300, width: 1),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(
                        '$daysPastDue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount: Rs. ${payment.amount}'),
                        Text(
                          'Due: ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}',
                        ),
                        Text(
                          '$daysPastDue days overdue',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (payment.notes?.contains('OVERDUE') == true)
                          const Text(
                            'Multiple challans created',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'pay',
                          child: Text('Mark as Paid'),
                        ),
                        const PopupMenuItem(
                          value: 'details',
                          child: Text('View Details'),
                        ),
                        const PopupMenuItem(
                          value: 'contact',
                          child: Text('Contact Student'),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'pay') {
                          await _markOverduePaymentAsPaid(payment);
                        } else if (value == 'details') {
                          _showPaymentDetails(payment, student);
                        } else if (value == 'contact') {
                          _showContactStudent(student);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _markOverduePaymentAsPaid(Payment payment) async {
    try {
      await PaymentService.markOverduePaymentAsPaid(
        paymentId: payment.id,
        paymentMethod: 'Cash', // Default payment method
      );
      _showSuccessSnackBar('Overdue payment marked as paid');
      _loadClassData();
    } catch (e) {
      _showErrorSnackBar('Failed to mark overdue payment as paid: $e');
    }
  }

  void _showPaymentDetails(Payment payment, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student.name}'),
            const SizedBox(height: 8),
            Text('Amount: Rs. ${payment.amount}'),
            const SizedBox(height: 8),
            Text(
              'Due Date: ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}',
            ),
            const SizedBox(height: 8),
            Text(
              'Days Overdue: ${DateTime.now().difference(payment.dueDate).inDays}',
            ),
            if (payment.notes != null) ...[
              const SizedBox(height: 8),
              Text('Notes: ${payment.notes}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactStudent(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${student.name}'),
            const SizedBox(height: 8),
            Text('Contact: ${student.parentContact}'),
            const SizedBox(height: 16),
            const Text(
              'You can contact the student or parent regarding the overdue payment.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
