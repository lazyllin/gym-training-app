import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/volume_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/ios_card.dart';
import '../widgets/section_header.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String? _selectedExercise;

  @override
  Widget build(BuildContext context) {
    final records = AppStateScope.watch(context).records;
    final frequency = StatsService.countExerciseFrequencyThisMonth(records);
    final bodyParts = StatsService.countBodyPartsThisMonth(records);
    final exerciseNames = frequency.keys.toList();
    if (exerciseNames.isEmpty) {
      _selectedExercise = null;
    } else if (_selectedExercise == null ||
        !exerciseNames.contains(_selectedExercise)) {
      _selectedExercise = exerciseNames.first;
    }

    final history = _selectedExercise == null
        ? <ExerciseHistoryEntry>[]
        : StatsService.findExerciseHistory(records, _selectedExercise!);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: SafeArea(
        child: records.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppTheme.pagePadding),
                child: EmptyState(
                  title: '记录训练后会生成统计',
                  message: '本月训练次数、部位分布和动作趋势都会显示在这里',
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppTheme.pagePadding),
                children: [
                  IosCard(
                    child: Row(
                      children: [
                        _Metric(
                          label: '本月训练',
                          value:
                              '${StatsService.countWorkoutsThisMonth(records)}次',
                        ),
                        _Metric(
                          label: '重量容量',
                          value:
                              '${VolumeUtils.formatNumber(StatsService.calculateWeightedVolumeThisMonth(records))}kg',
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: '部位分布'),
                  _rankCard(bodyParts, suffix: '次'),
                  const SectionHeader(title: '常练动作'),
                  _rankCard(frequency, suffix: '次'),
                  const SectionHeader(title: '训练量'),
                  IosCard(
                    child: Column(
                      children: [
                        _StatLine(
                          label: '重量训练总容量',
                          value:
                              '${VolumeUtils.formatNumber(StatsService.calculateWeightedVolumeThisMonth(records))}kg',
                        ),
                        _StatLine(
                          label: '自重动作总次数',
                          value:
                              '${VolumeUtils.formatNumber(StatsService.calculateBodyweightReps(records))}次',
                        ),
                        _StatLine(
                          label: '时间动作总时长',
                          value:
                              '${VolumeUtils.formatNumber(StatsService.calculateTimedSeconds(records) / 60)}分钟',
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: '动作趋势'),
                  IosCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedExercise,
                          decoration: const InputDecoration(labelText: '选择动作'),
                          items: exerciseNames
                              .map(
                                (name) => DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedExercise = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        if (history.isEmpty)
                          const Text('暂无动作历史')
                        else
                          ...history.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${AppDateUtils.displayDate(entry.date)}：${VolumeUtils.exerciseSummary(entry.exercise)}',
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _rankCard(Map<String, int> data, {required String suffix}) {
    if (data.isEmpty) return const IosCard(child: Text('暂无数据'));
    return IosCard(
      child: Column(
        children: data.entries.take(8).map((entry) {
          return _StatLine(label: entry.key, value: '${entry.value}$suffix');
        }).toList(),
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
