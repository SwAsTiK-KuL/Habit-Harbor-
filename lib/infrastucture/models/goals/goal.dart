import 'package:equatable/equatable.dart';
import 'package:habit_harbor/domain/entities/goals/goal_reminder.dart';

class Goal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String color;
  final String icon;
  final String targetFrequency;
  final int targetCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? todayStatus;
  final String? todayLogId;
  final Map<String, String>? recentLogs;
  final List<GoalReminder> reminders;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.color,
    required this.icon,
    required this.targetFrequency,
    required this.targetCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.todayStatus,
    this.todayLogId,
    this.recentLogs,
    this.reminders = const [],
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    category,
    color,
    icon,
    targetFrequency,
    targetCount,
    isActive,
    createdAt,
    updatedAt,
    todayStatus,
    todayLogId,
    recentLogs,
    reminders,
  ];

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    String? color,
    String? icon,
    String? targetFrequency,
    int? targetCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? todayStatus,
    String? todayLogId,
    Map<String, String>? recentLogs,
    List<GoalReminder>? reminders,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      targetCount: targetCount ?? this.targetCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      todayStatus: todayStatus ?? this.todayStatus,
      todayLogId: todayLogId ?? this.todayLogId,
      recentLogs: recentLogs ?? this.recentLogs,
      reminders: reminders ?? this.reminders,
    );
  }
}
