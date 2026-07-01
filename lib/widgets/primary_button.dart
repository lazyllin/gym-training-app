import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.isSecondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDestructive;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : isSecondary
            ? Colors.white
            : AppTheme.primary;
    final foreground = isSecondary ? AppTheme.textPrimary : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: AppTheme.border,
          disabledForegroundColor: AppTheme.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isSecondary
                ? const BorderSide(color: AppTheme.border)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
