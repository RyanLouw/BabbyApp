enum CareReminderType {
  feeding('Feeding', 'Time for a feed'),
  sleep('Sleep', 'Time to start the sleep routine');

  const CareReminderType(this.label, this.notificationBody);

  final String label;
  final String notificationBody;
}

class CareReminder {
  const CareReminder({
    required this.id,
    required this.type,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final int id;
  final CareReminderType type;
  final int hour;
  final int minute;
  final bool enabled;

  CareReminder copyWith({bool? enabled}) => CareReminder(
        id: id,
        type: type,
        hour: hour,
        minute: minute,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'type': type.name,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory CareReminder.fromJson(Map<String, dynamic> json) => CareReminder(
        id: json['id'] as int,
        type: CareReminderType.values.byName(json['type'] as String),
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        enabled: json['enabled'] as bool? ?? true,
      );
}
