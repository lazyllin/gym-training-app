import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/exercise_definition.dart';
import '../models/exercise_record.dart';
import '../models/set_record.dart';
import '../models/workout_record.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/volume_utils.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/ios_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/quick_set_recorder.dart';
import '../widgets/section_header.dart';

class AddWorkoutPage extends StatefulWidget {
  const AddWorkoutPage({
    super.key,
    this.initialRecord,
  });

  final WorkoutRecord? initialRecord;

  @override
  State<AddWorkoutPage> createState() => _AddWorkoutPageState();
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
  late DateTime _date;
  late String _title;
  late String _status;
  late List<String> _bodyParts;
  late List<ExerciseRecord> _exercises;
  late TextEditingController _durationController;
  late TextEditingController _noteController;
  bool _saving = false;

  bool get _isEditing => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _date = DateTime.tryParse(record?.date ?? '') ?? DateTime.now();
    _title = record?.title ?? '';
    _status = record?.status ?? '正常';
    _bodyParts = [...?record?.bodyParts];
    _exercises = [...?record?.exercises]
        .map(
          (exercise) => exercise.sets.isEmpty
              ? exercise.copyWith(sets: [_defaultSet(exercise.type, 1)])
              : exercise,
        )
        .toList();
    _durationController = TextEditingController(
      text: record?.durationMin?.toString() ?? '',
    );
    _noteController = TextEditingController(text: record?.note ?? '');
  }

  @override
  void dispose() {
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑训练' : '新增训练')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            _basicInfoCard(),
            const SizedBox(height: 14),
            const SectionHeader(title: '动作'),
            if (_exercises.isEmpty)
              IosCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('还没有添加动作'),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: '添加动作',
                      icon: Icons.add,
                      onPressed: _showExercisePicker,
                      isSecondary: true,
                    ),
                  ],
                ),
              )
            else
              ..._exercises.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _exerciseCard(entry.key, entry.value),
                    ),
                  ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: '添加动作',
              icon: Icons.add,
              onPressed: _showExercisePicker,
              isSecondary: true,
            ),
            const SizedBox(height: 14),
            IosCard(
              child: TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '当天备注',
                  hintText: '状态、疼痛、特殊情况',
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: _saving ? '保存中' : '保存训练',
              icon: Icons.save_outlined,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _basicInfoCard() {
    return IosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('日期'),
            subtitle: Text(AppDateUtils.formatDate(_date)),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          const Text('训练主题', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _titles.map((title) {
              return ChoiceChip(
                label: Text(title),
                selected: _title == title,
                onSelected: (_) => setState(() => _title = title),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('训练部位', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _parts.map((part) {
              final selected = _bodyParts.contains(part);
              return FilterChip(
                label: Text(part),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _bodyParts.add(part);
                    } else {
                      _bodyParts.remove(part);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('训练状态', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statuses.map((status) {
              return ChoiceChip(
                label: Text(status),
                selected: _status == status,
                onSelected: (_) => setState(() => _status = status),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '训练时长min',
              hintText: '可选',
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(int exerciseIndex, ExerciseRecord exercise) {
    final currentSetIndex = _currentSetIndex(exercise);
    final currentSet = exercise.sets[currentSetIndex];
    final completedCount = exercise.sets.where((set) => set.completed).length;
    final completedSets = exercise.sets
        .asMap()
        .entries
        .where((entry) => entry.value.completed && entry.key != currentSetIndex)
        .toList();

    return IosCard(
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
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.category} · ${VolumeUtils.typeLabel(exercise.type)}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '已完成 $completedCount/${exercise.sets.length} 组',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '删除动作',
                onPressed: () =>
                    setState(() => _exercises.removeAt(exerciseIndex)),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          QuickSetRecorder(
            type: exercise.type,
            set: currentSet,
            onChanged: (set) => _updateSet(exerciseIndex, currentSetIndex, set),
            onComplete: () => _completeSet(exerciseIndex, currentSetIndex),
            onUndoComplete: currentSet.completed
                ? () => _undoCompleteSet(exerciseIndex, currentSetIndex)
                : null,
          ),
          if (completedSets.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '已完成组',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...completedSets.map((entry) {
              return _completedSetTile(exerciseIndex, entry.key, entry.value);
            }),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addSet(exerciseIndex),
                  icon: const Icon(Icons.add),
                  label: const Text('添加一组'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyLastSet(exerciseIndex),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('复制上一组'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: exercise.note,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '动作备注'),
            onChanged: (value) {
              _replaceExercise(
                exerciseIndex,
                exercise.copyWith(note: value),
                refresh: false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _completedSetTile(int exerciseIndex, int setIndex, SetRecord set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '第${set.setIndex}组 ${_setSummary(_exercises[exerciseIndex].type, set)}'
              '${set.completedAt == null ? '' : ' · ${_clock(set.completedAt!)}完成'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => _undoCompleteSet(exerciseIndex, setIndex),
            child: const Text('撤销'),
          ),
          IconButton(
            tooltip: '删除组',
            onPressed: _exercises[exerciseIndex].sets.length > 1
                ? () => _deleteSet(exerciseIndex, setIndex)
                : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }

  void _showExercisePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: ExercisePickerSheet(onSelected: _addExercise),
        );
      },
    );
  }

  void _addExercise(ExerciseDefinition definition) {
    final now = DateTime.now().toIso8601String();
    setState(() {
      _exercises.add(
        ExerciseRecord(
          id: AppStateScope.read(context).nextId('ex'),
          name: definition.name,
          category: definition.category,
          type: definition.type,
          unit: definition.unit,
          isUnilateral: definition.isUnilateral,
          sets: [_defaultSet(definition.type, 1, createdAt: now)],
        ),
      );
    });
  }

  void _addSet(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final now = DateTime.now().toIso8601String();
    final sets = [
      ...exercise.sets,
      _defaultSet(
        exercise.type,
        exercise.sets.length + 1,
        createdAt: now,
      ),
    ];
    _replaceExercise(exerciseIndex, exercise.copyWith(sets: _reindex(sets)));
  }

  void _copyLastSet(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    final now = DateTime.now().toIso8601String();
    final last = exercise.sets.isEmpty
        ? _defaultSet(exercise.type, 1, createdAt: now)
        : exercise.sets.last;
    final sets = [
      ...exercise.sets,
      _copyAsNextSet(last, exercise.sets.length + 1, now),
    ];
    _replaceExercise(exerciseIndex, exercise.copyWith(sets: _reindex(sets)));
  }

  void _deleteSet(int exerciseIndex, int setIndex) {
    final exercise = _exercises[exerciseIndex];
    if (exercise.sets.length <= 1) return;
    final sets = [...exercise.sets]..removeAt(setIndex);
    _replaceExercise(exerciseIndex, exercise.copyWith(sets: _reindex(sets)));
  }

  void _updateSet(int exerciseIndex, int setIndex, SetRecord set) {
    final exercise = _exercises[exerciseIndex];
    final sets = [...exercise.sets];
    sets[setIndex] = set.copyWith(updatedAt: DateTime.now().toIso8601String());
    _replaceExercise(
      exerciseIndex,
      exercise.copyWith(sets: _reindex(sets)),
    );
  }

  void _completeSet(int exerciseIndex, int setIndex) {
    final exercise = _exercises[exerciseIndex];
    final sets = [...exercise.sets];
    final now = DateTime.now().toIso8601String();
    final current = sets[setIndex];
    sets[setIndex] = current.copyWith(
      completed: true,
      createdAt: current.createdAt ?? now,
      completedAt: current.completedAt ?? now,
      updatedAt: now,
    );

    if (setIndex == sets.length - 1) {
      sets.add(_copyAsNextSet(sets[setIndex], sets.length + 1, now));
    }

    _replaceExercise(exerciseIndex, exercise.copyWith(sets: _reindex(sets)));
  }

  void _undoCompleteSet(int exerciseIndex, int setIndex) {
    final exercise = _exercises[exerciseIndex];
    final sets = [...exercise.sets];
    final now = DateTime.now().toIso8601String();
    sets[setIndex] = sets[setIndex].copyWith(
      completed: false,
      clearCompletedAt: true,
      updatedAt: now,
    );
    _replaceExercise(exerciseIndex, exercise.copyWith(sets: _reindex(sets)));
  }

  void _replaceExercise(
    int index,
    ExerciseRecord exercise, {
    bool refresh = true,
  }) {
    _exercises[index] = exercise;
    if (refresh) setState(() {});
  }

  List<SetRecord> _reindex(List<SetRecord> sets) {
    return sets
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(setIndex: entry.key + 1))
        .toList();
  }

  SetRecord _defaultSet(String type, int index, {String? createdAt}) {
    switch (type) {
      case 'timed':
        return SetRecord(
          setIndex: index,
          timeSec: 30,
          side: 'none',
          completed: false,
          createdAt: createdAt,
          updatedAt: createdAt,
        );
      case 'cardio':
        return SetRecord(
          setIndex: index,
          timeSec: 600,
          completed: false,
          createdAt: createdAt,
          updatedAt: createdAt,
        );
      case 'mobility':
        return SetRecord(
          setIndex: index,
          completed: false,
          createdAt: createdAt,
          updatedAt: createdAt,
        );
      default:
        return SetRecord(
          setIndex: index,
          completed: false,
          createdAt: createdAt,
          updatedAt: createdAt,
        );
    }
  }

  SetRecord _copyAsNextSet(SetRecord source, int index, String now) {
    return source.copyWith(
      setIndex: index,
      completed: false,
      createdAt: now,
      clearCompletedAt: true,
      updatedAt: now,
    );
  }

  int _currentSetIndex(ExerciseRecord exercise) {
    final firstOpen = exercise.sets.indexWhere((set) => !set.completed);
    if (firstOpen >= 0) return firstOpen;
    return exercise.sets.length - 1;
  }

  String _setSummary(String type, SetRecord set) {
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
        return '${set.timeSec ?? 0}秒';
      case 'cardio':
        return '${VolumeUtils.formatNumber((set.timeSec ?? 0) / 60)}分钟';
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

  Future<void> _save() async {
    final appState = AppStateScope.read(context);
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now().toIso8601String();
    final initial = widget.initialRecord;
    final duration = int.tryParse(_durationController.text.trim());
    final exercises = _exercises.map(_pruneTrailingOpenSet).toList();
    final record = WorkoutRecord(
      id: initial?.id ?? appState.nextId('workout'),
      date: AppDateUtils.formatDate(_date),
      title: _title,
      bodyParts: _bodyParts,
      status: _status,
      durationMin: duration,
      note: _noteController.text.trim(),
      exercises: exercises,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (_isEditing) {
        await appState.updateRecord(record);
      } else {
        await appState.addRecord(record);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validate() {
    if (_title.isEmpty) return '请先选择训练主题';
    if (_bodyParts.isEmpty) return '请至少选择一个训练部位';
    if (_exercises.isEmpty) return '请至少添加一个动作';
    final durationText = _durationController.text.trim();
    if (durationText.isNotEmpty) {
      final duration = int.tryParse(durationText);
      if (duration == null || duration < 0) return '训练时长不能为负数';
    }
    for (final exercise in _exercises) {
      if (exercise.sets.isEmpty) return '${exercise.name} 请至少保留一组';
      for (final set in exercise.sets) {
        if ((set.weight ?? 0) < 0 ||
            (set.reps ?? 0) < 0 ||
            (set.timeSec ?? 0) < 0 ||
            (set.distanceKm ?? 0) < 0 ||
            (set.speed ?? 0) < 0 ||
            (set.rpe ?? 0) < 0) {
          return '数字不能为负';
        }
      }
    }
    return null;
  }

  ExerciseRecord _pruneTrailingOpenSet(ExerciseRecord exercise) {
    final sets = [...exercise.sets];
    while (sets.length > 1 &&
        !sets.last.completed &&
        sets.take(sets.length - 1).any((set) => set.completed)) {
      sets.removeLast();
    }
    return exercise.copyWith(sets: _reindex(sets));
  }

  static const List<String> _titles = [
    '背部训练',
    '腿部训练',
    '胸部训练',
    '肩部训练',
    '核心训练',
    '全身训练',
    '功能性训练',
    '恢复训练',
    '有氧训练',
    '自定义',
  ];

  static const List<String> _parts = [
    '背',
    '腿',
    '胸',
    '肩',
    '核心',
    '臀',
    '手臂',
    '有氧',
    '灵活性',
  ];

  static const List<String> _statuses = [
    '正常',
    '疲劳',
    '疼痛',
    '恢复',
    '未完成',
  ];
}
