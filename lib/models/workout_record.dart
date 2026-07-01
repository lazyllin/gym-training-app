import 'exercise_record.dart';

class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.bodyParts,
    required this.status,
    this.durationMin,
    this.note = '',
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String date;
  final String title;
  final List<String> bodyParts;
  final String status;
  final int? durationMin;
  final String note;
  final List<ExerciseRecord> exercises;
  final String createdAt;
  final String updatedAt;

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    final rawBodyParts = json['bodyParts'];
    final rawExercises = json['exercises'];
    final now = DateTime.now().toIso8601String();
    return WorkoutRecord(
      id: (json['id'] as String?) ?? '',
      date: (json['date'] as String?) ?? _dateOnly(DateTime.now()),
      title: (json['title'] as String?) ?? '',
      bodyParts: rawBodyParts is List
          ? rawBodyParts.map((item) => item.toString()).toList()
          : const [],
      status: (json['status'] as String?) ?? '正常',
      durationMin: _toInt(json['durationMin']),
      note: (json['note'] as String?) ?? '',
      exercises: rawExercises is List
          ? rawExercises
              .whereType<Map>()
              .map((item) =>
                  ExerciseRecord.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      createdAt: (json['createdAt'] as String?) ?? now,
      updatedAt: (json['updatedAt'] as String?) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'bodyParts': bodyParts,
      'status': status,
      'durationMin': durationMin,
      'note': note,
      'exercises': exercises.map((item) => item.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  WorkoutRecord copyWith({
    String? id,
    String? date,
    String? title,
    List<String>? bodyParts,
    String? status,
    int? durationMin,
    bool clearDurationMin = false,
    String? note,
    List<ExerciseRecord>? exercises,
    String? createdAt,
    String? updatedAt,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      bodyParts: bodyParts ?? this.bodyParts,
      status: status ?? this.status,
      durationMin: clearDurationMin ? null : durationMin ?? this.durationMin,
      note: note ?? this.note,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
