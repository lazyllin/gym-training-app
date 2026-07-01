import '../models/exercise_record.dart';
import '../models/set_record.dart';
import '../models/workout_record.dart';
import '../services/stats_service.dart';

class VolumeUtils {
  static String formatNumber(num value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'weighted':
        return '重量';
      case 'bodyweight':
        return '自重';
      case 'timed':
        return '时间';
      case 'cardio':
        return '有氧';
      case 'mobility':
        return '灵活性';
      default:
        return type;
    }
  }

  static String sideLabel(String side) {
    switch (side) {
      case 'left':
        return '左';
      case 'right':
        return '右';
      case 'both':
        return '每边';
      default:
        return '无';
    }
  }

  static String workoutVolume(WorkoutRecord record) {
    final volume = StatsService.calculateWorkoutWeightedVolume(record);
    return '${formatNumber(volume)}kg';
  }

  static String exerciseSummary(ExerciseRecord exercise) {
    if (exercise.sets.isEmpty) return '未记录组数据';
    final completedSets = StatsService.completedSets(exercise);
    if (completedSets.isEmpty) return '未完成';
    final progress = completedSets.length == exercise.sets.length
        ? ''
        : '（已完成${completedSets.length}/${exercise.sets.length}组）';
    switch (exercise.type) {
      case 'weighted':
        return '${_weightedSummary(completedSets)}$progress';
      case 'bodyweight':
        return completedSets
                .map((set) => set.reps == null ? '-' : formatNumber(set.reps!))
                .join(' / ') +
            progress;
      case 'timed':
        return completedSets.map((set) {
              final time = set.timeSec ?? 0;
              final side = set.side == 'none' ? '' : sideLabel(set.side);
              return '$time秒$side';
            }).join(' / ') +
            progress;
      case 'cardio':
        return completedSets.map((set) {
              final minutes = (set.timeSec ?? 0) / 60;
              final speed =
                  set.speed == null ? '' : ' ${formatNumber(set.speed!)}km/h';
              final distance = set.distanceKm == null
                  ? ''
                  : ' ${formatNumber(set.distanceKm!)}km';
              return '${formatNumber(minutes)}分钟$speed$distance';
            }).join(' / ') +
            progress;
      case 'mobility':
        return completedSets
                .map((set) => set.completed ? '已完成' : '未完成')
                .join(' / ') +
            progress;
      default:
        return '${completedSets.length}组$progress';
    }
  }

  static List<String> workoutExerciseSummaries(WorkoutRecord record) {
    return record.exercises
        .take(3)
        .map((exercise) => '${exercise.name} ${exerciseSummary(exercise)}')
        .toList();
  }

  static String _weightedSummary(List<SetRecord> sets) {
    final parts = <String>[];
    for (final set in sets) {
      final weight = set.weight == null ? '-' : formatNumber(set.weight!);
      final reps = set.reps == null ? '-' : formatNumber(set.reps!);
      parts.add('${weight}kg×$reps');
    }
    return parts.join(' / ');
  }
}
