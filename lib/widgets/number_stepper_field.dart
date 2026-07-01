import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/volume_utils.dart';

class NumberStepperField extends StatelessWidget {
  const NumberStepperField({
    super.key,
    required this.label,
    required this.value,
    required this.increments,
    required this.onChanged,
    this.suffix = '',
    this.allowDecimal = true,
  });

  final String label;
  final double? value;
  final List<double> increments;
  final ValueChanged<double?> onChanged;
  final String suffix;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _editValue(context),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    value == null
                        ? '-'
                        : '${VolumeUtils.formatNumber(value!)}$suffix',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: increments.map(_stepButton).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepButton(double increment) {
    final sign = increment > 0 ? '+' : '';
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: () {
          var next = (value ?? 0) + increment;
          if (next < 0) next = 0;
          if (!allowDecimal) next = next.roundToDouble();
          onChanged(next);
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.compact,
        ),
        child: Text('$sign${VolumeUtils.formatNumber(increment)}'),
      ),
    );
  }

  Future<void> _editValue(BuildContext context) async {
    final controller = TextEditingController(
      text: value == null ? '' : VolumeUtils.formatNumber(value!),
    );
    final raw = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('修改$label'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(
              decimal: allowDecimal,
            ),
            decoration: InputDecoration(labelText: label, suffixText: suffix),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('清空'),
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
    if (raw == null) return;
    if (raw.isEmpty) {
      onChanged(null);
      return;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 0) return;
    onChanged(allowDecimal ? parsed : parsed.roundToDouble());
  }
}
