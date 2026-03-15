import '../../../domain/entities/goals/goal_reminder.dart';

class GoalReminderModel {
  final String id;
  final String time;
  final String label;
  final bool enabled;

  GoalReminderModel({
    required this.id,
    required this.time,
    required this.label,
    required this.enabled,
  });

  factory GoalReminderModel.fromJson(Map<String, dynamic> json) =>
      GoalReminderModel(
        id: json['id']?.toString() ?? '',
        time: json['time']?.toString() ?? '08:00',
        label: json['label']?.toString() ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'label': label,
    'enabled': enabled,
  };

  GoalReminder toEntity() =>
      GoalReminder(id: id, time: time, label: label, enabled: enabled);
}
