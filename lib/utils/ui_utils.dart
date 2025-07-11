import 'package:flutter/material.dart';

/// UI utility class containing reusable components and styles
class UIUtils {
  // Private constructor to prevent instantiation
  UIUtils._();

  // ==================== COLORS ====================

  /// Primary green color used throughout the app
  static const Color primaryGreen = Color(0xFF4CAF50);

  /// Dark green color for gradients and accents
  static const Color darkGreen = Color(0xFF2E7D32);

  /// Light green for subtle backgrounds
  static const Color lightGreen = Color(0xFFE8F5E8);

  // ==================== GRADIENTS ====================

  /// Standard green gradient used across the app
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, darkGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Vertical green gradient
  static const LinearGradient verticalGradient = LinearGradient(
    colors: [primaryGreen, darkGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Light gradient for subtle backgrounds
  static const LinearGradient lightGradient = LinearGradient(
    colors: [lightGreen, Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== BORDER RADIUS ====================

  /// Small border radius (8px)
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));

  /// Medium border radius (12px)
  static const BorderRadius mediumRadius = BorderRadius.all(
    Radius.circular(12),
  );

  /// Large border radius (16px)
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));

  /// Extra large border radius (20px)
  static const BorderRadius extraLargeRadius = BorderRadius.all(
    Radius.circular(20),
  );

  // ==================== BOX DECORATIONS ====================

  /// Card decoration with shadow and border radius
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: borderRadius ?? mediumRadius,
      boxShadow:
          boxShadow ??
          [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
    );
  }

  /// Gradient container decoration
  static BoxDecoration gradientDecoration({
    LinearGradient? gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient ?? primaryGradient,
      borderRadius: borderRadius ?? mediumRadius,
      boxShadow: boxShadow,
    );
  }

  /// Border decoration with primary color
  static BoxDecoration borderDecoration({
    Color? borderColor,
    double borderWidth = 1,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      border: Border.all(
        color: borderColor ?? primaryGreen,
        width: borderWidth,
      ),
      borderRadius: borderRadius ?? mediumRadius,
    );
  }

  // ==================== APP BARS ====================

  /// Creates a standard AppBar with gradient background
  static AppBar createGradientAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    Color? backgroundColor,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
      leading: leading,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: primaryGradient),
      ),
    );
  }

  /// Creates a SliverAppBar with gradient background
  static SliverAppBar createSliverAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    bool pinned = true,
    bool floating = false,
    double expandedHeight = 120,
  }) {
    return SliverAppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      actions: actions,
      leading: leading,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: primaryGradient),
        ),
      ),
    );
  }

  // ==================== BUTTONS ====================

  /// Creates a primary elevated button with green gradient
  static ElevatedButton createPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    Size? minimumSize,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? primaryGreen,
        foregroundColor: foregroundColor ?? Colors.white,
        minimumSize: minimumSize ?? const Size(120, 45),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        elevation: 2,
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    );
  }

  /// Creates a secondary button with outline
  static ElevatedButton createSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? borderColor,
    Color? textColor,
    Size? minimumSize,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: textColor ?? primaryGreen,
        minimumSize: minimumSize ?? const Size(120, 45),
        side: BorderSide(color: borderColor ?? primaryGreen, width: 1),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        elevation: 0,
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    );
  }

  /// Creates a danger button (red)
  static ElevatedButton createDangerButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Size? minimumSize,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: minimumSize ?? const Size(120, 45),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        elevation: 2,
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    );
  }

  // ==================== CONTAINERS ====================

  /// Creates a card container with standard styling
  static Widget createCardContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: cardDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }

  /// Creates a gradient container
  static Widget createGradientContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    LinearGradient? gradient,
    BorderRadius? borderRadius,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: gradientDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  // ==================== DIALOGS ====================

  /// Shows a standard error dialog
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(content),
          shape: RoundedRectangleBorder(borderRadius: mediumRadius),
          actions: [
            TextButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              child: Text(
                buttonText,
                style: const TextStyle(color: primaryGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog
  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(content),
          shape: RoundedRectangleBorder(borderRadius: mediumRadius),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                cancelText,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                confirmText,
                style: TextStyle(color: confirmColor ?? primaryGreen),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== LOADING INDICATORS ====================

  /// Creates a circular progress indicator with primary color
  static Widget createLoadingIndicator({
    Color? color,
    double? strokeWidth,
    String? message,
  }) {
    final indicator = CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color ?? primaryGreen),
      strokeWidth: strokeWidth ?? 4.0,
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: color ?? primaryGreen, fontSize: 14),
          ),
        ],
      );
    }

    return indicator;
  }

  /// Creates a full-screen loading overlay
  static Widget createLoadingOverlay({
    String? message,
    Color? backgroundColor,
  }) {
    return Container(
      color: backgroundColor ?? Colors.black.withOpacity(0.3),
      child: Center(
        child: createCardContainer(
          child: createLoadingIndicator(message: message),
          padding: const EdgeInsets.all(24),
        ),
      ),
    );
  }

  // ==================== SPACING ====================

  /// Small vertical spacing (8px)
  static const SizedBox smallVerticalSpacing = SizedBox(height: 8);

  /// Medium vertical spacing (16px)
  static const SizedBox mediumVerticalSpacing = SizedBox(height: 16);

  /// Large vertical spacing (24px)
  static const SizedBox largeVerticalSpacing = SizedBox(height: 24);

  /// Small horizontal spacing (8px)
  static const SizedBox smallHorizontalSpacing = SizedBox(width: 8);

  /// Medium horizontal spacing (16px)
  static const SizedBox mediumHorizontalSpacing = SizedBox(width: 16);

  /// Large horizontal spacing (24px)
  static const SizedBox largeHorizontalSpacing = SizedBox(width: 24);

  // ==================== TEXT STYLES ====================

  /// Heading text style
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  /// Subheading text style
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  /// Body text style
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  /// Caption text style
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );

  /// White text for buttons and overlays
  static const TextStyle whiteTextStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );
}
