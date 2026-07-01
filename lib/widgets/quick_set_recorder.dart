import 'package:flutter/material.dart';

import '../models/set_record.dart';
import '../theme/app_theme.dart';
import '../utils/volume_utils.dart';
import 'number_stepper_field.dart';

class QuickSetRecorder extends StatefulWidget {
  const QuickSetRecorder({
    super.key,
    required this.type,
    required this.set,
    required this.onChanged,
    required this.onComplete,
    this.onUndoComplete,
  });

  final String type;
  final SetRecord set;
  final ValueChanged<SetRecord> onChanged;
  final VoidCallback onComplete;
  final VoidCallback? onUndoComplete;

  @override
  State<QuickSetRecorder> createState() => _QuickSetRecorderState();
}

class _QuickSetRecorderState extends State<QuickSetRecorder> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final completedText = set.completed
        ? '已完成${set.completedAt == null ? '' : ' · ${_clock(set.completedAt!)}'}'
        : '当前未完成';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '第${set.setIndex}组',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: set.completed
                      ? const Color(0xFFE8F7EF)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  completedText,
                  style: TextStyle(
                    color: set.completed
                        ? const Color(0xFF16834A)
                        : const Color(0xFFB45309),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (set.createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              '添加于 ${_clock(set.createdAt!)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          ..._fields(),
          if (_supportsRpe(widget.type)) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              icon: Icon(
                _showAdvanced ? Icons.expand_less : Icons.expand_more,
              ),
              label: const Text('高级：强度 RPE'),
            ),
            if (_showAdvanced)
              NumberStepperField(
                label: '强度 RPE',
                value: set.rpe,
                suffix: '',
                increments: const [-1, 1],
                onChanged: (value) {
                  widget.onChanged(
                    set.copyWith(
                      rpe: value == null ? null : value.clamp(1, 10).toDouble(),
                      clearRpe: value == null,
                    ),
                  );
                },
              ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: set.completed
                ? OutlinedButton.icon(
                    onPressed: widget.onUndoComplete,
                    icon: const Icon(Icons.undo),
                    label: const Text('撤销完成'),
                  )
                : FilledButton.icon(
                    onPressed: widget.onComplete,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('完成本组'),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields() {
    final set = widget.set;
    switch (widget.type) {
      case 'weighted':
        return [
          NumberStepperField(
            label: '重量',
            value: set.weight,
            suffix: 'kg',
            increments: const [-5, -2.5, 2.5, 5],
            onChanged: (value) => widget.onChanged(
              set.copyWith(weight: value, clearWeight: value == null),
            ),
          ),
          const SizedBox(height: 12),
          NumberStepperField(
            label: '次数',
            value: set.reps,
            increments: const [-1, 1],
            allowDecimal: false,
            onChanged: (value) => widget.onChanged(
              set.copyWith(reps: value, clearReps: value == null),
            ),
          ),
        ];
      case 'bodyweight':
        return [
          NumberStepperField(
            label: '次数',
            value: set.reps,
            increments: const [-1, 1],
            allowDecimal: false,
            onChanged: (value) => widget.onChanged(
              set.copyWith(reps: value, clearReps: value == null),
            ),
          ),
        ];
      case 'timed':
        return [
          NumberStepperField(
            label: '时间',
            value: set.timeSec?.toDouble(),
            suffix: '秒',
            increments: const [-10, -5, 5, 10],
            allowDecimal: false,
            onChanged: (value) => widget.onChanged(
              set.copyWith(
                timeSec: value?.round(),
                clearTimeSec: value == null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
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
            onChanged: (value) => widget.onChanged(set.copyWith(side: value)),
          ),
        ];
      case 'cardio':
        return [
          NumberStepperField(
            label: '时间',
            value: set.timeSec == null ? null : set.timeSec! / 60,
            suffix: '分钟',
            increments: const [-5, -1, 1, 5],
            onChanged: (value) => widget.onChanged(
              set.copyWith(
                timeSec: value == null ? null : (value * 60).round(),
                clearTimeSec: value == null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberStepperField(
            label: '速度',
            value: set.speed,
            suffix: 'km/h',
            increments: const [-0.5, 0.5],
            onChanged: (value) => widget.onChanged(
              set.copyWith(speed: value, clearSpeed: value == null),
            ),
          ),
          const SizedBox(height: 12),
          NumberStepperField(
            label: '距离',
            value: set.distanceKm,
            suffix: 'km',
            increments: const [-0.5, 0.5],
            onChanged: (value) => widget.onChanged(
              set.copyWith(
                distanceKm: value,
                clearDistanceKm: value == null,
              ),
            ),
          ),
        ];
      case 'mobility':
        return const [
          Text(
            '本组只记录是否完成，动作细节可以写在动作备注里。',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ];
      default:
        return const [];
    }
  }

  bool _supportsRpe(String type) {
    return type == 'weighted' || type == 'bodyweight';
  }

  String _clock(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
