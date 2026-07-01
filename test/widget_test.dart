import 'package:flutter_test/flutter_test.dart';
import 'package:gym_record_app/main.dart';
import 'package:gym_record_app/models/exercise_record.dart';
import 'package:gym_record_app/models/set_record.dart';
import 'package:gym_record_app/services/stats_service.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const GymRecordApp());
    await tester.pump();
    expect(find.text('首页'), findsOneWidget);
  });

  test('set record keeps completion timestamps', () {
    const set = SetRecord(
      setIndex: 1,
      completed: true,
      createdAt: '2026-07-01T20:00:00',
      completedAt: '2026-07-01T20:01:00',
      updatedAt: '2026-07-01T20:01:00',
    );

    final restored = SetRecord.fromJson(set.toJson());

    expect(restored.completed, isTrue);
    expect(restored.createdAt, '2026-07-01T20:00:00');
    expect(restored.completedAt, '2026-07-01T20:01:00');
  });

  test('weighted volume ignores unfinished sets', () {
    const exercise = ExerciseRecord(
      id: 'ex_1',
      name: '高位下拉',
      category: '背',
      type: 'weighted',
      unit: 'kg',
      sets: [
        SetRecord(setIndex: 1, weight: 40, reps: 10, completed: true),
        SetRecord(setIndex: 2, weight: 100, reps: 10, completed: false),
      ],
    );

    expect(StatsService.calculateExerciseWeightedVolume(exercise), 400);
  });
}
