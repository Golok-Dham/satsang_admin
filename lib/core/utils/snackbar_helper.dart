import 'package:flutter/material.dart';

/// Helper class for consistent SnackBar messaging across the application
/// 
/// Provides themed SnackBar methods that integrate with FlexColorScheme.
/// All SnackBars:
/// - Use proper theme colors with text contrast
/// - Auto-dismiss existing snackbars before showing new ones
/// - Check context.mounted for safety
/// - Use floating behavior for better UX
/// 
/// Usage:
/// ```dart
/// SnackBarHelper.showSuccess(context, 'Added to favorites');
/// SnackBarHelper.showError(context, 'Failed to load content');
/// SnackBarHelper.showInfo(context, 'Removed from favorites');
/// SnackBarHelper.showWarning(context, 'Browser blocked autoplay');
/// ```
class SnackBarHelper {
  // Private constructor to prevent instantiation
  SnackBarHelper._();

  /// Show a regular info SnackBar
  /// 
  /// Uses primaryContainer color from FlexColorScheme for neutral information.
  /// Best for: general notifications, state changes, neutral messages.
  /// 
  /// Examples:
  /// - "Removed from favorites"
  /// - "Loading lyrics..."
  /// - "Already in playlist"
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
    );
  }

  /// Show an error SnackBar
  /// 
  /// Uses error color from theme's colorScheme with proper text contrast.
  /// Best for: failures, errors, exceptions.
  /// 
  /// Examples:
  /// - "Failed to load content"
  /// - "Network error occurred"
  /// - "Unable to save changes"
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onError),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  /// Show a success SnackBar
  /// 
  /// Uses tertiary color (teal/green) from theme's colorScheme for positive feedback.
  /// Best for: successful operations, confirmations, achievements.
  /// 
  /// Examples:
  /// - "Added to favorites"
  /// - "Link copied"
  /// - "Added to playlist"
  /// - "Progress saved"
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onTertiary),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: theme.colorScheme.tertiary,
      ),
    );
  }

  /// Show a warning SnackBar
  /// 
  /// Uses secondary color (amber/orange) from theme's colorScheme.
  /// Best for: warnings, cautions, user attention needed.
  /// 
  /// Examples:
  /// - "Browser blocked autoplay"
  /// - "Login required"
  /// - "Limited functionality available"
  /// - "Slow network detected"
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onSecondary),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }
}
