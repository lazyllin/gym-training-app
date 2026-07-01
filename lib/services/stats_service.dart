import '../models/exercise_record.dart';
import '../models/set_record.dart';
import '../models/workout_record.dart';

class ExerciseHistoryEntry {
  const ExerciseHistoryEntry({
    required this.date,
    required this.workoutTitle,
    required this.exercise,
  });

  final String date;
  final String workoutTitle;
  final ExerciseRecord exercise;
}

class StatsService {
  static List<WorkoutRecord> filterRecordsByMonth(
    List<WorkoutRecord> records,
    DateTime target,
  ) {
    return records.where((record) {
      final date = DateTime.tryParse(record.date);
      return date != null &&
          date.year == target.year &&
          date.month == target.month;
    }).toList();
  }

  static List<WorkoutRecord> filterRecordsByBodyPart(
    List<WorkoutRecord> records,
    String bodyPart,
  ) {
    if (bodyPart == '全部') return records;
    return records
        .where((record) => record.bodyParts.contains(bodyPart))
        .toList();
  }

  static int countWorkoutsThisMonth(List<WorkoutRecord> records) {
    return filterRecordsByMonth(records, DateTime.now()).length;
  }

  static Map<String, int> countBodyPartsThisMonth(List<WorkoutRecord> records) {
    final result = <String, int>{};
    for (final record in filterRecordsByMonth(records, DateTime.now())) {
      for (final part in record.bodyParts) {
        result[part] = (result[part] ?? 0) + 1;
      }
    }
    return _sortedMap(result);
  }

  static Map<String, int> countExerciseFrequencyThisMonth(
    List<WorkoutRecord> records,
  ) {
    final result = <String, int>{};
    for (final record in filterRecordsByMonth(records, DateTime.now())) {
      for (final exercise in record.exercises) {
        if (completedSets(exercise).isEmpty) continue;
        result[exercise.name] = (result[exercise.name] ?? 0) + 1;
      }
    }
    return _sortedMap(result);
  }

  static double calculateWorkoutWeightedVolume(WorkoutRecord record) {
    return record.exercises.fold<double>(
      0,
      (sum, exercise) => sum + calculateExerciseWeightedVolume(exercise),
    );
  }

  static double calculateExerciseWeightedVolume(ExerciseRecord exercise) {
    if (exercise.type != 'weighted') return 0;
    return completedSets(exercise).fold<double>(0, (sum, set) {
      return sum + ((set.weight ?? 0) * (set.reps ?? 0));
    });
  }

  static double calculateBodyweightReps(List<WorkoutRecord> records) {
    return filterRecordsByMonth(records, DateTime.now()).fold<double>(0, (
      sum,
      record,
    ) {
      return sum +
          record.exercises
              .where((item) => item.type == 'bodyweight')
              .fold<double>(
                0,
                (inner, exercise) =>
                    inner +
                    completedSets(exercise).fold<double>(
                      0,
                      (setSum, set) => setSum + (set.reps ?? 0),
                    ),
              );
    });
  }

  static int calculateTimedSeconds(List<WorkoutRecord> records) {
    return filterRecordsByMonth(records, DateTime.now()).fold<int>(0, (
      sum,
      record,
    ) {
      return sum +
          record.exercises.where((item) => item.type == 'timed').fold<int>(
                0,
                (inner, exercise) =>
                    inner +
                    completedSets(exercise).fold<int>(
                      0,
                      (setSum, set) => setSum + (set.timeSec ?? 0),
                    ),
              );
    });
  }

  static double calculateWeightedVolumeThisMonth(List<WorkoutRecord> records) {
    return filterRecordsByMonth(records, DateTime.now()).fold<double>(
      0,
      (sum, record) => sum + calculateWorkoutWeightedVolume(record),
    );
  }

  static List<ExerciseHistoryEntry> findExerciseHistory(
    List<WorkoutRecord> records,
    String exerciseName,
  ) {
    final entries = <ExerciseHistoryEntry>[];
    for (final record in records) {
      for (final exercise in record.exercises) {
        if (exercise.name == exerciseName) {
          entries.add(
            ExerciseHistoryEntry(
              date: record.date,
              workoutTitle: record.title,
              exercise: exercise,
            ),
          );
        }
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static List<SetRecord> completedSets(ExerciseRecord exercise) {
    return exercise.sets.where((set) => set.completed).toList();
  }

  static Map<String, int> _sortedMap(Map<String, int> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }
}
