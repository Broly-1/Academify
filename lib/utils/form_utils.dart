import 'package:flutter/material.dart';
import 'ui_utils.dart';

/// Form utility class containing reusable form components
class FormUtils {
  // Private constructor to prevent instantiation
  FormUtils._();

  // ==================== TEXT FORM FIELDS ====================

  /// Creates a standard text form field with consistent styling
  static Widget createTextFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    Widget? prefixIcon,
    int maxLines = 1,
    String? hintText,
    bool enabled = true,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      onTap: onTap,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: UIUtils.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  /// Creates a dropdown form field with consistent styling
  static Widget createDropdownFormField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String? hintText,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: UIUtils.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: UIUtils.mediumRadius,
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  /// Creates a date picker form field
  static Widget createDateFormField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    String? Function(String?)? validator,
    DateTime? firstDate,
    DateTime? lastDate,
    String? hintText,
    bool enabled = true,
  }) {
    return createTextFormField(
      label: label,
      controller: controller,
      validator: validator,
      hintText: hintText ?? 'Select date',
      enabled: enabled,
      readOnly: true,
      suffixIcon: const Icon(Icons.calendar_today, color: UIUtils.primaryGreen),
      onTap: enabled
          ? () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: firstDate ?? DateTime(2000),
                lastDate: lastDate ?? DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: UIUtils.primaryGreen,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                controller.text =
                    "${picked.day}/${picked.month}/${picked.year}";
              }
            }
          : null,
    );
  }

  /// Creates a time picker form field
  static Widget createTimeFormField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    String? Function(String?)? validator,
    String? hintText,
    bool enabled = true,
  }) {
    return createTextFormField(
      label: label,
      controller: controller,
      validator: validator,
      hintText: hintText ?? 'Select time',
      enabled: enabled,
      readOnly: true,
      suffixIcon: const Icon(Icons.access_time, color: UIUtils.primaryGreen),
      onTap: enabled
          ? () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: UIUtils.primaryGreen,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                controller.text = picked.format(context);
              }
            }
          : null,
    );
  }

  // ==================== VALIDATORS ====================

  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    const emailPattern = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    final regExp = RegExp(emailPattern);
    if (!regExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    const phonePattern = r'^[0-9]{10,15}$';
    final regExp = RegExp(phonePattern);
    if (!regExp.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Number validation
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  /// Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return 'Enter a valid age (1-120)';
    }
    return null;
  }

  // ==================== FORM SECTIONS ====================

  /// Creates a form section with title and children
  static Widget createFormSection({
    required String title,
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return UIUtils.createCardContainer(
      padding: padding,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: UIUtils.subheadingStyle.copyWith(
              color: UIUtils.primaryGreen,
            ),
          ),
          UIUtils.mediumVerticalSpacing,
          ...children,
        ],
      ),
    );
  }

  /// Creates a form with standard spacing between fields
  static Widget createForm({
    required GlobalKey<FormState> formKey,
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
  }) {
    return Form(
      key: formKey,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          children:
              children
                  .expand((widget) => [widget, UIUtils.mediumVerticalSpacing])
                  .toList()
                ..removeLast(), // Remove last spacing
        ),
      ),
    );
  }

  // ==================== SEARCH FIELDS ====================

  /// Creates a search text field with search icon
  static Widget createSearchField({
    required TextEditingController controller,
    required void Function(String) onChanged,
    String hintText = 'Search...',
    VoidCallback? onClear,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: UIUtils.cardDecoration(),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, color: UIUtils.primaryGreen),
          suffixIcon: controller.text.isNotEmpty && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: UIUtils.mediumRadius,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ==================== CHECKBOX AND RADIO ====================

  /// Creates a checkbox list tile with consistent styling
  static Widget createCheckboxListTile({
    required String title,
    required bool value,
    required void Function(bool?) onChanged,
    String? subtitle,
    bool enabled = true,
  }) {
    return CheckboxListTile(
      title: Text(title, style: UIUtils.bodyStyle),
      subtitle: subtitle != null
          ? Text(subtitle, style: UIUtils.captionStyle)
          : null,
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: UIUtils.primaryGreen,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  /// Creates a radio list tile with consistent styling
  static Widget createRadioListTile<T>({
    required String title,
    required T value,
    required T? groupValue,
    required void Function(T?) onChanged,
    String? subtitle,
    bool enabled = true,
  }) {
    return RadioListTile<T>(
      title: Text(title, style: UIUtils.bodyStyle),
      subtitle: subtitle != null
          ? Text(subtitle, style: UIUtils.captionStyle)
          : null,
      value: value,
      groupValue: groupValue,
      onChanged: enabled ? onChanged : null,
      activeColor: UIUtils.primaryGreen,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
