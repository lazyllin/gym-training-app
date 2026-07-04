import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../utils/volume_utils.dart';
import '../widgets/ios_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          children: [
            const SectionHeader(title: '动作库'),
            IosCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.fitness_center,
                    title: '动作库管理',
                    subtitle: '${appState.exerciseLibrary.length}个动作',
                    onTap: () => _showLibrary(context),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '训练选项'),
            IosCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.label_outline,
                    title: '训练主题',
                    subtitle: '${appState.preferences.titles.length}个主题',
                    onTap: () => _showPreferenceManager(
                      context,
                      title: '训练主题',
                      group: 'titles',
                      values: appState.preferences.titles,
                    ),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.accessibility_new,
                    title: '训练部位',
                    subtitle: '${appState.preferences.bodyParts.length}个部位',
                    onTap: () => _showPreferenceManager(
                      context,
                      title: '训练部位',
                      group: 'bodyParts',
                      values: appState.preferences.bodyParts,
                    ),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.monitor_heart_outlined,
                    title: '训练状态',
                    subtitle: '${appState.preferences.statuses.length}个状态',
                    onTap: () => _showPreferenceManager(
                      context,
                      title: '训练状态',
                      group: 'statuses',
                      values: appState.preferences.statuses,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '数据'),
            IosCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.history,
                    title: '导入历史训练记录',
                    subtitle: '从内置结构化JSON导入',
                    onTap: () => _importHistory(context),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.file_download_outlined,
                    title: '数据导出',
                    subtitle: '导出本地JSON备份',
                    onTap: () => _export(context),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.delete_forever_outlined,
                    title: '清空全部数据',
                    subtitle: '只清空训练记录，不清空动作库',
                    danger: true,
                    onTap: () => _clearRecords(context),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '关于'),
            const IosCard(
              child: Text(
                '本地健身记录App\n第一版仅保存到手机本地JSON，不包含登录、云同步、网络请求、广告或会员功能。',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('导入历史训练记录？'),
          content: const Text(
            '会导入从历史训练记录.md整理出的记录。已导入过的记录会自动跳过。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('导入'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await AppStateScope.read(context).importBundledHistory();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入${result.records.length}条，跳过${result.skipped}条'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入失败，请检查历史数据文件')),
      );
    }
  }

  void _showPreferenceManager(
    BuildContext context, {
    required String title,
    required String group,
    required List<String> values,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) {
        return _PreferenceManagerSheet(
          title: title,
          group: group,
          values: values,
        );
      },
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final path = await AppStateScope.read(context).exportJson();
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('导出成功'),
            content: SelectableText(path),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出失败，请重试')),
      );
    }
  }

  Future<void> _clearRecords(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确定清空全部训练数据吗？'),
          content: const Text('该操作无法恢复。动作库会保留。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await AppStateScope.read(context).clearRecords();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已清空训练记录')),
    );
  }

  void _showLibrary(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return const _ExerciseLibrarySheet();
      },
    );
  }
}

class _ExerciseLibrarySheet extends StatelessWidget {
  const _ExerciseLibrarySheet();

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final exercises = [...appState.exerciseLibrary]..sort((a, b) {
        final byCategory = a.category.compareTo(b.category);
        return byCategory == 0 ? a.name.compareTo(b.name) : byCategory;
      });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const Row(
              children: [
                Expanded(
                  child: Text(
                    '动作库管理',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: '新增动作',
              icon: Icons.add,
              onPressed: () => _showAddExerciseDialog(context),
              isSecondary: true,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: exercise.enabled,
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.category} · ${VolumeUtils.typeLabel(exercise.type)}',
                    ),
                    onChanged: (value) {
                      AppStateScope.read(context).updateExerciseDefinition(
                        exercise.copyWith(enabled: value),
                      );
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: exercises.length,
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: '关闭',
              onPressed: () => Navigator.of(context).pop(),
              isSecondary: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddExerciseDialog(BuildContext context) async {
    final appState = AppStateScope.read(context);
    final nameController = TextEditingController();
    var category = appState.preferences.bodyParts.first;
    var type = 'weighted';
    var isUnilateral = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新增动作'),
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
                      items: appState.preferences.bodyParts
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
                      items: const [
                        'weighted',
                        'bodyweight',
                        'timed',
                        'cardio',
                        'mobility',
                      ]
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
                    await appState.addCustomExercise(
                      name: name,
                      category: category,
                      type: type,
                      unit: _unitForType(type),
                      isUnilateral: isUnilateral,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
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
    nameController.dispose();
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
}

class _PreferenceManagerSheet extends StatelessWidget {
  const _PreferenceManagerSheet({
    required this.title,
    required this.group,
    required this.values,
  });

  final String title;
  final String group;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.watch(context);
    final currentValues = switch (group) {
      'titles' => appState.preferences.titles,
      'bodyParts' => appState.preferences.bodyParts,
      'statuses' => appState.preferences.statuses,
      _ => values,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '新增',
                  onPressed: () => _addValue(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final value = currentValues[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(value),
                    trailing: IconButton(
                      tooltip: '删除',
                      onPressed: currentValues.length <= 1
                          ? null
                          : () {
                              AppStateScope.read(context)
                                  .removePreferenceValue(group, value);
                            },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: currentValues.length,
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: '关闭',
              onPressed: () => Navigator.of(context).pop(),
              isSecondary: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addValue(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('新增$title'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (value == null || value.isEmpty || !context.mounted) return;
    await AppStateScope.read(context).addPreferenceValue(group, value);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : AppTheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: danger ? Colors.red : null)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
