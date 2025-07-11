import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/attendance.dart';
import 'package:tuition_app/models/payment.dart';

class PDFService {
  // Academy branding constants
  static const String _academyName = 'ACADEMIFY TUITION CENTER';
  static const String _academyTagline = 'Excellence in Education';
  static const String _academyAddress = '123 Education Street, Knowledge City';
  static const String _academyContact =
      'Phone: +91 98765 43210 | Email: info@academify.edu';
  static const String _academyWebsite = 'www.academify.edu';

  // Professional color scheme
  static final PdfColor _primaryColor = PdfColor(25, 118, 210);
  static final PdfColor _accentColor = PdfColor(255, 193, 7);
  static final PdfColor _successColor = PdfColor(76, 175, 80);
  static final PdfColor _errorColor = PdfColor(244, 67, 54);
  static final PdfColor _textSecondary = PdfColor(117, 117, 117);
  static final PdfColor _borderColor = PdfColor(224, 224, 224);

  // Professional fonts
  static PdfFont get _titleFont =>
      PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold);
  static PdfFont get _headerFont =>
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
  static PdfFont get _subHeaderFont =>
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
  static PdfFont get _bodyFont => PdfStandardFont(PdfFontFamily.helvetica, 10);
  static PdfFont get _smallFont => PdfStandardFont(PdfFontFamily.helvetica, 8);

  // Enhanced Header with Academy Branding
  static double _drawProfessionalHeader(
    PdfGraphics graphics,
    PdfPage page,
    String documentTitle, {
    String? copyType,
  }) {
    final pageWidth = page.getClientSize().width;
    double yPosition = 40;

    // Academy logo placeholder
    final logoRect = Rect.fromLTWH(50, yPosition, 60, 60);
    graphics.drawRectangle(
      pen: PdfPen(_primaryColor, width: 2),
      brush: PdfSolidBrush(PdfColor(25, 118, 210, 20)),
      bounds: logoRect,
    );

    // Draw simple logo text
    graphics.drawString(
      'A',
      PdfStandardFont(PdfFontFamily.helvetica, 36, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(65, yPosition + 15, 30, 30),
      brush: PdfSolidBrush(_primaryColor),
    );

    // Academy name and details - centered in available space after logo
    final textStartX = 130.0;
    final availableWidth = pageWidth - textStartX - 50; // 50 for right margin

    graphics.drawString(
      _academyName,
      _titleFont,
      bounds: Rect.fromLTWH(
        textStartX,
        yPosition + 5,
        availableWidth * 0.7,
        25,
      ),
      brush: PdfSolidBrush(_primaryColor),
    );

    graphics.drawString(
      _academyTagline,
      _subHeaderFont,
      bounds: Rect.fromLTWH(
        textStartX,
        yPosition + 25,
        availableWidth * 0.7,
        15,
      ),
      brush: PdfSolidBrush(_textSecondary),
    );

    // Copy type indicator - properly positioned on the right
    if (copyType != null) {
      final copyTypeWidth = 120.0;
      final copyTypeX = pageWidth - copyTypeWidth - 50; // 50 for right margin
      graphics.drawString(
        copyType.toUpperCase(),
        _headerFont,
        bounds: Rect.fromLTWH(copyTypeX, yPosition + 15, copyTypeWidth, 20),
        brush: PdfSolidBrush(_accentColor),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    yPosition += 70;

    // Contact information - centered
    final contentWidth = pageWidth - 100; // 50 margin on each side
    graphics.drawString(
      _academyAddress,
      _bodyFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    yPosition += 15;

    graphics.drawString(
      _academyContact,
      _bodyFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    yPosition += 15;

    // Document title with decorative line
    graphics.drawLine(
      PdfPen(_primaryColor, width: 3),
      Offset(50, yPosition + 5),
      Offset(pageWidth - 50, yPosition + 5),
    );
    yPosition += 15;

    graphics.drawString(
      documentTitle.toUpperCase(),
      _headerFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 20),
      brush: PdfSolidBrush(_primaryColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    yPosition += 25;

    // Generation timestamp
    final now = DateTime.now();
    graphics.drawString(
      'Generated on: ${now.day}/${now.month}/${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      _smallFont,
      bounds: Rect.fromLTWH(50, yPosition, 500, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    return yPosition + 30;
  }

  // Enhanced Footer with Academy Branding
  static void _drawProfessionalFooter(
    PdfGraphics graphics,
    PdfPage page, {
    String? copyType,
  }) {
    final pageSize = page.size;
    double yPosition = pageSize.height - 80;

    // Footer separator line
    graphics.drawLine(
      PdfPen(_borderColor, width: 1),
      Offset(50, yPosition),
      Offset(pageSize.width - 50, yPosition),
    );
    yPosition += 10;

    // Academy info
    graphics.drawString(
      _academyName,
      _smallFont,
      bounds: Rect.fromLTWH(50, yPosition, 200, 12),
      brush: PdfSolidBrush(_textSecondary),
    );

    graphics.drawString(
      _academyWebsite,
      _smallFont,
      bounds: Rect.fromLTWH(300, yPosition, 150, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Page number
    graphics.drawString(
      'Page 1',
      _smallFont,
      bounds: Rect.fromLTWH(pageSize.width - 100, yPosition, 50, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    yPosition += 15;

    // Confidentiality notice
    String confidentialityText = copyType == 'Student Copy'
        ? 'This is an official document. Please keep it safe for your records.'
        : 'Confidential Document - For Internal Use Only';

    graphics.drawString(
      confidentialityText,
      _smallFont,
      bounds: Rect.fromLTWH(50, yPosition, pageSize.width - 100, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    yPosition += 15;

    // Copyright
    graphics.drawString(
      '© ${DateTime.now().year} $_academyName. All rights reserved.',
      _smallFont,
      bounds: Rect.fromLTWH(50, yPosition, pageSize.width - 100, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
  }

  // Student Copy - Attendance Report
  static Future<Uint8List> generateAttendanceReportForStudent(
    ClassModel classModel,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _generateAttendanceReportForCopy(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
      'Student Copy',
    );
  }

  // Teacher Copy - Attendance Report
  static Future<Uint8List> generateAttendanceReportForTeacher(
    ClassModel classModel,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _generateAttendanceReportForCopy(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
      'Teacher Copy',
    );
  }

  // Student Copy - Attendance Report with Preview
  static Future<void> previewAttendanceReportForStudent(
    ClassModel classModel,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdfBytes = await generateAttendanceReportForStudent(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name:
          'Attendance_Report_Student_${classModel.grade}_${classModel.section}.pdf',
    );
  }

  // Teacher Copy - Attendance Report with Preview
  static Future<void> previewAttendanceReportForTeacher(
    ClassModel classModel,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdfBytes = await generateAttendanceReportForTeacher(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name:
          'Attendance_Report_Teacher_${classModel.grade}_${classModel.section}.pdf',
    );
  }

  // Enhanced Attendance Report Generator
  static Future<Uint8List> _generateAttendanceReportForCopy(
    ClassModel classModel,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate,
    String copyType,
  ) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;

    // Professional header
    double yPosition = _drawProfessionalHeader(
      graphics,
      page,
      'Attendance Report',
      copyType: copyType,
    );

    yPosition += 20;

    final pageWidth = page.getClientSize().width;
    final contentWidth = pageWidth - 100; // 50 margin on each side
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth =
        (contentWidth / 2) - 20; // 20 for spacing between columns

    // Class Information Section
    final headerRect = Rect.fromLTWH(50, yPosition, contentWidth, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
      bounds: headerRect,
    );

    graphics.drawString(
      'CLASS INFORMATION',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, contentWidth - 20, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 35;

    // Class details
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Class:',
      '${classModel.grade} ${classModel.section}',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Academic Year:',
      classModel.year,
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Report Period:',
      '${startDate.day}/${startDate.month}/${startDate.year} to ${endDate.day}/${endDate.month}/${endDate.year}',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Monthly Fee:',
      '₹${classModel.monthlyFee.toStringAsFixed(2)}',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 40;

    // Attendance table
    yPosition = _drawAttendanceTable(
      graphics,
      students,
      attendanceRecords,
      startDate,
      endDate,
      yPosition,
      copyType,
    );

    // Add summary for teacher copy
    if (copyType == 'Teacher Copy') {
      yPosition += 30;
      yPosition = _drawAttendanceSummary(
        graphics,
        students,
        attendanceRecords,
        yPosition,
      );
    }

    // Professional footer
    _drawProfessionalFooter(graphics, page, copyType: copyType);

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();
    return bytes;
  }

  // Professional attendance table
  static double _drawAttendanceTable(
    PdfGraphics graphics,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate,
    double yPosition,
    String copyType,
  ) {
    // Table header
    final headerRect = Rect.fromLTWH(50, yPosition, 500, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(_primaryColor),
      bounds: headerRect,
    );

    graphics.drawString(
      'ATTENDANCE RECORDS',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, 400, 15),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
    );
    yPosition += 35;

    final totalDays = endDate.difference(startDate).inDays + 1;

    // Column widths
    const double studentNameWidth = 150;
    const double rollNumberWidth = 80;
    const double presentDaysWidth = 80;
    const double attendancePercentWidth = 100;
    const double statusWidth = 90;

    // Table header row
    final tableHeaderRect = Rect.fromLTWH(50, yPosition, 500, 20);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(240, 240, 240)),
      pen: PdfPen(_borderColor),
      bounds: tableHeaderRect,
    );

    double xPosition = 60;
    graphics.drawString(
      'Student Name',
      _subHeaderFont,
      bounds: Rect.fromLTWH(xPosition, yPosition + 3, studentNameWidth, 15),
    );
    xPosition += studentNameWidth;

    graphics.drawString(
      'Student ID',
      _subHeaderFont,
      bounds: Rect.fromLTWH(xPosition, yPosition + 3, rollNumberWidth, 15),
    );
    xPosition += rollNumberWidth;

    graphics.drawString(
      'Present Days',
      _subHeaderFont,
      bounds: Rect.fromLTWH(xPosition, yPosition + 3, presentDaysWidth, 15),
    );
    xPosition += presentDaysWidth;

    graphics.drawString(
      'Attendance %',
      _subHeaderFont,
      bounds: Rect.fromLTWH(
        xPosition,
        yPosition + 3,
        attendancePercentWidth,
        15,
      ),
    );
    xPosition += attendancePercentWidth;

    graphics.drawString(
      'Status',
      _subHeaderFont,
      bounds: Rect.fromLTWH(xPosition, yPosition + 3, statusWidth, 15),
    );

    yPosition += 25;

    // Student data rows
    for (final student in students) {
      final studentAttendance = attendanceRecords
          .where((a) => a.studentId == student.id)
          .toList();
      final presentDays = studentAttendance.where((a) => a.isPresent).length;
      final attendancePercentage = totalDays > 0
          ? (presentDays / totalDays) * 100
          : 0;

      // Row background
      final isEvenRow = students.indexOf(student) % 2 == 0;
      if (isEvenRow) {
        graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(250, 250, 250)),
          bounds: Rect.fromLTWH(50, yPosition, 500, 20),
        );
      }

      // Row border
      graphics.drawRectangle(
        pen: PdfPen(_borderColor),
        bounds: Rect.fromLTWH(50, yPosition, 500, 20),
      );

      xPosition = 60;

      // Student name
      graphics.drawString(
        student.name,
        _bodyFont,
        bounds: Rect.fromLTWH(
          xPosition,
          yPosition + 3,
          studentNameWidth - 10,
          15,
        ),
      );
      xPosition += studentNameWidth;

      // Student ID (since rollNumber doesn't exist)
      graphics.drawString(
        student.id.substring(0, 8), // Show first 8 characters of ID
        _bodyFont,
        bounds: Rect.fromLTWH(
          xPosition,
          yPosition + 3,
          rollNumberWidth - 10,
          15,
        ),
      );
      xPosition += rollNumberWidth;

      // Present days
      graphics.drawString(
        '$presentDays / $totalDays',
        _bodyFont,
        bounds: Rect.fromLTWH(
          xPosition,
          yPosition + 3,
          presentDaysWidth - 10,
          15,
        ),
      );
      xPosition += presentDaysWidth;

      // Attendance percentage
      final percentageColor = attendancePercentage >= 75
          ? _successColor
          : _errorColor;
      graphics.drawString(
        '${attendancePercentage.toStringAsFixed(1)}%',
        _bodyFont,
        bounds: Rect.fromLTWH(
          xPosition,
          yPosition + 3,
          attendancePercentWidth - 10,
          15,
        ),
        brush: PdfSolidBrush(percentageColor),
      );
      xPosition += attendancePercentWidth;

      // Status
      final status = attendancePercentage >= 75 ? 'Good' : 'Poor';
      graphics.drawString(
        status,
        _bodyFont,
        bounds: Rect.fromLTWH(xPosition, yPosition + 3, statusWidth - 10, 15),
        brush: PdfSolidBrush(percentageColor),
      );

      yPosition += 25;
    }

    return yPosition;
  }

  // Attendance summary for teacher copy
  static double _drawAttendanceSummary(
    PdfGraphics graphics,
    List<Student> students,
    List<Attendance> attendanceRecords,
    double yPosition,
  ) {
    // Summary header
    final pageWidth = 595.0; // Standard A4 width
    final contentWidth = pageWidth - 100; // 50 margin on each side
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth =
        (contentWidth / 2) - 20; // 20 for spacing between columns

    final headerRect = Rect.fromLTWH(50, yPosition, contentWidth, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
      bounds: headerRect,
    );

    graphics.drawString(
      'ATTENDANCE SUMMARY',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, contentWidth - 20, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 35;

    // Calculate statistics
    final totalStudents = students.length;
    int studentsWithGoodAttendance = 0;
    int studentsWithPoorAttendance = 0;
    double averageAttendance = 0;

    for (final student in students) {
      final studentAttendance = attendanceRecords
          .where((a) => a.studentId == student.id)
          .toList();
      final presentDays = studentAttendance.where((a) => a.isPresent).length;
      final totalDays = attendanceRecords.map((a) => a.date).toSet().length;
      final attendancePercentage = totalDays > 0
          ? (presentDays / totalDays) * 100
          : 0;

      averageAttendance += attendancePercentage;

      if (attendancePercentage >= 75) {
        studentsWithGoodAttendance++;
      } else {
        studentsWithPoorAttendance++;
      }
    }

    averageAttendance = totalStudents > 0
        ? averageAttendance / totalStudents
        : 0;

    // Summary data
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Total Students:',
      totalStudents.toString(),
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Average Attendance:',
      '${averageAttendance.toStringAsFixed(1)}%',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Good Attendance (≥75%):',
      studentsWithGoodAttendance.toString(),
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Poor Attendance (<75%):',
      studentsWithPoorAttendance.toString(),
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );

    return yPosition + 30;
  }

  // Payment Receipt Generation
  static Future<Uint8List> generatePaymentReceipt(
    Payment payment,
    Student student,
  ) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;

    // Professional header
    double yPosition = _drawProfessionalHeader(
      graphics,
      page,
      'Payment Receipt',
      copyType: 'Student Copy',
    );
    yPosition += 20;

    final pageWidth = page.getClientSize().width;
    final contentWidth = pageWidth - 100; // 50 margin on each side
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth =
        (contentWidth / 2) - 20; // 20 for spacing between columns

    // Receipt details section
    final headerRect = Rect.fromLTWH(50, yPosition, contentWidth, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
      bounds: headerRect,
    );

    graphics.drawString(
      'RECEIPT DETAILS',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, contentWidth - 20, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 35;

    // Receipt information
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Receipt No:',
      'RCP-${payment.id}',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Date:',
      '${payment.paidDate?.day ?? payment.dueDate.day}/${payment.paidDate?.month ?? payment.dueDate.month}/${payment.paidDate?.year ?? payment.dueDate.year}',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Student Name:',
      student.name,
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Student ID:',
      student.id.substring(0, 8),
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Payment Month:',
      '${payment.month} ${payment.year}',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Payment Method:',
      payment.paymentMethod ?? 'Not specified',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 40;

    // Amount section with highlight
    final amountRect = Rect.fromLTWH(50, yPosition, contentWidth, 40);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(76, 175, 80, 30)),
      pen: PdfPen(_successColor, width: 2),
      bounds: amountRect,
    );

    graphics.drawString(
      'AMOUNT PAID',
      _headerFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, 200, 20),
      brush: PdfSolidBrush(_successColor),
    );

    graphics.drawString(
      '₹${payment.amount.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(60, yPosition + 8, contentWidth - 20, 25),
      brush: PdfSolidBrush(_successColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    yPosition += 60;

    // Status
    if (payment.isPaid) {
      graphics.drawString(
        '✓ PAID',
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 20),
        brush: PdfSolidBrush(_successColor),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // Professional footer
    _drawProfessionalFooter(graphics, page, copyType: 'Student Copy');

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();
    return bytes;
  }

  // Student Report Card
  static Future<Uint8List> generateStudentReportCard(
    Student student,
    ClassModel classModel,
  ) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;

    // Professional header
    double yPosition = _drawProfessionalHeader(
      graphics,
      page,
      'Student Report Card',
      copyType: 'Student Copy',
    );
    yPosition += 20;

    // Student information
    final headerRect = Rect.fromLTWH(50, yPosition, 500, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
      bounds: headerRect,
    );

    graphics.drawString(
      'STUDENT INFORMATION',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, 400, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 35;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Student Name:',
      student.name,
      60,
      yPosition,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Student ID:',
      student.id.substring(0, 8),
      320,
      yPosition,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Class:',
      '${classModel.grade} ${classModel.section}',
      60,
      yPosition,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Academic Year:',
      classModel.year,
      320,
      yPosition,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Parent Contact:',
      student.parentContact,
      60,
      yPosition,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Student ID (Full):',
      student.id,
      320,
      yPosition,
    );
    yPosition += 40;

    // Academic performance placeholder
    final performanceRect = Rect.fromLTWH(50, yPosition, 500, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
      bounds: performanceRect,
    );

    graphics.drawString(
      'ACADEMIC PERFORMANCE',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, 400, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 35;

    graphics.drawString(
      'Academic performance data will be available in future updates.',
      _bodyFont,
      bounds: Rect.fromLTWH(60, yPosition, 400, 15),
      brush: PdfSolidBrush(_textSecondary),
    );

    // Professional footer
    _drawProfessionalFooter(graphics, page, copyType: 'Student Copy');

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();
    return bytes;
  }

  // Helper method for drawing detail rows with responsive layout
  static void _drawDetailRow(
    PdfGraphics graphics,
    PdfFont contentFont,
    PdfFont labelFont,
    String label,
    String value,
    double x,
    double y, {
    double? maxWidth,
  }) {
    final labelWidth = maxWidth != null ? (maxWidth * 0.4) : 150.0;
    final valueWidth = maxWidth != null ? (maxWidth * 0.6) : 300.0;

    graphics.drawString(
      label,
      labelFont,
      bounds: Rect.fromLTWH(x, y, labelWidth, 20),
    );
    graphics.drawString(
      value,
      contentFont,
      bounds: Rect.fromLTWH(x + labelWidth, y, valueWidth, 20),
    );
  }

  // Utility method for backward compatibility with Preview
  static Future<void> generateAttendanceReportPDF({
    required ClassModel classModel,
    required List<Student> students,
    required List<Attendance> attendanceRecords,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // For single student, show student copy; for multiple students, show teacher copy
    if (students.length == 1) {
      await previewAttendanceReportForStudent(
        classModel,
        students,
        attendanceRecords,
        startDate,
        endDate,
      );
    } else {
      await previewAttendanceReportForTeacher(
        classModel,
        students,
        attendanceRecords,
        startDate,
        endDate,
      );
    }
  }

  // Bulk Payment Receipts Generation with Preview
  static Future<void> generatePaymentReceiptsPDF({
    required ClassModel classModel,
    required List<Student> students,
    required double feeAmount,
    required String month,
    required int year,
  }) async {
    final document = PdfDocument();

    // Generate receipts for each student in the same document
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final payment = Payment(
        id: 'receipt_${student.id}_${month}_$year',
        studentId: student.id,
        classId: classModel.id,
        month: month,
        year: year,
        amount: feeAmount,
        dueDate: DateTime.now(),
        paidDate: DateTime.now(),
        isPaid: true,
        paymentMethod: 'Cash',
        receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch}-${i + 1}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add a new page for each receipt
      final page = document.pages.add();
      final graphics = page.graphics;

      // Draw receipt content
      double yPosition = _drawProfessionalHeader(
        graphics,
        page,
        'Payment Receipt',
        copyType: 'Student Copy',
      );
      yPosition += 20;

      // Receipt details section
      final headerRect = Rect.fromLTWH(50, yPosition, 500, 25);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
        bounds: headerRect,
      );

      graphics.drawString(
        'RECEIPT DETAILS',
        _subHeaderFont,
        bounds: Rect.fromLTWH(60, yPosition + 5, 400, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      yPosition += 35;

      // Receipt information
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Receipt No:',
        payment.receiptNumber ?? 'RCP-${payment.id}',
        60,
        yPosition,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Date:',
        '${payment.paidDate?.day ?? payment.dueDate.day}/${payment.paidDate?.month ?? payment.dueDate.month}/${payment.paidDate?.year ?? payment.dueDate.year}',
        320,
        yPosition,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Student Name:',
        student.name,
        60,
        yPosition,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Student ID:',
        student.id.substring(0, 8),
        320,
        yPosition,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Payment Month:',
        '${payment.month} ${payment.year}',
        60,
        yPosition,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Payment Method:',
        payment.paymentMethod ?? 'Not specified',
        320,
        yPosition,
      );
      yPosition += 40;

      // Amount section with highlight
      final amountRect = Rect.fromLTWH(50, yPosition, 500, 40);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(76, 175, 80, 30)),
        pen: PdfPen(_successColor, width: 2),
        bounds: amountRect,
      );

      graphics.drawString(
        'AMOUNT PAID',
        _headerFont,
        bounds: Rect.fromLTWH(60, yPosition + 5, 200, 20),
        brush: PdfSolidBrush(_successColor),
      );

      graphics.drawString(
        '₹${payment.amount.toStringAsFixed(2)}',
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(320, yPosition + 8, 200, 25),
        brush: PdfSolidBrush(_successColor),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      yPosition += 60;

      // Status
      if (payment.isPaid) {
        graphics.drawString(
          '✓ PAID',
          PdfStandardFont(
            PdfFontFamily.helvetica,
            16,
            style: PdfFontStyle.bold,
          ),
          bounds: Rect.fromLTWH(50, yPosition, 500, 20),
          brush: PdfSolidBrush(_successColor),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
      }

      // Professional footer
      _drawProfessionalFooter(graphics, page, copyType: 'Student Copy');
    }

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();

    // Use printing package to preview the combined PDF
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name:
          'Payment_Receipts_${classModel.grade}_${classModel.section}_${month}_$year.pdf',
    );
  }

  // Individual Payment Receipt with Preview
  static Future<void> generateIndividualPaymentReceipt({
    required Payment payment,
    required Student student,
    required ClassModel classModel,
  }) async {
    final pdfBytes = await generatePaymentReceipt(payment, student);

    // Use printing package to preview the PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name:
          'Payment_Receipt_${student.name.replaceAll(' ', '_')}_${payment.month}_${payment.year}.pdf',
    );
  }

  // Fee Challan Generation Methods

  // Generate individual fee challan
  static Future<Uint8List> generateFeeChallan({
    required Student student,
    required ClassModel classModel,
    required String month,
    required int year,
    required double feeAmount,
    String? dueDate,
  }) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;

    // Professional header
    double yPosition = _drawProfessionalHeader(graphics, page, 'Fee Challan');
    yPosition += 20;

    final pageWidth = page.getClientSize().width;
    final contentWidth = pageWidth - 100; // 50 margin on each side
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth =
        (contentWidth / 2) - 20; // 20 for spacing between columns

    // Fee challan details section
    final headerRect = Rect.fromLTWH(50, yPosition, contentWidth, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
      bounds: headerRect,
    );

    graphics.drawString(
      'FEE CHALLAN DETAILS',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, contentWidth - 20, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 35;

    // Challan information
    final challanNumber = 'CH-${DateTime.now().millisecondsSinceEpoch}';
    final currentDate = DateTime.now();
    final dueDateStr =
        dueDate ??
        '${currentDate.add(const Duration(days: 15)).day}/${currentDate.add(const Duration(days: 15)).month}/${currentDate.add(const Duration(days: 15)).year}';

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Challan No:',
      challanNumber,
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Issue Date:',
      '${currentDate.day}/${currentDate.month}/${currentDate.year}',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Student Name:',
      student.name,
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Student ID:',
      student.id.substring(0, 8),
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Class:',
      '${classModel.grade} ${classModel.section}',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Academic Year:',
      classModel.year,
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Fee Month:',
      '$month $year',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Due Date:',
      dueDateStr,
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 40;

    // Fee breakdown section
    final feeBreakdownRect = Rect.fromLTWH(50, yPosition, contentWidth, 25);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 193, 7, 30)),
      bounds: feeBreakdownRect,
    );

    graphics.drawString(
      'FEE BREAKDOWN',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, contentWidth - 20, 15),
      brush: PdfSolidBrush(_accentColor),
    );
    yPosition += 35;

    // Fee details
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Tuition Fee:',
      '₹${feeAmount.toStringAsFixed(2)}',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Late Fee:',
      '₹0.00',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Other Charges:',
      '₹0.00',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Discount:',
      '₹0.00',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 40;

    // Total amount section with highlight
    final totalRect = Rect.fromLTWH(50, yPosition, contentWidth, 40);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 193, 7, 30)),
      pen: PdfPen(_accentColor, width: 2),
      bounds: totalRect,
    );

    graphics.drawString(
      'TOTAL AMOUNT DUE',
      _headerFont,
      bounds: Rect.fromLTWH(60, yPosition + 5, 200, 20),
      brush: PdfSolidBrush(_accentColor),
    );

    graphics.drawString(
      '₹${feeAmount.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(60, yPosition + 8, contentWidth - 20, 25),
      brush: PdfSolidBrush(_accentColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    yPosition += 60;

    // Payment instructions
    graphics.drawString(
      'PAYMENT INSTRUCTIONS',
      _subHeaderFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 20;

    final instructions = [
      '• Payment can be made at the academy reception',
      '• Please bring this challan when making payment',
      '• Payment can be made by cash or bank transfer',
      '• Late fee may apply after due date',
      '• For queries, contact: ${_academyContact.split('|').first.trim()}',
    ];

    for (final instruction in instructions) {
      graphics.drawString(
        instruction,
        _bodyFont,
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 12),
        brush: PdfSolidBrush(_textSecondary),
      );
      yPosition += 15;
    }

    // Professional footer
    _drawProfessionalFooter(graphics, page, copyType: 'Fee Challan');

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();
    return bytes;
  }

  // Generate batch fee challans with preview
  static Future<void> generateBatchFeeChallans({
    required ClassModel classModel,
    required List<Student> students,
    required String month,
    required int year,
    required double feeAmount,
    String? dueDate,
  }) async {
    final document = PdfDocument();

    // Generate challans for each student in the same document
    for (int i = 0; i < students.length; i++) {
      final student = students[i];

      // Add a new page for each challan
      final page = document.pages.add();
      final graphics = page.graphics;

      // Professional header
      double yPosition = _drawProfessionalHeader(graphics, page, 'Fee Challan');
      yPosition += 20;

      final pageWidth = page.getClientSize().width;
      final contentWidth = pageWidth - 100; // 50 margin on each side
      final leftColumnX = 60.0;
      final rightColumnX = leftColumnX + (contentWidth / 2);
      final columnWidth =
          (contentWidth / 2) - 20; // 20 for spacing between columns

      // Fee challan details section
      final headerRect = Rect.fromLTWH(50, yPosition, contentWidth, 25);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(25, 118, 210, 30)),
        bounds: headerRect,
      );

      graphics.drawString(
        'FEE CHALLAN DETAILS',
        _subHeaderFont,
        bounds: Rect.fromLTWH(60, yPosition + 5, contentWidth - 20, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      yPosition += 35;

      // Challan information
      final challanNumber =
          'CH-${DateTime.now().millisecondsSinceEpoch}-${i + 1}';
      final currentDate = DateTime.now();
      final dueDateStr =
          dueDate ??
          '${currentDate.add(const Duration(days: 15)).day}/${currentDate.add(const Duration(days: 15)).month}/${currentDate.add(const Duration(days: 15)).year}';

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Challan No:',
        challanNumber,
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Issue Date:',
        '${currentDate.day}/${currentDate.month}/${currentDate.year}',
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Student Name:',
        student.name,
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Student ID:',
        student.id.substring(0, 8),
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Class:',
        '${classModel.grade} ${classModel.section}',
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Academic Year:',
        classModel.year,
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Fee Month:',
        '$month $year',
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Due Date:',
        dueDateStr,
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 40;

      // Fee breakdown section
      final feeBreakdownRect = Rect.fromLTWH(50, yPosition, contentWidth, 25);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 193, 7, 30)),
        bounds: feeBreakdownRect,
      );

      graphics.drawString(
        'FEE BREAKDOWN',
        _subHeaderFont,
        bounds: Rect.fromLTWH(60, yPosition + 5, contentWidth - 20, 15),
        brush: PdfSolidBrush(_accentColor),
      );
      yPosition += 35;

      // Fee details
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Tuition Fee:',
        '₹${feeAmount.toStringAsFixed(2)}',
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Late Fee:',
        '₹0.00',
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Other Charges:',
        '₹0.00',
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Discount:',
        '₹0.00',
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 40;

      // Total amount section with highlight
      final totalRect = Rect.fromLTWH(50, yPosition, contentWidth, 40);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 193, 7, 30)),
        pen: PdfPen(_accentColor, width: 2),
        bounds: totalRect,
      );

      graphics.drawString(
        'TOTAL AMOUNT DUE',
        _headerFont,
        bounds: Rect.fromLTWH(60, yPosition + 5, 200, 20),
        brush: PdfSolidBrush(_accentColor),
      );

      graphics.drawString(
        '₹${feeAmount.toStringAsFixed(2)}',
        PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(60, yPosition + 8, contentWidth - 20, 25),
        brush: PdfSolidBrush(_accentColor),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      yPosition += 60;

      // Payment instructions
      graphics.drawString(
        'PAYMENT INSTRUCTIONS',
        _subHeaderFont,
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      yPosition += 20;

      final instructions = [
        '• Payment can be made at the academy reception',
        '• Please bring this challan when making payment',
        '• Payment can be made by cash or bank transfer',
        '• Late fee may apply after due date',
        '• For queries, contact: ${_academyContact.split('|').first.trim()}',
      ];

      for (final instruction in instructions) {
        graphics.drawString(
          instruction,
          _bodyFont,
          bounds: Rect.fromLTWH(50, yPosition, contentWidth, 12),
          brush: PdfSolidBrush(_textSecondary),
        );
        yPosition += 15;
      }

      // Professional footer
      _drawProfessionalFooter(graphics, page, copyType: 'Fee Challan');
    }

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();

    // Use printing package to preview the combined PDF
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name:
          'Fee_Challans_${classModel.grade}_${classModel.section}_${month}_$year.pdf',
    );
  }
}
