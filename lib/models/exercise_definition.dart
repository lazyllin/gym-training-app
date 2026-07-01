class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.unit,
    this.isUnilateral = false,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String category;
  final String type;
  final String unit;
  final bool isUnilateral;
  final bool enabled;

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) {
    return ExerciseDefinition(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '其他',
      type: (json['type'] as String?) ?? 'weighted',
      unit: (json['unit'] as String?) ?? 'kg',
      isUnilateral:
          json['isUnilateral'] is bool ? json['isUnilateral'] as bool : false,
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
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
      'enabled': enabled,
    };
  }

  ExerciseDefinition copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    String? unit,
    bool? isUnilateral,
    bool? enabled,
  }) {
    return ExerciseDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      isUnilateral: isUnilateral ?? this.isUnilateral,
      enabled: enabled ?? this.enabled,
    );
  }
}
