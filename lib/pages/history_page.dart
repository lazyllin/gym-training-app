import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/workout_record.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/workout_summary_card.dart';
import 'workout_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedPart = '全部';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final filtered = _filter(appState.records);
    final grouped = _groupByMonth(filtered);
    final parts = ['全部', ...appState.preferences.bodyParts];
    if (!parts.contains(_selectedPart)) _selectedPart = '全部';

    return Scaffold(
      appBar: AppBar(title: const Text('记录')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索动作',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: parts.map((part) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(part),
                      selected: _selectedPart == part,
                      onSelected: (_) => setState(() => _selectedPart = part),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const EmptyState(
                title: '当前没有训练记录',
                message: '新增训练后会在这里按月份显示',
              )
            else
              ...grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title:
                          '${AppDateUtils.monthTitle(entry.value.first.date)} · ${entry.value.length}次',
                    ),
                    ...entry.value.map(
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
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  List<WorkoutRecord> _filter(List<WorkoutRecord> records) {
    var result = StatsService.filterRecordsByBodyPart(records, _selectedPart);
    final query = _query.trim();
    if (query.isNotEmpty) {
      result = result.where((record) {
        return record.exercises
            .any((exercise) => exercise.name.contains(query));
      }).toList();
    }
    return result;
  }

  Map<String, List<WorkoutRecord>> _groupByMonth(List<WorkoutRecord> records) {
    final grouped = <String, List<WorkoutRecord>>{};
    for (final record in records) {
      grouped
          .putIfAbsent(AppDateUtils.monthKey(record.date), () => [])
          .add(record);
    }
    return grouped;
  }
}
