import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ios_card.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return IosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_note_outlined,
              color: AppTheme.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}
