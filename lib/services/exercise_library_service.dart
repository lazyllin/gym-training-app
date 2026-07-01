import '../models/exercise_definition.dart';

class ExerciseLibraryService {
  static List<ExerciseDefinition> enabled(List<ExerciseDefinition> items) {
    return items.where((item) => item.enabled).toList();
  }

  static List<ExerciseDefinition> search(
    List<ExerciseDefinition> items,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    final source = enabled(items);
    if (normalized.isEmpty) return source;
    return source.where((item) {
      return item.name.toLowerCase().contains(normalized) ||
          item.category.toLowerCase().contains(normalized) ||
          item.type.toLowerCase().contains(normalized);
    }).toList();
  }

  static Map<String, List<ExerciseDefinition>> groupByCategory(
    List<ExerciseDefinition> items,
  ) {
    final grouped = <String, List<ExerciseDefinition>>{};
    for (final item in enabled(items)) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }
}
