import '../../../domain/entities/goals/goals_log.dart';

class GoalLogModel {
  final String id;
  final String goalId;
  final String userId;
  final DateTime date;
  final String status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalLogModel({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.date,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalLogModel.fromJson(Map<String, dynamic> json) {
    return GoalLogModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ✅ CRITICAL: This method converts model to entity
  GoalLog toEntity() {
    return GoalLog(
      id: id,
      goalId: goalId,
      userId: userId,
      date: date,
      status: status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory GoalLogModel.fromEntity(GoalLog goalLog) {
    return GoalLogModel(
      id: goalLog.id,
      goalId: goalLog.goalId,
      userId: goalLog.userId,
      date: goalLog.date,
      status: goalLog.status,
      notes: goalLog.notes,
      createdAt: goalLog.createdAt,
      updatedAt: goalLog.updatedAt,
    );
  }
}
