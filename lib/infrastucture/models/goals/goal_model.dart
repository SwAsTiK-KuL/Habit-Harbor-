import 'goal.dart';

class GoalModel {
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

  const GoalModel({
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
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      color: json['color'] as String? ?? '#4CAF50',
      icon: json['icon'] as String? ?? 'star',
      targetFrequency: json['target_frequency'] as String? ?? 'daily',
      targetCount: json['target_count'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      todayStatus: json['todayStatus'] as String?,
      todayLogId: json['todayLogId'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'color': color,
      'icon': icon,
      'target_frequency': targetFrequency,
      'target_count': targetCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'today_status': todayStatus,
      'today_log_id': todayLogId,
    };
  }

  // Convert to domain entity
  Goal toEntity() {
    return Goal(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      color: color,
      icon: icon,
      targetFrequency: targetFrequency,
      targetCount: targetCount,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      todayStatus: todayStatus,
      todayLogId: todayLogId,
    );
  }

  // Create from domain entity
  factory GoalModel.fromEntity(Goal goal) {
    return GoalModel(
      id: goal.id,
      userId: goal.userId,
      title: goal.title,
      description: goal.description,
      category: goal.category,
      color: goal.color,
      icon: goal.icon,
      targetFrequency: goal.targetFrequency,
      targetCount: goal.targetCount,
      isActive: goal.isActive,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
      todayStatus: goal.todayStatus,
      todayLogId: goal.todayLogId,
    );
  }
}
