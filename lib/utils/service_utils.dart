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
}
