import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_preferences.dart';
import '../models/exercise_definition.dart';
import '../models/workout_record.dart';
import 'sample_data_service.dart';

class StorageService {
  static const int schemaVersion = 1;
  static const String recordsFileName = 'workout_records.json';
  static const String exerciseLibraryFileName = 'exercise_library.json';
  static const String preferencesFileName = 'app_preferences.json';

  Future<Directory> _directory() {
    return getApplicationDocumentsDirectory();
  }

  Future<File> _file(String fileName) async {
    final directory = await _directory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Future<List<WorkoutRecord>> readWorkoutRecords() async {
    final file = await _file(recordsFileName);
    await _ensureFile(file, {'schemaVersion': schemaVersion, 'records': []});
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return [];
      final records = decoded['records'];
      if (records is! List) return [];
      return records
          .whereType<Map>()
          .map(
              (item) => WorkoutRecord.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWorkoutRecords(List<WorkoutRecord> records) async {
    final file = await _file(recordsFileName);
    final data = {
      'schemaVersion': schemaVersion,
      'records': records.map((item) => item.toJson()).toList(),
    };
    await _safeWrite(file, data);
  }

  Future<List<ExerciseDefinition>> readExerciseLibrary() async {
    final file = await _file(exerciseLibraryFileName);
    await _ensureFile(file, {
      'schemaVersion': schemaVersion,
      'exercises': SampleDataService.defaultExercises()
          .map((item) => item.toJson())
          .toList(),
    });
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        final defaults = SampleDataService.defaultExercises();
        await saveExerciseLibrary(defaults);
        return defaults;
      }
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return SampleDataService.defaultExercises();
      }
      final rawExercises = decoded['exercises'];
      if (rawExercises is! List || rawExercises.isEmpty) {
        final defaults = SampleDataService.defaultExercises();
        await saveExerciseLibrary(defaults);
        return defaults;
      }
      return rawExercises
          .whereType<Map>()
          .map((item) =>
              ExerciseDefinition.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList();
    } catch (_) {
      return SampleDataService.defaultExercises();
    }
  }

  Future<void> saveExerciseLibrary(List<ExerciseDefinition> exercises) async {
    final file = await _file(exerciseLibraryFileName);
    final data = {
      'schemaVersion': schemaVersion,
      'exercises': exercises.map((item) => item.toJson()).toList(),
    };
    await _safeWrite(file, data);
  }

  Future<AppPreferences> readAppPreferences() async {
    final file = await _file(preferencesFileName);
    final defaults = AppPreferences.defaults();
    await _ensureFile(file, {
      'schemaVersion': schemaVersion,
      'preferences': defaults.toJson(),
    });
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return defaults;
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return defaults;
      final raw = decoded['preferences'];
      if (raw is! Map) return defaults;
      return AppPreferences.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return defaults;
    }
  }

  Future<void> saveAppPreferences(AppPreferences preferences) async {
    final file = await _file(preferencesFileName);
    await _safeWrite(file, {
      'schemaVersion': schemaVersion,
      'preferences': preferences.toJson(),
    });
  }

  Future<String> exportBackup({
    required List<WorkoutRecord> records,
    required List<ExerciseDefinition> exercises,
  }) async {
    final directory = await _directory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      '${directory.path}${Platform.pathSeparator}gym_record_backup_$stamp.json',
    );
    final data = {
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'workout_records': {
        'schemaVersion': schemaVersion,
        'records': records.map((item) => item.toJson()).toList(),
      },
      'exercise_library': {
        'schemaVersion': schemaVersion,
        'exercises': exercises.map((item) => item.toJson()).toList(),
      },
    };
    await _safeWrite(file, data);
    return file.path;
  }

  Future<void> clearWorkoutRecords() async {
    await saveWorkoutRecords([]);
  }

  Future<void> _ensureFile(File file, Map<String, dynamic> initialData) async {
    if (await file.exists()) return;
    await _safeWrite(file, initialData);
  }

  Future<void> _safeWrite(File file, Map<String, dynamic> data) async {
    final temp = File('${file.path}.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await temp.writeAsString(encoder.convert(data), flush: true);
    await temp.copy(file.path);
    if (await temp.exists()) {
      await temp.delete();
    }
  }
}
