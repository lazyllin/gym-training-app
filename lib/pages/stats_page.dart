import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/workout_record.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/volume_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/ios_card.dart';
import '../widgets/section_header.dart';
import 'workout_detail_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsRange _range = StatsRange.month;
  String? _selectedExercise;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final records = AppStateScope.watch(context).records;
    final scopedRecords = StatsService.filterRecordsByRange(records, _range);
    final frequency = StatsService.countExerciseFrequency(scopedRecords);
    final bodyParts = StatsService.countBodyParts(scopedRecords);
    final exerciseNames = StatsService.exerciseNames(records);

    if (exerciseNames.isEmpty) {
      _selectedExercise = null;
    } else if (_selectedExercise == null ||
        !exerciseNames.contains(_selectedExercise)) {
      _selectedExercise = exerciseNames.first;
    }

    final history = _selectedExercise == null
        ? <ExerciseHistoryEntry>[]
        : StatsService.findExerciseHistory(scopedRecords, _selectedExercise!);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: SafeArea(
        child: records.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppTheme.pagePadding),
                child: EmptyState(
                  title: '记录训练后会生成统计',
                  message: '训练次数、部位分布、日历和动作历史都会显示在这里',
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppTheme.pagePadding),
                children: [
                  _rangeSelector(),
                  const SizedBox(height: 12),
                  const SectionHeader(title: '训练日历'),
                  _calendarCard(records),
                  const SectionHeader(title: '周期概览'),
                  IosCard(
                    child: Row(
                      children: [
                        _Metric(
                          label: StatsService.rangeLabel(_range),
                          value: '${scopedRecords.length}次',
                        ),
                        _Metric(
                          label: '重量容量',
                          value:
                              '${VolumeUtils.formatNumber(StatsService.calculateWeightedVolume(scopedRecords))}kg',
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
                              '${VolumeUtils.formatNumber(StatsService.calculateWeightedVolume(scopedRecords))}kg',
                        ),
                        _StatLine(
                          label: '自重动作总次数',
                          value:
                              '${VolumeUtils.formatNumber(StatsService.calculateBodyweightReps(scopedRecords))}次',
                        ),
                        _StatLine(
                          label: '时间动作总时长',
                          value:
                              '${VolumeUtils.formatNumber(StatsService.calculateTimedSeconds(scopedRecords) / 60)}分钟',
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: '动作历史'),
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
                        const Text(
                          '展示当前统计周期内该动作的历史记录。',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        if (history.isEmpty)
                          const Text('当前周期暂无该动作记录')
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

  Widget _rangeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: StatsRange.values.map((range) {
        return ChoiceChip(
          label: Text(StatsService.rangeLabel(range)),
          selected: _range == range,
          onSelected: (_) => setState(() => _range = range),
        );
      }).toList(),
    );
  }

  Widget _calendarCard(List<WorkoutRecord> records) {
    final monthRecords = <int, List<WorkoutRecord>>{};
    for (final record in records) {
      final date = DateTime.tryParse(record.date);
      if (date == null ||
          date.year != _calendarMonth.year ||
          date.month != _calendarMonth.month) {
        continue;
      }
      monthRecords.putIfAbsent(date.day, () => []).add(record);
    }

    return IosCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '上个月',
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(
                    _calendarMonth.year,
                    _calendarMonth.month - 1,
                  );
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_calendarMonth.year}年${_calendarMonth.month}月',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: '下个月',
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(
                    _calendarMonth.year,
                    _calendarMonth.month + 1,
                  );
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _WeekdayLabel('一'),
              _WeekdayLabel('二'),
              _WeekdayLabel('三'),
              _WeekdayLabel('四'),
              _WeekdayLabel('五'),
              _WeekdayLabel('六'),
              _WeekdayLabel('日'),
            ],
          ),
          const SizedBox(height: 6),
          ..._calendarRows(monthRecords),
        ],
      ),
    );
  }

  List<Widget> _calendarRows(Map<int, List<WorkoutRecord>> monthRecords) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final cellCount = leadingEmpty + daysInMonth;
    final rowCount = (cellCount / 7).ceil();
    final rows = <Widget>[];

    for (var row = 0; row < rowCount; row++) {
      rows.add(
        Row(
          children: List.generate(7, (col) {
            final offset = row * 7 + col;
            final day = offset - leadingEmpty + 1;
            if (day < 1 || day > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }
            final dayRecords = monthRecords[day] ?? const <WorkoutRecord>[];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: dayRecords.isEmpty
                      ? null
                      : () => _openDayRecords(dayRecords),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: dayRecords.isEmpty
                          ? Colors.transparent
                          : const Color(0xFFE6F2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: dayRecords.isEmpty
                                ? FontWeight.w500
                                : FontWeight.w900,
                            color: dayRecords.isEmpty
                                ? AppTheme.textSecondary
                                : AppTheme.primary,
                          ),
                        ),
                        if (dayRecords.isNotEmpty)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }
    return rows;
  }

  void _openDayRecords(List<WorkoutRecord> records) {
    if (records.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutDetailPage(recordId: records.first.id),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(record.title),
                subtitle: Text(record.bodyParts.join('、')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutDetailPage(recordId: record.id),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: records.length,
          ),
        );
      },
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

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
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
