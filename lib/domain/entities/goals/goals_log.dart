import 'package:equatable/equatable.dart';

class GoalLog extends Equatable {
  final String id;
  final String goalId;
  final String userId;
  final DateTime date;
  final String status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalLog({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.date,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    goalId,
    userId,
    date,
    status,
    notes,
    createdAt,
    updatedAt,
  ];

  GoalLog copyWith({
    String? id,
    String? goalId,
    String? userId,
    DateTime? date,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalLog(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getter to get the status as enum
  GoalLogStatus get statusEnum => GoalLogStatus.fromString(status);
}

enum GoalLogStatus {
  completed,
  missed,
  holiday,
  sick,
  skipped;

  String get displayName {
    switch (this) {
      case GoalLogStatus.completed:
        return 'Completed';
      case GoalLogStatus.missed:
        return 'Missed';
      case GoalLogStatus.holiday:
        return 'Holiday';
      case GoalLogStatus.sick:
        return 'Sick';
      case GoalLogStatus.skipped:
        return 'Skipped';
    }
  }

  String get emoji {
    switch (this) {
      case GoalLogStatus.completed:
        return '✅';
      case GoalLogStatus.missed:
        return '❌';
      case GoalLogStatus.holiday:
        return '🏖️';
      case GoalLogStatus.sick:
        return '🤒';
      case GoalLogStatus.skipped:
        return '⏭️';
    }
  }

  String get value {
    switch (this) {
      case GoalLogStatus.completed:
        return 'completed';
      case GoalLogStatus.missed:
        return 'missed';
      case GoalLogStatus.holiday:
        return 'holiday';
      case GoalLogStatus.sick:
        return 'sick';
      case GoalLogStatus.skipped:
        return 'skipped';
    }
  }

  static GoalLogStatus fromString(String status) {
    return GoalLogStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => GoalLogStatus.missed,
    );
  }
}
