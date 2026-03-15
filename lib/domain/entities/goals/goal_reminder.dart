import 'package:equatable/equatable.dart';

class GoalReminder extends Equatable {
  final String id;
  final String time;
  final String label;
  final bool enabled;

  const GoalReminder({
    required this.id,
    required this.time,
    required this.label,
    required this.enabled,
  });

  @override
  List<Object?> get props => [id, time, label, enabled];
}
