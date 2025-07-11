import 'package:flutter/material.dart';

/// Service utility class containing reusable service operations
class ServiceUtils {
  // Private constructor to prevent instantiation
  ServiceUtils._();

  // ==================== ERROR HANDLING ====================

  /// Handles common service errors and shows appropriate messages
  static void handleServiceError({
    required dynamic error,
    required BuildContext context,
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    String errorMessage = customMessage ?? 'An unexpected error occurred';

    if (error.toString().contains('network')) {
      errorMessage = 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('permission')) {
      errorMessage = 'Permission denied. Please check your access rights.';
    } else if (error.toString().contains('not-found')) {
      errorMessage = 'The requested resource was not found.';
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Operation timed out. Please try again.';
    }

    _showErrorDialog(
      context: context,
      title: 'Error',
      message: errorMessage,
      onRetry: onRetry,
    );
  }

  /// Shows a standardized error dialog
  static void _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onRetry,
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
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  // ==================== LOADING STATES ====================

  /// Shows a loading overlay
  static void showLoadingOverlay({
    required BuildContext context,
    String message = 'Loading...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hides the loading overlay
  static void hideLoadingOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ==================== SUCCESS MESSAGES ====================

  /// Shows a success snackbar
  static void showSuccessMessage({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a warning snackbar
  static void showWarningMessage({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an info snackbar
  static void showInfoMessage({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== CONFIRMATION DIALOGS ====================

  /// Shows a delete confirmation dialog
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    String? customMessage,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Delete',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            customMessage ??
                'Are you sure you want to delete "$itemName"? This action cannot be undone.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Shows a generic confirmation dialog
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: TextStyle(
                  color: confirmColor ?? const Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ==================== NETWORK HELPERS ====================

  /// Executes a service operation with error handling and loading state
  static Future<T?> executeServiceOperation<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String loadingMessage = 'Loading...',
    String? successMessage,
    bool showLoading = true,
    bool showSuccess = true,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      if (showLoading) {
        showLoadingOverlay(context: context, message: loadingMessage);
      }

      final result = await operation();

      if (showLoading) {
        hideLoadingOverlay(context);
      }

      if (showSuccess && successMessage != null) {
        showSuccessMessage(context: context, message: successMessage);
      }

      onSuccess?.call();
      return result;
    } catch (error) {
      if (showLoading) {
        hideLoadingOverlay(context);
      }

      handleServiceError(error: error, context: context);

      onError?.call();
      return null;
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Executes multiple operations in sequence with progress tracking
  static Future<List<T?>> executeBatchOperations<T>({
    required List<Future<T> Function()> operations,
    required BuildContext context,
    String loadingMessage = 'Processing...',
    bool showProgress = true,
    VoidCallback? onAllComplete,
  }) async {
    final results = <T?>[];

    if (showProgress) {
      showLoadingOverlay(context: context, message: loadingMessage);
    }

    try {
      for (int i = 0; i < operations.length; i++) {
        if (showProgress) {
          hideLoadingOverlay(context);
          showLoadingOverlay(
            context: context,
            message: '$loadingMessage (${i + 1}/${operations.length})',
          );
        }

        try {
          final result = await operations[i]();
          results.add(result);
        } catch (error) {
          results.add(null);
          // Continue with other operations even if one fails
        }
      }

      if (showProgress) {
        hideLoadingOverlay(context);
      }

      onAllComplete?.call();
      return results;
    } catch (error) {
      if (showProgress) {
        hideLoadingOverlay(context);
      }

      handleServiceError(
        error: error,
        context: context,
        customMessage: 'Some operations failed. Please try again.',
      );

      return results;
    }
  }

  // ==================== RETRY LOGIC ====================

  /// Executes an operation with retry logic
  static Future<T?> executeWithRetry<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    String loadingMessage = 'Loading...',
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        if (attempts == 0) {
          showLoadingOverlay(context: context, message: loadingMessage);
        } else {
          showLoadingOverlay(
            context: context,
            message: '$loadingMessage (Retry $attempts/$maxRetries)',
          );
        }

        final result = await operation();
        hideLoadingOverlay(context);
        return result;
      } catch (error) {
        attempts++;

        if (attempts >= maxRetries) {
          hideLoadingOverlay(context);
          handleServiceError(
            error: error,
            context: context,
            customMessage: 'Operation failed after $maxRetries attempts.',
          );
          return null;
        } else {
          await Future.delayed(retryDelay);
        }
      }
    }

    return null;
  }

  // ==================== DATA VALIDATION ====================

  /// Validates if a list is not empty
  static bool validateListNotEmpty(List? list, {String? fieldName}) {
    if (list == null || list.isEmpty) {
      return false;
    }
    return true;
  }

  /// Validates if a string is not empty or null
  static bool validateStringNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validates if an object is not null
  static bool validateNotNull(dynamic value) {
    return value != null;
  }

  // ==================== DATE UTILITIES ====================

  /// Formats a DateTime to a readable string
  static String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  /// Formats a DateTime to include time
  static String formatDateTime(DateTime dateTime) {
    return "${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  /// Parses a date string (DD/MM/YYYY) to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }
}
