class SetRecord {
  const SetRecord({
    required this.setIndex,
    this.weight,
    this.reps,
    this.timeSec,
    this.distanceKm,
    this.speed,
    this.side = 'none',
    this.completed = true,
    this.rpe,
    this.createdAt,
    this.completedAt,
    this.updatedAt,
  });

  final int setIndex;
  final double? weight;
  final double? reps;
  final int? timeSec;
  final double? distanceKm;
  final double? speed;
  final String side;
  final bool completed;
  final double? rpe;
  final String? createdAt;
  final String? completedAt;
  final String? updatedAt;

  factory SetRecord.fromJson(Map<String, dynamic> json) {
    return SetRecord(
      setIndex: _toInt(json['setIndex']) ?? 1,
      weight: _toDouble(json['weight']),
      reps: _toDouble(json['reps']),
      timeSec: _toInt(json['timeSec']),
      distanceKm: _toDouble(json['distanceKm']),
      speed: _toDouble(json['speed']),
      side: (json['side'] as String?) ?? 'none',
      completed: json['completed'] is bool ? json['completed'] as bool : true,
      rpe: _toDouble(json['rpe']),
      createdAt: json['createdAt'] as String?,
      completedAt: json['completedAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setIndex': setIndex,
      'weight': weight,
      'reps': reps,
      'timeSec': timeSec,
      'distanceKm': distanceKm,
      'speed': speed,
      'side': side,
      'completed': completed,
      'rpe': rpe,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'updatedAt': updatedAt,
    };
  }

  SetRecord copyWith({
    int? setIndex,
    double? weight,
    bool clearWeight = false,
    double? reps,
    bool clearReps = false,
    int? timeSec,
    bool clearTimeSec = false,
    double? distanceKm,
    bool clearDistanceKm = false,
    double? speed,
    bool clearSpeed = false,
    String? side,
    bool? completed,
    double? rpe,
    bool clearRpe = false,
    String? createdAt,
    bool clearCreatedAt = false,
    String? completedAt,
    bool clearCompletedAt = false,
    String? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return SetRecord(
      setIndex: setIndex ?? this.setIndex,
      weight: clearWeight ? null : weight ?? this.weight,
      reps: clearReps ? null : reps ?? this.reps,
      timeSec: clearTimeSec ? null : timeSec ?? this.timeSec,
      distanceKm: clearDistanceKm ? null : distanceKm ?? this.distanceKm,
      speed: clearSpeed ? null : speed ?? this.speed,
      side: side ?? this.side,
      completed: completed ?? this.completed,
      rpe: clearRpe ? null : rpe ?? this.rpe,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
