import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'models/app_preferences.dart';
import 'models/exercise_definition.dart';
import 'models/workout_record.dart';
import 'services/history_import_service.dart';
import 'services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<WorkoutRecord> records = [];
  List<ExerciseDefinition> exerciseLibrary = [];
  AppPreferences preferences = AppPreferences.defaults();
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final loadedRecords = await _storageService.readWorkoutRecords();
      final loadedLibrary = await _storageService.readExerciseLibrary();
      final loadedPreferences = await _storageService.readAppPreferences();
      records = _sortRecords(loadedRecords);
      exerciseLibrary = loadedLibrary;
      preferences = loadedPreferences;
    } catch (_) {
      records = [];
      exerciseLibrary = [];
      preferences = AppPreferences.defaults();
      errorMessage = '训练数据读取失败，已进入空数据模式';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(WorkoutRecord record) async {
    records = _sortRecords([record, ...records]);
    await _storageService.saveWorkoutRecords(records);
    notifyListeners();
  }

  Future<void> updateRecord(WorkoutRecord record) async {
    records = _sortRecords(
      records.map((item) => item.id == record.id ? record : item).toList(),
    );
    await _storageService.saveWorkoutRecords(records);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    records = records.where((item) => item.id != id).toList();
    await _storageService.saveWorkoutRecords(records);
    notifyListeners();
  }

  Future<ExerciseDefinition> addCustomExercise({
    required String name,
    required String category,
    required String type,
    required String unit,
    required bool isUnilateral,
  }) async {
    final exercise = ExerciseDefinition(
      id: 'custom_${_uuid.v4()}',
      name: name,
      category: category,
      type: type,
      unit: unit,
      isUnilateral: isUnilateral,
    );
    exerciseLibrary = [...exerciseLibrary, exercise];
    await _storageService.saveExerciseLibrary(exerciseLibrary);
    notifyListeners();
    return exercise;
  }

  Future<void> updateExerciseDefinition(ExerciseDefinition exercise) async {
    exerciseLibrary = exerciseLibrary
        .map((item) => item.id == exercise.id ? exercise : item)
        .toList();
    await _storageService.saveExerciseLibrary(exerciseLibrary);
    notifyListeners();
  }

  Future<void> updatePreferences(AppPreferences next) async {
    preferences = next;
    await _storageService.saveAppPreferences(preferences);
    notifyListeners();
  }

  Future<void> addPreferenceValue(String group, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    switch (group) {
      case 'titles':
        await updatePreferences(
          preferences.copyWith(
              titles: _appendUnique(preferences.titles, trimmed)),
        );
        return;
      case 'bodyParts':
        await updatePreferences(
          preferences.copyWith(
            bodyParts: _appendUnique(preferences.bodyParts, trimmed),
          ),
        );
        return;
      case 'statuses':
        await updatePreferences(
          preferences.copyWith(
            statuses: _appendUnique(preferences.statuses, trimmed),
          ),
        );
        return;
    }
  }

  Future<void> removePreferenceValue(String group, String value) async {
    switch (group) {
      case 'titles':
        await updatePreferences(
          preferences.copyWith(
            titles: _removeKeepingOne(preferences.titles, value),
          ),
        );
        return;
      case 'bodyParts':
        await updatePreferences(
          preferences.copyWith(
            bodyParts: _removeKeepingOne(preferences.bodyParts, value),
          ),
        );
        return;
      case 'statuses':
        await updatePreferences(
          preferences.copyWith(
            statuses: _removeKeepingOne(preferences.statuses, value),
          ),
        );
        return;
    }
  }

  Future<HistoryImportResult> importBundledHistory() async {
    final importer = HistoryImportService();
    final imported = await importer.readBundledHistory();
    final existingIds = records.map((record) => record.id).toSet();
    final fresh =
        imported.where((record) => !existingIds.contains(record.id)).toList();
    records = _sortRecords([...records, ...fresh]);
    await _storageService.saveWorkoutRecords(records);
    notifyListeners();
    return HistoryImportResult(
        records: fresh, skipped: imported.length - fresh.length);
  }

  Future<String> exportJson() {
    return _storageService.exportBackup(
      records: records,
      exercises: exerciseLibrary,
    );
  }

  Future<void> clearRecords() async {
    records = [];
    await _storageService.clearWorkoutRecords();
    notifyListeners();
  }

  String nextId(String prefix) => '${prefix}_${_uuid.v4()}';

  WorkoutRecord? findRecord(String id) {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  List<WorkoutRecord> _sortRecords(List<WorkoutRecord> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sorted;
  }

  List<String> _appendUnique(List<String> source, String value) {
    if (source.contains(value)) return source;
    return [...source, value];
  }

  List<String> _removeKeepingOne(List<String> source, String value) {
    if (source.length <= 1) return source;
    final next = source.where((item) => item != value).toList();
    return next.isEmpty ? source : next;
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppStateScope>();
    final scope = element?.widget as AppStateScope?;
    assert(scope != null, 'AppStateScope not found');
    return scope!.notifier!;
  }
}
