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
            const SectionHeader(title: '数据'),
            IosCard(
              child: Column(
                children: [
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
