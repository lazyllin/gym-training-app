import 'package:flutter/material.dart';

import '../models/workout_record.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/volume_utils.dart';
import 'ios_card.dart';

class WorkoutSummaryCard extends StatelessWidget {
  const WorkoutSummaryCard({
    super.key,
    required this.record,
    this.onTap,
  });

  final WorkoutRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final summaries = VolumeUtils.workoutExerciseSummaries(record);
    return IosCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppDateUtils.displayDate(record.date)} ${record.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.bodyParts.join('、'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.status,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...summaries.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '容量 ${VolumeUtils.workoutVolume(record)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
