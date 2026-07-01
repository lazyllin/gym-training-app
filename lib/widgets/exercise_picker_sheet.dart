import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/exercise_definition.dart';
import '../services/exercise_library_service.dart';
import '../theme/app_theme.dart';
import '../utils/volume_utils.dart';
import 'primary_button.dart';
import 'section_header.dart';

class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({
    super.key,
    required this.onSelected,
  });

  final ValueChanged<ExerciseDefinition> onSelected;

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final filtered = ExerciseLibraryService.search(
      appState.exerciseLibrary,
      _query,
    );
    final grouped = ExerciseLibraryService.groupByCategory(filtered);
    final common = _commonExercises(filtered);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '选择动作',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCustomExerciseDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('自定义'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索动作',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('没有找到动作'))
                  : ListView(
                      children: [
                        if (common.isNotEmpty) ...[
                          const SectionHeader(title: '常用'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: common
                                .map(
                                  (exercise) => ActionChip(
                                    label: Text(exercise.name),
                                    onPressed: () => _select(exercise),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ...grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(title: entry.key),
                              ...entry.value.map(
                                (exercise) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(exercise.name),
                                  subtitle: Text(
                                    '${VolumeUtils.typeLabel(exercise.type)} · ${exercise.category}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _select(exercise),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: '新增自定义动作',
              icon: Icons.add,
              onPressed: () => _showCustomExerciseDialog(context),
              isSecondary: true,
            ),
          ],
        ),
      ),
    );
  }

  List<ExerciseDefinition> _commonExercises(List<ExerciseDefinition> source) {
    const names = ['引体', '深蹲', '硬拉', '山羊挺身', '跑步机'];
    return names
        .map((name) => source.where((item) => item.name == name).firstOrNull)
        .whereType<ExerciseDefinition>()
        .toList();
  }

  void _select(ExerciseDefinition exercise) {
    Navigator.of(context).pop();
    widget.onSelected(exercise);
  }

  Future<void> _showCustomExerciseDialog(BuildContext context) async {
    final appState = AppStateScope.read(context);
    final nameController = TextEditingController();
    String category = '背';
    String type = 'weighted';
    bool isUnilateral = false;

    final result = await showDialog<ExerciseDefinition>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新增自定义动作'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '动作名称'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: '主要部位'),
                      items: _categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => category = value ?? category);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: '动作类型'),
                      items: _types
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(VolumeUtils.typeLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => type = value ?? type);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('是否单侧'),
                      value: isUnilateral,
                      onChanged: (value) {
                        setDialogState(() => isUnilateral = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final exercise = await appState.addCustomExercise(
                      name: name,
                      category: category,
                      type: type,
                      unit: _unitForType(type),
                      isUnilateral: isUnilateral,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(exercise);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      _select(result);
    }
  }

  String _unitForType(String type) {
    switch (type) {
      case 'weighted':
        return 'kg';
      case 'bodyweight':
        return 'reps';
      case 'timed':
        return 'sec';
      case 'cardio':
        return 'min';
      case 'mobility':
        return 'done';
      default:
        return '';
    }
  }

  static const List<String> _categories = [
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

  static const List<String> _types = [
    'weighted',
    'bodyweight',
    'timed',
    'cardio',
    'mobility',
  ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
