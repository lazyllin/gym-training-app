import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/workout_record.dart';

class HistoryImportResult {
  const HistoryImportResult({
    required this.records,
    required this.skipped,
  });

  final List<WorkoutRecord> records;
  final int skipped;
}

class HistoryImportService {
  static const String assetPath = 'assets/data/history_workout_records.json';

  Future<List<WorkoutRecord>> readBundledHistory() async {
    final content = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) return [];
    final rawRecords = decoded['records'];
    if (rawRecords is! List) return [];
    return rawRecords
        .whereType<Map>()
        .map((item) => WorkoutRecord.fromJson(Map<String, dynamic>.from(item)))
        .where((record) => record.id.isNotEmpty)
        .toList();
  }
}
