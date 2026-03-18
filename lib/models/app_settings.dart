class AppSettings {
  final String dayStartTime;
  final int shortTaskBaseCapacity;
  final int fixedTaskBaseCapacity;
  final int shortTaskCurrentCapacity;
  final int fixedTaskCurrentCapacity;

  const AppSettings({
    required this.dayStartTime,
    required this.shortTaskBaseCapacity,
    required this.fixedTaskBaseCapacity,
    required this.shortTaskCurrentCapacity,
    required this.fixedTaskCurrentCapacity,
  });

  AppSettings copyWith({
    String? dayStartTime,
    int? shortTaskBaseCapacity,
    int? fixedTaskBaseCapacity,
    int? shortTaskCurrentCapacity,
    int? fixedTaskCurrentCapacity,
  }) {
    return AppSettings(
      dayStartTime: dayStartTime ?? this.dayStartTime,
      shortTaskBaseCapacity:
          shortTaskBaseCapacity ?? this.shortTaskBaseCapacity,
      fixedTaskBaseCapacity:
          fixedTaskBaseCapacity ?? this.fixedTaskBaseCapacity,
      shortTaskCurrentCapacity:
          shortTaskCurrentCapacity ?? this.shortTaskCurrentCapacity,
      fixedTaskCurrentCapacity:
          fixedTaskCurrentCapacity ?? this.fixedTaskCurrentCapacity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': 'app_settings',
      'day_start_time': dayStartTime,
      'short_task_base_capacity': shortTaskBaseCapacity,
      'fixed_task_base_capacity': fixedTaskBaseCapacity,
      'short_task_current_capacity': shortTaskCurrentCapacity,
      'fixed_task_current_capacity': fixedTaskCurrentCapacity,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      dayStartTime: map['day_start_time'] as String,
      shortTaskBaseCapacity: map['short_task_base_capacity'] as int,
      fixedTaskBaseCapacity: map['fixed_task_base_capacity'] as int,
      shortTaskCurrentCapacity: map['short_task_current_capacity'] as int,
      fixedTaskCurrentCapacity: map['fixed_task_current_capacity'] as int,
    );
  }
}