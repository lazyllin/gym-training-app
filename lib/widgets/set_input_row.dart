import 'package:flutter/material.dart';

import '../models/set_record.dart';
import '../theme/app_theme.dart';
import '../utils/volume_utils.dart';

class SetInputRow extends StatelessWidget {
  const SetInputRow({
    super.key,
    required this.type,
    required this.set,
    required this.onChanged,
    required this.onDelete,
    this.canDelete = true,
  });

  final String type;
  final SetRecord set;
  final ValueChanged<SetRecord> onChanged;
  final VoidCallback onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '第${set.setIndex}组',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Switch(
                value: set.completed,
                onChanged: (value) => onChanged(set.copyWith(completed: value)),
              ),
              IconButton(
                tooltip: '删除组',
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _fieldsForType(),
        ],
      ),
    );
  }

  Widget _fieldsForType() {
    switch (type) {
      case 'weighted':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _numberField(
              label: '重量kg',
              value: set.weight,
              onChanged: (value) => onChanged(
                set.copyWith(weight: value, clearWeight: value == null),
              ),
            ),
            _numberField(
              label: '次数',
              value: set.reps,
              onChanged: (value) => onChanged(
                  set.copyWith(reps: value, clearReps: value == null)),
            ),
            _numberField(
              label: 'RPE',
              value: set.rpe,
              onChanged: (value) =>
                  onChanged(set.copyWith(rpe: value, clearRpe: value == null)),
            ),
          ],
        );
      case 'bodyweight':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _numberField(
              label: '次数',
              value: set.reps,
              onChanged: (value) => onChanged(
                  set.copyWith(reps: value, clearReps: value == null)),
            ),
            _numberField(
              label: 'RPE',
              value: set.rpe,
              onChanged: (value) =>
                  onChanged(set.copyWith(rpe: value, clearRpe: value == null)),
            ),
          ],
        );
      case 'timed':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _intField(
              label: '时间秒',
              value: set.timeSec,
              onChanged: (value) => onChanged(
                set.copyWith(timeSec: value, clearTimeSec: value == null),
              ),
            ),
            SizedBox(
              width: 126,
              child: DropdownButtonFormField<String>(
                initialValue: set.side,
                decoration: const InputDecoration(labelText: '侧别'),
                items: const ['none', 'left', 'right', 'both']
                    .map(
                      (side) => DropdownMenuItem(
                        value: side,
                        child: Text(VolumeUtils.sideLabel(side)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => onChanged(set.copyWith(side: value)),
              ),
            ),
          ],
        );
      case 'cardio':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _numberField(
              label: '时间分钟',
              value: set.timeSec == null ? null : set.timeSec! / 60,
              onChanged: (value) => onChanged(
                set.copyWith(
                  timeSec: value == null ? null : (value * 60).round(),
                  clearTimeSec: value == null,
                ),
              ),
            ),
            _numberField(
              label: '速度',
              value: set.speed,
              onChanged: (value) => onChanged(
                set.copyWith(speed: value, clearSpeed: value == null),
              ),
            ),
            _numberField(
              label: '距离km',
              value: set.distanceKm,
              onChanged: (value) => onChanged(
                set.copyWith(
                  distanceKm: value,
                  clearDistanceKm: value == null,
                ),
              ),
            ),
          ],
        );
      case 'mobility':
        return const Text(
          '用完成开关记录本组，备注写在动作备注里。',
          style: TextStyle(color: AppTheme.textSecondary),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _numberField({
    required String label,
    required double? value,
    required ValueChanged<double?> onChanged,
  }) {
    return SizedBox(
      width: 98,
      child: TextFormField(
        initialValue: value == null ? '' : VolumeUtils.formatNumber(value),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: (raw) => onChanged(_parseDouble(raw)),
      ),
    );
  }

  Widget _intField({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return SizedBox(
      width: 110,
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (raw) => onChanged(_parseInt(raw)),
      ),
    );
  }

  double? _parseDouble(String raw) {
    if (raw.trim().isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value < 0) return null;
    return value;
  }

  int? _parseInt(String raw) {
    if (raw.trim().isEmpty) return null;
    final value = int.tryParse(raw);
    if (value == null || value < 0) return null;
    return value;
  }
}
