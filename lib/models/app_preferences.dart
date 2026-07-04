class AppPreferences {
  const AppPreferences({
    required this.titles,
    required this.bodyParts,
    required this.statuses,
  });

  final List<String> titles;
  final List<String> bodyParts;
  final List<String> statuses;

  factory AppPreferences.defaults() {
    return const AppPreferences(
      titles: [
        '背部训练',
        '腿部训练',
        '胸部训练',
        '肩部训练',
        '核心训练',
        '全身训练',
        '功能性训练',
        '恢复训练',
        '有氧训练',
        '自定义',
      ],
      bodyParts: [
        '背',
        '腿',
        '胸',
        '肩',
        '核心',
        '臀',
        '手臂',
        '有氧',
        '灵活性',
      ],
      statuses: [
        '正常',
        '疲劳',
        '疼痛',
        '恢复',
        '未完成',
      ],
    );
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    final defaults = AppPreferences.defaults();
    return AppPreferences(
      titles: _list(json['titles'], defaults.titles),
      bodyParts: _list(json['bodyParts'], defaults.bodyParts),
      statuses: _list(json['statuses'], defaults.statuses),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titles': titles,
      'bodyParts': bodyParts,
      'statuses': statuses,
    };
  }

  AppPreferences copyWith({
    List<String>? titles,
    List<String>? bodyParts,
    List<String>? statuses,
  }) {
    return AppPreferences(
      titles: titles ?? this.titles,
      bodyParts: bodyParts ?? this.bodyParts,
      statuses: statuses ?? this.statuses,
    );
  }

  static List<String> _list(dynamic value, List<String> fallback) {
    if (value is! List) return fallback;
    final parsed = value.map((item) => item.toString().trim()).where(
          (item) => item.isNotEmpty,
        );
    final result = parsed.toSet().toList();
    return result.isEmpty ? fallback : result;
  }
}
