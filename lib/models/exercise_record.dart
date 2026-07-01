import 'set_record.dart';

class ExerciseRecord {
  const ExerciseRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.unit,
    this.isUnilateral = false,
    this.sets = const [],
    this.note = '',
  });

  final String id;
  final String name;
  final String category;
  final String type;
  final String unit;
  final bool isUnilateral;
  final List<SetRecord> sets;
  final String note;

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'];
    return ExerciseRecord(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '其他',
      type: (json['type'] as String?) ?? 'weighted',
      unit: (json['unit'] as String?) ?? 'kg',
      isUnilateral:
          json['isUnilateral'] is bool ? json['isUnilateral'] as bool : false,
      sets: rawSets is List
          ? rawSets
              .whereType<Map>()
              .map(
                  (item) => SetRecord.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      note: (json['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'type': type,
      'unit': unit,
      'isUnilateral': isUnilateral,
      'sets': sets.map((item) => item.toJson()).toList(),
      'note': note,
    };
  }

  ExerciseRecord copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    String? unit,
    bool? isUnilateral,
    List<SetRecord>? sets,
    String? note,
  }) {
    return ExerciseRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      isUnilateral: isUnilateral ?? this.isUnilateral,
      sets: sets ?? this.sets,
      note: note ?? this.note,
    );
  }
}
