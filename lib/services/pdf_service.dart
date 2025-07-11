import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:tuition_app/models/student.dart';
import 'package:tuition_app/models/class_model.dart';
import 'package:tuition_app/models/attendance.dart';
import 'package:tuition_app/models/payment.dart';
import 'package:tuition_app/models/teacher.dart';

class PDFService {
  // Academy branding constants
  static const String _academyName = 'ACADEMIFY TUITION CENTER';
  static const String _academyTagline = 'Excellence in Education';
  static const String _academyAddress = 'Lahore';
  static const String _academyContact =
      'Phone: +92 345678910 | Email: info@academify.edu';
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
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 12),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    return yPosition + 30;
  }

  // Clean section header helper
  static double _drawSectionHeader(
    PdfGraphics graphics,
    String title,
    double yPosition,
    double pageWidth, {
    bool withUnderline = true,
  }) {
    final contentWidth = pageWidth - 100;

    graphics.drawString(
      title,
      _headerFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 20),
      brush: PdfSolidBrush(_primaryColor),
    );

    if (withUnderline) {
      graphics.drawLine(
        PdfPen(_primaryColor, width: 2),
        Offset(50, yPosition + 25),
        Offset(pageWidth - 50, yPosition + 25),
      );
      return yPosition + 40;
    }
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
    DateTime endDate, {
    Teacher? teacher,
  }) async {
    return _generateAttendanceReportForCopy(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
      'Student Copy',
      teacher: teacher,
    );
  }

  // Teacher Copy - Attendance Report
  static Future<Uint8List> generateAttendanceReportForTeacher(
    ClassModel classModel,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate, {
    Teacher? teacher,
  }) async {
    return _generateAttendanceReportForCopy(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
      'Teacher Copy',
      teacher: teacher,
    );
  }

  // Student Copy - Attendance Report with Preview
  static Future<void> previewAttendanceReportForStudent(
    ClassModel classModel,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate, {
    Teacher? teacher,
  }) async {
    final pdfBytes = await generateAttendanceReportForStudent(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
      teacher: teacher,
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
    DateTime endDate, {
    Teacher? teacher,
  }) async {
    final pdfBytes = await generateAttendanceReportForTeacher(
      classModel,
      students,
      attendanceRecords,
      startDate,
      endDate,
      teacher: teacher,
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
    String copyType, {
    Teacher? teacher,
  }) async {
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

    // Class Information Section - Clean design
    yPosition = _drawSectionHeader(
      graphics,
      'CLASS INFORMATION',
      yPosition,
      pageWidth,
    );

    // Class details in clean layout
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
      'Monthly Fee: ',
      '₹${classModel.monthlyFee.toStringAsFixed(2)}',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    // Teacher information
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Teacher:',
      teacher?.name ?? 'Not Assigned',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 40;

    // Beautiful attendance table
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

  // Beautiful, modern attendance table without student ID
  static double _drawAttendanceTable(
    PdfGraphics graphics,
    List<Student> students,
    List<Attendance> attendanceRecords,
    DateTime startDate,
    DateTime endDate,
    double yPosition,
    String copyType,
  ) {
    final pageWidth = 595.0; // Standard A4 width
    final contentWidth = pageWidth - 100;

    // Clean table header
    yPosition = _drawSectionHeader(
      graphics,
      'ATTENDANCE RECORDS',
      yPosition,
      pageWidth,
    );

    final totalDays = endDate.difference(startDate).inDays + 1;
    // Conservative column widths that definitely fit within content width (495)
    final double nameWidth = contentWidth * 0.35; // ~173
    final double daysWidth = contentWidth * 0.25; // ~124
    final double percentWidth = contentWidth * 0.22; // ~109
    final double statusWidth = contentWidth * 0.18; // ~89

    // Beautiful table header with gradient-like effect
    final tableHeaderRect = Rect.fromLTWH(50, yPosition, contentWidth, 30);
    graphics.drawRectangle(
      brush: PdfSolidBrush(_primaryColor),
      bounds: tableHeaderRect,
    );

    double xPos = 60;
    final headers = ['Student Name', 'Present Days', 'Attendance %', 'Status'];
    final widths = [nameWidth, daysWidth, percentWidth, statusWidth];

    for (int i = 0; i < headers.length; i++) {
      graphics.drawString(
        headers[i],
        _subHeaderFont,
        bounds: Rect.fromLTWH(xPos, yPosition + 8, widths[i] - 10, 15),
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      );
      xPos += widths[i];
    }
    yPosition += 35;

    // Student data rows with beautiful styling
    for (int index = 0; index < students.length; index++) {
      final student = students[index];
      final studentAttendance = attendanceRecords
          .where((a) => a.studentId == student.id)
          .toList();
      final presentDays = studentAttendance.where((a) => a.isPresent).length;
      final attendancePercentage = totalDays > 0
          ? (presentDays / totalDays) * 100
          : 0;

      // Elegant alternating row colors
      final rowColor = index % 2 == 0
          ? PdfColor(248, 249, 250)
          : PdfColor(255, 255, 255);

      graphics.drawRectangle(
        brush: PdfSolidBrush(rowColor),
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 25),
      );

      // Subtle row border
      graphics.drawRectangle(
        pen: PdfPen(PdfColor(233, 236, 239), width: 0.5),
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 25),
      );

      xPos = 60;
      final percentageColor = attendancePercentage >= 75
          ? _successColor
          : attendancePercentage >= 50
          ? PdfColor(255, 152, 0) // Orange for average
          : _errorColor;

      final status = attendancePercentage >= 75
          ? 'Excellent'
          : attendancePercentage >= 50
          ? 'Average'
          : 'Poor';

      final rowData = [
        student.name,
        '$presentDays / $totalDays',
        '${attendancePercentage.toStringAsFixed(1)}%',
        status,
      ];

      for (int i = 0; i < rowData.length; i++) {
        final color = i >= 2 ? percentageColor : PdfColor(52, 58, 64);
        final font = i >= 2 ? _subHeaderFont : _bodyFont;

        graphics.drawString(
          rowData[i],
          font,
          bounds: Rect.fromLTWH(xPos, yPosition + 6, widths[i] - 10, 15),
          brush: PdfSolidBrush(color),
        );
        xPos += widths[i];
      }
      yPosition += 25;
    }

    return yPosition + 10;
  }

  // Beautiful attendance summary with modern design
  static double _drawAttendanceSummary(
    PdfGraphics graphics,
    List<Student> students,
    List<Attendance> attendanceRecords,
    double yPosition,
  ) {
    final pageWidth = 595.0;
    final contentWidth = pageWidth - 100;
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth = (contentWidth / 2) - 20;

    yPosition = _drawSectionHeader(
      graphics,
      'ATTENDANCE SUMMARY',
      yPosition,
      pageWidth,
    );

    // Calculate statistics efficiently
    final totalStudents = students.length;
    double totalAttendanceSum = 0;

    for (final student in students) {
      final studentAttendance = attendanceRecords
          .where((a) => a.studentId == student.id)
          .toList();
      final presentDays = studentAttendance.where((a) => a.isPresent).length;
      final totalDays = attendanceRecords.map((a) => a.date).toSet().length;
      final percentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

      totalAttendanceSum += percentage;
    }

    final overallAverage = totalStudents > 0
        ? totalAttendanceSum / totalStudents
        : 0;

    // Beautiful summary cards
    final cardHeight = 60.0;
    final cardSpacing = 20.0;

    // Overview card with gradient-like effect
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 249, 250)),
      pen: PdfPen(_primaryColor, width: 1.5),
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, cardHeight),
    );

    graphics.drawString(
      'CLASS OVERVIEW',
      _subHeaderFont,
      bounds: Rect.fromLTWH(60, yPosition + 10, contentWidth - 20, 15),
      brush: PdfSolidBrush(_primaryColor),
    );

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Total Students:',
      totalStudents.toString(),
      leftColumnX,
      yPosition + 30,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Overall Average:',
      '${overallAverage.toStringAsFixed(1)}%',
      rightColumnX,
      yPosition + 30,
      maxWidth: columnWidth,
    );

    yPosition += cardHeight + cardSpacing;

    return yPosition;
  }

  // Beautiful Payment Receipt Generation
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
    yPosition += 30;

    final pageWidth = page.getClientSize().width;
    final contentWidth = pageWidth - 100;
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth = (contentWidth / 2) - 20;

    // Beautiful receipt header with decorative elements
    final receiptHeaderRect = Rect.fromLTWH(50, yPosition, contentWidth, 60);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 249, 250)),
      pen: PdfPen(_primaryColor, width: 2),
      bounds: receiptHeaderRect,
    );

    // Decorative corner elements
    _drawDecorativeCorners(graphics, receiptHeaderRect, _primaryColor);

    graphics.drawString(
      'OFFICIAL PAYMENT RECEIPT',
      _headerFont,
      bounds: Rect.fromLTWH(60, yPosition + 15, contentWidth - 20, 20),
      brush: PdfSolidBrush(_primaryColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    graphics.drawString(
      'This receipt serves as proof of payment',
      _bodyFont,
      bounds: Rect.fromLTWH(60, yPosition + 35, contentWidth - 20, 15),
      brush: PdfSolidBrush(_textSecondary),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    yPosition += 80;

    // Receipt details section with enhanced styling
    yPosition = _drawSectionHeader(
      graphics,
      'PAYMENT INFORMATION',
      yPosition,
      pageWidth,
    );

    // Enhanced receipt information card
    final detailsCardRect = Rect.fromLTWH(50, yPosition, contentWidth, 120);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      pen: PdfPen(_borderColor, width: 1),
      bounds: detailsCardRect,
    );

    yPosition += 15;

    // Receipt number with special styling
    graphics.drawString(
      'Receipt Number:',
      _subHeaderFont,
      bounds: Rect.fromLTWH(leftColumnX, yPosition, columnWidth * 0.6, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    graphics.drawString(
      'RCP-${payment.id.substring(0, 8).toUpperCase()}',
      PdfStandardFont(PdfFontFamily.courier, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(
        leftColumnX + columnWidth * 0.6,
        yPosition,
        columnWidth * 0.4,
        15,
      ),
      brush: PdfSolidBrush(PdfColor(220, 53, 69)),
    );

    // Payment date with calendar icon representation
    graphics.drawString(
      'Payment Date:',
      _subHeaderFont,
      bounds: Rect.fromLTWH(rightColumnX, yPosition, columnWidth * 0.6, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    final paymentDate = payment.paidDate ?? payment.dueDate;
    graphics.drawString(
      '${paymentDate.day.toString().padLeft(2, '0')}/${paymentDate.month.toString().padLeft(2, '0')}/${paymentDate.year}',
      _bodyFont,
      bounds: Rect.fromLTWH(
        rightColumnX + columnWidth * 0.6,
        yPosition,
        columnWidth * 0.4,
        15,
      ),
      brush: PdfSolidBrush(PdfColor(52, 58, 64)),
    );
    yPosition += 25;

    // Student information with profile styling
    graphics.drawString(
      'Student Name:',
      _subHeaderFont,
      bounds: Rect.fromLTWH(leftColumnX, yPosition, columnWidth * 0.4, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    graphics.drawString(
      student.name,
      _bodyFont,
      bounds: Rect.fromLTWH(
        leftColumnX + columnWidth * 0.4,
        yPosition,
        columnWidth * 0.6,
        15,
      ),
      brush: PdfSolidBrush(PdfColor(52, 58, 64)),
    );

    graphics.drawString(
      'Academic Period:',
      _subHeaderFont,
      bounds: Rect.fromLTWH(rightColumnX, yPosition, columnWidth * 0.5, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    graphics.drawString(
      '${payment.month} ${payment.year}',
      _bodyFont,
      bounds: Rect.fromLTWH(
        rightColumnX + columnWidth * 0.5,
        yPosition,
        columnWidth * 0.5,
        15,
      ),
      brush: PdfSolidBrush(PdfColor(52, 58, 64)),
    );
    yPosition += 25;

    // Payment method with icon-like styling
    graphics.drawString(
      'Payment Method:',
      _subHeaderFont,
      bounds: Rect.fromLTWH(leftColumnX, yPosition, columnWidth * 0.4, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
    final paymentMethod = payment.paymentMethod ?? 'Cash';
    graphics.drawString(
      '💳 $paymentMethod',
      _bodyFont,
      bounds: Rect.fromLTWH(
        leftColumnX + columnWidth * 0.4,
        yPosition,
        columnWidth * 0.6,
        15,
      ),
      brush: PdfSolidBrush(PdfColor(52, 58, 64)),
    );
    yPosition += 50;

    // Enhanced amount display with premium styling
    graphics.drawString(
      'AMOUNT DETAILS',
      _headerFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 20),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 30;

    // Premium amount card with clean styling
    final amountCardRect = Rect.fromLTWH(50, yPosition, contentWidth, 80);

    // Clean white background with blue border
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)), // Clean white background
      pen: PdfPen(_primaryColor, width: 3), // Blue border instead of green
      bounds: amountCardRect,
    );

    // Decorative corner elements for amount card
    _drawDecorativeCorners(graphics, amountCardRect, _primaryColor);

    // Amount label with enhanced styling
    graphics.drawString(
      'TOTAL AMOUNT PAID',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(60, yPosition + 15, contentWidth - 20, 20),
      brush: PdfSolidBrush(_primaryColor), // Blue text on white background
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Enhanced amount display
    graphics.drawString(
      '₹${payment.amount.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 32, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(60, yPosition + 35, contentWidth - 20, 40),
      brush: PdfSolidBrush(_successColor), // Green for the amount value
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    yPosition += 100;

    // Enhanced status section with icons
    if (payment.isPaid) {
      final statusRect = Rect.fromLTWH(50, yPosition, contentWidth, 50);

      // Clean success background
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(248, 249, 250)), // Light gray background
        pen: PdfPen(_successColor, width: 2),
        bounds: statusRect,
      );

      // Status icon and text
      graphics.drawString(
        '✓',
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(60, yPosition + 10, 30, 30),
        brush: PdfSolidBrush(_successColor),
      );

      graphics.drawString(
        'PAYMENT SUCCESSFULLY RECEIVED',
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(100, yPosition + 15, contentWidth - 120, 20),
        brush: PdfSolidBrush(_successColor),
      );

      graphics.drawString(
        'This receipt is valid and authentic',
        _bodyFont,
        bounds: Rect.fromLTWH(100, yPosition + 32, contentWidth - 120, 15),
        brush: PdfSolidBrush(_textSecondary),
      );
      yPosition += 70;
    }

    // Additional receipt information
    graphics.drawString(
      'IMPORTANT NOTES',
      _subHeaderFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
      brush: PdfSolidBrush(_primaryColor),
    );

    // Add subtle underline
    graphics.drawLine(
      PdfPen(_primaryColor, width: 1),
      Offset(50, yPosition + 20),
      Offset(250, yPosition + 20),
    );
    yPosition += 30;

    final notes = [
      '• This receipt is computer generated and does not require signature',
      '• Please retain this receipt for your records',
      '• For any queries, contact the academy administration',
      '• Payment is non-refundable as per academy policy',
    ];

    // Notes with beautiful styling
    for (final note in notes) {
      graphics.drawString(
        note,
        _bodyFont,
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
        brush: PdfSolidBrush(PdfColor(73, 80, 87)),
      );
      yPosition += 18;
    }

    // Professional footer
    _drawProfessionalFooter(graphics, page, copyType: 'Student Copy');

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();
    return bytes;
  }

  // Beautiful Student Report Card without Student ID
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

    final pageWidth = page.getClientSize().width;
    final contentWidth = pageWidth - 100;
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth = (contentWidth / 2) - 20;

    // Beautiful student information section
    yPosition = _drawSectionHeader(
      graphics,
      'STUDENT INFORMATION',
      yPosition,
      pageWidth,
    );

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
      'Class:',
      '${classModel.grade} ${classModel.section}',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Academic Year:',
      classModel.year,
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Parent Contact:',
      student.parentContact,
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 40;

    // Academic performance section with beautiful styling
    yPosition = _drawSectionHeader(
      graphics,
      'ACADEMIC PERFORMANCE',
      yPosition,
      pageWidth,
    );

    // Beautiful placeholder card
    final performanceCardRect = Rect.fromLTWH(50, yPosition, contentWidth, 60);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 249, 250)),
      pen: PdfPen(_primaryColor, width: 1),
      bounds: performanceCardRect,
    );

    graphics.drawString(
      'Academic performance tracking will be available in future updates.',
      _bodyFont,
      bounds: Rect.fromLTWH(60, yPosition + 15, contentWidth - 20, 15),
      brush: PdfSolidBrush(PdfColor(108, 117, 125)),
    );

    graphics.drawString(
      'This section will include grades, assignments, and progress reports.',
      _bodyFont,
      bounds: Rect.fromLTWH(60, yPosition + 35, contentWidth - 20, 15),
      brush: PdfSolidBrush(PdfColor(108, 117, 125)),
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
    Teacher? teacher,
  }) async {
    // For single student, show student copy; for multiple students, show teacher copy
    if (students.length == 1) {
      await previewAttendanceReportForStudent(
        classModel,
        students,
        attendanceRecords,
        startDate,
        endDate,
        teacher: teacher,
      );
    } else {
      await previewAttendanceReportForTeacher(
        classModel,
        students,
        attendanceRecords,
        startDate,
        endDate,
        teacher: teacher,
      );
    }
  }

  // Enhanced Bulk Payment Receipts Generation with Preview
  static Future<void> generatePaymentReceiptsPDF({
    required ClassModel classModel,
    required List<Student> students,
    required double feeAmount,
    required String month,
    required int year,
  }) async {
    final document = PdfDocument();

    // Generate beautiful receipts for each student in the same document
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

      // Add a new page for each receipt and draw the enhanced receipt
      final page = document.pages.add();
      final graphics = page.graphics;

      // Draw beautiful receipt using the same styling as individual receipts
      double yPosition = _drawProfessionalHeader(
        graphics,
        page,
        'Payment Receipt',
        copyType: 'Student Copy',
      );
      yPosition += 30;

      final pageWidth = page.getClientSize().width;
      final contentWidth = pageWidth - 100;
      final leftColumnX = 60.0;
      final rightColumnX = leftColumnX + (contentWidth / 2);
      final columnWidth = (contentWidth / 2) - 20;

      // Beautiful receipt header with decorative elements
      final receiptHeaderRect = Rect.fromLTWH(50, yPosition, contentWidth, 60);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(248, 249, 250)),
        pen: PdfPen(_primaryColor, width: 2),
        bounds: receiptHeaderRect,
      );

      // Decorative corner elements
      _drawDecorativeCorners(graphics, receiptHeaderRect, _primaryColor);

      graphics.drawString(
        'OFFICIAL PAYMENT RECEIPT',
        _headerFont,
        bounds: Rect.fromLTWH(60, yPosition + 15, contentWidth - 20, 20),
        brush: PdfSolidBrush(_primaryColor),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      graphics.drawString(
        'This receipt serves as proof of payment',
        _bodyFont,
        bounds: Rect.fromLTWH(60, yPosition + 35, contentWidth - 20, 15),
        brush: PdfSolidBrush(_textSecondary),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      yPosition += 80;

      // Receipt details section with enhanced styling
      yPosition = _drawSectionHeader(
        graphics,
        'PAYMENT INFORMATION',
        yPosition,
        pageWidth,
      );

      // Enhanced receipt information card
      final detailsCardRect = Rect.fromLTWH(50, yPosition, contentWidth, 120);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        pen: PdfPen(_borderColor, width: 1),
        bounds: detailsCardRect,
      );

      yPosition += 15;

      // Receipt number with special styling
      graphics.drawString(
        'Receipt Number:',
        _subHeaderFont,
        bounds: Rect.fromLTWH(leftColumnX, yPosition, columnWidth * 0.6, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      graphics.drawString(
        payment.receiptNumber ??
            'RCP-${payment.id.substring(0, 8).toUpperCase()}',
        PdfStandardFont(PdfFontFamily.courier, 12, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(
          leftColumnX + columnWidth * 0.6,
          yPosition,
          columnWidth * 0.4,
          15,
        ),
        brush: PdfSolidBrush(PdfColor(220, 53, 69)),
      );

      // Payment date
      graphics.drawString(
        'Payment Date:',
        _subHeaderFont,
        bounds: Rect.fromLTWH(rightColumnX, yPosition, columnWidth * 0.6, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      final paymentDate = payment.paidDate ?? payment.dueDate;
      graphics.drawString(
        '${paymentDate.day.toString().padLeft(2, '0')}/${paymentDate.month.toString().padLeft(2, '0')}/${paymentDate.year}',
        _bodyFont,
        bounds: Rect.fromLTWH(
          rightColumnX + columnWidth * 0.6,
          yPosition,
          columnWidth * 0.4,
          15,
        ),
        brush: PdfSolidBrush(PdfColor(52, 58, 64)),
      );
      yPosition += 25;

      // Student information
      graphics.drawString(
        'Student Name:',
        _subHeaderFont,
        bounds: Rect.fromLTWH(leftColumnX, yPosition, columnWidth * 0.4, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      graphics.drawString(
        student.name,
        _bodyFont,
        bounds: Rect.fromLTWH(
          leftColumnX + columnWidth * 0.4,
          yPosition,
          columnWidth * 0.6,
          15,
        ),
        brush: PdfSolidBrush(PdfColor(52, 58, 64)),
      );

      graphics.drawString(
        'Academic Period:',
        _subHeaderFont,
        bounds: Rect.fromLTWH(rightColumnX, yPosition, columnWidth * 0.5, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      graphics.drawString(
        '${payment.month} ${payment.year}',
        _bodyFont,
        bounds: Rect.fromLTWH(
          rightColumnX + columnWidth * 0.5,
          yPosition,
          columnWidth * 0.5,
          15,
        ),
        brush: PdfSolidBrush(PdfColor(52, 58, 64)),
      );
      yPosition += 25;

      // Payment method
      graphics.drawString(
        'Payment Method:',
        _subHeaderFont,
        bounds: Rect.fromLTWH(leftColumnX, yPosition, columnWidth * 0.4, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      final paymentMethod = payment.paymentMethod ?? 'Cash';
      graphics.drawString(
        '💳 $paymentMethod',
        _bodyFont,
        bounds: Rect.fromLTWH(
          leftColumnX + columnWidth * 0.4,
          yPosition,
          columnWidth * 0.6,
          15,
        ),
        brush: PdfSolidBrush(PdfColor(52, 58, 64)),
      );
      yPosition += 50;

      // Enhanced amount display
      graphics.drawString(
        'AMOUNT DETAILS',
        _headerFont,
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 20),
        brush: PdfSolidBrush(_primaryColor),
      );
      yPosition += 30;

      // Premium amount card with clean styling
      final amountCardRect = Rect.fromLTWH(50, yPosition, contentWidth, 80);

      // Clean white background with blue border
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 255, 255)), // Clean white background
        pen: PdfPen(_primaryColor, width: 3), // Blue border instead of green
        bounds: amountCardRect,
      );

      // Decorative corners for amount card
      _drawDecorativeCorners(graphics, amountCardRect, _primaryColor);

      // Amount display
      graphics.drawString(
        'TOTAL AMOUNT PAID',
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(60, yPosition + 15, contentWidth - 20, 20),
        brush: PdfSolidBrush(_primaryColor), // Blue text on white background
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      graphics.drawString(
        '₹${payment.amount.toStringAsFixed(2)}',
        PdfStandardFont(PdfFontFamily.helvetica, 32, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(60, yPosition + 35, contentWidth - 20, 40),
        brush: PdfSolidBrush(_successColor), // Green for the amount value
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      yPosition += 100;

      // Enhanced status section
      if (payment.isPaid) {
        final statusRect = Rect.fromLTWH(50, yPosition, contentWidth, 50);

        // Clean success background
        graphics.drawRectangle(
          brush: PdfSolidBrush(
            PdfColor(248, 249, 250),
          ), // Light gray background
          pen: PdfPen(_successColor, width: 2),
          bounds: statusRect,
        );

        graphics.drawString(
          '✓',
          PdfStandardFont(
            PdfFontFamily.helvetica,
            24,
            style: PdfFontStyle.bold,
          ),
          bounds: Rect.fromLTWH(60, yPosition + 10, 30, 30),
          brush: PdfSolidBrush(_successColor),
        );

        graphics.drawString(
          'PAYMENT SUCCESSFULLY RECEIVED',
          PdfStandardFont(
            PdfFontFamily.helvetica,
            16,
            style: PdfFontStyle.bold,
          ),
          bounds: Rect.fromLTWH(100, yPosition + 15, contentWidth - 120, 20),
          brush: PdfSolidBrush(_successColor), // Green text on light background
        );

        graphics.drawString(
          'This receipt is valid and authentic',
          _bodyFont,
          bounds: Rect.fromLTWH(100, yPosition + 32, contentWidth - 120, 15),
          brush: PdfSolidBrush(_textSecondary), // Gray text
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
    double extraDues = 0.0,
  }) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;

    // Professional header
    double yPosition = _drawProfessionalHeader(graphics, page, 'Fee Challan');
    yPosition += 30;

    final pageWidth = page.getClientSize().width;
    final contentWidth = pageWidth - 100; // 50 margin on each side
    final leftColumnX = 60.0;
    final rightColumnX = leftColumnX + (contentWidth / 2);
    final columnWidth =
        (contentWidth / 2) - 20; // 20 for spacing between columns

    // Fee challan details section - Clean design
    yPosition = _drawSectionHeader(
      graphics,
      'FEE CHALLAN DETAILS',
      yPosition,
      pageWidth,
    );

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
      'Class:',
      '${classModel.grade} ${classModel.section}',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Academic Year:',
      classModel.year,
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Fee Month:',
      '$month $year',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Due Date:',
      dueDateStr,
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 50;

    // Beautiful fee breakdown section
    yPosition = _drawSectionHeader(
      graphics,
      'FEE BREAKDOWN',
      yPosition,
      pageWidth,
    );

    // Create a beautiful fee breakdown card
    final feeTableRect = Rect.fromLTWH(50, yPosition, contentWidth, 80);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 249, 250)),
      pen: PdfPen(_borderColor, width: 1),
      bounds: feeTableRect,
    );

    yPosition += 15;

    // Fee details
    final monthlyFee = classModel.monthlyFee;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Monthly Tuition Fee:',
      '₹${monthlyFee.toStringAsFixed(2)}',
      leftColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Extra Dues:',
      '₹${extraDues.toStringAsFixed(2)}',
      rightColumnX,
      yPosition,
      maxWidth: columnWidth,
    );
    yPosition += 25;

    _drawDetailRow(
      graphics,
      _bodyFont,
      _subHeaderFont,
      'Late Fee:',
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

    // Beautiful total amount section
    graphics.drawString(
      'TOTAL AMOUNT DUE',
      _headerFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 20),
      brush: PdfSolidBrush(_primaryColor),
    );
    yPosition += 30;

    // Elegant total amount card
    final totalAmountRect = Rect.fromLTWH(50, yPosition, contentWidth, 45);
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(240, 248, 255)), // Light blue background
      pen: PdfPen(_primaryColor, width: 2),
      bounds: totalAmountRect,
    );

    graphics.drawString(
      '₹${feeAmount.toStringAsFixed(2)}',
      PdfStandardFont(PdfFontFamily.helvetica, 26, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(60, yPosition + 10, contentWidth - 20, 35),
      brush: PdfSolidBrush(_primaryColor),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    yPosition += 65;

    // Beautiful payment instructions
    graphics.drawString(
      'PAYMENT INSTRUCTIONS',
      _subHeaderFont,
      bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
      brush: PdfSolidBrush(_primaryColor),
    );

    // Add subtle underline
    graphics.drawLine(
      PdfPen(_primaryColor, width: 1),
      Offset(50, yPosition + 20),
      Offset(250, yPosition + 20),
    );
    yPosition += 30;

    final instructions = [
      '• Payment can be made at the academy reception',
      '• Please bring this challan when making payment',
      '• Payment can be made by cash or bank transfer',
      '• Late fee may apply after due date',
      '• For queries, contact: ${_academyContact.split('|').first.trim()}',
    ];

    // Instructions with beautiful styling
    for (final instruction in instructions) {
      graphics.drawString(
        instruction,
        _bodyFont,
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
        brush: PdfSolidBrush(PdfColor(73, 80, 87)),
      );
      yPosition += 18;
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
    double extraDues = 0.0,
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
      yPosition += 30;

      final pageWidth = page.getClientSize().width;
      final contentWidth = pageWidth - 100; // 50 margin on each side
      final leftColumnX = 60.0;
      final rightColumnX = leftColumnX + (contentWidth / 2);
      final columnWidth =
          (contentWidth / 2) - 20; // 20 for spacing between columns

      // Fee challan details section - Beautiful design
      yPosition = _drawSectionHeader(
        graphics,
        'FEE CHALLAN DETAILS',
        yPosition,
        pageWidth,
      );

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
        'Class:',
        '${classModel.grade} ${classModel.section}',
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Academic Year:',
        classModel.year,
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Fee Month:',
        '$month $year',
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Due Date:',
        dueDateStr,
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 50;

      // Beautiful fee breakdown section
      yPosition = _drawSectionHeader(
        graphics,
        'FEE BREAKDOWN',
        yPosition,
        pageWidth,
      );

      // Create a beautiful fee breakdown card
      final feeTableRect = Rect.fromLTWH(50, yPosition, contentWidth, 80);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(248, 249, 250)),
        pen: PdfPen(_borderColor, width: 1),
        bounds: feeTableRect,
      );

      yPosition += 15;

      // Fee details
      final monthlyFee = classModel.monthlyFee;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Monthly Tuition Fee:',
        '₹${monthlyFee.toStringAsFixed(2)}',
        leftColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Extra Dues:',
        '₹${extraDues.toStringAsFixed(2)}',
        rightColumnX,
        yPosition,
        maxWidth: columnWidth,
      );
      yPosition += 25;

      _drawDetailRow(
        graphics,
        _bodyFont,
        _subHeaderFont,
        'Late Fee:',
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

      // Beautiful total amount section
      graphics.drawString(
        'TOTAL AMOUNT DUE',
        _headerFont,
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 20),
        brush: PdfSolidBrush(_primaryColor),
      );
      yPosition += 30;

      // Elegant total amount card
      final totalAmountRect = Rect.fromLTWH(50, yPosition, contentWidth, 45);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(240, 248, 255)), // Light blue background
        pen: PdfPen(_primaryColor, width: 2),
        bounds: totalAmountRect,
      );

      graphics.drawString(
        '₹${feeAmount.toStringAsFixed(2)}',
        PdfStandardFont(PdfFontFamily.helvetica, 26, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(60, yPosition + 10, contentWidth - 20, 35),
        brush: PdfSolidBrush(_primaryColor),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      yPosition += 65;

      // Beautiful payment instructions
      graphics.drawString(
        'PAYMENT INSTRUCTIONS',
        _subHeaderFont,
        bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
        brush: PdfSolidBrush(_primaryColor),
      );

      // Add subtle underline
      graphics.drawLine(
        PdfPen(_primaryColor, width: 1),
        Offset(50, yPosition + 20),
        Offset(250, yPosition + 20),
      );
      yPosition += 30;

      final instructions = [
        '• Payment can be made at the academy reception',
        '• Please bring this challan when making payment',
        '• Payment can be made by cash or bank transfer',
        '• Late fee may apply after due date',
        '• For queries, contact: ${_academyContact.split('|').first.trim()}',
      ];

      // Instructions with beautiful styling
      for (final instruction in instructions) {
        graphics.drawString(
          instruction,
          _bodyFont,
          bounds: Rect.fromLTWH(50, yPosition, contentWidth, 15),
          brush: PdfSolidBrush(PdfColor(73, 80, 87)),
        );
        yPosition += 18;
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

  // Helper method for drawing decorative corners on cards
  static void _drawDecorativeCorners(
    PdfGraphics graphics,
    Rect cardRect,
    PdfColor color,
  ) {
    const cornerSize = 8.0;

    // Top-left corner
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.left + 5, cardRect.top + 5),
      Offset(cardRect.left + 5 + cornerSize, cardRect.top + 5),
    );
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.left + 5, cardRect.top + 5),
      Offset(cardRect.left + 5, cardRect.top + 5 + cornerSize),
    );

    // Top-right corner
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.right - 5 - cornerSize, cardRect.top + 5),
      Offset(cardRect.right - 5, cardRect.top + 5),
    );
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.right - 5, cardRect.top + 5),
      Offset(cardRect.right - 5, cardRect.top + 5 + cornerSize),
    );

    // Bottom-left corner
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.left + 5, cardRect.bottom - 5 - cornerSize),
      Offset(cardRect.left + 5, cardRect.bottom - 5),
    );
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.left + 5, cardRect.bottom - 5),
      Offset(cardRect.left + 5 + cornerSize, cardRect.bottom - 5),
    );

    // Bottom-right corner
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.right - 5, cardRect.bottom - 5 - cornerSize),
      Offset(cardRect.right - 5, cardRect.bottom - 5),
    );
    graphics.drawLine(
      PdfPen(color, width: 2),
      Offset(cardRect.right - 5 - cornerSize, cardRect.bottom - 5),
      Offset(cardRect.right - 5, cardRect.bottom - 5),
    );
  }
}
