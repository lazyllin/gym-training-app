import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/volume_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/ios_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import '../widgets/workout_summary_card.dart';
import 'add_workout_page.dart';
import 'workout_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final records = appState.records;
    final bodyParts = StatsService.countBodyPartsThisMonth(records);
    final frequency = StatsService.countExerciseFrequencyThisMonth(records);
    final volume = StatsService.calculateWeightedVolumeThisMonth(records);

    return Scaffold(
      body: SafeArea(
        child: appState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppTheme.pagePadding),
                children: [
                  const Text(
                    '健身记录',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '本地离线记录',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  if (appState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      appState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 18),
                  IosCard(
                    child: Row(
                      children: [
                        _Metric(
                          label: '本月',
                          value:
                              '${StatsService.countWorkoutsThisMonth(records)}次',
                        ),
                        _Metric(
                          label: '主要部位',
                          value: bodyParts.isEmpty ? '-' : bodyParts.keys.first,
                        ),
                        _Metric(
                          label: '总容量',
                          value: '${VolumeUtils.formatNumber(volume)}kg',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: '新增训练',
                    icon: Icons.add,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddWorkoutPage()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (records.isEmpty)
                    EmptyState(
                      title: '还没有训练记录',
                      message: '点击下方按钮记录第一次训练',
                      action: PrimaryButton(
                        label: '新增训练',
                        icon: Icons.add,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddWorkoutPage(),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    const SectionHeader(title: '最近训练'),
                    ...records.take(3).map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: WorkoutSummaryCard(
                              record: record,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WorkoutDetailPage(recordId: record.id),
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SectionHeader(title: '常用动作'),
                    if (frequency.isEmpty)
                      const Text('记录训练后会显示常用动作')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: frequency.entries.take(5).map((entry) {
                          return Chip(
                            label: Text('${entry.key} ${entry.value}次'),
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
