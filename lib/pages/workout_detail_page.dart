import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/exercise_record.dart';
import '../models/set_record.dart';
import '../models/workout_record.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/volume_utils.dart';
import '../widgets/ios_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import 'add_workout_page.dart';

class WorkoutDetailPage extends StatelessWidget {
  const WorkoutDetailPage({
    super.key,
    required this.recordId,
  });

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final record = appState.findRecord(recordId);
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('训练详情')),
        body: const Center(child: Text('记录不存在')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('训练详情')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            IosCard(child: _header(record)),
            const SectionHeader(title: '动作记录'),
            ...record.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IosCard(child: _exerciseDetail(exercise)),
              ),
            ),
            const SectionHeader(title: '备注'),
            IosCard(
              child: Text(record.note.isEmpty ? '无' : record.note),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: '编辑',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddWorkoutPage(initialRecord: record),
                ),
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: '删除',
              icon: Icons.delete_outline,
              isDestructive: true,
              onPressed: () => _delete(context, record),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(WorkoutRecord record) {
    final volume = StatsService.calculateWorkoutWeightedVolume(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppDateUtils.displayFullDate(record.date)} ${record.title}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _InfoLine(label: '状态', value: record.status),
        _InfoLine(label: '部位', value: record.bodyParts.join('、')),
        _InfoLine(label: '容量', value: '${VolumeUtils.formatNumber(volume)}kg'),
        if (record.durationMin != null)
          _InfoLine(label: '时长', value: '${record.durationMin}min'),
      ],
    );
  }

  Widget _exerciseDetail(ExerciseRecord exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          '${exercise.category} · ${VolumeUtils.typeLabel(exercise.type)}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        Text(
          VolumeUtils.exerciseSummary(exercise),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...exercise.sets.map(
          (set) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SetDetailLine(type: exercise.type, set: set),
          ),
        ),
        if (exercise.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            exercise.note,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Future<void> _delete(BuildContext context, WorkoutRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确定删除这次训练吗？'),
          content: const Text('删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AppStateScope.read(context).deleteRecord(record.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败，请重试')),
      );
    }
  }
}

class _SetDetailLine extends StatelessWidget {
  const _SetDetailLine({
    required this.type,
    required this.set,
  });

  final String type;
  final SetRecord set;

  @override
  Widget build(BuildContext context) {
    final status = set.completed
        ? '已完成${set.completedAt == null ? '' : ' · ${_clock(set.completedAt!)}'}'
        : '未完成';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: set.completed ? AppTheme.background : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '第${set.setIndex}组 ${_summary()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: set.completed ? AppTheme.textSecondary : Colors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _summary() {
    switch (type) {
      case 'weighted':
        final weight =
            set.weight == null ? '-' : VolumeUtils.formatNumber(set.weight!);
        final reps =
            set.reps == null ? '-' : VolumeUtils.formatNumber(set.reps!);
        return '${weight}kg×$reps';
      case 'bodyweight':
        return '${set.reps == null ? '-' : VolumeUtils.formatNumber(set.reps!)}次';
      case 'timed':
        final side =
            set.side == 'none' ? '' : ' ${VolumeUtils.sideLabel(set.side)}';
        return '${set.timeSec ?? 0}秒$side';
      case 'cardio':
        final minutes = (set.timeSec ?? 0) / 60;
        final speed = set.speed == null
            ? ''
            : ' ${VolumeUtils.formatNumber(set.speed!)}km/h';
        final distance = set.distanceKm == null
            ? ''
            : ' ${VolumeUtils.formatNumber(set.distanceKm!)}km';
        return '${VolumeUtils.formatNumber(minutes)}分钟$speed$distance';
      case 'mobility':
        return set.completed ? '已完成' : '未完成';
      default:
        return '';
    }
  }

  String _clock(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
